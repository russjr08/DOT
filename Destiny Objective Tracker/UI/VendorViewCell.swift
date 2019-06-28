//
//  VendorViewCell.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 6/28/19.
//  Copyright © 2019 Russell Richardson. All rights reserved.
//

import UIKit

class VendorViewCell: UITableViewCell {

    
    @IBOutlet weak var vendorIcon: UIImageView!
    @IBOutlet weak var vendorNameLbl: UILabel!
    @IBOutlet weak var vendorSubtitleLbl: UILabel!
    @IBOutlet weak var vendorDescriptionLabel: UILabel!
    
    var vendor: Destiny.Vendor?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func grabImage() {

        
        if vendor != nil  && vendor?.definition?.displayProperties.icon != nil{
            self.vendorIcon.setAndCacheImage(withURL: "https://www.bungie.net\(vendor?.definition?.displayProperties.icon! ?? "")")
            return
        }

    }
    
    func setVendor(to vendor: Destiny.Vendor) {
        self.vendor = vendor
        self.grabImage()
        self.vendorNameLbl.text = vendor.definition!.displayProperties.name
        self.vendorSubtitleLbl.text = vendor.definition!.displayProperties.subtitle
        self.vendorDescriptionLabel.text = vendor.definition!.displayProperties.description
    }

}
