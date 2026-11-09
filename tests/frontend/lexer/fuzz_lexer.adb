with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Lexer;
with Lexer_Types;

procedure Fuzz_Lexer is
   use Lexer_Types;

   type Random_Word is mod 2 ** 32;
   State : Random_Word := 16#C0FFEE#;

   function Next_Byte return Natural is
   begin
      State := State * 1_664_525 + 1_013_904_223;
      return Natural (State mod 128);
   end Next_Byte;

begin
   for Round in 1 .. 2_000 loop
      pragma Unreferenced (Round);
      declare
         Source_Length : constant Natural := Next_Byte mod 97;
         Source : String (1 .. Source_Length);
         Tokens : Token_Array (1 .. 128);
         Count : Natural;
         Error : Diagnostic;
      begin
         for I in Source'Range loop
            Source (I) := Character'Val (Next_Byte);
         end loop;

         Lexer.Tokenize (Source, Tokens, Count, Error);
         Assert (Count <= Tokens'Length, "fuzz token count is bounded");

         if Error.Code = No_Error then
            if Count > 0 then
               declare
                  Previous_End : Natural := 0;
                  First_Token : Boolean := True;
               begin
                  for Offset in 0 .. Count - 1 loop
                     declare
                        Item : constant Token := Tokens (Tokens'First + Offset);
                     begin
                        Assert (Valid_Span (Item.Start_Offset, Item.Length, Source'Length),
                                "fuzz token span is non-empty and in bounds");
                        if not First_Token then
                           Assert (Previous_End <= Item.Start_Offset,
                                   "fuzz token spans are ordered and non-overlapping");
                        end if;
                        Previous_End := Item.Start_Offset + Item.Length;
                        First_Token := False;
                     end;
                  end loop;
               end;
            end if;
         end if;
      end;
   end loop;

   Put_Line ("Lexer deterministic fuzz tests passed (2000 source inputs)");
end Fuzz_Lexer;
