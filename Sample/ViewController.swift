//
//  ViewController.swift
//  Sample
//
//  Created by Eric on 22/08/2020.
//  Copyright © 2020 Eric. All rights reserved.
//

import UIKit
import Network
import TruSDK


class ViewController: UIViewController, UITextFieldDelegate {
    
    private var check: APIManager.Check?
    private var checkStatus: APIManager.CheckStatus?
    private var truSdk: TruSDK = TruSDK()


    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet var phoneField: UITextField!
    @IBOutlet var result: UILabel!
    @IBOutlet var console: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
    }
    
    @IBAction func phoneCheck(_ sender: Any) {
        // hide keyboard
        phoneField.resignFirstResponder()
        if let phone = phoneField.text {
            doPhoneCheck(phoneNumber: phone)
        }
    }
    
    @IBAction func enterField(_ sender: UITextField) {
        // hide keyboard
        phoneField.resignFirstResponder()
        if let phone = sender.text {
            doPhoneCheck(phoneNumber: phone)
        }
    }
    
    func doPhoneCheck(phoneNumber: String) {
        print("phoneNumber \(phoneNumber)")
        self.result.text =  ""
        self.console.text =  ""
        self.activityIndicator.startAnimating()
        self.checkStatus = nil
        let start = CFAbsoluteTimeGetCurrent()

        // Step 1: Send phone number to Server
        self.console.text =  "[\u{2714}] - Validating Phone Number Input"
        APIManager().postCheck(withPhoneNumber: phoneNumber) { (result) in
            switch result {
              case .success(let c):
                     self.check = c
                     DispatchQueue.main.async { // updating UI
                        let diff = CFAbsoluteTimeGetCurrent() - start
                        NSLog("server check \(c) \(diff)")
                        self.console.text = self.console.text! + "\n\n[\u{2714}] - Initiating Phone Verification"
                        self.console.text = self.console.text! + "\n\n[\u{2714}] - Creating Mobile Data Session"
                     }
                    // Step 2: Open check_url over cellular
                    self.truSdk.openCheckUrl(url: self.check!.url) { _ in
                        let diff = CFAbsoluteTimeGetCurrent() - start
                        NSLog("-------------- redirect ------->  \(diff)")
                        // Step 3: Get Result from Server
                        APIManager().getCheckStatus(withCheckId: self.check!.id) { (s) in
                            NSLog("-------------- get result-------------------")
                            DispatchQueue.main.async { // updating UI
                                self.checkStatus = s
                                let diff = CFAbsoluteTimeGetCurrent() - start
                                NSLog("server result \(s) \(diff)")
                                self.activityIndicator.stopAnimating()
                                self.console.text = self.console.text! + "\n\n[\u{2714}] - Phone Number match: \(s.match)"
                                if (s.match) {
                                    self.result.text =  "\u{2705}"
                                } else {
                                    self.result.text =  "\u{274C}"
                                }
                            }
                        }
                    }
            case .failure(let status):
                DispatchQueue.main.sync { // updating UI
                    self.activityIndicator.stopAnimating()
                    self.console.text =  ""
                    if (status == APIManager.CheckError.badRequest) {
                        self.result.text =  "\u{274C} wrong format"
                    } else {
                        self.result.text =  "\u{274C} error"
                    }
                }
            }
        }
    }
    
}

