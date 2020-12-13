//
//  File.swift
//  
//
//  Created by Maarten Engels on 22/11/2020.
//

import Foundation
import Vapor
import Leaf

func createManageAccountRoutes(_ app: Application) {
    
    let session = app.routes.grouped([
        SessionsMiddleware(session: app.sessions.driver),
        UserSessionAuthenticator(),
        UserCredentialsAuthenticator(),
    ])
    
    session.get("account", "manage") { req -> EventLoopFuture<View> in
        struct AccountManageContext: Content {
            let player: Player
            let infoMessage: String?
            let errorMessage: String?
        }
        
        guard let player = try? getPlayerFromSession(on: req) else {
            return req.view.render("index", ["state": app.simulation.state])
        }
        
        let context = AccountManageContext(player: player, infoMessage: app.infoMessages[player.id] ?? nil, errorMessage: app.errorMessages[player.id] ?? nil)
        
        return req.view.render("manageAccount", context)
    }
    
    session.post("account", "changePassword") { req -> Response in
        let player = try getPlayerFromSession(on: req)
        
        var newPasswordPlayer = player
        let password: String = try req.content.get(at: "password")
        newPasswordPlayer.setPassword(password)
        app.simulation = try app.simulation.replacePlayer(newPasswordPlayer)

        app.infoMessages[player.id] = "Succesfully changed password."
        
        let message = """
            Hi \(player.name),
            
            Your password was successfully changed.
                        
            If you did this, no further action is required.
            If you didn't recognize this action, please contact us by replying to this message.

            - the Mission2Mars team
            Sent from: \(Environment.get("ENVIRONMENT") ?? "local test")
        """
        
        let htmlMessage = """
            <h1>Hi \(player.name),</h1>
            <p>Your password was successfully changed.</p>
            <p>&nbsp;</p>
            <p>If you did this, no further action is required.</p>
            <p>If you don't recognize this action, please contact us by replying to this message.</p>
            <p>&nbsp;</p>
            <p>- the Mission2Mars team</p>
            <p>Sent from: \(Environment.get("ENVIRONMENT") ?? "unknown")</p>
        """
        
        if let publicKey = Environment.get("MAILJET_API_KEY"), let privateKey = Environment.get("MAILJET_SECRET_KEY") {
        
            let mailJetConfig = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Mission2Mars Support", senderEmail: "support@mission2mars.space")
                
            mailJetConfig.sendMessage(to: player.emailAddress, toName: player.name, subject: "Successfully changed password", message: message, htmlMessage: htmlMessage, on: req)
        }
        
        return req.redirect(to: "/manage/account")
    }
    
    session.get("account", "delete", ":id") { req -> Response in
        guard let user = req.auth.get(Player.self) else {
            throw Abort(.unauthorized)
        }
        
        guard let useridString = req.parameters.get("id") else {
            app.errorMessages[user.id] = "Error deleting account. Contact support for more help."
            return req.redirect(to: "/account/manage")
        }
        
        guard user.id == UUID(uuidString: useridString) else {
            req.logger.error("UUID did not match")
            app.errorMessages[user.id] = "Error deleting account. Contact support for more help."
            return req.redirect(to: "/account/manage")
        }
        
        guard user.isAdmin == false else {
            app.errorMessages[user.id] = "Admin accounts cannot be deleted."
            return req.redirect(to: "/account/manage")
        }
        
        guard user.ownsMissionID == nil else {
            app.errorMessages[user.id] = "Accounts who own missions cannot be deleted."
            return req.redirect(to: "/account/manage")
        }
        
        app.simulation = try app.simulation.deletePlayer(user)
        
        let message = """
            Hi \(user.name),
            
            Your account was successfully deleted.
                        
            - the Mission2Mars team
            Sent from: \(Environment.get("ENVIRONMENT") ?? "local test")
        """
        
        let htmlMessage = """
            <h1>Hi \(user.name),</h1>
            <p>Your account was successfully deleted.</p>
            <p>&nbsp;</p>
            <p>- the Mission2Mars team</p>
            <p>Sent from: \(Environment.get("ENVIRONMENT") ?? "unknown")</p>
        """
        
        if let publicKey = Environment.get("MAILJET_API_KEY"), let privateKey = Environment.get("MAILJET_SECRET_KEY") {
        
            let mailJetConfig = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Mission2Mars Support", senderEmail: "support@mission2mars.space")
                
            mailJetConfig.sendMessage(to: user.emailAddress, toName: user.name, subject: "Successfully deleted account", message: message, htmlMessage: htmlMessage, on: req)
        }
        
        app.logger.notice("Deleted player: \(user.name)")
        
        //assert(app.simulation.players.count > 0)
        return req.redirect(to: "/")
    }
    
    
    
    
    func getPlayerFromSession(on req: Request) throws -> Player {
        guard let user = req.auth.get(Player.self) else {
            throw Abort(.unauthorized)
        }
        return user
    }
}
