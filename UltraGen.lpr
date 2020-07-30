program UltraGen;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,{$ENDIF}
  Classes, SysUtils,
  { you can add units after this }
  ASTClass, LexerClass, ImpParserClass, InterpreterClass,
  StrUtils, LoggingClass, UltraGenInterfaceClass;
var
  BTree: TAST;
  LiveOut: string;
  i: integer;
  ParamsNodes: TStringList;
begin
  LogLevel := '';
  {$IFDEF Windows}DecimalSeparator := '.';{$ENDIF}
  if ParamCount > 0 then
  begin
    {if ParamCount > 1 then
    begin
      if ParamStr(2) = '--debug' then
        LogLevel := DEBUG
      else if ParamStr(2) = '--inter' then
        LogLevel := INTER
      else if ParamStr(2) = '--parser' then
        LogLevel := 'PARSER';
    end;}
    if ParamCount > 1 then
    begin
      ParamsNodes := TStringList.Create;
      ParamsNodes.Add('$params = []');
      i := 2;
      while ((Copy(ParamStr(i), 1, 2) <> '--')) and
            (i <= ParamCount) do
      begin
        ParamsNodes.Add('$params.append("' + ParamStr(i) + '")');
        i := i + 1;
      end;
      ParamsNodes.Add('$params.lock()');
      BTree := TUltraInterface.ParseStringList(ParamsNodes);
      ParamsNodes.Free;
		end;
    LiveOut := TUltraInterface.InterpretScript(ParamStr(1), TProgram(BTree));
    if Trim(LiveOut) <> '' then
      Writeln(LiveOut);
    {if (ParamStr(2) = '--persist') then
    begin
      AOut := TStringList.Create;
      AOut.SkipLastLineBreak := True;
      AOut.Text := LiveOut;
      AOut.SaveToFile(ParamStr(3));
		end;}
    //ATree.Free;
  end
  else
  begin
    WriteLn('UltraGen - Desktop/Web Template engine/Scripting language');
    WriteLn('Version: 0.7');
    WriteLn('Usage: ultragen [script path] [...params] [(--...OPTIONS)]');
    WriteLn('Created by Alan Telles');
  end;
end.

