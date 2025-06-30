module Plugin

import util::Reflective;
import util::IDEServices;
import util::LanguageServer;

import Server;

/*
* This is the main function of the project. This function enables the editor's syntax highlighting.
* After calling this function from the terminal, all files with extension .sm will be parsed using the parser defined in module Parser.
* If there are syntactic errors in the program, no highlighting will be shown in the editor.
*/
int main() {
  // we register a new language to Rascal's LSP multiplexer
  // the multiplexer starts a new evaluator and loads this module and function
  registerLanguage(
    language(
      pathConfig(srcs=[|project://statemachine/src|]),
      "StateMachine",     // name of the language
      {"sm"},             // extension, e.g., example.sm
      "Server",           // module to import, this one
      "contributions"
    )
  );
  return 0;
}

void clearMyLang() {
  unregisterLanguage("StateMachine", {"sm"});
}
