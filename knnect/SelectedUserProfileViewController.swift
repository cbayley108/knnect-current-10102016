//
//  SelectedUserProfileViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/22/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase
import MessageUI
import TagListView

class SelectedUserProfileViewController: UITableViewController, MFMailComposeViewControllerDelegate, TagListViewDelegate {
    @IBOutlet weak var knnectStatus: UILabel!
    @IBOutlet weak var knnectButton: UIButton!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var disknnectButton: UIButton!
    @IBOutlet weak var reportUserButton: UIButton!
    @IBOutlet weak var blockUserButton: UIButton!
    @IBOutlet weak var unblockUserButton: UIButton!
    
    @IBOutlet weak var headline: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var userType: UILabel!
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var profPicView: UIImageView!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var interestsTagListView: TagListView!
    //Selected user profile will either display a grade or corporation, not both. These values use the same label since they are mutually exclusive
    @IBOutlet weak var corporationOrGradeLabel: UILabel!
    @IBOutlet weak var corporationOrGrade: UILabel!
    @IBOutlet weak var bioTextView: UITextView!
    @IBOutlet weak var numberOfKnnections: UILabel!
    
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
    let userPath = "user-info"
    let storageRef = FIRStorage.storage().referenceForURL("gs://knnect-1431b.appspot.com")
    var userRef: FIRDatabaseReference?
    
    var timer: NSTimer?
    
    //Following values are set before view loads by prepare for segue in preceding controllers
    var selectedUserRef: FIRDatabaseReference?
    var currentUser: UserInfo?
    var showKnnect: Bool?
    var showAccept: Bool?
    var showKnnectStatus: Bool?
    var statusLabel: String?
    var showBlock = false
    var showReport = false
    var showUnblock = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Must check if nil before attempting to change values because not all instances of this class will have all the buttons (selecting user profiles from blocked users will not have normal buttons)
        //Toggle all hidden values
        if knnectButton != nil{
           knnectButton.hidden = !(self.showKnnect!)
        }
        if reportUserButton != nil{
            reportUserButton.hidden = !(self.showReport)
        }
        if blockUserButton != nil{
            blockUserButton.hidden = !(self.showBlock)
        }
        if unblockUserButton != nil{
            unblockUserButton.hidden = !(self.showUnblock)
        }
        acceptButton.hidden = !(self.showAccept!)
        knnectStatus.hidden = !(self.showKnnectStatus!)
        //Change knnect status color to red if pending
        if(self.statusLabel == "Pending"){
            knnectStatus.text = "Knnection Pending"
            knnectStatus.textColor = UIColor(red: 236/255, green: 56/255, blue: 59/255, alpha: 1.0)
        } else {
            knnectStatus.text = self.statusLabel
        }
        //Toggle disknnect button based on whther knnected or not
        if(self.statusLabel == "Knnected"){
            disknnectButton.hidden = false
        } else{
            disknnectButton.hidden = true
        }
        //Setup intereststaglistview settings
        interestsTagListView.delegate = self
        interestsTagListView.textFont = UIFont.systemFontOfSize(20)
        interestsTagListView.alignment = .Center
        let seaBlue = UIColor(red: 5/255, green: 102/255, blue: 141/255, alpha: 1.0)
        interestsTagListView.tagBackgroundColor = seaBlue
        //Get the navigation bar
        let navItem = self.parentViewController!.parentViewController!.navigationItem
        //Create bar button for going back to previous screen which triggers action backButtn
        let back = UIBarButtonItem(title: "Back", style: .Plain, target: self, action: #selector(backButtn))
        //Set left bar button tot he back button just created
        navItem.setLeftBarButtonItem(back, animated: true)
        //Set firebase reference values
        self.userRef = FIRDatabase.database().reference().child(self.userPath).child((FIRAuth.auth()?.currentUser?.uid)!)
        self.selectedUserRef = FIRDatabase.database().reference().child(self.userPath).child(currentUser!.uid)
        //Displaye labels and profpic
        displayLabels()
        downloadImage()
    }
    
