
{$define CONSOLE}

{$i deltics.smoketest.inc}

  program test;

uses
  FastMM4,
  Deltics.Smoketest,
  Deltics.io.Text in '..\src\Deltics.io.Text.pas',
  Deltics.io.Text.Interfaces in '..\src\Deltics.io.Text.Interfaces.pas',
  Deltics.io.Text.TextReader in '..\src\Deltics.io.Text.TextReader.pas',
  Deltics.io.Text.Types in '..\src\Deltics.io.Text.Types.pas',
  Deltics.io.Text.Unicode in '..\src\Deltics.io.Text.Unicode.pas',
  Deltics.io.Text.Utf8 in '..\src\Deltics.io.Text.Utf8.pas',
  Test.Utf8Reader in 'Test.Utf8Reader.pas',
  Test.UnicodeReader in 'Test.UnicodeReader.pas';

begin
  TestRun.Test(Utf8Reader);
  TestRun.Test(UnicodeReader);
end.
