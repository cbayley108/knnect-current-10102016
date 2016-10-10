//
//  ContainerViewController.swift
//  knnect
//
//  Created by Chris Bayley on 6/9/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {

    var segueIdentifier : String!
    var vc : UIViewController!
    var lastViewController: UIViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Display the first screen, the public network
        segueIdentifierReceivedFromParent(0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Called by the network view controller which holds this container view, switches the displayed view based on index from segemneted control button
    func segueIdentifierReceivedFromParent(index: Int){
        if index == 1
        {
            self.segueIdentifier = "publicNetwork"
            self.performSegueWithIdentifier(self.segueIdentifier, sender: nil)
        }
        else if index == 0
        {
            self.segueIdentifier = "privateNetwork"
            self.performSegueWithIdentifier(self.segueIdentifier, sender: nil)
        }
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == segueIdentifier{
            //Remove the last view controller
            if lastViewController is NamesTemplateViewController{
                (lastViewController as! NamesTemplateViewController).searchController.dismissViewControllerAnimated(true, completion: nil)
            }
            
            if lastViewController is UISearchController{
                lastViewController.dismissViewControllerAnimated(true, completion: nil)
            }

            if lastViewController != nil{
                lastViewController.view.removeFromSuperview()
            }
            //Add the new view controller to this container
            vc = segue.destinationViewController
            self.addChildViewController(vc)
            //Display the new view
            vc.view.frame = CGRect(x: 0,y: 0, width: self.view.frame.width,height: self.view.frame.height)
            self.view.addSubview(vc.view)
            vc.didMoveToParentViewController(self)
            //Store the current vc as the last view controller displayed
            lastViewController = vc
            
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
