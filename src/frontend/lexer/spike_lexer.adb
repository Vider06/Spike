with Lexer_Types;
package body Spike_Lexer
  with SPARK_Mode => On
is
   use Lexer_Types;
   function Is_Horizontal_Space (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT);
   function Is_Line_End (C : Character) return Boolean is
     (C = ASCII.LF or else C = ASCII.CR);
   function Is_Word_Delimiter (Source : String; I : Integer) return Boolean is
     (Is_Horizontal_Space (Source (I))
      or else Is_Line_End (Source (I))
      or else Source (I) = '[' or else Source (I) = ']'
      or else Source (I) = ',' or else Source (I) = '"'
      or else (Source (I) = '^' and then I < Source'Last
               and then Source (I + 1) = '^'));

   procedure Tokenize
     (Source : String;
      Result : out Lex_Result)
   is
      I : Integer := Source'First;
      Line : Positive := 1;
      Column : Positive := 1;
      At_Line_Start : Boolean := True;
      Failed : Boolean := False;

      procedure Fail (Code : Diagnostic_Code; At_Line, At_Column : Positive) is
      begin
         if not Failed then
            Result.Has_Error := True;
            Result.Error := (Code => Code, Line => At_Line, Column => At_Column);
            Failed := True;
         end if;
      end Fail;

      procedure Emit
        (Kind : Token_Kind;
         First_Offset, Last_Offset : Natural;
         At_Line, At_Column : Positive;
         Extra : Natural := 0)
      is
      begin
         if Result.Count = Max_Tokens then
            Fail (Token_Limit_Exceeded, At_Line, At_Column);
         else
            Result.Count := Result.Count + 1;
            Result.Tokens (Result.Count) :=
              (Kind => Kind, Start_Offset => First_Offset,
               End_Offset => Last_Offset, Line => At_Line,
               Column => At_Column, Auxiliary => Extra);
         end if;
      end Emit;

      function Offset return Natural is
        (Natural (I - Source'First));

      procedure Advance_One is
      begin
         I := I + 1;
         Column := Column + 1;
      end Advance_One;

   begin
      Result := (others => <>);
      while I <= Source'Last and then not Failed loop
         if At_Line_Start then
            declare
               First : constant Natural := Offset;
               Start_Column : constant Positive := Column;
               Width : Natural := 0;
            begin
               while I <= Source'Last
                 and then Is_Horizontal_Space (Source (I))
               loop
                  Width := Width + 1;
                  Advance_One;
               end loop;
               if Width > 0 then
                  Emit (Indentation, First, Offset, Line, Start_Column, Width);
               end if;
               At_Line_Start := False;
            end;
         elsif Is_Horizontal_Space (Source (I)) then
            Advance_One;
         elsif Is_Line_End (Source (I)) then
            declare
               First : constant Natural := Offset;
               Start_Line : constant Positive := Line;
               Start_Column : constant Positive := Column;
            begin
               if Source (I) = ASCII.CR and then I < Source'Last
                 and then Source (I + 1) = ASCII.LF
               then
                  I := I + 2;
               else
                  I := I + 1;
               end if;
               Emit (Newline, First, Offset, Start_Line, Start_Column);
               Line := Line + 1;
               Column := 1;
               At_Line_Start := True;
            end;
         elsif Source (I) = '^' and then I < Source'Last
           and then Source (I + 1) = '^'
         then
            declare
               First : constant Natural := Offset;
               Start_Line : constant Positive := Line;
               Start_Column : constant Positive := Column;
            begin
               while I <= Source'Last and then not Is_Line_End (Source (I)) loop
                  Advance_One;
               end loop;
               Emit (Comment, First, Offset, Start_Line, Start_Column);
            end;
         elsif Source (I) = '"' then
            declare
               First : constant Natural := Offset;
               Start_Line : constant Positive := Line;
               Start_Column : constant Positive := Column;
               Closed : Boolean := False;
            begin
               Advance_One;
               while I <= Source'Last and then not Closed and then not Failed loop
                  if Is_Line_End (Source (I)) then
                     Fail (Unterminated_String, Start_Line, Start_Column);
                  elsif Source (I) = Character'Val (16#5C#) then
                     Advance_One;
                     if I <= Source'Last and then not Is_Line_End (Source (I)) then
                        Advance_One;
                     else
                        Fail (Unterminated_String, Start_Line, Start_Column);
                     end if;
                  elsif Source (I) = '"' then
                     Advance_One;
                     Closed := True;
                  else
                     Advance_One;
                  end if;
               end loop;
               if not Failed then
                  if Closed then
                     Emit (Quoted_Text, First, Offset, Start_Line, Start_Column);
                  else
                     Fail (Unterminated_String, Start_Line, Start_Column);
                  end if;
               end if;
            end;
         elsif Source (I) = '[' then
            declare
               First : constant Natural := Offset;
               Start_Column : constant Positive := Column;
            begin
               if I = Source'Last or else Is_Horizontal_Space (Source (I + 1))
                 or else Is_Line_End (Source (I + 1))
               then
                  Fail (Bracket_Spacing, Line, Column);
               else
                  Advance_One;
                  Emit (Left_Bracket, First, Offset, Line, Start_Column);
               end if;
            end;
         elsif Source (I) = ']' then
            declare
               First : constant Natural := Offset;
               Start_Column : constant Positive := Column;
            begin
               if I = Source'First or else Is_Horizontal_Space (Source (I - 1))
                 or else Is_Line_End (Source (I - 1))
               then
                  Fail (Bracket_Spacing, Line, Column);
               else
                  Advance_One;
                  Emit (Right_Bracket, First, Offset, Line, Start_Column);
               end if;
            end;
         elsif Source (I) = ',' then
            declare
               First : constant Natural := Offset;
               Start_Column : constant Positive := Column;
            begin
               if I = Source'First or else I = Source'Last
                 or else not Is_Horizontal_Space (Source (I - 1))
                 or else not Is_Horizontal_Space (Source (I + 1))
               then
                  Fail (Comma_Spacing, Line, Column);
               else
                  Advance_One;
                  Emit (Comma, First, Offset, Line, Start_Column);
               end if;
            end;
         elsif Source (I) = '-' and then I < Source'Last
           and then Source (I + 1) = '-'
         then
            declare
               First : constant Natural := Offset;
               Start_Column : constant Positive := Column;
               Name_Start : Integer;
            begin
               Advance_One;
               Advance_One;
               Name_Start := I;
               if I > Source'Last
                 or else not (Source (I) = '_'
                   or else Source (I) in 'A' .. 'Z'
                   or else Source (I) in 'a' .. 'z')
               then
                  Fail (Invalid_Flag, Line, Start_Column);
               else
                  while I <= Source'Last
                    and then (Source (I) = '_'
                      or else Source (I) in 'A' .. 'Z'
                      or else Source (I) in 'a' .. 'z'
                      or else Source (I) in '0' .. '9')
                  loop
                     Advance_One;
                  end loop;
                  Emit (Flag, First, Offset, Line, Start_Column,
                        Natural (I - Name_Start));
               end if;
            end;
         else
            declare
               First : constant Natural := Offset;
               Start_Column : constant Positive := Column;
            begin
               while I <= Source'Last
                 and then not Is_Word_Delimiter (Source, I)
               loop
                  Advance_One;
               end loop;
               if Offset = First then
                  Fail (Invalid_Character, Line, Column);
               else
                  Emit (Word, First, Offset, Line, Start_Column);
               end if;
            end;
         end if;
      end loop;
   end Tokenize;
end Spike_Lexer;
