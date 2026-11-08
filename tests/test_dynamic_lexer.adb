with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Lexer_Config;
with Dynamic_Lexer;
with Token_Stream;

procedure Test_Dynamic_Lexer is
   Config : constant Lexer_Config.Lexer_Configuration :=
     Lexer_Config.Load ("config/lexer/tokens.json");
   Tokens : Token_Stream.Stream :=
     Dynamic_Lexer.Tokenize (Config, "out.term ""Hello"" " & ASCII.LF & "R0, 42");
   Item : Token_Stream.Token;
begin
   Assert (Token_Stream.Remaining (Tokens) = 7, "expected seven emitted tokens");
   Token_Stream.Expect (Tokens, "IDENTIFIER", Item);
   Assert (To_String (Item.Value) = "out", "identifier value");
   Token_Stream.Expect (Tokens, "DOT", Item);
   Token_Stream.Expect (Tokens, "IDENTIFIER", Item);
   Token_Stream.Expect (Tokens, "STRING", Item);
   Assert (To_String (Item.Value) = "Hello", "decoded JSON string");
   Token_Stream.Expect (Tokens, "IDENTIFIER", Item);
   Assert (Item.Line = 2 and Item.Column = 1, "line/column tracking");
   Token_Stream.Expect (Tokens, "COMMA", Item);
   Token_Stream.Expect (Tokens, "INTEGER", Item);
   Assert (Token_Stream.Remaining (Tokens) = 0, "stream exhausted");

   declare
      Mismatch : Token_Stream.Stream :=
        Dynamic_Lexer.Tokenize (Config, "word");
   begin
      begin
         Token_Stream.Expect (Mismatch, "INTEGER", Item);
         raise Program_Error with "mismatched Expect unexpectedly succeeded";
      exception
         when Token_Stream.Unexpected_Token => null;
      end;
      Assert (Token_Stream.Position (Mismatch) = 0,
              "Expect must not consume a mismatched token");
   end;

   declare
      Invalid : Boolean := False;
   begin
      begin
         declare
            Bad : constant Lexer_Config.Lexer_Configuration :=
              Lexer_Config.Validate
                ("{""schema_version"":""1.0"",""tokens"":["
                 & "{""name"":""A"",""matcher"":""identifier"","
                 & """unexpected"":true}]}");
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Lexer_Config.Config_Error => Invalid := True;
      end;
      Assert (Invalid, "unknown JSON fields must be rejected");
   end;

   declare
      Invalid : Boolean := False;
   begin
      begin
         declare
            Bad : constant Token_Stream.Stream :=
              Dynamic_Lexer.Tokenize (Config, "@");
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Dynamic_Lexer.Lexical_Error => Invalid := True;
      end;
      Assert (Invalid, "unknown source bytes must be rejected");
   end;

   Put_Line ("Dynamic lexer tests passed");
end Test_Dynamic_Lexer;
