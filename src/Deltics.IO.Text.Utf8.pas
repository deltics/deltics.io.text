
{$i deltics.io.text.inc}

  unit Deltics.IO.Text.Utf8;


interface

  uses
    Deltics.Strings,
    Deltics.IO.Text.TextReader,
    Deltics.IO.Text.Interfaces,
    Deltics.IO.Text.Types;


  type
    TCharArray = array of Utf8Char;
    TReaderMethod = function: Utf8Char of object;
    TWideCharReaderMethod = function: WideChar of object;


    TUtf8Reader = class(TTextReader, IUtf8Reader)
    // ITextReader
    protected
      function get_Location: TCharLocation; override;
    // IUtf8Reader
    protected
      procedure MoveBack;
      function IsWhitespace(const aChar: Utf8Char): Boolean;
      function NextChar: Utf8Char;
      function NextCharAfter(const aFilter: TUtf8CharFilterFn): Utf8Char;
      function NextCharSkippingWhitespace: Utf8Char;
      function NextCodePoint: Integer;
      function NextWideChar: WideChar;
      function PeekChar: Utf8Char;
      function PeekCharSkippingWhitespace: Utf8Char;
      procedure Skip(const aNumChars: Integer);
      procedure SkipWhitespace;
      procedure SkipChar;

    private
      fLoSurrogate: WideChar;
      fPrevChar: Utf8Char;
      fActiveReader: TReaderMethod;
      fActiveWideCharReader: TWideCharReaderMethod;

      fLocation: TCharLocation;
      fPrevLocation: TCharLocation;
      fActiveLocation: PCharLocation;

      function _ReadPrevChar: Utf8Char;
      function _ReadUtf8Char: Utf8Char;
      function _ReadError: Utf8Char;
      function _ReadWideChar: WideChar;
      function _ReadLoSurrogate: WideChar;
      procedure DecodeUtf16(const aInputBuffer; const aInputBufferSize: Integer; const aDecodedData; const aDecodedDataMaxSize: Integer; var aInputBufferBytesDecoded: Integer; var aDecodedDataActualSize: Integer);
      procedure DecodeUtf16LE(const aInputBuffer; const aInputBufferSize: Integer; const aDecodedData; const aDecodedDataMaxSize: Integer; var aInputBufferBytesDecoded: Integer; var aDecodedDataActualSize: Integer);

    protected
      property ReadChar: TReaderMethod read fActiveReader;
      property ReadWideChar: TWideCharReaderMethod read fActiveWideCharReader;
    public
      procedure AfterConstruction; override;
(*
      function NextRealChar(var aWhitespace: String): Utf8Char; overload; virtual;
      function NextWideChar(var aWhitespace: String): WideChar; overload; virtual;
      function PeekRealChar(var aWhitespace: String): Utf8Char; overload;
      procedure SkipWhitespace(var aWhitespace: String); overload;
*)
      function ReadLine: Utf8String;
      property Location: PCharLocation read fActiveLocation;
    end;




implementation

  uses
    SysUtils,
    Deltics.Exceptions,
    Deltics.Pointers;


  type
    TEncoding = Deltics.Strings.TEncoding;
    TByteArray = array of Byte;
    TWordArray = array of Word;



