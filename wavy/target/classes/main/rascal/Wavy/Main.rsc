module Wavy::Main

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
import Wavy::TypeChecker;

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
    cst = parseWavy(|project://wavy/tests/chords.wavy|);
    ast = loadWavy(cst);

    env = emptyEnv();
    env = checkProgram(env, ast);
    println(env);

    if (size(env.errors) > 0) {
        for (err <- env.errors) {
            println(err);
        }

        throw "Program contains static semantic errors";
    }

    /*
    compile(ast);
    */
}