    //Sets all the texts for the labels
    func displayLabels(){
        //Sets all the label text from the currentuser 
        //NOTE: currentUser in this class refers to the selected user, not the current user signed in. Sorry.
        self.userType.text = self.currentUser?.type
        self.name.text = ((self.currentUser?.firstName)! + " " + (self.currentUser?.lastName)!)
        self.schoolLabel.text = (self.currentUser?.school)!
        self.numberOfKnnections.text = self.currentUser?.allUserInfo["numberOfKnnections"]
        self.bioTextView.text = self.currentUser?.allUserInfo["bio"]
        self.headline.text = self.currentUser?.allUserInfo["headline"]
        //Clear all tags
        interestsTagListView.removeAllTags()
        //Interests are stored in firebase separated by a comma and space, creates an array of the interests from the string stored in firebase with comma and string separating each value
        let interests = Set(self.currentUser!.allUserInfo["interests"]!.componentsSeparatedByString(", "))
        for item in interests {
            interestsTagListView.addTag(item)
        }
        //Control flow for which value to put for corporation/grade as well as major
        if self.currentUser?.type == "Mentor"{
            self.corporationOrGradeLabel.text = "Corporation"
            self.corporationOrGrade.text = self.currentUser!.allUserInfo["corporation"]!
            self.majorLabel.text = self.currentUser!.allUserInfo["major"]!
        }
        else if self.currentUser?.type == "Student"{
            self.corporationOrGradeLabel.text = "Grade"
            self.corporationOrGrade.text = self.currentUser!.allUserInfo["grade"]!
        }
        //Just updated all the labels so reload the display
        self.tableView.reloadData()
    }
    
