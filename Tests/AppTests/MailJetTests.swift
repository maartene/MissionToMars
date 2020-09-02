//
//  MailJetTests.swift
//  AppTests
//
//  Created by Maarten Engels on 02/01/2020.
//

import Foundation
import Dispatch
@testable import App
import Vapor
import XCTest


class MailJetTests: XCTestCase {
    
    var app: Application!
    
    override func setUp() {
        do {
            var env = try Environment.detect()

            // this line clears the command-line arguments
            env.commandInput.arguments = []

            try LoggingSystem.bootstrap(from: &env)

            let app = Application(env)
            defer { app.shutdown() }
            
            try configure(app)
            try app.run()
                        
        } catch {
            fatalError("Failed to launch Vapor server: \(error.localizedDescription)")
        }
    }
    
    override func tearDown() {
        app.shutdown()
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
        
        /*let mailJet = MailJetConfig(apiKey: publicKey, secretKey: privateKey, senderName: "Maarten", senderEmail: "maarten@mission2mars.space")
        mailJet.sendMessage(to: "maarten@thedreamweb.eu", toName: "Maarten Engels", subject: "Test email", message: "Test message", htmlMessage: nil, on: app)*/
    }
        
}
