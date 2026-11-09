with Lexer_Properties;
with Lexer_Types;
with Parser_Types;
with Verb_Table_Types;
package body Parser is
   pragma SPARK_Mode (On);
   use Lexer_Types;
   use Parser_Types;
   use Verb_Table_Types;

   function Matches (Source : String; Item : Token; Value : Identifier) return Boolean is
      First : Natural;
   begin
      declare
         Prefix : constant Natural := (if Item.Kind = Flag then 2 else 0);
         Text_Length : constant Natural :=
           (if Item.Kind = Flag and then Item.Length >= 2 then Item.Length - 2
            else Item.Length);
      begin
         if Text_Length = 0 or else Text_Length /= Value.Length
           or else (Item.Kind = Flag and then Item.Length < 2)
           or else not Lexer_Properties.Valid_Span
             (Item.Start_Offset, Item.Length, Source'Length)
         then return False; end if;
         First := Source'First + Item.Start_Offset + Prefix;
      end;
      for Offset in 0 .. Item.Length - 1 loop
         if Source (First + Offset) /= Value.Data (Offset + 1) then return False; end if;
      end loop;
      return True;
   end Matches;

   function Is_Operand_Token (Kind : Token_Kind; Shape : Operand_Kind) return Boolean is
   begin
      case Shape is
         when Name => return Kind = Word;
         when Value => return Kind = Word or else Kind = Quoted_Text;
         when List | Bracket_Expression => return Kind = Left_Bracket;
      end case;
   end Is_Operand_Token;

   procedure Parse_Bracketed
     (Tokens : Token_Array; Last : Natural; Cursor : in out Natural; Valid : out Boolean)
   is
      Depth : Natural := 0;
   begin
      Valid := False;
      if Cursor > Last or else Tokens (Tokens'First + Cursor - 1).Kind /= Left_Bracket then return; end if;
      while Cursor <= Last loop
         declare
            Kind : constant Token_Kind := Tokens (Tokens'First + Cursor - 1).Kind;
         begin
            if Kind = Left_Bracket then
               Depth := Depth + 1;
            elsif Kind = Right_Bracket then
               if Depth = 0 then return; end if;
               Depth := Depth - 1;
               Cursor := Cursor + 1;
               if Depth = 0 then Valid := True; return; end if;
               continue;
            end if;
            Cursor := Cursor + 1;
         end;
      end loop;
   end Parse_Bracketed;

   procedure Try_Form
     (Source : String; Tokens : Token_Array; First : Natural; Last : Natural;
      Verb_Index : Natural; Form_Index : Natural; Form : Form_Entry;
      Candidate : out Statement; Accepted : out Boolean)
   is
      Cursor : Natural := First + 1;
      Operand_Number : Natural := 0;
      Flag_Number : Natural := 0;
      Good : Boolean := True;
   begin
      Candidate := (Verb_Token => First, Verb_Index => Verb_Index, Form_Index => Form_Index,
        Operand_Total => 0, Operands => [others => <>], Flag_Total => 0, Flags => [others => <>]);
      for Operand_Offset in 1 .. Form.Operand_Count loop
         if Operand_Offset > 1 then
            if Cursor > Last or else Tokens (Tokens'First + Cursor - 1).Kind /= Comma then
               Good := False; exit;
            end if;
            Cursor := Cursor + 1;
         end if;
         if Cursor > Last then Good := False; exit; end if;
         declare
            Current : constant Token := Tokens (Tokens'First + Cursor - 1);
            Shape : constant Operand_Kind := Form.Operands (Operand_Offset).Kind;
            Start : constant Natural := Cursor;
            Bracket_Valid : Boolean := False;
         begin
            if not Is_Operand_Token (Current.Kind, Shape) then Good := False; exit; end if;
            if Shape = Bracket_Expression or else Shape = List then
               Parse_Bracketed (Tokens, Last, Cursor, Bracket_Valid);
               if not Bracket_Valid then Good := False; exit; end if;
            else
               Cursor := Cursor + 1;
            end if;
            Operand_Number := Operand_Number + 1;
            Candidate.Operands (Operand_Number) := (First => Start, Count => Cursor - Start);
            Candidate.Operand_Total := Operand_Count (Operand_Number);
         end;
         for Keyword_Offset in 1 .. Form.Keyword_Count loop
            if Form.Keywords (Keyword_Offset).After_Operand = Operand_Offset then
               if Cursor > Last or else Tokens (Tokens'First + Cursor - 1).Kind /= Word
                 or else not Matches (Source, Tokens (Tokens'First + Cursor - 1),
                                      Form.Keywords (Keyword_Offset).Name)
               then Good := False; exit; end if;
               Cursor := Cursor + 1;
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
               if Current.Kind /= Flag then Good := False; exit; end if;
               for Flag_Offset in 1 .. Form.Flag_Count loop
                  if Matches (Source, Current, Form.Flags (Flag_Offset)) then Allowed := True; end if;
               end loop;
               if not Allowed or else Flag_Number = Max_Flags then Good := False; exit; end if;
               Flag_Number := Flag_Number + 1;
               Candidate.Flags (Flag_Number) := (First => Cursor, Count => 1);
               Candidate.Flag_Total := Flag_Count (Flag_Number);
               Cursor := Cursor + 1;
            end;
         end loop;
      end if;
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
      Matched : Boolean;
      Candidate : Statement;
      Selected : Statement;
      Verb_Token : Token;
   begin
      Result := (Tree => (Count => 0, Statements => [others => <>]),
                 Error => (Phase => Parsing, Code => No_Error,
                           Location => (Offset => 0, Line => 1, Column => 1)));
      while Cursor <= Token_Count loop
         while Cursor <= Token_Count
           and then (Tokens (Tokens'First + Cursor - 1).Kind = Newline_Indent
                     or else Tokens (Tokens'First + Cursor - 1).Kind = Comment)
         loop Cursor := Cursor + 1; end loop;
         exit when Cursor > Token_Count;

         First := Cursor;
         Last := First;
         while Last <= Token_Count
           and then Tokens (Tokens'First + Last - 1).Kind /= Newline_Indent
           and then Tokens (Tokens'First + Last - 1).Kind /= Comment
         loop Last := Last + 1; end loop;
         Last := Last - 1;

         Verb_Token := Tokens (Tokens'First + First - 1);
         if Verb_Token.Kind /= Word then
            Result.Error := (Phase => Parsing, Code => Unexpected_Token,
              Location => (Offset => Verb_Token.Start_Offset, Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;

         Found_Verb := 0;
         for Verb_Offset in 1 .. Table.Count loop
            if Matches (Source, Verb_Token, Table.Entries (Verb_Offset).Name) then
               Found_Verb := Verb_Offset; exit;
            end if;
         end loop;
         if Found_Verb = 0 then
            Result.Error := (Phase => Parsing, Code => Unknown_Verb,
              Location => (Offset => Verb_Token.Start_Offset, Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;

         Matched := False;
         for Form_Offset in 1 .. Table.Entries (Found_Verb).Form_Count loop
            Try_Form (Source, Tokens, First, Last, Found_Verb, Form_Offset,
              Table.Entries (Found_Verb).Forms (Form_Offset), Candidate, Matched);
            if Matched then Selected := Candidate; exit; end if;
         end loop;
         if not Matched then
            Result.Error := (Phase => Parsing, Code => No_Matching_Form,
              Location => (Offset => Verb_Token.Start_Offset, Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;
         if Result.Tree.Count = Max_Statements then
            Result.Error := (Phase => Parsing, Code => AST_Capacity_Exceeded,
              Location => (Offset => Verb_Token.Start_Offset, Line => Verb_Token.Line, Column => Verb_Token.Column));
            return;
         end if;
         Result.Tree.Count := Result.Tree.Count + 1;
         Result.Tree.Statements (Result.Tree.Count) := Selected;
         Cursor := Last + 1;
         if Cursor <= Token_Count and then Tokens (Tokens'First + Cursor - 1).Kind = Comment then
            Cursor := Cursor + 1;
         end if;
         if Cursor <= Token_Count and then Tokens (Tokens'First + Cursor - 1).Kind = Newline_Indent then
            Cursor := Cursor + 1;
         end if;
      end loop;
   end Parse;
end Parser;
