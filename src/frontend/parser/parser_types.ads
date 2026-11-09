with Lexer_Types;
package Parser_Types is
   pragma SPARK_Mode (On);
   Max_Statements : constant := 512;
   Max_Operands   : constant := 8;
   Max_Flags      : constant := 8;
   subtype Operand_Count is Natural range 0 .. Max_Operands;
   subtype Flag_Count is Natural range 0 .. Max_Flags;
   type Token_Span is record First : Natural := 0; Count : Natural := 0; end record;
   type Operand_Span_Array is array (Positive range 1 .. Max_Operands) of Token_Span;
   type Flag_Span_Array is array (Positive range 1 .. Max_Flags) of Token_Span;
   type Statement is record
      Verb_Token : Natural := 0;
      Verb_Index : Natural := 0;
      Form_Index : Natural := 0;
      Operand_Total : Operand_Count := 0;
      Operands : Operand_Span_Array := [others => <>];
      Flag_Total : Flag_Count := 0;
      Flags : Flag_Span_Array := [others => <>];
   end record;
   type Statement_Array is array (Positive range 1 .. Max_Statements) of Statement;
   type AST is record
      Count : Natural range 0 .. Max_Statements := 0;
      Statements : Statement_Array := [others => <>];
   end record;
   type Parse_Result is record
      Tree : AST;
      Error : Lexer_Types.Diagnostic :=
        (Phase => Lexer_Types.Parsing, Code => Lexer_Types.No_Error,
         Location => (Offset => 0, Line => 1, Column => 1));
   end record;
end Parser_Types;
