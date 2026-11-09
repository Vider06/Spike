with Lexer_Types;
package Spike_Lexer
  with SPARK_Mode => On
is
   procedure Tokenize
     (Source : String;
      Result : out Lexer_Types.Lex_Result)
   with Global => null;
end Spike_Lexer;
