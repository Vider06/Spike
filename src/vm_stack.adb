package body VM_Stack
  with SPARK_Mode => On
is
   use type Memory_Model.Address;
   use type Memory_Model.Memory_Result;
   use type Machine_State.Word;

   procedure Configure
     (State : out Stack;
      CPU : in out Machine_State.Machine_State;
      Lower : Memory_Model.Address;
      Upper : Memory_Model.Address;
      Result : out Stack_Result)
   is
   begin
      State := (Lower => 0, Upper => 0, Configured => False);

      if Lower >= Upper
        or else Lower mod 8 /= 0
        or else Upper mod 8 /= 0
        or else Upper - Lower < 8
      then
         Result := Invalid_Bounds;
         return;
      end if;

      State := (Lower => Lower, Upper => Upper, Configured => True);
      Machine_State.Set_Stack_Pointer (CPU, Machine_State.Word (Upper));
      Result := Success;
   end Configure;

   procedure Push
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : in out Memory_Model.Memory;
      Value : Machine_State.Word;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
   is
      Current : constant Memory_Model.Address :=
        Memory_Model.Address (Machine_State.Stack_Pointer (CPU));
      Next : Memory_Model.Address;
   begin
      Memory_Error := Memory_Model.Invalid_Range;

      if not State.Configured then
         Result := Not_Configured;
      elsif Current < State.Lower
        or else Current > State.Upper
        or else Current - State.Lower < 8
      then
         Result := Stack_Overflow;
      else
         Next := Current - 8;
         Memory_Model.Write_Word
           (Memory, Next, Memory_Model.Word (Value), Memory_Error);
         if Memory_Error = Memory_Model.Success then
            Machine_State.Set_Stack_Pointer
              (CPU, Machine_State.Word (Next));
            Result := Success;
         else
            Result := Memory_Access_Failed;
         end if;
      end if;
   end Push;

   procedure Pop
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : Memory_Model.Memory;
      Value : out Machine_State.Word;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
   is
      Current : constant Memory_Model.Address :=
        Memory_Model.Address (Machine_State.Stack_Pointer (CPU));
      Next : Memory_Model.Address;
      Loaded : Memory_Model.Word;
   begin
      Value := 0;
      Memory_Error := Memory_Model.Invalid_Range;

      if not State.Configured then
         Result := Not_Configured;
      elsif Current < State.Lower
        or else Current >= State.Upper
        or else Current > State.Upper - 8
      then
         Result := Stack_Underflow;
      else
         Memory_Model.Read_Word (Memory, Current, Loaded, Memory_Error);
         if Memory_Error = Memory_Model.Success then
            Next := Current + 8;
            Machine_State.Set_Stack_Pointer
              (CPU, Machine_State.Word (Next));
            Value := Machine_State.Word (Loaded);
            Result := Success;
         else
            Result := Memory_Access_Failed;
         end if;
      end if;
   end Pop;
   procedure Call
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : in out Memory_Model.Memory;
      Target : Machine_State.Word;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
   is
      Return_Address : Machine_State.Word;
   begin
      if Machine_State.Program_Counter (CPU) = Machine_State.Word'Last then
         Result := Invalid_Return_Address;
         Memory_Error := Memory_Model.Invalid_Range;
         return;
      end if;

      Return_Address := Machine_State.Program_Counter (CPU) + 1;
      Push (State, CPU, Memory, Return_Address, Result, Memory_Error);
      if Result = Success then
         Machine_State.Set_Program_Counter (CPU, Target);
      end if;
   end Call;

   procedure Return_From_Call
     (State : Stack;
      CPU : in out Machine_State.Machine_State;
      Memory : Memory_Model.Memory;
      Result : out Stack_Result;
      Memory_Error : out Memory_Model.Memory_Result)
   is
      Return_Address : Machine_State.Word;
   begin
      Pop (State, CPU, Memory, Return_Address, Result, Memory_Error);
      if Result = Success then
         Machine_State.Set_Program_Counter (CPU, Return_Address);
      end if;
   end Return_From_Call;
end VM_Stack;
