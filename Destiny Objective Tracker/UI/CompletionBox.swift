//
//  CompletionBox.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/15/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit

@IBDesignable
class CompletionBox: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    @IBInspectable var completed: Bool = false {
        didSet {
            self.setupView()
        }
    }
    @IBInspectable var completionBoxColor: UIColor {
        if(completed) {
            return UIColor.init(red: 109 / 255, green: 204 / 255, blue: 102 / 255, alpha: 1)
        } else {
            return UIColor.clear
        }
    }
    
    private func setupView() {
        self.layer.backgroundColor = completionBoxColor.cgColor
        self.layer.borderWidth = 2
        self.layer.borderColor = UIColor.white.cgColor
        
    }
    
    override func prepareForInterfaceBuilder() {
        setupView()
    }

}
