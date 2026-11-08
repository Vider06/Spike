with Machine_State;

package VM_Instructions
  with SPARK_Mode => On
is
   subtype Register_Index is Machine_State.Register_Index;

   procedure Mov
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Source : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;

   procedure Add
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;

   procedure Sub
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;

   procedure Bit_And
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;

   procedure Bit_Or
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;

   procedure Bit_Xor
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;

   procedure Bit_Not
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Source : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;

   procedure Halt
     (State : in out Machine_State.Machine_State)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running;
end VM_Instructions;
