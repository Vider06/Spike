with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNATCOLL.JSON;

package body Dynamic_Lexer is
   use Lexer_Config;
   use Token_Stream;

   type Candidate is record
      Found    : Boolean := False;
      Def      : Token_Definition;
      Lexeme   : Unbounded_String;
      Value    : Unbounded_String;
      Length   : Natural := 0;
   end record;

   function Is_Start (C : Character) return Boolean is
     (C = '_' or else C in 'A' .. 'Z' or else C in 'a' .. 'z');

   function Is_Continue (C : Character) return Boolean is
     (Is_Start (C) or else C in '0' .. '9');

   function Is_Space (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Starts (Source : String; At : Positive; Pattern : String)
     return Boolean
   is
   begin
      if Pattern'Length > Source'Last - At + 1 then
         return False;
      end if;
      for Offset in 0 .. Pattern'Length - 1 loop
         if Source (At + Offset) /= Pattern (Pattern'First + Offset) then
            return False;
         end if;
      end loop;
      return True;
   end Starts;

   function Match
     (Def : Token_Definition; Source : String; At : Positive)
      return Candidate
   is
      Result : Candidate;
      Last   : Natural := At - 1;
      C      : Character;
   begin
      if At > Source'Last then
         return Result;
      end if;

      case Def.Matcher is
         when Literal | Line_Comment =>
            declare
               Pattern : constant String := To_String (Def.Value);
            begin
               if not Starts (Source, At, Pattern) then return Result; end if;
               Last := At + Pattern'Length - 1;
               if Def.Matcher = Line_Comment then
                  while Last < Source'Last and then Source (Last + 1) /= ASCII.LF loop
                     Last := Last + 1;
                  end loop;
               end if;
            end;
         when Identifier =>
            if not Is_Start (Source (At)) then return Result; end if;
            Last := At;
            while Last < Source'Last and then Is_Continue (Source (Last + 1)) loop
               Last := Last + 1;
            end loop;
         when Decimal_Integer =>
            if Source (At) not in '0' .. '9' then return Result; end if;
            Last := At;
            while Last < Source'Last and then Source (Last + 1) in '0' .. '9' loop
               Last := Last + 1;
            end loop;
         when Hex_Integer | Binary_Integer =>
            if At + 2 > Source'Last or else Source (At) /= '0' then
               return Result;
            end if;
            if (Def.Matcher = Hex_Integer and then
                Source (At + 1) not in 'x' | 'X')
              or else (Def.Matcher = Binary_Integer and then
                       Source (At + 1) not in 'b' | 'B')
            then
               return Result;
            end if;
            Last := At + 2;
            while Last <= Source'Last loop
               C := Source (Last);
               exit when
                 (Def.Matcher = Hex_Integer and then
                    C not in '0' .. '9' and then C not in 'a' .. 'f'
                    and then C not in 'A' .. 'F')
                 or else (Def.Matcher = Binary_Integer and then C not in '0' .. '1');
               Last := Last + 1;
            end loop;
            Last := Last - 1;
            if Last = At + 1 then return Result; end if;
         when Whitespace =>
            if not Is_Space (Source (At)) then return Result; end if;
            Last := At;
            while Last < Source'Last and then Is_Space (Source (Last + 1)) loop
               Last := Last + 1;
            end loop;
         when Quoted_String =>
            if Source (At) /= '"' then return Result; end if;
            Last := At + 1;
            while Last <= Source'Last loop
               if Source (Last) = ASCII.LF or else Source (Last) = ASCII.CR then
                  return Result;
               elsif Source (Last) = Character'Val (16#5C#) then
                  Last := Last + 1;
                  if Last > Source'Last then return Result; end if;
               elsif Source (Last) = '"' then
                  declare
                     Parsed : constant GNATCOLL.JSON.Read_Result :=
                       GNATCOLL.JSON.Read (Source (At .. Last));
                  begin
                     if not Parsed.Success
                       or else Parsed.Value.Kind /= GNATCOLL.JSON.JSON_String_Type
                     then
                        return Result;
                     end if;
                     Result.Value := To_Unbounded_String
                       (GNATCOLL.JSON.Get (Parsed.Value));
                     Result.Length := Last - At + 1;
                     Result.Lexeme := To_Unbounded_String (Source (At .. Last));
                     Result.Def := Def;
                     Result.Found := True;
                     return Result;
                  end;
               end if;
               Last := Last + 1;
            end loop;
            return Result;
      end case;

      Result.Length := Last - At + 1;
      Result.Lexeme := To_Unbounded_String (Source (At .. Last));
      Result.Value := Result.Lexeme;
      Result.Def := Def;
      Result.Found := True;
      return Result;
   end Match;

   function Tokenize
     (Configuration : Lexer_Config.Lexer_Configuration;
      Source        : String) return Token_Stream.Stream
   is
      Output : Token_Vectors.Vector;
      Offset : Natural := 0;
      Line   : Positive := 1;
      Column : Positive := 1;
      Best   : Candidate;
      Tied   : Boolean;
   begin
      while Offset < Source'Length loop
         declare
            At : constant Positive := Source'First + Offset;
         begin
            Best := (others => <>);
            Tied := False;
            for Def of Configuration.Definitions loop
               declare
                  Current : constant Candidate := Match (Def, Source, At);
               begin
                  if Current.Found then
                     if not Best.Found or else Current.Length > Best.Length
                       or else (Current.Length = Best.Length
                                and then Current.Def.Priority > Best.Def.Priority)
                     then
                        Best := Current;
                        Tied := False;
                     elsif Current.Length = Best.Length
                       and then Current.Def.Priority = Best.Def.Priority
                     then
                        Tied := True;
                     end if;
                  end if;
               end;
            end loop;

            if not Best.Found then
               raise Lexical_Error with "unrecognized byte at "
                 & Line'Image & ":" & Column'Image
                 & " (offset" & Offset'Image & ")";
            end if;
            if Tied then
               raise Lexical_Error with "ambiguous token definitions at "
                 & Line'Image & ":" & Column'Image;
            end if;

            if Best.Def.Emit then
               Output.Append
                 ((Kind => Best.Def.Name,
                   Lexeme => Best.Lexeme,
                   Value => Best.Value,
                   Start_Offset => Offset,
                   End_Offset => Offset + Best.Length,
                   Line => Line,
                   Column => Column));
            end if;

            for I in At .. At + Best.Length - 1 loop
               if Source (I) = ASCII.LF then
                  Line := Line + 1;
                  Column := 1;
               else
                  Column := Column + 1;
               end if;
            end loop;
            Offset := Offset + Best.Length;
         end;
      end loop;
      return Token_Stream.Create (Output);
   end Tokenize;
end Dynamic_Lexer;
