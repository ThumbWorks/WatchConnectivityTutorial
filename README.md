# Using WatchConnectivity

## Abstract 

One of the most anticipated announcements of WWDC 2015 was the exposure of an SDK to allow 3rd party developers the opportunity to put real software on the newly released Apple Watch. Before WWDC 2015, developers were allowed to put a UI on the watch, with the actual controllers of the app running on the iPhone itself. While this is decent for some cases, clear disadvantages appeared nearly immediately. Apps took time to load because the iPhone app had to wake up, do some things, then send content and state to the watch, at which point the watch could actually display something. An informal poll shows that folks generally didn’t use the apps that they’d installed on their watch because they felt too cumbersome.

At the keynote, Tim Cook and co discussed watchOS2. A true native experience for the Apple Watch. One where the actual code, not just the UI was running on the watch device itself. The possibilities are endless. 

## Introducing WatchConnectivity
In this post, I’ll be digging into a very specific enhancement that came along with watchOS2 which piqued my interest, called `WatchConnectivity`. 

`WatchConnectivity` describes the communication API between the Apple Watch and the iPhone. The interface is straightforward, as there is a 1 to 1 relationship between devices. As in, there is 1 iPhone paired with 1 Watch. To communicate with your paired device, you simply access the `WCSession.defaultSession()` object, activate it, ensure that you’re connected, then send data. There are several ways to send data to the paired counterpart. I’ll only go into depth on one, specifically through - sendMessage:replyHandler:errorHandler: The rest of this post will describe how to set that up. 

## Our Catalyst App

The toy app that we’re going to create is a single view app on both the watch and the iPhone. They each contain 4 buttons: Top Left, Top Right, Bottom Left, Bottom Right. Tapping on 1 button, say, Top Left on the watch, should send a message to the counterpart where the results will be nicely displayed. 

## Starting the project
So let’s start by creating a new project which will be an iOS App with WatchKit App. 

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/june15/WikiImages/1%20Create_New_Project_iOS_App_With_WatchKit_App.jpg)

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/june15/WikiImages/2%20Create_Product_Name.jpg)

Notice the 3 different groups that are created when we create this type of app. This helps us draw a clear line between the iOS app, the watch extension where our code lives and the watch views. 

## Adding UI to the Watch
Moving on, let’s start adding some UI. Open the `Interface.Storyboard`. This is the storyboard that describes all of our watch UI. We’re going to be focusing on the main part of the interface, not the glances or notifications. So let’s add 2 groups that each take up the full width of the screen and half of the height of the screen. We’ll then place 2 buttons into each of these groups. This should give us a quadrant looking main watch view in our storyboard. 

Our final UI element is a Label which describes which button was last pressed on the iPhone simulator. When a message comes from the iPhone, we'll want to update the label to display that latest activity from the phone.

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/june15/WikiImages/3%20Buttons_and_Label_laid_out.jpg)

Now that we’ve got the buttons and our activity label added, we’ll need to make IBOutlets so we have a reference to the UI elements, then we’ll need to make IBActions for the buttons so that we can actually do something when we press them. 

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/june15/WikiImages/3_5_connecting_watch_buttons.jpg)

We’re going to want to kick off our network communications in these IBActions. Since we’ll more or less be doing the same action 4 times, let’s make a nice convenience method that each of these will call. To keep things simple each IBAction sends an `Int` type representing it’s position in the grid. So Top Left is 0, Top Right is 1, Bottom Left is 2, Bottom right is 3. Mine looks something like this:

```swift
    func buttonPressed(offset : Int) {
        print("Button pressed \(offset)")
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
```

Now that we’ve got the shell of this all figured out and we’re passing an appropriate simple identifier to our convenience method, we can generate the dictionary that we’d like to send over. Again for simplicity sake, we’re going to send over a dictionary in the form `{“buttonTapped” : <offset of button pressed>}`. Very simple code, we’re creating a dictionary.

## The Send API

