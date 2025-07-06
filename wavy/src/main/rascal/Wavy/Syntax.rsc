module Wavy::Syntax

layout Whitespace = [\t\ ]*;

lexical EOL = [\r\n]+;
lexical Identifier = [A-Za-z][A-Za-z0-9#_]*;
lexical Number = "-"?[0-9]+ ("." [0-9]*)?;

start syntax Wavy = Statement+;

syntax Statement
  = loop: "while" Expression "do" EOL Statement* EOL "end" EOL
  | conditionElse: "if" Expression "then" EOL Statement* "else" Statement EOL "end" EOL
  > condition: "if" Expression "then" EOL Statement* "end" EOL
  | Declaration EOL
  | functionDeclaration: FunctionDeclaration EOL
  | Output
  > expression: Expression EOL
  ;

syntax Expression
  = Identifier "(" {Expression ","}* ")"
  | Identifier
  | Number
  | NumberList
  | Identifier "[" Expression "]"
  | bracket "(" Expression ")"
  > right Expression "^" Expression
  > left (Expression "*" Expression | Expression "/" Expression)
  > left (Expression "+" Expression | Expression "-" Expression)
  > left Expression "=" Expression 
  | left Expression "\>" Expression 
  | left Expression "\>=" Expression 
  | left Expression "\<" Expression 
  | left Expression "\<=" Expression 
  ;

syntax NumberList = "[" {Number ","}* "]";

syntax Declaration = Identifier ":=" Expression;
syntax FunctionDeclaration
  = "func" Identifier "(" {Identifier ","}* ")" (
      (":=" Expression) |
      (EOL Statement* "end")
  )
  ;
syntax Output = "output" Expression;