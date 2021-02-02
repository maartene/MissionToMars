//
//  File.swift
//  
//
//  Created by Maarten Engels on 22/11/2020.
//

import Foundation
import Vapor
import Leaf
import SotoS3

func createAdminRoutes(_ app: Application) {
    app.get("admin", "state") { req in
        app.simulation.state.rawValue
    }
    
    let session = app.routes.grouped([
        SessionsMiddleware(session: app.sessions.driver),
        UserSessionAuthenticator(),
        UserCredentialsAuthenticator(),
    ])
    
    session.get("admin") { req -> EventLoopFuture<View> in
        return try adminPage(on: req, with: app.simulation, in: app)
    }

   
        
    session.get("admin", "leaveAdminMode") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state == .admin else {
            throw Abort(.badRequest, reason: "Can only leave admin mode when simulation is in admin mode.")
        }
        
        app.simulation.state = .running
        return req.redirect(to: "/admin")
    }
        
    session.get("admin", "save") { req -> EventLoopFuture<Response> in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        return app.saveSimulationToSpace(on: req).map { result in
            if let location = result.location {
                app.infoMessages[player.id] = "Succesfully saved: \(location)"
            } else {
                app.errorMessages[player.id] = "Failed to save."
            }
            
            return req.redirect(to: "/admin")
        }
        
        
    }
        
    session.get("admin", "enterAdminMode") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state != .admin else {
            throw Abort(.badRequest, reason: "Can only enter admin mode when simulation is not already in admin mode.")
        }
        
        req.logger.notice("entering admin mode.")
        app.simulation.state = .admin
        return req.redirect(to: "/admin")
    }
    
    session.post("admin", "set", "motd") { req -> Response in
        let player = try req.getPlayerFromSession()
        
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        let message: String = try req.content.get(at: "motd")
        
        app.motd = message
        
        return req.redirect(to: "/admin")
    }
        
    session.get("admin", "bless", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToBlessName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToBless = app.simulation.players.first(where: {$0.name == playerToBlessName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToBlessName).")
        }
        
        let blessedPlayer = playerToBless.bless()
        app.simulation = try app.simulation.replacePlayer(blessedPlayer)
        return req.redirect(to: "/admin")
    }

    session.get("admin", "unbless", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToBlessName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToBless = app.simulation.players.first(where: {$0.name == playerToBlessName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToBlessName).")
        }
        
        let unblessedPlayer = playerToBless.unbless()
        app.simulation = try app.simulation.replacePlayer(unblessedPlayer)
        return req.redirect(to: "/admin")
    }
    
    session.get("admin", "give", "tech", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToReceiveName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToReceive = app.simulation.players.first(where: {$0.name == playerToReceiveName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToReceiveName).")
        }
        
        let giftedPlayer = playerToReceive.extraTech(amount: 1000)
        app.simulation = try app.simulation.replacePlayer(giftedPlayer)
        return req.redirect(to: "/admin")
    }
    
    session.get("admin", "give", "cash", ":userName") { req -> Response in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard let playerToReceiveName = req.parameters.get("userName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("userName") ?? "unknown") is not a valid string value.")
        }
        
        guard let playerToReceive = app.simulation.players.first(where: {$0.name == playerToReceiveName }) else {
            throw Abort(.notFound, reason: "Could not find player with name \(playerToReceiveName).")
        }
        
        let giftedPlayer = playerToReceive.extraIncome(amount: 1_000_000)
        app.simulation = try app.simulation.replacePlayer(giftedPlayer)
        return req.redirect(to: "/admin")
    }
        
    session.get("admin", "load", "simulation", ":fileName") { req -> EventLoopFuture<Response> in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state == .admin else {
            throw Abort(.badRequest, reason: "Loading of database is only allowed in 'Admin' state.")
        }
        
        guard let fileName = req.parameters.get("fileName") else {
            throw Abort(.badRequest, reason: "\(req.parameters.get("fileName") ?? "unknown") is not a valid string value.")
        }
        
        return app.loadSimulationFromSpace(fileName: fileName, on: req).map { result in
            switch result {
            case .success(let loadedSimulation):
                app.simulation = loadedSimulation
                return req.redirect(to: "/")
            case .failure(let error):
                switch error {
                case ApplicationAWSErrors.other(let message):
                    app.errorMessages[player.id] = message
                default:
                    app.errorMessages[player.id] = "Error: \(error)"
                }
                return req.redirect(to: "/admin")
            }
        }
    }
}

func adminPage(on req: Request, with simulation: Simulation, in app: Application) throws -> EventLoopFuture<View> {
    /*struct FileInfo: Content {
        let fileName: String
        //let creationDate: String
        let modifiedDate: String
        let isCurrentSimulation: Bool
    }*/
    
    struct PlayerInfo: Content {
        let name: String
        let email: String
        let isAdmin: Bool
    }
        
    struct AdminContext: Content {
        let player: Player
        //let backupFiles: [FileInfo]
        let infoMessage: String?
        let errorMessage: String?
        let state: Simulation.SimulationState
        let players: [PlayerInfo]
        let motd: String
        let fileList: [SimulationFileInfo]
    }
    
    let player = try req.getPlayerFromSession()
    guard player.isAdmin else {
        throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
    }
    
    let players = simulation.players.map { player in
        PlayerInfo(name: player.name, email: player.emailAddress, isAdmin: player.isAdmin)
    }
    
    

    return app.getFileList(on: req).flatMap { fileList in
        
        let context = AdminContext(player: player,
                                   //backupFiles: sortedFiles,
                                   infoMessage: app.infoMessages[player.id] ?? nil, errorMessage: app.errorMessages[player.id] ?? nil, state: app.simulation.state, players: players, motd: app.motd, fileList: fileList)
        
        req.logger.info("File list retrieve complete.")
        
        
        return req.view.render("admin/admin", context)
    }
}
