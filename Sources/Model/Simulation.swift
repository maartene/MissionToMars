//
//  Simulation.swift
//  MissionToMars
//
//  Created by Maarten Engels on 15/12/2019.
//

import Foundation
import Vapor

public struct Simulation: Content {
    public enum SimulationError: Error {
        case userAlreadyExists
        case usernameFailedValidation
        case missionNotFound
        case userDoesNotExist
        case playersNotInSameMission
        

    }
    
    public static let UPDATE_INTERVAL_IN_MINUTES = 15.0
    
    public private(set) var missions = [Mission]()
    public private(set) var players = [Player]()
    
    public var id: UUID
    public let tickCount: Int
    public let gameDate: Date
    public let nextUpdateDate: Date
    
    public init(id: UUID = UUID(), tickCount: Int, gameDate: Date, nextUpdateDate: Date) {
        self.id = id
        self.tickCount = tickCount
        self.gameDate = gameDate
        self.nextUpdateDate = nextUpdateDate
    }
    
    public func updateSimulation(currentDate: Date) -> Simulation {
        var updatedSimulation = self
        var updatedPlayers = players
        var updatedMissions = missions
    
        while updatedSimulation.simulationShouldUpdate(currentDate: currentDate) {
            //print("updating \(result)")
            //let nextUpdateDate = updatedSimulation.nextUpdateDate.addingTimeInterval(Simulation.UPDATE_INTERVAL_IN_MINUTES * 60)
            let nextUpdateDate = updatedSimulation.nextUpdateDate.addingTimeInterval(120)
            let gameDate = updatedSimulation.gameDate.addingTimeInterval(24*60*60)
            let tickCount = updatedSimulation.tickCount + 1
            
            updatedPlayers = updatedPlayers.map { player in
                player.updatePlayer()
            }
            
            updatedMissions = updatedMissions.map { mission in
                let supportingPlayers = mission.getSupportingPlayers(from: updatedPlayers)
                return mission.updateMission(supportingPlayers: supportingPlayers)
            }
            
            updatedSimulation = Simulation(id: self.id, tickCount: tickCount, gameDate: gameDate, nextUpdateDate: nextUpdateDate)
        }
        
        updatedSimulation.players = updatedPlayers
        updatedSimulation.missions = updatedMissions
        
        return updatedSimulation
    }
    
    public func simulationShouldUpdate(currentDate: Date) -> Bool {
        return currentDate >= self.nextUpdateDate
    }
    
    public func createPlayer(emailAddress: String, name: String) throws -> (newPlayer: Player, updatedSimulation: Simulation) {
        guard players.contains(where: { player in player.name == name || player.emailAddress == emailAddress }) == false else {
            throw SimulationError.userAlreadyExists
        }
        
        guard name.count >= 3 else {
            throw SimulationError.usernameFailedValidation
        }
        
        let newPlayer = Player(emailAddress: emailAddress, name: name)
        var updatedSimulation = self
        updatedSimulation.players.append(newPlayer)
        return (newPlayer, updatedSimulation)
    }
    
    public func getSupportedMissionForPlayer(_ player: Player) -> Mission? {
        if let supportedMissionID = player.ownsMissionID {
            return missions.first(where: {mission in mission.id == supportedMissionID})
        }
        
        if let supportedPlayerID = player.supportsPlayerID {
            if let supportedPlayer = players.first(where: {player in player.id == supportedPlayerID}) {
                return getSupportedMissionForPlayer(supportedPlayer)
            }
        }
        
        return nil
    }
    
    public func replaceMission(_ updatedMission: Mission) throws -> Simulation {
        guard let missionIndex = missions.firstIndex(where: {mission in mission.id == updatedMission.id} )else {
            throw SimulationError.missionNotFound
        }
        
        var changedSimulation = self
        changedSimulation.missions[missionIndex] = updatedMission
        return changedSimulation
    }
    
