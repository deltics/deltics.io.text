
{$define CONSOLE}

{$i deltics.smoketest.inc}

  program test;

uses
  FastMM4,
  Deltics.Smoketest,
  Deltics.IO.TextReaders in '..\src\Deltics.IO.TextReaders.pas',
  Deltics.IO.TextReaders.TextReader in '..\src\Deltics.IO.TextReaders.TextReader.pas',
  Deltics.IO.TextReaders.Interfaces in '..\src\Deltics.IO.TextReaders.Interfaces.pas',
  Deltics.IO.TextReaders.Types in '..\src\Deltics.IO.TextReaders.Types.pas',
  Deltics.IO.TextReaders.Unicode in '..\src\Deltics.IO.TextReaders.Unicode.pas',
  Deltics.IO.TextReaders.Utf8 in '..\src\Deltics.IO.TextReaders.Utf8.pas',
  Test.Utf8Reader in 'Test.Utf8Reader.pas',
  Test.UnicodeReader in 'Test.UnicodeReader.pas';

begin
  TestRun.Test(Utf8Reader);
  TestRun.Test(UnicodeReader);
end.
