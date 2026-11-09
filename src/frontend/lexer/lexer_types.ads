package Lexer_Types is
   pragma SPARK_Mode (On);

   Max_Source_Length : constant := 16 * 1_024 * 1_024;
   Max_Tokens        : constant := 4_096;

   type Token_Kind is
     (Word,
      Quoted_Text,
      Left_Bracket,
      Right_Bracket,
      Comma,
      Flag,
      Newline_Indent,
      Comment);

   type Token is record
      Kind          : Token_Kind := Word;
      Start_Offset  : Natural := 0;
      Length        : Natural := 0;
      Line          : Positive := 1;
      Column        : Positive := 1;
      Indent_Width  : Natural := 0;
   end record;

   type Token_Array is array (Positive range <>) of Token;

   type Diagnostic_Phase is
     (Lexing,
      Parsing,
      Scope_Resolution,
      Type_Checking,
      IR_Validation,
      Lowering,
      Execution);

   type Diagnostic_Code is
     (No_Error,
      Unexpected_Control_Character,
      Unterminated_Quoted_Text,
      Invalid_Flag,
      Unmatched_Right_Bracket,
      Unclosed_Left_Bracket,
      Empty_Brackets,
      Whitespace_After_Left_Bracket,
      Whitespace_Before_Right_Bracket,
      Invalid_Comma,
      Token_Capacity_Exceeded,
      Input_Too_Large,
      Unknown_Verb,
      No_Matching_Form,
      Unexpected_Token,
      AST_Capacity_Exceeded);

   type Source_Location is record
      Offset : Natural := 0;
      Line   : Positive := 1;
      Column : Positive := 1;
   end record;

   type Diagnostic is record
      Phase    : Diagnostic_Phase := Lexing;
      Code     : Diagnostic_Code := No_Error;
      Location : Source_Location;
   end record;
end Lexer_Types;
