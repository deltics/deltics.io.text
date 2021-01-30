
{$i deltics.io.textreaders.inc}

  unit Deltics.IO.TextReaders;


interface

  uses
    Deltics.IO.TextReaders.Interfaces,
    Deltics.IO.TextReaders.Unicode,
    Deltics.IO.TextReaders.Utf8;


  type
    ITextReader     = Deltics.IO.TextReaders.Interfaces.ITextReader;
    IUnicodeReader  = Deltics.IO.TextReaders.Interfaces.IUnicodeReader;
    IUtf8Reader     = Deltics.IO.TextReaders.Interfaces.IUtf8Reader;


    TUnicodeReader  = Deltics.IO.TextReaders.Unicode.TUnicodeReader;
    TUtf8Reader     = Deltics.IO.TextReaders.Utf8.TUtf8Reader;




implementation

end.