Now that we’ve got the data we’d like to send over, let’s take a look at [the docs](https://developer.apple.com/library/prerelease/watchos/documentation/WatchConnectivity/Reference/WCSession_class/index.html#//apple_ref/occ/instm/WCSession/sendMessage:replyHandler:errorHandler:) for `- sendMessage:replyHandler:errorHandler:`. 

The `message` is obviously the content we’re going to be sending over. The `replyHandler` closure will get called if you’re counterpart determines that they want to actually reply to what you’re saying. In an app where the watch asks questions of the iPhone, this would be how the i iPhone responds. This is optional. The error handler takes care of scenarios where either device becomes disconnected or possibly other catastrophes. For the sake of brevity, we'll not be doing anything of any significance in the reply or the error closures. We will simply send our message.

```swift
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
```

So far this should be pretty straight forward. Assuming our `WCSession` is activated (it isn't yet) and a companion device is paired (none is), we should be able to send messages as easy as this. Again, we're not really doing much with the `replyHandler`, other than printing out that we got a reply.

## Setting up the session

I'd mentioned a second ago that we need to do some `WCSession` boilerplate. This is pretty lightweight boilerplate, but it will mean the difference between this working and not. So we'll do 3 things: 

1. Keep a reference to the default `WCSession` object if this device supports `WatchConnectivity` (iPods/iPads do not as of β1).
2. Set the delegate for our session and activate it. This starts us up and listens for requests from the other side through the `WCSessionDelegate` protocol. We'll need to declare that both the iPhone and the watch view controllers conform to the `WCSessionDelegate` protocol. We'll actually implement the protocol in a later section.
3. Check our paired and connected state before we send our messages.

So first create a class level `let session : WCSession!`. Then override `init()` like this:

```swift
    override init() {
        if(WCSession.isSupported()) {
            session =  WCSession.defaultSession()
        } else {
            session = nil
        }
    }
```

Then override `willActivate`:

```swift
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

        if(WCSession.isSupported()) {
            session.delegate = self
            session.activateSession()
        }
        self.tappedLabel.setText("")
    }
```

So far our code should look [something like this] (https://github.com/ThumbWorks/WatchConnectivityTutorial/blob/watch-side-networking-implemented/WatchConnectivityTutorial/WatchConnectivityTutorial%20WatchKit%20Extension/InterfaceController.swift).

## Implementing the iPhone side

So let's take a look at the iPhone here. Like last time we'll set up our UI first. Let's open up Main.storyboard and add some more buttons that we can interact with. Since you're using size classes (you ARE using size classes correct?), we'll need to set some constraints on the buttons since we always want them to be visible. Let's set up 4 buttons that are constrained to the outer edges of the view.  There are probably several ways of adding constraints in Interface Builder, but I like to use the ole' Ctrl+drag from the button to the edge. The details of how you constrain these are not important but it is likely safe to have the buttons 10 pixels from their closest edges.

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/june15/WikiImages/4_Added_labels_to_the_phone_storyboard.jpg)

Next we'll add the `IBOutlet` to the `UIViewController`. We should be able to Ctrl+drag from the "New Referencing Outlet Collection" in the connections inspector on the right side to the code in the `ViewController.swift` just below the start of the `@class InterfaceController`. Be sure to do this 1 at a time starting at the top left button and moving clockwise. We'll do this so we can determine the offset in the collection of each button. For clarification sake, we'll be adding each button to the SAME referencing outlet collections. So you should see something like this `@IBOutlet var buttons: [UIButton]!` where mousing over the little connection button next to it highlights all 4 of the buttons.

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/june15/WikiImages/5_Buttons_in_a_collection.jpg)

Next we can add our `IBAction`. In this case, each of the buttons can be connected to the same `IBAction` since we've got that collection of outlets as defined above, we can easily query that to determine the data we need to send over when these things are tapped. In this case, it is the `indexOf` method on that collection. We'll build our dictionary just like we did on the watch side, and send our data in a very similar fashion. So we end up with a method like this:

```swift
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
```

To finish out the networking portion of this code, we need to set up our `WCSession` object similar to how we did it on the watch. So we'll create a `WCSession` reference in this view controller like so: `let session : WCSession!`. This should feel familiar. And in our `viewDidLoad` we'll do something like this to activate it:

```swift
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(WCSession.isSupported()) {
            session.delegate = self
            session.activateSession()
        }
    }
```

Finally, since our session is a `let` we've got to set that when we init:

```swift
    required init(coder aDecoder: NSCoder) {
        self.session = WCSession.defaultSession()
        super.init(coder: aDecoder)
    }
```


Alright, so to recap what we've done so far. We've set up our UI for the watch with 4 buttons and a label to show what's been changed on the iPhone side. We also set up a method which creates appropriate content and sends it over. We set up the UI for our iPhone similar to the watch. We created a method to send similar content to the watch. The only thing left to do is to update each UI when we get a response. We are able to do that by implementing the `WCSessionDelegate` method `- session:didReceiveMessage:replyHandler:`. So let's go ahead and do that.

## Handling the network requests

So now that we've got some data being sent over, let's be sure to handle the data when we get it. You'll remember that we declared `self` as the `delegate` to the `WCSession` on both ends. This just means that we'll be the object that handles the incoming messages. So the very basic implementation is something like this:

```swift
func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
   print("we just got a message: " + message.description)
}

```

We'll add that to both of the view controllers. Now if we were to build and run, we'd be able to tap some buttons and actually see things happening in the debugger of the companion device. 

## State of the Debugging

A quick note here on the state of the tools we've got for debugging. This is the first time we've really been able to, or ever really had a need run two different simulators from the same build. There are a few little gotchas to consider when running this kind of environment.

1. We need to determine which device we're actually running when he hit build and run. More concretely, we need to determine which target is being built. To do this, we edit our scheme. Apple has done a nice job of adding some UI in the scheme editor to change the target device. In the scheme editor, take a look at the run target and look at the Executable option. You'll notice both your Watch App and your iPhone App. Keep this in mind when debugging.
1. Once we've finally started, we need to remember that the debugger is only attached to one process at a time. What that means is that only 1 device will ever show any debug statements. There is a half way workaround. You can go to Debug > Attach to Process, then select the device which is not currently being run. This will allow you to hit breakpoints, but unfortunately not debug statements. I've filed a radar (21351217) hopefully it gets duped and fixed.

## Updating the Watch UI

So hopefully you're running and seeing some debug statements on at least one of your devices. As a nice finishing touch, we'll go ahead and add some text changes so we can get some better visual cues that things are happening. For the watch, we'll need to extract the appropriate mapping, which is just an integer, from the dictionary that was sent over and we'll display some text in that status label we added form earlier. Then, on the main queue, we'll change the text for the label, and after some delay, we'll set the text back to an empty string.

```swift
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
```

Feel free to build and run to try it out. Make sure you're building for the watch so the changes take. Tap on the buttons on the iPhone simulator and watch the label magically update. 

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/june15/WikiImages/6%20BasicTalkingDevices.gif)

