//
//  NamesTemplateViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/23/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

//Extend this class in other table views to display list of users, classes which extend are public/privatenetworktableviewcontroller and blockeduserstableviewcontroller

class NamesTemplateViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {

    let searchController = UISearchController(searchResultsController: nil)

    //Array for the second section
    var secondArray = [
        ["first-name": "", "type": "", "uid": ""]
    ]
    //Array for the first section
    var firstArray = [
        ["first-name": "", "type": "", "uid": ""]
    ]
    //Array for the filtered first array
    var filteredFirstArray = [
        ["first-name": "", "type": "", "uid": ""]
    ]
    //Array for the filtered second array 
    var filteredSecondArray = [
        ["first-name": "", "type": "", "uid": ""]
    ]
    //Section titles
    var sectionTitle1 = "Mentors"
    var sectionTitle2 = "Students"
    let userPath = "user-info"
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
    var pathRef: FIRDatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Create and set background color
        let ghostWhite = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0)
        self.view.backgroundColor = ghostWhite
        //Forces the search controller to hide upon tranistioning to new controller
        definesPresentationContext = true
        //Setup search controller
        searchController.searchBar.placeholder = "Search by name, interests, school, or user type"
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 123/255, blue: 157/255, alpha: 1.0)
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar


    }
    
    func setArrays(){ //TO be overriden
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    //Called when table view is loaded, functin informs how many sections are needed
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        var sections = 0;
        
        var fArray = self.firstArray
        var sArray = self.secondArray
        //If the user is searching reference the filtered arrays not the original versions
        if searchController.active && searchController.searchBar.text != "" {
            fArray = filteredFirstArray
            sArray = filteredSecondArray
        }

        //Increases number of connections for each nonempty array
        if(!sArray.isEmpty){
            sections += 1
        }
        if(!fArray.isEmpty){
            sections += 1
        }
        return sections
    }
    
    //Called when table view is loaded, functin informs how many rows are needed for a given section
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        var fArray = self.firstArray
        var sArray = self.secondArray
        //If the user is searching reference the filtered arrays not the original versions
        if searchController.active && searchController.searchBar.text != "" {
            fArray = filteredFirstArray
            sArray = filteredSecondArray
        }
        //section 0 can refer to the second array if the first is empty
        //NOTE: Adds 1 to array counts for the section titles
        if section == 0 {
            if(!fArray.isEmpty){
                return fArray.count + 1
            } else {
                return sArray.count + 1
            }
        } else {
            //Section 1 must always be the second array
            return sArray.count + 1
        }
    }
    
    
    //Function is called when the tableview reloads, creates a cell given the indexpath which contains the row and section
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        // Configure the cell...
        
        var rowData: [String: String]
        var fArray = firstArray
        var sArray = secondArray
        //If the user is searching reference the filtered arrays not the original versions
        if searchController.active && searchController.searchBar.text != ""{
            fArray = filteredFirstArray
            sArray = filteredSecondArray
        }
        //Must be within first array
        if !fArray.isEmpty && indexPath.section == 0 {
            if indexPath.row == 0 {
                //This cell is the section title
                let cell = tableView.dequeueReusableCellWithIdentifier("NetworkSectionTitleCell", forIndexPath: indexPath)
                cell.textLabel?.text = self.sectionTitle1
                if(self.sectionTitle1 == "Pending Knnections"){
                    cell.textLabel?.textColor = UIColor(red: 236/255, green: 56/255, blue: 59/255, alpha: 1.0)
                }
                cell.backgroundColor = UIColor.init(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
            //Sets the rowdata to be from the first array
            rowData = fArray[indexPath.row - 1]
            
        } else {
            if indexPath.row == 0 {
                //This cell is the ection title
                let cell = tableView.dequeueReusableCellWithIdentifier("NetworkSectionTitleCell", forIndexPath: indexPath)
                cell.textLabel?.text = self.sectionTitle2
                cell.backgroundColor = UIColor.init(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                return cell
            }
            //Sets the rowdata to be from the second array
            rowData = sArray[indexPath.row - 1]
        }
        //Already returned cells for section titles, create a normal cell and set values
        let cell = tableView.dequeueReusableCellWithIdentifier("NetworkCell", forIndexPath: indexPath)
        cell.textLabel?.text = rowData["first-name"]! + " " + rowData["last-name"]!
        cell.detailTextLabel?.text = rowData["type"]
        return cell
    }
    
    //Space between sections
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 3
    }
    
    
    func filterContentForSearchText(searchText: String) {
        self.filteredFirstArray = self.firstArray.filter({ item in
            
            return (item["first-name"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["last-name"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["type"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["interests"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["school"]!.lowercaseString.containsString(searchText.lowercaseString))
        })
        
        self.filteredSecondArray = self.secondArray.filter({ item in
            
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


}

extension NamesTemplateViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
