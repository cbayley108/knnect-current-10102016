//
//  NetworkViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/8/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit

class NetworkViewController: UIViewController{
    
    let loadController = UIApplication.sharedApplication().keyWindow?.rootViewController as! LoadScreenViewController

    @IBOutlet weak var notificationLabel: UILabel!
    @IBOutlet weak var notificationImage: UIImageView!
    @IBOutlet weak var container: UIView!
     var containerView: ContainerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setup colors and displays
        let ghostWhite = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1.0)
        let seaBlue = UIColor(red: 5/255, green: 102/255, blue: 141/255, alpha: 1.0)
        segmentedController.tintColor = seaBlue
        segmentedController.backgroundColor = ghostWhite
        segmentedController.layer.borderColor = seaBlue.CGColor
        segmentedController.layer.borderWidth = 1.0
        self.notificationImage.hidden = true
        self.notificationLabel.hidden = true
        //Set the badge value for the networks
        
        if(loadController.invitedArray.count > 0){
            self.navigationController!.tabBarItem.badgeValue = String(loadController.invitedArray.count)
            self.notificationImage.hidden = false
            self.notificationLabel.hidden = false
            self.notificationLabel.text = String(loadController.invitedArray.count)
            let image = UIImage(named: "circle")?.imageWithRenderingMode(.AlwaysTemplate)
            self.notificationImage.image = image
            self.notificationImage.tintColor = UIColor(red: 236/255, green: 56/255, blue: 59/255, alpha: 1.0)
        }
       
        
        
        // Do any additional setup after loading the view.
    }
    
    func reloadNotification(){
        self.notificationImage.hidden = true
        self.notificationLabel.hidden = true
        if(loadController.invitedArray.count > 0){
            self.notificationImage.hidden = false
            self.notificationLabel.hidden = false
            self.notificationLabel.text = String(loadController.invitedArray.count)
            let image = UIImage(named: "circle")?.imageWithRenderingMode(.AlwaysTemplate)
            self.notificationImage.image = image
            self.notificationImage.tintColor = UIColor(red: 236/255, green: 56/255, blue: 59/255, alpha: 1.0)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet weak var segmentedController: UISegmentedControl!

    //Called when the segmented control is pressed
    @IBAction func switchViews(sender: UISegmentedControl) {
        //Calls function in the container view to switch the displayed view based on the index
        containerView!.segueIdentifierReceivedFromParent(segmentedController.selectedSegmentIndex)
        //May currently be displaying a back button if the user is on a profile, remove this
        self.navigationItem.leftBarButtonItem = nil
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //Stores the container view for this class before performing segue
        if segue.identifier == "container"{
            containerView = segue.destinationViewController as? ContainerViewController
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

