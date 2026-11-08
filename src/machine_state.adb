package body Machine_State
  with SPARK_Mode => On
is
   function Initial_State return Machine_State is
      State : Machine_State;
   begin
      Reset (State);
      return State;
   end Initial_State;

   procedure Reset (State : out Machine_State) is
   begin
      State :=
        (Registers => (others => 0),
         PC        => 0,
         Flags     => (Z => False, N => False, C => False, V => False),
         Status    => Running);
   end Reset;

   function Get_Register
     (State : Machine_State;
      Index : Register_Index) return Word
   is
   begin
      return State.Registers (Index);
   end Get_Register;

   procedure Set_Register
     (State : in out Machine_State;
      Index : Register_Index;
      Value : Word)
   is
   begin
      State.Registers (Index) := Value;
   end Set_Register;

   function Program_Counter (State : Machine_State) return Word is
   begin
      return State.PC;
   end Program_Counter;

   procedure Set_Program_Counter
     (State : in out Machine_State;
      Value : Word)
   is
   begin
      State.PC := Value;
   end Set_Program_Counter;

   function Get_Flags (State : Machine_State) return Status_Flags is
   begin
      return State.Flags;
   end Get_Flags;

   procedure Set_Flags
     (State : in out Machine_State;
      Value : Status_Flags)
   is
   begin
      State.Flags := Value;
   end Set_Flags;

   function Current_Status
     (State : Machine_State) return Execution_Status
   is
   begin
      return State.Status;
   end Current_Status;

   procedure Halt (State : in out Machine_State) is
   begin
      State.Status := Halted;
   end Halt;
end Machine_State;
