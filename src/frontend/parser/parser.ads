with Lexer_Types;
with Parser_Types;
with Verb_Table_Types;
package Parser is
   pragma SPARK_Mode (On);
   procedure Parse
     (Source : String;
      Tokens : Lexer_Types.Token_Array;
      Token_Count : Natural;
      Table : Verb_Table_Types.Verb_Table;
      Result : out Parser_Types.Parse_Result)
   with Pre => Token_Count <= Tokens'Length;
end Parser;
