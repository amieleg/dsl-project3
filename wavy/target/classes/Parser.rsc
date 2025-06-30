module Parser

import ParseTree;
import Syntax;

start[Machine] parse(loc l) = parse(#start[Machine], l);

// For debug purposes
start[Machine] parse(str txt) = parse(#start[Machine], txt);
