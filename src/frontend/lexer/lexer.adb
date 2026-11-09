with Lexer_Types;
with Lexer_Properties;

package body Lexer is
   pragma SPARK_Mode (On);
   use Lexer_Types;

   procedure Tokenize
     (Source      : String;
      Tokens      : out Token_Array;
      Token_Count : out Natural;
      Error       : out Diagnostic)
   is
      Cursor        : Natural := 0;
      Line          : Positive := 1;
      Column        : Positive := 1;
      Bracket_Depth : Natural := 0;
      Opening       : Source_Location := (Offset => 0, Line => 1, Column => 1);
      Failed        : Boolean := False;

      function Character_At (Offset : Natural) return Character is
        (Source (Source'First + Offset));

      function Starts_Comment (Offset : Natural) return Boolean is
        (Offset + 1 < Source'Length
         and then Character_At (Offset) = '^'
         and then Character_At (Offset + 1) = '^');

      function Is_Delimiter (Offset : Natural) return Boolean is
        (Lexer_Properties.Is_Horizontal_Space (Character_At (Offset))
         or else Lexer_Properties.Is_Line_Break (Character_At (Offset))
         or else Character_At (Offset) in '[' | ']' | ',' | '"'
         or else Starts_Comment (Offset));

      function Is_Control (Item : Character) return Boolean is
        (Character'Pos (Item) < 32 or else Character'Pos (Item) = 127);

      procedure Fail
        (Code   : Diagnostic_Code;
         Offset : Natural;
         At_Line : Positive;
         At_Column : Positive)
      is
      begin
         if not Failed then
            Error :=
              (Phase => Lexing,
               Code => Code,
               Location =>
                 (Offset => Offset, Line => At_Line, Column => At_Column));
            Failed := True;
         end if;
      end Fail;

      procedure Emit
        (Kind         : Token_Kind;
         Start_Offset : Natural;
         Span_Length  : Natural;
         At_Line      : Positive;
         At_Column    : Positive;
         Indent_Width : Natural := 0)
      is
         Slot : Positive;
      begin
         if Token_Count >= Tokens'Length then
            Fail (Token_Capacity_Exceeded, Start_Offset, At_Line, At_Column);
         else
            Slot := Tokens'First + Token_Count;
            Tokens (Slot) :=
              (Kind => Kind,
               Start_Offset => Start_Offset,
               Length => Span_Length,
               Line => At_Line,
               Column => At_Column,
               Indent_Width => Indent_Width);
            Token_Count := Token_Count + 1;
         end if;
      end Emit;

      procedure Validate_Commas is
         Slot      : Positive;
         Last_Slot : Positive;
      begin
         if Token_Count > 0 and then not Failed then
            Last_Slot := Tokens'First + Token_Count - 1;
            for Offset in 0 .. Token_Count - 1 loop
               Slot := Tokens'First + Offset;
               if Tokens (Slot).Kind = Comma then
                  declare
                     Comma_Offset : constant Natural :=
                       Tokens (Slot).Start_Offset;
                  begin
                     if Slot = Tokens'First or else Slot = Last_Slot then
                        Fail
                          (Invalid_Comma,
                           Comma_Offset,
                           Tokens (Slot).Line,
                           Tokens (Slot).Column);
                     elsif Comma_Offset = 0
                       or else Comma_Offset + 1 >= Source'Length
                     then
                        Fail
                          (Invalid_Comma,
                           Comma_Offset,
                           Tokens (Slot).Line,
                           Tokens (Slot).Column);
                     elsif not Lexer_Properties.Is_Horizontal_Space
                       (Character_At (Comma_Offset - 1))
                       or else not Lexer_Properties.Is_Horizontal_Space
                         (Character_At (Comma_Offset + 1))
                     then
                        Fail
                          (Invalid_Comma,
                           Comma_Offset,
                           Tokens (Slot).Line,
                           Tokens (Slot).Column);
                     elsif not Lexer_Properties.Can_Precede_Comma
                       (Tokens (Slot - 1).Kind)
                       or else not Lexer_Properties.Can_Follow_Comma
                         (Tokens (Slot + 1).Kind)
                     then
                        Fail
                          (Invalid_Comma,
                           Comma_Offset,
                           Tokens (Slot).Line,
                           Tokens (Slot).Column);
                     end if;
                  end;
               end if;
               exit when Failed;
            end loop;
         end if;
      end Validate_Commas;

   begin
      Tokens := [others => <>];
      Token_Count := 0;
      Error :=
        (Phase => Lexing,
         Code => No_Error,
         Location => (Offset => 0, Line => 1, Column => 1));

      if Source'Length > Max_Source_Length then
         Fail (Input_Too_Large, 0, 1, 1);
      end if;

      while Cursor < Source'Length and then not Failed loop
         declare
            Current  : constant Character := Character_At (Cursor);
            Start    : constant Natural := Cursor;
            Start_Line   : constant Positive := Line;
            Start_Column : constant Positive := Column;
         begin
            if Lexer_Properties.Is_Horizontal_Space (Current) then
               Cursor := Cursor + 1;
               Column := Column + 1;

            elsif Lexer_Properties.Is_Line_Break (Current) then
               declare
                  Indent : Natural := 0;
               begin
                  if Current = ASCII.CR
                    and then Cursor + 1 < Source'Length
                    and then Character_At (Cursor + 1) = ASCII.LF
                  then
                     Cursor := Cursor + 2;
                  else
                     Cursor := Cursor + 1;
                  end if;

                  Line := Line + 1;
                  Column := 1;
                  while Cursor < Source'Length
                    and then Lexer_Properties.Is_Horizontal_Space (Character_At (Cursor))
                  loop
                     Cursor := Cursor + 1;
                     Column := Column + 1;
                     Indent := Indent + 1;
                  end loop;

                  Emit
                    (Newline_Indent,
                     Start,
                     Cursor - Start,
                     Start_Line,
                     Start_Column,
                     Indent);
               end;

            elsif Starts_Comment (Cursor) then
               while Cursor < Source'Length
                 and then not Lexer_Properties.Is_Line_Break (Character_At (Cursor))
               loop
                  Cursor := Cursor + 1;
                  Column := Column + 1;
               end loop;
               Emit
                 (Comment,
                  Start,
                  Cursor - Start,
                  Start_Line,
                  Start_Column);

            elsif Current = '"' then
               declare
                  Closed : Boolean := False;
               begin
                  Cursor := Cursor + 1;
                  Column := Column + 1;

                  while Cursor < Source'Length and then not Failed loop
                     declare
                        Item : constant Character := Character_At (Cursor);
                     begin
                        if Lexer_Properties.Is_Line_Break (Item) then
                           Fail
                             (Unterminated_Quoted_Text,
                              Start,
                              Start_Line,
                              Start_Column);
                        elsif Item = Character'Val (16#5C#) then
                           if Cursor + 1 >= Source'Length
                             or else Lexer_Properties.Is_Line_Break
                               (Character_At (Cursor + 1))
                           then
                              Fail
                                (Unterminated_Quoted_Text,
                                 Start,
                                 Start_Line,
                                 Start_Column);
                           else
                              Cursor := Cursor + 2;
                              Column := Column + 2;
                           end if;
                        elsif Item = '"' then
                           Cursor := Cursor + 1;
                           Column := Column + 1;
                           Closed := True;
                           exit;
                        else
                           Cursor := Cursor + 1;
                           Column := Column + 1;
                        end if;
                     end;
                  end loop;

                  if not Failed then
                     if Closed then
                        Emit
                          (Quoted_Text,
                           Start,
                           Cursor - Start,
                           Start_Line,
                           Start_Column);
                     else
                        Fail
                          (Unterminated_Quoted_Text,
                           Start,
                           Start_Line,
                           Start_Column);
                     end if;
                  end if;
               end;

            elsif Current = '[' then
               if Cursor + 1 < Source'Length
                 and then Character_At (Cursor + 1) = ']'
               then
                  Fail (Empty_Brackets, Start, Start_Line, Start_Column);
               elsif Cursor + 1 < Source'Length
                 and then Lexer_Properties.Is_Horizontal_Space
                   (Character_At (Cursor + 1))
               then
                  Fail
                    (Whitespace_After_Left_Bracket,
                     Cursor + 1,
                     Line,
                     Column + 1);
               else
                  if Bracket_Depth = 0 then
                     Opening :=
                       (Offset => Start, Line => Start_Line, Column => Start_Column);
                  end if;
                  Bracket_Depth := Bracket_Depth + 1;
                  Cursor := Cursor + 1;
                  Column := Column + 1;
                  Emit
                    (Left_Bracket, Start, 1, Start_Line, Start_Column);
               end if;

            elsif Current = ']' then
               if Bracket_Depth = 0 then
                  Fail (Unmatched_Right_Bracket, Start, Start_Line, Start_Column);
               elsif Cursor > 0
                 and then Lexer_Properties.Is_Horizontal_Space (Character_At (Cursor - 1))
               then
                  Fail
                    (Whitespace_Before_Right_Bracket,
                     Cursor - 1,
                     Line,
                     Column - 1);
               else
                  Bracket_Depth := Bracket_Depth - 1;
                  Cursor := Cursor + 1;
                  Column := Column + 1;
                  Emit
                    (Right_Bracket, Start, 1, Start_Line, Start_Column);
               end if;

            elsif Current = ',' then
               Cursor := Cursor + 1;
               Column := Column + 1;
               Emit (Comma, Start, 1, Start_Line, Start_Column);

            elsif Current = '-'
              and then Cursor + 1 < Source'Length
              and then Character_At (Cursor + 1) = '-'
            then
               declare
                  Name_Length : Natural := 0;
               begin
                  Cursor := Cursor + 2;
                  Column := Column + 2;

                  while Cursor < Source'Length
                    and then not Is_Delimiter (Cursor)
                    and then not Failed
                  loop
                     declare
                        Item : constant Character := Character_At (Cursor);
                        Valid : constant Boolean :=
                          (if Name_Length = 0
                           then Lexer_Properties.Is_Flag_Name_Start (Item)
                           else Lexer_Properties.Is_Flag_Name_Continue (Item));
                     begin
                        if not Valid then
                           Fail (Invalid_Flag, Cursor, Line, Column);
                        else
                           Name_Length := Name_Length + 1;
                           Cursor := Cursor + 1;
                           Column := Column + 1;
                        end if;
                     end;
                  end loop;

                  if not Failed then
                     if Name_Length = 0 then
                        Fail (Invalid_Flag, Start, Start_Line, Start_Column);
                     else
                        Emit (Flag, Start, Cursor - Start, Start_Line, Start_Column);
                     end if;
                  end if;
               end;

            else
               while Cursor < Source'Length
                 and then not Is_Delimiter (Cursor)
                 and then not Failed
               loop
                  declare
                     Item : constant Character := Character_At (Cursor);
                  begin
                     if Is_Control (Item) then
                        Fail
                          (Unexpected_Control_Character,
                           Cursor,
                           Line,
                           Column);
                     else
                        Cursor := Cursor + 1;
                        Column := Column + 1;
                     end if;
                  end;
               end loop;

               if not Failed then
                  if Cursor = Start then
                     Fail
                       (Unexpected_Control_Character,
                        Cursor,
                        Line,
                        Column);
                  else
                     Emit (Word, Start, Cursor - Start, Start_Line, Start_Column);
                  end if;
               end if;
            end if;
         end;
      end loop;

      if not Failed and then Bracket_Depth > 0 then
         Fail
           (Unclosed_Left_Bracket,
            Opening.Offset,
            Opening.Line,
            Opening.Column);
      end if;

      Validate_Commas;
      if Failed then
         Token_Count := 0;
      end if;
   end Tokenize;
end Lexer;
