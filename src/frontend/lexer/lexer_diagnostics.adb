with Ada.Strings.Fixed;
package body Lexer_Diagnostics is
   use Ada.Strings.Fixed;
   function Format (Value : Lexer_Types.Diagnostic) return String is
      Code : constant String :=
        (case Value.Code is
            when Lexer_Types.No_Error => "E0000",
            when Lexer_Types.Invalid_Character => "E0001",
            when Lexer_Types.Unterminated_String => "E0002",
            when Lexer_Types.Invalid_Flag => "E0003",
            when Lexer_Types.Bracket_Spacing => "E0004",
            when Lexer_Types.Comma_Spacing => "E0005",
            when Lexer_Types.Token_Limit_Exceeded => "E0006");
      Message : constant String :=
        (case Value.Code is
            when Lexer_Types.No_Error => "no error",
            when Lexer_Types.Invalid_Character => "invalid character",
            when Lexer_Types.Unterminated_String => "unterminated quoted text",
            when Lexer_Types.Invalid_Flag => "invalid flag; expected --name",
            when Lexer_Types.Bracket_Spacing => "invalid spacing inside square brackets",
            when Lexer_Types.Comma_Spacing => "comma must have whitespace on both sides",
            when Lexer_Types.Token_Limit_Exceeded => "token limit exceeded");
   begin
      return Code & " at "
        & Trim (Positive'Image (Value.Line), Both) & ":"
        & Trim (Positive'Image (Value.Column), Both) & ": " & Message;
   end Format;
end Lexer_Diagnostics;
