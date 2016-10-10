//
//  HomeFeedViewController.swift
//  knnect
//
//  Created by Jonathan Victorino on 6/27/16.
//  Copyright © 2016 Jonathan Victoirno. All rights reserved.
//



import UIKit
import Firebase

class HomeFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, UIPopoverPresentationControllerDelegate {
    
  
    @IBOutlet weak var postLabel: UILabel!
    @IBOutlet weak var postField: UITextView!
    @IBOutlet weak var postTableView: UITableView!
    @IBOutlet weak var writePostView: UIView!
    
    // Properties
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
    var feedArray = [ ["name": "", "text": "", "likes": ""] ]
    var filteredArray =  [ ["name": "", "text": "", "likes": ""] ]
    let searchController = UISearchController(searchResultsController: nil)
    //var choiceIndex: Int?
    var senderDisplay: String?
    var timer: NSTimer?
    var viewKeyboardHeight: CGFloat = 0
    var viewDefaultHeight: CGFloat = 0
    let uid = FIRAuth.auth()?.currentUser!.uid
    var refreshControl: UIRefreshControl!
    var writePostViewHeight: CGFloat = 0
    var showPostField = false
    
    //Function runs when the screen has been made and constraints applied
    override func viewDidLayoutSubviews() {
        //Default value is 0, stores the height for the write post box
        if writePostViewHeight == 0 {
            writePostViewHeight = writePostView.frame.height
        }
        //Should not show post
        if(!showPostField){
            //Constraints were just applied when this code is running, meaning the height for the table view is the default setting, which displays the write post box. Set the frame for the table view to be its own frame plus the height of the text box, set the height for the write post box to be 0
            postTableView.frame = CGRect(x: postTableView.frame.minX, y: postTableView.frame.minY, width: postTableView.frame.width,height: postTableView.frame.height + writePostViewHeight)
            writePostView.frame = CGRect(x: writePostView.frame.minX, y: writePostView.frame.maxY, width: writePostView.frame.width,height: 0)
        }
    }
    
    
    
