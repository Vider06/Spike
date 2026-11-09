with Verb_Table_Types;

package Verb_Table_Config is
   Config_Error : exception;

   function Validate (Document : String) return Verb_Table_Types.Verb_Table;
   function Load (Path : String) return Verb_Table_Types.Verb_Table;
end Verb_Table_Config;
