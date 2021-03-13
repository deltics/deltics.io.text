
{$i deltics.io.text.inc}

  unit Deltics.IO.Text.Types;


interface

  uses
    Deltics.StringTypes;


  type
    TEofMethod = function: Boolean of object;
    TUtf8CharReaderMethod = function: Utf8Char of object;
    TWideCharReaderMethod = function: WideChar of object;


    PCharLocation = ^TCharLocation;
    TCharLocation = record
      Line: Integer;
      Character: Integer;
    end;


    TUtf8CharFilterFn = function(const aChar: Utf8Char): Boolean of object;
    TWideCharFilterFn = function(const aChar: WideChar): Boolean of object;




implementation




end.
