with Virtual_Memory;

procedure Test_Virtual_Memory is
   package Test_Memory is new Virtual_Memory
     (Capacity => 256, Max_Regions => 2);
   use Test_Memory;
   use type Byte;
   use type Word;

   State : Memory;
   Result : Memory_Result;
   Value : Byte;
   Value_Word : Word;
begin
   Initialize (State);

   Map_Region (State, 0, 64,
     (Read => True, Write => False, Execute => True), Result);
   pragma Assert (Result = Success);
   pragma Assert (Region_Count (State) = 1);

   Map_Region (State, 64, 64,
     (Read => True, Write => True, Execute => False), Result);
   pragma Assert (Result = Success);
   pragma Assert (Region_Count (State) = 2);

   Map_Region (State, 32, 16,
     (Read => True, Write => True, Execute => False), Result);
   pragma Assert (Result = Region_Overlap);
   pragma Assert (Region_Count (State) = 2);

   Map_Region (State, 128, 16,
     (Read => True, Write => True, Execute => True), Result);
   pragma Assert (Result = Write_Execute_Violation);

   Map_Region (State, 128, 0,
     (Read => True, Write => False, Execute => False), Result);
   pragma Assert (Result = Invalid_Range);

   Map_Region (State, 128, 16,
     (Read => True, Write => False, Execute => False), Result);
   pragma Assert (Result = Region_Table_Full);
   pragma Assert (Region_Count (State) = 2);

   Write_Byte (State, 4, 16#AA#, Result);
   pragma Assert (Result = Permission_Denied);
   Fetch_Byte (State, 4, Value, Result);
   pragma Assert (Result = Success);
   pragma Assert (Value = 0);

   Write_Byte (State, 70, 16#5A#, Result);
   pragma Assert (Result = Success);
   Read_Byte (State, 70, Value, Result);
   pragma Assert (Result = Success);
   pragma Assert (Value = 16#5A#);

   Fetch_Byte (State, 70, Value, Result);
   pragma Assert (Result = Permission_Denied);
   Read_Byte (State, 200, Value, Result);
   pragma Assert (Result = Unmapped_Address);

   Write_Byte (State, 256, 1, Result);
   pragma Assert (Result = Invalid_Range);
   Map_Region (State, 240, 32,
     (Read => True, Write => False, Execute => False), Result);
   pragma Assert (Result = Invalid_Range);

   --  A complete word is read/written in little-endian order.
   Write_Word (State, 70, 16#0123_4567_89AB_CDEF#, Result);
   pragma Assert (Result = Success);
   Read_Word (State, 70, Value_Word, Result);
   pragma Assert (Result = Success);
   pragma Assert (Value_Word = 16#0123_4567_89AB_CDEF#);

   --  A word crossing a region boundary is rejected without partial writes.
   Write_Word (State, 121, 16#FFFF_FFFF_FFFF_FFFF#, Result);
   pragma Assert (Result = Unmapped_Address);
   Read_Word (State, 70, Value_Word, Result);
   pragma Assert (Result = Success);
   pragma Assert (Value_Word = 16#0123_4567_89AB_CDEF#);

   Read_Word (State, 250, Value_Word, Result);
   pragma Assert (Result = Invalid_Range);
end Test_Virtual_Memory;
