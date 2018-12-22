//
// Created by Russell Richardson on 2018-12-01.
// Copyright (c) 2018 Russell Richardson. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class ItemTooltip: UIViewController {

    var backgroundView = UIView()

    var dialogView = UIView()

    var item: Destiny.Item?

    static let LEGENDARY_QUEST_COLOR = UIColor.init(red: 47.0, green: 28.0, blue: 56.0, alpha: 1.0)

    @IBOutlet weak var questTopBorder: UIView!
    
    @IBOutlet weak var lblItemName: UILabel!
    
    @IBOutlet weak var lblItemType: UILabel!
    
    @IBOutlet weak var lblItemDescription: UILabel!
    
    @IBInspectable var questColor: UIColor = LEGENDARY_QUEST_COLOR {
        didSet {
            //Test
        }
    }


    func associate(with item: Destiny.Item) {
        self.item = item

        lblItemName.text = item.name
        lblItemDescription.text = item.description
        lblItemType.text = item.definition?.itemTypeAndTierDisplayName
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    func setup() {
        //self.dialogView = Bundle.init(for: type(of: self)).loadNibNamed("QuestTooltip", owner: self, options: nil)?.first as! UIView

        //self.frame = UIScreen.main.bounds
        //self.dialogView.frame = self.bounds

        //backgroundView.frame = frame

        //backgroundView.backgroundColor = UIColor.black

//        backgroundView.alpha = 0.6

//        dialogView.frame.origin = CGPoint(x: 32, y: frame.height)
//        dialogView.frame.size = CGSize(width: frame.width-64, height: 250)
//        dialogView.backgroundColor = UIColor.white
//        dialogView.layer.cornerRadius = 6

//        addSubview(backgroundView)
//
//        self.addSubview(dialogView)
//
//        backgroundView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(didTapOnBackgroundView)))

        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = UIScreen.main.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.insertSubview(blurEffectView, at: 0)
    }

    @IBAction func closeBtnPressed(_ sender: Any) {
        
        self.navigationController?.popToRootViewController(animated: true)
        self.view.isHidden = true

    }
    
    @objc func didTapOnBackgroundView() {

    }

}
