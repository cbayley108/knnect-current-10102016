//
//  ProfileViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/8/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase
import TagListView

class ProfileViewController: UITableViewController, UIPopoverPresentationControllerDelegate, TagListViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var firstName: UILabel!
    @IBOutlet weak var userType: UILabel!
    @IBOutlet weak var school: UILabel!
    @IBOutlet weak var interests: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var interestsTagListView: TagListView!
    @IBOutlet weak var corporationOrGradeLabel: UILabel!
    @IBOutlet weak var headline: UILabel!
    @IBOutlet weak var corporationOrGrade: UILabel!
    @IBOutlet weak var numberOfKnnections: UILabel!
    @IBOutlet weak var bio: UITextView!
    @IBOutlet weak var profPicView: UIImageView!
    @IBOutlet weak var editPicButton: UIButton!
    
    
    
    
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
    var currentUser: UserInfo?
    let storageRef = FIRStorage.storage().referenceForURL("gs://knnect-1431b.appspot.com")
    let imagePicker = UIImagePickerController()
    var imageToUpload : UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayLabels()
        imagePicker.delegate = self
        downloadImage()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //Reset display every time view appears
        interestsTagListView.delegate = self
        interestsTagListView.textFont = UIFont.systemFontOfSize(20)
        interestsTagListView.alignment = .Center
        let seaBlue = UIColor(red: 5/255, green: 102/255, blue: 141/255, alpha: 1.0)
        interestsTagListView.tagBackgroundColor = seaBlue
        displayLabels()
    }
    
    
    
    func displayLabels(){
        //Load in user and set all label values
        self.currentUser = loadController.currentUser
        self.userType.text = self.currentUser?.type
        self.firstName.text = ((self.currentUser?.firstName)! + " " + (self.currentUser?.lastName)!)
        self.school.text = (self.currentUser?.school)!
        self.numberOfKnnections.text = String(loadController.acceptedArray.count)
        self.bio.text = self.currentUser?.allUserInfo["bio"]
        self.headline.text = self.currentUser?.allUserInfo["headline"]
        interestsTagListView.removeAllTags()
        let interests = Set(self.currentUser!.allUserInfo["interests"]!.componentsSeparatedByString(", "))
        for item in interests {
            interestsTagListView.addTag(item)
        }
        //Shared label for corporation/grade because only one will be displayed at a time
        if self.currentUser?.type == "Mentor"{
            self.corporationOrGradeLabel.text = "Corporation"
            self.corporationOrGrade.text = self.currentUser!.allUserInfo["corporation"]!
            self.majorLabel.text = self.currentUser!.allUserInfo["major"]!
        }
        else if self.currentUser?.type == "Student"{
            self.corporationOrGradeLabel.text = "Grade"
            self.corporationOrGrade.text = self.currentUser!.allUserInfo["grade"]!
        }
        //Reload the table view
        self.tableView.reloadData()
    }
    
    //Heights for each row
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0{
            //Height for first row with prof pic and name
            return 350
        }else if indexPath.row == 1 {
            //Height for the interests section
            //NOTE: In selcted user profile we calculate the height needed but here we get the max y coordinate of the last tag in the taglist view. This doesn't work in the selected user profile because at the time that this function runs it will not have the correct width and the rows will be too long
            let lastTag = self.interestsTagListView.tagViews[self.interestsTagListView.tagViews.count - 1]
            return lastTag.superview!.superview!.frame.maxY + 50
        } else if indexPath.row == 3{
            //Major cell, height should be 0 if not a mentor
            if currentUser?.type == "Mentor" {
                return 84
            } else {
                return 0
            }
        }else if indexPath.row == 6 {
            //Bio cell, adjusts cell height based on sizethatfits given what the actual width will be (constraints will always make width of this textview the width of the view minus 100)
            let height = bio.sizeThatFits(CGSize(width: (self.view.frame.width) - 100, height: bio.frame.size.height)).height
            bio.frame = CGRect(x: bio.frame.minX, y: bio.frame.minY, width: bio.frame.width, height: height)
            return height + 75
        }else{
            //Default height for all other sections
            return 84
        }
    }
    
    
    //Called when the user hits the settings button in the nav bar
    @IBAction func settingsPressed(sender: AnyObject) {
        //Create the view controller to be displayed as a popover
        let storyboard : UIStoryboard = UIStoryboard(
            name: "Knnect",
            bundle: nil)
        let menuViewController: ProfileMenuViewController = storyboard.instantiateViewControllerWithIdentifier("ProfileMenuViewController") as! ProfileMenuViewController
        menuViewController.modalPresentationStyle = .Popover
        //Set the preferred size, fits three buttons
        menuViewController.preferredContentSize = CGSizeMake(110, 110)
        let popoverMenuViewController = menuViewController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = .Any
        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.sourceView = self.view
        //Set the popover to display from a bar button
        popoverMenuViewController?.barButtonItem = self.navigationItem.rightBarButtonItem
        menuViewController.vc = self
        self.presentViewController(menuViewController, animated: true, completion: nil)
    }
    
    //Called when the user hits the edit button on their prof pic
    @IBAction func loadImagePicker(sender: AnyObject) {
        if editPicButton.currentTitle == "Edit"{
            //Displays an image picker form the user's library
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .PhotoLibrary
            presentViewController(imagePicker, animated: true, completion: nil)
        } else{
            //The edit button is now the save button, user has saved the image
            self.uploadImage(self.imageToUpload!)
            self.editPicButton.setTitle("Edit", forState: .Normal)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profPicView.image = pickedImage
            imageToUpload = pickedImage
        }
        
        dismissViewControllerAnimated(true, completion: {
            self.editPicButton.setTitle("Save", forState: .Normal)
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func downloadImage() {
        if loadController.profilePics[loadController.currentUser!.uid] == nil{
            let picRef = storageRef.child("images/" + (loadController.currentUser?.uid)!)
            
            picRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
                if (error != nil) {
                    self.profPicView.image = UIImage(named:"Default Profile Pic")
                } else {
                    self.profPicView.image = UIImage(data: data!)
                }
            }
        } else{
            self.profPicView.image = loadController.profilePics[loadController.currentUser!.uid]
        }
        
    }
    
    func uploadImage(image:UIImage){
        
        let localFile = UIImageJPEGRepresentation(image, 0.001)
        let picRef = self.storageRef.child("images/" + (self.loadController.currentUser?.uid)!)
        
        picRef.putData(localFile!, metadata: nil) { metadata, error in
            if (error != nil) {
                // Uh-oh, an error occurred!
            } else {
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata!.downloadURL
            }
        }
        loadController.profilePics.updateValue(image, forKey: loadController.currentUser!.uid)
    }
    
    //Function so popover displays on all phone types
    func adaptivePresentationStyleForPresentationController(
        controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    //Called by the popover vc when the user selects the edit button from the menu
    func editProfile(){
        if(currentUser?.type == "Student"){
            self.performSegueWithIdentifier("editStudent", sender: nil)
        } else if (currentUser?.type == "Mentor"){
            self.performSegueWithIdentifier("editMentor", sender: nil)
        }
    }
    
    //Called by the popover vc when the user selects the sign out button from the menu
    func signOut(){
        try! FIRAuth.auth()?.signOut()
        currentUser = nil
        let storyboard = UIStoryboard(name:"Main", bundle: nil)
        let controller = storyboard.instantiateInitialViewController()! as UIViewController
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    //Called by the popover vc when the user selects the blocked users button from the menu
    func blockPressed(){
        self.performSegueWithIdentifier("presentBlockedUsers", sender: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "editStudent" || segue.identifier == "editMentor"){
            let vc = segue.destinationViewController
            vc.navigationItem.title = "Edit Profile"
            //Set the default texts to be the current user's information
            if(segue.identifier == "editStudent"){
                let studentVC = vc as! StudentSignUpViewController
                studentVC.defaultTexts["first-name"] = self.currentUser?.firstName!
                studentVC.defaultTexts["last-name"] = self.currentUser?.lastName!
                studentVC.defaultTexts["school"] = self.currentUser?.school!
                studentVC.defaultTexts["grade"] = self.currentUser?.allUserInfo["grade"]
                studentVC.defaultTexts["interests"] = self.currentUser?.allUserInfo["interests"]
                studentVC.defaultTexts["bio"] = self.currentUser?.allUserInfo["bio"]
                studentVC.defaultTexts["headline"] = self.currentUser?.allUserInfo["headline"]
            } else {
                let mentorVC = vc as! MentorSignUpViewController
                mentorVC.defaultTexts["first-name"] = self.currentUser?.firstName!
                mentorVC.defaultTexts["last-name"] = self.currentUser?.lastName!
                mentorVC.defaultTexts["school"] = self.currentUser?.school!
                mentorVC.defaultTexts["major"] = self.currentUser?.allUserInfo["major"]
                mentorVC.defaultTexts["corporation"] = self.currentUser?.allUserInfo["corporation"]
                mentorVC.defaultTexts["interests"] = self.currentUser?.allUserInfo["interests"]
                mentorVC.defaultTexts["bio"] = self.currentUser?.allUserInfo["bio"]
                mentorVC.defaultTexts["headline"] = self.currentUser?.allUserInfo["headline"]
            }
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
