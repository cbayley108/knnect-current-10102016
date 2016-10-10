//
//  UserInfo.swift
//  knnect
//
//  Created by Chris Bayley on 6/23/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import Foundation
import Firebase

struct UserInfo {
    
    let uid: String!
    let firstName: String!
    let lastName: String!
    let type: String!
    let school: String!
    //Realized it's easier to store all the info in an array rather than individual variables for every thing, realistically don't need the other variables
    var allUserInfo = ["first-name": "", "type": "", "last-name": "", "school": "", "major": "", "grade": "", "interests": "", "corporation": "", "uid": "", "bio": "", "headline": "", "numberOfKnnections": "0"]
    
    
    
    
    // Initialize from arbitrary data
    init(info: Dictionary<String, String>) {
        self.uid = info["uid"]
        self.firstName = info["first-name"]
        self.lastName = info["last-name"]
        self.type = info["type"]
        self.school = info["school"]
        self.allUserInfo["first-name"] = info["first-name"]
        self.allUserInfo["last-name"] = info["last-name"]
        self.allUserInfo["type"] = info["type"]
        self.allUserInfo["grade"] = info["grade"]
        self.allUserInfo["interests"] = info["interests"]
        self.allUserInfo["corporation"] = info["corporation"]
        self.allUserInfo["school"] = info["school"]
        self.allUserInfo["major"] = info["major"]
        self.allUserInfo["headline"] = info["headline"]
        self.allUserInfo["uid"] = info["uid"]
        self.allUserInfo["numberOfKnnections"] = info["numberOfKnnections"]
        if (info["bio"] != nil){
            self.allUserInfo["bio"] = info["bio"]
        } else {
            self.allUserInfo["bio"] = "Water. Earth. Fire. Air. Long ago, the four nations lived together in harmony. Then, everything changed when the Fire Nation attacked. Only the Avatar, master of all four elements, could stop them, but when the world needed him most, he vanished. A hundred years passed and my brother and I discovered the new Avatar, an airbender named Aang. And although his airbending skills are great, he has a lot to learn before he's ready to save anyone. But I believe Aang can save the world."
        }
    }
    
    //Initialize given a firebase snapshot from the user-info for a user
    init(snapshot: FIRDataSnapshot) {
        self.uid = snapshot.key
        self.firstName = snapshot.value!["first-name"] as! String
        self.lastName = snapshot.value!["last-name"] as! String
        self.type = snapshot.value!["type"] as! String
        self.school = snapshot.value!["school"] as! String
        
        self.allUserInfo["first-name"] = snapshot.value!["first-name"] as? String
        self.allUserInfo["last-name"] = snapshot.value!["last-name"] as? String
        self.allUserInfo["type"] = snapshot.value!["type"] as? String
        self.allUserInfo["grade"] = snapshot.value!["grade"] as? String
        self.allUserInfo["interests"] = snapshot.value!["interests"] as? String
        self.allUserInfo["corporation"] = snapshot.value!["corporation"] as? String
        self.allUserInfo["headline"] = snapshot.value!["headline"] as? String
        self.allUserInfo["school"] = snapshot.value!["school"] as? String
        if(snapshot.value!["major"]! != nil){
            self.allUserInfo["major"] = snapshot.value!["major"] as? String
        } else {
            self.allUserInfo["major"] = "Computer Science"
        }
        if((snapshot.value!["connections"]!)?.count != nil){
            self.allUserInfo["numberOfKnnections"] = String((snapshot.value!["connections"]!)!.count!)
        }
        if(snapshot.value!["bio"]! != nil){
            self.allUserInfo["bio"] = snapshot.value!["bio"] as? String
        } else {
            self.allUserInfo["bio"] = "Water. Earth. Fire. Air. Long ago, the four nations lived together in harmony. Then, everything changed when the Fire Nation attacked. Only the Avatar, master of all four elements, could stop them, but when the world needed him most, he vanished. A hundred years passed and my brother and I discovered the new Avatar, an airbender named Aang. And although his airbending skills are great, he has a lot to learn before he's ready to save anyone. But I believe Aang can save the world."
        }
        self.allUserInfo["uid"] = snapshot.key
    }
    
    //Returns an array of all the user's info
    func toAnyObject() -> AnyObject {
        return allUserInfo
    }

    
    
}
