//
//  SelectedPostViewController.swift
//  knnect
//
//  Created by Chris Bayley on 7/19/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class SelectedPostViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate {

    @IBOutlet weak var commentTableView: UITableView!
    //Field to write comment
    @IBOutlet weak var commentField: UITextView!
    //Text which tells user to write a comment, hides when field has text
    @IBOutlet weak var commentFieldPlaceholder: UILabel!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
    //The height of the keyboard, set first time keyboard is opened
    var viewKeyboardHeight: CGFloat = 0
    //The height of the table view when there is no keyboard open, set first time keyboard is opened
    var viewDefaultHeight: CGFloat = 0
    var commentArray = [ ["name": "", "text": "", "senderId": "", "commentId": ""] ]
    var timer: NSTimer?
    var loading = true
    var postId: String?
    var commentRef: FIRDatabaseReference?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        commentTableView.delegate = self
        commentTableView.dataSource = self
        commentTableView.userInteractionEnabled = true
        commentTableView.hidden = true
        loadingIndicator.hidden = false
        loadingIndicator.startAnimating()
        commentField.delegate = self
        commentField.layer.borderWidth = 1.0
        commentField.layer.cornerRadius = 5.0
        commentField.layer.borderColor = UIColor.lightGrayColor().CGColor
        commentTableView.rowHeight = UITableViewAutomaticDimension
        commentTableView.estimatedRowHeight = 50
        //Listener to hide keyboard on tap
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (handleTap)))
        //Can not highlight cells
        commentTableView.allowsSelection = false
        commentRef = FIRDatabase.database().reference().child("posts").child(self.postId!).child("comments")
        loadArray()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    //Started when the table view should reload its data
    //NOTE: The firebas listener established by the loadarray method will remain active and change the loading value back to false once it hs finished updating
    func timerAction(){
        if(self.loading){
            return
        } else {
            self.commentTableView.reloadData()
            self.loadingIndicator.stopAnimating()
            self.loadingIndicator.hidden = true
            self.commentTableView.hidden = false
            timer?.invalidate()
        }
    }
    
    //Called when the user taps anwhere on the screen, hides keyboard
    func handleTap(sender: UITapGestureRecognizer) {
        if sender.state == .Ended {
            self.view.endEditing(true)
        }
        sender.cancelsTouchesInView = false
    }
    
    //By default a popover will be full screen on a phone and a popover on tablet, adding this function forces presented controller to always be a popover
    func adaptivePresentationStyleForPresentationController(
        controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    //Called once in viewdidload, creates firebase listener and stores comments in array
    func loadArray(){
        commentRef!.observeEventType(.Value, withBlock: {snapshot in
            self.commentArray.removeAll()
            var tempArray = ["name": "", "text": "", "senderId": ""]
            var count: UInt = 0
            let rootView = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
            for item in snapshot.children {
                count+=1
                if(!rootView.blockedArray.contains((item as! FIRDataSnapshot).value!["senderId"] as! String!)){
                    tempArray["name"] = (item as! FIRDataSnapshot).value!["name"] as! String!
                    tempArray["senderId"] = (item as! FIRDataSnapshot).value!["senderId"] as! String!
                    tempArray["text"] = (item as! FIRDataSnapshot).value!["text"] as! String!
                    tempArray["commentId"] = (item as! FIRDataSnapshot).key
                    self.commentArray.insert(tempArray, atIndex: 0)
                }
                if count == snapshot.childrenCount  {
                    self.loading = false
                }
            }
            if snapshot.childrenCount == 0 {
                self.loading = false
            }
        })
    }
    
    //Called when the keyboard is going to show
    func keyboardWillShow(notification: NSNotification){
        //Only true the first time this method has been called
        if(viewKeyboardHeight == 0){
            //Gets the frame for the keyboard
            var info = notification.userInfo!
            let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            //Stores the current height, with no keyboard showing, as the default height for the view
            viewDefaultHeight = self.view.frame.height
            //Stores the height of the view with a keyboard present
            viewKeyboardHeight = self.view.frame.height - keyboardFrame.height
            
        }
        //Sets the height for the view to the proper height with a keyboard on screen
        self.view.frame = CGRect(x: self.view.frame.minX,y: self.view.frame.minY, width: self.view.frame.width,height: viewKeyboardHeight)
    }
    
    //Called when the keyboard is going to hide
    func keyboardWillHide(notification: NSNotification){
        //Sets the height for the view back to the default
        self.view.frame = CGRect(x: self.view.frame.minX,y: self.view.frame.minY, width: self.view.frame.width, height: viewDefaultHeight)
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Called when the commentfield is changed
    func textViewDidChange(textView: UITextView) {
        //Hides the placeholder text if the commentfield has text
        commentFieldPlaceholder.hidden = commentField.hasText()
    }
    
    //Only one section
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    //Number of cells is equal to hthe length of the array
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.commentArray.count
    }
    
    //This method is called when the table view is loading its data, anytime reload data is called
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //Retrieves cell with identifier commenCell from the storyboard
        let cell = tableView.dequeueReusableCellWithIdentifier("commentCell", forIndexPath: indexPath) as! CommentCell
        
        // Configure the cell...
        
        //All the info for this cell
        let rowData = self.commentArray[indexPath.row]
        
        //Sets all the values in the cell
        cell.commentTextView?.text = rowData["text"]
        cell.nameLabel?.text = rowData["name"]
        //Shows delete if it is this users post
        if(rowData["senderId"] != FIRAuth.auth()?.currentUser!.uid){
            cell.showDelete = false
        } else {
            cell.showDelete = true
        }
        //If this picture has already been loaded once access it from the loadcontroller, otherwise download it
        if loadController.profilePics[rowData["senderId"]!] != nil{
            cell.profilePic.image = loadController.profilePics[rowData["senderId"]!]
        } else {
            downloadImage(rowData["senderId"]!)
        }
        cell.postId = self.postId
        cell.commentId = rowData["commentId"]
        cell.tableViewController = self
        cell.setupSwipeRecognizer()
        //Resizes the cell now that all the values have been set
        cell.resizeCell()
        return cell
    }
    
    //Method to load an image given a user's id
    func downloadImage(uid: String) {
        //NOTE: If the database is changed this url will be different and must be changed
        let picRef = FIRStorage.storage().referenceForURL("gs://knnect-1431b.appspot.com").child("images/" + uid)
        var image: UIImage?
        picRef.dataWithMaxSize(1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                self.loadController.profilePics.updateValue(UIImage(named:"Default Profile Pic")!, forKey: uid)
            } else {
                image = UIImage(data: data!)!
                self.loadController.profilePics.updateValue(image!, forKey: uid)
            }
        }
    }

    @IBAction func commentPressed(sender: AnyObject) {
        //Hide keyboard
        self.view.endEditing(true)
        //Checks if this post has been deleted
        if(loadController.feedArrayIds.containsObject(self.postId!)){
            if (commentField!.hasText()){
                // adds to Firebase
                let postItem = [
                    "text": commentField?.text as! AnyObject,
                    "senderId": FIRAuth.auth()?.currentUser?.uid as! AnyObject,
                    "name": (self.loadController.currentUser!.firstName as String) + " " + (self.loadController.currentUser!.lastName as String)
                ]
                let postRef = commentRef!.childByAutoId()
                postRef.setValue(postItem)
                //Clears the commentfield's text
                commentField?.text = ""
                commentFieldPlaceholder?.hidden = false
                //Data has been changed, should reload table view
                self.loading = true
                //Hides the table view and shows loading indicator
                self.commentTableView.hidden = true
                self.loadingIndicator.hidden = false
                self.loadingIndicator.startAnimating()
                //Will display the table view again once the new comment has been loaded in
                timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            }
        } else {
            //User's feed was old and current feed no longer contains that post, alerts user and reloads data
            let alert = UIAlertController(title: "Error", message: "This post was deleted", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                self.navigationController?.popViewControllerAnimated(true)
            }
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    //Called by a cell when its been deleted
    func deletePressed(){
        //Data has changed, should reload table view
        self.loading = true
        //Hides the table view and displays the loading indicator
        self.commentTableView.hidden = true
        self.loadingIndicator.hidden = false
        self.loadingIndicator.startAnimating()
        //Will display the table view again once the new comment has been loaded in
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
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

