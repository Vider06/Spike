with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with GNATCOLL.JSON;
with Verb_Table_Types;

package body Verb_Table_Config is
   use GNATCOLL.JSON;
   use Verb_Table_Types;

   function Is_Letter (C : Character) return Boolean is
     (C in 'A' .. 'Z' or else C in 'a' .. 'z');

   function Valid_Identifier (Value : String; Allow_Dot : Boolean) return Boolean is
   begin
      if Value'Length = 0 or else Value'Length > Max_Name_Length then
         return False;
      end if;
      if not Is_Letter (Value (Value'First)) and then Value (Value'First) /= '_' then
         return False;
      end if;
      for C of Value loop
         if not Is_Letter (C) and then C not in '0' .. '9'
           and then C /= '_' and then not (Allow_Dot and then C = '.')
         then
            return False;
         end if;
      end loop;
      return Value (Value'Last) /= '.';
   end Valid_Identifier;

   function Make_Identifier
     (Value : String; Context : String; Allow_Dot : Boolean := True)
      return Identifier
   is
      Result : Identifier;
   begin
      if not Valid_Identifier (Value, Allow_Dot) then
         raise Config_Error with Context & ": expected an ASCII identifier";
      end if;
      Result.Length := Value'Length;
      Result.Data (1 .. Value'Length) := Value;
      return Result;
   end Make_Identifier;

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

   function Required_String
     (Object : JSON_Value; Field, Context : String) return String
   is
   begin
      if not Object.Has_Field (Field)
        or else Object.Get (Field).Kind /= JSON_String_Type
      then
         raise Config_Error with Context & ": " & Field & " must be a string";
      end if;
      return GNATCOLL.JSON.Get (Object.Get (Field));
   end Required_String;

   function Parse_Operand_Kind
     (Value, Context : String) return Operand_Kind
   is
   begin
      if Value = "name" then
         return Name;
      elsif Value = "value" then
         return Verb_Table_Types.Value;
      elsif Value = "list" then
         return List;
      elsif Value = "bracket_expression" then
         return Bracket_Expression;
      else
         raise Config_Error with Context & ": unknown type '" & Value & "'";
      end if;
   end Parse_Operand_Kind;

   function Validate (Document : String) return Verb_Table is
      Parsed : constant Read_Result := Read (Document);
      Root   : JSON_Value;
      Items  : JSON_Array;
      Result : Verb_Table := (others => <>);
   begin
      if not Parsed.Success then
         raise Config_Error with "invalid JSON: " & Format_Parsing_Error (Parsed.Error);
      end if;
      Root := Parsed.Value;
      if not Allowed_Fields (Root, "schema_version|verbs") then
         raise Config_Error with "root: unknown field or expected JSON object";
      end if;
      if Required_String (Root, "schema_version", "root") /= "1.0" then
         raise Config_Error with "root: schema_version must be exactly 1.0";
      end if;
      if not Root.Has_Field ("verbs")
        or else Root.Get ("verbs").Kind /= JSON_Array_Type
      then
         raise Config_Error with "root: verbs must be an array";
      end if;
      Items := Root.Get ("verbs");
      if Length (Items) = 0 then
         raise Config_Error with "root: verbs must be a non-empty array";
      elsif Length (Items) > Max_Verbs then
         raise Config_Error with "root: verb limit (128) exceeded";
      end if;

      for V in 1 .. Length (Items) loop
         declare
            Item : constant JSON_Value := Get (Items, V);
            Verb : Verb_Entry;
            Verb_Name : Unbounded_String;
            Forms : JSON_Array;
         begin
            if Item.Kind /= JSON_Object_Type then
               raise Config_Error with "verb" & V'Image & ": expected an object";
            end if;
            Verb_Name := To_Unbounded_String
              (Required_String (Item, "name", "verb" & V'Image));
            if not Allowed_Fields (Item, "name|forms") then
               raise Config_Error with "verb " & To_String (Verb_Name)
                 & ": unknown field";
            end if;
            Verb.Name := Make_Identifier (To_String (Verb_Name), "verb name");
            for Existing in 1 .. Result.Count loop
               if Result.Entries (Existing).Name = Verb.Name then
                  raise Config_Error with "duplicate verb name: " & To_String (Verb_Name);
               end if;
            end loop;
            if not Item.Has_Field ("forms")
              or else Item.Get ("forms").Kind /= JSON_Array_Type
            then
               raise Config_Error with "verb " & To_String (Verb_Name) & ": forms must be an array";
            end if;
            Forms := Item.Get ("forms");
            if Length (Forms) = 0 then
               raise Config_Error with "verb " & To_String (Verb_Name)
                 & ": at least one form is required";
            elsif Length (Forms) > Max_Forms then
               raise Config_Error with "verb " & To_String (Verb_Name)
                 & ": form limit (8) exceeded";
            end if;

            for F in 1 .. Length (Forms) loop
               declare
                  Form_JSON : constant JSON_Value := Get (Forms, F);
                  Form : Form_Entry;
                  Operands : JSON_Array;
                  Flags : JSON_Array;
                  Keywords : JSON_Array;
               begin
                  if not Allowed_Fields (Form_JSON, "operands|flags|keywords") then
                     raise Config_Error with "verb " & To_String (Verb_Name)
                       & ", form" & F'Image & ": unknown field or expected object";
                  end if;
                  if not Form_JSON.Has_Field ("operands")
                    or else Form_JSON.Get ("operands").Kind /= JSON_Array_Type
                  then
                     raise Config_Error with "verb " & To_String (Verb_Name)
                       & ", form" & F'Image & ": operands must be an array";
                  end if;
                  Operands := Form_JSON.Get ("operands");
                  if Length (Operands) > Max_Operands then
                     raise Config_Error with "verb " & To_String (Verb_Name)
                       & ", form" & F'Image & ": operand limit (8) exceeded";
                  end if;
                  Form.Operand_Count := Length (Operands);

                  for O in 1 .. Length (Operands) loop
                     declare
                        Operand_JSON : constant JSON_Value := Get (Operands, O);
                        Context : constant String :=
                          "verb " & To_String (Verb_Name) & ", operand" & O'Image;
                     begin
                        if not Allowed_Fields (Operand_JSON, "type") then
                           raise Config_Error with Context
                             & ": unknown field or expected object";
                        end if;
                        Form.Operands (O).Kind :=
                          Parse_Operand_Kind
                            (Required_String (Operand_JSON, "type", Context), Context);
                     end;
                  end loop;

                  if Form_JSON.Has_Field ("flags") then
                     if Form_JSON.Get ("flags").Kind /= JSON_Array_Type then
                        raise Config_Error with "verb " & To_String (Verb_Name)
                          & ", form" & F'Image & ": flags must be an array";
                     end if;
                     Flags := Form_JSON.Get ("flags");
                     if Length (Flags) > Max_Flags then
                        raise Config_Error with "verb " & To_String (Verb_Name)
                          & ", form" & F'Image & ": flag limit (8) exceeded";
                     end if;
                     Form.Flag_Count := Length (Flags);
                     for A in 1 .. Length (Flags) loop
                        declare
                           Flag_JSON : constant JSON_Value := Get (Flags, A);
                           Flag_Name : Unbounded_String;
                        begin
                           if Flag_JSON.Kind /= JSON_String_Type then
                              raise Config_Error with "verb " & To_String (Verb_Name)
                                & ", flag" & A'Image & ": expected a string";
                           end if;
                           Flag_Name := To_Unbounded_String (GNATCOLL.JSON.Get (Flag_JSON));
                           Form.Flags (A) := Make_Identifier
                             (To_String (Flag_Name),
                              "verb " & To_String (Verb_Name) & ", flag" & A'Image,
                              Allow_Dot => False);
                           for Previous in 1 .. A - 1 loop
                              if Form.Flags (Previous) = Form.Flags (A) then
                                 raise Config_Error with "verb " & To_String (Verb_Name)
                                   & ": duplicate flag " & To_String (Flag_Name);
                              end if;
                           end loop;
                        end;
                     end loop;
                  end if;

                  if Form_JSON.Has_Field ("keywords") then
                     if Form_JSON.Get ("keywords").Kind /= JSON_Array_Type then
                        raise Config_Error with "verb " & To_String (Verb_Name)
                          & ", form" & F'Image & ": keywords must be an array";
                     end if;
                     Keywords := Form_JSON.Get ("keywords");
                     if Length (Keywords) > Max_Keywords then
                        raise Config_Error with "verb " & To_String (Verb_Name)
                          & ", form" & F'Image & ": keyword limit (8) exceeded";
                     end if;
                     Form.Keyword_Count := Length (Keywords);
                     for K in 1 .. Length (Keywords) loop
                        declare
                           Keyword_JSON : constant JSON_Value := Get (Keywords, K);
                           Keyword_Name : Unbounded_String;
                           After_Value : Long_Long_Integer;
                        begin
                           if not Allowed_Fields (Keyword_JSON, "name|after_operand") then
                              raise Config_Error with "verb " & To_String (Verb_Name)
                                & ", keyword" & K'Image & ": unknown field or expected object";
                           end if;
                           Keyword_Name := To_Unbounded_String
                             (Required_String
                                (Keyword_JSON, "name",
                                 "verb " & To_String (Verb_Name) & ", keyword" & K'Image));
                           Form.Keywords (K).Name := Make_Identifier
                             (To_String (Keyword_Name),
                              "verb " & To_String (Verb_Name) & ", keyword" & K'Image,
                              Allow_Dot => False);
                           if not Keyword_JSON.Has_Field ("after_operand")
                             or else Keyword_JSON.Get ("after_operand").Kind /= JSON_Int_Type
                           then
                              raise Config_Error with "verb " & To_String (Verb_Name)
                                & ", keyword" & K'Image & ": after_operand must be an integer";
                           end if;
                           After_Value := Keyword_JSON.Get ("after_operand").Get;
                           if After_Value < 0
                             or else After_Value > Long_Long_Integer (Form.Operand_Count)
                           then
                              raise Config_Error with "verb " & To_String (Verb_Name)
                                & ", keyword" & K'Image
                                & ": after_operand is outside the operand range";
                           end if;
                           Form.Keywords (K).After_Operand := Natural (After_Value);
                           for Previous in 1 .. K - 1 loop
                              if Form.Keywords (Previous).Name = Form.Keywords (K).Name then
                                 raise Config_Error with "verb " & To_String (Verb_Name)
                                   & ": duplicate keyword " & To_String (Keyword_Name);
                              end if;
                           end loop;
                        end;
                     end loop;
                  end if;
                  Verb.Forms (F) := Form;
               end;
            end loop;
            Result.Count := Result.Count + 1;
            Result.Entries (Result.Count) := Verb;
         end;
      end loop;
      return Result;
   end Validate;

   function Load (Path : String) return Verb_Table is
      Parsed : constant Read_Result := Read_File (Path);
   begin
      if not Parsed.Success then
         raise Config_Error with "cannot load " & Path & ": "
           & Format_Parsing_Error (Parsed.Error);
      end if;
      return Validate (Write (Parsed.Value));
   end Load;
end Verb_Table_Config;
