package body VM_Instructions
  with SPARK_Mode => On
is
   use Machine_State;

   function Add_Value (Left, Right : Word) return Word is
     (Left + Right);

   function Subtract_Value (Left, Right : Word) return Word is
     (Left - Right);

   function Logical_Flags (Value : Word) return Status_Flags is
     (Z => Value = 0,
      N => (Value and Sign_Mask) /= 0,
      C => False,
      V => False);

   function Add_Flags (Left, Right : Word) return Status_Flags is
      Value : constant Word := Add_Value (Left, Right);
   begin
      return
        (Z => Value = 0,
         N => (Value and Sign_Mask) /= 0,
         C => Value < Left,
         V => ((not (Left xor Right)) and (Left xor Value) and Sign_Mask) /= 0);
   end Add_Flags;

   function Subtract_Flags (Left, Right : Word) return Status_Flags is
      Value : constant Word := Subtract_Value (Left, Right);
   begin
      return
        (Z => Value = 0,
         N => (Value and Sign_Mask) /= 0,
         C => Left < Right,
         V => ((Left xor Right) and (Left xor Value) and Sign_Mask) /= 0);
   end Subtract_Flags;

   function Condition_Holds
     (Flags : Machine_State.Status_Flags; Condition : Branch_Condition)
      return Boolean
   is
   begin
      case Condition is
         when Always         => return True;
         when Zero_Set       => return Flags.Z;
         when Zero_Clear     => return not Flags.Z;
         when Negative_Set   => return Flags.N;
         when Negative_Clear => return not Flags.N;
         when Carry_Set      => return Flags.C;
         when Carry_Clear    => return not Flags.C;
         when Overflow_Set   => return Flags.V;
         when Overflow_Clear => return not Flags.V;
      end case;
   end Condition_Holds;

   procedure Branch
     (State : in out Machine_State.Machine_State;
      Condition : Branch_Condition;
      Target : Word)
   is
   begin
      if Condition_Holds (Get_Flags (State), Condition) then
         Set_Program_Counter (State, Target);
      end if;
   end Branch;

   procedure Mov
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Source : Register_Index)
   is
      Value : constant Word := Get_Register (State, Source);
   begin
      Set_Register (State, Destination, Value);
   end Mov;

   procedure Add
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
   is
      Left_Value : constant Word := Get_Register (State, Left);
      Right_Value : constant Word := Get_Register (State, Right);
      Value : constant Word := Add_Value (Left_Value, Right_Value);
      Flags : constant Status_Flags := Add_Flags (Left_Value, Right_Value);
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Flags);
   end Add;

   procedure Sub
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
   is
      Left_Value : constant Word := Get_Register (State, Left);
      Right_Value : constant Word := Get_Register (State, Right);
      Value : constant Word := Subtract_Value (Left_Value, Right_Value);
      Flags : constant Status_Flags :=
        Subtract_Flags (Left_Value, Right_Value);
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Flags);
   end Sub;

   procedure Bit_And
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
   is
      Left_Value : constant Word := Get_Register (State, Left);
      Right_Value : constant Word := Get_Register (State, Right);
      Value : constant Word := Left_Value and Right_Value;
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Logical_Flags (Value));
   end Bit_And;

   procedure Bit_Or
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
   is
      Left_Value : constant Word := Get_Register (State, Left);
      Right_Value : constant Word := Get_Register (State, Right);
      Value : constant Word := Left_Value or Right_Value;
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Logical_Flags (Value));
   end Bit_Or;

   procedure Bit_Xor
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Left : Register_Index;
      Right : Register_Index)
   is
      Left_Value : constant Word := Get_Register (State, Left);
      Right_Value : constant Word := Get_Register (State, Right);
      Value : constant Word := Left_Value xor Right_Value;
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Logical_Flags (Value));
   end Bit_Xor;

   procedure Bit_Not
     (State : in out Machine_State.Machine_State;
      Destination : Register_Index;
      Source : Register_Index)
   is
      Value : constant Word := not Get_Register (State, Source);
   begin
      Set_Register (State, Destination, Value);
   end Bit_Not;

   procedure Halt (State : in out Machine_State.Machine_State) is
   begin
      Machine_State.Halt (State);
   end Halt;
end VM_Instructions;
