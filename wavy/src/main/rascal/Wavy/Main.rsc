module Wavy::Main

import IO;
import String;
import ParseTree;

import util::LanguageServer;
import util::IDEServices;
import util::Reflective;

import Wavy::Syntax;
import Wavy::Parser;
import Wavy::CST2AST;
import Wavy::AST;
import Wavy::Compile;

int main() {
    registerLanguage(language(
        pathConfig(srcs=[|project://wavy/src/main/rascal|]),
        "Wavy",
        {"wavy"},
        "Wavy::Server",
        "contributions"
    ));

    return 0;
}

void clearWavy() {
    unregisterLanguage("Wavy", {"wavy"});
}

void run() {
    x = parseWavy(|project://wavy/tests/chords.wavy|);
    ast = loadWavy(x);
    compile(ast);
}

/* Static semantic rules */

data Type = number();

alias TENV = tuple[
    map[str, Type] symbols,
    list[str] errors
];

TENV addError(TENV env, str msg) = env[errors = env.errors + msg];

TENV checkExpr(ExpressionAST e, Type expected, TENV env) {
    switch (e){
        case \number(_):
            expected == number() ? env : addError(env, "Expected number");
    }

    return env;
}

bool validAST(WavyAST ast) {
    // Check if ast contains an output statement
    // Check if each variable is defined before it is used (except for variable t in the output statement)
    // Check if each function is defined before it is used (except the built-in functions)
    return false;
}