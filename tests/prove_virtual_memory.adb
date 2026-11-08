with Virtual_Memory;

procedure Prove_Virtual_Memory
  with SPARK_Mode => On
is
   package Proof_Memory is new Virtual_Memory
     (Capacity => 256, Max_Regions => 4);
   use Proof_Memory;
   use type Byte;

   State : Memory;
   Result : Memory_Result;
   Value : Byte := 0;
begin
   Initialize (State);

   Map_Region (State, 0, 64,
     (Read => True, Write => True, Execute => False), Result);
   if Result = Success then
      Write_Byte (State, 0, 16#A5#, Result);
      if Result = Success then
         Read_Byte (State, 0, Value, Result);
      end if;
   end if;

   Map_Region (State, 64, 64,
     (Read => True, Write => False, Execute => True), Result);
   if Result = Success then
      Fetch_Byte (State, 64, Value, Result);
   end if;

   if Value = 16#A5# then
      null;
   end if;
end Prove_Virtual_Memory;
