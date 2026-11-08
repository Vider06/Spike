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
        (Registers => [others => 0],
         PC        => 0,
         Flags     => (Z => False, N => False, C => False, V => False),
         Status    => Running,
         Fault     => No_Fault);
   end Reset;

   procedure Set_Register
     (State : in out Machine_State; Index : Register_Index; Value : Word)
   is
   begin
      State.Registers (Index) := Value;
   end Set_Register;

   procedure Set_Program_Counter
     (State : in out Machine_State; Value : Word)
   is
   begin
      State.PC := Value;
   end Set_Program_Counter;

   procedure Set_Flags
     (State : in out Machine_State; Value : Status_Flags)
   is
   begin
      State.Flags := Value;
   end Set_Flags;

   procedure Halt (State : in out Machine_State) is
   begin
      State.Status := Halted;
   end Halt;

   procedure Raise_Fault
     (State : in out Machine_State; Reason : Fault_Kind)
   is
   begin
      State.Status := Faulted;
      State.Fault := Reason;
   end Raise_Fault;
end Machine_State;
