with Machine_State;

package VM_Instructions
  with SPARK_Mode => On
is
   subtype Register_Index is Machine_State.Register_Index;
   subtype Word is Machine_State.Word;
   use type Word;
   use type Machine_State.Status_Flags;
   use type Machine_State.Execution_Status;

   Sign_Mask : constant Word := 16#8000_0000_0000_0000#;

   type Branch_Condition is
     (Always, Zero_Set, Zero_Clear, Negative_Set, Negative_Clear,
      Carry_Set, Carry_Clear, Overflow_Set, Overflow_Clear);

   --  Pure semantic functions make the VM contract independently reusable.
   --  They describe virtual 64-bit behavior, not source-language syntax.
   function Add_Value (Left, Right : Word) return Word
     with Global => null,
          Post => Add_Value'Result = Left + Right;

   function Subtract_Value (Left, Right : Word) return Word
     with Global => null,
          Post => Subtract_Value'Result = Left - Right;

   function Logical_Flags (Value : Word) return Machine_State.Status_Flags
     with Global => null,
          Post =>
            Logical_Flags'Result =
              (Z => Value = 0,
               N => (Value and Sign_Mask) /= 0,
               C => False,
               V => False);

   function Add_Flags (Left, Right : Word)
     return Machine_State.Status_Flags
     with Global => null,
          Post =>
            Add_Flags'Result =
              (Z => Add_Value (Left, Right) = 0,
               N => (Add_Value (Left, Right) and Sign_Mask) /= 0,
               C => Add_Value (Left, Right) < Left,
               V =>
                 ((not (Left xor Right))
                  and (Left xor Add_Value (Left, Right))
                  and Sign_Mask) /= 0);

   function Subtract_Flags (Left, Right : Word)
     return Machine_State.Status_Flags
     with Global => null,
          Post =>
            Subtract_Flags'Result =
              (Z => Subtract_Value (Left, Right) = 0,
               N => (Subtract_Value (Left, Right) and Sign_Mask) /= 0,
               C => Left < Right,
               V =>
                 ((Left xor Right)
                  and (Left xor Subtract_Value (Left, Right))
                  and Sign_Mask) /= 0);

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
              Add_Value
                (Machine_State.Get_Register (State'Old, Left),
                 Machine_State.Get_Register (State'Old, Right))
            and then Machine_State.Get_Flags (State) =
              Add_Flags
                (Machine_State.Get_Register (State'Old, Left),
                 Machine_State.Get_Register (State'Old, Right))
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
              Subtract_Value
                (Machine_State.Get_Register (State'Old, Left),
                 Machine_State.Get_Register (State'Old, Right))
            and then Machine_State.Get_Flags (State) =
              Subtract_Flags
                (Machine_State.Get_Register (State'Old, Left),
                 Machine_State.Get_Register (State'Old, Right))
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
              Logical_Flags
                (Machine_State.Get_Register (State'Old, Left) and
                 Machine_State.Get_Register (State'Old, Right))
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
              Logical_Flags
                (Machine_State.Get_Register (State'Old, Left) or
                 Machine_State.Get_Register (State'Old, Right))
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
              Logical_Flags
                (Machine_State.Get_Register (State'Old, Left) xor
                 Machine_State.Get_Register (State'Old, Right))
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
      Target : Word)
     with Global => null,
          Pre => Machine_State.Current_Status (State) = Machine_State.Running,
          Post =>
            Machine_State.Program_Counter (State) =
              (if Condition_Holds
                    (Machine_State.Get_Flags (State'Old), Condition)
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
