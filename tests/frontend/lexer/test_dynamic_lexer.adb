with Ada.Assertions; use Ada.Assertions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Lexer_Config;
with Dynamic_Lexer;
with Token_Stream;

procedure Test_Dynamic_Lexer is
   Config : constant Lexer_Config.Lexer_Configuration :=
     Lexer_Config.Load ("src/leng/lexer/tokens.json");
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

   declare
      Invalid_Items : Token_Stream.Token_Vectors.Vector;
      Invalid : Boolean := False;
   begin
      Invalid_Items.Append
        (Token_Stream.Token'
           (Kind => To_Unbounded_String ("BROKEN"),
            Lexeme => To_Unbounded_String ("x"),
            Value => To_Unbounded_String ("x"),
            Start_Offset => 2,
            End_Offset => 1,
            Line => 1,
            Column => 1));
      begin
         declare
            Bad_Stream : constant Token_Stream.Stream :=
              Token_Stream.Create (Invalid_Items, 3);
         begin
            pragma Unreferenced (Bad_Stream);
         end;
      exception
         when Token_Stream.Invalid_Stream => Invalid := True;
      end;
      Assert (Invalid, "stream creation rejects invalid token spans");
   end;

   declare
      Probe : Token_Stream.Stream := Dynamic_Lexer.Tokenize (Config, "a b");
      First : constant Token_Stream.Token := Token_Stream.Peek (Probe);
   begin
      Assert (To_String (First.Value) = "a", "peek does not consume");
      Assert (Token_Stream.Position (Probe) = 0, "peek preserves cursor");
      Token_Stream.Consume (Probe, Item);
      Token_Stream.Reset (Probe);
      Assert (Token_Stream.Position (Probe) = 0, "reset restores cursor");
      Assert (To_String (Token_Stream.Peek (Probe).Value) = "a",
              "peek after reset returns first token");
      begin
         declare
            Past_End : constant Token_Stream.Token :=
              Token_Stream.Peek (Probe, Natural'Last);
         begin
            pragma Unreferenced (Past_End);
            raise Program_Error with "oversized lookahead unexpectedly succeeded";
         end;
      exception
         when Token_Stream.End_Of_Stream => null;
      end;
   end;

   declare
      Maximal_Config : constant Lexer_Config.Lexer_Configuration :=
        Lexer_Config.Validate
          ("{""schema_version"":""1.0"",""tokens"":["
           & "{""name"":""GT"",""matcher"":""literal"",""value"":"">""},"
           & "{""name"":""SHIFT"",""matcher"":""literal"",""value"":"">>""},"
           & "{""name"":""SPACE"",""matcher"":""whitespace"",""emit"":false}]}");
      Maximal : Token_Stream.Stream :=
        Dynamic_Lexer.Tokenize (Maximal_Config, ">>");
   begin
      Token_Stream.Expect (Maximal, "SHIFT", Item);
      Assert (Token_Stream.Remaining (Maximal) = 0,
              "maximal munch chooses the longest configured literal");
   end;

   declare
      CRLF_Stream : Token_Stream.Stream :=
        Dynamic_Lexer.Tokenize (Config, "alpha" & ASCII.CR & ASCII.LF & "beta");
   begin
      Token_Stream.Expect (CRLF_Stream, "IDENTIFIER", Item);
      Token_Stream.Expect (CRLF_Stream, "IDENTIFIER", Item);
      Assert (Item.Line = 2 and Item.Column = 1,
              "CRLF advances to the next source line");
   end;

   declare
      Invalid : Boolean := False;
   begin
      begin
         declare
            Bad : constant Token_Stream.Stream :=
              Dynamic_Lexer.Tokenize (Config, """unterminated");
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Dynamic_Lexer.Lexical_Error => Invalid := True;
      end;
      Assert (Invalid, "unterminated quoted strings are rejected");
   end;

   declare
      Document : Unbounded_String :=
        To_Unbounded_String ("{""schema_version"":""1.0"",""tokens"":[");
   begin
      for I in 0 .. 675 loop
         declare
            First_Byte : constant Character :=
              Character'Val (Character'Pos ('A') + I / 26);
            Second_Byte : constant Character :=
              Character'Val (Character'Pos ('A') + I mod 26);
            Token_Name : constant String :=
              "TOKEN_" & Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Left);
            Token_Value : constant String := First_Byte & Second_Byte & "x";
         begin
            if I > 0 then
               Append (Document, ",");
            end if;
            Append
              (Document,
               "{""name"":""" & Token_Name
               & """,""matcher"":""literal"",""value"":"""
               & Token_Value & """}");
         end;
      end loop;
      Append
        (Document,
         ",{""name"":""SPACE"",""matcher"":""whitespace"",""emit"":false}]}");
      declare
         Large_Config : constant Lexer_Config.Lexer_Configuration :=
           Lexer_Config.Validate (To_String (Document));
         Large_Stream : Token_Stream.Stream :=
           Dynamic_Lexer.Tokenize (Large_Config, "ZZx");
      begin
         Token_Stream.Expect (Large_Stream, "TOKEN_675", Item);
         Assert (Token_Stream.Remaining (Large_Stream) = 0,
                 "large JSON rule sets use the compiled prefix index");
      end;
   end;

   declare
      Invalid : Boolean := False;
   begin
      begin
         declare
            Bad : constant Lexer_Config.Lexer_Configuration :=
              Lexer_Config.Validate
                ("{""schema_version"":""1.0"",""tokens"":["
                 & "{""name"":""IDENT_A"",""matcher"":""identifier""},"
                 & "{""name"":""IDENT_B"",""matcher"":""identifier""}]}");
         begin
            pragma Unreferenced (Bad);
         end;
      exception
         when Lexer_Config.Config_Error => Invalid := True;
      end;
      Assert (Invalid, "equal-priority identical generic matchers are ambiguous");
   end;

   Put_Line ("Dynamic lexer tests passed");
end Test_Dynamic_Lexer;
