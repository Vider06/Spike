with Lexer_Config;
with Token_Stream;

package Dynamic_Lexer is
   pragma SPARK_Mode (Off);

   Lexical_Error : exception;

   function Tokenize
     (Configuration : Lexer_Config.Lexer_Configuration;
      Source        : String) return Token_Stream.Stream;
end Dynamic_Lexer;
