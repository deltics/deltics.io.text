
{$i deltics.io.text.inc}

  unit Deltics.io.Text.Unicode;


interface

  uses
    Deltics.Strings,
    Deltics.IO.Text.TextReader,
    Deltics.IO.Text.Interfaces,
    Deltics.IO.Text.Types;


  type
    TWideCharArray = array of WideChar;
    TEOFMethod = function: Boolean of object;
    TReaderMethod = function: WideChar of object;


    TUnicodeReader = class(TTextReader, IUnicodeReader)
    // ITextReader
    protected
      function get_EOF: Boolean; override;
      function get_Location: TCharLocation; override;
    // IUnicodeReader
    protected
      function IsWhitespace(const aChar: WideChar): Boolean;
      function NextChar: WideChar;
      function NextCharAfter(const aFilter: TWideCharFilterFn): WideChar;
      function NextCharSkippingWhitespace: WideChar;
      function PeekChar: WideChar;
      function PeekCharSkippingWhitespace: WideChar;
      procedure Skip(const aNumChars: Integer);
      procedure SkipWhitespace;
      procedure SkipChar;
    private
      fPrevChar: WideChar;
      fActiveEOF: TEOFMethod;
      fActiveReader: TReaderMethod;

      fLocation: TCharLocation;
      fPrevLocation: TCharLocation;
      fActiveLocation: PCharLocation;

      function _InheritedEOF: Boolean;
      function _NotEOF: Boolean;
      function _ReadPrevChar: WideChar;
      function _ReadNextChar: WideChar;
      procedure DecodeUtf8(const aInputBuffer; const aInputBufferSize: Integer; const aDecodedData; const aDecodedDataMaxSize: Integer; var aInputBufferBytesDecoded: Integer; var aDecodedDataActualSize: Integer);
      procedure DecodeUtf16(const aInputBuffer; const aInputBufferSize: Integer; const aDecodedData; const aDecodedDataMaxSize: Integer; var aInputBufferBytesDecoded: Integer; var aDecodedDataActualSize: Integer);

    protected
      property EOF: TEOFMethod read fActiveEOF;
      property ReadChar: TReaderMethod read fActiveReader;
    public
      procedure AfterConstruction; override;
      procedure MoveBack;
      function ReadLine: UnicodeString;
      property Location: PCharLocation read fActiveLocation;
    end;




implementation

  uses
    SysUtils,
    Deltics.Exceptions,
    Deltics.Pointers,
    Deltics.ReverseBytes;


  type
    TEncoding = Deltics.Strings.TEncoding;
    TByteArray = array of Byte;
    TWordArray = array of Word;



  procedure TUnicodeReader.AfterConstruction;
  begin
    inherited;

    fActiveEOF      := _InheritedEOF;
    fActiveReader   := _ReadNextChar;
    fActiveLocation := @fLocation;

    case SourceEncoding.Codepage of
      cpUtf16   : SetDecoder(DecodeUtf16);
      cpUtf16LE : SetDecoder(NIL);
      cpUtf8    : SetDecoder(DecodeUtf8);
    else
      raise ENotSupported.Create('UnicodeReader does not support reading from sources with encoding ' + IntToStr(SourceEncoding.Codepage));
    end;

    fLocation.Line  := 1;
  end;



(*
  procedure TUtf8TextReader.DecodeMBCS;
  begin
  end;
  var
    i: Integer;
    dp: Integer;
    s: ANSIString;
    b: Byte;
    wc: array of WideChar;
    wcLen: Integer;
  begin
    SetLength(fUtf8, fUtf8Size + (3 * fBufferSize));

    dp  := fUtf8Pos;
    i   := 0;
    while (i < fBufferSize) do
    begin
      b := Byte(fBuffer[i]);

      if (b < $80) then
      begin
        fUtf8[dp] := Utf8Char(b);
        Inc(dp);
        Inc(i);
        CONTINUE;
      end;

      s := '';
      while (b >= $80) do
      begin
        s := s + ANSIChar(b);
        Inc(i);

        if (i = fBufferSize) then
        begin
          if (fBufferSize < fBlockSize) then
            BREAK;

          ReadBlock;
          if (fBufferSize > 0) then
          begin
            SetLength(fUtf8, dp + (3 * fBufferSize));
            i := 0;
          end;
        end;

        b := Byte(fBuffer[i]);
      end;
      SetLength(wc, Length(s) * 2);
      wcLen := MultiByteToWideChar(fCodePage, 0, @s[1], Length(s), @wc[0], Length(wc));
      Move(wc[0], fUtf8[dp], wcLen * 2);
      Inc(dp, wcLen);
    end;

    SetLength(fUtf8, dp);
    fUtf8Size := dp;
  end;
*)

