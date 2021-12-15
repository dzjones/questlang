# Questlang

Questlang is a simple language for specifying and verifying Quest descriptions. It was based off of http://ianparberry.com/pubs/pcg2011.pdf and a desire to do something a little different for a Programming Languages and Compilers course project.
The tool will take as input a file written in Questlang that specifies possible locations in your world, possible items that the player character can collect at each location and NPCs that the player character can interact with at each location.
It will also specify a quest that is to be validated in order to confirm if it can be completed in the world described previously.
The quest is composed of basic actions such as `kill` and `goto`, and for instance, the quest will be shown invalid if the player character tries to `kill` a monster that's not at his location.
For a description of all basic actions see the `Actions` section below.

## Dependencies

`ocamlyacc`, `ocamllex`, `ocamlopt`

## Usage

To use this tool:
1. Run `make`
2. (optional) Run `make test` to run the unit and integration tests
3. Run `./questlang my-quest.ql` to validate a quest written in questlang, stored in `my-quest.ql`

See `quest-example.ql` for a sample questlang file.

To clean up the project directory run `make clean`

## Actions
* `goto` - Changes the player's current location
* `get` - Tries to collect an item and add it to the player's inventory if it is at the player's location
* `kill` - Kills a monster if it is at the player's location
* `use` - Uses up one of the player's held items
* `require` - Checks if a certain predicate about the world is true


Please report any issues with this tool on it's GitHub page: https://github.com/dzjones/questlang/issues
