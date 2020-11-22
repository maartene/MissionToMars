//
//  File.swift
//  
//
//  Created by Maarten Engels on 22/11/2020.
//

import Foundation
import Vapor
import Leaf
import S3

func createAdminRoutes(_ app: Application) {
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
        
        let dataDir = Environment.get("DATA_DIR") ?? ""
        let data = try app.simulation.save(fileName: "\(SIMULATION_FILENAME).json", path: dataDir)
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
        
        guard let accessKey = Environment.get("DO_SPACES_ACCESS_KEY"), let secretKey = Environment.get("DO_SPACES_SECRET") else {
            app.errorMessages[player.id] = "S3 access key and secret key not set in environment. Save failed."
            let promise = req.eventLoop.makePromise(of: Response.self)
            promise.succeed(req.redirect(to: "/admin"))
            return promise.futureResult
        }
        
        let s3 = S3(accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")
        let uploadRequest = S3.PutObjectRequest(acl: .private, body: data, bucket: bucket, contentLength: Int64(data.count), key: "\(SIMULATION_FILENAME).json")
        return s3.putObject(uploadRequest).map { result in
            app.infoMessages[player.id] = "Save succesfull. (\(result.eTag ?? "unknown"))"
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
        
        print("entering admin mode.")
        app.simulation.state = .admin
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
        
    session.get("admin", "load") { req -> EventLoopFuture<Response> in
        let player = try req.getPlayerFromSession()
        guard player.isAdmin else {
            throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
        }
        
        guard app.simulation.state == .admin else {
            throw Abort(.badRequest, reason: "Loading of database is only allowed in 'Admin' state.")
        }
        
        let bucket = Environment.get("DO_SPACES_FOLDER") ?? "default"
        
        guard let accessKey = Environment.get("DO_SPACES_ACCESS_KEY"), let secretKey = Environment.get("DO_SPACES_SECRET") else {
            req.logger.error("S3 access key and secret key not set in environment. Save failed.")
            let promise = req.eventLoop.makePromise(of: Response.self)
            promise.succeed(req.redirect(to: "/admin"))
            return promise.futureResult
        }
        
        let s3 = S3(accessKeyId: accessKey, secretAccessKey: secretKey, region: .euwest1, endpoint: "https://m2m.ams3.digitaloceanspaces.com")
        let downloadRequest = S3.GetObjectRequest(bucket: bucket, key: "\(SIMULATION_FILENAME).json")
        return s3.getObject(downloadRequest).map { response in
            guard let data = response.body else {
                app.errorMessages[player.id] = "Received empty/no response. Load failed."
                return req.redirect(to: "/admin")
            }
            
            let decoder = JSONDecoder()
            do {
                let loadedSimulation = try decoder.decode(Simulation.self, from: data)
                guard let adminPlayer = loadedSimulation.players.first(where: {$0.isAdmin}) else {
                    app.errorMessages[player.id] = "Did not find any admin player in loaded simulation. Load failed."
                    return req.redirect(to: "/admin")
                }
                req.logger.notice("Loaded admin player with username: \(adminPlayer.name), email: \(adminPlayer.emailAddress) and id: \(adminPlayer.id)")
                app.simulation = loadedSimulation
                return req.redirect(to: "/")
            } catch {
                
                req.logger.error("Load failed: \(error)")
                return req.redirect(to: "/admin")
            }
            
        }
    }
}

func adminPage(on req: Request, with simulation: Simulation, in app: Application) throws -> EventLoopFuture<View> {
    struct FileInfo: Content {
        let fileName: String
        let creationDate: String
        let modifiedDate: String
        let isCurrentSimulation: Bool
    }
    
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
    }
    
    let player = try req.getPlayerFromSession()
    guard player.isAdmin else {
        throw Abort(.unauthorized, reason: "Player \(player.name) is not an admin.")
    }
    
    let players = simulation.players.map { player in
        PlayerInfo(name: player.name, email: player.emailAddress, isAdmin: player.isAdmin)
    }
    
    let context = AdminContext(player: player,
                               //backupFiles: sortedFiles,
                               infoMessage: app.infoMessages[player.id] ?? nil, errorMessage: app.errorMessages[player.id] ?? nil, state: app.simulation.state, players: players)
    return req.view.render("admin/admin", context)
}
