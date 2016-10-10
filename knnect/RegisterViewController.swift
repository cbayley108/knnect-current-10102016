//
//  RegisterViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/20/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {

    //Segue identifier for transitioning to student or mentor select
    let loginToJoinScreen = "LoginToJoinScreen"
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    var ref: FIRDatabaseReference?
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
        super.viewDidAppear(animated)
        //listener if a user is authenticated
        listener = FIRAuth.auth()?.addAuthStateDidChangeListener{ auth, user in
            if user != nil {
                //User was created and authenticated, proceed to student/mentor select
                self.performSegueWithIdentifier(self.loginToJoinScreen, sender: nil)
                //Remove this listener
                FIRAuth.auth()?.removeAuthStateDidChangeListener(self.listener!)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func registerPressed(sender: AnyObject) {
        //Check if passwords match
        if confirmPasswordField.text != passwordField.text{
            let alert = UIAlertController(title: "Error", message: "Your passwords do not match. Please try again.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                UIAlertAction in
            }
            alert.addAction(okAction)
            self.presentViewController(alert, animated: true, completion: nil)
            
            //Might want to add an else if for user already exists
            
        }else{
            //Create user
            FIRAuth.auth()?.createUserWithEmail(self.emailField.text!, password: self.passwordField.text!, completion: {result, error in
                if error == nil {
                    //Sign the user in
                    FIRAuth.auth()?.signInWithEmail(self.emailField.text!, password: self.passwordField.text!,
                        completion: { (error, auth) -> Void in})
                } else if error?.description != nil{
                    let alert = UIAlertController(title: "Error", message: "Invalid email/password. Passwords must be at least six characters long.", preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                        UIAlertAction in
                    }
                    alert.addAction(okAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                else {
                    let alert = UIAlertController(title: "Error", message: "Registration failed. Check your internet connection, and contact the developers if the problem persists.", preferredStyle: .Alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                        UIAlertAction in
                    }
                    alert.addAction(okAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            })
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