//
//  Feed.swift
//  knnect
//
//  Created by Jonathan Victorino on 6/9/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import Foundation
import Firebase

struct Feed {

    let key: String!
    let name: String!
    let addedByUser: String!
    var completed: Bool!
    
    // Initialize from arbitrary data
    init(name: String, addedByUser: String, completed: Bool, key: String = "") {
        self.key = key
        self.name = name
        self.addedByUser = addedByUser
        self.completed = completed
        //self.ref = nil
    }
    
    
    func toAnyObject() -> AnyObject {
        return [
            "name": name,
            "addedByUser": addedByUser,
            "completed": completed
        ]
    }


}
