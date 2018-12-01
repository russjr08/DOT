//
//  IntrinsicTableView.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/16/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit

class IntrinsicTableView: UITableView {

    override var contentSize:CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }

}
