with Ada.Assertions; use Ada.Assertions;
with Ada.Exceptions;
with Ada.Strings.Fixed;
with Ada.Text_IO; use Ada.Text_IO;
with Verb_Table_Config;
with Verb_Table_Types;

procedure Test_Verb_Table is
   use Verb_Table_Types;
   Table : constant Verb_Table := Verb_Table_Config.Load ("src/leng/verbs/verbs.json");

   procedure Expect_Error (Document, Expected : String) is
      Failed : Boolean := False;
   begin
      begin
         declare
            Ignored : constant Verb_Table := Verb_Table_Config.Validate (Document);
         begin
            pragma Unreferenced (Ignored);
         end;
      exception
         when Error : Verb_Table_Config.Config_Error =>
            Failed := True;
            Assert
              (Ada.Strings.Fixed.Index
                 (Ada.Exceptions.Exception_Message (Error), Expected) > 0,
               "diagnostic should contain: " & Expected
               & "; got: " & Ada.Exceptions.Exception_Message (Error));
      end;
      Assert (Failed, "invalid verb table must be rejected");
   end Expect_Error;

begin
   Assert (Table.Count = 6, "starter verb table loads six verbs");
   Assert (To_String (Table.Entries (1).Name) = "mov", "first verb name");
   Assert (Table.Entries (1).Forms (1).Operand_Count = 2, "mov has two operands");
   Assert (Table.Entries (2).Forms (1).Operand_Count = 3, "add has three operands");
   Assert (Table.Entries (3).Forms (1).Operand_Count = 0, "halt accepts no operands");
   Assert (To_String (Table.Entries (4).Name) = "out.term", "dotted verb names are supported");
   Assert (Table.Entries (5).Forms (1).Keyword_Count = 1, "get declares a keyword");
   Assert (To_String (Table.Entries (5).Forms (1).Keywords (1).Name) = "from",
           "get keyword name");
   Assert (Table.Entries (5).Forms (1).Keywords (1).After_Operand = 2,
           "from follows the second operand");
   Assert (Table.Entries (6).Forms (1).Operand_Count = 1,
           "give requires its continuation operand");
   Assert (Table.Entries (6).Forms (1).Operands (1).Kind = Bracket_Expression,
           "give continuation is a bracket expression");

   declare
      With_Flag_And_List : constant Verb_Table := Verb_Table_Config.Validate
        ("{""schema_version"":""1.0"",""verbs"":[{""name"":""probe"",""forms"":["
         & "{""operands"":[{""type"":""list""}],""flags"":[""trace""]},"
         & "{""operands"":[{""type"":""name""}]}]}]}");
   begin
      Assert (With_Flag_And_List.Entries (1).Form_Count = 2,
              "multiple operand forms are retained");
      Assert (With_Flag_And_List.Entries (1).Forms (1).Flag_Count = 1,
              "allowed flags are retained");
      Assert (With_Flag_And_List.Entries (1).Forms (1).Operands (1).Kind = List,
              "list operands are retained");
   end;

   declare
      With_Into : constant Verb_Table := Verb_Table_Config.Validate
        ("{""schema_version"":""1.0"",""verbs"":[{""name"":""transfer"",""forms"":["
         & "{""operands"":[{""type"":""name""},{""type"":""bracket_expression""}],"
         & """keywords"":[{""name"":""into"",""after_operand"":1}]}]}]}");
   begin
      Assert (To_String (With_Into.Entries (1).Forms (1).Keywords (1).Name) = "into",
              "into keyword is supported");
      Assert (With_Into.Entries (1).Forms (1).Keywords (1).After_Operand = 1,
              "keyword position is retained");
   end;

   Expect_Error
     ("{""schema_version"":""1.0"",""verbs"":[{""name"":""cop"",""forms"":[{""operands"":[{""type"":""name""},{""type"":""register""}]}]}]}",
      "verb cop, operand 2: unknown type 'register'");
   Expect_Error
     ("{""schema_version"":""1.0"",""verbs"":[{""name"":""cop"",""forms"":[{""operands"":[]}]},{""name"":""cop"",""forms"":[{""operands"":[]}]}]}",
      "duplicate verb name: cop");
   Expect_Error
     ("{""schema_version"":""1.0"",""verbs"":[{""name"":""get"",""forms"":[{""operands"":[{""type"":""name""}],""keywords"":[{""name"":""from"",""after_operand"":2}]}]}]}",
      "after_operand is outside the operand range");
   Expect_Error
     ("{""schema_version"":""1.0"",""verbs"":[{""name"":""halt"",""forms"":[{""operands"":[],""unexpected"":true}]}]}",
      "verb halt, form 1: unknown field");
   Expect_Error
     ("{""schema_version"":""2.0"",""verbs"":[{""name"":""halt"",""forms"":[{""operands"":[]}]}]}",
      "schema_version must be exactly 1.0");
   Expect_Error ("{broken", "invalid JSON");

   Put_Line ("Spike verb table phase 2 tests passed");
end Test_Verb_Table;
