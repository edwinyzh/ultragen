unit InterpreterClass;

{$mode objfpc}{$H+}

interface

uses
      Classes, SysUtils, ASTClass,
      BinOpClass, NumClass, UnaryOpClass, BinLogicOpClass, UnaryLogicopClass,
      Tokens, ImpParserClass, StrUtils, LoggingClass, FlowControlASTClass,
      StackClass, ARClass, InstanceofClass, CoreFunctionsClass;

type
  TInterpreter = class
    private
      FTree: TAST;
      FCallStack: TStack;
      FCore: TCoreFunction;

    public
      property PTree:TAST read FTree;
      constructor Create(var ATree: TAST);
      function Visit(ANode:TAST):TInstanceOf;
      procedure VisitProgram(ANode: TProgram);
      procedure VisitNoOp(ANode: TNoOp);
      procedure VisitVarAssign(ANode: TVarAssign);
      function VisitVariableReference(ANode: TVariableReference):TInstanceOf;
      function VisitBinOp(ANode:TBinOp):TInstanceOf;

      //overloads
      function VisitBinLogicOp(ANode: TBinLogicOp): TBooleanInstance;

      function VisitBoolean(ANode:TBoolean):TBooleanInstance;
      function VisitNumInt(ANode:TNumInt):TIntegerInstance;
      function VisitNull(ANode:TNull):TNullInstance;
      function VisitNumFloat(ANode:TNumFloat):TFloatInstance;
      function VisitString(ANode:TString):TStringInstance;
      function VisitFunctionCall(ANode: TFunctionCall):TInstanceOf;
      function VisitFunctionDefinition(ANode: TFunctionDefinition): TInstanceOf;


      //overloads
      function VisitUnaryOp(ANode: TUnaryOp):TFloatInstance;
      function VisitUnaryOp(ANode: TUnaryOp):TIntegerInstance;
      function VisitUnaryLogicOp(ANode: TUnaryLogicOp):TBooleanInstance;
      function Interpret:string;

      // flow
      function VisitIfCondition(ANode: TIfConditionBlock):TBooleanInstance;
      procedure VisitConditional(ANode: TConditional);
      procedure VisitWhileLoop(ANode: TWhileLoop);

	end;

implementation

uses
  Math, ExceptionsClasses;


constructor TInterpreter.Create(var ATree: TAST);
begin
  FCore := TCoreFunction.Create;
  FTree := ATree;
  FCallStack := TStack.Create;
end;

function TInterpreter.Interpret:string;
var
  Ret:TInstanceOf;
begin
  Ret := Visit(FTree);

  Result := '';
end;

function TInterpreter.VisitFunctionDefinition(ANode: TFunctionDefinition):TInstanceOf;
var
  i, len: integer;
  AParam: string;
  AValue: TFunctionInstance;
  AActRec: TActivationRecord;
  ABlock: TAST;
begin
  logtext('INTER', 'Interpreter', 'Visiting function definition');
  AActRec := FCallStack.Peek;
  AValue := TFunctionInstance.Create(ANode.PName);
  len := Length(ANode.PParamList);
  if len > 0 then
  begin
    for i:=0 to (len - 1) do
    begin
      AParam :=  TVarAssign(ANode.PParamList[i]).PVarName.PValue;
      Logtext('INTER', 'Interpreter', 'Adding parameter ' +AParam+ ' to AR');
      AValue.AddParam(AParam);
    end;
	end;
  AValue.PBlock := ANode.PBlock;
	AActrec.AddMember(ANode.PName, AValue);

  // ASymbolTable.AsString;
end;

procedure TInterpreter.VisitConditional(ANode: TConditional);
var
  ACondition: TAST;
  Return: TBooleanInstance;
begin
  for ACondition in ANode.PConditions do
  begin
    Return := VisitIfCondition(TIfConditionBlock(ACondition));
    if Return.PValue then
      break;
  end;
end;

function TInterpreter.VisitIfCondition(ANode: TIfConditionBlock): TBooleanInstance;
var
  AEval: TBooleanInstance = nil;
  ABlockNode: TAST;
