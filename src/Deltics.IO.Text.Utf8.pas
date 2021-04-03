
{$i deltics.IO.text.inc}

  unit Deltics.IO.Text.Utf8;


interface

  uses
    Deltics.StringTypes,
    Deltics.IO.Text.TextReader,
    Deltics.IO.Text.Interfaces,
    Deltics.IO.Text.Types;


  type
    TUtf8Reader = class(TTextReader, IUtf8Reader)
    // ITextReader
    protected
      function get_EOF: Boolean; override;
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
      function ReadLine: Utf8String;
      procedure Skip(const aNumChars: Integer);
      procedure SkipWhitespace;
      procedure SkipChar;

    private
      fLoSurrogate: WideChar;
      fPrevChar: Utf8Char;
      fActiveEOF: TEofMethod;
      fActiveReader: TUtf8CharReaderMethod;
      fActiveWideCharReader: TWideCharReaderMethod;

      fLocation: TCharLocation;
      fPrevLocation: TCharLocation;
      fActiveLocation: PCharLocation;

      function _InheritedEOF: Boolean;
      function _NotEOF: Boolean;
      function _ReadPrevChar: Utf8Char;
      function _ReadUtf8Char: Utf8Char;
      function _ReadError: Utf8Char;
      function _ReadWideChar: WideChar;
      function _ReadLoSurrogate: WideChar;
      procedure DecodeUtf16Be(const aInputBuffer: Pointer; const aInputBytes: Integer; const aDecodeBuffer: Pointer; const aMaxDecodedBytes: Integer; var aInputBytesDecoded: Integer; var aDecodedBytes: Integer);
      procedure DecodeUtf16(const aInputBuffer: Pointer; const aInputBytes: Integer; const aDecodeBuffer: Pointer; const aMaxDecodedBytes: Integer; var aInputBytesDecoded: Integer; var aDecodedBytes: Integer);
    protected
      property Location: PCharLocation read fActiveLocation;
      property EOF: TEofMethod read fActiveEOF;
      property ReadChar: TUtf8CharReaderMethod read fActiveReader;
      property ReadWideChar: TWideCharReaderMethod read fActiveWideCharReader;
    public
      procedure AfterConstruction; override;
(*
      function NextRealChar(var aWhitespace: String): Utf8Char; overload; virtual;
      function NextWideChar(var aWhitespace: String): WideChar; overload; virtual;
      function PeekRealChar(var aWhitespace: String): Utf8Char; overload;
      procedure SkipWhitespace(var aWhitespace: String); overload;
*)
    end;




implementation

  uses
    SysUtils,
    Deltics.Exceptions,
    Deltics.Memory,
    Deltics.StringEncodings,
    Deltics.Unicode;


  type
    TEncoding = Deltics.StringEncodings.TEncoding;
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

    fActiveEOF            := _InheritedEOF;
    fActiveReader         := _ReadUtf8Char;
    fActiveWideCharReader := _ReadWideChar;
    fActiveLocation       := @fLocation;

    case SourceEncoding.Codepage of
      cpUtf16   : SetDecoder(DecodeUtf16Be);
      cpUtf16Le : SetDecoder(DecodeUtf16);
      cpUtf8    : SetDecoder(NIL);
    else
      raise ENotSupported.Create('Utf8Reader does not support reading from sources with encoding ' + IntToStr(SourceEncoding.Codepage));
    end;

    fLocation.Line  := 1;
  end;



  procedure TUtf8Reader.DecodeUtf16Be(const aInputBuffer: Pointer;
                                      const aInputBytes: Integer;
                                      const aDecodeBuffer: Pointer;
                                      const aMaxDecodedBytes: Integer;
                                      var   aInputBytesDecoded: Integer;
                                      var   aDecodedBytes: Integer);
  var
    inBuf: PWideChar;
    outBuf: PUtf8Char;
    inChars: Integer;
    outChars: Integer;
  begin
    inBuf   := PWideChar(aInputBuffer);
    outBuf  := PUtf8Char(aDecodeBuffer);

    inChars   := aInputBytes div 2;
    outChars  := aMaxDecodedBytes;

    Unicode.Utf16BeToUtf8(inBuf, inChars, outBuf, outChars);

    aInputBytesDecoded  := aInputBytes - (inChars * 2);
    aDecodedBytes       := aMaxDecodedBytes - outChars;
  end;


  procedure TUtf8Reader.DecodeUtf16(const aInputBuffer: Pointer;
                                    const aInputBytes: Integer;
                                    const aDecodeBuffer: Pointer;
                                    const aMaxDecodedBytes: Integer;
                                    var   aInputBytesDecoded: Integer;
                                    var   aDecodedBytes: Integer);
  var
    inBuf: PWideChar;
    outBuf: PUtf8Char;
    inChars: Integer;
    outChars: Integer;
  begin
    inBuf   := PWideChar(aInputBuffer);
    outBuf  := PUtf8Char(aDecodeBuffer);

    inChars   := aInputBytes div 2;
    outChars  := aMaxDecodedBytes;

    Unicode.Utf16ToUtf8(inBuf, inChars, outBuf, outChars);

    aInputBytesDecoded  := aInputBytes - (inChars * 2);
    aDecodedBytes       := aMaxDecodedBytes - outChars;
  end;


  function TUtf8Reader.get_EOF: Boolean;
  begin
    result := fActiveEOF;
  end;


  function TUtf8Reader.get_Location: TCharLocation;
  begin
    result := Location^;
  end;


  procedure TUtf8Reader.MoveBack;
  begin
    fActiveEOF      := _NotEOF;
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
    ic: Integer;
  begin
    SetLength(result, 2048);
    ic := 0;
    currentLine := Location.Line;

    while (Location.Line = currentLine) and NOT EOF do
    begin
      if (ic = Length(result)) then
        SetLength(result, ic * 2);

      c := NextChar;
      case c of
        #10..#12  : CONTINUE;
        #13       : begin
                      c := NextChar;
                      if c <> #10 then
                        MoveBack;
                    end;
      else
        Inc(ic);
        result[ic] := c;
      end;
    end;

    SetLength(result, ic);
  end;


  function TUtf8Reader._InheritedEOF: Boolean;
  begin
    result := inherited EOF;
  end;


  function TUtf8Reader._NotEOF: Boolean;
  begin
    result := FALSE;
  end;


  function TUtf8Reader._ReadError: Utf8Char;
  begin
    raise Exception.Create('Reading a Utf8 character is invalid when the reader is in this state (Lo Surrogate expected, following NextWideChar)');
  end;


  function TUtf8Reader._ReadUtf8Char: Utf8Char;
  begin
    result := Utf8Char(ReadByte);

    Memory.Copy(@fLocation, sizeof(TCharLocation), @fPrevLocation);

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

    fActiveEOF      := _InheritedEOF;
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
