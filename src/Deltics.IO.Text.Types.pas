
{$i deltics.io.text.inc}

  unit Deltics.io.Text.Types;


interface

  uses
    Deltics.Strings;


  type
    PCharLocation = ^TCharLocation;
    TCharLocation = record
      Line: Integer;
      Character: Integer;
    end;


    TUtf8CharFilterFn = function(const aChar: Utf8Char): Boolean of object;
    TWideCharFilterFn = function(const aChar: WideChar): Boolean of object;




implementation




end.
