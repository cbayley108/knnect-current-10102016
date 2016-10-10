//
//  BlockedUsersTableViewController.swift
//  knnect
//
//  Created by Chris Bayley on 7/21/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class BlockedUsersTableViewController: NamesTemplateViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //Set the background color
        self.view.backgroundColor = UIColor.lightGrayColor()
        //Set section title in namestemplateviewcontroller
        super.sectionTitle1 = "All Users"
        super.sectionTitle2 = "Blocked Users"
        //Setup arrays for table view
        setArrays()
        //Change the title in the nav bar
        self.navigationItem.title = "Block Users"
    }
    
    override func setArrays() {
        //Sets the arrays in namestemplateviewcontroller to the values in load controller
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        //Mentor and student array are equal to all users minus the blocked users and self
        super.firstArray = loadController.mentorArray
        super.firstArray.appendContentsOf(loadController.studentArray)
        super.secondArray = loadController.blockedTableViewArray
        super.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Called when a user selects a cell
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Make sure it wasn't a secion title, ie row 0, that was selected
        if indexPath.row != 0{
            //Perform segue with the indexpath as sender so we know which data to present
            self.performSegueWithIdentifier("BlockedSelectedProfile", sender: indexPath)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        var fArray = firstArray
        var sArray = secondArray
        
        //If the user is searching reference the filtered arrays not the original versions
        if self.searchController.active && self.searchController.searchBar.text != "" {
            fArray = filteredFirstArray
            sArray = filteredSecondArray
        }
        
        //Segue to go to selected profile from blocked list
        if segue.identifier == "BlockedSelectedProfile"{
            let vc = segue.destinationViewController
            var rowData: [String: String]
            //Selected cell was in the first section and the first array is not empty
            if (sender as! NSIndexPath).section == 0 && !fArray.isEmpty{
                rowData = fArray[(sender as! NSIndexPath).row - 1]
                print("swagsawg")
                //This user has not been blocked because in first array, show block hide unblock
                (vc as! SelectedUserProfileViewController).showBlock = true
                (vc as! SelectedUserProfileViewController).showUnblock = false
            } else {
                //indexpath is off by one because the displayed array has one more cell for the section title
                rowData = sArray[(sender as! NSIndexPath).row - 1]
                //This user has been blocked because in second array, hide block show unblock
                (vc as! SelectedUserProfileViewController).showBlock = false
                (vc as! SelectedUserProfileViewController).showUnblock = true
            }
            
            //Set the user for the selecteduserprofile
            (vc as! SelectedUserProfileViewController).setUser(rowData)
            //Hide all the other buttons, show report
            (vc as! SelectedUserProfileViewController).toggleAccept(false)
            (vc as! SelectedUserProfileViewController).toggleKnnect(false)
            (vc as! SelectedUserProfileViewController).toggleKnnectStatus(false)
            (vc as! SelectedUserProfileViewController).showReport = true           
        }
        
    }


    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
