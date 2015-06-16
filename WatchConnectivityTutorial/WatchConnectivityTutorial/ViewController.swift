//
//  ViewController.swift
//  WatchConnectivityTutorial
//
//  Created by Roderic on 6/15/15.
//  Copyright © 2015 Thumbworks. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate {

    @IBOutlet var buttons: [UIButton]!
    let session : WCSession!

    required init(coder aDecoder: NSCoder) {
        self.session = WCSession.defaultSession()
        super.init(coder: aDecoder)
    }
    
    @IBAction func tappedButton(sender: UIButton) {
        
        if let i = buttons.indexOf(sender) {
            let message = ["buttonOffset" : i]
            
            session.sendMessage(message, replyHandler: { (content:[String : AnyObject]) -> Void in
                print("Our counterpart sent something back. This is optional")
                }, errorHandler: {  (error ) -> Void in
                    print("We got an error from our watch device : " + error.domain)
            })
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(WCSession.isSupported()) {
            session.delegate = self
            session.activateSession()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

