with Machine_State;
with Virtual_Memory;
with VM_Stack;

procedure Test_VM_Stack is
   package Test_Memory is new Virtual_Memory
     (Capacity => 256, Max_Regions => 2);
   package Test_Stack is new VM_Stack (Test_Memory);
   use Test_Memory;
   use Test_Stack;
   use Machine_State;
   use type Machine_State.Word;

   Memory : Test_Memory.Memory;
   CPU : Machine_State.Machine_State;
   Stack_State : Test_Stack.Stack;
   Result : Test_Stack.Stack_Result;
   Memory_Error : Test_Memory.Memory_Result;
   Value : Machine_State.Word;
begin
   Initialize (Memory);
   Map_Region
     (Memory, 0, 64,
      (Read => True, Write => False, Execute => True), Memory_Error);
   pragma Assert (Memory_Error = Test_Memory.Success);
   Map_Region
     (Memory, 64, 64,
      (Read => True, Write => True, Execute => False), Memory_Error);
   pragma Assert (Memory_Error = Success);

   Reset (CPU);
   Configure (Stack_State, CPU, 64, 128, Result);
   pragma Assert (Result = Test_Stack.Success);
   pragma Assert (Is_Configured (Stack_State));
   pragma Assert (Stack_Pointer (CPU) = 128);

   Push (Stack_State, CPU, Memory, 16#1122_3344_5566_7788#, Result, Memory_Error);
   pragma Assert (Result = Test_Stack.Success);
   pragma Assert (Stack_Pointer (CPU) = 120);
   Push (Stack_State, CPU, Memory, 16#AABB_CCDD_EEFF_0011#, Result, Memory_Error);
   pragma Assert (Result = Test_Stack.Success);
   pragma Assert (Stack_Pointer (CPU) = 112);

   Pop (Stack_State, CPU, Memory, Value, Result, Memory_Error);
   pragma Assert (Result = Test_Stack.Success);
   pragma Assert (Value = 16#AABB_CCDD_EEFF_0011#);
   pragma Assert (Stack_Pointer (CPU) = 120);
   Pop (Stack_State, CPU, Memory, Value, Result, Memory_Error);
   pragma Assert (Result = Test_Stack.Success);
   pragma Assert (Value = 16#1122_3344_5566_7788#);
   pragma Assert (Stack_Pointer (CPU) = 128);

   Pop (Stack_State, CPU, Memory, Value, Result, Memory_Error);
   pragma Assert (Result = Stack_Underflow);
   pragma Assert (Stack_Pointer (CPU) = 128);

   for Index in 1 .. 8 loop
      Push (Stack_State, CPU, Memory, Machine_State.Word (Index), Result, Memory_Error);
      pragma Assert (Result = Test_Stack.Success);
   end loop;
   pragma Assert (Stack_Pointer (CPU) = 64);
   Push (Stack_State, CPU, Memory, 99, Result, Memory_Error);
   pragma Assert (Result = Stack_Overflow);
   pragma Assert (Stack_Pointer (CPU) = 64);

   Configure (Stack_State, CPU, 64, 130, Result);
   pragma Assert (Result = Invalid_Bounds);
   pragma Assert (Stack_Pointer (CPU) = 64);

   --  Calls save the next instruction index and returns restore it.
   Configure (Stack_State, CPU, 64, 128, Result);
   pragma Assert (Result = Test_Stack.Success);
   Set_Program_Counter (CPU, 10);
   Call (Stack_State, CPU, Memory, 50, Result, Memory_Error);
   pragma Assert (Result = Test_Stack.Success);
   pragma Assert (Program_Counter (CPU) = 50);
   pragma Assert (Stack_Pointer (CPU) = 120);
   Return_From_Call (Stack_State, CPU, Memory, Result, Memory_Error);
   pragma Assert (Result = Test_Stack.Success);
   pragma Assert (Program_Counter (CPU) = 11);
   pragma Assert (Stack_Pointer (CPU) = 128);

   Set_Program_Counter (CPU, Machine_State.Word'Last);
   Call (Stack_State, CPU, Memory, 99, Result, Memory_Error);
   pragma Assert (Result = Invalid_Return_Address);
   pragma Assert (Program_Counter (CPU) = Machine_State.Word'Last);
   pragma Assert (Stack_Pointer (CPU) = 128);

   --  A read/execute region cannot be used as a writable stack.
   Configure (Stack_State, CPU, 0, 64, Result);
   pragma Assert (Result = Test_Stack.Success);
   Push (Stack_State, CPU, Memory, 1, Result, Memory_Error);
   pragma Assert (Result = Memory_Access_Failed);
   pragma Assert (Memory_Error = Permission_Denied);
   pragma Assert (Stack_Pointer (CPU) = 64);
end Test_VM_Stack;
