//
//  AppDelegate.swift
//  knnect
//
//  Created by Chris Bayley on 6/8/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    //Number of unread messages
    var unreadNotificationCount = 0
    //Number of pending knnections
    var pendingNotificationCount = 0
    //Firebase listeners that are activated upon app entering background, check for any notifications
    var messageObserver: UInt?
    var inviteObserver: UInt?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        FIRApp.configure()
        try! FIRAuth.auth()?.signOut()
        //Setup notifications
        let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()

        UIApplication.sharedApplication().statusBarStyle = .LightContent
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        /* Global color settings here: */
        
        let ghostWhite = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0)
        let seaBlue = UIColor(red: 5/255, green: 102/255, blue: 141/255, alpha: 1.0)
        let jet = UIColor(red: 92/255, green: 158/255, blue: 173/255, alpha: 1.0)



        //Nav Bar
        UINavigationBar.appearance().tintColor = ghostWhite
        UINavigationBar.appearance().barTintColor = seaBlue
        
        
        //Tool Bar
        UIBarButtonItem.appearance().tintColor = ghostWhite
        UIToolbar.appearance().barTintColor = seaBlue
        //Tab Bar
        UITabBar.appearance().tintColor = ghostWhite
        UITabBar.appearance().barTintColor = seaBlue
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: jet], forState:.Normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: ghostWhite], forState:.Selected)
        //Search Bar
        UISearchBar.appearance().tintColor = ghostWhite
        UISearchBar.appearance().backgroundColor = seaBlue
        //Table View
        UITableView.appearance().backgroundColor = ghostWhite
        
        
    
        //If else control flow to take user to main landing page or directly to feed if signed in
        var controller: UIViewController
        if FIRAuth.auth()?.currentUser == nil{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            controller = storyboard.instantiateInitialViewController()!
        }
        
        else {
            let storyboard = UIStoryboard(name: "Knnect", bundle: nil)
            controller = storyboard.instantiateInitialViewController()!
        }
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = controller
        self.window?.makeKeyAndVisible()
        return true
    }
    
   
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        //Reset current notification counts
        self.pendingNotificationCount = 0
        self.unreadNotificationCount = 0
        application.applicationIconBadgeNumber = 0
        //Make sure there is a signed in user, else do nothing
        if FIRAuth.auth()?.currentUser != nil {
            let connectionRef = FIRDatabase.database().reference().child("user-info").child((FIRAuth.auth()?.currentUser!.uid)!).child("connections")
            //Remove the old observer so there are no concurrent listeners
            if(inviteObserver != nil){
                connectionRef.removeObserverWithHandle(inviteObserver!)
            }
            //Set the current observer for checking invites
            self.inviteObserver = connectionRef.observeEventType(.Value, withBlock: { snapshot in
                var invitedCount = 0
                var count:UInt = 0
                for item in snapshot.children {
                    count += 1
                    if ((item as! FIRDataSnapshot).value as! String) == "Invited" {
                        invitedCount += 1
                    }
                    //Finished going through all of the user's connections
                    if count == snapshot.childrenCount {
                        if(invitedCount > self.pendingNotificationCount){
                            //The number of invites is greater than what it was last time it was checked, send notification
                            let notification = UILocalNotification()
                            notification.fireDate = NSDate(timeIntervalSinceNow: 0)
                            notification.soundName = UILocalNotificationDefaultSoundName
                            notification.alertBody = String(invitedCount) + " pending knnections"
                            UIApplication.sharedApplication().scheduleLocalNotification(notification)
                            //Set the current number of unread messages
                            self.pendingNotificationCount = invitedCount
                            application.applicationIconBadgeNumber = self.unreadNotificationCount + self.pendingNotificationCount
                        }
                    }
                }
            })
            let messagesRef = FIRDatabase.database().reference().child("user-info").child((FIRAuth.auth()?.currentUser?.uid)!).child("messages")
            //Remove the old observer so there are no concurrent listeners
            if(messageObserver != nil){
                messagesRef.removeObserverWithHandle(messageObserver!)
            }
            //Set the current observer for checking messages
            self.messageObserver = messagesRef.observeEventType(.Value, withBlock: { snapshot in
                var unreadCount = 0
                var count:UInt = 0
                for item in snapshot.children {
                    count += 1
                    if(!(item.value!["read"]! as! Bool)){
                        unreadCount += 1
                    }
                    //Finished going through staus of all user's messages
                    if count == snapshot.childrenCount {
                        if(unreadCount > self.unreadNotificationCount){
                            //Number of unread messages is greater than last time it was checked, send notification
                            let notification = UILocalNotification()
                            notification.fireDate = NSDate(timeIntervalSinceNow: 0)
                            notification.soundName = UILocalNotificationDefaultSoundName
                            notification.alertBody = String(unreadCount) + " unread messages"
                            UIApplication.sharedApplication().scheduleLocalNotification(notification)
                            //Set the current number of unread messages
                            self.unreadNotificationCount = unreadCount
                            application.applicationIconBadgeNumber = self.unreadNotificationCount + self.pendingNotificationCount
                        }
                    }
                }
                
            })
        }
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

