module Wavy::Parser

import IO;
import ParseTree;
import Wavy::Syntax;

start[Wavy] parseStr(str string) {
    return parse(#start[Wavy], string);
}

start[Wavy] parseWavy(loc filepath) {
    return parse(#start[Wavy], readFile(filepath));
}