    public func replacePlayer(_ updatedPlayer: Player) throws -> Simulation {
        guard let playerIndex = players.firstIndex(where: {player in player.id == updatedPlayer.id} )else {
            throw SimulationError.userDoesNotExist
        }
        
        var changedSimulation = self
        changedSimulation.players[playerIndex] = updatedPlayer
        return changedSimulation
    }
    
    public func createMission(for player: Player) throws -> Simulation {
        guard player.ownsMissionID == nil else {
            throw Player.PlayerError.playerAlreadySupportsMission
        }
        
        guard player.supportsPlayerID == nil else {
            throw Player.PlayerError.playerAlreadySupportsMission
        }
        
        guard missions.contains(where: {mission in mission.owningPlayerID == player.id}) == false else {
            throw Player.PlayerError.playerAlreadySupportsMission
        }
        
        let mission = Mission(owningPlayerID: player.id)
        var changedPlayer = player
        changedPlayer.ownsMissionID = mission.id
        var changedSimulation = try replacePlayer(changedPlayer)
        changedSimulation.missions.append(mission)
        return changedSimulation
    }
    
    public func donateToPlayerInSameMission(donatingPlayer: Player, receivingPlayer: Player, cash: Double) throws -> Simulation {
        guard getSupportedMissionForPlayer(donatingPlayer)?.id == getSupportedMissionForPlayer(receivingPlayer)?.id else {
            throw SimulationError.playersNotInSameMission
        }
                
        let result = try donatingPlayer.donate(cash: cash, to: receivingPlayer)
        
        var changedSimulation = self
        changedSimulation = try changedSimulation.replacePlayer(result.donatingPlayer)
        changedSimulation = try changedSimulation.replacePlayer(result.receivingPlayer)
        return changedSimulation
    }
    
    public func donateToPlayerInSameMission(donatingPlayer: Player, receivingPlayer: Player, techPoints: Int) throws -> Simulation {
        guard getSupportedMissionForPlayer(donatingPlayer)?.id == getSupportedMissionForPlayer(receivingPlayer)?.id else {
            throw SimulationError.playersNotInSameMission
        }
                
        let result = try donatingPlayer.donate(techPoints: Double(techPoints), to: receivingPlayer)
        
        var changedSimulation = self
        changedSimulation = try changedSimulation.replacePlayer(result.donatingPlayer)
        changedSimulation = try changedSimulation.replacePlayer(result.receivingPlayer)
        return changedSimulation
    }
    
    public func playerInvestsInComponent(player: Player, component: Component) throws -> Simulation {
        guard let mission = getSupportedMissionForPlayer(player) else {
            throw Player.PlayerError.noMission
        }
        
        let result = try player.investInComponent(component, in: mission, date: gameDate)
        
        var changedSimulation = self
        changedSimulation = try changedSimulation.replacePlayer(result.changedPlayer)
        changedSimulation = try changedSimulation.replaceMission(result.changedMission)
        return changedSimulation
    }
    
    public func supportingPlayersForMission(_ mission: Mission) throws -> [Player] {
        guard missions.contains(where: { $0.id == mission.id }) else {
            throw SimulationError.missionNotFound
        }
        
        return players.filter { player in
            getSupportedMissionForPlayer(player)?.id == mission.id
        }
    }
    
    public func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // we make a copy of this simulation to make sure we never try to write a simulation that is being changed (in another thread)
            // this works because structures are values and copying is thread safe
            let copy = self
            let data = try encoder.encode(copy)
            let url = URL(fileURLWithPath: SIMULATION_FILENAME + ".json")
            try data.write(to: url)
            print("Succesfully saved simulation to file: \(url)")
        } catch {
            print("Error while saving simulation: \(error).")
        }
    }
    
    public static func load() -> Simulation? {
        do {
            let decoder = JSONDecoder()
            let url = URL(fileURLWithPath: SIMULATION_FILENAME + ".json")
            let data = try Data(contentsOf: url)
            let simulation = try decoder.decode(Simulation.self, from: data)
            print("Succesfully loaded simulation from file: \(url)")
            return simulation
        } catch {
            print("Error while loading simulation: \(error).")
        }
        
        return nil
    }
    
}
