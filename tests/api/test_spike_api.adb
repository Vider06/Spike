with Lexer_Types;
use type Lexer_Types.Token_Kind;
use type Lexer_Types.Diagnostic_Code;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Fixed;
with Spike_API;
with Lexer_Types;
with Lexer_Diagnostics;

procedure Test_Spike_API is
   Source : constant String := "out.term ""Hello""";
   Stream : Spike_API.Token_Stream_Handle :=
     Spike_API.Tokenize_Source (Source);
   Item : Spike_API.Token_Info;
begin
   Assert (Spike_API.Version = "1.1", "public API version");
   Assert (Spike_API.Is_Successful (Stream), "well-formed source succeeds");
   Assert (Spike_API.Remaining (Stream) = 2, "API exposes token count");
   Assert (Spike_API.Peek_Token (Stream).Kind = Lexer_Types.Word,
           "API peek returns the first token without consuming");
   Assert (Spike_API.Position (Stream) = 0, "peek does not advance API cursor");
   Assert (Spike_API.Text_Of (Source, Spike_API.Peek_Token (Stream)) = "out.term",
           "API token span returns the original word");

   Spike_API.Next_Token (Stream, Item);
   Assert (Item.Kind = Lexer_Types.Word, "next returns a word");
   Assert (Spike_API.Position (Stream) = 1, "next advances API cursor");
   Assert (Spike_API.Text_Of (Source, Item) = "out.term", "word span is exact");

   Spike_API.Next_Token (Stream, Item);
   Assert (Item.Kind = Lexer_Types.Quoted_Text, "quoted text has its own token kind");
   Assert (Spike_API.Text_Of (Source, Item) = """Hello""",
           "quoted token span retains delimiters");

   Spike_API.Reset (Stream);
   Assert (Spike_API.Position (Stream) = 0, "API reset restores cursor");

   declare
      Broken : constant Spike_API.Token_Stream_Handle :=
        Spike_API.Tokenize_Source ("""unterminated");
      Diagnostic : constant Lexer_Types.Diagnostic := Spike_API.Failure (Broken);
   begin
      Assert (not Spike_API.Is_Successful (Broken),
              "malformed source is returned as a structured diagnostic");
      Assert (Diagnostic.Code = Lexer_Types.Unterminated_Quoted_Text,
              "API preserves the lexical diagnostic code");
      Assert
        (Ada.Strings.Fixed.Index (Lexer_Diagnostics.Format (Diagnostic), "LEX002 at 1:1") = 1,
         "API diagnostics use the shared phase/code/location format");
   end;
end Test_Spike_API;
