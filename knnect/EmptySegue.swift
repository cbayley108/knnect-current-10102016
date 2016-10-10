//
//  EmptySegue.swift
//  knnect
//
//  Created by Chris Bayley on 6/9/16.
//  Copyright © 2016 Chris Bayley. All rights reserved.
//

import UIKit

//Sometimes we need to perform a segue but we need to manually do stuff, mainly in the networks area because it is inside of a container view and we want to display two view controllers there. We use this class instead of other segues and this will do nothing. The actual changing of screens takes place in the performsegue function in whatever screen is going to be replaced.
class EmptySegue: UIStoryboardSegue {
    override func perform() {
    }
}