## Update the iPhone UI 

At this point we can do the same on the iPhone that we just did on the watch. We'll receive the message in the same `- session:didReceiveMessage:replyHandler:` method and update the UI appropriately. This time we can do a nice thing and change the button text. This is something we couldn't do on the watch because changing the text isn't supported as of β1.

```swift
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
```

Build and run and you'll now be able to tap on any of the 4 buttons on the watch or any of the 4 buttons on the iPhone. The UI on the companion is updated so we're sure that the messages are getting over.

![](https://raw.githubusercontent.com/ThumbWorks/WatchConnectivityTutorial/2871265f3e78492497d831cf11189051e43e155b/FinishedTalkingDevices.gif)

## Closing remarks

So we've covered the basics of sending a message using `WCSession` from a Watch to an iPhone, having the iPhone respond appropriately to the interactions. We've also covered the inverse of an iPhone interactions being mirrored on the Watch. There are still a few APIs yet to be explored including: `- updateApplicationContext:error:`, background data sends using `- transferUserInfo:` and also updating complication content using `- transferCurrentComplicationUserInfo:`.

This is some really great stuff which opens up tons of opportunities for a more interesting experience on or through the Watch. I'm curious to see what some folks end up doing with this information.

If you've got any questions about the code which is posted [here](https://github.com/ThumbWorks/WatchConnectivityTutorial), or see issues, or just want to discuss Watch stuff, feel free to reach out to me on twitter [@roderic](http://twitter.com/roderic).

Happy Coding!
