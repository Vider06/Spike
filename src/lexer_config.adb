with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNATCOLL.JSON;

package body Lexer_Config is
   use GNATCOLL.JSON;

   function Is_ASCII_Letter (C : Character) return Boolean is
     (C in 'A' .. 'Z' or else C in 'a' .. 'z');

   function Valid_Name (S : String) return Boolean is
   begin
      if S'Length = 0 then
         return False;
      end if;
      if not Is_ASCII_Letter (S (S'First)) and then S (S'First) /= '_' then
         return False;
      end if;
      for C of S loop
         if not Is_ASCII_Letter (C) and then C not in '0' .. '9'
           and then C /= '_'
         then
            return False;
         end if;
      end loop;
      return True;
   end Valid_Name;

   function Allowed_Fields
     (Object : JSON_Value; Allowed : String) return Boolean
   is
      Good : Boolean := True;
      procedure Check_Field (Name : UTF8_String; Value : JSON_Value) is
         pragma Unreferenced (Value);
         Start : Integer := Allowed'First;
         Stop  : Integer;
         Found : Boolean := False;
      begin
         while Start <= Allowed'Last loop
            Stop := Start;
            while Stop <= Allowed'Last and then Allowed (Stop) /= '|' loop
               Stop := Stop + 1;
            end loop;
            if Stop > Allowed'Last then
               Stop := Allowed'Last;
            else
               Stop := Stop - 1;
            end if;
            if Name = Allowed (Start .. Stop) then
               Found := True;
               exit;
            end if;
            Start := Stop + 2;
         end loop;
         if not Found then
            Good := False;
         end if;
      end Check_Field;
   begin
      if Object.Kind /= JSON_Object_Type then
         return False;
      end if;
      Map_JSON_Object (Object, Check_Field'Access);
      return Good;
   end Allowed_Fields;

   function Parse_Matcher (Name : String) return Matcher_Kind is
   begin
      if Name = "literal" then return Literal;
      elsif Name = "identifier" then return Identifier;
      elsif Name = "decimal_integer" then return Decimal_Integer;
      elsif Name = "hex_integer" then return Hex_Integer;
      elsif Name = "binary_integer" then return Binary_Integer;
      elsif Name = "quoted_string" then return Quoted_String;
      elsif Name = "whitespace" then return Whitespace;
      elsif Name = "line_comment" then return Line_Comment;
      else raise Config_Error with "unsupported matcher: " & Name;
      end if;
   end Parse_Matcher;

   function Validate (Document : String) return Lexer_Configuration is
      Parsed : constant Read_Result := Read (Document);
      Root   : JSON_Value;
      Items  : JSON_Array;
      Result : Lexer_Configuration;
   begin
      if not Parsed.Success then
         raise Config_Error with Format_Parsing_Error (Parsed.Error);
      end if;
      Root := Parsed.Value;
      if not Allowed_Fields (Root, "schema_version|tokens") then
         raise Config_Error with "root must contain only schema_version and tokens";
      end if;
      if not Root.Has_Field ("schema_version")
        or else Root.Get ("schema_version").Kind /= JSON_String_Type
        or else GNATCOLL.JSON.Get (Root.Get ("schema_version")) /= "1.0"
      then
         raise Config_Error with "schema_version must be exactly 1.0";
      end if;
      if not Root.Has_Field ("tokens")
        or else Root.Get ("tokens").Kind /= JSON_Array_Type
      then
         raise Config_Error with "tokens must be a non-empty array";
      end if;
      Items := Root.Get ("tokens");
      if Length (Items) = 0 then
         raise Config_Error with "tokens must be a non-empty array";
      elsif Length (Items) > 4_096 then
         raise Config_Error with "token definition limit (4096) exceeded";
      end if;
      Result.Schema_Version := To_Unbounded_String ("1.0");

      for I in 1 .. Length (Items) loop
         declare
            Item : constant JSON_Value := Get (Items, I);
            Def  : Token_Definition;
            Name : Unbounded_String;
            Matcher_Name : Unbounded_String;
            Has_Value : Boolean;
         begin
            if not Allowed_Fields (Item, "name|matcher|value|priority|emit") then
               raise Config_Error with "tokens[" & I'Image & "] has unknown fields";
            end if;
            if not Item.Has_Field ("name")
              or else Item.Get ("name").Kind /= JSON_String_Type
            then
               raise Config_Error with "token name must be a string";
            end if;
            declare
               Name_Text : constant String := GNATCOLL.JSON.Get (Item.Get ("name"));
            begin
               Name := To_Unbounded_String (Name_Text);
            end;
            if not Valid_Name (To_String (Name)) then
               raise Config_Error with "token name must be an ASCII identifier";
            end if;
            for Existing of Result.Definitions loop
               if Existing.Name = Name then
                  raise Config_Error with "duplicate token name: " & To_String (Name);
               end if;
            end loop;

            if not Item.Has_Field ("matcher")
              or else Item.Get ("matcher").Kind /= JSON_String_Type
            then
               raise Config_Error with "token matcher must be a string";
            end if;
            declare
               Matcher_Text : constant String := GNATCOLL.JSON.Get (Item.Get ("matcher"));
            begin
               Matcher_Name := To_Unbounded_String (Matcher_Text);
            end;
            Def.Name := Name;
            Def.Matcher := Parse_Matcher (To_String (Matcher_Name));

            if Def.Matcher not in Literal | Line_Comment then
               for Existing of Result.Definitions loop
                  if Existing.Matcher = Def.Matcher
                    and then Existing.Priority = Def.Priority
                  then
                     raise Config_Error with
                       "ambiguous generic matcher priority: "
                       & To_String (Matcher_Name);
                  end if;
               end loop;
            end if;

            Has_Value := Item.Has_Field ("value");
            if Def.Matcher in Literal | Line_Comment then
               if not Has_Value or else Item.Get ("value").Kind /= JSON_String_Type then
                  raise Config_Error with "literal and line_comment require a string value";
               end if;
               declare
                  Token_Text : constant String :=
                    GNATCOLL.JSON.Get (Item.Get ("value"));
               begin
                  if Token_Text'Length = 0 then
                     raise Config_Error with
                       "literal and line_comment require non-empty value";
                  end if;
                  Def.Value := To_Unbounded_String (Token_Text);
               end;
            elsif Has_Value then
               raise Config_Error with "value is only valid for literal and line_comment";
            end if;

            if Item.Has_Field ("priority") then
               if Item.Get ("priority").Kind /= JSON_Int_Type then
                  raise Config_Error with "priority must be an integer";
               end if;
               declare
                  P : constant Long_Long_Integer := Item.Get ("priority").Get;
               begin
                  if P < Long_Long_Integer (Integer'First)
                    or else P > Long_Long_Integer (Integer'Last)
                  then
                     raise Config_Error with "priority is outside Ada Integer range";
                  end if;
                  Def.Priority := Integer (P);
               end;
            end if;
            if Item.Has_Field ("emit") then
               if Item.Get ("emit").Kind /= JSON_Boolean_Type then
                  raise Config_Error with "emit must be boolean";
               end if;
               Def.Emit := Item.Get ("emit").Get;
            end if;

            if Def.Matcher = Literal then
               for Existing of Result.Definitions loop
                  if Existing.Matcher = Literal and then Existing.Value = Def.Value
                    and then Existing.Priority = Def.Priority
                  then
                     raise Config_Error with "ambiguous literal has duplicate priority";
                  end if;
               end loop;
            end if;
            Result.Definitions.Append (Def);
         end;
      end loop;

      for Def of Result.Definitions loop
         if Def.Emit then
            return Result;
         end if;
      end loop;
      raise Config_Error with "at least one token definition must emit tokens";
   end Validate;

   function Load (Path : String) return Lexer_Configuration is
      Parsed : constant Read_Result := Read_File (Path);
   begin
      if not Parsed.Success then
         raise Config_Error with "cannot load " & Path & ": "
           & Format_Parsing_Error (Parsed.Error);
      end if;
      return Validate (Write (Parsed.Value));
   end Load;
end Lexer_Config;
