//
//  ViewController.swift
//  Sample
//
//  Created by Eric on 22/08/2020.
//  Copyright © 2020 Eric. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var check: APIManager.Check?
    private var checkStatus: APIManager.CheckStatus?

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var result: UILabel!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func enterField(_ sender: UITextField) {
        print("enter "+sender.text!)
        
        self.label.text =  ""
        self.result.text =  ""
        activityIndicator.startAnimating()
        let startTime = NSDate().timeIntervalSince1970 * 1000

        APIManager().getCheck(withPhoneNumber: sender.text!) { (c) in
             DispatchQueue.main.async {
                self.check = c
                self.label.text =  c.url
                let currentTime = NSDate().timeIntervalSince1970 * 1000
                print(currentTime-startTime)
                print(c)
                
                self.doRedirect(url: self.check!.url)
                //self.fireURL(url: self.check!.url)
                
                APIManager().getCheckStatus(withCheckId: self.check!.id) { (s) in
                             DispatchQueue.main.async {
                                self.checkStatus = s
                                let currentTime = NSDate().timeIntervalSince1970 * 1000
                                print(currentTime-startTime)
                                print(s)
                                self.label.text =  ""
                                self.result.text =  s.match.description
                                self.activityIndicator.stopAnimating()
                            }
                        }
                
            }
        }
    }
    
    func doRedirect(url: String) {
        let rm: RedirectManager  = RedirectManager()
        rm.doRedirect(string: url)
    }
    
    func fireURL(url:String) -> String {
        var response = "ERROR: Unknown HTTP Response"
        print(url)
        response = HTTPRequester.performGetRequest(URL(string: url))
        
        if response.range(of:"REDIRECT:") != nil {
            // Get redirect link
            let redirectRange = response.index(response.startIndex, offsetBy: 9)...
            let redirectLink = String(response[redirectRange])
            // Make recursive call
            response = fireURL(url: redirectLink)
        } else if response.range(of:"ERROR: Done") != nil {
            return "ERROR: Unknown HTTP Response"
        }
        return response
    }
    

}

