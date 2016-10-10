//
//  PostCell.swift
//  knnect
//
//  Created by Jonathan Victorino on 6/30/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//



import UIKit
import Firebase

class PostCell: UITableViewCell, UIPopoverPresentationControllerDelegate {


   
    @IBOutlet weak var userTypeLabel: UILabel!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var postLabel: UITextView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var likesImage: UIImageView!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var profPicView: UIImageView!
    @IBOutlet weak var innerView: UIView!
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController
    
    var tableViewController: UIViewController!
    var postId: String!
    var showDelete: Bool!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func LikePressed(sender: AnyObject){
        //Check if post was deleted
        if(loadController.feedArrayIds.containsObject(postId)){
            if(loadController.likedPostsArray[postId] == nil) {
                //Adds this user to list of user who like this post, stored under posts and postid
                FIRDatabase.database().reference().child("posts").child(postId).child("like-list").child((loadController.currentUser?.uid!)!).setValue(FIRServerValue.timestamp())
                //Adds this post to the list of posts liked by this user, stored under user-info and liked-posts
                FIRDatabase.database().reference().child("user-info").child((loadController.currentUser?.uid!)!).child("liked-posts").child(postId).setValue(FIRServerValue.timestamp())
                
            } else {
                //Remove this user's id from list of users who have liked this post
                FIRDatabase.database().reference().child("posts").child(postId).child("like-list").child((loadController.currentUser?.uid!)!).removeValue()
                //Remove this post from list of posts like by this user
                FIRDatabase.database().reference().child("user-info").child((loadController.currentUser?.uid!)!).child("liked-posts").child(postId).removeValue()
            }
        }
    }
    
    //Called when cell is created
    func updateLikeButton(){
        //Highlighted if it is contained in the array of liked posts in the load controller
        likeButton.highlighted = loadController.likedPostsArray[postId] != nil
        if likeButton.highlighted{
            likesLabel.alpha = 0.25
            likesImage.alpha = 0.25
        } else {
            likesLabel.alpha = 1
            likesImage.alpha = 1
        }

    }
    
    //Sets up listener for a long press on a user's profpic in a post
    func setProfPicListener(){
        //Creates the listener with action displayProfile
        let holdToSelectUser = UILongPressGestureRecognizer(target: self, action: #selector(PostCell.displayProfile(_:)))
        //Duration to hold in seconds
        holdToSelectUser.minimumPressDuration = 0.35;
        //Must enable user interaction so the UIImageView can detect taps
        profPicView.userInteractionEnabled = true
        profPicView.addGestureRecognizer(holdToSelectUser)
    }
    
    func displayProfile(gestureRecognizer: UILongPressGestureRecognizer){
        //When the gesture has started, transition to the selected user's profile
        if(gestureRecognizer.state == UIGestureRecognizerState.Began){
            self.tableViewController.performSegueWithIdentifier("selectedUser", sender: postId)
        }
    }
    
    
    //Called from the PostCellDropDownViewController when delete button is pressed
    func deletePressed(){
        FIRDatabase.database().reference().child("posts").child(postId).removeValue()
        //Signals the feed that a post was deleted
        (self.tableViewController as! HomeFeedViewController).deletePressed()
    }
    
    //The options button on the post cell was pressed
    @IBAction func dropDownPressed(sender: AnyObject) {
        //Create the view controller which will be opened as a popup
        let storyboard : UIStoryboard = UIStoryboard(
            name: "Knnect",
            bundle: nil)
        let menuViewController: PostCellDropDownViewController = storyboard.instantiateViewControllerWithIdentifier("PostCellDropDownViewController") as! PostCellDropDownViewController
        //Set the presentation style
        menuViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
        //How big the popup will be, the size of one button
        menuViewController.preferredContentSize = CGSizeMake(65, 40)
        //Set the popup's cell, so that it can keep track of which cell to update
        menuViewController.cell = self
        //Whether the delete button should be shown
        menuViewController.showDelete = self.showDelete
        //Setup the view controller as a popup
        let popoverMenuViewController = menuViewController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = .Up
        popoverMenuViewController?.delegate = self.tableViewController as? UIPopoverPresentationControllerDelegate
        //Where the arrow will come from and where the popup will be displayed relative to
        popoverMenuViewController?.sourceView = sender as! UIButton
        popoverMenuViewController?.sourceRect = (sender as! UIButton).bounds
        self.tableViewController.presentViewController(menuViewController, animated: true, completion: nil)
    }
    
    
    
    func resizeCell(){
        //Update the size of the cell to fit the post
        innerView.updateConstraints()
        self.updateConstraints()
    }
    
    
    
}
