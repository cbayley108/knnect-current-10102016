//
//  messagesInitTableViewCell.swift
//  knnect
//
//  Created by Charles Yu on 7/27/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit

class messagesInitTableViewCell: UITableViewCell {

    @IBOutlet weak var lastMessage: UILabel!
    @IBOutlet weak var unreadNotifier: UIImageView!
    @IBOutlet weak var type: UILabel!
    @IBOutlet weak var name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let image = UIImage(named: "circle")?.imageWithRenderingMode(.AlwaysTemplate)
        unreadNotifier.image = image
        unreadNotifier.tintColor = UIColor(red: 5/255, green: 102/255, blue: 141/255, alpha: 1.0)

    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
