with Interfaces;

generic
   Capacity    : Positive;
   Max_Regions : Positive;
package Virtual_Memory
  with SPARK_Mode => On
is
   subtype Address is Interfaces.Unsigned_64;
   subtype Byte is Interfaces.Unsigned_8;

   type Permissions is record
      Read    : Boolean := False;
      Write   : Boolean := False;
      Execute : Boolean := False;
   end record;

   type Memory_Result is
     (Success, Invalid_Range, Region_Overlap, Unmapped_Address,
      Permission_Denied, Write_Execute_Violation);

   type Memory is private;

   function Region_Count (State : Memory) return Natural
     with Global => null;

   procedure Initialize (State : out Memory)
     with Global => null;

   procedure Map_Region
     (State       : in out Memory;
      Start       : Address;
      Length      : Address;
      Access      : Permissions;
      Result      : out Memory_Result)
     with Global => null, Pre => Length > 0;

   procedure Read_Byte
     (State : Memory; At : Address; Value : out Byte;
      Result : out Memory_Result)
     with Global => null;

   procedure Write_Byte
     (State : in out Memory; At : Address; Value : Byte;
      Result : out Memory_Result)
     with Global => null;

   procedure Fetch_Byte
     (State : Memory; At : Address; Value : out Byte;
      Result : out Memory_Result)
     with Global => null;

private
   subtype Region_Index is Positive range 1 .. Max_Regions;

   type Region is record
      Start  : Address := 0;
      Length : Address := 0;
      Access : Permissions := (Read => False, Write => False, Execute => False);
   end record;

   type Region_Array is array (Region_Index) of Region;
   type Storage_Array is array (Natural range 0 .. Capacity - 1) of Byte;

   type Memory is record
      Storage : Storage_Array := (others => 0);
      Regions : Region_Array := (others =>
        (Start => 0, Length => 0,
         Access => (Read => False, Write => False, Execute => False)));
      Count : Natural range 0 .. Max_Regions := 0;
   end record;
end Virtual_Memory;
