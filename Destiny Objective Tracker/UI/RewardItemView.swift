//
//  RewardItemView.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/19/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit

class RewardItemView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    @IBOutlet var container: UIView!
    
    @IBOutlet weak var icon: UIImageView!
    
    @IBOutlet weak var name: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
    
    func setItem(to item: RewardItemDefinition) {
        
        if(item.quantity == 0) {
            self.name.text = item.item?.displayProperties.name
        } else {
            self.name.text = "+\(item.quantity) \(item.item?.displayProperties.name ?? "Unknown")"
        }
        
        if let url = item.item?.displayProperties.icon {
            icon.setAndCacheImage(withURL: "https://www.bungie.net/\(url)")
            //icon.image = icon.image?.resizeImage(targetSize: CGSize.init(width: 40, height: 40))
        }
    }

    func setNeedsTransparentDisplay() {
        container.backgroundColor = UIColor.clear
        name.textColor = UIColor.white
    }
    
    func loadNib() {
        let bundle = Bundle(for: RewardItemView.self)
        bundle.loadNibNamed("RewardItemView", owner: self, options: nil)
        addSubview(container)
        container.frame = bounds
        container.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        self.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
        //        self.autoresizesSubviews = false
        
    }
    
}
