//
//  MessagesContainer.swift
//  knnect
//
//  Created by Charles Yu on 6/21/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase
/** This is the class for 'Existing Messages' in chat. It keeps track of the pre-existing messages the user currently has going on, and initializes the MessagesViewController(The actual chat mechanism) upon selection.
 **/

class MessagesInitViewController:  UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate{
    
    let authRef = FIRAuth.auth()!
    let rootRef = FIRDatabase.database().reference()
    var dataArray = [ ["first-name": "", "last-name": "", "type": "", "uid": ""] ] //Array of unfiltered search results
    var filteredArray =  [ ["first-name": "", "last-name": "", "type": "", "uid": ""] ] //Array of filtered search results
    var choiceIndex: Int? //The index of the cell selected
    var senderDisplay: String? //The value to be passed as MessagesViewController's .senderDisplay
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController //Shortcut to loadscreen
    var userType: String?
    let searchController = UISearchController(searchResultsController: nil)
    var timer: NSTimer?
    
    //View did appear
    override func viewDidAppear(animated: Bool){
        
        super.viewDidAppear(animated)
        self.navigationItem.hidesBackButton = true;
        
        //Stalls for loading time: Timer reloads data when necessary, runs the timerAction every interval until timer invalidated
        timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    //Action checks loadcontroller's loading status and invalidates timer when loading is complete
    func timerAction(){
        if(loadController.loading!){
            return
        } else {
            self.dataArray = loadController.messageDataArray
            self.tableView.reloadData()
            timer?.invalidate()
        }
    }
    
    
    //Initializing Table Data
    override func viewDidLoad(){
        super.viewDidLoad()
        self.senderDisplay = (loadController.currentUser?.firstName)! + " " + (loadController.currentUser?.lastName)!
        self.userType = loadController.currentUser?.type
        
        //Setting up search controller
        searchController.searchBar.placeholder = "Search by name, interests, school, or user type"
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 123/255, blue: 157/255, alpha: 1.0)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    //Returns the proper count of cells for the table view depending on whether search is active
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.active && searchController.searchBar.text != "" {
            return filteredArray.count
        }
        return dataArray.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> messagesInitTableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("NetworkCell", forIndexPath: indexPath) as! messagesInitTableViewCell
        
        var rowData: Dictionary<String,String>
        
        //If control flow for search active
        if searchController.active && searchController.searchBar.text != "" {
            rowData = filteredArray[indexPath.row] //setting the table's data source as the filtered array
            
            cell.name.text = rowData["first-name"]! + " " + rowData["last-name"]!
            cell.type.text = rowData["type"]!
            if rowData["interests"]!.lowercaseString.containsString(searchController.searchBar.text!.lowercaseString) {
                cell.lastMessage.text = "Interests: " + rowData["interests"]!
            } else if rowData["school"]!.lowercaseString.containsString(searchController.searchBar.text!.lowercaseString){
                cell.lastMessage.text = "School: " + rowData["school"]!
            }else if rowData["last-message"] != nil{
                cell.lastMessage.text = rowData["last-message"]!
                
            } else{
                cell.lastMessage.text = ""
            }
            
            // Hides/Unhides unreadNotifier depending on conversation read status
            if rowData["read"] == "true"{
                cell.unreadNotifier.hidden = true
            } else{
                cell.unreadNotifier.hidden = false
            }
            return cell
        
            
        //Else control flow for search inactive
        } else {
            rowData = dataArray[indexPath.row] //setting the table's data source as the unfiltered array
            
            cell.name.text = rowData["first-name"]! + " " + rowData["last-name"]!
            cell.type.text = rowData["type"]!
            if rowData["last-message"] != nil{
                cell.lastMessage.text = rowData["last-message"]!
            }
            
            // Hides/Unhides unreadNotifier depending on conversation read status
            if rowData["read"] == "true"{
                cell.unreadNotifier.hidden = true
            } else{
                cell.unreadNotifier.hidden = false
            }
            return cell
            
        }
    }
    
    //Defining what fields the search bar will match
    func filterContentForSearchText(searchText: String) {
        self.filteredArray = self.dataArray.filter({ item in
            
            return (item["first-name"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["last-name"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["type"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["interests"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["school"]!.lowercaseString.containsString(searchText.lowercaseString))
        })
        tableView.reloadData()
    }
    
    func searchController(controller: UISearchController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        self.filterContentForSearchText(searchString!)
        return true
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        if segue.identifier == "toChat"{
            
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
    
    
}

extension MessagesInitViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

