//
//  CommentCell.swift
//  knnect
//
//  Created by Chris Bayley on 7/19/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class CommentCell: UITableViewCell {

    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var postId: String!
    var commentId: String!
    var tableViewController: UIViewController!
    var showDelete: Bool!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
   
    //Called from the CommentCellDropDownViewController when delete button is pressed
    func deletePressed(){
        FIRDatabase.database().reference().child("posts").child(postId).child("comments").child(commentId).removeValue()
        (self.tableViewController as! SelectedPostViewController).deletePressed()
    }

    
    func resizeCell(){
        //Update the size of the cell to fit the comment
        let sizeThatShouldFitTheContent: CGSize = commentTextView.sizeThatFits(commentTextView.frame.size)
        heightConstraint.constant = sizeThatShouldFitTheContent.height;
    }
    
    //Sets up a listener to detect for swipes on this cell
    func setupSwipeRecognizer(){
        //Creates observer with action displayDropdown
        let swipeOptions = UISwipeGestureRecognizer(target: self, action: #selector(CommentCell.displayDropdown(_:)))
        swipeOptions.direction = .Left
        self.addGestureRecognizer(swipeOptions);
    }
    
    
    
    func displayDropdown(gestureRecognizer: UIGestureRecognizer){
        //Create the view commentCellDropDown view controller
        let storyboard : UIStoryboard = UIStoryboard(
            name: "Knnect",
            bundle: nil)
        let menuViewController: CommentCellDropDownViewController = storyboard.instantiateViewControllerWithIdentifier("CommentCellDropDownViewController") as! CommentCellDropDownViewController
        //Set the presentation style to be a popover
        menuViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
        //Sets the size of the popover, equal to one button
        menuViewController.preferredContentSize = CGSizeMake(65, 40)
        //Sets the cell in the view controller so it can keep track of which cell to update
        menuViewController.cell = self
        //Whether the delete button should be shown
        menuViewController.showDelete = self.showDelete
        //Create the popover from the view controller
        let popoverMenuViewController = menuViewController.popoverPresentationController
        //No option to have no arrow direction, instead create an arrow direction with an invalid value, ie 0, and it will not be able to display an arrow
        popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
        popoverMenuViewController?.delegate = self.tableViewController as? UIPopoverPresentationControllerDelegate
        //The source from where the popover will be displayed from
        popoverMenuViewController?.sourceView = self
        //The rect to display the popover from, equal to the max x coordinate and 5 below the max y coordinate of the name. Width and height are 0 to make it a point.
        popoverMenuViewController?.sourceRect = CGRect(x: self.bounds.maxX, y: self.nameLabel.bounds.maxY + 5, width: 0, height: 0)
        self.tableViewController.presentViewController(menuViewController, animated: true, completion: nil)
    }

}


