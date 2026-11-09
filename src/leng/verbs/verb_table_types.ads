package Verb_Table_Types
  with SPARK_Mode => On
is
   Max_Name_Length : constant := 64;
   Max_Verbs        : constant := 128;
   Max_Forms        : constant := 8;
   Max_Operands     : constant := 8;
   Max_Flags        : constant := 8;
   Max_Keywords     : constant := 8;

   subtype Name_Length is Natural range 0 .. Max_Name_Length;
   type Identifier is record
      Length : Name_Length := 0;
      Data   : String (1 .. Max_Name_Length) := [others => ' '];
   end record;

   type Operand_Kind is (Name, Value, List, Bracket_Expression);
   type Operand_Spec is record
      Kind : Operand_Kind := Name;
   end record;
   type Operand_Array is array (Positive range 1 .. Max_Operands) of Operand_Spec;

   type Identifier_Array is
     array (Positive range 1 .. Max_Flags) of Identifier;
   type Keyword_Array is
     array (Positive range 1 .. Max_Keywords) of Identifier;

   type Keyword_Spec is record
      Name           : Identifier;
      After_Operand  : Natural range 0 .. Max_Operands := 0;
   end record;
   type Keyword_Spec_Array is
     array (Positive range 1 .. Max_Keywords) of Keyword_Spec;

   type Form_Entry is record
      Operand_Count : Natural range 0 .. Max_Operands := 0;
      Operands      : Operand_Array := [others => <>];
      Flag_Count    : Natural range 0 .. Max_Flags := 0;
      Flags         : Identifier_Array := [others => <>];
      Keyword_Count : Natural range 0 .. Max_Keywords := 0;
      Keywords      : Keyword_Spec_Array := [others => <>];
   end record;
   type Form_Array is array (Positive range 1 .. Max_Forms) of Form_Entry;

   type Verb_Entry is record
      Name       : Identifier;
      Form_Count : Natural range 0 .. Max_Forms := 0;
      Forms      : Form_Array := [others => <>];
   end record;
   type Verb_Array is array (Positive range 1 .. Max_Verbs) of Verb_Entry;

   type Verb_Table is record
      Count   : Natural range 0 .. Max_Verbs := 0;
      Entries : Verb_Array := [others => <>];
   end record;

   function To_String (Value : Identifier) return String;
end Verb_Table_Types;
