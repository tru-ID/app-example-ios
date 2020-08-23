//
//  APIManager.swift
//  Sample
//
//  Created by Eric on 22/08/2020.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation

final class APIManager {
        
    private let serverUrl = Bundle.main.object(forInfoDictionaryKey: "appServerUrl") as! String
    
    func getCheck(withPhoneNumber phone:String, completionHandler: @escaping (Check) -> Void) {        
        let endPoint: String = serverUrl + "/check?phone_number=\(phone)"
        
        print("endPoint[" + endPoint + "]")

        if let url = URL(string: endPoint) {
            print("url " + url.description)
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                  print("Error returning phone \(phone): \(error)")
                  return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                  print("Unexpected response status code: \(response)")
                  return
                }
                if let data = data,
                    let check = try? JSONDecoder().decode(Check.self, from: data) {
                    completionHandler(check)
                }
            }
            task.resume()
        } else {
            print("error")
        }
    }
    
    func getCheckStatus(withCheckId id:String, completionHandler: @escaping (CheckStatus) -> Void) {
        let endPoint: String = serverUrl + "/check_status?check_id=\(id)"
        
        print("endPoint[" + endPoint + "]")

        if let url = URL(string: endPoint) {
              print(url)
              let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                  print("Error returning id \(id): \(error)")
                  return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                  print("Unexpected response status code: \(response)")
                  return
                }
                if let data = data,
                    let check = try? JSONDecoder().decode(CheckStatus.self, from: data) {
                    completionHandler(check)
                }
              }
              task.resume()
        } else {
            print("error")
        }
    }
    
    struct Check: Codable {
      let id: String
      let url: String
      
      enum CodingKeys: String, CodingKey {
        case id = "check_id"
        case url = "check_url"
      }
      
      init(id: String,
           url: String) {
        self.id = id
        self.url = url
      }
    }
    
    struct CheckStatus: Codable {
      let id: String
      let match: Bool

      enum CodingKeys: String, CodingKey {
        case id = "check_id"
        case match
      }

      init(id: String,
           match: Bool) {
        self.id = id
        self.match = match
      }
    }

}