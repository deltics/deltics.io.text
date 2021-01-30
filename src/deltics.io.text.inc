
{$i deltics.inc}

{$debuginfo OFF}

{$ifdef debug_DelticsIo}
  {$define debug_DelticsIoText}
{$endif}

{$ifdef debug_DelticsIoText}
  {$undef InlineMethods}
  {$debuginfo ON}
{$endif}