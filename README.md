TODO: Explain what the tool actually does

To use this tool:
1. Create a new OCaml (`.ml`) file in this directory (e.g. `my_file.ml`)
2. At the beginning of the file add the 2 lines:
```
open Abstract_syntax_tree;;
open Semantics;;
```
3. Build an AST in OCaml (an object of type `_AST`) in your file (e.g. `let ast1 : _AST = ...`)
4. To run the quests associated to those ASTs, call `printEvalAST` on each of them (e.g. `printEvalAST ast1;;`)
5. To actually run the quests in your file, run `make my_file.q && ./my_file.q`
6. The above command will compile the whole project and print to standard output a line describing what whent wrong or a success message if nothing went wrong.

You can find an example of what this file should look like in `example.ml`
To run the example, run `make example.q && ./example.q`

To clean up the project directory run `make clean`

Please report and issues with this tool on it's GitHub page: https://github.com/dzjones/questlang/issues