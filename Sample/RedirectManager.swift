//
//  RedirectManager.swift
//  Sample
//
//  Created by Eric on 23/08/2020.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation
import Network


class RedirectManager {
    
var connection: NWConnection?

    func startConnection(url: URL) {
        let params = NWParameters.tls
        params.requiredInterfaceType = NWInterface.InterfaceType.cellular

        let connection = NWConnection(host: NWEndpoint.Host(url.host!), port: 443, using: params)
        self.connection?.stateUpdateHandler = { (newState) in
            print("This is stateUpdateHandler:")
            switch (newState) {
                case .ready:
                    print("State: Ready\n")
                case .setup:
                    print("State: Setup\n")
                case .cancelled:
                    print("State: Cancelled\n")
                case .preparing:
                    print("State: Preparing\n")
                default:
                    print("ERROR! State not defined!\n")
            }
        }
        
        connection.start(queue: .main)
        self.connection = connection
        print(connection.debugDescription)
    }

    func sendAndReceive(data: Data, completion: @escaping (String?) -> ()) {
        self.connection!.send(content: data, completion: NWConnection.SendCompletion.contentProcessed(({ (error) in
            if let err = error {
                print("Sending error \(err)")
            } else {
                print("Sent successfully")
            }
        })))
        self.connection!.receiveMessage { data, context, isComplete, error in
              print("Receive isComplete: " + isComplete.description)
              guard let d = data else {
                  print("Error: Received nil Data")
                  return
              }
              let r = String(data: d, encoding: .utf8)!
              print(r)
              completion(self.parseRedirect(response: r))
        }
    }
    
    private func parseRedirect(response: String) -> String? {
        let status = response[response.index(response.startIndex, offsetBy: 9)..<response.index(response.startIndex, offsetBy: 12)]
        print(status)
        if (status == "302") {
            if let range = response.range(of: #"Location: (.*)\r\n"#,
            options: .regularExpression) {
                let location = response[range];
                print(location)
                let redirect = location[location.index(location.startIndex, offsetBy: 10)..<location.index(location.endIndex, offsetBy: -1)]
                print(redirect)
                return String(redirect)
            }
        }
        return nil
    }

    func doRedirect(string: String) {
        print("doGet "+string)
        let url = URL(string: string)!
        self.startConnection(url: url)
        var str = String(format: "GET %@", url.path)
        if (url.query != nil) {
            str = str + String(format:"?%@", url.query!)
        }
        str = str + String(format:" HTTP/1.1\r\nHost: %@", url.host!)
//        if (url.port != nil) {
//            query = query + String(format:":%@", url.port!)
//        } else {
            str = str + String(format:":%@", "443")
//        }
        str = str + " \r\nConnection: close\r\n\r\n"
        print("-------")
        print(str)
        print("-------")
        let data: Data? = str.data(using: .utf8)
        self.sendAndReceive(data: data!) { (result) -> () in
            if let r = result {
                print("--- r ----")
                print(r)
                print("-------")
                self.doRedirect(string: r)
            }
        }
    }
}

