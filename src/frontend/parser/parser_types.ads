with Lexer_Types;
package Parser_Types is
   pragma SPARK_Mode (On);

   Max_AST_Entries : constant := Lexer_Types.Max_Tokens;
   subtype Span_Count is Natural range 0 .. Max_AST_Entries;

   type Token_Span is record
      First : Natural := 0;
      Count : Natural := 0;
   end record;

   type Span_Array is array (Positive range 1 .. Max_AST_Entries) of Token_Span;

   type Statement is record
      Verb_Token    : Natural := 0;
      Verb_Index    : Natural := 0;
      Form_Index    : Natural := 0;
      Operand_First : Natural := 0;
      Operand_Total : Span_Count := 0;
      Flag_First    : Natural := 0;
      Flag_Total    : Span_Count := 0;
   end record;

   type Statement_Array is
     array (Positive range 1 .. Max_AST_Entries) of Statement;

   type AST is record
      Count         : Span_Count := 0;
      Operand_Count : Span_Count := 0;
      Flag_Count    : Span_Count := 0;
      Statements    : Statement_Array := [others => <>];
      Operands      : Span_Array := [others => <>];
      Flags         : Span_Array := [others => <>];
   end record;

   type Parse_Result is record
      Tree : AST;
      Error : Lexer_Types.Diagnostic :=
        (Phase => Lexer_Types.Parsing, Code => Lexer_Types.No_Error,
         Location => (Offset => 0, Line => 1, Column => 1));
   end record;
end Parser_Types;
