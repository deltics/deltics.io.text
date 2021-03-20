
{$i deltics.io.text.inc}

  unit Deltics.IO.Text.Interfaces;


interface

  uses
    Deltics.StringEncodings,
    Deltics.StringTypes,
    Deltics.IO.Streams,
    Deltics.IO.Text.Types;


  type
    IStream = Deltics.IO.Streams.IStream;


    ITextReader = interface
    ['{CA26B554-81FE-4511-B5C9-9B854A819CF8}']
      function get_EOF: Boolean;
      function get_Location: TCharLocation;
      function get_Source: IStream;
      function get_SourceEncoding: TEncoding;

      property EOF: Boolean read get_EOF;
      property Location: TCharLocation read get_Location;
      property Source: IStream read get_Source;
      property SourceEncoding: TEncoding read get_SourceEncoding;
    end;


    IUtf8Reader = interface(ITextReader)
      function IsWhitespace(const aChar: Utf8Char): Boolean;
      procedure MoveBack;
      function NextChar: Utf8Char;
      function NextCharAfter(const aFilter: TUtf8CharFilterFn): Utf8Char;
      function NextCharSkippingWhitespace: Utf8Char;
      function NextWideChar: WideChar;
      function PeekChar: Utf8Char;
      function PeekCharSkippingWhitespace: Utf8Char;
      function ReadLine: Utf8String;
      procedure Skip(const aNumChars: Integer);
      procedure SkipWhitespace;
      procedure SkipChar;
    end;


    IUnicodeReader = interface(ITextReader)
    ['{719165A6-AD65-4C7F-8D8B-8A680031B5FD}']
      function IsWhitespace(const aChar: WideChar): Boolean;
      function NextChar: WideChar;
      function NextCharAfter(const aFilter: TWideCharFilterFn): WideChar;
      function NextCharSkippingWhitespace: WideChar;
      procedure MoveBack;
      function PeekChar: WideChar;
      function PeekCharSkippingWhitespace: WideChar;
      function ReadLine: UnicodeString;
      procedure Skip(const aNumChars: Integer);
      procedure SkipWhitespace;
      procedure SkipChar;
    end;


implementation

end.
