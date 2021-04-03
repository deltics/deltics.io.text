
{$i deltics.inc}

  unit Test.UnicodeReader;


interface

  uses
    Deltics.Smoketest;


  type
    UnicodeReader = class(TTest)
      procedure LocationReportsLine1Character5For5CharactersOnFirstLine;
      procedure LocationReportsLine1Character5For5CharactersOnFirstLineSkippingWhitespace;
      procedure LocationReportsLine2Character1AfterReadingFirstCharacterAfterCR;
      procedure LocationReportsLine2Character1AfterReadingFirstCharacterAfterCRLF;
      procedure MoveBackRereadsCharacterPreviouslyRead;
      procedure NextCharReadsSurrogatesCorrectly;
      procedure ReadsWideStringToEnd;
      procedure ReadsWideStringToEndIgnoringAsciiWhitespace;
      procedure ReadsUtf8StringToEnd;
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
    Deltics.io.Text;


{ UtfReader }

  type TProtectedReader = class(TUnicodeReader);


  procedure UnicodeReader.EOFIsFalseForProtectedMethodsWhenPreviousCharIsCachedAfterMoveBackAtTheEndOfStream;
  var
    src: UnicodeString;
    sut: TProtectedReader;
  begin
    src := 'Test';

    sut := TProtectedReader.Create(src);
    sut.Skip(4);

    Test('EOF').Assert(sut.EOF).IsTrue;

    sut.MoveBack;

    Test('EOF').Assert(sut.EOF).IsFALSE;
  end;


  procedure UnicodeReader.EOFIsFalseWhenPreviousCharIsCachedAfterMoveBackAtTheEndOfStream;
  var
    src: UnicodeString;
    sut: IUnicodeReader;
  begin
    src := 'Test';

    sut := TUnicodeReader.Create(src);
    sut.Skip(4);

    Test('EOF').Assert(sut.EOF).IsTrue;

    sut.MoveBack;

    Test('EOF (after MoveBack)').Assert(sut.EOF).IsFalse;
    Test('NextChar (after MoveBack)').Assert(sut.NextChar).Equals('t');

    Test('EOF (after NextChar, after MoveBack)').Assert(sut.EOF).IsTrue;
  end;


  procedure UnicodeReader.LocationReportsLine1Character5For5CharactersOnFirstLine;
  var
    src: UnicodeString;
    sut: IUnicodeReader;
    c: WideChar;
  begin
    src := 'The quick brown fox'#13'jumped over the lazy dog!';

    sut := TUnicodeReader.Create(src);
    sut.Skip(4);
    c := sut.NextChar;

    Test('c').Assert(c).Equals('q');
    Test('Location.Line').Assert(sut.Location.Line).Equals(1);
    Test('Location.Character').Assert(sut.Location.Character).Equals(5);
  end;



  procedure UnicodeReader.LocationReportsLine1Character5For5CharactersOnFirstLineSkippingWhitespace;
  var
    src: UnicodeString;
    sut: IUnicodeReader;
    c: WideChar;
  begin
    src := 'The quick brown fox'#13'jumped over the lazy dog!';

    sut := TUnicodeReader.Create(src);
    sut.Skip(3);
    c := sut.NextCharSkippingWhitespace;

    Test('c').Assert(c).Equals('q');
    Test('Location.Line').Assert(sut.Location.Line).Equals(1);
    Test('Location.Character').Assert(sut.Location.Character).Equals(5);
  end;



  procedure UnicodeReader.LocationReportsLine2Character1AfterReadingFirstCharacterAfterCR;
  var
    src: UnicodeString;
    sut: IUnicodeReader;
    c: WideChar;
  begin
    src := 'The quick brown fox'#13'jumped over the lazy dog!';

    sut := TUnicodeReader.Create(src);
    sut.Skip(19);
    sut.SkipWhitespace;
    c := sut.NextChar;

    Test('c').Assert(c).Equals('j');
    Test('Location.Line').Assert(sut.Location.Line).Equals(2);
    Test('Location.Character').Assert(sut.Location.Character).Equals(1);
  end;



  procedure UnicodeReader.LocationReportsLine2Character1AfterReadingFirstCharacterAfterCRLF;
  var
    src: UnicodeString;
    sut: IUnicodeReader;
    c: WideChar;
  begin
    src := 'The quick brown fox'#13#10'jumped over the lazy dog!';

    sut := TUnicodeReader.Create(src);
    sut.Skip(19);
    sut.SkipWhitespace;
    c := sut.NextChar;

    Test('c').Assert(c).Equals('j');
    Test('Location.Line').Assert(sut.Location.Line).Equals(2);
    Test('Location.Character').Assert(sut.Location.Character).Equals(1);
  end;



  procedure UnicodeReader.MoveBackRereadsCharacterPreviouslyRead;
  var
    src: UnicodeString;
    s: UnicodeString;
    sut: IUnicodeReader;
  begin
    src := 'abc';

    sut := TUnicodeReader.Create(src);
    s := s + sut.NextChar;
    s := s + sut.NextChar;
    sut.MoveBack;
    s := s + sut.NextChar;
    s := s + sut.NextChar;

    Test('s').Assert(s).Equals('abbc');
  end;


  procedure UnicodeReader.NextCharReadsSurrogatesCorrectly;
  {
    For this test we use Unicode codepoint Ux1d11e - the treble clef

      UTF-8 Encoding  :	0xF0 0x9D 0x84 0x9E
      UTF-16 Encoding :	0xD834 0xDD1E
  }
  var
    src: UnicodeString;
    hi, lo: WideChar;
    c1, c2: WideChar;
    sut: IUnicodeReader;
  begin
    src  := 'a??b';
    src[2] := WideChar($d834);
    src[3] := WideChar($dd1e);

    sut := TUnicodeReader.Create(src);
    c1 := sut.NextChar;
    hi := sut.NextChar;
    lo := sut.NextChar;
    c2 := sut.NextChar;

    Test('hi').Assert(Word(hi)).Equals($d834);
    Test('lo').Assert(Word(lo)).Equals($dd1e);
    Test('c1').Assert(c1).Equals('a');
    Test('c2').Assert(c2).Equals('b');
  end;


  procedure UnicodeReader.ReadsUtf8StringToEnd;
  var
    src: Utf8String;
    sut: IUnicodeReader;
    s: WideString;
  begin
    src  := 'Quick Brown??2020: The Quick Brown Fox Jumped Over The Lazy Dog';
    src[12] := Utf8Char($c2);
    src[13] := Utf8Char($a9);

    sut := TUnicodeReader.Create(src);
    while NOT sut.EOF do
      s := s + sut.NextChar;

    Test('s').Assert(s).Equals('Quick Brown©2020: The Quick Brown Fox Jumped Over The Lazy Dog');
  end;


  procedure UnicodeReader.ReadsWideStringToEndIgnoringAsciiWhitespace;
  var
    src, csrc: UnicodeString;
    s: UnicodeString;
    sut: IUnicodeReader;
  begin
    src   := 'The quick brown fox jumped over the lazy dog!';
    csrc  := 'Thequickbrownfoxjumpedoverthelazydog!';

    sut := TUnicodeReader.Create(src);
    while NOT sut.EOF do
      s := s + sut.NextCharSkippingWhitespace;

    Test('s').Assert(s).Equals(csrc);
  end;


  procedure UnicodeReader.ReadsWideStringToEnd;
  var
    src: UnicodeString;
    s: UnicodeString;
    sut: IUnicodeReader;
  begin
    src := 'The quick brown fox jumped over the lazy dog!';

    sut := TUnicodeReader.Create(src);
    while NOT sut.EOF do
      s := s + sut.NextChar;

    Test('s').Assert(s).Equals(src);
  end;



  procedure UnicodeReader.ReadLineReadsBlankLinesWithCR;
  const
    LINE1: UnicodeString = 'The quick brown fox';
    LINE2: UnicodeString = 'jumped over the lazy dog';
  var
    src: UnicodeString;
    s1, s2, s3: UnicodeString;
    sut: IUnicodeReader;
  begin
    src := LINE1 + #13#13 + LINE2;

    sut := TUnicodeReader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);
    s3  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);

    Test('s1').Assert(s1).Equals(LINE1);
    Test('s2').Assert(s2).IsEmpty;
    Test('s3').Assert(s3).Equals(LINE2);
  end;


  procedure UnicodeReader.ReadLineReadsBlankLinesWithCRLF;
  const
    LINE1: UnicodeString = 'The quick brown fox';
    LINE2: UnicodeString = 'jumped over the lazy dog';
  var
    src: UnicodeString;
    s1, s2, s3: UnicodeString;
    sut: IUnicodeReader;
  begin
    src := LINE1 + #13#10#13#10 + LINE2;

    sut := TUnicodeReader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);
    s3  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(3);

    Test('s1').Assert(s1).Equals(LINE1);
    Test('s2').Assert(s2).IsEmpty;
    Test('s3').Assert(s3).Equals(LINE2);
  end;


  procedure UnicodeReader.ReadLineReadsMultipleLinesWithCR;
  const
    LINE1: UnicodeString = 'The quick brown fox';
    LINE2: UnicodeString = 'jumped over the lazy dog';
  var
    src: UnicodeString;
    s1, s2: UnicodeString;
    sut: IUnicodeReader;
  begin
    src := LINE1 + #13 + LINE2;

    sut := TUnicodeReader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);

    Test('s1').Assert(s1).Equals(LINE1);
    Test('s2').Assert(s2).Equals(LINE2);
  end;


  procedure UnicodeReader.ReadLineReadsMultipleLinesWithCRLF;
  const
    LINE1: UnicodeString = 'The quick brown fox';
    LINE2: UnicodeString = 'jumped over the lazy dog';
  var
    src: UnicodeString;
    s1, s2: UnicodeString;
    sut: IUnicodeReader;
  begin
    src := LINE1 + #13#10 + LINE2;

    sut := TUnicodeReader.Create(src);

    Test('Line').Assert(sut.Location.Line).Equals(1);
    s1  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);
    s2  := sut.ReadLine;
    Test('Line').Assert(sut.Location.Line).Equals(2);

    Test('s1').Assert(s1).Equals(LINE1);
    Test('s2').Assert(s2).Equals(LINE2);
  end;


  procedure UnicodeReader.ReadLineReadsSingleLine;
  var
    src: UnicodeString;
    s: UnicodeString;
    sut: IUnicodeReader;
  begin
    src   := 'The quick brown fox jumped over the lazy dog!';

    sut := TUnicodeReader.Create(src);
    s := sut.ReadLine;

    Test('s').Assert(s).Equals(src);
  end;



end.
