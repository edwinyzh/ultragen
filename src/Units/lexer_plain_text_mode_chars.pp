if (FCurrChar = ' ') and FInterpol then
begin
  SkipSpace;
  continue;
end;

if (FCurrChar + Peek(1)) = '{{' then
begin
    FInterpol := True;
    FScriptMode := True;
    Advance;
    Advance;
    Result := TToken.Create(T_INTERPOLATION_START, '{{', FScriptLine, FLineChar, FFileName);
    exit
end

else if (FCurrChar = sLineBreak)  then
begin
  Advance;
  FScriptLine := FScriptLine + 1;
  FLineChar := 1;
  Result := TToken.Create(T_NEWLINE, sLineBreak, FLineChar, FScriptLine, FFileName);
  exit
end

else if (FCurrchar = '@') then
begin
  FScriptMode := True;
  FLineScript := True;
  Advance;
  Result := TToken.Create(T_LINE_SCRIPT_EMBED, '@', FScriptLine, FLineChar, FFileName);
  exit
end

else
begin
    Result := GetPlainText();
    exit
end;
