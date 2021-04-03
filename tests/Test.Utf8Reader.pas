
{$i deltics.inc}

  unit Test.Utf8Reader;


interface

  uses
    Deltics.Smoketest;


  type
    Utf8Reader = class(TTest)
      procedure ReadsUtf8StringToEnd;
      procedure ReadsUtf8StringToEndIgnoringAsciiWhitespace;
      procedure ReadsWideStringToEnd;
      procedure MoveBackRereadsCharacterPreviouslyRead;
      procedure LocationReportsLine1Character5For5CharactersOnFirstLine;
      procedure LocationReportsLine1Character5For5CharactersOnFirstLineSkippingWhitespace;
      procedure LocationReportsLine2Character1AfterReadingFirstCharacterAfterCR;
      procedure LocationReportsLine2Character1AfterReadingFirstCharacterAfterCRLF;
      procedure NextWideCharDecodesTrailBytesCorrectly;
      procedure NextWideCharDecodesSurrogatesCorrectly;
      procedure ReadLineReadsSingleLine;
      procedure ReadLineReadsBlankLinesWithCR;
      procedure ReadLineReadsBlankLinesWithCRLF;
      procedure ReadLineReadsMultipleLinesWithCR;
      procedure ReadLineReadsMultipleLinesWithCRLF;
      procedure EOFIsFalseForProtectedMethodsWhenPreviousCharIsCachedAfterMoveBackAtTheEndOfStream;
      procedure EOFIsFalseWhenPreviousCharIsCachedAfterMoveBackAtTheEndOfStream;
    end;



implementation

  uses
    Deltics.Strings,
    Deltics.IO.Text;


