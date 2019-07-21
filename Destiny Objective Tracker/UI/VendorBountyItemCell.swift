//
//  VendorBountyItemCell.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 7/17/19.
//  Copyright © 2019 Russell Richardson. All rights reserved.
//

import UIKit

class VendorBountyItemCell: UITableViewCell {
    
    @IBOutlet weak var bountyName: UILabel!
    @IBOutlet weak var bountyDescription: UILabel!
    @IBOutlet weak var bountyImage: UIImageView!
    
    var item: Destiny.VendorItem?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setItem(to item: Destiny.VendorItem) {
        self.item = item
        
        self.bountyName.text = item.item?.displayProperties.name
        self.bountyDescription.text = item.item?.displayProperties.description
        self.bountyImage.setAndCacheImage(withURL: "https://www.bungie.net\(item.item?.displayProperties.icon! ?? "")")


        
    }

}
