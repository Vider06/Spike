package body Virtual_Memory
  with SPARK_Mode => On
is
   function Region_Count (State : Memory) return Natural is
   begin
      return State.Count;
   end Region_Count;

   procedure Initialize (State : out Memory) is
   begin
      State :=
        (Storage => (others => 0),
         Regions => (others =>
           (Start => 0, Length => 0,
            Access => (Read => False, Write => False, Execute => False))),
         Count => 0);
   end Initialize;

   function Contains (Item : Region; At : Address) return Boolean is
   begin
      return Item.Length > 0
        and then At >= Item.Start
        and then At - Item.Start < Item.Length;
   end Contains;

   function Find_Region (State : Memory; At : Address) return Natural is
   begin
      for Index in 1 .. State.Count loop
         if Contains (State.Regions (Index), At) then
            return Index;
         end if;
      end loop;
      return 0;
   end Find_Region;

   procedure Map_Region
     (State : in out Memory;
      Start : Address;
      Length : Address;
      Access : Permissions;
      Result : out Memory_Result)
   is
      Finish : Address;
   begin
      if Length = 0
        or else Start >= Address (Capacity)
        or else Length > Address (Capacity) - Start
      then
         Result := Invalid_Range;
         return;
      end if;

      if Access.Write and Access.Execute then
         Result := Write_Execute_Violation;
         return;
      end if;

      if State.Count = Max_Regions then
         Result := Invalid_Range;
         return;
      end if;

      Finish := Start + Length;
      for Index in 1 .. State.Count loop
         declare
            Existing_Start : constant Address := State.Regions (Index).Start;
            Existing_End : constant Address :=
              Existing_Start + State.Regions (Index).Length;
         begin
            if Start < Existing_End and Existing_Start < Finish then
               Result := Region_Overlap;
               return;
            end if;
         end;
      end loop;

      State.Count := State.Count + 1;
      State.Regions (State.Count) :=
        (Start => Start, Length => Length, Access => Access);
      Result := Success;
   end Map_Region;

   procedure Read_Byte
     (State : Memory; At : Address; Value : out Byte;
      Result : out Memory_Result)
   is
      Index : constant Natural := Find_Region (State, At);
   begin
      Value := 0;
      if At >= Address (Capacity) then
         Result := Invalid_Range;
      elsif Index = 0 then
         Result := Unmapped_Address;
      elsif not State.Regions (Index).Access.Read then
         Result := Permission_Denied;
      else
         Value := State.Storage (Natural (At));
         Result := Success;
      end if;
   end Read_Byte;

   procedure Write_Byte
     (State : in out Memory; At : Address; Value : Byte;
      Result : out Memory_Result)
   is
      Index : constant Natural := Find_Region (State, At);
   begin
      if At >= Address (Capacity) then
         Result := Invalid_Range;
      elsif Index = 0 then
         Result := Unmapped_Address;
      elsif not State.Regions (Index).Access.Write then
         Result := Permission_Denied;
      else
         State.Storage (Natural (At)) := Value;
         Result := Success;
      end if;
   end Write_Byte;

   procedure Fetch_Byte
     (State : Memory; At : Address; Value : out Byte;
      Result : out Memory_Result)
   is
      Index : constant Natural := Find_Region (State, At);
   begin
      Value := 0;
      if At >= Address (Capacity) then
         Result := Invalid_Range;
      elsif Index = 0 then
         Result := Unmapped_Address;
      elsif not State.Regions (Index).Access.Execute then
         Result := Permission_Denied;
      else
         Value := State.Storage (Natural (At));
         Result := Success;
      end if;
   end Fetch_Byte;
end Virtual_Memory;