begin
  if ANode.PCondition <> nil then
  begin
    AEval := TBooleanInstance(Visit(ANode.PCondition));
    if AEval.PValue or (ANode.PCondition = nil) then
    begin
      for ABlockNode in ANode.PBlock do
        Visit(ABlockNode);
    end;
  end
  else
  begin
    for ABlockNode in ANode.PBlock do
        Visit(ABlockNode);
    AEval := TBooleanInstance.Create(False);
  end;
  Result := AEval;
end;

procedure TInterpreter.VisitWhileLoop(ANode: TWhileLoop);
var
  AState:TAST;
begin
  while TBooleanInstance(Visit(ANode.PCondition)).PValue do
  begin
    for AState in ANode.PBLock do
      Visit(AState);
  end;
end;

procedure TInterpreter.VisitVarAssign(ANode: TVarAssign);
var
  AValue: TInstanceOf;
  AName: string;
  AActRec: TActivationRecord;
begin
  LogText(INTER, 'Interpreter', 'VarAssign visitation');
  AName := ANode.PVarName.PValue;
  AValue := Visit(ANode.PValue);
  AActrec := FCallStack.Peek;
  {if AValue.ClassNameIs('TStringInstance') then
    AActRec.AddMember(AName, TStringInstance(AValue))
  else if AValue.ClassNameIs('TBooleanInstance') then
    AActRec.AddMember(AName, TBooleanInstance(AValue))
  else if AValue.ClassNameIs('TIntegerInstance') then
    AActRec.AddMember(AName, TIntegerInstance(AValue))
  else if AValue.ClassNameIs('TFloatInstance') then
    AActRec.AddMember(AName, TFloatInstance(AValue))
  else if AValue.ClassNameIs('TFunctionInstance') then
    AActRec.AddMember(Aname, AValue)
  else}
    AActRec.AddMember(AName, AValue);
  //LogText(DEBUG, 'Interpreter', 'Assigning var '+ ANode.PLeft.PToken.AsString +' to symbol table');
  //ASolve := visit(ANode.PRight);
  // FGlobals.Add(ANode.PLeft.PToken.PValue+'='+FloatToStr(ASolve));
  //LogText(DEBUG, 'Interpreter', 'Added value :'+ FGlobals.Values[ANode.PLeft.PToken.PValue]);
end;

function TInterpreter.VisitVariableReference(ANode: TVariableReference):TInstanceOf;
var
  AName:string;
  AActRec: TActivationRecord;
  Ret: TInstanceOf;
  ResFloat: TFloatInstance;
begin
  AName := Anode.PToken.PValue;

  AActRec := FCallStack.Peek();
  //ResFloat := TFloatInstance(AActRec.GetMember(AName));
  Ret := AActRec.GetMember(AName);
  LogText(INTER, 'Interpreter', 'Getting value of "'+ ANode.PToken.PValue+'" from type '+Ret.ClassName);
  Result := Ret;
end;

function TInterpreter.VisitFunctionCall(ANode: TFunctionCall):TInstanceOf;
var
  AActRec, ARNext: TActivationRecord;
  AState: TAST;
  Res: TInstanceOf;
  FuncDef: TFunctioninstance;
  i, len, len2: integer;
  ArgsList: TInstanceList;
