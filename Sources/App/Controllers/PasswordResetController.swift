//
//  File.swift
//  
//
//  Created by Maarten Engels on 24/10/2020.
//

import Foundation
import Vapor

struct PasswordResetEntry: Codable {
    static let DEFAULT_VALIDITY_TIME: Double = 3600
    
    let key: UUID
    let email: String
    let expirationDate: Date
    
    init(email: String) {
        self.key = UUID()
        self.email = email
        self.expirationDate = Date().addingTimeInterval(PasswordResetEntry.DEFAULT_VALIDITY_TIME)
    }
    
    var isStillValid: Bool {
        self.expirationDate >= Date()
    }
}

extension Application {
    struct PasswordResetEntries: StorageKey {
        typealias Value = [PasswordResetEntry]
    }
    
    var passwordResetTokens: [PasswordResetEntry] {
        get { guard let tokens = self.storage[PasswordResetEntries.self] else {
                self.storage[PasswordResetEntries.self] = [PasswordResetEntry]()
                return []
            }
            return tokens
        }
        set { self.storage[PasswordResetEntries.self] = newValue }
    }
}

func createPasswordResetRoutes(_ app: Application) {
    let session = app.routes.grouped([
        SessionsMiddleware(session: app.sessions.driver),
        UserSessionAuthenticator(),
        UserCredentialsAuthenticator(),
    ])
    
    app.get("reset") { req -> EventLoopFuture<View> in
        return req.view.render("passwordResetRequest")
    }
    
    app.post("reset") { req -> EventLoopFuture<View> in
        let emailAddress: String = try req.content.get(at: "emailAddress")
        let name: String = try req.content.get(at: "name")
        
        let succesMessage = """
            <p>A password reset link was sent to email address <span class="text-info">\(emailAddress)</span> if this is a valid email/name combination.</p>
            <p>Please follow further instructions in the email.</p>
        """
        
        guard let player = app.simulation.players.first(where: { $0.emailAddress == emailAddress }) else {
            app.logger.warning("No player found with email address \(emailAddress).")
            return req.view.render("result", ["successMessage": succesMessage])
        }
        
        guard player.name == name else {
            app.logger.warning("No player found with email address \(emailAddress).")
            return req.view.render("result", ["successMessage": succesMessage])
        }
        
        app.logger.info("Password reset sent for player \(player.name) with email address \(emailAddress)")
        
        // send email
        let token = PasswordResetEntry(email: emailAddress)
        app.passwordResetTokens.append(token)
        
        let baseURL = Environment.get("BASE_URL") ?? "http://localhost:8080"
        
        let message = """
            Hi \(player.name),
            
            We received your password reset request.
            
            Please use copy this url in your browser to choose a new password:
            \(baseURL)/reset/\(token.key)
            
            - the Mission2Mars team
            Sent from: \(Environment.get("ENVIRONMENT") ?? "local test")
            """
        let htmlMessage = """
            <h1>Hi \(player.name),</h1>
            <p>We received your password reset request.</p>
            <p>&nbsp;</p>
            <p>Please use <a href="\(baseURL)/reset/\(token.key)">this link</a> to choose a new password.</p>
            <p>&nbsp;</p>
            <p>- the Mission2Mars team</p>
            <p>Sent from: \(Environment.get("ENVIRONMENT") ?? "unknown")</p>
            """
        
        if let publicKey = Environment.get("MAILJET_API_KEY"), let privateKey = Environment.get("MAILJET_SECRET_KEY") {
        
            let mailJetConfig = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Mission2Mars Support", senderEmail: "support@mission2mars.space")
                
            mailJetConfig.sendMessage(to: player.emailAddress, toName: player.name, subject: "Password reset request", message: message, htmlMessage: htmlMessage, on: req)
        }
        return req.view.render("result", ["successMessage": succesMessage])
    }
    
    app.get("reset", ":key") { req -> EventLoopFuture<View> in
        app.passwordResetTokens.removeAll(where: {$0.isStillValid == false})
        
        guard let key = UUID(req.parameters.get("key") ?? "") else {
            return req.view.render("result", ["errorMessage": "Invalid password reset url."])
        }
        
        guard let token = app.passwordResetTokens.first(where: {$0.key == key}) else {
            app.logger.warning("Token is no longer valid.")
            return req.view.render("result", ["errorMessage": "Password reset link no longer valid."])
        }
        
        guard token.isStillValid else {
            app.logger.warning("Token is no longer valid.")
            return req.view.render("result", ["errorMessage": "Password reset link no longer valid."])
            
        }
        
        return req.view.render("passwordResetChoosePassword", ["token": token])
    }
    
    app.post("reset", ":key") { req -> EventLoopFuture<View> in
        guard let key = UUID(req.parameters.get("key") ?? "") else {
            return req.view.render("result", ["errorMessage": "Invalid password reset url."])
        }
        
        guard let token = app.passwordResetTokens.first(where: {$0.key == key}) else {
            app.logger.warning("Token is no longer valid.")
            return req.view.render("result", ["errorMessage": "Password reset token not found."])
        }
        
        guard token.isStillValid else {
            app.logger.warning("Token is no longer valid.")
            return req.view.render("result", ["errorMessage": "Password reset token no longer valid."])
        }
        
        guard let player = app.simulation.players.first(where: {$0.emailAddress == token.email}) else {
            app.logger.warning("Player not found for email address \(token.email).")
            return req.view.render("result", ["errorMessage": "Player not found for email addresss \(token.email)."])
        }
        
        var newPasswordPlayer = player
        let password: String = try req.content.get(at: "password")
        newPasswordPlayer.setPassword(password)
        app.simulation = try app.simulation.replacePlayer(newPasswordPlayer)
        
        app.passwordResetTokens.removeAll(where: { $0.email == token.email })
        
        let message = """
            Hi \(player.name),
            
            Your password was just reset using our password reset option.
            
            If you did this, no further action is required.

            If you don't recognize this action, please contact us by replying to this message.
            
            - the Mission2Mars team
            Sent from: \(Environment.get("ENVIRONMENT") ?? "local test")
            """
        let htmlMessage = """
            <h1>Hi \(player.name),</h1>
            <p>Your password was just reset using our password reset option.</p>
            <p>&nbsp;</p>
            <p>If you did this, no further action is required.</p>
            <p>If you don't recognize this action, please contact us by replying to this message.</p>
            <p>&nbsp;</p>
            <p>- the Mission2Mars team</p>
            <p>Sent from: \(Environment.get("ENVIRONMENT") ?? "unknown")</p>
            """
        
        if let publicKey = Environment.get("MAILJET_API_KEY"), let privateKey = Environment.get("MAILJET_SECRET_KEY") {
        
            let mailJetConfig = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Mission2Mars Support", senderEmail: "support@mission2mars.space")
                
            mailJetConfig.sendMessage(to: player.emailAddress, toName: player.name, subject: "Password reset confirmation", message: message, htmlMessage: htmlMessage, on: req)
        }
        
        return req.view.render("result", ["successMessage": "Password was succesfully reset."])
    }
    
}
