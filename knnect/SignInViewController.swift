//
//  SignInViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/8/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    var listener: FIRAuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Sets the backgorund to be a full screen image
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "darkBlueBackground.png")?.drawInRect(self.view.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image)
    }
    
    override func viewDidAppear(animated: Bool) {
        //Create listener if a user has been signed in
        listener = FIRAuth.auth()?.addAuthStateDidChangeListener{ auth, user in
            if user != nil {
                //Proceed to knnect storyboard
                let storyboard = UIStoryboard(name:"Knnect", bundle: nil)
                let controller = storyboard.instantiateInitialViewController()
                self.presentViewController(controller!, animated: true, completion: nil)
                FIRAuth.auth()?.removeAuthStateDidChangeListener(self.listener!)
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func forgotPasswordPressed(sender: AnyObject) {
        //Create Alert
        let alert = UIAlertController(title: "Forgot Password", message: nil, preferredStyle: .Alert)
        //Create action to send password reset
        let saveAction = UIAlertAction(title: "Send Email", style: .Default)
            { (action: UIAlertAction) -> Void in
                    let emailField = alert.textFields![0]
                FIRAuth.auth()?.sendPasswordResetWithEmail(emailField.text!) {(error) in
                   
                }
        }
        //Create cancel action
        let cancelAction = UIAlertAction(title: "Cancel",
            style: .Default) { (action: UIAlertAction) -> Void in
        }
        //Add textfield for password
        alert.addTextFieldWithConfigurationHandler {
            (textEmail) -> Void in
            textEmail.placeholder = "Enter your email"
        }
        //Setup alert
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        //Display alert
        presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func signInPressed(sender: AnyObject) {
        //Attempt to sign in with given email and password, completion will sign in user and trigger authstatelistener
        FIRAuth.auth()?.signInWithEmail(emailField.text!, password: passwordField.text!, completion: {user, error in
            //There was an error
            if error != nil {
                let alert = UIAlertController(title: "Error", message: "Invalid username or password. Please try again.", preferredStyle: .Alert)
                
                let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                }
                alert.addAction(okAction)
                self.presentViewController(alert,
                    animated: true,
                    completion: nil)
            }
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
