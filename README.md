![Swift 5.1](http://img.shields.io/badge/swift-5.1-orange.svg) https://img.shields.io/circleci/build/github/maartene/MissionToMars ![MIT License](http://img.shields.io/badge/license-MIT-brightgreen.svg) 

# Mission To Mars
Getting to Mars is hard. Very hard. This game aims to become a "hard-scifi" simulation of the challenges to get to Mars.
* It will require teamwork, as it's not feasible to go there alone;
* It's business only, the assumption being that in the end it requires the will and the funds to get there more than anything else;
* Whether you spend your funds on improving technology, supporting other players, building improvements is up to you.

## Features
### Whats available
* In the current state, this "game" is only a model with very little simulation;
* Model is database-backed (currently: SQLite);
* There is no UI/(restful)API yet. All functionality is validated using automated tests;
* Stubs for income and research, mission progress and technology (currently just values).

### What's still to come
* Actual simulation of building a mission (i.e. work on components);
* Persistent step-based simulation (where for instance a real-world hour translates to a day in game time);
* Build improvements to get more cash per day, more value from research, improved production and the possibility to build mission parts;
* User management and authentication (for now, using the randomly generated UUID for a Player will be enough);
* Web based UI.

### What won't be here
* forums, messaging, chat: I assume you bring your own.

## Architecture - model
This game is built on the Vapor Server-side Swift framework.
The actual simulation/model is in the `Sources/Model` folder. To reference it's types, use `import Model`
Currently the model contains two types:
1. A `Player` struct
2. A `Mission` struct

### Structure
The structures contain two parts:
A "pure struct" (`internal`) part;
A database/persistance (`public`) aware part.
The database/persistance functions can be recognised by the `conn: DatabaseConnectable` attribute and return a `Future`.

#### Example:
```
public func investInMission(amount: Double, on conn: DatabaseConnectable) throws -> Future<(changedPlayer: Player, changedMission: Mission)>
```
This allows a player to invest in a mission. Note:
* this requires an associated mission (i.e. `ownsMissionID` cannot be `nil` and a `Mission` with this ID needs to exist in the database.). The function throws an error if this condition is not met;
* the function returns a tuple with the changed player and changed mission. It does not mutate the player and mission directly.

### Usage
These structs do not contain any mutable functions. All functions that should change the state of the game return a copy of the struct (including any others that might be changed) with the changes applied. 
It is your responsibility to take this result, use it and if necesarry persist it.

An example:
```
// assume we have a player "player" and a database connection from a request "req": 
// this player performs an action:
let changedPlayer = try player.investInNextLevelOfTechnology()
// persist changed state due to the action performed
let savedPlayer = try changedPlayer.save(on: req)
```

## Contact details
Need to contact me? Drop an email at maarten@thedreamweb.eu or twitter at [@maarten_engels](https://twitter.com/maarten_engels)