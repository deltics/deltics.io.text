
{$i deltics.io.text.inc}

  unit Deltics.io.Text;


interface

  uses
    Deltics.io.Text.Interfaces,
    Deltics.io.Text.Types,
    Deltics.io.Text.Unicode,
    Deltics.io.Text.Utf8;


  type
    PCharLocation   = Deltics.IO.Text.Types.PCharLocation;
    TCharLocation   = Deltics.IO.Text.Types.TCharLocation;

    ITextReader     = Deltics.IO.Text.Interfaces.ITextReader;
    IUnicodeReader  = Deltics.IO.Text.Interfaces.IUnicodeReader;
    IUtf8Reader     = Deltics.IO.Text.Interfaces.IUtf8Reader;


    TUnicodeReader  = Deltics.IO.Text.Unicode.TUnicodeReader;
    TUtf8Reader     = Deltics.IO.Text.Utf8.TUtf8Reader;




implementation

end.
