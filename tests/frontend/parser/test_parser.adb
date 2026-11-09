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
   Source : constant String := "get first , second from [data]" & ASCII.LF
     & "give [continue]" & ASCII.LF & "halt";
   Tokens : Token_Array (1 .. Max_Tokens);
   Token_Count : Natural := 0;
   Lex_Error : Diagnostic;
   Parsed : Parser_Types.Parse_Result;
   Table : constant Verb_Table_Types.Verb_Table :=
     Verb_Table_Config.Load ("src/leng/verbs/verbs.json");
begin
   Lexer.Tokenize (Source, Tokens, Token_Count, Lex_Error);
   Assert (Lex_Error.Code = No_Error, "fixture must lex");
   Parser.Parse (Source, Tokens, Token_Count, Table, Parsed);
   Assert (Parsed.Error.Code = No_Error, "valid source must parse");
   Assert (Parsed.Tree.Count = 3, "three statements are represented");
   Assert (Parsed.Tree.Statements (1).Operand_Total = 3, "get has three operands");
   Assert (Parsed.Tree.Statements (2).Operand_Total = 1, "give continuation is required");
   Assert (Parsed.Tree.Statements (3).Verb_Index = 3, "halt resolves through the verb table");
   Put_Line ("Spike parser phase 3 tests passed");
end Test_Parser;