    //View did appear
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        //Updates the feed when the screen appears
        timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    func timerAction(){
        if(loadController.loading!){
            return
        } else {
            //Load controller isn't loading, set the feed array to be what the load controller has
            self.feedArray = loadController.feedArray
            self.postTableView.reloadData()
            timer?.invalidate()
        }
    }
    
    
    //Called by the cells when they have been deleted, refreshes the displayed feed
    func deletePressed(){
        self.loadController.loading = true
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    //Fuction needed ot make popovers show on iPhones as well as iPads
    func adaptivePresentationStyleForPresentationController(
        controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
   
    
    @IBAction func commentPressed(sender: AnyObject) {
        //Linked to comment button in feed, sender is the uibutton
        //UIBUtton superview = inner content view, inner content view superview = content view, content view superview = post cell
        //If the feed still contains the post id for the selected cell, display the comments for that post
        if(loadController.feedArrayIds.containsObject(((sender as! UIButton).superview?.superview?.superview as! PostCell).postId)){
            performSegueWithIdentifier("presentComments", sender: sender)
        } else {
            //Postid no longer exists
            let alert = UIAlertController(title: "Error", message: "This post was deleted", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
            }
            
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)

            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            
        }
    }
    
    @IBAction func likePressed(sender: AnyObject) {
        //Linked to like button in feed, sender is the uibutton
        //UIBUtton superview = inner content view, inner content view superview = content view, content view superview = post cell
        //If the feed still contains the post id for the selected cell, display the comments for that post
        if(loadController.feedArrayIds.containsObject(((sender as! UIButton).superview?.superview?.superview as! PostCell).postId)){
            self.loadController.loading = true
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        } else {
            //Postid no longer exists
            let alert = UIAlertController(title: "Error", message: "This post was deleted", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
            }
            
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            
        }

    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if(segue.identifier == "presentComments"){
            //Sender is the comments button
            let postId = ((sender as! UIButton).superview?.superview?.superview as! PostCell).postId
            let vc = segue.destinationViewController
            (vc as! SelectedPostViewController).postId = postId
        } else if(segue.identifier == "selectedUser"){
            //User selected a user profile fomr the feed
            let vc = segue.destinationViewController
            //Sender is the postid for the selected post
            if(loadController.feedArrayIds.containsObject(sender as! String)) {
                FIRDatabase.database().reference().child("posts").child(sender as! String).child("senderId").observeSingleEventOfType(.Value, withBlock: {snapshot in
                    //Access the senderid for this post, do nothing if it is this user
                    if(snapshot.value! as? String == self.loadController.currentUser?.uid) {
                        return
                    }
                    //Firebase listener to access all the info for the selected user
                    FIRDatabase.database().reference().child("user-info").child(snapshot.value! as! String).observeSingleEventOfType(.Value, withBlock: {snapshot2 in
                        //User does not exist
                        if snapshot2.value is NSNull {
                            return
                        }
                        //Create user from snapshot
                        let user = UserInfo(snapshot: snapshot2)
                        //Mentor cannot view a student profile
                        if(user.type == "Student" && self.loadController.currentUser?.type == "Mentor"){
                            return
                        }
                        (vc as! SelectedUserProfileViewController).setUser(user.toAnyObject() as! Dictionary<String, String>)
                        //Some conenction exists between users
                        if let status = snapshot2.value!["connections"]??[(FIRAuth.auth()?.currentUser?.uid)!] as? String {
                            //Some connection exists, hide knnect button
                            (vc as! SelectedUserProfileViewController).toggleKnnect(false)
                            //NOTE: The status is the knnection status for the selected user
                            if status == "Pending" {
                                //Selected user added this user, display accept button
                                (vc as! SelectedUserProfileViewController).toggleAccept(true)
                                (vc as! SelectedUserProfileViewController).changeKnnectStatus("Invited")
                            } else {
                                //Selected user did not add this user, don't display accept button
                                (vc as! SelectedUserProfileViewController).toggleAccept(false)
                                //Current user added selected user
                                if(status == "Invited"){
                                    (vc as! SelectedUserProfileViewController).changeKnnectStatus("Pending")
                                } else {
                                    (vc as! SelectedUserProfileViewController).changeKnnectStatus("Knnected")
                                }
                            }
                        } else {
                            //No connection, display knnect, hide accept, hide knnect status
                            (vc as! SelectedUserProfileViewController).toggleKnnect(true)
                            (vc as! SelectedUserProfileViewController).toggleAccept(false)
                            (vc as! SelectedUserProfileViewController).toggleKnnectStatus(false)
                        }
                        self.navigationController?.pushViewController(vc, animated: true)
                    })
                })

            } else {
                //Postid no longer exists
                let alert = UIAlertController(title: "Error", message: "This post was deleted", preferredStyle: .Alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                }
                
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
                
                timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            }
        }
    }
    
    //Called when the user enters text into the write post box
    func textViewDidChange(textView: UITextView) {
        //Hide the placeholder text if the textview isn't empty
        postLabel.hidden = !textView.text.isEmpty
    }
    
    //Initializing Table Data
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.whiteColor()
        //Setup the table view
        postTableView.delegate = self
        postTableView.dataSource = self
        postTableView.userInteractionEnabled = true
        postTableView.rowHeight = UITableViewAutomaticDimension
        postTableView.estimatedRowHeight = 100
        postTableView.allowsSelection = false
        self.view.userInteractionEnabled = true
        //Setup post box
        postField.delegate = self
        postField.layer.borderWidth = 1.0
        postField.layer.cornerRadius = 5.0
        postField.layer.borderColor = UIColor.lightGrayColor().CGColor
        //Add tap listener to hide keyboard if necessary
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector (handleTap)))
        //Setup refresh functionality
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(HomeFeedViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        postTableView.addSubview(refreshControl)
        //Setup search bar
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = UIColor(red: 41/255, green: 123/255, blue: 157/255, alpha: 1.0)
        definesPresentationContext = true
        postTableView.tableHeaderView = searchController.searchBar
        //Set the array to be displayed to be the array in the load controller
        feedArray = loadController.feedArray
        //Adds observer to call functions when keyboard should hide/show
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name: UIKeyboardWillHideNotification, object: nil)
        //Start the timer to set the feed array if loading
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        
    }
    
    //Function is called by the refresh control when user pulls down
    func refresh(){
        //Start timer to reset feed array when done loading
        timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        self.refreshControl.endRefreshing()
    }
    
    //Called when the user taps anywhere on the screen
    func handleTap(sender: UITapGestureRecognizer) {
        //When the user has realeased tap
        if sender.state == .Ended {
            //End editing, hide keyboard
            self.view.endEditing(true)
        }
        sender.cancelsTouchesInView = false
    }
    
    //Called when the keybaord should show
    func keyboardWillShow(notification: NSNotification){
        //Default value is 0, only runs first time
        if(viewKeyboardHeight == 0){
            //Get the height for the keyboard
            var info = notification.userInfo!
            var keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            keyboardFrame = self.view.convertRect(keyboardFrame, fromView: nil)
            //Store the default height for the table view and the height for the table view if the keyboard is showing
            viewDefaultHeight = self.view.frame.height
            viewKeyboardHeight = self.view.frame.height - keyboardFrame.height
        }
        //Set the height for the table view to be the stored height if a keybaord is going to show
        self.view.frame = CGRect(x: self.view.frame.minX,y: self.view.frame.minY, width: self.view.frame.width,height: viewKeyboardHeight)
    }
    
    //Called when the keyboard is going to hide
    func keyboardWillHide(notification: NSNotification){
        //Set the height for the table view back to the default height
        self.view.frame = CGRect(x: self.view.frame.minX,y: self.view.frame.minY, width: self.view.frame.width, height: viewDefaultHeight)
    }
  
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    // MARK: - Table view data source
    
    //Only one section
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    //Number of rows is equal to
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Checl if search bar is active
        if searchController.active && searchController.searchBar.text != "" {
            return filteredArray.count
        }
        return self.feedArray.count
    }

    
    // loads cells from firebase
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PostCell", forIndexPath: indexPath) as! PostCell

        
        var rowData: Dictionary<String,String>
        //Set the row data from the proper array depending on whether search is active
        if searchController.active && searchController.searchBar.text != "" {
            rowData = filteredArray[indexPath.row]
        } else {
            rowData = self.feedArray[indexPath.row]
        }
        //Set the profile pic if its already been laoded, otherwise download the image
        if loadController.profilePics[rowData["senderId"]!] != nil{
            cell.profPicView.image = loadController.profilePics[rowData["senderId"]!]
        } else {
            downloadImage(rowData["senderId"]!)
        }
        //Set values for the cell
        cell.postLabel?.text = rowData["text"]
        cell.nameLabel?.text = rowData["name"]
        cell.likesLabel?.text = rowData["likes"]
        cell.userTypeLabel?.text = rowData["headline"]
        cell.postId = rowData["postId"]
        if(rowData["timestamp"] != nil){
            cell.timestampLabel?.text = rowData["timestamp"]
        }
        //Toggle displaying delete button if the post was made by user
        if(rowData["senderId"] != FIRAuth.auth()?.currentUser!.uid){
            cell.showDelete = false
        } else {
            cell.showDelete = true
        }
        
        cell.tableViewController = self
        //Start an observer if the user lng presses on a posts porifle picture to select the user
        cell.setProfPicListener()
        cell.updateLikeButton()
        cell.resizeCell()
        return cell
    }
    
    //Function to download images from firebase
    func downloadImage(uid: String) {
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

    //Filter the feed array based on a given text
    func filterContentForSearchText(searchText: String) {
        self.filteredArray = self.feedArray.filter({ item in
            
            return (item["name"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["school"]!.lowercaseString.containsString(searchText.lowercaseString) ||
                item["text"]!.lowercaseString.containsString(searchText.lowercaseString))
        })
        feedArray = loadController.feedArray
        postTableView.reloadData()
    }
    
    func searchController(controller: UISearchController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        self.filterContentForSearchText(searchString!)
        return true
    }

    // adds a post
    @IBAction func newPostPressed(sender: AnyObject) {
        //Close the writePostView
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()
        showPostField = false
        //This will trigger the viewdidlayoutsubviews if the keybaord is showing
        self.view.endEditing(true)
        
        if (postField!.hasText()){
            // adds to Firebase
            let itemRef = loadController.postRef!.childByAutoId()
            let rootView = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
            //Store all the data into an array

            let postItem = [
                "text": postField?.text as! AnyObject,
                "senderId": self.uid as! AnyObject,
                "name": (rootView.currentUser!.firstName as String) + " " + (rootView.currentUser!.lastName as String),
                "headline": rootView.currentUser!.allUserInfo["headline"]!,
                "likes": 0 as AnyObject,
                "timestamp": FIRServerValue.timestamp()
            ]
            //Set the value in firebase to be the array
            itemRef.setValue(postItem)
            //Reset the text, display the placeholder
            postField?.text = ""
            postLabel?.hidden = false
            //Start a timer to reload all the data
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        }
        //Hide the write post box
        //NOTE: The write post box will be hidden automaticaly if the keyboard was displayed because viewdidlayoutsubviews will be called. This is to catch times when the user posts with no keyboard present
        UIView.animateWithDuration(0.2, animations: {
            self.writePostView.frame = CGRect(x: self.writePostView.frame.minX, y: self.writePostView.frame.maxY, width: self.writePostView.frame.width, height: 0)
            self.postTableView.frame = CGRect(x: self.postTableView.frame.minX, y: self.postTableView.frame.minY, width: self.postTableView.frame.width,height: self.postTableView.frame.height + self.writePostViewHeight)
        })
    }
    
    
    @IBAction func addPressed(sender: AnyObject) {
        if(!showPostField){
            //User hit plus to OPEN writePostView
            showPostField = true
            //Change color of add button
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.lightGrayColor()
            //Resize table view, display keyboard
            UIView.animateWithDuration(0.2, animations: {
                self.writePostView.frame = CGRect(x: self.writePostView.frame.minX, y: self.writePostView.frame.minY - self.writePostViewHeight, width: self.writePostView.frame.width, height: self.writePostViewHeight)
                self.postTableView.frame = CGRect(x: self.postTableView.frame.minX, y: self.postTableView.frame.minY, width: self.postTableView.frame.width,height: self.postTableView.frame.height - self.writePostViewHeight)
            })
        } else {
            //User hit plus to CLOSE writePostView
            showPostField = false
            //Hide keyboard, change color of add button
            self.view.endEditing(true)
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()
            //Resize table view, hide keyboard
            UIView.animateWithDuration(0.2, animations: {
                self.writePostView.frame = CGRect(x: self.writePostView.frame.minX, y: self.writePostView.frame.maxY, width: self.writePostView.frame.width, height: 0)
                self.postTableView.frame = CGRect(x: self.postTableView.frame.minX, y: self.postTableView.frame.minY, width: self.postTableView.frame.width,height: self.postTableView.frame.height + self.writePostViewHeight)
            })
        }
    }
    
}
extension HomeFeedViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}
