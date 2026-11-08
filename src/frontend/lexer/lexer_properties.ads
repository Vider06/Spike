package Lexer_Properties
  with SPARK_Mode => On
is
   function Is_ASCII_Digit (Value : Character) return Boolean
     is (Value in '0' .. '9')
     with Global => null;

   function Is_ASCII_Hex_Digit (Value : Character) return Boolean
     is (Is_ASCII_Digit (Value)
         or else Value in 'a' .. 'f'
         or else Value in 'A' .. 'F')
     with Global => null;

   function Is_Identifier_Start (Value : Character) return Boolean
     is (Value = '_' or else Value in 'A' .. 'Z' or else Value in 'a' .. 'z')
     with Global => null;

   function Is_Identifier_Continue (Value : Character) return Boolean
     is (Is_Identifier_Start (Value) or else Is_ASCII_Digit (Value))
     with Global => null;

   function Valid_Span
     (Start_Offset, End_Offset, Source_Length : Natural) return Boolean
     is (Start_Offset <= End_Offset and then End_Offset <= Source_Length)
     with Global => null;

   function Valid_Token_Span
     (Start_Offset, End_Offset, Lexeme_Length : Natural) return Boolean
     is (Start_Offset < End_Offset
         and then End_Offset - Start_Offset = Lexeme_Length)
     with Global => null;

   function Spans_Are_Ordered
     (Previous_End, Next_Start : Natural) return Boolean
     is (Previous_End <= Next_Start)
     with Global => null;

   function Better_Match
     (Candidate_Length  : Natural;
      Candidate_Priority : Integer;
      Current_Length    : Natural;
      Current_Priority  : Integer) return Boolean
     is (Candidate_Length > Current_Length
         or else (Candidate_Length = Current_Length
                  and then Candidate_Priority > Current_Priority))
     with Global => null;

   function Match_Tied
     (Candidate_Length  : Natural;
      Candidate_Priority : Integer;
      Current_Length    : Natural;
      Current_Priority  : Integer) return Boolean
     is (Candidate_Length = Current_Length
         and then Candidate_Priority = Current_Priority)
     with Global => null;

   function Cursor_In_Bounds
     (Cursor, Token_Count : Natural) return Boolean
     is (Cursor <= Token_Count)
     with Global => null;

   procedure Advance_Offset
     (Offset : in out Natural; Amount, Source_Length : Natural)
     with
       Global => null,
       Pre => Offset <= Source_Length
         and then Amount <= Source_Length - Offset,
       Post => Offset = Offset'Old + Amount
         and then Offset <= Source_Length;

   procedure Advance_Cursor (Cursor : in out Natural; Token_Count : Natural)
     with
       Global => null,
       Pre => Cursor_In_Bounds (Cursor, Token_Count)
         and then Cursor < Token_Count,
       Post => Cursor = Cursor'Old + 1
         and then Cursor_In_Bounds (Cursor, Token_Count);
end Lexer_Properties;
