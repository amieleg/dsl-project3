module Wavy::TypeChecker

import IO;
import String;
import ParseTree;
import List;

import util::LanguageServer;
import util::IDEServices;
import util::Reflective;

import Wavy::Syntax;
import Wavy::Parser;
import Wavy::CST2AST;
import Wavy::AST;
import Wavy::Compile;


data Type = number() | func();

alias TENV = tuple[
    map[str, Type] symbols,
    list[str] errors
];

TENV emptyEnv() {
    return <(), []>;
}

str type2str(Type t) {
    switch (t) {
        case number(): return "number";
        case func(): return "func";
    }

    throw "type2str: Switch case is not exhaustive";
}


TENV addError(TENV env, str msg) = env[errors = env.errors + msg];

TENV checkBinaryOp(ExpressionAST lhs, ExpressionAST rhs, TENV env) {
    env = checkExpr(lhs, number(), env);
    env = checkExpr(rhs, number(), env);

    return env;
}

bool hasReturnExpression(list[StatementAST] block) {
    n_stats = size(block);
    last_idx = n_stats - 1;

    switch (block[last_idx]) {
        case \expression(_): true;
        case \if(cond, body): hasReturnExpression(body);
        case \ifelse(cond, true_body, false_body): hasReturnExpression(true_body) && hasReturnExpression(false_body);
    }

    return false;
}

TENV checkProgram(TENV env, WavyAST ast) {
    for (stat <- ast.program) {
        env = checkStat(stat, env);
    }

    return env;
}

TENV checkStat(StatementAST s, TENV env) {
    switch (s) {
        case \declaration(id, expr): {
            env = checkExpr(expr, number(), env);
            env.symbols[id] = number();

            return env;
        }
        case \functionDeclaration(id, _, body): {
            env.symbols[id] = func();

            for (stat <- body) {
                env = checkStat(stat, env);
            }

            // Check if the last statement of the block is an expression (return value)
            return hasReturnExpression(body)
                ? env
                : addError(env, "The body is missing a final expression statement to use as return value");
        }
        case \expression(expr): checkExpr(expr, number(), env); 
        case \while(cond, body): {
            env = checkExpr(cond, number(), env);

            for (stat <- body) {
                env = checkStat(stat, env);
            }

            return env;
        }
        case \if(cond, body): {
            env = checkExpr(cond, number(), env);

            for (stat <- body) {
                env = checkStat(stat, env);
            }

            return env;
        }
        case \ifelse(cond, true_body, false_body): {
            env = checkExpr(cond, number(), env);

            for (stat <- true_body) {
                env = checkStat(stat, env);
            }
            for (stat <- false_body) {
                env = checkStat(stat, env);
            }

            return env;
        }
        case \output(e, n): checkExpr(e, func(), env);
    }

    return env;
}

TENV checkExpr(ExpressionAST e, Type expected, TENV env) {
    switch (e) {
        case \number(_):
            expected == number() ? env : addError(env, "Expected number");
        case \addition(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \subtraction(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \multiplication(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \division(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \power(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \less(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \lesseq(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \greater(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \greatereq(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \equal(lhs, rhs): expected == number() ? checkBinaryOp(lhs, rhs, env) : addError(env, "Unexpected number");
        case \brackets(expr): checkExpr(expr, expected, env);
        case \number(_): expected == number() ? env : addError(env, "Unexpected number");
        case \var(id): {
            if (expected != number()) {
                return addError(env, "Expected " + type2str(expected) + ", but got number");
            }

            if (!(id in env.symbols)) {
                return addError(env, "Variable usage before declaration");
            }

            if (expected != env.symbols[id]) {
                return addError(env, "Expected " + type2str(expected) + ", but got " + type2str(env.symbols[id]));
            }

            return env;
        }
        case \call(id, args): {
            if (!(id in env.symbols)) {
                return addError(env, "Function usage before declaration");
            }

            for (arg <- args) {
                env = checkExpr(arg, number(), env);
            }

            return env;
        }
    }

    return env;
}