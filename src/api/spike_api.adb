with Lexer_Properties;
with Lexer;
with Verb_Table_Config;
with Verb_Table_Types;

package body Spike_API is
   use Lexer_Types;

   function Version return String is (API_Version);

   function Load_Verb_Table (Path : String) return Verb_Table_Types.Verb_Table is
     (Verb_Table_Config.Load (Path));

   function Validate_Verb_Table (Document : String) return Verb_Table_Types.Verb_Table is
     (Verb_Table_Config.Validate (Document));

   function Tokenize_Source (Source : String) return Token_Stream_Handle is
      Result : Token_Stream_Handle;
   begin
      Lexer.Tokenize
        (Source,
         Result.Data,
         Result.Count,
         Result.Error);
      return Result;
   end Tokenize_Source;

   function Is_Successful (Stream : Token_Stream_Handle) return Boolean is
     (Stream.Error.Code = No_Error);

   function Failure (Stream : Token_Stream_Handle) return Diagnostic_Info is
     (Stream.Error);

   function Position (Stream : Token_Stream_Handle) return Natural is
     (Stream.Cursor);

   function Remaining (Stream : Token_Stream_Handle) return Natural is
     (Stream.Count - Stream.Cursor);

   function Peek_Token
     (Stream : Token_Stream_Handle;
      Distance : Natural := 0) return Token_Info
   is
   begin
      if Distance >= Remaining (Stream) then
         raise End_Of_Stream;
      end if;
      return Stream.Data (Stream.Cursor + Distance + 1);
   end Peek_Token;

   procedure Next_Token
     (Stream : in out Token_Stream_Handle;
      Item : out Token_Info)
   is
   begin
      Item := Peek_Token (Stream);
      Stream.Cursor := Stream.Cursor + 1;
   end Next_Token;

   procedure Reset (Stream : in out Token_Stream_Handle) is
   begin
      Stream.Cursor := 0;
   end Reset;

   function Text_Of
     (Source : String;
      Item : Token_Info) return String
   is
      First_Offset : Natural;
      Last_Offset  : Natural;
   begin
      if not Lexer_Properties.Valid_Span
        (Item.Start_Offset, Item.Length, Source'Length)
      then
         raise Invalid_Token_Span;
      end if;
      First_Offset := Source'First + Item.Start_Offset;
      Last_Offset := First_Offset + Item.Length - 1;
      return Source (First_Offset .. Last_Offset);
   end Text_Of;
end Spike_API;
