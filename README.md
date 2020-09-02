![Swift 5.2](http://img.shields.io/badge/swift-5.2-orange.svg) 
![Vapor v4.0](https://img.shields.io/badge/vapor-4.0-blue) [![CircleCI](https://circleci.com/gh/maartene/MissionToMars.svg?style=shield)](https://circleci.com/gh/maartene/MissionToMars) ![MIT License](http://img.shields.io/badge/license-MIT-brightgreen.svg) 

# Mission To Mars
Getting to Mars is hard. Very hard. This game aims to become a "hard-scifi" simulation of the challenges to get to Mars.
* It will require teamwork, as it's not feasible to go there alone;
* It's business only, the assumption being that in the end it requires the will and the funds to get there more than anything else;
* Whether you spend your funds on improving technology, supporting other players, building improvements is up to you.

## Playable version online
You can play a playable build of version 0.0.15 on https://www.mission2mars.space 

## Features
### Whats available
* In the current state, this "game" is only a model with very little simulation;
* Persistent step-based simulation (where for instance a real-world hour translates to a day in game time);
* Model is file-backed;
* There is a simple Leaf based UI: completely server-side rendered, no JS/AJAX whatsoever;
* Mission stages and components;
* Build improvements to get more cash per day, more value from research, improved production and the possibility to build mission parts
* Stub for income;
* Email integration using [MailJet](https://www.mailjet.com)
* Persistence using Digital Ocean Spaces. This is easy to change to something like AWS S3.
* There is a first tech tree implementation for stage one of missions.

### What's still to come
* Incorporate flight time;
* Technology (tech tree) for stages 2-5 (including extra improvements);
* More interesting interaction with other players (especially when you want to support somebody else's mission);
* Tuning;
* User management and authentication (for now, using the randomly generated UUID for a Player will be enough);
* Backup/restore in case something goes wrong with the database/server.

### What won't be here
* forums, messaging, chat: I assume you bring your own.

## Architecture - model
This game is built on the Vapor Server-side Swift framework.
The actual simulation/model is in the `Sources/Model` folder. To reference it's types, use `import Model`
Currently the model contains three types:
1. A `Player` struct that represents users of the game;
3. An `Improvement` struct that describes "buildings" players can build that have various beneficial effects. Instances of Players have their improvements as values;
4. The `Technology` struct is mostly a static and immutable data carrier: both an array of all technologies in the game (i.e. tech tree), as well as the basic data we need to know about. By themselves, the technology has no behaviour. Behaviour is added with players (which technologies does the player know about? is the player able to unlock this technology?), components (which technology is required to build the component?) and improvements (which technology is required to build the improvement?). Instances of Players store their unlocked technologies by reference to the technology's ShortName;
5. A `Mission` struct: Missions are build up of `Stages`. `Stages` struct: stages are built up from `Components`. Stages and Components are stored as values in a mission.
(Mission has sub-structures for `Stages` and ``Components`, but these are not database aware, just plain strucs.)
6. A `Simulation` struct that ties Players and Missions together. It contains arrays for all Players and all Simulation and contains operations where you need to interact with both at the same time. Note: the entire game state is kept in memory at all times!

### Structure
All struct tend to follow the same pattern:
* they are immutable. Functions that change state return *new instances* of the affected instance. Please take care not to lose these.

### Usage
These structs do not contain any mutable functions. All functions that should change the state of the game return a copy of the struct (including any others that might be changed) with the changes applied. 
It is your responsibility to take this result, use it and if necesarry persist it.

An example:
```
// assume we have a player "player" that is part of simulation "simulation": 
// this player performs an action:
let changedPlayer = try player.investInNextLevelOfTechnology()
// store the changed player in the simulation
simulation = simulation.replacePlayer(changedPlayer)
```

### Simulation update cycle
With arrays of [Players] and [Mission], `Simulation` struct also contains meta data about the Simulation: when it should update (in real time), how often it was updates and the "game date": a fictional date representing in game time. 

It also contains an updateSimulation function that takes care of updating data elements in the game. This function performs enough updates to compensate for the actual time that passed since the last simulation update, the current time and the length of a simulation "tick". 

```
 public func updateSimulation(currentDate: Date) -> Simulation
```

In principle, there should only be one simulation active in your game at any time. But more are allowed. In this version, the FrontEndController contains the single instance of Simulation that represents the entire game state.

### Persistence
Earlier versions of this game used SQLite and PostgreSQL as persistence backend. However, after performance testing I found that simply writing the game state to a JSON file was way faster than using database operations, especially for the update cycle that might (one day!) need to update millions of players! You can see [this spreadsheet](Documentation/SQLite vs PostgreSQL performance.xlsx) for details.

Persistance is now the task of `Simulation.swift` that contains `load()` and `save()` functions. The initiazer in `FrontEndController.swift` first tries to load a simulation. If it fails, it creates a new one. Everytime the simulation update is triggered in the FrontEndController, the simulation.save() method is called to persist the game state.
THIS MEANS THAT GAME STATE IS ONLY PERSISTED EVERY SO OFTEN AS THE GAME UPDATES. IF THE GAME CRASHES BETWEEN UPDATES, ALL CHANGES SINCE THE LAST UPDATE ARE LOST!

### Environment variables
M2M uses the following environment variables:
* DATA_DIR (string): local folder to store the simulation.json as well as backup files
* ADMIN_EMAIL (string): email address to use for the default admin player
* ADMIN_USER (string): username for the default admin player
* DEBUG_MODE ("active" || "inactive"): enables or disables debug mode (enables /debug/* end points)
* DO_SPACES_ACCESS_KEY (string): 1 part of the Digital Ocean Spaces API key
* DO_SPACES_SECRET (string): Second part of the Digital Ocean Spaces API key
* DO_SPACES_FOLDER (string): subfolder to use (use this to share one Space between various development/production environments)
* MAILJET_API_KEY (string): first part of the MailJet API key
* MAILJET_SECRET_KEY (string) second part of the MailJet API key

Note: none are required for the application to work per se.

## Architecture - UI
The UI is Leaf based. The most important Leaf view is `main.leaf` (called from `\main`). This shows the game dashboard, but also performs the following tasks:
1. Calling `/main` checks  whether enough real time has passed to update the simulation;
2. If the simulation needs to update, all players and missions are also updated;
3. It checks whether the mission for the current player (either owning or supporting) is complete. If so, the "Win screen" is shown;
4. There is an `errorMessages` dictionary ([UUID: String?]), you can use to show an error message to players. See `donate/to/supportedPlayer` route in `FrontEndController.swift` for an exmaple.

## Debug features
The game provides some debug features:
* There a routes specifically intented for debug functionality. These need to be deleted for production work (or otherwise disabled);
* The main debug solution is lowering the time between ticks (i.e. to less than a second) to get through the game quicker;
* Off course, the regular xcode debug features can be used.

## Contact details
Need to contact me? Drop an email at maarten@thedreamweb.eu or twitter at [@maarten_engels](https://twitter.com/maarten_engels) 

## Licensed assets & embedded media
* [Solar theme](https://bootswatch.com/solar/) by [Thomas Park](https://thomaspark.co/) (MIT License)
* Icons for components, stages, technologies, company and improvements are from the [Free Icons from Streamline Icons pack](https://www.streamlineicons.com/).
* Paul Hudson's "vapor-clean" template is the basis of this product. You can find it here. https://github.com/twostraws/vapor-clean (MIT License). Also, his book was/is invaluable if you want to take Vapor development further: https://www.hackingwithswift.com/store/server-side-swift  
* Favicon is based on a Mars image from NASA. Apart from being a very esthetically pleasing image, it also shows Gale Crater: a possible Mars landing site. Original file:  https://www.nasa.gov/mission_pages/msl/multimedia/pia14293-amended.html 
* Digital Ocean Spaces integration using [AWSSDKSwift](https://github.com/swift-aws/aws-sdk-swift.git).
