with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNATCOLL.JSON;
with Lexer_Properties;
use type GNATCOLL.JSON.JSON_Value_Type;

package body Dynamic_Lexer is
   use Lexer_Config;
   use Token_Stream;

   type Single_Character_Buckets is
     array (Character) of Lexer_Config.Definition_Vectors.Vector;
   type Prefix_Heads is array (Natural range 0 .. 65_535) of Natural;
   type Prefix_Links is array (Positive range 1 .. 4_096) of Natural;

   type Generic_Entry is record
      Available  : Boolean := False;
      Definition : Token_Definition;
   end record;
   type Generic_Matchers is array (Matcher_Kind) of Generic_Entry;

   type Candidate is record
      Found  : Boolean := False;
      Def    : Token_Definition;
      Lexeme : Unbounded_String;
      Value  : Unbounded_String;
      Length : Natural := 0;
   end record;

   function Is_Space (C : Character) return Boolean is
     (C = ' ' or else C = ASCII.HT or else C = ASCII.LF or else C = ASCII.CR);

   function Prefix_Key (First, Second : Character) return Natural is
     (Character'Pos (First) * 256 + Character'Pos (Second));

   function Starts (Source : String; Source_Position : Positive; Pattern : String)
     return Boolean
   is
   begin
      if Pattern'Length > Source'Last - Source_Position + 1 then
         return False;
      end if;
      for Offset in 0 .. Pattern'Length - 1 loop
         if Source (Source_Position + Offset) /= Pattern (Pattern'First + Offset) then
            return False;
         end if;
      end loop;
      return True;
   end Starts;

   function Match
     (Def : Token_Definition; Source : String; Source_Position : Positive)
      return Candidate
   is
      Result : Candidate;
      Last   : Natural := Source_Position - 1;
      C      : Character;
   begin
      if Source_Position > Source'Last then
         return Result;
      end if;

      case Def.Matcher is
         when Literal | Line_Comment =>
            declare
               Pattern : constant String := To_String (Def.Value);
            begin
               if not Starts (Source, Source_Position, Pattern) then
                  return Result;
               end if;
               Last := Source_Position + Pattern'Length - 1;
               if Def.Matcher = Line_Comment then
                  while Last < Source'Last and then Source (Last + 1) /= ASCII.LF loop
                     Last := Last + 1;
                  end loop;
               end if;
            end;
         when Identifier =>
            if not Lexer_Properties.Is_Identifier_Start (Source (Source_Position)) then
               return Result;
            end if;
            Last := Source_Position;
            while Last < Source'Last
              and then Lexer_Properties.Is_Identifier_Continue (Source (Last + 1))
            loop
               Last := Last + 1;
            end loop;
         when Decimal_Integer =>
            if not Lexer_Properties.Is_ASCII_Digit (Source (Source_Position)) then
               return Result;
            end if;
            Last := Source_Position;
            while Last < Source'Last
              and then Lexer_Properties.Is_ASCII_Digit (Source (Last + 1))
            loop
               Last := Last + 1;
            end loop;
         when Hex_Integer | Binary_Integer =>
            if Source_Position + 2 > Source'Last
              or else Source (Source_Position) /= '0'
            then
               return Result;
            end if;
            if (Def.Matcher = Hex_Integer
                and then Source (Source_Position + 1) not in 'x' | 'X')
              or else (Def.Matcher = Binary_Integer
                       and then Source (Source_Position + 1) not in 'b' | 'B')
            then
               return Result;
            end if;
            Last := Source_Position + 2;
            while Last <= Source'Last loop
               C := Source (Last);
               exit when
                 (Def.Matcher = Hex_Integer
                  and then not Lexer_Properties.Is_ASCII_Hex_Digit (C))
                 or else (Def.Matcher = Binary_Integer and then C not in '0' .. '1');
               Last := Last + 1;
            end loop;
            Last := Last - 1;
            if Last = Source_Position + 1 then
               return Result;
            end if;
         when Whitespace =>
            if not Is_Space (Source (Source_Position)) then
               return Result;
            end if;
            Last := Source_Position;
            while Last < Source'Last and then Is_Space (Source (Last + 1)) loop
               Last := Last + 1;
            end loop;
         when Quoted_String =>
            if Source (Source_Position) /= '"' then
               return Result;
            end if;
            Last := Source_Position + 1;
            while Last <= Source'Last loop
               if Source (Last) = ASCII.LF or else Source (Last) = ASCII.CR then
                  return Result;
               elsif Source (Last) = Character'Val (16#5C#) then
                  Last := Last + 1;
                  if Last > Source'Last then
                     return Result;
                  end if;
               elsif Source (Last) = '"' then
                  declare
                     Parsed : constant GNATCOLL.JSON.Read_Result :=
                       GNATCOLL.JSON.Read (Source (Source_Position .. Last));
                  begin
                     if not Parsed.Success
                       or else Parsed.Value.Kind /= GNATCOLL.JSON.JSON_String_Type
                     then
                        return Result;
                     end if;
                     Result.Value :=
                       To_Unbounded_String (GNATCOLL.JSON.Get (Parsed.Value));
                     Result.Length := Last - Source_Position + 1;
                     Result.Lexeme :=
                       To_Unbounded_String (Source (Source_Position .. Last));
                     Result.Def := Def;
                     Result.Found := True;
                     return Result;
                  end;
               end if;
               Last := Last + 1;
            end loop;
            return Result;
      end case;

      Result.Length := Last - Source_Position + 1;
      Result.Lexeme := To_Unbounded_String (Source (Source_Position .. Last));
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

      Single_Literals : Single_Character_Buckets;
      Prefix_Head : Prefix_Heads := (others => 0);
      Prefix_Next : Prefix_Links := (others => 0);
      Prefix_Rules : Definition_Vectors.Vector;
      Generic_Definitions : Generic_Matchers;

      procedure Consider (Def : Token_Definition) is
         Current : constant Candidate :=
           Match (Def, Source, Source'First + Offset);
      begin
         if Current.Found then
            if not Best.Found
              or else Lexer_Properties.Better_Match
                (Current.Length, Current.Def.Priority,
                 Best.Length, Best.Def.Priority)
            then
               Best := Current;
               Tied := False;
            elsif Lexer_Properties.Match_Tied
              (Current.Length, Current.Def.Priority,
               Best.Length, Best.Def.Priority)
            then
               Tied := True;
            end if;
         end if;
      end Consider;

      procedure Consider_Generic (Kind : Matcher_Kind) is
      begin
         if Generic_Definitions (Kind).Available then
            Consider (Generic_Definitions (Kind).Definition);
         end if;
      end Consider_Generic;

   begin
      if Source'Length > 16 * 1_024 * 1_024 then
         raise Lexical_Error with "source exceeds the 16 MiB lexer input limit";
      end if;
      if Configuration.Definitions.Length > 4_096 then
         raise Lexical_Error with "token definition limit (4096) exceeded";
      end if;

      --  Compile the JSON definitions into dispatch tables once per input.
      --  Single-byte and two-byte prefix indexes avoid scanning unrelated
      --  literals; generic matchers collapse to their highest-priority rule.
      for Def of Configuration.Definitions loop
         if Def.Matcher in Literal | Line_Comment then
            declare
               Pattern : constant String := To_String (Def.Value);
            begin
               if Pattern'Length = 0 then
                  raise Lexical_Error with "empty literal matcher in configuration";
               elsif Pattern'Length = 1 then
                  Single_Literals (Pattern (Pattern'First)).Append (Def);
               else
                  declare
                     Key : constant Natural :=
                       Prefix_Key (Pattern (Pattern'First),
                                   Pattern (Pattern'First + 1));
                  begin
                     Prefix_Rules.Append (Def);
                     Prefix_Next (Positive (Prefix_Rules.Length)) :=
                       Prefix_Head (Key);
                     Prefix_Head (Key) := Natural (Prefix_Rules.Length);
                  end;
               end if;
            end;
         else
            declare
               Matcher_Rule : Generic_Entry renames Generic_Definitions (Def.Matcher);
            begin
               if not Matcher_Rule.Available
                 or else Def.Priority > Matcher_Rule.Definition.Priority
               then
                  Matcher_Rule.Available := True;
                  Matcher_Rule.Definition := Def;
               elsif Def.Priority = Matcher_Rule.Definition.Priority then
                  raise Lexical_Error with
                    "ambiguous generic matcher definitions: "
                    & To_String (Def.Name);
               end if;
            end;
         end if;
      end loop;

      while Offset < Source'Length loop
         declare
            Source_Position : constant Positive := Source'First + Offset;
         begin
            Best := (others => <>);
            Tied := False;

            for Def of Single_Literals (Source (Source_Position)) loop
               Consider (Def);
            end loop;

            if Source_Position < Source'Last then
               declare
                  Index : Natural :=
                    Prefix_Head
                      (Prefix_Key (Source (Source_Position),
                                  Source (Source_Position + 1)));
               begin
                  while Index /= 0 loop
                     Consider (Prefix_Rules (Positive (Index)));
                     Index := Prefix_Next (Positive (Index));
                  end loop;
               end;
            end if;

            if Lexer_Properties.Is_Identifier_Start (Source (Source_Position)) then
               Consider_Generic (Identifier);
            elsif Lexer_Properties.Is_ASCII_Digit (Source (Source_Position)) then
               Consider_Generic (Decimal_Integer);
               Consider_Generic (Hex_Integer);
               Consider_Generic (Binary_Integer);
            elsif Source (Source_Position) = '"' then
               Consider_Generic (Quoted_String);
            elsif Is_Space (Source (Source_Position)) then
               Consider_Generic (Whitespace);
            end if;

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
                 (Token'
                    (Kind => Best.Def.Name,
                     Lexeme => Best.Lexeme,
                     Value => Best.Value,
                     Start_Offset => Offset,
                     End_Offset => Offset + Best.Length,
                     Line => Line,
                     Column => Column));
            end if;

            for I in Source_Position .. Source_Position + Best.Length - 1 loop
               if Source (I) = ASCII.LF then
                  Line := Line + 1;
                  Column := 1;
               else
                  Column := Column + 1;
               end if;
            end loop;
            Lexer_Properties.Advance_Offset
              (Offset, Best.Length, Source'Length);
         end;
      end loop;
      return Token_Stream.Create (Output);
   end Tokenize;
end Dynamic_Lexer;
