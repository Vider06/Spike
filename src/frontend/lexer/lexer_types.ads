package Lexer_Types
  with SPARK_Mode => On
is
   Max_Tokens : constant := 16_384;
   type Token_Kind is
     (Word, Quoted_Text, Left_Bracket, Right_Bracket, Comma, Flag,
      Newline, Indentation, Comment);
   type Token is record
      Kind : Token_Kind := Word;
      Start_Offset : Natural := 0;
      End_Offset : Natural := 0;
      Line : Positive := 1;
      Column : Positive := 1;
      Auxiliary : Natural := 0;
   end record;
   type Token_Array is array (Positive range 1 .. Max_Tokens) of Token;
   subtype Token_Count is Natural range 0 .. Max_Tokens;
   type Diagnostic_Code is
     (No_Error, Invalid_Character, Unterminated_String, Invalid_Flag,
      Bracket_Spacing, Comma_Spacing, Token_Limit_Exceeded);
   type Diagnostic is record
      Code : Diagnostic_Code := No_Error;
      Line : Positive := 1;
      Column : Positive := 1;
   end record;
   type Lex_Result is record
      Tokens : Token_Array := [others => (others => <>)];
      Count : Token_Count := 0;
      Has_Error : Boolean := False;
      Error : Diagnostic := (others => <>);
   end record;
end Lexer_Types;
