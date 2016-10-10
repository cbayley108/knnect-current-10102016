//
//  CommentCellDropDownViewController.swift
//  knnect
//
//  Created by Chris Bayley on 8/8/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import MessageUI

//The view controller displayed when the user swipes left on a comment cell 
class CommentCellDropDownViewController: UIViewController, MFMailComposeViewControllerDelegate {

    //Values set before view loads
    var cell: CommentCell!
    var showDelete = true
    
    @IBOutlet weak var reportButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        //Show either delete or report button
        if(showDelete){
            reportButton.hidden = true
        } else {
            deleteButton.hidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func deletePressed(sender: AnyObject) {
        //Close this popup and delete the cell on completion
        self.dismissViewControllerAnimated(true, completion: {
            self.cell.deletePressed()
        })
    }
    
    @IBAction func reportPressed(sender: AnyObject) {
        //Display email report option or an error if cannot present the mailComposeViewController
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
        mailComposerVC.setSubject("REPORT POST")
        mailComposerVC.setMessageBody("This post is offensive because: \n \n [Your reason here]\n \n POST-ID [DO NOT ALTER]: " + self.cell.postId, isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertView(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
        sendMailErrorAlert.show()
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: {
            self.dismissViewControllerAnimated(true, completion: nil)
        })
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
