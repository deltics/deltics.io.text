
{$i deltics.inc}

{$debuginfo OFF}

{$ifdef debug_DelticsIo}
  {$define debug_DelticsIoTextReaders}
{$endif}

{$ifdef debug_DelticsIoTextReaders}
  {$undef InlineMethods}
  {$debuginfo ON}
{$endif}