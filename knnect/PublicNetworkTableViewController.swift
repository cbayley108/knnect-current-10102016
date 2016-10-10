//
//  PublicNetworkTableViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/21/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class PublicNetworkTableViewController: NamesTemplateViewController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        //Sets the arrays in namestemplateviewconroller to the values in load controller
        super.firstArray = loadController.mentorArray
        if loadController.currentUser?.type == "Student"{
            super.secondArray = loadController.studentArray
        } else {
            super.secondArray = []
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    
    //Called when a user selects a cell
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Make sure it wasn't a section title, ie row 0, that was selected
        if(indexPath.row != 0){
            //Perform segue with the indexpath as sender so we know which data to present
            self.performSegueWithIdentifier("publicNetworkSelectedUser", sender: indexPath)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        var fArray = firstArray
        var sArray = secondArray
        
        //If the user is searching refernce the filtered arrays not the original versions
        if self.searchController.active && self.searchController.searchBar.text != "" {
            fArray = filteredFirstArray
            sArray = filteredSecondArray
        }
        
        //Dismiss the search bar
        searchController.dismissViewControllerAnimated(true, completion: nil)
        //Selected a user from the public network screen
        if segue.identifier == "publicNetworkSelectedUser"{
            let vc = segue.destinationViewController
            var rowData: [String: String]
            //Selected cell was in the first section and the first array is not empty
            if (sender as! NSIndexPath).section == 0 && !fArray.isEmpty{
                //indexpath is off by one because the displayed array has one more cell for the section title
                rowData = fArray[(sender as! NSIndexPath).row - 1]
            } else {
                rowData = sArray[(sender as! NSIndexPath).row - 1]
            }
            //Set the user for the selected user profile
            (vc as! SelectedUserProfileViewController).setUser(rowData)
            //check knnection status on the selected user by accessing firebase
            FIRDatabase.database().reference().child("user-info").child((FIRAuth.auth()?.currentUser?.uid)!).child("connections").child(rowData["uid"]!).observeSingleEventOfType(.Value, withBlock:{snapshot in
                if snapshot.value is NSNull {
                    //No connections between the users, show knnect and hide everything else
                    (vc as! SelectedUserProfileViewController).toggleKnnect(true)
                    (vc as! SelectedUserProfileViewController).toggleAccept(false)
                    (vc as! SelectedUserProfileViewController).toggleKnnectStatus(false)
                } else {
                    //Some connection exists so hide the knnect button
                    (vc as! SelectedUserProfileViewController).toggleKnnect(false)
                    //Change the knnect status to whatver the current status is
                    (vc as! SelectedUserProfileViewController).changeKnnectStatus(snapshot.value as! String)
                    if snapshot.value as! String == "Invited" {
                        //Invitation received from the other user so display accept
                        (vc as! SelectedUserProfileViewController).toggleAccept(true)
                    } else {
                        //Not invited, don't show accept button
                        (vc as! SelectedUserProfileViewController).toggleAccept(false)
                    }
              
                }
                //Segue used was an empt segue class because currently in container view, meaning we must manually display the next screen
                self.parentViewController?.addChildViewController(vc)
                vc.view.frame = CGRect(x: 0,y: 0, width: self.view.frame.width,height: self.view.frame.height)
                self.parentViewController?.view.addSubview(vc.view)
                
                
                vc.didMoveToParentViewController(self.parentViewController)
            })
            
        }
        
    }
    

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