begin

  LogText(INTER, 'Interpreter', 'Visiting function ' + ANode.PFuncName);
  if not FCore.FunctionExists(ANode.PFuncName) then
  begin

        ARNext := TActivationRecord.Create(ANode.PToken.PValue, AR_FUNCTION, FCallStack.PLevel+1);
        AActRec := FCallStack.Peek();
		    FuncDef := TFunctionInstance(AActRec.GetMember(Anode.PFuncname));

		    len := length(FuncDef.PParams);
		    if len > 0 then
		    begin
		      for i:=0 to len-1 do
		      begin
            {if Anode.PEvalParams[i].PToken.PType = T_ID then
		          Res := VisitVariableReference(TVariablereference(Anode.PEvalParams[i]))
            else
              }Res := Visit(Anode.PEvalParams[i]);
						LogText(INTER, 'Interpreter', 'Registering param ' + FuncDef.PParams[i] + ' with value '+Res.ClassName);
		        ARNext.AddMember(FuncDef.PParams[i], Res);
			    end;
			  end;
		    FCallStack.Push(ARNext);
		    for AState in FuncDef.PBlock do
		    begin
		      LogText(INTER, 'Interpreter', 'Visiting a function statement ' + AState.ToString);
		      Visit(AState);
		    end;
			  FCallStack.Pop();
	end
  else
  begin
    SetLength(ArgsList, 0);
    len := Length(Anode.PEvalParams);
    if len > 0 then
    begin
      for i:=0 to len-1 do
      begin
        {if (Anode.PEvalParams[i].PToken.PType = T_ID) then
          Res := VisitVariableReference(TVariableReference(Anode.PEvalParams[i]))
        else
          }Res := Visit(Anode.PEvalParams[i]);
        LogText(INTER, 'Interpreter', 'Registering param ' + Anode.PEvalParams[i].PToken.PValue + ' with value '+Res.ClassName);
        SetLength(ArgsList, i+1);
        ArgsList[i] := Res;
	    end;
	  end;
    Res := FCore.Execute(ANode.PToken.PValue, ArgsList);
    Result := Res;
	end;
end;

procedure TInterpreter.VisitProgram(ANode: TProgram);
var
  AChild: TAST;
  AActRec: TActivationRecord;
begin
  LogText(INTER, 'Interpreter', 'Visiting a program');
  AActRec := TActivationRecord.Create('PROGRAM', AR_PROGRAM, 1);
  FCallStack.Push(AActRec);
  for AChild in ANode.PChildren do
  begin
    LogText(INTER, 'Interpreter', 'Visiting a child ' + AChild.ToString);
    Visit(AChild);
  end;
  FCallStack.Pop();
end;

procedure TInterpreter.VisitNoOp(ANode: TNoOp);
begin

end;

function TInterpreter.Visit(ANode:TAST):TInstanceOf;
var
  AuxBool:boolean;
begin
  if ANode.ClassNameIs('TProgram') then
  begin
    VisitProgram(TProgram(ANode));
  end
  else if ANode.ClassNameIs('TVarAssign') then   
    VisitVarAssign(TVarAssign(ANode))
  else if ANode.ClassNameIs('TVariableReference') then
    Result := VisitVariableReference(TVariableReference(ANode))
  else if ANode.ClassNameIs('TFunctionCall') then
    Result := VisitFunctionCall(TFunctionCall(Anode))
  else if ANode.ClassNameIs('TFunctionDefinition') then
    VisitFunctionDefinition(TFunctionDefinition(Anode))
  else if Anode.ClassNameIs('TNumInt') then
    Result := VisitNumInt(TNumInt(ANode))
  else if Anode.ClassNameIs('TNull') then
    Result := VisitNull(TNull(ANode))
  else if Anode.ClassNameIs('TNumFloat') then
    Result := VisitNumFloat(TNumFloat(ANode))
  else if Anode.ClassNameIs('TString') then
    Result := VisitString(TString(ANode))
  else if Anode.ClassNameIs('TBoolean') then
    Result := VisitBoolean(TBoolean(ANode))
  else if ANode.ClassNameIs('TUnaryOp') then
    Result := VisitUnaryOp(TUnaryOp(ANode))
  else if ANode.ClassNameIs('TBinOp') then
    Result := VisitBinOp(TBinOp(ANode))
  else if ANode.ClassNameIs('TBinLogicOp') then
    Result := VisitBinLogicOp(TBinLogicOp(ANode))
  else if ANode.ClassNameIs('TUnaryLogicOp') then
    Result := VisitUnaryLogicOp(TUnaryLogicOp(ANode))
  else if ANode.ClassNameIs('TConditional') then
    VisitConditional(TConditional(ANode))
  else if ANode.ClassNameIs('TIfConditionBlock') then
    VisitIfCondition(TIfConditionBlock(ANode))
  else if ANode.ClassNameIs('TWhileLoop') then
    VisitWhileLoop(TWhileLoop(ANode));
end;

function TInterpreter.VisitUnaryOp(ANode: TUnaryOp):TFloatInstance;
var
  AOper:string;
  Ret: TFloatInstance;
