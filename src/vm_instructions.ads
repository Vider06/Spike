with Machine_State;

package VM_Instructions
  with SPARK_Mode => On
is
   subtype Register_Index is Machine_State.Register_Index;
   use type Machine_State.Word;
   use type Machine_State.Status_Flags;
   use type Machine_State.Execution_Status;

   Sign_Mask : constant Machine_State.Word := 16#8000_0000_0000_0000#;

   type Branch_Condition is
     (Always, Zero_Set, Zero_Clear, Negative_Set, Negative_Clear,
      Carry_Set, Carry_Clear, Overflow_Set, Overflow_Clear);

   function Condition_Holds
     (Flags : Machine_State.Status_Flags; Condition : Branch_Condition)
      return Boolean
     with Global => null;

   procedure Mov
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Source : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Get_Register (State, Destination) =
              Machine_State.Get_Register (State'Old, Source)
            and then Machine_State.Get_Flags (State) =
              Machine_State.Get_Flags (State'Old)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Add
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Get_Register (State, Destination) =
              Machine_State.Get_Register (State'Old, Left) +
              Machine_State.Get_Register (State'Old, Right)
            and then Machine_State.Get_Flags (State) =
              (Z =>
                 Machine_State.Get_Register (State'Old, Left) +
                 Machine_State.Get_Register (State'Old, Right) = 0,
               N =>
                 ((Machine_State.Get_Register (State'Old, Left) +
                   Machine_State.Get_Register (State'Old, Right)) and Sign_Mask) /= 0,
               C =>
                 Machine_State.Get_Register (State'Old, Left) +
                 Machine_State.Get_Register (State'Old, Right) <
                   Machine_State.Get_Register (State'Old, Left),
               V =>
                 ((not
                     (Machine_State.Get_Register (State'Old, Left) xor
                      Machine_State.Get_Register (State'Old, Right)))
                  and
                    (Machine_State.Get_Register (State'Old, Left) xor
                     (Machine_State.Get_Register (State'Old, Left) +
                      Machine_State.Get_Register (State'Old, Right)))
                  and Sign_Mask) /= 0)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Sub
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Get_Register (State, Destination) =
              Machine_State.Get_Register (State'Old, Left) -
              Machine_State.Get_Register (State'Old, Right)
            and then Machine_State.Get_Flags (State) =
              (Z =>
                 Machine_State.Get_Register (State'Old, Left) -
                 Machine_State.Get_Register (State'Old, Right) = 0,
               N =>
                 ((Machine_State.Get_Register (State'Old, Left) -
                   Machine_State.Get_Register (State'Old, Right)) and Sign_Mask) /= 0,
               C =>
                 Machine_State.Get_Register (State'Old, Left) <
                   Machine_State.Get_Register (State'Old, Right),
               V =>
                 ((Machine_State.Get_Register (State'Old, Left) xor
                   Machine_State.Get_Register (State'Old, Right))
                  and
                    (Machine_State.Get_Register (State'Old, Left) xor
                     (Machine_State.Get_Register (State'Old, Left) -
                      Machine_State.Get_Register (State'Old, Right)))
                  and Sign_Mask) /= 0)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Bit_And
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Get_Register (State, Destination) =
              (Machine_State.Get_Register (State'Old, Left) and
               Machine_State.Get_Register (State'Old, Right))
            and then Machine_State.Get_Flags (State) =
              (Z =>
                 (Machine_State.Get_Register (State'Old, Left) and
                  Machine_State.Get_Register (State'Old, Right)) = 0,
               N =>
                 ((Machine_State.Get_Register (State'Old, Left) and
                   Machine_State.Get_Register (State'Old, Right)) and Sign_Mask) /= 0,
               C => False, V => False)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Bit_Or
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Get_Register (State, Destination) =
              (Machine_State.Get_Register (State'Old, Left) or
               Machine_State.Get_Register (State'Old, Right))
            and then Machine_State.Get_Flags (State) =
              (Z =>
                 (Machine_State.Get_Register (State'Old, Left) or
                  Machine_State.Get_Register (State'Old, Right)) = 0,
               N =>
                 ((Machine_State.Get_Register (State'Old, Left) or
                   Machine_State.Get_Register (State'Old, Right)) and Sign_Mask) /= 0,
               C => False, V => False)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Bit_Xor
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Get_Register (State, Destination) =
              (Machine_State.Get_Register (State'Old, Left) xor
               Machine_State.Get_Register (State'Old, Right))
            and then Machine_State.Get_Flags (State) =
              (Z =>
                 (Machine_State.Get_Register (State'Old, Left) xor
                  Machine_State.Get_Register (State'Old, Right)) = 0,
               N =>
                 ((Machine_State.Get_Register (State'Old, Left) xor
                   Machine_State.Get_Register (State'Old, Right)) and Sign_Mask) /= 0,
               C => False, V => False)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Bit_Not
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Source : Register_Index)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Get_Register (State, Destination) =
              not Machine_State.Get_Register (State'Old, Source)
            and then Machine_State.Get_Flags (State) =
              Machine_State.Get_Flags (State'Old)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Branch
     (State : in out Machine_State.Machine_State;
      Condition : Branch_Condition;
      Target : Machine_State.Word)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Program_Counter (State) =
              (if Condition_Holds (Machine_State.Get_Flags (State'Old), Condition)
               then Target
               else Machine_State.Program_Counter (State'Old))
            and then Machine_State.Get_Flags (State) =
              Machine_State.Get_Flags (State'Old)
            and then Machine_State.Current_Status (State) =
              Machine_State.Current_Status (State'Old);

   procedure Halt
     (State : in out Machine_State.Machine_State)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Current_Status (State) = Machine_State.Halted
            and then
              (for all Index in Register_Index =>
                 Machine_State.Get_Register (State, Index) =
                   Machine_State.Get_Register (State'Old, Index))
            and then Machine_State.Get_Flags (State) =
              Machine_State.Get_Flags (State'Old);
end VM_Instructions;
