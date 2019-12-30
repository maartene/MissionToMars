![Swift 5.1](http://img.shields.io/badge/swift-5.1-orange.svg) 
![Vapor v3.3](https://img.shields.io/badge/vapor-3.3-blue) [![CircleCI](https://circleci.com/gh/maartene/MissionToMars.svg?style=shield)](https://circleci.com/gh/maartene/MissionToMars) ![MIT License](http://img.shields.io/badge/license-MIT-brightgreen.svg) 

# Mission To Mars
Getting to Mars is hard. Very hard. This game aims to become a "hard-scifi" simulation of the challenges to get to Mars.
* It will require teamwork, as it's not feasible to go there alone;
* It's business only, the assumption being that in the end it requires the will and the funds to get there more than anything else;
* Whether you spend your funds on improving technology, supporting other players, building improvements is up to you.

## Playable version online
You can play a playable build of version 0.0.3 on https://mission2mars.space 

## Features
### Whats available
* In the current state, this "game" is only a model with very little simulation;
* Persistent step-based simulation (where for instance a real-world hour translates to a day in game time);
* Model is database-backed (currently: SQLite);
* There is a simple Leaf based UI: completely server-side rendered, no JS/AJAX whatsoever;
* Mission stages and components;
* Stubs for income and research.

### What's still to come
* Incorporate flight time;
* Build improvements to get more cash per day, more value from research, improved production and the possibility to build mission parts;
* User management and authentication (for now, using the randomly generated UUID for a Player will be enough).

### What won't be here
* forums, messaging, chat: I assume you bring your own.

## Architecture - model
This game is built on the Vapor Server-side Swift framework.
The actual simulation/model is in the `Sources/Model` folder. To reference it's types, use `import Model`
Currently the model contains two types:
1. A `Player` struct
2. A `Mission` struct (Mission has sub-structures for `Stages` and ``Components`, but these are not database aware, just plain strucs.)
3. A `Simulation` struct

### Structure
The structures contain two parts:
* A "pure struct" (`internal`) part;
* A database/persistance (`public`) aware part.
The database/persistance functions can be recognised by the `conn: DatabaseConnectable` attribute and return a `Future`.

#### Example:
```
// from Player.swift:
public func getSupportedMission(on conn: DatabaseConnectable) throws -> Future<Mission?>
```
This allows to get the supported mission for a player (if one exists)
* this requires an associated mission (i.e. `ownsMissionID` cannot be `nil` and a `Mission` with this ID needs to exist in the database.). The function throws an error if this condition is not met;
* the function returns a Future with an optional Mission. If a mission exists, it is returned, `nil` otherwise.

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

### Simulation.swift
The `Simulation` struct only contains meta data about the Simulation: when it should update (in real time), how often it was updates and the "game date": a fictional date representing in game time. 

It also contains an updateSimulation function that takes care of updating data elements in the game. This function performs enough updates to compensate for the actual time that passed since the last simulation update, the current time and the length of a simulation "tick". Note that other data elements are passed as parameters to the function, they are not members of the Simulation itself.

```
 public func updateSimulation(currentDate: Date, players: [Player], missions: [Mission]) -> (updatedSimulation: Simulation, updatedPlayers: [Player], updatedMissions: [Mission])
```

There should only be one simulation in the database at any time. To prevent unnecessary database lookups, the simulation ID (as it is known in the database) is cashed as a global variable: `Simulation.GLOBAL_SIMULATION_ID`.

## Architecture - UI
The UI is Leaf based. The most important Leaf view is `main.leaf` (called from `\main`). This shows the game dashboard, but also performs the following tasks:
1. Calling `/main` checks  whether enough real time has passed to update the simulation;
2. If the simulation needs to update, all players and missions are also updated;
3. It checks whether the mission for the current player (either owning or supporting) is complete. If so, the "Win screen" is shown;
4. There is an `errorMessages` dictionary ([UUID: String?]), you can use to show an error message to players. See `donate/to/supportedPlayer` route in `routes.swift` for an exmaple.

## Debug features
The game provides some debug features:
* There a routes specifically intented for debug functionality. These need to be deleted for production work (or otherwise disabled);
* The main debug solution is lowering the time between ticks (i.e. to less than a second) to get through the game quicker;
* Off course, the regular xcode debug features can be used.

## Contact details
Need to contact me? Drop an email at maarten@thedreamweb.eu or twitter at [@maarten_engels](https://twitter.com/maarten_engels)

## Licensed assets & embedded media
* [Solar theme](https://bootswatch.com/solar/) by [Thomas Park](https://thomaspark.co/)
* Icons for components, stages, technologies, company and improvements are from the [Free Icons from Streamline Icons pack](https://www.streamlineicons.com/).
* Paul Hudson's "vapor-clean" template is the basis of this product. You can find it here. https://github.com/twostraws/vapor-clean . Also, his book was/is invuluable if you want to take Vapor development further: https://www.hackingwithswift.com/store/server-side-swift  
* Favicon is based on a Mars image from NASA. Apart from being a very esthetically pleasing image, it also shows Gale Crater: a possible Mars landing site. Original file:  https://www.nasa.gov/mission_pages/msl/multimedia/pia14293-amended.html 
