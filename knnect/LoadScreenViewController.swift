//
//  LoadScreenViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/30/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class LoadScreenViewController: UIViewController {

    

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    let userPath = "user-info"
    //Formats dates, used in setting values for feed array
    let formatter = NSDateFormatter()
    var userRef: FIRDatabaseReference?
    var rootRef: FIRDatabaseReference?
    var postRef: FIRDatabaseReference?
    var currentUser: UserInfo?
    var loading: Bool?
    var userSet: Bool?
    var unreadMessageCount = 0
    //Keeps track of when the initial setup is done, there are 6 total listeners which must be set and 6 arrays which are loaded. This counter is incremented for each of these so initial setup is done if it is >= 6.
    var initialSetupDone = 0
    //Used to check if done loading to progress to to the tab bar, only started once
    var timer: NSTimer?
    //Message data array is dependent on other areas already being set, second timer checks to make sure the other arrays are set then loads the message data array
    var timer2: NSTimer?
    //There is a possibility that the user is at this screen without having a valid user-info struct in the database, timer is used to check if a valid user has been set before trying to access any info
    var blockTimer: NSTimer?
    //A dictionary of all the posts liked by this user
    var likedPostsArray: [String: Int] = ["postId" : 0]
    //NOTE: All of these arrays are kept in sync with firebase through listeners, as long as loading is false accessing these arrays is functionally the same as accessing firebase
    //Array for this users pending knnections, ie all users who have invited this user
    var invitedArray = [
        ["first-name": "", "type": "", "last-name": "", "school": "", "grade": "", "interests": "", "corporation": "", "uid": ""]
    ]
    //Array for this users accepted knnections
    var acceptedArray = [
        ["first-name": "", "type": "", "last-name": "", "school": "", "grade": "", "interests": "", "corporation": "", "uid": ""]
    ]
    //Array for all student users
    var studentArray = [
        ["first-name": "", "type": "", "last-name": "", "school": "", "grade": "", "interests": "", "uid": ""]
    ]
    //Array for all mentor users
    var mentorArray = [
        ["first-name": "", "type": "", "last-name": "", "school": "", "corporation": "", "uid": ""]
    ]
    //Array for all posts to be displayed in the feed
    var feedArray = [
        ["text": "", "senderId": "", "name": "", "postId": "", "likes": ""]
    ]
    //Array for all the user ids who are blocked by this user
    var blockedArray = [""]
    //Array for all the users who are blocoked by this user, with all their info
    var blockedTableViewArray = [
        ["first-name": "", "type": "", "last-name": "", "school": "", "grade": "", "interests": "", "corporation": "", "uid": ""]
    ]
    //Array for all this users conversations
    var messageDataArray = [ ["first-name": "", "last-name": "", "type": "", "uid": ""] ]
    //Dictionary for all the profile pics, key is user id
    var profilePics = [String:UIImage]()
    //Set of all the postids in the feed
    var feedArrayIds = NSMutableSet()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        // Do any additional setup after loading the view.
        //Set this view controller as the applications root view controller
        //NOTE: This is very important, this is what allows access to this class from anywhere in the app, allowing us to store needed data here
        UIApplication.sharedApplication().keyWindow?.rootViewController = self
        //Sets up the date formatter
        formatter.dateStyle = NSDateFormatterStyle.MediumStyle
        formatter.timeStyle = NSDateFormatterStyle.NoStyle
        formatter.timeZone = NSTimeZone.localTimeZone()
        //No data has been stored yet, loading until all data has been stored
        self.loading = true
        //Reference for the firebase root database
        self.rootRef = FIRDatabase.database().reference()
        //Creates the user
        print("Calling create user")
        createUser()
        //Begins a timer which checks if a user was successfully made, which then creates the array of blocked users then all sets all other arrays
        startBlockArrayTimer()
    }
    
    //Begins timer to segue to the tab bar once it has finished loading
    override func viewDidAppear(animated: Bool) {
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    //Segues once done loading initial data
    func timerAction(){
        if(self.initialSetupDone != 6){
            return
        } else {
            self.performSegueWithIdentifier("showTabBar", sender: nil)
            timer?.invalidate()
        }
    }

    
    func createUser(){
        //Sets reference for this user's userinfo in firebase
        print("Create user")
        self.userRef = FIRDatabase.database().reference().child(self.userPath).child((FIRAuth.auth()?.currentUser?.uid)!)
        
        self.userRef?.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            //Possible that the user has no information set but user still exists, ie user closed application without setting information first time
            //User's info does not exist
            print("snaphsot created")
            if(!snapshot.exists()){
                //Take user back to Student/Mentor selection screen
                print("No user-info")
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let controller = storyboard.instantiateViewControllerWithIdentifier("JoinNow")
                UIApplication.sharedApplication().keyWindow?.rootViewController = controller
                UIApplication.sharedApplication().keyWindow?.makeKeyAndVisible()
                //Failed to create a user
                self.userSet = false
                return
            }
            //User info does exist
            self.currentUser = UserInfo(snapshot: snapshot)
            //Done loading the user info
            self.loading = false
            //Successfully made a user
            self.userSet = true
        })
    }
    
    func startBlockArrayTimer(){
        blockTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(setBlockArray), userInfo: nil, repeats: true)
    }
    
    func setBlockArray(){
        //Hasn't attempted to make a user yet
        if(userSet == nil){
            return
        }
        //Tried to make a user at this point, done with timer
        blockTimer?.invalidate()
        //Successfully made a user
        if(userSet!){
            self.userRef!.child("blocked-users").observeEventType(.Value, withBlock: {snapshot in
                //Clear the blocked array
                self.blockedArray.removeAll()
                //Beginning to load data
                self.loading = true
                //Adds each user to the array of blocked users
                for item in snapshot.children {
                    self.blockedArray.append((item as! FIRDataSnapshot).value! as! String)
                }
                //Done laoding
                self.loading = false
                //Setup all the other arrays now that all blocked users have been set
                self.setup()
            })
        }
    }
    
    //Loads all the other arrays
    func setup(){
        self.loading = true
        setBlockTableViewArray()
        setPublicNetworkArrays()
        setPrivateNetworkArrays()
        setFeedArray()
        setLikedPostsArray()
        setMessageDataArray()
    }
    
    //Stores all the user info for users who are blocked
    func setBlockTableViewArray(){
        let pathRef = FIRDatabase.database().reference().child(self.userPath)
        pathRef.observeEventType(.Value, withBlock: {snapshot in
            //Clears blocked array
            self.blockedTableViewArray.removeAll()
            self.loading = true
            //Counter keeps track of when all info has been loaded
            var count: UInt = 0
            for item in snapshot.children {
                count+=1
                //Creates user from snapshot
                let user = UserInfo(snapshot: item as! FIRDataSnapshot)
                //Add this user to the users to be displayed by the blocked table view if they are blocked by this user
                if(self.blockedArray.contains(user.uid)){
                    self.blockedTableViewArray.insert(user.toAnyObject() as! Dictionary<String, String>, atIndex: 0)
                }
                //Done going through all users
                if count == snapshot.childrenCount  {
                    self.loading = false
                    self.initialSetupDone += 1
                    print("1")
                }
                
            }
            //No children, also done loading
            if snapshot.childrenCount == 0 {
                self.loading = false
                self.initialSetupDone += 1
                print("2")
            }
        })

    }
    
    //Stores all the posts
    func setFeedArray(){
        self.postRef = rootRef!.child("posts")
        //storing reference for the current user's post data
        postRef?.observeEventType(.Value, withBlock: {snapshot in
            //Clears feed arrays
            self.feedArray.removeAll()
            self.feedArrayIds.removeAllObjects()
            var tempArray = ["text": "","senderId": "", "name": "","postId": "", "likes": ""]
            //Going to laod data
            self.loading = true
            //Counter keeps track of when all info has been loaded
            var count: UInt = 0
            for item in snapshot.children {
                count+=1
                //Not blocked by this user
                if(!self.blockedArray.contains(((item as! FIRDataSnapshot).value!["senderId"] as? String)!)){
                    //Store all info in temp array
                    tempArray["text"] = (item as! FIRDataSnapshot).value!["text"] as? String
                    tempArray["senderId"] = (item as! FIRDataSnapshot).value!["senderId"] as? String
                    tempArray["name"] = (item as! FIRDataSnapshot).value!["name"] as? String
                    tempArray["headline"] = (item as! FIRDataSnapshot).value!["headline"] as? String
                    
                    
                    if self.profilePics[((item as! FIRDataSnapshot).value!["senderId"] as? String)!] == nil{
                        self.downloadImage(((item as! FIRDataSnapshot).value!["senderId"] as? String)!)
                    }
                    let time = (item as! FIRDataSnapshot).value!["timestamp"] as? NSTimeInterval
                    //Format time, check if nil because old posts didn't have timestamp value
                    if time != nil {
                        tempArray["timestamp"] = self.formatter.stringFromDate(NSDate(timeIntervalSince1970: time!/1000))
                    }
                    let likes = ((item as! FIRDataSnapshot).value!["like-list"]!)?.count
                    if(likes == nil){
                        tempArray["likes"] = String(0)
                    } else {
                        tempArray["likes"] = String(likes!)
                    }
                    tempArray["postId"] = (item as! FIRDataSnapshot).key
                    //Add post id to set of current feed ids
                    self.feedArrayIds.addObject((item as! FIRDataSnapshot).key)
                    //Add entire temp array to the feed array
                    self.feedArray.insert(tempArray, atIndex: 0)
                }
                //Done loading
                if count == snapshot.childrenCount  {
                    self.loading = false
                    self.initialSetupDone += 1
                    print("3")
                }
                
                
            }
            if snapshot.childrenCount == 0 {
                self.loading = false
                self.initialSetupDone += 1
                print("4")
            }
        })
        
    
    }
    
    //Downloads image from firebase and adds it to dictionary
    func downloadImage(uid: String) {
        //NOTE: This url is specific to the current databse, if database changes this url must be changed
        let picRef = FIRStorage.storage().referenceForURL("gs://knnect-1431b.appspot.com").child("images/" + uid)
        var image: UIImage?
        picRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                self.profilePics.updateValue(UIImage(named:"Default Profile Pic")!, forKey: uid)
            } else {
                image = UIImage(data: data!)!
                self.profilePics.updateValue(image!, forKey: uid)
            }
        }
    }
    
    func setPublicNetworkArrays(){
        let pathRef = FIRDatabase.database().reference().child(self.userPath)
        pathRef.observeEventType(.Value, withBlock: {snapshot in
            //Clears student/mentor arrays
            self.studentArray.removeAll()
            self.mentorArray.removeAll()
            self.loading = true
            //Counter keeps track of when all info has been loaded
            var count: UInt = 0
            for item in snapshot.children {
                count+=1
                //Creates user from snapshot
                let user = UserInfo(snapshot: item as! FIRDataSnapshot)
                //Check if not the current user and also not blocked by this user
                if(FIRAuth.auth()?.currentUser?.uid != user.uid && !self.blockedArray.contains(user.uid)){
                    //User type control flow
                    if(user.type == "Mentor"){
                        self.mentorArray.insert(user.toAnyObject() as! Dictionary<String, String>, atIndex: 0)
                    } else {
                        self.studentArray.insert(user.toAnyObject() as! Dictionary<String, String>, atIndex: 0)
                    }
                }
                //Done going through all users
                if count == snapshot.childrenCount  {
                    self.loading = false
                    self.initialSetupDone += 1
                    print("5")
                }
            }
            //No children, also done loading
            if snapshot.childrenCount == 0 {
                self.loading = false
                self.initialSetupDone += 1
                print("6")
            }
        })
    }
    
    func setPrivateNetworkArrays(){
        let pathRef = self.userRef!.child("connections")
        pathRef.observeEventType(.Value, withBlock: {snapshot in
            self.loading = true
            //Clears invited/accepted arrays
            self.invitedArray.removeAll()
            self.acceptedArray.removeAll()
            //Counter keeps track of when all info has been loaded
            var count: UInt = 0;
            for item in snapshot.children {
                let status = (item as! FIRDataSnapshot).value as! String
                //Currently in the signed in users connections in database, only the uid and status is stored here. Must create new firebase listener in the other user's user info section of database to get all their info and load it into arrays
                if status == "Knnected"{
                    FIRDatabase.database().reference().child("user-info").child(item.key).observeSingleEventOfType(.Value, withBlock: {snapshotTwo in
                        count+=1
                        //Creates user from new snapshot
                        let user = UserInfo(snapshot: snapshotTwo)
                        //Check if not this user and not blocked by this user
                        if(FIRAuth.auth()?.currentUser?.uid != user.uid && !self.blockedArray.contains(user.uid)){
                            self.acceptedArray.insert(user.toAnyObject() as! Dictionary<String, String>, atIndex: 0)
                        }
                        //Done going through all users
                        if count == snapshot.childrenCount  {
                            print("7")
                            self.loading = false
                            self.initialSetupDone += 1
                            //Finished setting up for the first time
                            if self.initialSetupDone > 5 {
                                //Set badge value on tab bar for pending invitations
                                if self.invitedArray.count > 0{
                                    (self.presentedViewController as! UITabBarController).tabBar.items![2].badgeValue = String(self.invitedArray.count)
                                    //Set the badge value for the segmented controller in networks 
                                    (((self.presentedViewController as! UITabBarController).childViewControllers[2] as! UINavigationController).childViewControllers[0] as! NetworkViewController).reloadNotification()
                                } else {
                                    (self.presentedViewController as! UITabBarController).tabBar.items![2].badgeValue = nil
                                    //Set the badge value for the segmented controller in networks
                                    (((self.presentedViewController as! UITabBarController).childViewControllers[2] as! UINavigationController).childViewControllers[0] as! NetworkViewController).reloadNotification()
                                }
                            }
                        }
                    })
                } else if status == "Invited" {
                    FIRDatabase.database().reference().child("user-info").child(item.key).observeSingleEventOfType(.Value, withBlock: {snapshotTwo in
                        count+=1
                        //Create a user from new snaphsot
                        let user = UserInfo(snapshot: snapshotTwo)
                        //Check if not the current user and not blocked by this user
                        if(FIRAuth.auth()?.currentUser?.uid != user.uid && !self.blockedArray.contains(user.uid)){
                            self.invitedArray.insert(user.toAnyObject() as! Dictionary<String, String>, atIndex: 0)
                        }
                        //Done going through all users
                        if count == snapshot.childrenCount  {
                            print("8")
                            self.loading = false
                            self.initialSetupDone += 1
                            //Finished setting up for the first time
                            if self.initialSetupDone > 5 {
                                //Set badge value on tab bar for pending invitations
                                if self.invitedArray.count > 0{
                                    (self.presentedViewController as! UITabBarController).tabBar.items![2].badgeValue = String(self.invitedArray.count)
                                } else {
                                    (self.presentedViewController as! UITabBarController).tabBar.items![2].badgeValue = nil
                                }
                            }
                        }
                    })
                } else {
                    //Not accepted or invited
                    count+=1
                    //Done going through all users
                    if count == snapshot.childrenCount  {
                        self.loading = false
                        self.initialSetupDone += 1
                        //Finished setting up for the first time
                        if self.initialSetupDone > 5 {
                            //Set badge value on tab bar for pending invitations
                            if self.invitedArray.count > 0{
                                (self.presentedViewController as! UITabBarController).tabBar.items![2].badgeValue = String(self.invitedArray.count)
                            } else {
                                (self.presentedViewController as! UITabBarController).tabBar.items![2].badgeValue = nil
                            }
                        }
                    }
                }
                
            }
            //No children, also done loading
            if snapshot.childrenCount == 0 {
                print("9")
                self.loading = false
                self.initialSetupDone += 1
            }
        })
    }
    
    func setLikedPostsArray(){
        userRef?.child("liked-posts").observeEventType(.Value, withBlock: {snapshot in
            //Clear dictionary of all liked posts
            self.likedPostsArray.removeAll()
            self.loading = true
            //Counter keeps track of when all info has been loaded
            var count: UInt = 0
            for item in snapshot.children {
                count+=1
                let postId = (item as! FIRDataSnapshot).key
                //Add this post to dictionary of liked posts
                self.likedPostsArray[postId] = (item as! FIRDataSnapshot).value! as? Int
                //Done going through all liked posts
                if count == snapshot.childrenCount  {
                    print("10")
                    self.loading = false
                    self.initialSetupDone += 1
                }
            }
            //No children, also done
            if snapshot.childrenCount == 0 {
                print("11")
                self.loading = false
                self.initialSetupDone += 1
            }
        })
    }
    
    
    func setMessageDataArray(){
        timer2 = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(messageTimerAction), userInfo: nil, repeats: true)
    }
    
    func messageTimerAction(){
        //All other areas have not been set yet
        if(self.initialSetupDone < 5){
            return
        } else {
            //Going to load data
            self.loading = true
            let messagesRef = rootRef!.child("user-info").child((self.currentUser?.uid)!).child("messages")
            //Array of all users minus self and blocked users, created by adding students and mentors
            var usersArray = [ ["first-name": "", "last-name": "", "type": "", "uid": ""] ]
            usersArray.appendContentsOf(self.mentorArray)
            usersArray.appendContentsOf(self.studentArray)
            //Load in all conversations, with unread mesages at top
            messagesRef.queryOrderedByChild("read").observeEventType(.Value, withBlock: { snapshot in
                //Counter keeps track of when all info has been loaded
                var count: UInt = 0
                //Clear message data
                self.messageDataArray.removeAll()
                //Counter for number of unread messages
                self.unreadMessageCount = 0
                
                for item in snapshot.children {
                    count += 1
                    let msgID = (item as! FIRDataSnapshot).key
                    //Iterate through every user
                    for user in usersArray{
                        //Check if user is the correct user for this messageid
                        if user["uid"]! == msgID {
                            var messageUser = user
                            //Check if read or unread
                            if item.value["read"]! != nil{
                                //Set the read value for the message user
                                messageUser.updateValue(String(item.value!["read"]! as! Bool), forKey: "read")
                                //If not read, increase unread counter
                                if(!(item.value!["read"]! as! Bool)){
                                    self.unreadMessageCount += 1
                                }
                            }
                            //Add last message to message user
                            if item.value["last-message"]! != nil{
                                messageUser.updateValue(item.value!["last-message"]! as! String, forKey: "last-message")
                            } else{
                                messageUser.updateValue("", forKey: "last-message")
                            }
                            //Add user to message data array
                            self.messageDataArray.append(messageUser)
                        }
                    }
                    //Done going through all message ids
                    if count == snapshot.childrenCount  {
                        print("12")
                        self.loading = false
                        self.initialSetupDone += 1
                        //Has presented the tab bar
                        //NOTE: This is essentially the same as checking if the initial setup is done, but a more direct, safer version. This is probably how we should check if the initial setup is done in all other places besides the original timer action which begins the segue
                        if( self.presentedViewController as? UITabBarController != nil){
                            //Set badge value for unread messages
                            if(self.unreadMessageCount > 0){
                               (self.presentedViewController as! UITabBarController).tabBar.items![3].badgeValue = String(self.unreadMessageCount)
                                (((self.presentedViewController as! UITabBarController).childViewControllers[3] as! UINavigationController).childViewControllers[0] as! MessagesInitViewController).timerAction()
                            } else {
                                (self.presentedViewController as! UITabBarController).tabBar.items![3].badgeValue = nil
                            }
                            
                        }
                    }
                }
                //No message ids, also done loading
                if snapshot.childrenCount == 0 {
                    print("13")
                    self.loading = false
                    self.initialSetupDone += 1
                }
            })
            //Done with timer
            self.timer2?.invalidate()
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Called when going to transition to a new controller
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //If going to the tab bar
        if(segue.identifier == "showTabBar"){
            let tabBarVC = segue.destinationViewController
            //Update the badge values for invites and messages
            if(self.invitedArray.count > 0){
                (tabBarVC as! UITabBarController).tabBar.items![2].badgeValue = String(self.invitedArray.count)
            }
            if(unreadMessageCount > 0){
                (tabBarVC as! UITabBarController).tabBar.items![3].badgeValue = String(unreadMessageCount)
            }
            let jet = UIColor(red: 92/255, green: 158/255, blue: 173/255, alpha: 1.0)
            for item in (tabBarVC as! UITabBarController).tabBar.items! {
                (item as UITabBarItem).image = (item as UITabBarItem).image!.jsq_imageMaskedWithColor(jet).imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
            }

        }
    }
  

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
