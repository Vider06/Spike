with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

package Lexer_Config is
   pragma Elaborate_Body;

   Config_Error : exception;

   type Matcher_Kind is
     (Literal, Identifier, Decimal_Integer, Hex_Integer, Binary_Integer,
      Quoted_String, Whitespace, Line_Comment);

   type Token_Definition is record
      Name     : Ada.Strings.Unbounded.Unbounded_String;
      Matcher  : Matcher_Kind := Identifier;
      Value    : Ada.Strings.Unbounded.Unbounded_String;
      Priority : Integer := 0;
      Emit     : Boolean := True;
   end record;

   package Definition_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Token_Definition);

   type Lexer_Configuration is record
      Schema_Version : Ada.Strings.Unbounded.Unbounded_String;
      Definitions    : Definition_Vectors.Vector;
   end record;

   function Load (Path : String) return Lexer_Configuration;
   function Validate (Document : String) return Lexer_Configuration;
end Lexer_Config;
