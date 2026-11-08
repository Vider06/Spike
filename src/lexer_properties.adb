package body Lexer_Properties
  with SPARK_Mode => On
is
   procedure Advance_Offset
     (Offset : in out Natural; Amount, Source_Length : Natural)
   is
   begin
      Offset := Offset + Amount;
   end Advance_Offset;

   procedure Advance_Cursor (Cursor : in out Natural; Token_Count : Natural) is
   begin
      Cursor := Cursor + 1;
   end Advance_Cursor;
end Lexer_Properties;
