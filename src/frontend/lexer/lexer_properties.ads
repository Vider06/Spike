with Lexer_Types;

package Lexer_Properties is
   pragma SPARK_Mode (On);
   use Lexer_Types;

   function Is_Horizontal_Space (Item : Character) return Boolean;
   function Is_Line_Break (Item : Character) return Boolean;
   function Is_ASCII_Letter (Item : Character) return Boolean;
   function Is_Flag_Name_Start (Item : Character) return Boolean;
   function Is_Flag_Name_Continue (Item : Character) return Boolean;

   function Can_Precede_Comma (Kind : Token_Kind) return Boolean;
   function Can_Follow_Comma (Kind : Token_Kind) return Boolean;

   function Valid_Span
     (Start_Offset : Natural;
      Span_Length  : Natural;
      Source_Length : Natural) return Boolean;
end Lexer_Properties;
