//
//  MailJetTests.swift
//  AppTests
//
//  Created by Maarten Engels on 02/01/2020.
//

import Foundation
import Dispatch
import App
import Vapor
import XCTest
@testable import MailJet


class MailJetTests: XCTestCase {
    
    var app: Application!
    
    override func setUp() {
        do {
            var config = Config.default()
            var env = try Environment.detect()
            var services = Services.default()
            
            // this line clears the command-line arguments
            env.commandInput.arguments = []
            
            try App.configure(&config, &env, &services)

            app = try Application(
                config: config,
                environment: env,
                services: services
            )
            
            try App.boot(app)
            try app.asyncRun().wait()
        } catch {
            fatalError("Failed to launch Vapor server: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        try? app.runningServer?.close().wait()
    }
    
    func disable_testSendTestMail() throws {
        guard let publicKey = Environment.get("MAILJET_API_KEY") else {
            XCTFail("Could not find MailJet api key in environment. Did you remember to set it?")
            return
        }
        
        guard let privateKey = Environment.get("MAILJET_SECRET_KEY") else {
            XCTFail("Could not find MailJet api secret key in environment. Did you remember to set it?")
            return
        }
        
        
        let mailJet = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Maarten", senderEmail: "maarten@mission2mars.space")
        mailJet.sendMessage(to: "maarten@thedreamweb.eu", toName: "Maarten Engels", subject: "Test email", message: "Test message", on: app)
    }
        
}
