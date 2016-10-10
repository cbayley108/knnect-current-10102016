//
//  MentorSignUpViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/8/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase
import TagListView

class MentorSignUpViewController: UITableViewController, UITextFieldDelegate, TagListViewDelegate {

    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var schoolField: UITextField!
    @IBOutlet weak var corporationField: UITextField!
    @IBOutlet weak var tagListView: TagListView!
    @IBOutlet weak var bioField: UITextView!
    @IBOutlet weak var majorTextField: UITextField!

    @IBOutlet weak var headlineField: UITextField!
    @IBOutlet weak var UserAgreementTextView: UITextView!
    
    @IBOutlet weak var userAgreementSwitch: UISwitch!
    let userPath = "user-info"
    var userRef: FIRDatabaseReference?
    var interestsArray = [""]
    var selectedInterests = Set<String>()
    var timer: NSTimer?
    var defaultTexts = ["first-name": "", "last-name": "", "school": "", "corporation": "", "interests": "", "bio": ""]

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setting up interestsArray
        waitingFunction()
        //Setup taglistview settings
        tagListView.textFont = UIFont.systemFontOfSize(24)
        tagListView.alignment = .Center
        tagListView.tagBackgroundColor = UIColor.grayColor()
        tagListView.delegate = self
        setDefaultTexts()
        //Listens for tap to close keyboard if currently open
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (handleTap)))
        self.userRef = FIRDatabase.database().reference().child(self.userPath).child((FIRAuth.auth()?.currentUser?.uid)!)
 
    }
    
    
    func tagPressed(title: String, tagView: TagView, sender: TagListView) {
        if !tagView.selected{
            tagView.selected = true
            tagView.tagBackgroundColor = UIColor.blueColor()
            selectedInterests.insert(title)
        } else{
            tagView.selected = false
            tagView.tagBackgroundColor = UIColor.grayColor()
            selectedInterests.remove(title)
        }
    }

    
    func setDefaultTexts(){
        firstNameField.text = self.defaultTexts["first-name"]
        lastNameField.text = self.defaultTexts["last-name"]
        schoolField.text = self.defaultTexts["school"]
        corporationField.text = self.defaultTexts["corporation"]
        majorTextField.text = self.defaultTexts["major"]
        bioField.text = self.defaultTexts["bio"]
        headlineField.text = self.defaultTexts["headline"]
        bioField.layer.borderColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.4).CGColor
        bioField.layer.borderWidth = 1.0
        bioField.layer.cornerRadius = 5.0
        if (self.defaultTexts["interests"]! != ""){
            selectedInterests = Set(defaultTexts["interests"]!.componentsSeparatedByString(", "))
        }
        for item in interestsArray{
            if selectedInterests.contains(item){
                tagListView.addTag(item).selected = true
            } else{
                tagListView.addTag(item)
            }
        }
        //Creates an attributed string so that we may add links to parts of the text
        let agreementsLinks = NSMutableAttributedString(string: "I have read and accept the Terms of Service and the Privacy Policy")
        //Set font and color
        agreementsLinks.addAttribute(NSFontAttributeName, value: UIFont(name: "Avenir", size: 17.0)!, range: NSMakeRange(0, agreementsLinks.length))
        agreementsLinks.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 5/255, green: 102/255, blue: 141/255, alpha: 1.0), range: NSMakeRange(0, agreementsLinks.length))
        //Adds a link for the Privacy Policy (starts at index of 52, length 14)
        agreementsLinks.addAttribute(NSLinkAttributeName, value: "http://www.google.com", range: NSMakeRange(52, 14))
        //Adds a link for the Terms of Service (starts at index of 27, length 16)
        agreementsLinks.addAttribute(NSLinkAttributeName, value: "http://www.google.com", range: NSMakeRange(27, 16))
        //Set the text for the user agreement
        if(UserAgreementTextView != nil){
            UserAgreementTextView.userInteractionEnabled = true
            UserAgreementTextView.attributedText = agreementsLinks
        }
    }
 
    //Triggerred any time the user taps the screen
    func handleTap(sender: UITapGestureRecognizer) {
        //User has realeased tap
        if sender.state == .Ended {
            //No longer editing, hides keyboard
            self.view.endEditing(true)
        }
        sender.cancelsTouchesInView = false
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //Called when the user hits the save button by editing an existing profile
    @IBAction func editSavePressed(sender: AnyObject) {
        //Checks if all fields have been completed
        let fieldsArray = [ firstNameField, lastNameField, schoolField, corporationField, majorTextField, headlineField]
        var fieldsCompleted = true
        for item in fieldsArray{
            fieldsCompleted = fieldsCompleted && (item.hasText())
        }
        fieldsCompleted = fieldsCompleted && (bioField.hasText()) && selectedInterests.count > 0
        
        //Check if any of the fields were changed
        var fieldsChanged = true
        if(firstNameField.text == defaultTexts["first-name"] &&
            lastNameField.text == defaultTexts["last-name"] &&
            schoolField.text == defaultTexts["school"] &&
            majorTextField.text == defaultTexts["major"] &&
            corporationField.text == defaultTexts["corporation"] &&
            headlineField.text == defaultTexts["headline"] &&
            selectedInterests == Set(defaultTexts["interests"]!.componentsSeparatedByString(", ")) &&
            bioField.text == defaultTexts["bio"]){
            fieldsChanged = false
        }
        
        if fieldsCompleted {
            if fieldsChanged{
                self.userRef!.child("first-name").setValue(firstNameField.text)
                self.userRef!.child("last-name").setValue(lastNameField.text)
                self.userRef!.child("school").setValue(schoolField.text)
                self.userRef!.child("major").setValue(majorTextField.text)
                self.userRef!.child("corporation").setValue(corporationField.text)
                self.userRef!.child("bio").setValue(bioField.text)
                self.userRef!.child("headline").setValue(headlineField.text)
                self.userRef!.child("interests").setValue(Array(selectedInterests).joinWithSeparator(", "))
                self.userRef!.child("type").setValue("Mentor")
            }
           
            
            let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
            //Load controller will only need to load if the fields were changed
            loadController.loading = fieldsChanged
            //We've changed info in user-info of current user, triggering the loadscreen's listener in createuser which will change loading back to false once it has finished updating
            //Start timer to update display when done loading
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            
        } else {
            //Send alert for missing fields
            let alert = UIAlertController(title: "Missing fields", message: "You have not completed all required fields.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
            }
            
            alert.addAction(okAction)
            
            self.presentViewController(alert,animated: true, completion: nil)
        }

    }
    
    //Called after changing info in firebase
    func timerAction(){
        let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
        if(loadController.loading!){
            return
        } else {
            //Go back to previous screen
            self.navigationController?.popViewControllerAnimated(true)
            //Go to the last view controller of this viewcontrollers navigation controller, which will always be the profile page, update the labels
            (self.navigationController?.viewControllers[(self.navigationController?.viewControllers.count)! - 1] as! ProfileViewController).displayLabels()
            //Stop timer
            timer?.invalidate()
        }
        
    }
    
    //Gives values for height of speecific rows in the tableview
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //interests cell
        if indexPath.row == 2 {
            //Calculates the height needed for the tag list view
            let width = self.view.frame.width - 100
            var lines: CGFloat = 0
            var currentWidth: CGFloat = 0
            var height: CGFloat = 0
            for tag in tagListView.tagViews {
                if(currentWidth + tag.frame.width > width){
                    lines += 1
                    currentWidth = tag.frame.width
                }else {
                    currentWidth += tag.frame.width
                }
                height = lines * tag.frame.height + lines * 8
            }
            return height + 50
        }else if indexPath.row == 6 {
            //bio cell
            return 162
        }else{
            //All other cells
            return 84
        }
    }
    
    //Called when user is setting information for the first time through the main storyboard
    @IBAction func savePressed(sender: AnyObject) {
        //Checks if all fields have been completed
        let fieldsArray = [ firstNameField, lastNameField, schoolField, corporationField, majorTextField]
        var fieldsCompleted = true
        for item in fieldsArray{
            fieldsCompleted = fieldsCompleted && (item.hasText())
        }
        fieldsCompleted = fieldsCompleted && (bioField.hasText()) && userAgreementSwitch.on && selectedInterests.count > 0
        
        if fieldsCompleted{
            //Store all fields into the default texts array, no reason for it to be the defualt texts array we just need an array to hold all the info and defualtTexts conveniently has all the correct keys
            self.defaultTexts["first-name"] = firstNameField.text
            self.defaultTexts["last-name"] = lastNameField.text
            self.defaultTexts["school"] = schoolField.text
            self.defaultTexts["major"] = majorTextField.text
            self.defaultTexts["corporation"] = corporationField.text
            self.defaultTexts["headline"] = headlineField.text
            self.defaultTexts["interests"] = Array(selectedInterests).joinWithSeparator(", ")
            self.defaultTexts["type"] = "Mentor"
            self.defaultTexts["bio"] = bioField.text
            //Must store all user-info simultaneously using an array, not field by field, because when partially completed user-info struct in database is accessed by other users it will find nil and crash
            self.userRef!.setValue(self.defaultTexts)
            //Proceed to the knnect storyboard
            let storyboard = UIStoryboard(name:"Knnect", bundle: nil)
            let controller = storyboard.instantiateInitialViewController()! as UIViewController
            self.presentViewController(controller, animated: true, completion: nil)
            
        } else {
            //Send alert for missing fields
            let alert = UIAlertController(title: "Missing fields", message: "You have not completed all required fields.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
            }
            alert.addAction(okAction)
            self.presentViewController(alert,animated: true, completion: nil)
        }
        
    }
    
    
    func waitingFunction()
    {
        //set a lock during your async function
        var locked = true
        
        FIRDatabase.database().reference().child("interests").observeSingleEventOfType(.Value, withBlock: { snapshot in
                self.interestsArray = snapshot.value as! [String]
            locked = false
            })
        
        //wait for the async method to complete before advancing
        while(locked){wait()}
    }
    func wait()
    {
        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: 0.1))
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