begin
  try
    Ret := TFloatinstance(Visit(ANode.PExpr));
    AOper := ANode.POper.PType;
		if AOper = T_PLUS then
		  Ret.PValue := Ret.PValue
		else if AOper = T_MINUS then
		begin
		  Ret.PValue := Ret.PValue * (-1);
		end;
    Result := ret;
  except
    raise ERunTimeError.Create('Invalid operation for class ' + Ret.ClassName);
	end;
end;

function TInterpreter.VisitUnaryOp(ANode: TUnaryOp):TIntegerInstance;
var
  AOper:string;
  Ret: TIntegerInstance;
begin
  try
    Ret := TIntegerinstance(Visit(ANode.PExpr));
    AOper := ANode.POper.PType;
		if AOper = T_PLUS then
		  Ret.PValue := Ret.PValue
		else if AOper = T_MINUS then
		begin
		  Ret.PValue := Ret.PValue * (-1);
		end;
    Result := ret;
  except
    raise ERunTimeError.Create('Invalid operation for class ' + Ret.ClassName);
	end;
end;

function TInterpreter.VisitUnaryLogicOp(ANode: TUnaryLogicOp):TBooleanInstance;
var
  AOper:string;
  AuxExt:boolean;
  ARes: TBooleanInstance;
begin
  try
    ARes := TBooleanInstance(Visit(ANode.PExpr));
    ARes.PValue := not ARes.PValue;
    Result := ARes;

	except
    raise ERunTimeError.Create('Invalid operation for class '+ARes.ClassName);
	end;
end;

function TInterpreter.VisitBinLogicOp(ANode: TBinLogicOp): TBooleanInstance;
var
  LeftExt, RightExt:Extended;
  LeftInt, RightInt:integer;
  LeftBool, RightBool:boolean;
  LeftStr, RightStr: string;
  LeftClass, RightClass: string;
  AResl, AResR: TInstanceOf;
  Cmp: boolean;

