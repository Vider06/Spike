with Machine_State;
with VM_Instructions;

procedure Test_VM_Instructions
  with SPARK_Mode => On
is
   use Machine_State;
   use VM_Instructions;
   use type Machine_State.Word;

   State : Machine_State.Machine_State;
   Flags : Status_Flags;
begin
   Reset (State);

   Set_Register (State, 1, Word'Last);
   Set_Register (State, 2, 1);
   Add (State, 3, 1, 2);
   pragma Assert (Get_Register (State, 3) = 0);
   Flags := Get_Flags (State);
   pragma Assert (Flags.Z and Flags.C and not Flags.N and not Flags.V);

   Reset (State);
   Set_Register (State, 1, 16#7FFF_FFFF_FFFF_FFFF#);
   Set_Register (State, 2, 1);
   Add (State, 1, 1, 2);
   pragma Assert (Get_Register (State, 1) = 16#8000_0000_0000_0000#);
   Flags := Get_Flags (State);
   pragma Assert (Flags.N and Flags.V and not Flags.C and not Flags.Z);

   Reset (State);
   Set_Register (State, 1, 0);
   Set_Register (State, 2, 1);
   Sub (State, 1, 1, 2);
   pragma Assert (Get_Register (State, 1) = Word'Last);
   Flags := Get_Flags (State);
   pragma Assert (Flags.N and Flags.C and not Flags.V and not Flags.Z);

   Reset (State);
   Set_Register (State, 1, 16#8000_0000_0000_0000#);
   Set_Register (State, 2, 1);
   Sub (State, 3, 1, 2);
   pragma Assert (Get_Register (State, 3) = 16#7FFF_FFFF_FFFF_FFFF#);
   Flags := Get_Flags (State);
   pragma Assert (Flags.V and not Flags.N and not Flags.C);

   Reset (State);
   Set_Register (State, 1, 16#F0F0#);
   Set_Register (State, 2, 16#0FF0#);
   Bit_And (State, 3, 1, 2);
   pragma Assert (Get_Register (State, 3) = 16#00F0#);
   Bit_Or (State, 4, 1, 2);
   pragma Assert (Get_Register (State, 4) = 16#FFF0#);
   Bit_Xor (State, 5, 1, 2);
   pragma Assert (Get_Register (State, 5) = 16#FF00#);

   Set_Flags (State, (Z => True, N => True, C => True, V => True));
   Mov (State, 6, 1);
   pragma Assert (Get_Register (State, 6) = 16#F0F0#);
   pragma Assert
     (Get_Flags (State) = (Z => True, N => True, C => True, V => True));

   Bit_Not (State, 7, 1);
   pragma Assert (Get_Register (State, 7) = not Word'(16#F0F0#));
   pragma Assert
     (Get_Flags (State) = (Z => True, N => True, C => True, V => True));

   VM_Instructions.Halt (State);
   pragma Assert (Current_Status (State) = Halted);
end Test_VM_Instructions;
