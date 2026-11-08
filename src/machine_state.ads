with Interfaces;

package Machine_State
  with SPARK_Mode => On
is
   subtype Word is Interfaces.Unsigned_64;
   use type Word;

   subtype Register_Index is Natural range 0 .. 15;

   type Status_Flags is record
      Z : Boolean := False;
      N : Boolean := False;
      C : Boolean := False;
      V : Boolean := False;
   end record;

   type Execution_Status is (Running, Halted, Faulted);
   type Fault_Kind is
     (No_Fault, Invalid_Instruction, Invalid_Address, Unmapped_Memory,
      Permission_Denied, Stack_Bounds, Invalid_Machine_State);

   type Machine_State is private;

   function Get_Register (State : Machine_State; Index : Register_Index) return Word
     with Global => null;
   function Program_Counter (State : Machine_State) return Word
     with Global => null;
   function Get_Flags (State : Machine_State) return Status_Flags
     with Global => null;
   function Current_Status (State : Machine_State) return Execution_Status
     with Global => null;
   function Last_Fault (State : Machine_State) return Fault_Kind
     with Global => null;

   function Initial_State return Machine_State
     with
       Global => null,
       Post =>
         Program_Counter (Initial_State'Result) = 0
         and then Current_Status (Initial_State'Result) = Running
         and then Last_Fault (Initial_State'Result) = No_Fault
         and then Get_Flags (Initial_State'Result) =
           (Z => False, N => False, C => False, V => False)
         and then
           (for all Index in Register_Index =>
              Get_Register (Initial_State'Result, Index) = 0);

   procedure Reset (State : out Machine_State)
     with
       Global => null,
       Post =>
         Program_Counter (State) = 0
         and then Current_Status (State) = Running
         and then Last_Fault (State) = No_Fault
         and then Get_Flags (State) =
           (Z => False, N => False, C => False, V => False)
         and then
           (for all Index in Register_Index =>
              Get_Register (State, Index) = 0);

   procedure Set_Register
     (State : in out Machine_State; Index : Register_Index; Value : Word)
     with
       Global => null,
       Pre => Current_Status (State) = Running,
       Post =>
         Get_Register (State, Index) = Value
         and then Program_Counter (State) = Program_Counter (State'Old)
         and then Get_Flags (State) = Get_Flags (State'Old)
         and then Current_Status (State) = Current_Status (State'Old)
         and then Last_Fault (State) = Last_Fault (State'Old);

   procedure Set_Program_Counter
     (State : in out Machine_State; Value : Word)
     with
       Global => null,
       Pre => Current_Status (State) = Running,
       Post =>
         Program_Counter (State) = Value
         and then Get_Flags (State) = Get_Flags (State'Old)
         and then Current_Status (State) = Current_Status (State'Old)
         and then Last_Fault (State) = Last_Fault (State'Old);

   procedure Set_Flags
     (State : in out Machine_State; Value : Status_Flags)
     with
       Global => null,
       Pre => Current_Status (State) = Running,
       Post =>
         Get_Flags (State) = Value
         and then Program_Counter (State) = Program_Counter (State'Old)
         and then Current_Status (State) = Current_Status (State'Old)
         and then Last_Fault (State) = Last_Fault (State'Old);

   procedure Halt (State : in out Machine_State)
     with
       Global => null,
       Pre => Current_Status (State) = Running,
       Post =>
         Current_Status (State) = Halted
         and then Program_Counter (State) = Program_Counter (State'Old)
         and then Get_Flags (State) = Get_Flags (State'Old)
         and then
           (for all Index in Register_Index =>
              Get_Register (State, Index) = Get_Register (State'Old, Index));

   procedure Raise_Fault (State : in out Machine_State; Reason : Fault_Kind)
     with
       Global => null,
       Pre => Current_Status (State) = Running and then Reason /= No_Fault,
       Post =>
         Current_Status (State) = Faulted
         and then Last_Fault (State) = Reason
         and then Program_Counter (State) = Program_Counter (State'Old)
         and then Get_Flags (State) = Get_Flags (State'Old)
         and then
           (for all Index in Register_Index =>
              Get_Register (State, Index) = Get_Register (State'Old, Index));

private
   type Register_File is array (Register_Index) of Word;
   type Machine_State is record
      Registers : Register_File := (others => 0);
      PC : Word := 0;
      Flags : Status_Flags := (Z => False, N => False, C => False, V => False);
      Status : Execution_Status := Running;
      Fault : Fault_Kind := No_Fault;
   end record;
end Machine_State;