begin
  try
    AResL := Visit(Anode.PLeft);
    AResR := Visit(Anode.PRight);
    LeftClass := AResL.ClassName;
    RightClass := AResR.ClassName;
    if LeftClass = RightClass then
    begin
      if LeftClass = 'TBooleanInstance' then
      begin
        LeftBool := TBooleanInstance(AResL).PValue;
        RightBool := TBooleanInstance(AResR).PValue;
        if (ANode.POper.PType = T_GT) then
          Cmp := LeftBool > RightBool
        else if (ANode.POper.PType = T_LT) then
          Cmp := LeftBool < RightBool
        else if (ANode.POper.PType = T_EQ) then
          Cmp := LeftBool = RightBool
        else if (ANode.POper.PType = T_LEQ) then
          Cmp := LeftBool <= RightBool
        else if (ANode.POper.PType = T_GEQ) then
          Cmp := LeftBool >= RightBool
        else if (ANode.POper.PType = T_NEQ) then
          Cmp := LeftBool <> RightBool
        else if (ANode.POper.PType = T_AND) then
          Cmp := LeftBool and RightBool
        else if (ANode.POper.PType = T_OR) then
          Cmp := LeftBool or RightBool;
        Result := TBooleanInstance.Create(Cmp);
        exit;
      end
      else if LeftClass = 'TStringInstance' then
      begin
        LeftStr := TStringInstance(AResL).PValue;
        RightStr := TStringInstance(AResR).PValue;
        if (ANode.POper.PType = T_GT) then
          Cmp := LeftStr > RightStr
        else if (ANode.POper.PType = T_LT) then
          Cmp := LeftStr < RightStr
        else if (ANode.POper.PType = T_EQ) then
          Cmp := LeftStr = RightStr
        else if (ANode.POper.PType = T_LEQ) then
          Cmp := LeftStr <= RightStr
        else if (ANode.POper.PType = T_GEQ) then
          Cmp := LeftStr >= RightStr
        else if (ANode.POper.PType = T_NEQ) then
          Cmp := LeftStr <> RightStr
        else
          raise ERunTimeError.Create('Logic operation '+ANode.POper.PType+' forbidden for type '+LeftClass);
        Result := TBooleanInstance.Create(Cmp);
        exit;
      end
      else if LeftClass = 'TIntegerInstance' then
      begin
        LeftInt := TIntegerInstance(AresL).PValue;
        RightInt := TIntegerInstance(AResR).PValue;
        if (ANode.POper.PType = T_GT) then
          Cmp := LeftInt > RightInt
        else if (ANode.POper.PType = T_LT) then
          Cmp := LeftInt < RightInt
        else if (ANode.POper.PType = T_EQ) then
          Cmp := LeftInt = RightInt
        else if (ANode.POper.PType = T_LEQ) then
          Cmp := LeftInt <= RightInt
        else if (ANode.POper.PType = T_GEQ) then
          Cmp := LeftInt >= RightInt
        else if (ANode.POper.PType = T_NEQ) then
          Cmp := LeftInt <> RightInt
        else if (ANode.POper.PType = T_AND) then
          Cmp := (LeftInt > 0) and (RightInt > 0)
        else if (ANode.POper.PType = T_OR) then
          Cmp := (LeftInt > 0) and (RightInt > 0);
        Result := TBooleanInstance.Create(Cmp);
        exit;
      end
      else if LeftClass = 'TFloatInstance' then
      begin
        LeftExt := TFloatInstance(AresL).PValue;
        RightExt := TFloatInstance(AResR).PValue;
        if (ANode.POper.PType = T_GT) then
          Cmp := LeftExt > RightExt
        else if (ANode.POper.PType = T_LT) then
          Cmp := LeftExt < RightExt
        else if (ANode.POper.PType = T_EQ) then
          Cmp := LeftExt = RightExt
        else if (ANode.POper.PType = T_LEQ) then
          Cmp := LeftExt <= RightExt
        else if (ANode.POper.PType = T_GEQ) then
          Cmp := LeftExt >= RightExt
        else if (ANode.POper.PType = T_NEQ) then
          Cmp := LeftExt <> RightExt
        else if (ANode.POper.PType = T_AND) then
          Cmp := (LeftExt > 0) and (RightExt > 0)
        else if (ANode.POper.PType = T_OR) then
          Cmp := (LeftExt > 0) and (RightExt > 0);
        Result := TBooleanInstance.Create(Cmp);
        exit;
      end
      else
        raise ERunTimeError.Create('Can''t compare instances of type '+LeftClass);
		end
    else
      raise ERunTimeError.Create('Can''t compare different types '+LeftClass+' and '+RightClass+' implicitly.');
		{if (ANode.POper.PType = T_GT) then
      Result := LeftRes > RightRes
    else if (ANode.POper.PType = T_LT) then
      Result := LeftRes < RightRes
    else if (ANode.POper.PType = T_EQ) then
      Result := LeftRes = RightRes
    else if (ANode.POper.PType = T_LEQ) then
      Result := LeftRes <= RightRes
    else if (ANode.POper.PType = T_GEQ) then
      Result := LeftRes >= RightRes
    else if (ANode.POper.PType = T_NEQ) then
      Result := LeftRes <> RightRes
    else if (ANode.POper.PType = T_AND) then
      Result := LeftBool and RightBool
    else if (ANode.POper.PType = T_OR) then
      Result := LeftBool or RightBool;}
  except
	end;



  {if ANode.PLeft.ClassNameIs('TNum') then
    LeftRes := VisitNum(TNum(ANode.PLeft))
  else if ANode.PLeft.ClassNameIs('TUnaryOp') then
    LeftRes := VisitUnaryOp(TUnaryOp(ANode.PLeft))
  else if ANode.PLeft.ClassNameIs('TBinOp') then
    LeftRes := VisitBinOp(TBinOp(ANode.PLeft))
  else if ANode.PLeft.ClassNameIs('TBinLogicOp') then
  begin
    AuxBool := VisitBinLogicOp(TBinLogicOp(ANode.PLeft));
    if AuxBool then
      LeftRes := 1
    else
      LeftRes := 0;
  end
  else if ANode.PLeft.ClassNameIs('TUnaryLogicOp') then
  begin
    AuxBool := VisitUnaryLogicOp(TUnaryLogicOp(ANode.PLeft));
    if AuxBool then
      LeftRes := 1
    else
      LeftRes := 0;
  end;

  if ANode.PRight.ClassNameIs('TNum') then
    RightRes := VisitNum(TNum(ANode.PRight))
  else if ANode.PRight.ClassNameIs('TUnaryOp') then
    RightRes := VisitUnaryOp(TUnaryOp(ANode.PRight))
  else if ANode.PRight.ClassNameIs('TBinOp') then
    RightRes := VisitBinOp(TBinOp(ANode.PRight))
  else if ANode.PRight.ClassNameIs('TBinLogicOp') then
  begin
    AuxBool := VisitBinLogicOp(TBinLogicOp(ANode.PRight));
    if AuxBool then
      RightRes := 1
    else
      RightRes := 0;
  end
  else if ANode.PRight.ClassNameIs('TUnaryLogicOp') then
  begin
    AuxBool := VisitUnaryLogicOp(TUnaryLogicOp(ANode.PRight));
    if AuxBool then
      RightRes := 1
    else
      RightRes := 0;
  end;

  LeftBool := LeftRes > 0;
  RightBool := RightRes > 0;

  }


  {if (ANode.POper.PType = T_GT) then
    Result := LeftRes > RightRes
  else if (ANode.POper.PType = T_LT) then
    Result := LeftRes < RightRes
  else if (ANode.POper.PType = T_EQ) then
    Result := LeftRes = RightRes
  else if (ANode.POper.PType = T_LEQ) then
    Result := LeftRes <= RightRes
  else if (ANode.POper.PType = T_GEQ) then
    Result := LeftRes >= RightRes
  else if (ANode.POper.PType = T_NEQ) then
    Result := LeftRes <> RightRes
  else if (ANode.POper.PType = T_AND) then
    Result := LeftBool and RightBool
  else if (ANode.POper.PType = T_OR) then
    Result := LeftBool or RightBool;  }