(*
  function TUtf8TextReader.DecodeUTF16BE: Integer;
  type
    PByte = array of Byte;
    TWordArray = array of Word;
  var
    i: Integer;
    dp: Integer;
    wc: Word;
  begin
    if NOT Assigned(fData) then
      GetMem(fData, fBufferSize);

    dp := 0;
    for i := 0 to Pred(fBufferSize) div 2 do
    begin
      wc := Swap(TWordArray(fBuffer)[i]);

      case wc of
        $0000..$007f  : begin
                          PByte(fData)[dp] := Byte(wc);
                          Inc(dp);
                        end;

        $0080..$07ff  : begin
                          PByte(fData)[dp]     := Byte($c0 or (wc shr 6));
                          PByte(fData)[dp + 1] := Byte($80 or (wc and $3f));
                          Inc(dp, 2);
                        end;

        $0800..$ffff  : begin
                          PByte(fData)[dp]     := Byte($e0 or (wc shr 12));
                          PByte(fData)[dp + 1] := Byte($80 or ((wc shr 6) and $3f));
                          PByte(fData)[dp + 2] := Byte($80 or (wc and $3f));
                          Inc(dp, 3);
                        end;

        //TODO: Correctly decode surrogate pairs
      end;
    end;

    result := dp;
  end;


  function TUtf8TextReader.DecodeUTF16LE: Integer;
  type
    PByte = array of Byte;
    TWordArray = array of Word;
  var
    i: Integer;
    dp: Integer;
    wc: Word;
  begin
    if NOT Assigned(fData) then
      GetMem(fData, fBufferSize);

    dp := 0;
    for i := 0 to Pred(fBufferLimit) div 2 do
    begin
      wc := TWordArray(fBuffer)[i];

      case wc of
        $0000..$007f  : begin
                          PByte(fData)[dp] := Byte(wc);
                          Inc(dp);
                        end;

        $0080..$07ff  : begin
                          PByte(fData)[dp]     := Byte($c0 or (wc shr 6));
                          PByte(fData)[dp + 1] := Byte($80 or (wc and $3f));
                          Inc(dp, 2);
                        end;

        $0800..$ffff  : begin
                          PByte(fData)[dp]     := Byte($e0 or (wc shr 12));
                          PByte(fData)[dp + 1] := Byte($80 or ((wc shr 6) and $3f));
                          PByte(fData)[dp + 2] := Byte($80 or (wc and $3f));
                          Inc(dp, 3);
                        end;

        //TODO: Correctly decode surrogate pairs
      end;
    end;

    result := dp;
  end;
*)

  procedure TUnicodeReader.DecodeUtf16(const aInputBuffer;
                                       const aInputBufferSize: Integer;
                                       const aDecodedData;
                                       const aDecodedDataMaxSize: Integer;
                                       var aInputBufferBytesDecoded: Integer;
                                       var aDecodedDataActualSize: Integer);
  begin
    Memory.Copy(@aInputBuffer, @aDecodedData, aInputBufferSize);
    ReverseBytes(PWord(@aDecodedData), aInputBufferSize div 2);
  end;


  procedure TUnicodeReader.DecodeUtf8(const aInputBuffer;
                                      const aInputBufferSize: Integer;
                                      const aDecodedData;
                                      const aDecodedDataMaxSize: Integer;
                                      var   aInputBufferBytesDecoded: Integer;
                                      var   aDecodedDataActualSize: Integer);

  var
    buffer: PByteArray;
    bufIdx: Integer;
    bufRemain: Integer;

    function GetByte: Byte;
    begin
      result := buffer[bufIdx];
      Inc(bufIdx);
      Dec(bufRemain);
    end;

    function GetBufferCodepoint(var aCodepoint: Integer): Boolean;
    var
      b1, b2, b3, b4: Byte;
    begin
      result := bufRemain > 0;
      if NOT result then
        EXIT;

      b1 := GetByte;

      result := (b1 and $80) = $00;
      if result then
      begin
        aCodepoint := Integer(b1);
        EXIT;
      end;

      try
        case b1 and $f0 of
          $c0,                                // 1100
          $d0 : begin                         // 1101
                  if bufRemain = 0 then
                    EXIT;

                  b2          := GetByte;
                  aCodepoint  := ((b1 and $1f) shl 6)
                               or (b2 and $3f);
                end;

          $e0 : begin                         // 1110
                  if bufRemain < 2 then
                    EXIT;

                  b2 := GetByte;
                  b3 := GetByte;
                  aCodepoint  := ((b1 and $0f) shl 12)
                              or ((b2 and $3f) shl 6)
                              or  (b3 and $3f);
                end;

          $f0 : begin                         // 11110
                  if bufRemain < 3 then
                    EXIT;

                  b2 := GetByte;
                  b3 := GetByte;
                  b4 := GetByte;
                  aCodepoint := ((b1 and $0f) shl 18)
                             or ((b2 and $3f) shl 12)
                             or ((b3 and $3f) shl 6)
                             or  (b4 and $3f);
                end;
        else
          raise Exception.Create('Not a valid Utf8 encoded stream');
        end;
        result := TRUE;

      finally
        if NOT result then
          Dec(bufIdx);
      end;
    end;

  var
    data: PWideChar;
    codepoint: Integer;
    dataIdx: Integer;
  begin
    buffer  := PByteArray(@aInputBuffer);
    data    := PWideChar(@aDecodedData);

    bufIdx    := 0;
    bufRemain := aInputBufferSize;
    dataIdx   := 0;

    while GetBufferCodepoint(codepoint) do
    begin
      if codepoint < $10000 then
      begin
        data[dataIdx] := WideChar(codepoint);
        Inc(dataIdx);
        CONTINUE;
      end;

      codepoint := codepoint - $10000;

      data[dataIdx]     := WideChar($d800 or ((codepoint shr 10) and $03ffff));
      data[dataIdx + 1] := WideChar($dc00 or (codepoint and $03ffff));

      Inc(dataIdx, 2);
    end;

    aInputBufferBytesDecoded  := bufIdx;
    aDecodedDataActualSize    := dataIdx * 2;
  end;


  function TUnicodeReader.get_EOF: Boolean;
  begin
    result := fActiveEOF;
  end;


  function TUnicodeReader.get_Location: TCharLocation;
  begin
    result := Location^;
  end;


  procedure TUnicodeReader.MoveBack;
  begin
    fActiveEOF      := _NotEOF;
    fActiveReader   := _ReadPrevChar;
    fActiveLocation := @fPrevLocation;
  end;


  function TUnicodeReader.NextChar: WideChar;
  begin
    result := ReadChar;
  end;


  function TUnicodeReader.IsWhitespace(const aChar: WideChar): Boolean;
  begin
    result := ((Word(aChar) and $ff00) = 0) and (AnsiChar(aChar) in [#9, #10, #11, #12, #13, #32]);
  end;


  function TUnicodeReader.NextCharAfter(const aFilter: TWideCharFilterFn): WideChar;
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


  function TUnicodeReader.NextCharSkippingWhitespace: WideChar;
  begin
    result := NextCharAfter(IsWhitespace);
  end;


  function TUnicodeReader.PeekChar: WideChar;
  begin
    result := NextChar;
    MoveBack;
  end;


  function TUnicodeReader.PeekCharSkippingWhitespace: WideChar;
  begin
    result := NextCharSkippingWhitespace;
    MoveBack;
  end;


  function TUnicodeReader.ReadLine: UnicodeString;
  var
    currentLine: Integer;
    c: WideChar;
  begin
    result := '';
    currentLine := Location.Line;

    while (Location.Line = currentLine) and NOT EOF do
    begin
      c := NextChar;
      case Word(c) of
        10..12  : CONTINUE;
        13      : begin
                    c := NextChar;
                    if c <> #10 then
                      MoveBack;
                  end;
      else
        result := result + c;
      end;
    end;
  end;


  function TUnicodeReader._InheritedEOF: Boolean;
  begin
    result := inherited EOF;
  end;


  function TUnicodeReader._NotEOF: Boolean;
  begin
    result := FALSE;
  end;


  function TUnicodeReader._ReadNextChar: WideChar;
  begin
    result := WideChar(ReadWord);

    Memory.Copy(@fLocation, @fPrevLocation, sizeof(TCharLocation));

    if Word(result) < $0080 then                                        // IsAscii
    begin
      case Word(result) of
        10       : if Word(fPrevChar) <> 13 then
                    begin
                      Inc(fLocation.Line);
                      fLocation.Character := 0;
                    end;

        11..13  : begin
                      Inc(fLocation.Line);
                      fLocation.Character := 0;
                    end;
      else
        Inc(fLocation.Character);
      end;
    end
    else if (Word(result) >= $dc00) and (Word(result) <= $dfff) then  // IsLoSurrogate
      Inc(fLocation.Character);

    fActiveLocation := @fLocation;
    fPrevChar       := result;
  end;


  function TUnicodeReader._ReadPrevChar: WideChar;
  begin
    result := fPrevChar;

    fActiveEOF      := _InheritedEOF;
    fActiveReader   := _ReadNextChar;
    fActiveLocation := @fLocation;
  end;


  procedure TUnicodeReader.Skip(const aNumChars: Integer);
  var
    i: Integer;
  begin
    for i := 1 to aNumChars do
      SkipChar;
  end;


  procedure TUnicodeReader.SkipChar;
  begin
    NextChar;
  end;


  procedure TUnicodeReader.SkipWhitespace;
  begin
    NextCharSkippingWhitespace;
    if NOT EOF then
      MoveBack;
  end;



(*
  function TUtf8TextReader.NextRealChar(var aWhitespace: String): Utf8Char;
  var
    remaining: integer;
  begin
    aWhitespace := '';

    remaining := MakeDataAvailable;
    while NOT fEOF do
    begin
      result := fUtf8[fUtf8Pos];
      IncPos(remaining);

      if NOT (result in fWhitespace) then
        EXIT;

      aWhitespace := aWhitespace + STR.FromUtf8(result);
    end;

    // If we reach this point then EOF is TRUE - we found nothing but whitespace
    result := #0;
  end;


  procedure TUtf8TextReader.SkipWhitespace(var aWhitespace: String);
  var
    l: Integer;
    c: Utf8Char;
    s: Utf8String;
    remaining: integer;
  begin
    l := 0;
    s := '';

    remaining := MakeDataAvailable;
    while NOT fEOF do
    begin
      c := fUtf8[fUtf8Pos];
      IncPos(remaining);

      if (c in fWhitespace) then
      begin
        Inc(l);
        if (l > Length(s)) then
          SetLength(s, Length(s) + 256);

        s[l] := c;
      end
      else
      begin
        SetLength(s, l);
        aWhitespace := STR.FromUtf8(s);
        MoveBack;
        EXIT;
      end;
    end;

    // If we reach this point then EOF is TRUE - we found nothing but whitespace
  end;


  function TUtf8TextReader.PeekRealChar(var aWhitespace: String): Utf8Char;
  begin
    result := NextRealChar(aWhitespace);
    MoveBack;
  end;


  function TUtf8TextReader.NextWideChar(var aWhitespace: String): WideChar;
  begin
    while NOT fEOF do
    begin
      result := NextWideChar;

      if NOT (ANSIChar(result) in fWhitespace) then
        EXIT;

      aWhitespace := aWhitespace + result;
    end;

    result := #0;
  end;

*)



end.
