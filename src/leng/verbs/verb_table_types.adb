package body Verb_Table_Types
  with SPARK_Mode => On
is
   function To_String (Value : Identifier) return String is
   begin
      if Value.Length = 0 then
         return "";
      end if;
      return Value.Data (1 .. Value.Length);
   end To_String;
end Verb_Table_Types;
