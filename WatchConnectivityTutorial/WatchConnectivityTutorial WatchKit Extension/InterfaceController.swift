//
//  InterfaceController.swift
//  WatchConnectivityTutorial WatchKit Extension
//
//  Created by Roderic on 6/15/15.
//  Copyright © 2015 Thumbworks. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController, WCSessionDelegate {

    let session : WCSession!
    @IBOutlet var tappedLabel: WKInterfaceLabel!

    override init() {
        if(WCSession.isSupported()) {
            session =  WCSession.defaultSession()
        } else {
            session = nil
        }
    }

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        if(WCSession.isSupported()) {
            session.delegate = self
            session.activateSession()
        }
        self.tappedLabel.setText("")
        
    }


    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    func buttonPressed(offset : Int) {
        
        // verify that this device supports WCSession (iPod and iPad do not as of β1
        if(WCSession.isSupported()) {
            
            // create a message dictionary to send
            let message = ["buttonOffset" : offset]
            
            session.sendMessage(message, replyHandler: { (content:[String : AnyObject]) -> Void in
                print("Our counterpart sent something back. This is optional")
                }, errorHandler: {  (error ) -> Void in
                    print("We got an error from our paired device : " + error.domain)
            })
        }
    }
    
    @IBAction func topLeftButtonTapped() {
        buttonPressed(0)
    }
    
    @IBAction func topRightButtonTapped() {
        buttonPressed(1)
    }
    
    @IBAction func bottomLeftButtonTapped() {
        buttonPressed(2)
    }
    
    @IBAction func bottomRightButtonTapped() {
        buttonPressed(3)
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        print("we got something from the iPhone" + message.description)
        
        if let offsetValue = message["buttonOffset"] as! Int? {
            
            let labelText = ["top Left", "top Right", "bottom Left", "bottom Right"][offsetValue]
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tappedLabel.setText(labelText)
            })
            
            // Delay a little bit then set it back
            let delayTime = dispatch_time(DISPATCH_TIME_NOW,
                Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.tappedLabel.setText("")
            }
        }
        // optionally send some data back through the replyHandler
    }
}
