//
//  ViewController.swift
//  Sample
//
//  Created by Eric on 22/08/2020.
//  Copyright © 2020 Eric. All rights reserved.
//

import UIKit
import Network


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
        self.activityIndicator.startAnimating()
        let startTime = NSDate().timeIntervalSince1970 * 1000


        // Step 1: Send phone number to Server
        APIManager().postCheck(withPhoneNumber: sender.text!) { (c) in
             DispatchQueue.main.async {
                self.check = c
                self.label.text =  c.url
                let currentTime = NSDate().timeIntervalSince1970 * 1000
                print("time: \(currentTime-startTime)")
                print("server check \(c)")
                // Step 2: Open check_url over cellular
                self.doRedirect(url: self.check!.url) { _ in ()
                    DispatchQueue.main.asyncAfter(deadline:.now() + 3) {
                        print("-------------- asyncAfter-------------------")
                        // Step 3: Get Result from Server
                        APIManager().getCheckStatus(withCheckId: self.check!.id) { (s) in
                            print("-------------- redirect result-------------------")
                                    DispatchQueue.main.async {
                                        self.checkStatus = s
                                        let currentTime = NSDate().timeIntervalSince1970 * 1000
                                        print("time: \(currentTime-startTime)")
                                        print("server result \(s)")
                                        self.label.text =  ""
                                        self.result.text =  s.match.description
                                        self.activityIndicator.stopAnimating()
                                    }
                                }
                        }
                    }
                }
        }
    }
    
    func doRedirect(url: String , completion: (Bool) -> ()) {
        let rm: RedirectManager  = RedirectManager()
        rm.doRedirect(link: url)
        return completion(true)
    }
    
}

