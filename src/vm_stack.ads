with Machine_State;
with Virtual_Memory;

generic
   with package Memory_Model is new Virtual_Memory (<>);
package VM_Stack
  with SPARK_Mode => On
is
   use type Memory_Model.Address;
   use type Memory_Model.Memory_Result;
   use type Machine_State.Execution_Status;
   use type Machine_State.Status_Flags;

   type Stack_Result is
     (Success, Not_Configured, Invalid_Bounds, Stack_Overflow,
      Stack_Underflow, Memory_Access_Failed);

   type Stack is private;

   function Is_Configured (State : Stack) return Boolean
     with Global => null;

   function Lower_Bound (State : Stack) return Memory_Model.Address
     with Global => null;

   function Upper_Bound (State : Stack) return Memory_Model.Address
     with Global => null;

   procedure Configure
     (State : out Stack;
      CPU : in out Machine_State.Machine_State;
      Lower : Memory_Model.Address;
      Upper : Memory_Model.Address;
      Result : out Stack_Result)
     with Global => null,
          Pre => Machine_State.Current_Status (CPU) = Machine_State.Running,
          Post =>
            Machine_State.Current_Status (CPU) =
              Machine_State.Current_Status (CPU'Old)
            and then
              (if Result = Success
               then Is_Configured (State)
                 and then Lower_Bound (State) = Lower
                 and then Upper_Bound (State) = Upper
                 and then Machine_State.Stack_Pointer (CPU) =
                   Machine_State.Word (Upper)
               else not Is_Configured (State)
                 and then Machine_State.Stack_Pointer (CPU) =
                   Machine_State.Stack_Pointer (CPU'Old));

   procedure Push
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : in out Memory_Model.Memory;
      Value : Machine_State.Word;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
     with Global => null,
          Pre => Machine_State.Current_Status (CPU) = Machine_State.Running,
          Post =>
            Machine_State.Current_Status (CPU) =
              Machine_State.Current_Status (CPU'Old)
            and then Machine_State.Program_Counter (CPU) =
              Machine_State.Program_Counter (CPU'Old)
            and then Machine_State.Get_Flags (CPU) =
              Machine_State.Get_Flags (CPU'Old)
            and then
              (if Result = Success
               then Machine_State.Stack_Pointer (CPU) =
                 Machine_State.Stack_Pointer (CPU'Old) - 8
                 and then Memory_Error = Memory_Model.Success
               else Machine_State.Stack_Pointer (CPU) =
                 Machine_State.Stack_Pointer (CPU'Old));

   procedure Pop
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : Memory_Model.Memory;
      Value : out Machine_State.Word;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
     with Global => null,
          Pre => Machine_State.Current_Status (CPU) = Machine_State.Running,
          Post =>
            Machine_State.Current_Status (CPU) =
              Machine_State.Current_Status (CPU'Old)
            and then Machine_State.Program_Counter (CPU) =
              Machine_State.Program_Counter (CPU'Old)
            and then Machine_State.Get_Flags (CPU) =
              Machine_State.Get_Flags (CPU'Old)
            and then
              (if Result = Success
               then Machine_State.Stack_Pointer (CPU) =
                 Machine_State.Stack_Pointer (CPU'Old) + 8
                 and then Memory_Error = Memory_Model.Success
               else Machine_State.Stack_Pointer (CPU) =
                 Machine_State.Stack_Pointer (CPU'Old)
                 and then Value = 0);

   procedure Call
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : in out Memory_Model.Memory;
      Target : Machine_State.Word;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
     with Global => null,
          Pre => Machine_State.Current_Status (CPU) = Machine_State.Running,
          Post =>
            Machine_State.Current_Status (CPU) =
              Machine_State.Current_Status (CPU'Old)
            and then Machine_State.Get_Flags (CPU) =
              Machine_State.Get_Flags (CPU'Old)
            and then
              (if Result = Success
               then Machine_State.Program_Counter (CPU) = Target
                 and then Machine_State.Stack_Pointer (CPU) =
                   Machine_State.Stack_Pointer (CPU'Old) - 8
               else Machine_State.Program_Counter (CPU) =
                   Machine_State.Program_Counter (CPU'Old)
                 and then Machine_State.Stack_Pointer (CPU) =
                   Machine_State.Stack_Pointer (CPU'Old));

   procedure Return_From_Call
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : Memory_Model.Memory;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
     with Global => null,
          Pre => Machine_State.Current_Status (CPU) = Machine_State.Running,
          Post =>
            Machine_State.Current_Status (CPU) =
              Machine_State.Current_Status (CPU'Old)
            and then Machine_State.Get_Flags (CPU) =
              Machine_State.Get_Flags (CPU'Old)
            and then
              (if Result = Success
               then Machine_State.Stack_Pointer (CPU) =
                 Machine_State.Stack_Pointer (CPU'Old) + 8
               else Machine_State.Program_Counter (CPU) =
                   Machine_State.Program_Counter (CPU'Old)
                 and then Machine_State.Stack_Pointer (CPU) =
                   Machine_State.Stack_Pointer (CPU'Old));

private
   type Stack is record
      Lower : Memory_Model.Address := 0;
      Upper : Memory_Model.Address := 0;
      Configured : Boolean := False;
   end record;

   function Is_Configured (State : Stack) return Boolean
   is (State.Configured);

   function Lower_Bound (State : Stack) return Memory_Model.Address
   is (State.Lower);

   function Upper_Bound (State : Stack) return Memory_Model.Address
   is (State.Upper);
end VM_Stack;
