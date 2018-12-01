//
//  StatusLabel.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 8/3/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit

class StatusLabel: UILabel {

    override var text: String? {
        didSet {
            if text != nil {
                self.sizeToFit()
            }
        }
    }

}
