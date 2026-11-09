with Ada.Text_IO; use Ada.Text_IO;
with Lexer_Types;
with Lexer_Diagnostics;
with Spike_Lexer;

procedure Test_Spike_Lexer is
   use Lexer_Types;
   Result : Lex_Result;
   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         raise Program_Error with Message;
      end if;
   end Check;
begin
   Spike_Lexer.Tokenize
     ("part [""data""] global" & ASCII.LF
      & "    first , second ""Hello"" global --inmut ^^ note", Result);
   Check (not Result.Has_Error, "valid source must tokenize");
   Check (Result.Count >= 10, "expected token sequence");
   Check (Result.Tokens (1).Kind = Word, "first token is a word");
   Check (Result.Tokens (2).Kind = Left_Bracket, "left bracket token");
   Check (Result.Tokens (3).Kind = Quoted_Text, "quoted text token");
   Check (Result.Tokens (4).Kind = Right_Bracket, "right bracket token");
   declare
      Found_Indent : Boolean := False;
      Found_Flag : Boolean := False;
      Found_Comment : Boolean := False;
      Found_Comma : Boolean := False;
   begin
      for Index in 1 .. Result.Count loop
         Found_Indent := Found_Indent or else Result.Tokens (Index).Kind = Indentation;
         Found_Flag := Found_Flag or else Result.Tokens (Index).Kind = Flag;
         Found_Comment := Found_Comment or else Result.Tokens (Index).Kind = Comment;
         Found_Comma := Found_Comma or else Result.Tokens (Index).Kind = Comma;
      end loop;
      Check (Found_Indent, "indentation token must be emitted");
      Check (Found_Flag, "flag token must be emitted");
      Check (Found_Comment, "comment token must be emitted");
      Check (Found_Comma, "comma token must be emitted");
   end;
   Spike_Lexer.Tokenize ("item [ ""data""]", Result);
   Check (Result.Has_Error and then Result.Error.Code = Bracket_Spacing,
          "space after opening bracket must fail");
   Check (Result.Error.Line = 1 and then Result.Error.Column = 6,
          "opening bracket diagnostic position");
   Check (Lexer_Diagnostics.Format (Result.Error) =
          "E0004 at 1:6: invalid spacing inside square brackets",
          "diagnostics use the stable phase-one display format");
   Spike_Lexer.Tokenize ("item [""data ""]", Result);
   Check (Result.Has_Error and then Result.Error.Code = Bracket_Spacing,
          "space before closing bracket must fail");
   Spike_Lexer.Tokenize ("first ,second", Result);
   Check (Result.Has_Error and then Result.Error.Code = Comma_Spacing,
          "comma without following whitespace must fail");
   Spike_Lexer.Tokenize ("first, second", Result);
   Check (Result.Has_Error and then Result.Error.Code = Comma_Spacing,
          "comma without preceding whitespace must fail");
   Spike_Lexer.Tokenize ("""unterminated", Result);
   Check (Result.Has_Error and then Result.Error.Code = Unterminated_String,
          "unterminated string must fail");
   Spike_Lexer.Tokenize ("--", Result);
   Check (Result.Has_Error and then Result.Error.Code = Invalid_Flag,
          "empty flag must fail");
   Spike_Lexer.Tokenize ("one" & ASCII.LF & "    two", Result);
   Check (not Result.Has_Error, "indented line must be valid");
   Check (Result.Tokens (2).Kind = Newline, "newline token must be emitted");
   Check (Result.Tokens (3).Kind = Indentation, "indentation follows newline");
   Check (Result.Tokens (3).Auxiliary = 4, "indentation width is retained");
   Check (Result.Tokens (4).Line = 2 and then Result.Tokens (4).Column = 5,
          "source coordinates are one-based");
   Put_Line ("Spike lexer phase 1 tests passed");
end Test_Spike_Lexer;
