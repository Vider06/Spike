with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Lexer;
with Lexer_Types;
with Parser;
with Parser_Types;
with Verb_Table_Config;
with Verb_Table_Types;

procedure Test_Parser is
   use Lexer_Types;
   Source : constant String :=
     "get a , b , c , d from [""data""]=x , y , z , w" & ASCII.LF
     & "give [continue]" & ASCII.LF
     & "give alpha , beta , gamma" & ASCII.LF
     & "halt";
   Tokens : Token_Array (1 .. Max_Tokens);
   Token_Count : Natural := 0;
   Lex_Error : Diagnostic;
   Parsed : Parser_Types.Parse_Result;
   Table : constant Verb_Table_Types.Verb_Table :=
     Verb_Table_Config.Load ("src/leng/verbs/verbs.json");
   Get_Statement : Parser_Types.Statement;
   Ambiguous_Source : constant String := "amb value";
   Ambiguous_Document : constant String :=
     "{""schema_version"":""1.0"",""verbs"":[{""name"":""amb"",""forms"":["
     & "{""operands"":[{""type"":""name""}]},"
     & "{""operands"":[{""type"":""name""}]}]}]}";
   Ambiguous_Table : constant Verb_Table_Types.Verb_Table :=
     Verb_Table_Config.Validate (Ambiguous_Document);
begin
   Lexer.Tokenize (Source, Tokens, Token_Count, Lex_Error);
   Assert (Lex_Error.Code = No_Error, "fixture must lex including '=' separator");
   Parser.Parse (Source, Tokens, Token_Count, Table, Parsed);
   Assert (Parsed.Error.Code = No_Error, "valid variable-arity source must parse");
   Assert (Parsed.Tree.Count = 4, "four statements are represented");

   Get_Statement := Parsed.Tree.Statements (1);
   Assert (Get_Statement.Operand_Total = 9,
     "get stores all destination and source names plus the bracket expression");
   Assert (Parsed.Tree.Operands (Get_Statement.Operand_First).Count = 1,
     "first destination is stored as a distinct operand");
   Assert (Parsed.Tree.Operands (Get_Statement.Operand_First + 4).Count = 3,
     "bracket expression is stored as one complete token span");
   Assert (Parsed.Tree.Operands (Get_Statement.Operand_First + 8).Count = 1,
     "last source name is retained");

   Assert (Parsed.Tree.Statements (2).Operand_Total = 1,
     "give continuation marker remains a required bracket operand");
   Assert (Parsed.Tree.Statements (3).Operand_Total = 3,
     "give accepts an arbitrary-length name group");
   Assert (Parsed.Tree.Statements (4).Verb_Index = 3,
     "halt resolves through the verb table");

   Lexer.Tokenize (Ambiguous_Source, Tokens, Token_Count, Lex_Error);
   Assert (Lex_Error.Code = No_Error, "ambiguous-form fixture must lex");
   Parser.Parse (Ambiguous_Source, Tokens, Token_Count, Ambiguous_Table, Parsed);
   Assert (Parsed.Error.Code = Ambiguous_Form,
     "the parser must reject forms that match the same statement");

   Put_Line ("Spike parser variable-arity and form-selection tests passed");
end Test_Parser;
