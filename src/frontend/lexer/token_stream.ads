with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Token_Stream is
   pragma SPARK_Mode (Off);

   type Token is record
      Kind         : Ada.Strings.Unbounded.Unbounded_String;
      Lexeme       : Ada.Strings.Unbounded.Unbounded_String;
      Value        : Ada.Strings.Unbounded.Unbounded_String;
      Start_Offset : Natural := 0;
      End_Offset   : Natural := 0;
      Line         : Positive := 1;
      Column       : Positive := 1;
   end record;

   package Token_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Token);

   type Stream is private;
   End_Of_Stream   : exception;
   Unexpected_Token : exception;
   Invalid_Stream  : exception;

   --  Create validates token spans, lexeme lengths, kinds, and ordering.
   function Create
     (Items : Token_Vectors.Vector; Source_Length : Natural) return Stream;
   function Position (Items : Stream) return Natural;
   function Remaining (Items : Stream) return Natural;
   function Peek (Items : Stream; Distance : Natural := 0) return Token;
   procedure Consume (Items : in out Stream; Value : out Token);
   procedure Expect
     (Items : in out Stream; Kind : String; Value : out Token);
   procedure Reset (Items : in out Stream);

private
   type Stream is record
      Items  : Token_Vectors.Vector;
      Cursor : Natural := 0;
   end record;
end Token_Stream;
