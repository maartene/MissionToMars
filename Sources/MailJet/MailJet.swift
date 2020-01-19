
import Foundation
import Vapor

public struct MailJetConfig {
    
    let apiKey: String
    let secretKey: String
    let senderName: String
    let senderEmail: String
    
    public init(apiKey: String, secretKey: String, senderName: String, senderEmail: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.senderName = senderName
        self.senderEmail = senderEmail
    }
    
    public func sendMessage(to toEmail: String, toName: String, subject: String, message: String, htmlMessage: String?, on container: Container) {
        sendMessages([Message(from: EmailAddress(name: senderName, email: senderEmail), to: [EmailAddress(name: toName, email: toEmail)], subject: subject, textPart: message, htmlPart: htmlMessage)], on: container)
    }
    
    public func sendMessages(_ messages: [Message], on container: Container) {
        do {
            
        // Connect a new client to the supplied hostname.
            let client = try container.client()
            
            
            guard let base64encodedApiKey = ("\(apiKey):\(secretKey)").data(using: .utf8)?.base64EncodedString() else {
                print("failed to create data from apikey.")
                return
            }
            
            let headers = HTTPHeaders([("Content-Type", "application/json"), ("Authorization", "Basic \(base64encodedApiKey)")])
            let body = try JSONEncoder().encode(["Messages": messages])
            
            let httpRequest = HTTPRequest(method: .POST, url: "https://api.mailjet.com/v3.1/send", headers: headers, body: HTTPBody(data: body))
            let request = Request(http: httpRequest, using: container)
            
            //print(request)
            
            _ = client.send(request)
        } catch {
            print(error)
        }
    }
}

public struct EmailAddress: Codable {
    let name: String
    let email: String
}

public struct Message: Content {
    let from: EmailAddress
    let to: [EmailAddress]
    let subject: String
    let textPart: String
    let htmlPart: String?
    
    
}
