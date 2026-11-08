with Ada.Strings.Unbounded;
with Lexer_Config;
with Token_Stream;

package Spike_API is
   --  Stable Ada-facing boundary for the Spike toolchain.
   --  The manager and other Ada clients should depend on this package rather
   --  than importing frontend implementation units directly.

   API_Version : constant String := "1.0";

   type Token_Info is record
      Kind         : Ada.Strings.Unbounded.Unbounded_String;
      Lexeme       : Ada.Strings.Unbounded.Unbounded_String;
      Value        : Ada.Strings.Unbounded.Unbounded_String;
      Start_Offset : Natural := 0;
      End_Offset   : Natural := 0;
      Line         : Positive := 1;
      Column       : Positive := 1;
   end record;

   type Token_Stream_Handle is private;

   function Load_Lexer_Configuration
     (Path : String) return Lexer_Config.Lexer_Configuration;

   function Validate_Lexer_Configuration
     (Document : String) return Lexer_Config.Lexer_Configuration;

   function Tokenize_Source
     (Configuration : Lexer_Config.Lexer_Configuration;
      Source        : String) return Token_Stream_Handle;

   function Position (Stream : Token_Stream_Handle) return Natural;
   function Remaining (Stream : Token_Stream_Handle) return Natural;
   function Peek_Token
     (Stream : Token_Stream_Handle; Distance : Natural := 0)
      return Token_Info;
   procedure Next_Token
     (Stream : in out Token_Stream_Handle; Item : out Token_Info);
   procedure Reset (Stream : in out Token_Stream_Handle);

private
   type Token_Stream_Handle is record
      Data : Token_Stream.Stream;
   end record;
end Spike_API;
