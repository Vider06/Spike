with Lexer_Properties;
with Lexer_Types;

procedure Prove_Lexer_Properties
  with SPARK_Mode => On
is
   use Lexer_Properties;
   use Lexer_Types;
begin
   pragma Assert (Is_Horizontal_Space (' '));
   pragma Assert (Is_Horizontal_Space (ASCII.HT));
   pragma Assert (not Is_Horizontal_Space ('x'));
   pragma Assert (Is_Line_Break (ASCII.LF));
   pragma Assert (Is_Line_Break (ASCII.CR));
   pragma Assert (not Is_Line_Break (' '));
   pragma Assert (Is_ASCII_Letter ('A'));
   pragma Assert (Is_ASCII_Letter ('z'));
   pragma Assert (not Is_ASCII_Letter ('4'));
   pragma Assert (Is_Flag_Name_Start ('_'));
   pragma Assert (Is_Flag_Name_Continue ('7'));
   pragma Assert (Is_Flag_Name_Continue ('-'));
   pragma Assert (not Is_Flag_Name_Continue ('.'));
   pragma Assert (Can_Precede_Comma (Word));
   pragma Assert (Can_Precede_Comma (Right_Bracket));
   pragma Assert (not Can_Precede_Comma (Left_Bracket));
   pragma Assert (Can_Follow_Comma (Quoted_Text));
   pragma Assert (Can_Follow_Comma (Left_Bracket));
   pragma Assert (not Can_Follow_Comma (Right_Bracket));
   pragma Assert (Valid_Span (0, 1, 1));
   pragma Assert (Valid_Span (3, 2, 5));
   pragma Assert (not Valid_Span (3, 3, 5));
   pragma Assert (not Valid_Span (5, 0, 5));
end Prove_Lexer_Properties;
