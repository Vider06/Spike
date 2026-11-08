with Interfaces;

package body VM_Instructions
  with SPARK_Mode => On
is
   use Machine_State;

   Sign_Mask : constant Word := 16#8000_0000_0000_0000#;

   function Result_Flags
     (Value : Word; Carry : Boolean := False; Overflow : Boolean := False)
      return Status_Flags
   is
   begin
      return
        (Z => Value = 0,
         N => (Value and Sign_Mask) /= 0,
         C => Carry,
         V => Overflow);
   end Result_Flags;

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
      Value : constant Word := Left_Value + Right_Value;
      Carry : constant Boolean := Value < Left_Value;
      Overflow : constant Boolean :=
        ((not (Left_Value xor Right_Value))
         and (Left_Value xor Value)
         and Sign_Mask) /= 0;
      Flags : constant Status_Flags := Result_Flags (Value, Carry, Overflow);
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
      Value : constant Word := Left_Value - Right_Value;
      Borrow : constant Boolean := Left_Value < Right_Value;
      Overflow : constant Boolean :=
        ((Left_Value xor Right_Value)
         and (Left_Value xor Value)
         and Sign_Mask) /= 0;
      Flags : constant Status_Flags := Result_Flags (Value, Borrow, Overflow);
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
      Flags : constant Status_Flags := Result_Flags (Value);
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Flags);
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
      Flags : constant Status_Flags := Result_Flags (Value);
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Flags);
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
      Flags : constant Status_Flags := Result_Flags (Value);
   begin
      Set_Register (State, Destination, Value);
      Set_Flags (State, Flags);
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
