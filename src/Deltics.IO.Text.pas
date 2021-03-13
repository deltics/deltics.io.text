
{$i deltics.IO.text.inc}

  unit Deltics.IO.Text;


interface

  uses
    Deltics.IO.Text.Interfaces,
    Deltics.IO.Text.Types,
    Deltics.IO.Text.Unicode,
    Deltics.IO.Text.Utf8;


  type
    PCharLocation   = Deltics.IO.Text.Types.PCharLocation;
    TCharLocation   = Deltics.IO.Text.Types.TCharLocation;

    ITextReader     = Deltics.IO.Text.Interfaces.ITextReader;
    IUnicodeReader  = Deltics.IO.Text.Interfaces.IUnicodeReader;
    IUtf8Reader     = Deltics.IO.Text.Interfaces.IUtf8Reader;


    TUnicodeReader  = Deltics.IO.Text.Unicode.TUnicodeReader;
    TUtf8Reader     = Deltics.IO.Text.Utf8.TUtf8Reader;




implementatIOn

end.