end;

function TInterpreter.VisitBinOp(ANode:TBinOp): TInstanceOf;
var
  LeftExt, RightExt, ResExt:Extended;
  LeftInt, RightInt:integer;
  LeftBool, RightBool, Leftnum, RightNum:boolean;
  LeftStr, RightStr: string;
  LeftClass, RightClass: string;
  AResl, AResR: TInstanceOf;
  StrRes:string;
  Numeric, StrOper, Mismatch: boolean;

begin
  LeftStr := ANode.PLeft.PToken.PType;
  {if LeftStr = T_ID then
    AResL := VisitVariableReference(TVariableReference(ANode.PLeft))
  else
    }AResL := Visit(Anode.PLeft);
  RightStr := ANode.PRight.PToken.PType;
  {if RightStr = T_ID then
    AResR := VisitVariableReference(TVariableReference(ANode.PRight))
  else
    }AResR := Visit(Anode.PRight);
  LeftClass := AResL.ClassName;
  RightClass := AresR.ClassName;
  LeftNum := (LeftClass = 'TIntegerInstance') or (LeftClass = 'TFloatInstance');
  RightNum := (RightClass = 'TIntegerInstance') or (RightClass = 'TFloatInstance');
  Numeric := LeftNum and RightNum;
  StrOper := (LeftClass = 'TStringInstance') and (RightClass = 'TStringInstance');
  Mismatch := ((LeftClass = 'TStringInstance') and (RightClass <> 'TStringInstance')) and
              ((LeftClass <> 'TStringInstance') and (RightClass = 'TStringInstance'));
  if StrOper then
  begin
    if (ANode.POper.PType = T_PLUS) then
    begin
      StrRes := TStringInstance(AResL).PValue + TStringInstance(AResR).PValue;
      Result := TStringInstance.Create(Strres);
		end
		else
      raise ERunTimeError.Create('Invalid operation '+Anode.POper.PType+' between strings');
	end
  else if Numeric then
  begin
    if AResl.ClassNameIs('TIntegerInstance') then
      LeftExt := TIntegerInstance(AresL).PValue
    else
      LeftExt := TFloatInstance(AResL).PValue;
    if AResR.ClassNameIs('TIntegerInstance') then
      RightExt := TIntegerInstance(AresR).PValue
    else
      RightExt := TFloatInstance(AResR).PValue;


    if (ANode.POper.PType = T_PLUS) then
      ResExt := LeftExt + RightExt
		else if (ANode.POper.PType = T_MINUS) then
      ResExt := LeftExt - RightExt
    else if (ANode.POper.PType = T_MULT) then
      ResExt := LeftExt * RightExt
    else if (ANode.POper.PType = T_INT_DIV) then
      ResExt := Floor(LeftExt / RightExt)
    else if (ANode.POper.PType = T_MODULUS) then
      ResExt := Floor(LeftExt) mod Floor(RightExt)
    else if (ANode.POper.PType = T_DIV) then
      ResExt := LeftExt / RightExt;
    if Floor(ResExt) = ResExt then
      Result := TIntegerInstance.Create(Floor(ResExt))
    else
      Result := TFloatInstance.Create(ResExt);
	end
  else if LeftClass = RightClass then
    raise ERunTimeError.Create('Invalid operation '+ ANode.POper.ptype + ' for type ' + LeftClass)
	else
    raise ERunTimeError.Create('Can''t perform opertions between different types '+LeftClass+' and '+RightClass+' implicitly.');



  {if ANode.PLeft.ClassNameIs('TNum') then
    LeftRes := VisitNum(TNum(ANode.PLeft))
  else if ANode.PLeft.ClassNameIs('TUnaryOp') then
    LeftRes := VisitUnaryOp(TUnaryOp(ANode.PLeft))
  else if ANode.PLeft.ClassNameIs('TBinOp') then
    LeftRes := VisitBinOp(TBinOp(ANode.PLeft))
  else if ANode.PLeft.ClassNameIs('TBinLogicOp') then
  begin
    AuxBool := VisitBinLogicOp(TBinLogicOp(ANode.PLeft));
    if AuxBool then
      LeftRes := 1
    else
      LeftRes := 0;
  end;

  if ANode.PRight.ClassNameIs('TNum') then
    RightRes := VisitNum(TNum(ANode.PRight))
  else if ANode.PRight.ClassNameIs('TUnaryOp') then
    RightRes := VisitUnaryOp(TUnaryOp(ANode.PRight))
  else if ANode.PRight.ClassNameIs('TBinOp') then
    RightRes := VisitBinOp(TBinOp(ANode.PRight))
  else if ANode.PRight.ClassNameIs('TBinLogicOp') then
  begin
    AuxBool := VisitBinLogicOp(TBinLogicOp(ANode.PRight));
    if AuxBool then
      RightRes := 1
    else
      RightRes := 0;
  end;

  if (ANode.POper.PType = T_PLUS) then
    Result := LeftRes + RightRes
  else if (ANode.POper.PType = T_MINUS) then
    Result := LeftRes - RightRes
  else if (ANode.POper.PType = T_MULT) then
    Result := LeftRes * RightRes
  else if (ANode.POper.PType = T_INT_DIV) then
    Result := Floor(LeftRes / RightRes)
  else if (ANode.POper.PType = T_MODULUS) then
    Result := Floor(LeftRes) mod Floor(RightRes)
  else if (ANode.POper.PType = T_DIV) then
    Result := LeftRes / RightRes; }
end;

function TInterpreter.VisitNumFloat(ANode:TNumFloat):TFloatInstance;
begin

  Result := TFloatInstance.Create(ANode.PValue.ToExtended);
end;

function TInterpreter.VisitNull(ANode:TNull):TNullInstance;
begin

  Result := TNullInstance.Create;
end;

function TInterpreter.VisitNumInt(ANode:TNumInt):TIntegerInstance;
begin

  Result := TIntegerInstance.Create(ANode.PValue.ToInteger);
end;

function TInterpreter.VisitString(ANode:TString):TStringInstance;
begin

  Result := TStringInstance.Create(ANode.PValue);
end;



function Tinterpreter.VisitBoolean(ANode:TBoolean):TBooleanInstance;
begin
  if (ANode.PValue = T_LANG_TRUE) then
    Result := TBooleanInstance.Create(True)
  else if (ANode.PValue = T_LANG_FALSE) then
    Result := TBooleanInstance.Create(False);

end;

end.

