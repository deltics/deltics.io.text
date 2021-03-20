
{$i deltics.IO.text.inc}

  unit Deltics.IO.Text.TextReader;


interface

  uses
    Classes,
    Deltics.InterfacedObjects,
    Deltics.StringEncodings,
    Deltics.StringTypes,
    Deltics.IO.Text.Interfaces,
    Deltics.IO.Text.Types;


  type
    TDecoderMethod = procedure(const aInputBuffer: Pointer; const aInputBytes: Integer; const aDecodeBuffer: Pointer; const aMaxDecodedBytes: Integer; var aInputBytesDecoded: Integer; var aDecodedBytes: Integer) of object;
    TReadSourceMethod = procedure of object;


    TTextReader = class(TComInterfacedObject, ITextReader)
    {
      Provides a base class for parsers.  This base class provides the fundamental
       mechanisms required for reading any arbitrary stream as a series of UTF8 chars.
       Transcoding of the source stream to UFT8 is performed automatically.

      The encoding of the source ise determined by identifying a BOM signature at
       the initial read position of the stream.  BOM signatures are automatically
       recognised for the standard UTF encodings (UTF8, UTF16 etc).  Derived classes
       should add their own signatures if/as required by overriding the Initialise
       virtual method and calling ADDBOMSignature for each signature that may be
       recognisable.
    }
    // ITextReader
    protected
      function get_Location: TCharLocation; virtual; abstract;
      function get_Source: IStream;
      function get_SourceEncoding: TEncoding;
      function get_EOF: Boolean; virtual;
    private
      fSource: TStream;
      fSourceIntf: IStream;
      fSourceEncoding: TEncoding;

    protected
      fBuffer: PByte;
      fBufferRemaining: Integer;

    protected
      fData: PByte;
      fDataCurrent: PByte;
      fDataSize: Integer;
      fDataAvailable: Integer;
      fDataRemaining: Integer;
    private
      fEOF: Boolean;

      fDecoderMethod: TDecoderMethod;
      fReadSourceMethod: TReadSourceMethod;

      procedure ReadSourceAndDecodeIntoData;
      procedure ReadSourceDirectlyIntoData;

    protected
      function ReadByte: Byte;
      function ReadWord: Word;
      function MakeDataAvailable: Boolean;
      procedure SetDecoder(const aDecoderMethod: TDecoderMethod);
      property Decode: TDecoderMethod read fDecoderMethod;
      property ReadData: TReadSourceMethod read fReadSourceMethod;
    public
      constructor Create(const aStream: IStream; const aEncoding: TEncoding = NIL); overload;
      constructor Create(const aStream: TStream; const aEncoding: TEncoding = NIL); overload;
      constructor Create(const aString: UnicodeString); overload;
      constructor Create(const aString: Utf8String); overload;
      destructor Destroy; override;
      procedure AfterConstruction; override;
      property SourceEncoding: TEncoding read fSourceEncoding;
      property EOF: Boolean read fEOF;
    end;




