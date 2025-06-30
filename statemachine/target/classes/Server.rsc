module Server

import ParseTree;

import util::IDEServices;
import util::LanguageServer;

import Syntax;

// A minimal implementation of a DSL in rascal
// users can add support for more advanced features
// More information about language servers can be found here:
// - https://www.rascal-mpl.org/docs/Packages/RascalLsp/API/util/LanguageServer/#util-LanguageServer-Summary
// - https://www.rascal-mpl.org/docs/Packages/RascalLsp/API/demo/lang/pico/LanguageServer/#demo-lang-pico-LanguageServer-picoExecutionService
set[LanguageService] contributions() = {
  parsing(parser(#start[Machine]), usesSpecialCaseHighlighting = false),
  documentSymbol(stateMachineOutliner),
  analysis(summaryService, providesDocumentation = false, providesImplementations = false)
};

list[DocumentSymbol] stateMachineOutliner(start[Machine] input) {
  // Go through all the states in the program and create a symbol in the outline menu for them.
  // We use the list compression syntax to make this expression more concise.
  list[DocumentSymbol] states = [symbol("<state.name>", \object(), state.src, children=[
      *[symbol("<trans.event> -\> <trans.to>", DocumentSymbolKind::\function(), trans.src) | /Trans trans := state]
  ]) | /State state := input];

  // At the top-level, we have our file that we decided to always name "StateMachine"
  return [symbol("StateMachine", DocumentSymbolKind::\file(), input.src, children=states)];
}

// More info about locations can be found here:
// - https://www.rascal-mpl.org/docs/Packages/Typepal/API/analysis/typepal/GetLoc/#analysis-typepal-GetLoc-getLastLoc
loc lastStateLoc(start[Machine] input) {
  list[loc] stateLocs = [state.src | /State state := input];
  return size(stateLocs) > 0 ? last(stateLocs) : input.src;
}

list[CodeAction] prepareNotDefinedFixes(str name, loc src, rel[str, loc] defs, start[Machine] input)
  = [action(title="Create state <name>", edits=[
      changed(src.top, [
        insertAfter(lastStateLoc(input), "\n\nstate <name>\n")
      ])
    ])] +
    [action(title="Change to <existing<0>>", edits=[
      changed(src.top, [
        replace(src, existing<0>)
      ])
    ]) | existing <- defs];

Summary summaryService(loc l, start[Machine] input) {
  Summary s = summary(l);

  // Find the state definitions
  rel[str, loc] defs = {<"<state.name>", state.src> | /State state := input};

  // Find the usage of said states in the transitions
  rel[loc, str] uses = {<trans.to.src, "<trans.to>"> | /Trans trans := input};

  // Provide error messages
  s.messages += {<src, error("State \"<id>\" is not defined", src, fixes=prepareNotDefinedFixes(id, src, defs, input))>
                | <src, id> <- uses, id notin defs<0>};

  // "references" are links for loc to loc (from def to use)
  s.references += (uses o defs)<1,0>;

  // "definitions" are also links from loc to loc (from use to def)
  s.definitions += uses o defs;

  return s;
}
