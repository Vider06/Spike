with Lexer_Types;

package Lexer_Diagnostics is
   function Token_Kind_Name (Kind : Lexer_Types.Token_Kind) return String;
   function Code_Name (Code : Lexer_Types.Diagnostic_Code) return String;
   function Message (Code : Lexer_Types.Diagnostic_Code) return String;
   function Format (Item : Lexer_Types.Diagnostic) return String;
end Lexer_Diagnostics;
