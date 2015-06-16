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
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        
        // verify that we've gotten a number at the "buttonOffset" key
        if let offsetValue = message["buttonOffset"] as! Int? {
            
            // Determine which watch button has been tapped as mapped to the iPhone's
            let tappedButton = buttons[offsetValue]
            
            // We're going to change the title, so let's store the old one so we can set it back
            let oldTitle = tappedButton.titleForState(UIControlState.Normal)
            
            // Change the title on the main thread
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                tappedButton.setTitle("😍", forState:UIControlState.Normal)
            })
            
            // Delay a little bit then set it back
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(1 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                tappedButton.setTitle(oldTitle, forState:UIControlState.Normal)
            }
            // again, we can optionally call replyHandler(<some response dictionary>)
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