implementation

  uses
    SysUtils,
    Deltics.Exceptions,
    Deltics.IO.Streams,
    Deltics.Memory;


  const
    INPUT_BUFFER_SIZE = 4096;

  type
    TEncoding = Deltics.StringEncodings.TEncoding;
    TByteArray = array of Byte;
    TWordArray = array of Word;


  constructor TTextReader.Create(const aStream: IStream;
                                 const aEncoding: TEncoding);
  begin
    fSourceIntf := aStream;
    Create(aStream.Stream, aEncoding);
  end;


  constructor TTextReader.Create(const aStream: TStream;
                                 const aEncoding: TEncoding);
  begin
    inherited Create;

    fSource         := aStream;
    fSourceEncoding := aEncoding;
  end;


  constructor TTextReader.Create(const aString: UnicodeString);
  var
    strm: IStream;
  begin
    strm := MemoryStream.CreateCopy(@aString[1], Length(aString) * 2);

    Create(strm, TEncoding.Utf16LE);
  end;


  constructor TTextReader.Create(const aString: Utf8String);
  var
    strm: IStream;
  begin
    strm := MemoryStream.CreateCopy(@aString[1], Length(aString));

    Create(strm, TEncoding.Utf8);
  end;


  destructor TTextReader.Destroy;
  begin
    Freemem(fBuffer);
    FreeMem(fData);

    inherited;
  end;


  function TTextReader.get_EOF: Boolean;
  begin
    result := EOF;
  end;


  function TTextReader.get_Source: IStream;
  begin
    result := fSourceIntf;
  end;


  function TTextReader.get_SourceEncoding: TEncoding;
  begin
    result := fSourceEncoding;
  end;


  function TTextReader.MakeDataAvailable: Boolean;
  begin
    result := TRUE;

    // We still have data from the previous read/decode
    if (fDataRemaining > 0) then
      EXIT;

    // Need to read (and possibly decode) another block
    ReadData;

    fDataCurrent := fData;

    fEOF    := fDataRemaining = 0;
    result  := NOT fEOF;
  end;


  procedure TTextReader.ReadSourceAndDecodeIntoData;
  var
    maxBufferBytesToRead: Integer;
    inputBufferAddress: Pointer;
    bufferBytesAvailable: Integer;
    bufferBytesDecoded: Integer;
    dataBytes: Integer;
  begin
    if (fBufferRemaining > 0) then
    begin
      Memory.Copy(Memory.Offset(fBuffer, INPUT_BUFFER_SIZE - fBufferRemaining), fBufferRemaining, fBuffer);

      maxBufferBytesToRead  := INPUT_BUFFER_SIZE - fBufferRemaining;
      inputBufferAddress    := Memory.Offset(fBuffer, fBufferRemaining);
    end
    else
    begin
      maxBufferBytesToRead  := INPUT_BUFFER_SIZE;
      inputBufferAddress    := fBuffer;
    end;
    bufferBytesAvailable := fSource.Read(inputBufferAddress^, maxBufferBytesToRead) + fBufferRemaining;

    Decode(fBuffer, bufferBytesAvailable, fData, fDataSize, bufferBytesDecoded, dataBytes);

    fBufferRemaining  := bufferBytesAvailable - bufferBytesDecoded;
    fDataRemaining    := dataBytes;
  end;


  procedure TTextReader.ReadSourceDirectlyIntoData;
  begin
    fDataRemaining := fSource.Read(fData^, INPUT_BUFFER_SIZE);
  end;


  function TTextReader.ReadByte: Byte;
  begin
    if NOT MakeDataAvailable then
      raise Exception.Create('EOF');

    result := fDataCurrent^;

    Inc(fDataCurrent);
    Dec(fDataRemaining);

    fEOF := (fDataRemaining = 0) and (fBufferRemaining = 0) and (fSource.Position = fSource.Size);
  end;


  function TTextReader.ReadWord: Word;
  begin
    if NOT MakeDataAvailable then
      raise Exception.Create('EOF');

    result := PWord(fDataCurrent)^;

    Inc(fDataCurrent, 2);
    Dec(fDataRemaining, 2);

    fEOF := (fDataRemaining = 0) and (fBufferRemaining = 0) and (fSource.Position = fSource.Size);
  end;


  procedure TTextReader.SetDecoder(const aDecoderMethod: TDecoderMethod);
  begin
    if Assigned(fDecoderMethod) and Assigned(aDecoderMethod)
     and NOT CompareMem(@fDecoderMethod, @aDecoderMethod, sizeof(TMethod)) then
      raise ENotSupported.Create('Cannot change decoder methods');

    fDecoderMethod := aDecoderMethod;

    FreeMem(fBuffer);
    FreeMem(fData);

    if Assigned(aDecoderMethod) then
    begin
      GetMem(fBuffer, INPUT_BUFFER_SIZE);
      GetMem(fData, INPUT_BUFFER_SIZE * 4); // When decoding, the decoded data may be up to 4x
                                            //  the input size (utf8 -> utf32, each byte becomes 4 bytes).
                                            //
                                            // It will typically be smaller, but since we don't know
                                            //  what encoding the input uses or what encoding the
                                            //  decoded data will use, we allocate the maximum possible.

      fDataSize := INPUT_BUFFER_SIZE * 4;

      fReadSourceMethod := ReadSourceAndDecodeIntoData;
    end
    else // No decoder => no input buffer required; data will be read directly into data buffer
    begin
      GetMem(fData, INPUT_BUFFER_SIZE);

      fReadSourceMethod := ReadSourceDirectlyIntoData;
    end;
  end;


  procedure TTextReader.AfterConstruction;
  var
    detectedEncoding: TEncoding;
  begin
    inherited;

    if TEncoding.Identify(fSource, detectedEncoding) then
      if Assigned(fSourceEncoding) and (detectedEncoding <> fSourceEncoding) then
        raise Exception.Create('Unexpected stream encoding');

    if Assigned(detectedEncoding) and NOT Assigned(fSourceEncoding) then
      fSourceEncoding := detectedEncoding;

    if NOT Assigned(fSourceEncoding) then
      raise Exception.Create('No encoding detected or specified');

    SetDecoder(NIL);
  end;





end.
