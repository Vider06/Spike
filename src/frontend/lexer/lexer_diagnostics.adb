with Ada.Strings;
with Ada.Strings.Fixed;

package body Lexer_Diagnostics is
   use Lexer_Types;

   function Number (Value : Natural) return String is
     (Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Left));

   function Token_Kind_Name (Kind : Token_Kind) return String is
   begin
      case Kind is
         when Word            => return "WORD";
         when Quoted_Text     => return "QUOTED_TEXT";
         when Left_Bracket    => return "LEFT_BRACKET";
         when Right_Bracket   => return "RIGHT_BRACKET";
         when Comma           => return "COMMA";
         when Flag            => return "FLAG";
         when Newline_Indent  => return "NEWLINE_INDENT";
         when Comment         => return "COMMENT";
      end case;
   end Token_Kind_Name;

   function Code_Name (Code : Diagnostic_Code) return String is
   begin
      case Code is
         when No_Error                       => return "LEX000";
         when Unexpected_Control_Character  => return "LEX001";
         when Unterminated_Quoted_Text       => return "LEX002";
         when Invalid_Flag                   => return "LEX003";
         when Unmatched_Right_Bracket        => return "LEX004";
         when Unclosed_Left_Bracket          => return "LEX005";
         when Empty_Brackets                 => return "LEX006";
         when Whitespace_After_Left_Bracket  => return "LEX007";
         when Whitespace_Before_Right_Bracket => return "LEX008";
         when Invalid_Comma                  => return "LEX009";
         when Token_Capacity_Exceeded        => return "LEX010";
         when Input_Too_Large                => return "LEX011";
      end case;
   end Code_Name;

   function Message (Code : Diagnostic_Code) return String is
   begin
      case Code is
         when No_Error                       => return "no error";
         when Unexpected_Control_Character  => return "unexpected control character";
         when Unterminated_Quoted_Text       => return "unterminated quoted text";
         when Invalid_Flag                   => return "invalid flag; expected --name";
         when Unmatched_Right_Bracket        => return "closing bracket has no matching opening bracket";
         when Unclosed_Left_Bracket          => return "opening bracket has no matching closing bracket";
         when Empty_Brackets                 => return "square brackets cannot be empty";
         when Whitespace_After_Left_Bracket  => return "whitespace is not allowed after '['";
         when Whitespace_Before_Right_Bracket => return "whitespace is not allowed before ']'";
         when Invalid_Comma                  => return "comma must separate two operands";
         when Token_Capacity_Exceeded        => return "token buffer capacity exceeded";
         when Input_Too_Large                => return "source exceeds the 16 MiB lexer limit";
      end case;
   end Message;

   function Format (Item : Diagnostic) return String is
   begin
      return Code_Name (Item.Code)
        & " at " & Number (Item.Location.Line)
        & ":" & Number (Item.Location.Column)
        & ": " & Message (Item.Code);
   end Format;
end Lexer_Diagnostics;
