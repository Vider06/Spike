with Machine_State;

procedure Test_Machine_State is
   use Machine_State;

   State : Machine_State;
   Expected_Flags : constant Status_Flags :=
     (Z => True, N => False, C => True, V => False);
begin
   Reset (State);

   pragma Assert (Program_Counter (State) = 0);
   pragma Assert (Current_Status (State) = Running);
   pragma Assert
     (Get_Flags (State) = (Z => False, N => False, C => False, V => False));

   for Index in Register_Index loop
      pragma Assert (Get_Register (State, Index) = 0);
   end loop;

   Set_Register (State, 0, 16#FFFF_FFFF_FFFF_FFFF#);
   Set_Register (State, 15, 42);
   pragma Assert (Get_Register (State, 0) = Word'Last);
   pragma Assert (Get_Register (State, 15) = 42);
   pragma Assert (Get_Register (State, 1) = 0);

   Set_Program_Counter (State, 7);
   pragma Assert (Program_Counter (State) = 7);

   Set_Flags (State, Expected_Flags);
   pragma Assert (Get_Flags (State) = Expected_Flags);

   Halt (State);
   pragma Assert (Current_Status (State) = Halted);
   pragma Assert (Program_Counter (State) = 7);
   pragma Assert (Get_Flags (State) = Expected_Flags);
   pragma Assert (Get_Register (State, 0) = Word'Last);
   pragma Assert (Get_Register (State, 15) = 42);

   Reset (State);
   pragma Assert (Current_Status (State) = Running);
   pragma Assert (Program_Counter (State) = 0);
   pragma Assert (Get_Register (State, 0) = 0);
   pragma Assert
     (Get_Flags (State) = (Z => False, N => False, C => False, V => False));
end Test_Machine_State;
