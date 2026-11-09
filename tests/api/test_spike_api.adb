with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Fixed;
with Spike_API;
with Lexer_Types;
with Lexer_Diagnostics;
with Verb_Table_Types;
with Parser_Types;
use type Lexer_Types.Token_Kind;
use type Lexer_Types.Diagnostic_Code;

procedure Test_Spike_API is
   Source : constant String := "out.term ""Hello""";
   Stream : Spike_API.Token_Stream_Handle :=
     Spike_API.Tokenize_Source (Source);
   Item : Spike_API.Token_Info;
begin
   Assert (Spike_API.Version = "1.4", "public API version");
   declare
      Verbs : constant Verb_Table_Types.Verb_Table :=
        Spike_API.Load_Verb_Table ("src/leng/verbs/verbs.json");
   begin
      Assert (Verbs.Count = 6, "public API loads the validated verb table");
      Assert (Verb_Table_Types.To_String (Verbs.Entries (5).Name) = "get",
              "public API preserves verb metadata");
   end;
   declare
      Table : constant Verb_Table_Types.Verb_Table :=
        Spike_API.Load_Verb_Table ("src/leng/verbs/verbs.json");
      Parsed : constant Parser_Types.Parse_Result :=
        Spike_API.Parse_Source (Source, Table);
   begin
      Assert (Parsed.Error.Code = Lexer_Types.No_Error,
              "public API parses source through the metadata-driven parser");
      Assert (Parsed.Tree.Count = 1,
              "public API returns the parsed statement tree");
   end;
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
