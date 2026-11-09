package body Lexer_Properties is
   pragma SPARK_Mode (On);

   function Is_Horizontal_Space (Item : Character) return Boolean is
     (Item = ' ' or else Item = ASCII.HT);

   function Is_Line_Break (Item : Character) return Boolean is
     (Item = ASCII.LF or else Item = ASCII.CR);

   function Is_ASCII_Letter (Item : Character) return Boolean is
     (Item in 'A' .. 'Z' or else Item in 'a' .. 'z');

   function Is_Flag_Name_Start (Item : Character) return Boolean is
     (Is_ASCII_Letter (Item) or else Item = '_');

   function Is_Flag_Name_Continue (Item : Character) return Boolean is
     (Is_ASCII_Letter (Item)
      or else Item in '0' .. '9'
      or else Item = '_'
      or else Item = '-');

   function Can_Precede_Comma (Kind : Token_Kind) return Boolean is
     (Kind in Word | Quoted_Text | Right_Bracket | Flag);

   function Can_Follow_Comma (Kind : Token_Kind) return Boolean is
     (Kind in Word | Quoted_Text | Left_Bracket | Flag);

   function Valid_Span
     (Start_Offset : Natural;
      Span_Length  : Natural;
      Source_Length : Natural) return Boolean
   is
     (Span_Length > 0
      and then Start_Offset <= Source_Length
      and then Span_Length <= Source_Length - Start_Offset);
end Lexer_Properties;
