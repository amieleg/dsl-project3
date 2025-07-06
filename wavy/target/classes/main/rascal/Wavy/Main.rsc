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

    println(x);
}

bool validAST(WavyAST ast) {
    // Check if ast contains an output statement
    // Check if each variable is defined before it is used (except for variable t in the output statement)
    // Check if each function is defined before it is used (except the built-in functions)
    return false;
}