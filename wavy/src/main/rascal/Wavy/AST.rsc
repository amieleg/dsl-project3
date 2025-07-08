module Wavy::AST

data WavyAST = \wavy(list[StatementAST] program);

data StatementAST
    = \declaration(str id, ExpressionAST expr)
    | \functionDeclaration(str id, list[str] parameters, list[StatementAST] body)
    | \expression(ExpressionAST expr)
    | \while(ExpressionAST condition, list[StatementAST] body)
    | \if(ExpressionAST condition, list[StatementAST] body)
    | \ifelse(ExpressionAST condition, list[StatementAST] true_body, list[StatementAST] false_body)
    | \output(ExpressionAST result, num duration)
    ;

data ExpressionAST
    = \addition(ExpressionAST lhs, ExpressionAST rhs)
    | \subtraction(ExpressionAST lhs, ExpressionAST rhs)
    | \multiplication(ExpressionAST lhs, ExpressionAST rhs)
    | \division(ExpressionAST lhs, ExpressionAST rhs)
    | \power(ExpressionAST lhs, ExpressionAST rhs)
    | \less(ExpressionAST lhs, ExpressionAST rhs)
    | \lesseq(ExpressionAST lhs, ExpressionAST rhs)
    | \greater(ExpressionAST lhs, ExpressionAST rhs)
    | \greatereq(ExpressionAST lhs, ExpressionAST rhs)
    | \equal(ExpressionAST lhs, ExpressionAST rhs)
    | \brackets(ExpressionAST expr)
    | \var(str id)
    | \number(num val)
    | \call(str func, list[ExpressionAST] arguments)
    ;