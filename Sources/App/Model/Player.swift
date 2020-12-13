//
//  Player.swift
//  App
//
//  Created by Maarten Engels on 08/12/2019.
//

import Foundation
import Vapor

public struct Player: Content {
    public enum PlayerError: Error {
        case noMission
        case insufficientFunds
        case insufficientTechPoints
        case noSupportedPlayer

        case playerAlreadyHasImprovement
        case playerAlreadySupportsMission
        case playerAlreadyUnlockedTechnology
        case playerMissesPrerequisiteTechnology
        
        case playerIsAlreadyBuildingImprovement
        case playerNotFound
        case cannotDonateToYourself
        case illegalImprovementSlot
        
        case insufficientImprovementSlots
        case insufficientSpecializationSlots
        
        case missingImprovement
        case insufficientActionPoints
        
        case insufficientRushes
    }
    
    public var id = UUID()
    
    public let emailAddress: String
    public private(set) var hashedPassword = ""
    public let name: String
    public private(set) var isAdmin: Bool = false
    public var ownsMissionID: UUID?
    public var supportsPlayerID: UUID?
    
    public private(set) var unlockedTechnologyNames: [Technology.ShortName]
    
    // resources
    public private(set) var cash: Double = 2_500_000
    public private(set) var technologyPoints: Double = 75
    public private(set) var buildPoints: Double = 0
    public private(set) var componentBuildPoints: Double = 0
    public private(set) var actionPoints: Int = 10
    
    public private(set) var improvements: [Improvement]
    
    public private(set) var rushes = 1
    
    // MARK: Calculated properties
    public var unlockedTechnologies: [Technology] {
        return unlockedTechnologyNames.compactMap { techName in
            return Technology.getTechnologyByName(techName)
        }
    }
    
    public var currentlyBuildingImprovement: Improvement? {
        let unfinishedImprovements = improvements.filter { improvement in
            return improvement.buildStartedOn != nil && improvement.isCompleted == false
        }
        return unfinishedImprovements.first
    }
    
    public var isCurrentlyBuildingImprovement: Bool {
        return currentlyBuildingImprovement != nil
    }
    
    var completedImprovements: [Improvement] {
        return improvements.filter { improvement in
            return improvement.isCompleted
        }
    }
    
    public var cashPerTick: Double {
        let updatedPlayer = self.updatePlayer(ignoreOneShots: true)
        return updatedPlayer.cash - cash
    }
    
    public var buildPointsPerTick: Double {
        var updatedPlayer = self
        updatedPlayer.improvements.removeAll(where: { improvement in improvement.percentageCompleted < 100})
        updatedPlayer = updatedPlayer.updatePlayer(ignoreOneShots: true)
        return updatedPlayer.buildPoints
    }
    
    public var componentBuildPointsPerTick: Double {
        let updatedPlayer = self.updatePlayer(ignoreOneShots: true)
        return updatedPlayer.componentBuildPoints
    }
    
    public var techPerTick: Double {
        let updatedPlayer = self.updatePlayer(ignoreOneShots: true)
        return updatedPlayer.technologyPoints - technologyPoints
        
        /*let allEffects = completedImprovements.map { improvement in
            return improvement.updateEffects
            }.joined()
        
        let flatTechPerTick = allEffects.reduce(0.0) { result, effect in
            switch effect {
            case .extraTechFlat(let amount):
                return result + amount
            default:
                return result
            }
        }
        
        return flatTechPerTick*/
    }

    public var improvementSlotsCount: Int {
        var count = 5
        
        unlockedTechnologies.forEach { tech in
            tech.updateEffects.forEach{ effect in
                switch effect {
                case .extraImprovementSlots(let amount):
                    count += amount
                default:
                    break;
                }
            }
        }
        return count
    }
    
