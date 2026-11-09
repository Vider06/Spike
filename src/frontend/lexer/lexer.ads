with Lexer_Types;

package Lexer is
   pragma SPARK_Mode (On);
   use Lexer_Types;

   procedure Tokenize
     (Source      : String;
      Tokens      : out Token_Array;
      Token_Count : out Natural;
      Error       : out Diagnostic)
   with
     Pre  => Tokens'Length > 0,
     Post => Token_Count <= Tokens'Length;
end Lexer;
