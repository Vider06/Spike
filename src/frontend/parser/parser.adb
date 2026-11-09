with Lexer_Properties;

package body Parser is
   pragma SPARK_Mode (On);
   use Lexer_Types;
   use Parser_Types;
   use Verb_Table_Types;

   function Matches (Source : String; Item : Token; Value : Identifier) return Boolean is
      First : Natural;
      Prefix : constant Natural := (if Item.Kind = Flag then 2 else 0);
      Text_Length : constant Natural :=
        (if Item.Kind = Flag and then Item.Length >= 2 then Item.Length - 2
         else Item.Length);
   begin
      if Text_Length = 0 or else Text_Length /= Value.Length
        or else (Item.Kind = Flag and then Item.Length < 2)
        or else not Lexer_Properties.Valid_Span
          (Item.Start_Offset, Item.Length, Source'Length)
      then
         return False;
      end if;
      First := Source'First + Item.Start_Offset + Prefix;
      for Offset in 0 .. Value.Length - 1 loop
         if Source (First + Offset) /= Value.Data (Offset + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Matches;

   function Is_Operand_Token (Kind : Token_Kind; Shape : Operand_Kind) return Boolean is
   begin
      case Shape is
         when Name =>
            return Kind = Word;
         when Value =>
            return Kind = Word or else Kind = Quoted_Text;
         when List | Bracket_Expression =>
            return Kind = Left_Bracket;
      end case;
   end Is_Operand_Token;

   procedure Parse_Bracketed
     (Tokens : Token_Array; Last : Natural; Cursor : in out Natural;
      Valid : out Boolean)
   is
      Depth : Natural := 0;
   begin
      Valid := False;
      if Cursor > Last
        or else Tokens (Tokens'First + Cursor - 1).Kind /= Left_Bracket
      then
         return;
      end if;
      while Cursor <= Last loop
         declare
            Kind : constant Token_Kind :=
              Tokens (Tokens'First + Cursor - 1).Kind;
         begin
            if Kind = Left_Bracket then
               Depth := Depth + 1;
            elsif Kind = Right_Bracket then
               if Depth = 0 then
                  return;
               end if;
               Depth := Depth - 1;
               Cursor := Cursor + 1;
               if Depth = 0 then
                  Valid := True;
                  return;
               end if;
            else
               Cursor := Cursor + 1;
            end if;
         end;
      end loop;
   end Parse_Bracketed;

   procedure Try_Form
     (Source : String; Tokens : Token_Array; First : Natural; Last : Natural;
      Verb_Index : Natural; Form_Index : Natural; Form : Form_Entry;
      Candidate : out Statement; Operand_Scratch : out Span_Array;
      Flag_Scratch : out Span_Array; Accepted : out Boolean)
   is
      Cursor : Natural := First + 1;
      Operand_Number : Natural := 0;
      Flag_Number : Natural := 0;
      Good : Boolean := True;
      Previous_Keyword : Boolean := False;
   begin
      Candidate :=
        (Verb_Token => First, Verb_Index => Verb_Index, Form_Index => Form_Index,
         Operand_First => 0, Operand_Total => 0, Flag_First => 0, Flag_Total => 0);
      Operand_Scratch := [others => <>];
      Flag_Scratch := [others => <>];

      for Operand_Offset in 1 .. Form.Operand_Count loop
         if Operand_Offset > 1 and then not Previous_Keyword then
            if Cursor > Last
              or else Tokens (Tokens'First + Cursor - 1).Kind /= Comma
            then
               Good := False;
               exit;
            end if;
            Cursor := Cursor + 1;
         end if;
         Previous_Keyword := False;

         if Cursor > Last then
            Good := False;
            exit;
         end if;

         declare
            Shape : constant Operand_Kind := Form.Operands (Operand_Offset).Kind;
            Start : Natural;
            Bracket_Valid : Boolean := False;
         begin
            if not Is_Operand_Token
              (Tokens (Tokens'First + Cursor - 1).Kind, Shape)
            then
               Good := False;
               exit;
            end if;
            Start := Cursor;
            if Shape = Bracket_Expression or else Shape = List then
               Parse_Bracketed (Tokens, Last, Cursor, Bracket_Valid);
               if not Bracket_Valid then
                  Good := False;
                  exit;
               end if;
            else
               Cursor := Cursor + 1;
            end if;

            Operand_Number := Operand_Number + 1;
            Operand_Scratch (Operand_Number) :=
              (First => Start, Count => Cursor - Start);

            if Form.Operands (Operand_Offset).Repeated then
               while Cursor <= Last
                 and then Tokens (Tokens'First + Cursor - 1).Kind = Comma
               loop
                  Cursor := Cursor + 1;
                  if Cursor > Last
                    or else not Is_Operand_Token
                      (Tokens (Tokens'First + Cursor - 1).Kind, Shape)
                  then
                     Good := False;
                     exit;
                  end if;
                  Start := Cursor;
                  if Shape = Bracket_Expression or else Shape = List then
                     Parse_Bracketed (Tokens, Last, Cursor, Bracket_Valid);
                     if not Bracket_Valid then
                        Good := False;
                        exit;
                     end if;
                  else
                     Cursor := Cursor + 1;
                  end if;
                  Operand_Number := Operand_Number + 1;
                  Operand_Scratch (Operand_Number) :=
                    (First => Start, Count => Cursor - Start);
               end loop;
            end if;
         end;

         exit when not Good;

         for Keyword_Offset in 1 .. Form.Keyword_Count loop
            if Form.Keywords (Keyword_Offset).After_Operand = Operand_Offset then
               if Cursor > Last
                 or else Tokens (Tokens'First + Cursor - 1).Kind not in Word | Equals
                 or else not Matches
                   (Source, Tokens (Tokens'First + Cursor - 1),
                    Form.Keywords (Keyword_Offset).Name)
               then
                  Good := False;
                  exit;
               end if;
               Cursor := Cursor + 1;
               Previous_Keyword := True;
            end if;
         end loop;
         exit when not Good;
      end loop;

      if Good then
         while Cursor <= Last loop
            declare
               Current : constant Token := Tokens (Tokens'First + Cursor - 1);
               Allowed : Boolean := False;
            begin
               if Current.Kind /= Flag then
                  Good := False;
                  exit;
               end if;
               for Flag_Offset in 1 .. Form.Flag_Count loop
                  if Matches (Source, Current, Form.Flags (Flag_Offset)) then
                     Allowed := True;
                  end if;
               end loop;
               if not Allowed then
                  Good := False;
                  exit;
               end if;
               Flag_Number := Flag_Number + 1;
               Flag_Scratch (Flag_Number) := (First => Cursor, Count => 1);
               Cursor := Cursor + 1;
            end;
         end loop;
      end if;

      Candidate.Operand_Total := Span_Count (Operand_Number);
      Candidate.Flag_Total := Span_Count (Flag_Number);
      Accepted := Good and then Cursor = Last + 1;
   end Try_Form;

   procedure Parse
     (Source : String; Tokens : Token_Array; Token_Count : Natural;
      Table : Verb_Table; Result : out Parse_Result)
   is
      Cursor : Natural := 1;
      First : Natural;
      Last : Natural;
      Found_Verb : Natural;
      Matched_Count : Natural;
      Matched : Boolean;
      Candidate : Statement;
      Selected : Statement;
      Candidate_Operands : Span_Array;
      Candidate_Flags : Span_Array;
      Selected_Operands : Span_Array;
      Selected_Flags : Span_Array;
      Verb_Token : Token;
   begin
      Result := (Tree => (others => <>),
                 Error => (Phase => Parsing, Code => No_Error,
                           Location => (Offset => 0, Line => 1, Column => 1)));

      while Cursor <= Token_Count loop
         while Cursor <= Token_Count
           and then (Tokens (Tokens'First + Cursor - 1).Kind = Newline_Indent
                     or else Tokens (Tokens'First + Cursor - 1).Kind = Comment)
         loop
            Cursor := Cursor + 1;
         end loop;
         exit when Cursor > Token_Count;

         First := Cursor;
         Last := First;
         while Last <= Token_Count
           and then Tokens (Tokens'First + Last - 1).Kind /= Newline_Indent
           and then Tokens (Tokens'First + Last - 1).Kind /= Comment
         loop
            Last := Last + 1;
         end loop;
         Last := Last - 1;

         Verb_Token := Tokens (Tokens'First + First - 1);
         if Verb_Token.Kind /= Word then
            Result.Error :=
              (Phase => Parsing, Code => Unexpected_Token,
               Location => (Offset => Verb_Token.Start_Offset,
                            Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;

         Found_Verb := 0;
         for Verb_Offset in 1 .. Table.Count loop
            if Matches (Source, Verb_Token, Table.Entries (Verb_Offset).Name) then
               Found_Verb := Verb_Offset;
               exit;
            end if;
         end loop;
         if Found_Verb = 0 then
            Result.Error :=
              (Phase => Parsing, Code => Unknown_Verb,
               Location => (Offset => Verb_Token.Start_Offset,
                            Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;

         Matched_Count := 0;
         for Form_Offset in 1 .. Table.Entries (Found_Verb).Form_Count loop
            Try_Form
              (Source, Tokens, First, Last, Found_Verb, Form_Offset,
               Table.Entries (Found_Verb).Forms (Form_Offset),
               Candidate, Candidate_Operands, Candidate_Flags, Matched);
            if Matched then
               Matched_Count := Matched_Count + 1;
               if Matched_Count = 1 then
                  Selected := Candidate;
                  Selected_Operands := Candidate_Operands;
                  Selected_Flags := Candidate_Flags;
               end if;
            end if;
         end loop;

         if Matched_Count = 0 then
            Result.Error :=
              (Phase => Parsing, Code => No_Matching_Form,
               Location => (Offset => Verb_Token.Start_Offset,
                            Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         elsif Matched_Count > 1 then
            Result.Error :=
              (Phase => Parsing, Code => Ambiguous_Form,
               Location => (Offset => Verb_Token.Start_Offset,
                            Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;

         if Result.Tree.Count = Max_AST_Entries
           or else Result.Tree.Operand_Count + Selected.Operand_Total > Max_AST_Entries
           or else Result.Tree.Flag_Count + Selected.Flag_Total > Max_AST_Entries
         then
            Result.Error :=
              (Phase => Parsing, Code => AST_Capacity_Exceeded,
               Location => (Offset => Verb_Token.Start_Offset,
                            Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;

         Result.Tree.Count := Result.Tree.Count + 1;
         if Selected.Operand_Total > 0 then
            Selected.Operand_First := Result.Tree.Operand_Count + 1;
            for Offset in 1 .. Selected.Operand_Total loop
               Result.Tree.Operands (Selected.Operand_First + Offset - 1) :=
                 Selected_Operands (Offset);
            end loop;
            Result.Tree.Operand_Count :=
              Result.Tree.Operand_Count + Selected.Operand_Total;
         end if;
         if Selected.Flag_Total > 0 then
            Selected.Flag_First := Result.Tree.Flag_Count + 1;
            for Offset in 1 .. Selected.Flag_Total loop
               Result.Tree.Flags (Selected.Flag_First + Offset - 1) :=
                 Selected_Flags (Offset);
            end loop;
            Result.Tree.Flag_Count := Result.Tree.Flag_Count + Selected.Flag_Total;
         end if;
         Result.Tree.Statements (Result.Tree.Count) := Selected;

         Cursor := Last + 1;
         if Cursor <= Token_Count
           and then Tokens (Tokens'First + Cursor - 1).Kind = Comment
         then
            Cursor := Cursor + 1;
         end if;
         if Cursor <= Token_Count
           and then Tokens (Tokens'First + Cursor - 1).Kind = Newline_Indent
         then
            Cursor := Cursor + 1;
         end if;
      end loop;
   end Parse;
end Parser;
