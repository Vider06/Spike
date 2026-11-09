with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with Lexer;
with Lexer_Diagnostics;
with Lexer_Types;

procedure Test_Lexer is
   use Lexer_Types;

   procedure Expect_Error
     (Source : String;
      Expected_Code : Diagnostic_Code;
      Expected_Line : Positive;
      Expected_Column : Positive)
   is
      Tokens : Token_Array (1 .. 32);
      Count  : Natural;
      Error  : Diagnostic;
   begin
      Lexer.Tokenize (Source, Tokens, Count, Error);
      declare
         Formatted : constant String := Lexer_Diagnostics.Format (Error);
      begin
         Assert (Error.Code = Expected_Code, Formatted);
         Assert
           (Error.Location.Line = Expected_Line
            and then Error.Location.Column = Expected_Column,
            "diagnostic has the wrong source location: " & Formatted);
         Assert
           (Ada.Strings.Fixed.Index (Formatted, "LEX") = 1
            and then Ada.Strings.Fixed.Index (Formatted, " at ") > 0,
            "diagnostic must use the shared format: " & Formatted);
      end;
   end Expect_Error;

   function Read_Text_File (Path : String) return String is
      File   : File_Type;
      Result : Unbounded_String;
      First  : Boolean := True;
   begin
      Open (File, In_File, Path);
      while not End_Of_File (File) loop
         declare
            Line_Text : constant String := Get_Line (File);
         begin
            if not First then
               Append (Result, ASCII.LF);
            end if;
            Append (Result, Line_Text);
            First := False;
         end;
      end loop;
      Close (File);
      return To_String (Result);
   end Read_Text_File;

   function Number (Value : Natural) return String is
     (Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Left));

   function Render
     (Tokens : Token_Array;
      Count : Natural) return String
   is
      Output : Unbounded_String;
   begin
      if Count > 0 then
         for Offset in 0 .. Count - 1 loop
            declare
               Item : constant Token := Tokens (Tokens'First + Offset);
            begin
               if Offset > 0 then
                  Append (Output, ASCII.LF);
               end if;
               Append
                 (Output,
                  Lexer_Diagnostics.Token_Kind_Name (Item.Kind)
                  & " " & Number (Item.Line)
                  & ":" & Number (Item.Column)
                  & " " & Number (Item.Start_Offset)
                  & "+" & Number (Item.Length));
               if Item.Kind = Newline_Indent then
                  Append (Output, " indent=" & Number (Item.Indent_Width));
               end if;
            end;
         end loop;
      end if;
      return To_String (Output);
   end Render;

   Sample : constant String :=
     "out.term ""Hello, world!"" [""data""] first , second --inmut^^ note"
     & ASCII.LF & ASCII.HT & "next";
   Tokens : Token_Array (1 .. 64);
   Count  : Natural;
   Error  : Diagnostic;
begin
   Lexer.Tokenize (Sample, Tokens, Count, Error);
   Assert (Error.Code = No_Error, Lexer_Diagnostics.Format (Error));
   Assert (Count = 12, "sample emits all eight token kinds and the newline token");
   Assert (Tokens (1).Kind = Word, "dotted operation is one word");
   Assert (Tokens (2).Kind = Quoted_Text, "quoted text is one token");
   Assert (Tokens (3).Kind = Left_Bracket, "left bracket token");
   Assert (Tokens (4).Kind = Quoted_Text, "quoted text inside brackets");
   Assert (Tokens (5).Kind = Right_Bracket, "right bracket token");
   Assert (Tokens (6).Kind = Word, "word before comma");
   Assert (Tokens (7).Kind = Comma, "comma token");
   Assert (Tokens (8).Kind = Word, "word after comma");
   Assert (Tokens (9).Kind = Flag, "--inmut flag token");
   Assert (Tokens (10).Kind = Comment, "^^ comment token");
   Assert (Tokens (11).Kind = Newline_Indent, "newline and indentation are one token");
   Assert (Tokens (11).Indent_Width = 1, "tab indentation is retained");
   Assert (Tokens (12).Kind = Word, "token after indentation");
   Assert
     (Tokens (12).Line = 2 and then Tokens (12).Column = 2,
      "tab indentation advances the next token position");

   declare
      Bracketed : constant String := "[""hello world""]";
      Bracket_Tokens : Token_Array (1 .. 8);
      Bracket_Count : Natural;
      Bracket_Error : Diagnostic;
   begin
      Lexer.Tokenize
        (Bracketed, Bracket_Tokens, Bracket_Count, Bracket_Error);
      Assert (Bracket_Error.Code = No_Error, "spaces inside quoted text are allowed");
      Assert (Bracket_Count = 3, "bracketed quoted text has three tokens");
   end;

   declare
      CRLF_Source : constant String := "first" & ASCII.CR & ASCII.LF & "second";
      CRLF_Tokens : Token_Array (1 .. 8);
      CRLF_Count : Natural;
      CRLF_Error : Diagnostic;
   begin
      Lexer.Tokenize (CRLF_Source, CRLF_Tokens, CRLF_Count, CRLF_Error);
      Assert (CRLF_Error.Code = No_Error, "CRLF source succeeds");
      Assert (CRLF_Count = 3, "CRLF is emitted as one newline token");
      Assert (CRLF_Tokens (2).Kind = Newline_Indent, "CRLF token kind");
      Assert (CRLF_Tokens (3).Line = 2 and then CRLF_Tokens (3).Column = 1,
              "CRLF advances to the next line");
   end;

   declare
      Empty_Tokens : Token_Array (1 .. 4);
      Empty_Count : Natural;
      Empty_Error : Diagnostic;
   begin
      Lexer.Tokenize ("", Empty_Tokens, Empty_Count, Empty_Error);
      Assert (Empty_Error.Code = No_Error and then Empty_Count = 0,
              "empty source produces an empty token list");
   end;

   declare
      Golden_Source : constant String :=
        Read_Text_File ("tests/frontend/lexer/golden/basic.spike");
      Golden_Expected : constant String :=
        Read_Text_File ("tests/frontend/lexer/golden/basic.tokens");
      Golden_Tokens : Token_Array (1 .. 32);
      Golden_Count : Natural;
      Golden_Error : Diagnostic;
   begin
      Lexer.Tokenize (Golden_Source, Golden_Tokens, Golden_Count, Golden_Error);
      Assert (Golden_Error.Code = No_Error, Lexer_Diagnostics.Format (Golden_Error));
      Assert (Render (Golden_Tokens, Golden_Count) = Golden_Expected,
              "basic lexer golden output differs");
   end;

   Expect_Error
     ("""unterminated",
      Unterminated_Quoted_Text, 1, 1);
   Expect_Error
     ("""line" & ASCII.LF & "next",
      Unterminated_Quoted_Text, 1, 1);
   Expect_Error ("--", Invalid_Flag, 1, 1);
   Expect_Error (Character'Val (0) & "word", Unexpected_Control_Character, 1, 1);
   Expect_Error ("]", Unmatched_Right_Bracket, 1, 1);
   Expect_Error ("[value", Unclosed_Left_Bracket, 1, 1);
   Expect_Error ("[]", Empty_Brackets, 1, 1);
   Expect_Error ("[ ""value""]", Whitespace_After_Left_Bracket, 1, 2);
   Expect_Error ("[""value"" ]", Whitespace_Before_Right_Bracket, 1, 9);
   Expect_Error (", value", Invalid_Comma, 1, 1);
   Expect_Error ("value ,", Invalid_Comma, 1, 7);
   Expect_Error ("one ,, two", Invalid_Comma, 1, 5);
   Expect_Error ("first, second", Invalid_Comma, 1, 6);
   Expect_Error ("first ,second", Invalid_Comma, 1, 7);

   declare
      Small_Buffer : Token_Array (1 .. 1);
      Small_Count : Natural;
      Small_Error : Diagnostic;
   begin
      Lexer.Tokenize ("one two", Small_Buffer, Small_Count, Small_Error);
      Assert (Small_Error.Code = Token_Capacity_Exceeded,
              "token buffer overflow is a structured error");
      Assert
        (Small_Error.Location.Line = 1 and then Small_Error.Location.Column = 5,
         "token capacity errors identify the first token that did not fit");
   end;

   Put_Line ("Lexer phase-one tests passed");
end Test_Lexer;