{ UtfReader }

  type TProtectedReader = class(TUtf8Reader);


  procedure Utf8Reader.EOFIsFalseForProtectedMethodsWhenPreviousCharIsCachedAfterMoveBackAtTheEndOfStream;
  var
    src: Utf8String;
    sut: TProtectedReader;
  begin
    src := 'Test';

    sut := TProtectedReader.Create(src);
    sut.Skip(4);

    Test('EOF').Assert(sut.EOF).IsTrue;

    sut.MoveBack;

    Test('EOF').Assert(sut.EOF).IsFALSE;
  end;


  procedure Utf8Reader.EOFIsFalseWhenPreviousCharIsCachedAfterMoveBackAtTheEndOfStream;
  var
    src: Utf8String;
    sut: IUtf8Reader;
  begin
    src := 'Test';

    sut := TUtf8Reader.Create(src);
    sut.Skip(4);

    Test('EOF').Assert(sut.EOF).IsTrue;

    sut.MoveBack;

    Test('EOF (after MoveBack)').Assert(sut.EOF).IsFalse;
    Test('NextChar (after MoveBack)').AssertUtf8(sut.NextChar).Equals('t');

    Test('EOF (after NextChar, after MoveBack)').Assert(sut.EOF).IsTrue;
  end;


  procedure Utf8Reader.LocationReportsLine1Character5For5CharactersOnFirstLine;
  var
    src: Utf8String;
    sut: IUtf8Reader;
    c: Utf8Char;
  begin
    src := 'The quick brown fox'#13'jumped over the lazy dog!';

    sut := TUtf8Reader.Create(src);
    sut.Skip(4);
    c := sut.NextChar;

    Test('c').Assert(c).Equals('q');
    Test('Location.Line').Assert(sut.Location.Line).Equals(1);
    Test('Location.Character').Assert(sut.Location.Character).Equals(5);
  end;



  procedure Utf8Reader.LocationReportsLine1Character5For5CharactersOnFirstLineSkippingWhitespace;
  var
    src: Utf8String;
    sut: IUtf8Reader;
    c: Utf8Char;
  begin
    src := 'The quick brown fox'#13'jumped over the lazy dog!';

    sut := TUtf8Reader.Create(src);
    sut.Skip(3);
    c := sut.NextCharSkippingWhitespace;

    Test('c').Assert(c).Equals('q');
    Test('Location.Line').Assert(sut.Location.Line).Equals(1);
    Test('Location.Character').Assert(sut.Location.Character).Equals(5);
  end;



  procedure Utf8Reader.LocationReportsLine2Character1AfterReadingFirstCharacterAfterCR;
  var
    src: Utf8String;
    sut: IUtf8Reader;
    c: Utf8Char;
  begin
    src := 'The quick brown fox'#13'jumped over the lazy dog!';

    sut := TUtf8Reader.Create(src);
    sut.Skip(19);
    sut.SkipWhitespace;
    c := sut.NextChar;

    Test('c').Assert(c).Equals('j');
    Test('Location.Line').Assert(sut.Location.Line).Equals(2);
    Test('Location.Character').Assert(sut.Location.Character).Equals(1);
  end;



  procedure Utf8Reader.LocationReportsLine2Character1AfterReadingFirstCharacterAfterCRLF;
  var
    src: Utf8String;
    sut: IUtf8Reader;
    c: Utf8Char;
  begin
    src := 'The quick brown fox'#13#10'jumped over the lazy dog!';

    sut := TUtf8Reader.Create(src);
    sut.Skip(19);
    sut.SkipWhitespace;
    c := sut.NextChar;

    Test('c').Assert(c).Equals('j');
    Test('Location.Line').Assert(sut.Location.Line).Equals(2);
    Test('Location.Character').Assert(sut.Location.Character).Equals(1);
  end;



  procedure Utf8Reader.MoveBackRereadsCharacterPreviouslyRead;
  var
    src: Utf8String;
    s: Utf8String;
    sut: IUtf8Reader;
  begin
    src := 'abc';

    sut := TUtf8Reader.Create(src);
    s := Utf8.Append(s, sut.NextChar);
    s := Utf8.Append(s, sut.NextChar);
    sut.MoveBack;
    s := Utf8.Append(s, sut.NextChar);
    s := Utf8.Append(s, sut.NextChar);

    Test('s').Assert(STR.FromUTF8(s)).Equals('abbc');
  end;


  procedure Utf8Reader.NextWideCharDecodesSurrogatesCorrectly;
  {
    For this test we use Unicode codepoint Ux1d11e - the treble clef

      UTF-8 Encoding  :	0xF0 0x9D 0x84 0x9E
      UTF-16 Encoding :	0xD834 0xDD1E
  }
  var
    src: Utf8String;
    hi, lo: WideChar;
    c: Utf8Char;
    sut: IUtf8Reader;
  begin
    src  := 'a????b';
    src[2] := Utf8Char($f0);
    src[3] := Utf8Char($9d);
    src[4] := Utf8Char($84);
    src[5] := Utf8Char($9e);

    sut := TUtf8Reader.Create(src);
    sut.NextChar;
    hi := sut.NextWideChar;
    lo := sut.NextWideChar;
    c := sut.NextChar;

    Test('hi').Assert(Word(hi)).Equals($d834);
    Test('lo').Assert(Word(lo)).Equals($dd1e);
    Test('c').Assert(c).Equals('b');
  end;


  procedure Utf8Reader.NextWideCharDecodesTrailBytesCorrectly;
  var
    src: Utf8String;
    wc: WideChar;
    sut: IUtf8Reader;
  begin
    src  := 'Quick Brown??2020';
    src[12] := Utf8Char($c2);
    src[13] := Utf8Char($a9);

    sut := TUtf8Reader.Create(src);
    sut.Skip(11);

    wc := sut.NextWideChar;

    Test('wc').Assert(Word(wc)).Equals(169);
  end;


  procedure Utf8Reader.ReadLineReadsBlankLinesWithCR;
  const
    LINE1: Utf8String = 'The quick brown fox';
    LINE2: Utf8String = 'jumped over the lazy dog';
  var
    src: Utf8String;
    s1, s2, s3: Utf8String;
    sut: IUtf8Reader;
  begin
    src := LINE1 + #13#13 + LINE2;

    sut := TUtf8Reader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);
    s3  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);

    Test('s1').Assert(STR.FromUtf8(s1)).Equals(STR.FromUtf8(LINE1));
    Test('s2').Assert(STR.FromUtf8(s2)).IsEmpty;
    Test('s3').Assert(STR.FromUtf8(s3)).Equals(STR.FromUtf8(LINE2));
  end;


  procedure Utf8Reader.ReadLineReadsBlankLinesWithCRLF;
  const
    LINE1: Utf8String = 'The quick brown fox';
    LINE2: Utf8String = 'jumped over the lazy dog';
  var
    src: Utf8String;
    s1, s2, s3: Utf8String;
    sut: IUtf8Reader;
  begin
    src := LINE1 + #13#10#13#10 + LINE2;

    sut := TUtf8Reader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);
    s3  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);

    Test('s1').Assert(STR.FromUtf8(s1)).Equals(STR.FromUtf8(LINE1));
    Test('s2').Assert(STR.FromUtf8(s2)).IsEmpty;
    Test('s3').Assert(STR.FromUtf8(s3)).Equals(STR.FromUtf8(LINE2));
  end;


  procedure Utf8Reader.ReadLineReadsMultipleLinesWithCR;
  const
    LINE1: Utf8String = 'The quick brown fox';
    LINE2: Utf8String = 'jumped over the lazy dog';
  var
    src: Utf8String;
    s1, s2: Utf8String;
    sut: IUtf8Reader;
  begin
    src := LINE1 + #13 + LINE2;

    sut := TUtf8Reader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);

    Test('s1').Assert(STR.FromUtf8(s1)).Equals(STR.FromUtf8(LINE1));
    Test('s2').Assert(STR.FromUtf8(s2)).Equals(STR.FromUtf8(LINE2));
  end;


  procedure Utf8Reader.ReadLineReadsMultipleLinesWithCRLF;
  const
    LINE1: Utf8String = 'The quick brown fox';
    LINE2: Utf8String = 'jumped over the lazy dog';
  var
    src: Utf8String;
    s1, s2: Utf8String;
    sut: IUtf8Reader;
  begin
    src := LINE1 + #13#10 + LINE2;

    sut := TUtf8Reader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);

    Test('s1').Assert(STR.FromUtf8(s1)).Equals(STR.FromUtf8(LINE1));
    Test('s2').Assert(STR.FromUtf8(s2)).Equals(STR.FromUtf8(LINE2));
  end;


  procedure Utf8Reader.ReadLineReadsSingleLine;
  var
    src: Utf8String;
    s: Utf8String;
    sut: IUtf8Reader;
  begin
    src := 'The quick brown fox jumped over the lazy dog!';

    sut := TUtf8Reader.Create(src);
    s := sut.ReadLine;

    Test('s').Assert(STR.FromUtf8(s)).Equals(STR.FromUtf8(src));
  end;


  procedure Utf8Reader.ReadsUtf8StringToEnd;
  var
    src: Utf8String;
    s: Utf8String;
    sut: IUtf8Reader;
  begin
    src   := 'The quick brown fox jumped over the lazy dog!';

    sut := TUtf8Reader.Create(src);
    while NOT sut.EOF do
      s := Utf8.Append(s, sut.NextChar);

    Test('').Assert(STR.FromUtf8(s)).Equals(STR.FromUtf8(src));
  end;


  procedure Utf8Reader.ReadsUtf8StringToEndIgnoringAsciiWhitespace;
  var
    src, csrc: Utf8String;
    s: Utf8String;
    sut: IUtf8Reader;
  begin
    src   := 'The quick brown fox jumped over the lazy dog!';
    csrc  := 'Thequickbrownfoxjumpedoverthelazydog!';

    sut := TUtf8Reader.Create(src);
    while NOT sut.EOF do
      s := Utf8.Append(s, sut.NextCharSkippingWhitespace);

    Test('').Assert(STR.FromUTF8(s)).Equals(STR.FromUtf8(csrc));
  end;


  procedure Utf8Reader.ReadsWideStringToEnd;
  var
    src: UnicodeString;
    s: Utf8String;
    sut: IUtf8Reader;
  begin
    src := 'The quick brown fox jumped over the lazy dog!';

    sut := TUtf8Reader.Create(src);
    while NOT sut.EOF do
      s := Utf8.Append(s, sut.NextChar);

    Test('').Assert(STR.FromUTF8(s)).Equals(src);
  end;




end.
