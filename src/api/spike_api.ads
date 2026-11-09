with Lexer_Types;
with Verb_Table_Types;
with Parser_Types;

package Spike_API is
   --  Stable Ada-facing boundary for the Spike toolchain.
   --  Clients depend on this package rather than frontend implementation units.

   API_Version : constant String := "1.3";
   End_Of_Stream : exception;
   Invalid_Token_Span : exception;

   subtype Token_Info is Lexer_Types.Token;
   subtype Diagnostic_Info is Lexer_Types.Diagnostic;

   type Token_Stream_Handle is private;

   function Version return String;
   function Load_Verb_Table (Path : String) return Verb_Table_Types.Verb_Table;
   function Validate_Verb_Table (Document : String) return Verb_Table_Types.Verb_Table;
   function Tokenize_Source (Source : String) return Token_Stream_Handle;
   function Parse_Source
     (Source : String; Table : Verb_Table_Types.Verb_Table)
      return Parser_Types.Parse_Result;

   function Is_Successful (Stream : Token_Stream_Handle) return Boolean;
   function Failure (Stream : Token_Stream_Handle) return Diagnostic_Info;
   function Position (Stream : Token_Stream_Handle) return Natural;
   function Remaining (Stream : Token_Stream_Handle) return Natural;

   function Peek_Token
     (Stream : Token_Stream_Handle;
      Distance : Natural := 0) return Token_Info;

   procedure Next_Token
     (Stream : in out Token_Stream_Handle;
      Item : out Token_Info);

   procedure Reset (Stream : in out Token_Stream_Handle);

   function Text_Of
     (Source : String;
      Item : Token_Info) return String;

private
   subtype Token_Buffer is
     Lexer_Types.Token_Array (1 .. Lexer_Types.Max_Tokens);

   type Token_Stream_Handle is record
      Data    : Token_Buffer := [others => <>];
      Count   : Natural := 0;
      Cursor  : Natural := 0;
      Error   : Lexer_Types.Diagnostic :=
        (Phase => Lexer_Types.Lexing,
         Code => Lexer_Types.No_Error,
         Location => (Offset => 0, Line => 1, Column => 1));
   end record;
end Spike_API;
