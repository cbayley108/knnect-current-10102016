//
//  ProfileMenuViewController.swift
//  knnect
//
//  Created by Chris Bayley on 7/21/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit

//The view controller displayed when the user selects the settings option from the profile page
class ProfileMenuViewController: UIViewController {

    var vc: ProfileViewController?
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func editPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {
            self.vc!.editProfile()
        })
    }
    
   
    @IBAction func blockPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {
            self.vc!.blockPressed()
        })
    }

    @IBAction func signOutPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: {
            self.vc!.signOut()
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