(*
  procedure TUtf8TextReader.Advance(const aChars: Integer);
  begin
    Inc(fDataCurrent, aChars);
    Dec(fDataRemaining, aChars);

    if fDataRemaining = 0 then
      MakeDataAvailable;
  end;
*)

  procedure TUtf8Reader.AfterConstruction;
  begin
    inherited;

    fActiveReader         := _ReadUtf8Char;
    fActiveWideCharReader := _ReadWideChar;
    fActiveLocation       := @fLocation;

    case SourceEncoding.Codepage of
      cpUtf16   : SetDecoder(DecodeUtf16);
      cpUtf16LE : SetDecoder(DecodeUtf16LE);
      cpUtf8    : SetDecoder(NIL);
    else
      raise ENotSupported.Create('Utf8Reader does not support reading from sources with encoding ' + IntToStr(SourceEncoding.Codepage));
    end;

    fLocation.Line  := 1;
  end;



  procedure TUtf8Reader.DecodeUtf16(const aInputBuffer;
                                        const aInputBufferSize: Integer;
                                        const aDecodedData;
                                        const aDecodedDataMaxSize: Integer;
                                        var aInputBufferBytesDecoded: Integer;
                                        var aDecodedDataActualSize: Integer);
  var
    input: TWordArray absolute aInputBuffer;
    data: TByteArray absolute aDecodedData;
    i: Integer;
    dp: Integer;
    wc: Word;
  begin

    dp := 0;
    for i := 0 to Pred(aInputBufferSize) div 2 do
    begin
      wc := input[i];

      case wc of
        $0000..$007f  : begin
                          data[dp] := Byte(wc);
                          Inc(dp);
                        end;

        $0080..$07ff  : begin
                          data[dp]     := Byte($c0 or (wc shr 6));
                          data[dp + 1] := Byte($80 or (wc and $3f));
                          Inc(dp, 2);
                        end;

        $0800..$ffff  : begin
                          data[dp]     := Byte($e0 or (wc shr 12));
                          data[dp + 1] := Byte($80 or ((wc shr 6) and $3f));
                          data[dp + 2] := Byte($80 or (wc and $3f));
                          Inc(dp, 3);
                        end;

        //TODO: Correctly decode surrogate pairs
      end;
    end;

    aInputBufferBytesDecoded  := aInputBufferSize;
    aDecodedDataActualSize    := dp;
  end;


  procedure TUtf8Reader.DecodeUtf16LE(const aInputBuffer;
                                          const aInputBufferSize: Integer;
                                          const aDecodedData;
                                          const aDecodedDataMaxSize: Integer;
                                          var aInputBufferBytesDecoded: Integer;
                                          var aDecodedDataActualSize: Integer);
  var
    input: PWordArray;
    data: PByteArray;
    i: Integer;
    dp: Integer;
    wc: Word;
  begin
    input := PWordArray(@aInputBuffer);
    data  := PByteArray(@aDecodedData);

    dp := 0;
    for i := 0 to Pred(aInputBufferSize) div 2 do
    begin
      wc := input[i];

      case wc of
        $0000..$007f  : begin
                          data[dp] := Byte(wc);
                          Inc(dp);
                        end;

        $0080..$07ff  : begin
                          data[dp]     := Byte($c0 or (wc shr 6));
                          data[dp + 1] := Byte($80 or (wc and $3f));
                          Inc(dp, 2);
                        end;

        $0800..$ffff  : begin
                          data[dp]     := Byte($e0 or (wc shr 12));
                          data[dp + 1] := Byte($80 or ((wc shr 6) and $3f));
                          data[dp + 2] := Byte($80 or (wc and $3f));
                          Inc(dp, 3);
                        end;

        //TODO: Correctly decode surrogate pairs and handle split pairs at buffer boundaries
        //       (i.e. when the last 2 bytes in the input buffer are a hi-surrogate with the
        //       lo-surrogate of the pair inaccessible [in the _next_ input buffer])
      end;
    end;

    aInputBufferBytesDecoded  := aInputBufferSize;
    aDecodedDataActualSize    := dp;
  end;


  function TUtf8Reader.get_Location: TCharLocation;
  begin
    result := Location^;
  end;


  procedure TUtf8Reader.MoveBack;
  begin
    fActiveReader   := _ReadPrevChar;
    fActiveLocation := @fPrevLocation;
  end;


  function TUtf8Reader.NextChar: Utf8Char;
  begin
    result := ReadChar;
  end;


  function TUtf8Reader.IsWhitespace(const aChar: Utf8Char): Boolean;
  begin
    result := aChar in [#9, #10, #11, #12, #13, #32];
  end;


  function TUtf8Reader.NextCharAfter(const aFilter: TUtf8CharFilterFn): Utf8Char;
  begin
    while NOT EOF do
    begin
      result := ReadChar;
      if NOT aFilter(result) then
        EXIT;
    end;

    // If we reach this point then EOF is TRUE and we found nothing but whitespace
    result := #0;
  end;


  function TUtf8Reader.NextCharSkippingWhitespace: Utf8Char;
  begin
    result := NextCharAfter(IsWhitespace);
  end;


  function TUtf8Reader.NextCodePoint: Integer;
  var
    b1, b2, b3, b4: Byte;
  begin
    b1 := Byte(NextChar);

    if (b1 and $80) = $00 then
    begin
      result := Integer(b1);
      EXIT;
    end;

    case b1 and $f0 of
      $c0,                                // 1100
      $d0 : begin                         // 1101
              b2     := Byte(NextChar);
              result := ((b1 and $1f) shl 6)
                      or (b2 and $3f);
            end;

      $e0 : begin                         // 1110
              b2     := Byte(NextChar);
              b3     := Byte(NextChar);
              result := ((b1 and $0f) shl 12)
                     or ((b2 and $3f) shl 6)
                     or  (b3 and $3f);
            end;
      $f0 : begin                         // 11110
              b2     := Byte(NextChar);
              b3     := Byte(NextChar);
              b4     := Byte(NextChar);
              result := ((b1 and $0f) shl 18)
                     or ((b2 and $3f) shl 12)
                     or ((b3 and $3f) shl 6)
                     or  (b4 and $3f);
            end;
    else
      raise Exception.Create('Not a valid Utf8 encoded stream');
    end;
  end;


  function TUtf8Reader.NextWideChar: WideChar;
  begin
    result := fActiveWideCharReader;
  end;


  function TUtf8Reader.PeekChar: Utf8Char;
  begin
    result := NextChar;
    MoveBack;
  end;


  function TUtf8Reader.PeekCharSkippingWhitespace: Utf8Char;
  begin
    result := NextCharSkippingWhitespace;
    MoveBack;
  end;


  function TUtf8Reader.ReadLine: Utf8String;
  var
    currentLine: Integer;
    c: Utf8Char;
  begin
    result := '';
    currentLine := Location.Line;

    while (Location.Line = currentLine) and NOT EOF do
    begin
      c := NextChar;
      case c of
        #10..#12  : CONTINUE;
        #13       : begin
                      c := NextChar;
                      if c <> #10 then
                        MoveBack;
                    end;
      else
        result := Utf8.Append(result, c);
      end;
    end;
  end;


  function TUtf8Reader._ReadError: Utf8Char;
  begin
    raise Exception.Create('Reading a Ut8 character is invalid when the reader is in this state');
  end;


  function TUtf8Reader._ReadUtf8Char: Utf8Char;
  begin
    result    := Utf8Char(ReadByte);

    Memory.Copy(@fLocation, @fPrevLocation, sizeof(TCharLocation));

    case result of
      #10       : if fPrevChar <> #13 then
                  begin
                    Inc(fLocation.Line);
                    fLocation.Character := 0;
                  end;

      #11..#13  : begin
                    Inc(fLocation.Line);
                    fLocation.Character := 0;
                  end;
    else
      Inc(fLocation.Character);
    end;

    fActiveLocation := @fLocation;
    fPrevChar       := result;
  end;


  function TUtf8Reader._ReadLoSurrogate: WideChar;
  begin
    result := fLoSurrogate;

    fLoSurrogate  := #0;
    fActiveReader := _ReadUtf8Char;
  end;


  function TUtf8Reader._ReadPrevChar: Utf8Char;
  begin
    result := fPrevChar;

    fActiveReader   := _ReadUtf8Char;
    fActiveLocation := @fLocation;
  end;


  function TUtf8Reader._ReadWideChar: WideChar;
  var
    codepoint: Cardinal;
    hi: Word;
    lo: Word;
  begin
    codepoint := NextCodepoint;

    if codepoint < $10000 then
    begin
      result := WideChar(codepoint);
      EXIT;
    end;

    codepoint := codepoint - $10000;

    hi := $d800 or ((codepoint shr 10) and $03ffff);
    lo := $dc00 or (codepoint and $03ffff);

    result        := WideChar(hi);
    fLoSurrogate  := WideChar(lo);

    fActiveWideCharReader := _ReadLoSurrogate;
    fActiveReader         := _ReadError;
  end;


  procedure TUtf8Reader.Skip(const aNumChars: Integer);
  var
    i: Integer;
  begin
    for i := 1 to aNumChars do
      NextChar;
  end;


  procedure TUtf8Reader.SkipChar;
  begin
    NextChar;
  end;


  procedure TUtf8Reader.SkipWhitespace;
  begin
    NextCharSkippingWhitespace;
    if NOT EOF then
      MoveBack;
  end;





end.