    /*public var maxActionPoints: Int {
        let count = MAXIMUM_PLAYER_ACTION_POINTS
        /*if unlockedTechnologyNames.contains(.ScaledAgileLeadership) {
            count += TECH_EXTRA_MAXIMUM_PLAYER_ACTION_POINTS
        }*/
        return count
    }*/
    
    public var maximumNumberOfSpecializations: Int {
        var count = BASE_PLAYER_SPECILIAZATION_SLOTS
        for tech in unlockedTechnologies {
            for effect in tech.updateEffects {
                switch effect {
                case .extraSpeciliazationSlots(let amount):
                    count += amount
                default:
                    break
                }
            }
        }
        return count
    }
    
    public var specilizationCount: Int {
        improvements.filter({ improvement in improvement.tags.contains(.Specialization)}).count
    }
    
    
    // MARK: Init
    public init(emailAddress: String, name: String, password: String, startImprovementShortName: Improvement.ShortName = .TechConsultancy) {
        self.emailAddress = emailAddress
        self.name = name
        self.improvements = []
        self.hashedPassword = (try? Bcrypt.hash(password)) ?? ""

        let startImprovement = Improvement.getImprovementByName(startImprovementShortName)!
        if let completedStartImprovement = try? startImprovement.startBuild(startDate: Date()).updateImprovement(buildPoints: Double(startImprovement.buildTime)) {
            assert(completedStartImprovement.updatedImprovement.isCompleted, "Your starting tech consultancy firm should be complete.")
            self.improvements = [completedStartImprovement.updatedImprovement]
        }
        
        self.unlockedTechnologyNames = [Technology.ShortName.LiIonBattery]
    }
    
    public mutating func setPassword(_ password: String) {
        self.hashedPassword = (try? Bcrypt.hash(password)) ?? ""
    }
    
    // MARK: Update
    public func updatePlayer(ignoreOneShots: Bool = false) -> Player {
        var updatedPlayer = self
        updatedPlayer.componentBuildPoints = 1
        
        updatedPlayer.buildPoints = 1
        // updatedPlayer.actionPoints = min(maxActionPoints, updatedPlayer.actionPoints + 1)
        
        for improvement in updatedPlayer.completedImprovements.filter({ improvement in
            ignoreOneShots == false || improvement.hasOneShotEffect == false
        }) {
            updatedPlayer = improvement.applyEffectForOwner(player: updatedPlayer)
        }
        //print("Player build points before: \(updatedPlayer.componentBuildPoints)")
        
        var updatedImprovements = updatedPlayer.improvements
        
        for i in 0 ..< updatedPlayer.improvements.count {
            let result = updatedImprovements[i].updateImprovement(buildPoints: updatedPlayer.buildPoints)
            updatedImprovements[i] = result.updatedImprovement
            updatedPlayer.buildPoints = result.remainingBuildPoints
        }
        
        updatedPlayer.improvements = updatedImprovements
        //print("Player build points after: \(updatedPlayer.buildPoints)")
        
        //print("cashPerTick: \(cashPerTick)")
        //print(updatedPlayer)
        return updatedPlayer
    }
    
    // MARK: Effect helpers
    func extraIncome(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.cash += amount
        return changedPlayer
    }
    
    func extraTech(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.technologyPoints += amount
        return changedPlayer
    }
    
    func extraBuildPoints(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.buildPoints += amount
        return changedPlayer
    }
    
    func extraComponentBuildPoints(amount: Double) -> Player {
        var changedPlayer = self
        changedPlayer.componentBuildPoints += amount
        return changedPlayer
    }
    
    /*func extraActionPoints(amount: Int) -> Player {
        var changedPlayer = self
        changedPlayer.actionPoints += amount
        return changedPlayer
    }*/
    
    func extraRushes(amount: Int) -> Player {
        var changedPlayer = self
        changedPlayer.rushes += amount
        return changedPlayer
    }
    
    // MARK: Player-to-player interaction
    func donate(cash amount: Double, to player: Player) throws -> (donatingPlayer: Player, receivingPlayer: Player) {
        guard amount <= self.cash else {
            throw PlayerError.insufficientFunds
        }
        
        guard player.emailAddress != self.emailAddress else {
            throw PlayerError.cannotDonateToYourself
        }
        
        var receivingPlayer = player
        var donatingPlayer = self
        
        receivingPlayer.cash += amount
        donatingPlayer.cash -= amount
        
        return (donatingPlayer, receivingPlayer)
    }
    
    func donate(techPoints amount: Double, to player: Player) throws -> (donatingPlayer: Player, receivingPlayer: Player) {
        guard amount <= self.technologyPoints else {
            throw PlayerError.insufficientTechPoints
        }
        
        guard player.emailAddress != self.emailAddress else {
            throw PlayerError.cannotDonateToYourself
        }
        
        var receivingPlayer = player
        var donatingPlayer = self
        
        receivingPlayer.technologyPoints += amount
        donatingPlayer.technologyPoints -= amount
        
        return (donatingPlayer, receivingPlayer)
    }
    
    // MARK: Components
    func investInComponent(_ component: Component, in mission: Mission, date: Date, ignoreTechPrereqs: Bool = false) throws -> (changedPlayer: Player, changedMission: Mission) {
        var updatedPlayer = self
        var updatedMission = mission
        
        guard mission.currentStage.unstartedComponents.contains(component) else {
            return (updatedPlayer, updatedMission)
        }
        
        let netCost = component.cost * 1.0
        
        guard cash >= netCost else {
            throw PlayerError.insufficientFunds
        }
        
        guard component.playerHasPrerequisitesForComponent(self) || ignoreTechPrereqs else {
            throw PlayerError.playerMissesPrerequisiteTechnology
        }
        
        updatedMission = try updatedMission.startBuildingInStage(component, buildDate: date, by: self)
        updatedPlayer.cash -= netCost
        
        return (updatedPlayer, updatedMission)
    }
        
    // MARK: Improvements
    public func canBuildImprovement(_ improvement: Improvement) -> Bool {
        (try? startBuildImprovement(improvement, startDate: Date())) != nil
    }
    
    public func startBuildImprovement(_ improvement: Improvement, startDate: Date, options: [BuildImprovementOption] = []) throws -> Player {
        // This is no longer relevant if we want to allow the same building built more than once. 
        /*guard improvements.contains(improvement) == false else {
            throw PlayerError.playerAlreadyHasImprovement
        }*/
        
        guard improvements.count < improvementSlotsCount else {
            throw PlayerError.insufficientImprovementSlots
        }
        
        guard options.contains(.ignoreTechPrereqs) || improvement.playerHasPrerequisitesForImprovement(self) else {
            throw PlayerError.playerMissesPrerequisiteTechnology
        }
        
        guard options.contains(.ignoreUniqueness) || (improvement.tags.contains(.Unique) && improvements.contains(improvement)) == false else {
            throw Improvement.ImprovementError.improvementIsUnique
        }
        
        guard options.contains(.ignoreSpecializationSlotCount) || (improvement.tags.contains(.Specialization) && improvements.filter({$0.tags.contains(.Specialization)}).count >= maximumNumberOfSpecializations) == false else {
            throw PlayerError.insufficientSpecializationSlots
        }
        
        guard cash >= improvement.cost else {
            throw PlayerError.insufficientFunds
        }
        
        if currentlyBuildingImprovement != nil {
            throw PlayerError.playerIsAlreadyBuildingImprovement
        }
        
        
        
        let buildingImprovement = try improvement.startBuild(startDate: startDate)
        
        var changedPlayer = self
        
        changedPlayer.improvements.append(buildingImprovement)
        assert(buildingImprovement.percentageCompleted == 0)
        assert(changedPlayer.improvements.last!.buildStartedOn != nil)
        changedPlayer.cash -= improvement.cost
        
        return changedPlayer
    }
    
    public func triggerImprovement(_ index: Int) throws -> Player {
        guard (0 ..< improvements.count).contains(index) else {
            throw PlayerError.missingImprovement
        }
        
        guard actionPoints > 0 else {
            throw PlayerError.insufficientActionPoints
        }
        
        let improvement = improvements[index]
    
        guard improvement.triggerable else {
            throw Improvement.ImprovementError.improvementCannotBeTriggered
        }
        
        var updatedPlayer = self
        updatedPlayer.actionPoints -= 1
        
        if improvement.isCompleted {
            
            return improvement.applyEffectForOwner(player: updatedPlayer)
        } else {
            let updatedImprovement = improvement.updateImprovement(buildPoints: 1)
            updatedPlayer.improvements[index] = updatedImprovement.updatedImprovement
            return updatedPlayer
        }
    }
    
    func replaceImprovementInSlot(_ slot: Int, with improvement: Improvement) throws -> Player {
        guard (0 ..< improvements.count).contains(slot) else {
            print("Slot \(slot) outside of improvement slot range.")
            throw PlayerError.illegalImprovementSlot
        }
        
        var changedPlayer = self
        changedPlayer.improvements[slot] = improvement
        return changedPlayer
    }
    
    func removeImprovementInSlot(_ slot: Int) throws -> Player {
        guard (0 ..< improvements.count).contains(slot) else {
            print("Slot \(slot) outside of improvement slot range.")
            throw PlayerError.illegalImprovementSlot
        }
        
        var changedPlayer = self
        changedPlayer.improvements.remove(at: slot)
        return changedPlayer
    }
    
    func removeImprovement(_ shortName: Improvement.ShortName) throws -> Player {
        guard let index = improvements.firstIndex(where: {$0.shortName == shortName }) else {
            throw PlayerError.missingImprovement
        }
        
        var changedPlayer = self
        changedPlayer.improvements.remove(at: index)
        return changedPlayer
    }
    
    public func sellImprovement(_ improvement: Improvement) throws -> Player {
        guard completedImprovements.contains(improvement) else {
            throw Improvement.ImprovementError.improvementIncomplete
        }
        
        if let slot = improvements.firstIndex(of: improvement) {
            let changedPlayer = try removeImprovementInSlot(slot)
            return changedPlayer.extraIncome(amount: improvement.cost * IMPROVEMENT_SELL_RATIO)
        } else {
            throw PlayerError.illegalImprovementSlot
        }
    }
    
    public func rushImprovement(in slot: Int) throws -> Player {
        guard (0 ..< improvements.count).contains(slot) else {
            throw PlayerError.illegalImprovementSlot
        }
        
        let improvement = improvements[slot]
        
        guard rushes > 0 else {
            throw PlayerError.insufficientRushes
        }
        
        guard improvement.isCompleted == false else {
            throw Improvement.ImprovementError.improvementCannotBeRushed
        }
        
        var rushingPlayer = self
        
        let rushedImprovement = try improvement.rush()
        rushingPlayer.rushes -= 1
        
        return try rushingPlayer.replaceImprovementInSlot(slot, with: rushedImprovement)
    }
    
    /*@available(*, deprecated, message: "This function has been replaced with 'rushImprovement(in:)'.")
    public func rushImprovement(_ improvement: Improvement) throws -> Player {
        guard cash >= improvement.cost else {
            throw PlayerError.insufficientFunds
        }
        
        var rushingPlayer = self
        
        let rushedImprovement = try improvement.rush()
        
        if let slot = rushingPlayer.improvements.firstIndex(where: { existingImprovement in
            existingImprovement == improvement && existingImprovement.isCompleted == false
        }) {
            rushingPlayer.cash -= improvement.cost
            return try rushingPlayer.replaceImprovementInSlot(slot, with: rushedImprovement)
        }
        
        return rushingPlayer
    }*/
        
    // MARK: Technology
    public func investInTechnology(_ technology: Technology) throws -> Player {
        guard technologyPoints >= technology.cost else {
            throw PlayerError.insufficientTechPoints
        }
        
        guard unlockedTechnologies.contains(technology) == false else {
            throw PlayerError.playerAlreadyUnlockedTechnology
        }
        
        guard technology.playerHasPrerequisitesForTechnology(self) else {
            throw PlayerError.playerMissesPrerequisiteTechnology
        }
        
        var changedPlayer = self
        changedPlayer.unlockedTechnologyNames.append(technology.shortName)
        changedPlayer.technologyPoints -= technology.cost
        return changedPlayer
    }
    
    public func technologyToCash(techPoints amount: Double) throws -> Player {
        guard cash >= amount else {
            throw PlayerError.insufficientTechPoints
        }
        
        let cashValue = amount * TECH_TO_CASH_CONVERSION_RATE
        
        var changedPlayer = self
        changedPlayer.cash += cashValue
        changedPlayer.technologyPoints -= amount
        
        return changedPlayer
    }
    
    mutating public func debug_setCash(_ amount: Double) {
        self.cash = amount
    }
    
    mutating public func debug_setTech(_ amount: Double) {
        self.technologyPoints = amount
    }
    
    mutating func debug_setActionPoints(_ amount: Int) {
        self.actionPoints = amount
    }
    
    public func bless() -> Player {
        var blessedPlayer = self
        blessedPlayer.isAdmin = true
        return blessedPlayer
    }
    
    public func unbless() -> Player {
        var unblessedPlayer = self
        unblessedPlayer.isAdmin = false
        return unblessedPlayer
    }
    
    // MARK: Internal - for testing only
    @available(*, deprecated, message: "This function is for internal, testing purposes only.")
    mutating func forceUnlockTechnology(shortName: Technology.ShortName) {
        unlockedTechnologyNames.append(shortName)
    }
}
