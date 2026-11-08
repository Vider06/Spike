with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded;
with Lexer_Config;
with Dynamic_Lexer;
with Token_Stream;

procedure Fuzz_Dynamic_Lexer is
   type Random_Word is mod 2 ** 32;
   State : Random_Word := 16#C0FFEE#;

   function Next_Byte return Natural is
   begin
      State := State * 1_664_525 + 1_013_904_223;
      return Natural (State mod 128);
   end Next_Byte;

   Config : constant Lexer_Config.Lexer_Configuration :=
     Lexer_Config.Load ("config/lexer/tokens.json");
begin
   for Round in 1 .. 2_000 loop
      pragma Unreferenced (Round);
      declare
         Source_Length : constant Natural := Next_Byte mod 97;
         Source : String (1 .. Source_Length);
      begin
         for I in Source'Range loop
            Source (I) := Character'Val (Next_Byte);
         end loop;

         begin
            declare
               Stream : Token_Stream.Stream :=
                 Dynamic_Lexer.Tokenize (Config, Source);
               Previous_End : Natural := 0;
               First_Token : Boolean := True;
               Item : Token_Stream.Token;
            begin
               while Token_Stream.Remaining (Stream) > 0 loop
                  Token_Stream.Consume (Stream, Item);
                  Assert (Item.Start_Offset < Item.End_Offset,
                          "fuzz produced an empty token span");
                  Assert (Item.End_Offset - Item.Start_Offset =
                            Natural (Ada.Strings.Unbounded.Length (Item.Lexeme)),
                          "fuzz token span/lexeme mismatch");
                  if not First_Token then
                     Assert (Previous_End <= Item.Start_Offset,
                             "fuzz produced overlapping token spans");
                  end if;
                  Previous_End := Item.End_Offset;
                  First_Token := False;
               end loop;
               Assert (Token_Stream.Remaining (Stream) = 0,
                       "fuzz stream must terminate at EOF");
            end;
         exception
            when Dynamic_Lexer.Lexical_Error =>
               null;
         end;
      end;
   end loop;

   for Round in 1 .. 512 loop
      pragma Unreferenced (Round);
      declare
         Document_Length : constant Natural := Next_Byte mod 129;
         Document : String (1 .. Document_Length);
      begin
         for I in Document'Range loop
            Document (I) := Character'Val (Next_Byte);
         end loop;
         begin
            declare
               Candidate : constant Lexer_Config.Lexer_Configuration :=
                 Lexer_Config.Validate (Document);
            begin
               pragma Unreferenced (Candidate);
            end;
         exception
            when Lexer_Config.Config_Error =>
               null;
         end;
      end;
   end loop;

   Put_Line ("Dynamic lexer deterministic fuzz tests passed (2000 source and 512 JSON inputs)");
end Fuzz_Dynamic_Lexer;
