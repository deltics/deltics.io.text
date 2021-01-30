
{$define CONSOLE}

{$i deltics.smoketest.inc}

  program test;

uses
  FastMM4,
  Deltics.Smoketest,
  Deltics.IO.Text in '..\src\Deltics.IO.Text.pas',
  Deltics.IO.Text.Interfaces in '..\src\Deltics.IO.Text.Interfaces.pas',
  Deltics.IO.Text.TextReader in '..\src\Deltics.IO.Text.TextReader.pas',
  Deltics.IO.Text.Types in '..\src\Deltics.IO.Text.Types.pas',
  Deltics.IO.Text.Unicode in '..\src\Deltics.IO.Text.Unicode.pas',
  Deltics.IO.Text.Utf8 in '..\src\Deltics.IO.Text.Utf8.pas',
  Test.Utf8Reader in 'Test.Utf8Reader.pas',
  Test.UnicodeReader in 'Test.UnicodeReader.pas';

begin
  TestRun.Test(Utf8Reader);
  TestRun.Test(UnicodeReader);
end.
