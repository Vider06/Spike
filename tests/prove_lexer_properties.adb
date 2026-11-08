with Lexer_Properties;

procedure Prove_Lexer_Properties
  with SPARK_Mode => On
is
begin
   pragma Assert (Lexer_Properties.Is_ASCII_Digit ('0'));
   pragma Assert (Lexer_Properties.Is_ASCII_Digit ('9'));
   pragma Assert (not Lexer_Properties.Is_ASCII_Digit ('A'));
   pragma Assert (Lexer_Properties.Is_ASCII_Hex_Digit ('f'));
   pragma Assert (Lexer_Properties.Is_ASCII_Hex_Digit ('B'));
   pragma Assert (not Lexer_Properties.Is_ASCII_Hex_Digit ('g'));
   pragma Assert (Lexer_Properties.Is_Identifier_Start ('_'));
   pragma Assert (Lexer_Properties.Is_Identifier_Start ('Z'));
   pragma Assert (not Lexer_Properties.Is_Identifier_Start ('4'));
   pragma Assert (Lexer_Properties.Is_Identifier_Continue ('4'));
   pragma Assert (Lexer_Properties.Valid_Span (0, 4, 4));
   pragma Assert (not Lexer_Properties.Valid_Span (3, 2, 4));
   pragma Assert (not Lexer_Properties.Valid_Span (0, 5, 4));
   pragma Assert (Lexer_Properties.Better_Match (3, 0, 2, 100));
   pragma Assert (Lexer_Properties.Better_Match (3, 2, 3, 1));
   pragma Assert (not Lexer_Properties.Better_Match (3, 1, 3, 2));
   pragma Assert (Lexer_Properties.Cursor_In_Bounds (0, 0));
   pragma Assert (Lexer_Properties.Cursor_In_Bounds (4, 4));
end Prove_Lexer_Properties;
