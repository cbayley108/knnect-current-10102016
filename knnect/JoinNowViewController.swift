//
//  JoinNowViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/20/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class JoinNowViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        //Hide back button so user cannot return to main screen after creating an account
        self.navigationItem.setHidesBackButton(true, animated: false)
        let cancel = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(deleteUser))
        self.navigationItem.setLeftBarButtonItem(cancel, animated: false)
        //Remove translucent nav bar
        self.navigationController?.navigationBar.translucent = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    //ADD CASES FOR IF USER LOGIN FAILS, ALSO SECURE ENTRY FOR PASSWORD
    func deleteUser(){
        var user = FIRAuth.auth()!.currentUser
        print(user?.email)
        user?.deleteWithCompletion { error in
            if let error = error {
                // An error happened.
                
                print(error.localizedDescription)
                print(error.code)
                
                let alert = UIAlertController(title: "Login", message: "Please login to confirm cancel", preferredStyle: UIAlertControllerStyle.Alert)
                
                alert.addTextFieldWithConfigurationHandler { (textField) in
                    textField.placeholder = "Email"
                }
                alert.addTextFieldWithConfigurationHandler { (textField) in
                    textField.placeholder = "Password"
                }
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                    let emailField = alert.textFields![0] as? UITextField
                    let passwordField = alert.textFields![1] as? UITextField
                    FIRAuth.auth()?.signInWithEmail(emailField!.text!, password: passwordField!.text!, completion: {user, error in
                        //There was an error
                        if error != nil {
                            
                        }else {
                            self.deleteUser()
                        }
                    })
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                }
                alert.addAction(cancelAction)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                //Deleted user, now take them back to another screen
                //Checks if there is a view controller before this one in the navigation controller
                print(self.navigationController?.childViewControllers.count)
                if self.navigationController?.childViewControllers.count > 1 {
                    //Pop this vc off and the previous ill be displayed
                    self.navigationController?.popViewControllerAnimated(true)
                } else {
                    //There was no prior screen so take the user back to the landing page
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let controller = storyboard.instantiateInitialViewController()!
                    UIApplication.sharedApplication().keyWindow?.rootViewController = controller
                    UIApplication.sharedApplication().keyWindow?.makeKeyAndVisible()
                }
                
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
