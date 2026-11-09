with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Lexer_Config;
with Lexer_Types;
with Spike_API;

procedure Test_Spike_API is
   use type Lexer_Types.Token_Kind;
   Config : constant Lexer_Config.Lexer_Configuration :=
     Spike_API.Load_Lexer_Configuration ("src/leng/lexer/tokens.json");
   Stream : Spike_API.Token_Stream_Handle :=
     Spike_API.Tokenize_Source (Config, "out.term 42");
   Item : Spike_API.Token_Info;
begin
   Assert (Spike_API.Version = "1.0", "public API version");
   declare
      Lexed : constant Lexer_Types.Lex_Result := Spike_API.Lex_Source ("hello");
   begin
      Assert (not Lexed.Has_Error and then Lexed.Count = 1,
              "public API exposes the phase-one SPARK lexer");
      Assert (Lexed.Tokens (1).Kind = Lexer_Types.Word,
              "public API preserves token kind");
   end;
   Assert (Spike_API.Remaining (Stream) = 4, "API exposes emitted token count");
   Assert (To_String (Spike_API.Peek_Token (Stream).Kind) = "IDENTIFIER",
           "API peek returns the first token without consuming");
   Assert (Spike_API.Position (Stream) = 0, "peek does not advance API cursor");

   Spike_API.Next_Token (Stream, Item);
   Assert (To_String (Item.Value) = "out", "API returns identifier value");
   Assert (Spike_API.Position (Stream) = 1, "next advances API cursor");

   Spike_API.Reset (Stream);
   Assert (Spike_API.Position (Stream) = 0, "API reset restores cursor");

   declare
      Inline_Config : constant Lexer_Config.Lexer_Configuration :=
        Spike_API.Validate_Lexer_Configuration
          ("{""schema_version"":""1.0"",""tokens"":["
           & "{""name"":""WORD"",""matcher"":""identifier""}]}");
      Inline_Stream : Spike_API.Token_Stream_Handle :=
        Spike_API.Tokenize_Source (Inline_Config, "dynamic");
   begin
      Spike_API.Next_Token (Inline_Stream, Item);
      Assert (To_String (Item.Kind) = "WORD",
              "API validates caller-provided JSON and invokes the dynamic lexer");
   end;
end Test_Spike_API;
