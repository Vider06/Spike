with Machine_State;
with Virtual_Memory;
with VM_Stack;

procedure Prove_VM_Stack
  with SPARK_Mode => On
is
   package Proof_Memory is new Virtual_Memory
     (Capacity => 256, Max_Regions => 2);
   package Proof_Stack is new VM_Stack (Proof_Memory);
   use Proof_Memory;
   use Proof_Stack;

   CPU : Machine_State.Machine_State;
   Memory_State : Proof_Memory.Memory;
   Stack_State : Proof_Stack.Stack;
   Stack_Status : Proof_Stack.Stack_Result;
   Memory_Status : Proof_Memory.Memory_Result;
   Loaded : Machine_State.Word := 0;
begin
   Proof_Memory.Initialize (Memory_State);
   Proof_Memory.Map_Region
     (Memory_State, 64, 64,
      (Read => True, Write => True, Execute => False), Memory_Status);

   if Memory_Status = Proof_Memory.Success then
      Machine_State.Reset (CPU);
      Proof_Stack.Configure (Stack_State, CPU, 64, 128, Stack_Status);

      if Stack_Status = Proof_Stack.Success then
         Proof_Stack.Push
           (Stack_State, CPU, Memory_State, 16#1122_3344_5566_7788#,
            Stack_Status, Memory_Status);

         if Stack_Status = Proof_Stack.Success then
            Proof_Stack.Pop
              (Stack_State, CPU, Memory_State, Loaded,
               Stack_Status, Memory_Status);

            if Stack_Status = Proof_Stack.Success then
               Machine_State.Set_Register (CPU, 0, Loaded);
            end if;
         end if;

         Machine_State.Set_Program_Counter (CPU, 11);
         Proof_Stack.Call
           (Stack_State, CPU, Memory_State, 50, Stack_Status, Memory_Status);

         if Stack_Status = Proof_Stack.Success then
            Proof_Stack.Return_From_Call
              (Stack_State, CPU, Memory_State, Stack_Status, Memory_Status);

            if Stack_Status = Proof_Stack.Success then
               Machine_State.Set_Register
                 (CPU, 1, Machine_State.Program_Counter (CPU));
            end if;
         end if;
      end if;
   end if;
end Prove_VM_Stack;
