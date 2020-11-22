//
//  File.swift
//  
//
//  Created by Maarten Engels on 20/10/2020.
//

import Foundation
import Vapor

extension Player: SessionAuthenticatable {
    public var sessionID: String {
        self.id.uuidString
    }
}

enum AuthenticationErrors: Error {
    case cannotFindPlayer
    case passwordDidNotMatch
}

struct UserSessionAuthenticator: SessionAuthenticator {
    typealias User = App.Player
    func authenticate(sessionID: String, for request: Request) -> EventLoopFuture<Void> {
        if let uuid = UUID(sessionID) {
            if let user = request.application.simulation.players.first(where: {$0.id == uuid}) {
                request.auth.login(user)
                return request.eventLoop.makeSucceededFuture(())
            }
        }
        return request.eventLoop.makeFailedFuture(AuthenticationErrors.cannotFindPlayer)
    }
}

struct UserCredentialsAuthenticator: CredentialsAuthenticator {
    struct Input: Content {
        let emailAddress: String
        let password: String
    }
    
    typealias Credentials = Input
    
    func authenticate(credentials: Credentials, for request: Request) -> EventLoopFuture<Void> {
        guard let user = request.application.simulation.players.first(where: {$0.emailAddress == credentials.emailAddress }) else {
            return request.eventLoop.makeFailedFuture(AuthenticationErrors.cannotFindPlayer)
        }
        
        do {
            if try Bcrypt.verify(credentials.password, created: user.hashedPassword) {
                request.auth.login(user)
                return request.eventLoop.makeSucceededFuture(())
            } else {
                return request.eventLoop.makeFailedFuture(AuthenticationErrors.passwordDidNotMatch)
            }
        } catch {
            print("Error during authentication: \(error)")
            return request.eventLoop.makeFailedFuture(error)
        }
        
    }
}

extension Request {
    func getPlayerFromSession() throws -> Player {
        guard let user = self.auth.get(Player.self) else {
            throw Abort(.unauthorized)
        }
        return user
    }
}
