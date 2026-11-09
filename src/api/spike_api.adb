with Dynamic_Lexer;

package body Spike_API is
   function Version return String is (API_Version);

   function Load_Lexer_Configuration
     (Path : String) return Lexer_Config.Lexer_Configuration
   is (Lexer_Config.Load (Path));

   function Validate_Lexer_Configuration
     (Document : String) return Lexer_Config.Lexer_Configuration
   is (Lexer_Config.Validate (Document));

   function Tokenize_Source
     (Configuration : Lexer_Config.Lexer_Configuration;
      Source        : String) return Token_Stream_Handle
   is
   begin
      return (Data => Dynamic_Lexer.Tokenize (Configuration, Source));
   end Tokenize_Source;

   function Position (Stream : Token_Stream_Handle) return Natural is
     (Token_Stream.Position (Stream.Data));

   function Remaining (Stream : Token_Stream_Handle) return Natural is
     (Token_Stream.Remaining (Stream.Data));

   function Convert (Item : Token_Stream.Token) return Token_Info is
     ((Kind         => Item.Kind,
       Lexeme       => Item.Lexeme,
       Value        => Item.Value,
       Start_Offset => Item.Start_Offset,
       End_Offset   => Item.End_Offset,
       Line         => Item.Line,
       Column       => Item.Column));

   function Peek_Token
     (Stream : Token_Stream_Handle; Distance : Natural := 0)
      return Token_Info
   is (Convert (Token_Stream.Peek (Stream.Data, Distance)));

   procedure Next_Token
     (Stream : in out Token_Stream_Handle; Item : out Token_Info)
   is
      Token : Token_Stream.Token;
   begin
      Token_Stream.Consume (Stream.Data, Token);
      Item := Convert (Token);
   end Next_Token;

   procedure Reset (Stream : in out Token_Stream_Handle) is
   begin
      Token_Stream.Reset (Stream.Data);
   end Reset;
end Spike_API;