    func downloadImage() {
        //Sets the profile pic from loadconroller if already loaded or downloads it here if hasn't been loaded yet
        if loadController.profilePics[self.currentUser!.uid] == nil{
            let picRef = storageRef.child("images/" + (self.currentUser?.uid)!)
            picRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
                if (error != nil) {
                    self.profPicView.image = UIImage(named:"Default Profile Pic")
                } else {
                    self.profPicView.image = UIImage(data: data!)
                }
            }
        } else{
            self.profPicView.image = loadController.profilePics[self.currentUser!.uid]!
        }
        
    }
    
    //Gives a height for each row
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //Height for first row with profi pic, name label, and knnect status
        if indexPath.row == 0{
            return 350
        }else if indexPath.row == 7{
            //Last row where the buttons are, knnection pending is only status where no buttons will display
            if(knnectStatus.text == "Knnection Pending"){
                return 0
            }
            //DEfault height if displaying a button
            return 44
        }else if indexPath.row == 1 {
            //Interests cell, calculates the height needed for the intereststaglistview
            let width = self.view.frame.width - 100
            var lines: CGFloat = 0
            var currentWidth: CGFloat = 0
            var height: CGFloat = 0
            for tag in self.interestsTagListView.tagViews {
                if(currentWidth + tag.frame.width > width){
                    lines += 1
                    currentWidth = tag.frame.width
                }else {
                    currentWidth += tag.frame.width
                }
                height = lines * tag.frame.height + lines * 6
            }
            return height + 60
        } else if indexPath.row == 3{
            //Major cell, height should be 0 if not a mentor
            if currentUser?.type == "Mentor" {
                return 84
            } else {
                return 0
            }
        }else if indexPath.row == 6 {
            //Bio cell, adjusts cell height based on sizethatfits given what the actual width will be (constraints will always make width of this textview the width of the view minus 100)
            let height = self.bioTextView.sizeThatFits(CGSize(width: (self.view.frame.width) - 100, height: self.bioTextView.frame.size.height)).height
            self.bioTextView.frame = CGRect(x: self.bioTextView.frame.minX, y: self.bioTextView.frame.minY, width: self.bioTextView.frame.width, height: height)
            return height + 60
        }else{
            //Default height for all other sections
            return 84
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Called when the user hits the bak button in the navbar
    func backButtn(){
        //Go back to the networks screen
        self.performSegueWithIdentifier("backToNetworks", sender: nil)
        let navItem = self.parentViewController!.parentViewController!.navigationItem
        //Remove the back button nav bar
        navItem.leftBarButtonItem = nil

    }

    @IBAction func knnectPressed(sender: AnyObject) {
        //Update the connections for both users
        self.userRef?.child("connections").child(currentUser!.uid).setValue("Pending")
        self.selectedUserRef?.child("connections").child((FIRAuth.auth()?.currentUser?.uid)!).setValue("Invited")
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        //Changed data, loadcontroller firebase listeners will trigger and set the value back to false
        loadController.loading = true
        //Checks for done loading, when loaded goes back to networks
         timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    @IBAction func acceptPressed(sender: AnyObject) {
        //Update the connection for both users
        self.userRef?.child("connections").child(currentUser!.uid).setValue("Knnected")
        self.selectedUserRef?.child("connections").child((FIRAuth.auth()?.currentUser?.uid)!).setValue("Knnected")
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        //Changed data, loadcontroller firebase listneres will trigger and set value back to false
        loadController.loading = true
        //Checks for done loading, when loaded goes back to networks
         timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    @IBAction func disknnectPressed(sender: AnyObject) {
        //Update the connections for both users
        self.userRef?.child("connections").child(currentUser!.uid).removeValue()
        self.selectedUserRef?.child("connections").child((FIRAuth.auth()?.currentUser?.uid)!).removeValue()
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        //Changed data, loadcontroller firebase listeners will change back to false
        loadController.loading = true
        //Checks for done loading, when loaded goes back to networks
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    @IBAction func reportUserPressed(sender: AnyObject) {
        //Displayes the email view or an error if not possible
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.presentViewController(mailComposeViewController, animated: true, completion: {
                
            })
        } else {
            self.showSendMailErrorAlert()
        }
        
        
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["appadmin@knodemy.com"])
        mailComposerVC.setSubject("REPORT USER")
        mailComposerVC.setMessageBody("This user is offensive because: \n \n [Your reason here]\n \n USER-ID [DO NOT ALTER]: " + self.currentUser!.uid, isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: {
           
        })
    }
    
  
    @IBAction func blockPressed(sender: AnyObject) {
          let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        //Updates the values of both users
        self.userRef?.child("blocked-users").child((currentUser?.uid)!).setValue((currentUser?.uid)!)
        self.selectedUserRef?.child("hidden-users").child((loadController.currentUser?.uid)!).setValue(loadController.currentUser?.uid)
        //Changed data, loadcontroller will change back to false
        loadController.loading = true
        //Checks for done loading, when loaded goes back to networks
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(blockedTimerAction), userInfo: nil, repeats: true)
    }
    
    @IBAction func unblockPressed(sender: AnyObject) {
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        //Updates the values of both users
        self.userRef?.child("blocked-users").child((currentUser?.uid)!).removeValue()
        self.selectedUserRef?.child("hidden-users").child((loadController.currentUser?.uid)!).removeValue()
        //Changed data, loadcontroller will change back to false
        loadController.loading = true
        //Checks for done loading, when loaded goes back to networks
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(blockedTimerAction), userInfo: nil, repeats: true)
    }
    
    //Different timer action because the segue to be performed is to different controller
    func blockedTimerAction(){
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        if(loadController.loading!){
            return
        } else {
            self.navigationController?.popViewControllerAnimated(true)
            (self.navigationController?.topViewController as? BlockedUsersTableViewController)?.setArrays()
            timer?.invalidate()
        }
    }
    
    //Timer action to transfer back to networks on loadcontroller done loading
    func timerAction(){
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        if(loadController.loading!){
            return
        } else {
            if(self.navigationController?.navigationBar.backItem != nil){
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                self.performSegueWithIdentifier("backToNetworks", sender: nil)
            }
            timer?.invalidate()
        }
    }

    
    func setUser(user: Dictionary<String, String>){
        self.currentUser = UserInfo(info: user)
    }
    
    func toggleKnnect(show: Bool){
        self.showKnnect = show
    }
    
    func toggleAccept(show: Bool){
        self.showAccept = show
    }
    
    func changeKnnectStatus(label: String){
        self.statusLabel = label
        self.showKnnectStatus = true
    }
    
    func toggleKnnectStatus(show: Bool){
        self.showKnnectStatus = show
    }
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "backToNetworks"{
            //Empty segue, must manually change frames
            let vc = segue.destinationViewController
            (vc as! NamesTemplateViewController).setArrays()
            self.parentViewController?.addChildViewController(vc)
            vc.view.frame = CGRect(x: 0,y: 0, width: self.view.frame.width,height: self.view.frame.height)
            self.parentViewController?.view.addSubview(vc.view)
            
            vc.didMoveToParentViewController(self.parentViewController)
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
