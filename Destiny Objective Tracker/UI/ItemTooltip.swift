//
// Created by Russell Richardson on 2018-12-01.
// Copyright (c) 2018 Russell Richardson. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ItemTooltip: UIViewController {

    var backgroundView = UIView()

    var item: Destiny.Item?

    static let UNCOMMON_QUEST_COLOR = UIColor.init(red: 0.23, green: 0.34, blue: 0.19, alpha: 1.0)
    static let RARE_QUEST_COLOR = UIColor.init(red:0.34, green:0.41, blue:0.55, alpha:1.0)
    static let LEGENDARY_QUEST_COLOR = UIColor.init(red:0.18, green:0.11, blue:0.22, alpha:1.0)
    static let EXOTIC_QUEST_COLOR = UIColor.init(red:0.81, green:0.68, blue:0.20, alpha:1.0)



    @IBOutlet weak var questTopBorder: UIView!
    
    @IBOutlet weak var lblItemName: UILabel!
    
    @IBOutlet weak var lblItemType: UILabel!
    
    @IBOutlet weak var lblItemDescription: UILabel!
    
    @IBInspectable var questColor: UIColor = LEGENDARY_QUEST_COLOR {
        didSet {
            self.questTopBorder.backgroundColor = self.questColor
        }
    }


    func associate(with item: Destiny.Item) {
        self.item = item
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.lblItemDescription.sizeToFit()
    }

    func setup() {

        lblItemName.text = self.item?.name
        lblItemDescription.text = self.item?.description
        lblItemType.text = self.item?.definition?.itemTypeAndTierDisplayName

        switch(item?.definition?.inventory.tierTypeName) {
        case "Uncommon":
            self.questColor = ItemTooltip.UNCOMMON_QUEST_COLOR
        case "Rare":
            self.questColor = ItemTooltip.RARE_QUEST_COLOR
        case "Legendary":
            self.questColor = ItemTooltip.LEGENDARY_QUEST_COLOR
        case "Exotic":
            self.questColor = ItemTooltip.EXOTIC_QUEST_COLOR
        default:
            self.questColor = ItemTooltip.RARE_QUEST_COLOR
        }

        let blurEffect = UIBlurEffect(style: .regular)

        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.insertSubview(blurEffectView, at: 0)
    }

    @IBAction func closeBtnPressed(_ sender: Any) {
        
        self.navigationController?.popToRootViewController(animated: true)
        self.dismiss(animated: true)

    }


}
