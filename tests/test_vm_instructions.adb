with Machine_State;
with VM_Instructions;

procedure Test_VM_Instructions is
   use Machine_State;
   use type Machine_State.Word;

   State : Machine_State.Machine_State;
   Flags : Status_Flags;
begin
   Reset (State);

   Set_Register (State, 1, Machine_State.Word'Last);
   Set_Register (State, 2, 1);
   VM_Instructions.Add (State, 3, 1, 2);
   pragma Assert (Get_Register (State, 3) = 0);
   Flags := Get_Flags (State);
   pragma Assert (Flags.Z and Flags.C and not Flags.N and not Flags.V);

   Reset (State);
   Set_Register (State, 1, 16#7FFF_FFFF_FFFF_FFFF#);
   Set_Register (State, 2, 1);
   VM_Instructions.Add (State, 1, 1, 2);
   pragma Assert (Get_Register (State, 1) = 16#8000_0000_0000_0000#);
   Flags := Get_Flags (State);
   pragma Assert (Flags.N and Flags.V and not Flags.C and not Flags.Z);

   Reset (State);
   Set_Register (State, 1, 0);
   Set_Register (State, 2, 1);
   VM_Instructions.Sub (State, 1, 1, 2);
   pragma Assert (Get_Register (State, 1) = Machine_State.Word'Last);
   Flags := Get_Flags (State);
   pragma Assert (Flags.N and Flags.C and not Flags.V and not Flags.Z);

   Reset (State);
   Set_Register (State, 1, 16#8000_0000_0000_0000#);
   Set_Register (State, 2, 1);
   VM_Instructions.Sub (State, 3, 1, 2);
   pragma Assert (Get_Register (State, 3) = 16#7FFF_FFFF_FFFF_FFFF#);
   Flags := Get_Flags (State);
   pragma Assert (Flags.V and not Flags.N and not Flags.C);

   Reset (State);
   Set_Register (State, 1, 16#F0F0#);
   Set_Register (State, 2, 16#0FF0#);
   VM_Instructions.Bit_And (State, 3, 1, 2);
   pragma Assert (Get_Register (State, 3) = 16#00F0#);
   VM_Instructions.Bit_Or (State, 4, 1, 2);
   pragma Assert (Get_Register (State, 4) = 16#FFF0#);
   VM_Instructions.Bit_Xor (State, 5, 1, 2);
   pragma Assert (Get_Register (State, 5) = 16#FF00#);

   Set_Flags (State, (Z => True, N => True, C => True, V => True));
   VM_Instructions.Mov (State, 6, 1);
   pragma Assert (Get_Register (State, 6) = 16#F0F0#);
   pragma Assert
     (Get_Flags (State) = (Z => True, N => True, C => True, V => True));

   VM_Instructions.Bit_Not (State, 7, 1);
   pragma Assert (Get_Register (State, 7) = not Machine_State.Word'(16#F0F0#));
   pragma Assert
     (Get_Flags (State) = (Z => True, N => True, C => True, V => True));

   --  Branch conditions inspect flags without modifying them.
   Set_Flags (State, (Z => True, N => False, C => True, V => False));
   Set_Program_Counter (State, 10);
   VM_Instructions.Branch (State, VM_Instructions.Zero_Set, 20);
   pragma Assert (Program_Counter (State) = 20);
   VM_Instructions.Branch (State, VM_Instructions.Carry_Clear, 30);
   pragma Assert (Program_Counter (State) = 20);
   VM_Instructions.Branch (State, VM_Instructions.Always, 40);
   pragma Assert (Program_Counter (State) = 40);
   pragma Assert
     (Get_Flags (State) = (Z => True, N => False, C => True, V => False));

   VM_Instructions.Halt (State);
   pragma Assert (Current_Status (State) = Halted);
end Test_VM_Instructions;
