with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Lexer_Properties;

package body Token_Stream is
   function Create
     (Items : Token_Vectors.Vector; Source_Length : Natural) return Stream is
      Previous_End : Natural := 0;
      First_Item   : Boolean := True;
   begin
      for Item of Items loop
         if Length (Item.Kind) = 0 or else Length (Item.Lexeme) = 0 then
            raise Invalid_Stream with "tokens require non-empty kind and lexeme";
         end if;
         if not Lexer_Properties.Valid_Span
           (Item.Start_Offset, Item.End_Offset, Source_Length)
         then
            raise Invalid_Stream with "token span lies outside the source buffer";
         end if;
         if not Lexer_Properties.Valid_Token_Span
           (Item.Start_Offset, Item.End_Offset, Length (Item.Lexeme))
         then
            raise Invalid_Stream with "token span does not match its lexeme length";
         end if;
         if not First_Item
           and then not Lexer_Properties.Spans_Are_Ordered
             (Previous_End, Item.Start_Offset)
         then
            raise Invalid_Stream with "token spans overlap or are out of order";
         end if;
         Previous_End := Item.End_Offset;
         First_Item := False;
      end loop;
      return (Items => Items, Cursor => 0);
   end Create;

   function Position (Items : Stream) return Natural is (Items.Cursor);

   function Remaining (Items : Stream) return Natural is
   begin
      if not Lexer_Properties.Cursor_In_Bounds
        (Items.Cursor, Natural (Items.Items.Length))
      then
         raise Invalid_Stream with "token stream cursor invariant violated";
      end if;
      return Natural (Items.Items.Length) - Items.Cursor;
   end Remaining;

   function Peek (Items : Stream; Distance : Natural := 0) return Token is
      Count : constant Natural := Natural (Items.Items.Length);
   begin
      if not Lexer_Properties.Cursor_In_Bounds (Items.Cursor, Count)
        or else Distance >= Natural'Last - Items.Cursor
      then
         raise End_Of_Stream;
      end if;
      declare
         Index : constant Natural := Items.Cursor + Distance + 1;
      begin
         if Index > Count then
            raise End_Of_Stream;
         end if;
         return Items.Items (Positive (Index));
      end;
   end Peek;

   procedure Consume (Items : in out Stream; Value : out Token) is
      Count : constant Natural := Natural (Items.Items.Length);
   begin
      Value := Peek (Items);
      Lexer_Properties.Advance_Cursor (Items.Cursor, Count);
   end Consume;

   procedure Expect
     (Items : in out Stream; Kind : String; Value : out Token)
   is
      Candidate : constant Token := Peek (Items);
   begin
      if To_String (Candidate.Kind) /= Kind then
         raise Unexpected_Token with "expected " & Kind & ", found "
           & To_String (Candidate.Kind) & " at"
           & Candidate.Line'Image & ":" & Candidate.Column'Image;
      end if;
      Consume (Items, Value);
   end Expect;

   procedure Reset (Items : in out Stream) is
   begin
      Items.Cursor := 0;
   end Reset;
end Token_Stream;
