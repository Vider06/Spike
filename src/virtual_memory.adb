package body Virtual_Memory
  with SPARK_Mode => On
is
   use type Address;

   function Region_Count (State : Memory) return Natural is
   begin
      return State.Count;
   end Region_Count;

   procedure Initialize (State : out Memory) is
   begin
      State :=
        (Storage => [others => 0],
         Regions => [others =>
           (Start => 0, Length => 0,
            Rights => (Read => False, Write => False, Execute => False))],
         Count => 0);
   end Initialize;

   function Contains
     (Item : Region; Address_Value : Address) return Boolean
   is
   begin
      return Item.Length > 0
        and then Address_Value >= Item.Start
        and then Address_Value - Item.Start < Item.Length;
   end Contains;

   function Find_Region
     (State : Memory; Address_Value : Address) return Natural
   is
   begin
      for Index in 1 .. State.Count loop
         if Contains (State.Regions (Index), Address_Value) then
            return Index;
         end if;
      end loop;
      return 0;
   end Find_Region;

   procedure Map_Region
     (State : in out Memory; Start : Address; Length : Address;
      Rights : Permissions; Result : out Memory_Result)
   is
   begin
      if Length = 0
        or else Start >= Address (Capacity)
        or else Length > Address (Capacity) - Start
      then
         Result := Invalid_Range;
         return;
      end if;

      if Rights.Write and Rights.Execute then
         Result := Write_Execute_Violation;
         return;
      end if;

      if State.Count = Max_Regions then
         Result := Region_Table_Full;
         return;
      end if;

      for Index in 1 .. State.Count loop
         declare
            Existing : constant Region := State.Regions (Index);
            Overlaps : constant Boolean :=
              (if Start >= Existing.Start
               then Start - Existing.Start < Existing.Length
               else Existing.Start - Start < Length);
         begin
            if Overlaps then
               Result := Region_Overlap;
               return;
            end if;
         end;
      end loop;

      State.Count := State.Count + 1;
      State.Regions (State.Count) :=
        (Start => Start, Length => Length, Rights => Rights);
      Result := Success;
   end Map_Region;

   procedure Read_Byte
     (State : Memory; Address_Value : Address; Value : out Byte;
      Result : out Memory_Result)
   is
      Index : constant Natural := Find_Region (State, Address_Value);
   begin
      Value := 0;
      if Address_Value >= Address (Capacity) then
         Result := Invalid_Range;
      elsif Index = 0 then
         Result := Unmapped_Address;
      elsif not State.Regions (Index).Rights.Read then
         Result := Permission_Denied;
      else
         Value := State.Storage (Natural (Address_Value));
         Result := Success;
      end if;
   end Read_Byte;

   procedure Write_Byte
     (State : in out Memory; Address_Value : Address; Value : Byte;
      Result : out Memory_Result)
   is
      Index : constant Natural := Find_Region (State, Address_Value);
   begin
      if Address_Value >= Address (Capacity) then
         Result := Invalid_Range;
      elsif Index = 0 then
         Result := Unmapped_Address;
      elsif not State.Regions (Index).Rights.Write then
         Result := Permission_Denied;
      else
         State.Storage (Natural (Address_Value)) := Value;
         Result := Success;
      end if;
   end Write_Byte;

   procedure Fetch_Byte
     (State : Memory; Address_Value : Address; Value : out Byte;
      Result : out Memory_Result)
   is
      Index : constant Natural := Find_Region (State, Address_Value);
   begin
      Value := 0;
      if Address_Value >= Address (Capacity) then
         Result := Invalid_Range;
      elsif Index = 0 then
         Result := Unmapped_Address;
      elsif not State.Regions (Index).Rights.Execute then
         Result := Permission_Denied;
      else
         Value := State.Storage (Natural (Address_Value));
         Result := Success;
      end if;
   end Fetch_Byte;
end Virtual_Memory;
