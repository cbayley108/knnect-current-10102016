//
//  NewMessageInitViewController.swift
//  knnect
//
//  Created by Charles Yu on 7/19/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class NewMessageInitViewController: UITableViewController {

    // Properties
    let authRef = FIRAuth.auth()!
    let rootRef = FIRDatabase.database().reference()
    var dataArray = [ ["first-name": "", "last-name": "", "type": "", "uid": ""] ]
    var filteredArray =  [ ["first-name": "", "last-name": "", "type": "", "uid": ""] ] //
    var choiceIndex: Int?
    var senderDisplay: String?
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
    var userType: String?
    let searchController = UISearchController(searchResultsController: nil)
    
    
    //View did appear
    override func viewDidAppear(animated: Bool){
        
        super.viewDidAppear(animated)
//        self.navigationItem.hidesBackButton = true;
        
        self.dataArray = [ ["first-name": "", "last-name": "", "type": "", "uid": ""] ]
        
        if (userType! == "Mentor") {
            self.dataArray.appendContentsOf(loadController.mentorArray)
            for user in loadController.acceptedArray{
              if user["type"] == "Student"{
                    self.dataArray.append(user)
                }
            }
            
        } else{
            self.dataArray.appendContentsOf(loadController.studentArray)
            self.dataArray.appendContentsOf(loadController.mentorArray) //Question - Would students even need to see all mentors if their chats can't be seen unless they're connected?
        }
        self.dataArray.removeAtIndex(0)
        self.tableView.reloadData()
        
        
    }
    
    //Initializing Table Data
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderDisplay = (loadController.currentUser?.firstName)! + " " + (loadController.currentUser?.lastName)!
        
        self.userType = loadController.currentUser?.type
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name, interests, school, or user type"
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 123/255, blue: 157/255, alpha: 1.0)
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredArray.count
        }
        return dataArray.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NetworkCell", forIndexPath: indexPath)
        var rowData: Dictionary<String,String>
        if searchController.active && searchController.searchBar.text != "" {
            rowData = filteredArray[indexPath.row]
            
           cell.textLabel?.text  = rowData["first-name"]! + " " + rowData["last-name"]!
            if rowData["interests"]!.lowercaseString.containsString(searchController.searchBar.text!.lowercaseString) {
                cell.detailTextLabel?.text = "Interests: " + rowData["interests"]!
            } else if rowData["school"]!.lowercaseString.containsString(searchController.searchBar.text!.lowercaseString){
                cell.detailTextLabel?.text = "School: " + rowData["school"]!
            } else if rowData["type"]!.lowercaseString.containsString(searchController.searchBar.text!.lowercaseString){
                cell.detailTextLabel?.text = rowData["type"]!
                
            } else{
                cell.detailTextLabel?.text = ""
            }
            
            return cell
            
        } else {
            rowData = dataArray[indexPath.row]
            cell.textLabel?.text = rowData["first-name"]! + " " + rowData["last-name"]!
            cell.detailTextLabel?.text = rowData["type"]
            return cell
        }
    }
    
    
    
    func filterContentForSearchText(searchText: String) {
        self.filteredArray = self.dataArray.filter({ item in
            
            return (item["first-name"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["last-name"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["type"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["school"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["interests"]!.lowercaseString.containsString(searchText.lowercaseString))
        })
        tableView.reloadData()
    }
    
    func searchController(controller: UISearchController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        self.filterContentForSearchText(searchString!)
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        let chatViewController = segue.destinationViewController as! MessageViewController
        chatViewController.senderId = authRef.currentUser?.uid
        chatViewController.senderDisplayName = self.senderDisplay //see if this works...
        
        //Initializing the chat window with selected user
        choiceIndex = tableView.indexPathForSelectedRow?.row
        var array: [Dictionary<String, String>]
        if searchController.active && searchController.searchBar.text != "" {
            array = filteredArray
        } else {
            array = dataArray
        }
        let name = array[choiceIndex!]["first-name"]! + " " + array[choiceIndex!]["last-name"]!
        chatViewController.title = name
        chatViewController.uidToChat = array[choiceIndex!]["uid"]!
        
        
    }
    
    
}

extension NewMessageInitViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}



