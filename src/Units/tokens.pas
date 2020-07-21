unit Tokens;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, TokenClass;

const
  TYPE_INTEGER = 'INTEGER';
  TYPE_FLOAT = 'FLOAT';      
  TYPE_STRING = 'STRING';
  TYPE_BOOLEAN = 'BOOLEAN';
  TYPE_NULL = 'NULL';
  TYPE_LIST = 'LIST';



  T_LANG_TRUE = 'true';
  T_LANG_FALSE = 'false';
  T_LANG_NULL = 'null';
  T_PLUS = 'T_PLUS'; T_MINUS = 'T_MINUS'; T_MULT = 'T_MULT'; T_DIV = 'T_DIV';
  T_INT_DIV = 'T_INT_DIV'; T_MODULUS = 'T_MODULUS';
  T_REF_INC = 'T_REFERENTIAL_INC'; T_REF_DEC = 'T_REFERENTIAL_DEC';
  T_GT = 'T_GREATER_THAN'; T_LT = 'T_LESS_THAN'; T_EQ = 'T_EQUAL'; T_NOT = 'T_NOT';
  T_GEQ = 'T_GREATER_OR_EQUAL'; T_LEQ = 'T_LESS_OR_EQUAL'; T_NEQ = 'T_NOT_EQUAL';
  T_AND = 'T_AND'; T_OR  = 'T_OR';

  T_IF_START = 'T_IF_START';
  T_IF_END = 'T_IF_END';
  T_ELSE = 'T_ELSE';
  T_ELSE_IF = 'T_ELSE_IF';
  T_CONTINUE = 'T_CONTINUE';
  T_BREAK = 'T_BREAK';
  T_RETURN = 'T_RETURN';
  T_WHILE_LOOP = 'While loop';
  T_FOR_LOOP = 'For Loop';

  T_LPAREN = 'T_LPAREN';
  T_RPAREN = 'T_RPAREN';
  T_ASSIGN = 'T_ASSIGN';
  T_ESCAPE = 'T_ESCAPE';
  T_DB_QT = 'T_DOUBLE_QUOTES';
  T_SG_QT = 'T_SINGLE_QUOTES';
  T_STRENC_SINGLE = '''';
  T_STRENC_DOUBLE = '"';
  T_STRENC_MULTI = '"""';
  T_LONG_STR = 'T_LONG_STRING';
  T_FUNC_PARAM = 'T_FUNC_PARAM';
  T_FUNC_DEF = 'T_FUNCTION_DEFINITION';
  T_COMMA = 'T_COMMA';
  T_END = 'block end: ';
  T_ID = 'T_ID';
  T_ATTR_ACCESSOR = 'ATTRIBUTE ACCESS';
  T_LIVE_OUTPUT = 'T_LIVE_OUTPUT';
  T_LIVE_PRINT = 'T_LIVE_PRINT';
  T_INTERPOLATION_START = 'T_INTERPOLATION_START';
  T_INTERPOLATION_END = 'T_INTERPOLATION_END';
  T_PLAIN_TEXT = 'T_PLAIN_TEXT';
  T_LINE_SCRIPT_EMBED = 'T_LINE_SCRIPT_EMBED';
  T_FROM_NAMESPACE = 'T_FROM_NAMESPACE';
  T_INCLUDE = 'T_INCLUDE';
  T_IMPORT = 'T_IMPORT';
  T_DICT_ASSIGN = 'T_DICT_ASSIGN';
  T_NEW_OBJECT = 'T_NEW_OBJECT';

  ESCAPE_SYMBOL = '\';
  ASSIGN_SYMBOL = '=';
  ATTR_ACCESSOR = '.';
  EOF = 'EOF';
  NONE = '';
  SET_NUMBERS = '0123456789';
  LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz';
  T_NEWLINE = 'T_NEWLINE';
  T_COMMENT = 'T_COMMENT';

  T_LINE_COMMENT = '#';
  T_LIST_START = 'T_LIST_START';
  T_LIST_END = 'T_LIST_END';
  T_DICT_START = 'T_DICT_START';
  T_DICT_END = 'T_DICT_END';


var
  ReservedWords: TFPHashObjectList;
  InnerAttributes: TFPHashObjectList;

implementation
begin
  ReservedWords := TFPHashObjectList.Create();
  ReservedWords.Add('function', TToken.Create(T_FUNC_DEF, 'block:function definition'));
  ReservedWords.Add('if', TToken.Create(T_IF_START, 'block:IF START'));
  ReservedWords.Add('elsif', TToken.Create(T_ELSE_IF, 'ELSE IF'));
  ReservedWords.Add('else', TToken.Create(T_ELSE, 'T_ELSE'));
  ReservedWords.Add('while', TToken.Create(T_WHILE_LOOP, 'block:'+T_WHILE_LOOP));
  ReservedWords.Add('for', TToken.Create(T_FOR_LOOP, 'block:'+T_FOR_LOOP));
  ReservedWords.Add(T_LANG_TRUE, TToken.Create(TYPE_BOOLEAN, T_LANG_TRUE));
  ReservedWords.Add(T_LANG_FALSE, TToken.Create(TYPE_BOOLEAN, T_LANG_FALSE));
  ReservedWords.Add(T_LANG_NULL, TToken.Create(TYPE_NULL, T_LANG_NULL));
  ReservedWords.Add('continue', TToken.Create(T_CONTINUE, T_CONTINUE));
  ReservedWords.Add('break', TToken.Create(T_BREAK, T_BREAK));
  ReservedWords.Add('live', TToken.Create(T_LIVE_OUTPUT, T_LIVE_OUTPUT));
  ReservedWords.Add('return', TToken.Create(T_RETURN, T_RETURN));
  ReservedWords.Add('include', TToken.Create(T_INCLUDE, T_INCLUDE));
  ReservedWords.Add('new', TToken.Create(T_NEW_OBJECT, T_NEW_OBJECT));
  ReservedWords.Add('import', TToken.Create(T_IMPORT, T_IMPORT));

  InnerAttributes := TFPHashObjectList.Create();
  InnerAttributes.Add('LIVE', TToken.Create(T_LIVE_PRINT, T_LIVE_PRINT));


end.

