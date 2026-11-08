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


   declare
      Custom : constant Lexer_Config.Lexer_Configuration :=
        Lexer_Config.Validate
          ("{""schema_version"":""1.0"",""tokens"":["
           & "{""name"":""IDENT"",""matcher"":""identifier""},"
           & "{""name"":""KEYWORD_IF"",""matcher"":""literal"","
           & """value"":""if"",""priority"":20},"
           & "{""name"":""EQUAL"",""matcher"":""literal"",""value"":""==""},"
           & "{""name"":""ASSIGN"",""matcher"":""literal"",""value"":""=""},"
           & "{""name"":""COMMENT"",""matcher"":""line_comment"","
           & """value"":""#"",""emit"":false},"
           & "{""name"":""SPACE"",""matcher"":""whitespace"",""emit"":false}]}");
      Dynamic : Token_Stream.Stream :=
        Dynamic_Lexer.Tokenize (Custom, "if == name # hidden");
   begin
      Token_Stream.Expect (Dynamic, "KEYWORD_IF", Item);
      Token_Stream.Expect (Dynamic, "EQUAL", Item);
      Token_Stream.Expect (Dynamic, "IDENT", Item);
      Assert (To_String (Item.Value) = "name",
              "JSON-configured identifier must be tokenized dynamically");
      Assert (Token_Stream.Remaining (Dynamic) = 0,
              "configured comment and whitespace must be skipped");
   end;

   declare
      Numbers : Token_Stream.Stream :=
        Dynamic_Lexer.Tokenize (Config, "0xFF 0b101");
   begin
      Token_Stream.Expect (Numbers, "HEX_INTEGER", Item);
      Assert (To_String (Item.Value) = "0xFF", "hexadecimal literal");
      Token_Stream.Expect (Numbers, "BINARY_INTEGER", Item);
      Assert (To_String (Item.Value) = "0b101", "binary literal");
   end;

   declare
      Invalid : Boolean := False;
   begin
      begin
         declare
            Bad : constant Token_Stream.Stream :=
              Dynamic_Lexer.Tokenize
                (Config, Character'Val (16#D9#) & Character'Val (16#A1#));
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Dynamic_Lexer.Lexical_Error => Invalid := True;
      end;
      Assert (Invalid, "numeric matchers must accept ASCII digits only");
   end;

   declare
      Priority_Config : constant Lexer_Config.Lexer_Configuration :=
        Lexer_Config.Validate
          ("{""schema_version"":""1.0"",""tokens"":["
           & "{""name"":""LOW"",""matcher"":""identifier"",""priority"":0},"
           & "{""name"":""HIGH"",""matcher"":""identifier"",""priority"":10}]}");
      Priority_Stream : Token_Stream.Stream :=
        Dynamic_Lexer.Tokenize (Priority_Config, "dynamic");
   begin
      Token_Stream.Expect (Priority_Stream, "HIGH", Item);
      Assert (Token_Stream.Remaining (Priority_Stream) = 0,
              "priority resolves multiple definitions of the same matcher");
   end;

   declare
      Invalid : Boolean := False;
   begin
      begin
         declare
            Bad : constant Lexer_Config.Lexer_Configuration :=
              Lexer_Config.Validate
                ("{""schema_version"":""2.0"",""tokens"":["
                 & "{""name"":""IDENT"",""matcher"":""identifier""}]}");
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Lexer_Config.Config_Error => Invalid := True;
      end;
      Assert (Invalid, "unsupported JSON schema versions must be rejected");
   end;

   Put_Line ("Dynamic lexer tests passed");
end Test_Dynamic_Lexer;
