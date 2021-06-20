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

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var result: UILabel!
    @IBOutlet weak var console: UILabel!
    @IBOutlet weak var termsConditionsTextView: UITextView!
    @IBOutlet weak var termsConditionsSwitch: UISwitch!
    @IBOutlet weak var verifyButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        let attributedString = NSMutableAttributedString(string: "tru.ID terms & conditions")
        attributedString.addAttribute(.link, value: "https://tru.id/terms", range: NSRange(location: 0, length: 25))
        //attributedString.addAttribute(.paragraphStyle, value: NSTextAlignment.center, range: NSMakeRange(0, attributedString.length))

//        termsConditionsTextView.attributedText = attributedString

    }

    @IBAction func termAndConditionsAcceptChanged(_ sender: Any) {
        if let _ = sender as? UISwitch {
            if let phoneNumber = phoneField.text {
                validateUI(with: phoneNumber)
            }
        }
    }

    @IBAction func phoneCheck(_ sender: Any) {
        // hide keyboard
        phoneField.resignFirstResponder()
        if let phone = phoneField.text {
            doPhoneCheck(phoneNumber: phone)
        }
    }
    
    func doPhoneCheck(phoneNumber: String) {
        // Auto-completed phone numbers come with spaces so strip them out
        let phoneNumber = phoneNumber.replacingOccurrences(of: "\\s*", with: "", options: [.regularExpression])
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

extension ViewController {
    func validateUI(with phoneNumber: String) {
        if termsConditionsSwitch.isOn &&
            !phoneNumber.isEmpty &&
            phoneNumber.count == 13 &&
            phoneNumber.hasPrefix("+"){
            verifyButton.isEnabled = true
        } else {
            verifyButton.isEnabled = false
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let phoneNumber = textField.text {
            validateUI(with: phoneNumber)
        }
    }

    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.text?.count == 13 {
            return true
        } else {
            return false
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let field = textField.text as NSString? {
            let testString = field.replacingCharacters(in: range, with: string)
            validateUI(with: testString)
        }

        return true
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}

