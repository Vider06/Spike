with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Token_Stream is
   function Create (Items : Token_Vectors.Vector) return Stream is
   begin
      return (Items => Items, Cursor => 0);
   end Create;

   function Position (Items : Stream) return Natural is (Items.Cursor);

   function Remaining (Items : Stream) return Natural is
   begin
      return Natural (Items.Items.Length) - Items.Cursor;
   end Remaining;

   function Peek (Items : Stream; Distance : Natural := 0) return Token is
   begin
      if Distance >= Natural'Last - Items.Cursor then
         raise End_Of_Stream;
      end if;
      declare
         Index : constant Natural := Items.Cursor + Distance + 1;
      begin
         if Index > Natural (Items.Items.Length) then
            raise End_Of_Stream;
         end if;
         return Items.Items (Positive (Index));
      end;
   end Peek;

   procedure Consume (Items : in out Stream; Value : out Token) is
   begin
      Value := Peek (Items);
      Items.Cursor := Items.Cursor + 1;
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
