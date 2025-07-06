module Wavy::CST2AST

import Wavy::AST;
import Wavy::Syntax;
import IO;
import String;

WavyAST loadWavy((start[Wavy]) `<Statement+ stats>`) {
    return \wavy([toAST(s) | s <- stats]);
}

StatementAST toAST(Statement pt) {
    switch (pt) {
        case (Statement) `<Identifier id> := <Expression e> <EOL _>`:
            return \declaration("<id>", toAST(e));
        case (Statement) `<FunctionDeclaration fd> <EOL _>`:
            return toAST(fd);
        case (Statement) `<Expression e> <EOL _>`:
            return \expression(toAST(e));
        case (Statement) `while <Expression e> do <EOL _> <Statement* stats> <EOL _> end <EOL _>`:
            return \while(toAST(e), [toAST(s) | s <- stats]);
        case (Statement) `if <Expression e> then <EOL _> <Statement* stats> end <EOL _>`:
            return \if(toAST(e), [toAST(s) | s <- stats]);
        case (Statement) `if <Expression e> then <EOL _> <Statement* stats> else <Statement* stats_else> <EOL _> end <EOL _>`:
            return \ifelse(toAST(e), [toAST(s) | s <- stats], [toAST(s) | s <- stats_else]);
        case (Statement) `output <Expression e>`:
            return \output(toAST(e));
    }

    throw "Invalid statement parsetree";
}

public StatementAST toAST((FunctionDeclaration) pt) {
    switch (pt) {
        case (FunctionDeclaration) `func <Identifier id>(<{Identifier ","}* params>) := <Expression e>`:
            return \functionDeclaration(
                "<id>",
                ["<p>" | p <- params],
                [\expression(toAST(e))]);
        case (FunctionDeclaration) `func <Identifier id>(<{Identifier ","}* params>) <EOL _> <Statement* body> end`:
            return \functionDeclaration(
                "<id>",
                ["<p>" | p <- params],
                [toAST(b) | b <- body]);
    }

    throw "Invalid functiondelcaration parsetree";
}

public ExpressionAST toAST((Expression) pt) {
    switch (pt) {
        case (Expression) `<Number n>`:
            return \number(toReal("<n>"));
        case (Expression) `<Identifier id>`:
            return \var("<id>");
        case (Expression) `<Expression lhs> + <Expression rhs>`:
            return \addition(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> - <Expression rhs>`:
            return \subtraction(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> * <Expression rhs>`:
            return \multiplication(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> / <Expression rhs>`:
            return \division(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> ^ <Expression rhs>`:
            return \power(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> \< <Expression rhs>`:
            return \less(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> \<= <Expression rhs>`:
            return \lesseq(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> \>= <Expression rhs>`:
            return \greatereq(toAST(lhs), toAST(rhs));
        case (Expression) `<Expression lhs> = <Expression rhs>`:
            return \equal(toAST(lhs), toAST(rhs));
        case (Expression) `(<Expression expr>)`:
            return \brackets(toAST(expr));
        case (Expression) `<Identifier id>( <{Expression ","}* exprs> )`:
            return \call("<id>", [toAST(e) | e <- exprs]);
    }

    println(pt);

    throw "Invalid Expression parsetree";
}