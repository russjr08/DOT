//
//  IndividualVendorController.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 7/4/19.
//  Copyright © 2019 Russell Richardson. All rights reserved.
//

import UIKit

class IndividualVendorController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var vendorTitle: UILabel!
    @IBOutlet weak var vendorSubTitle: UILabel!
    @IBOutlet weak var vendorDescription: UILabel!
    @IBOutlet weak var vendorImage: UIImageView!
    @IBOutlet weak var vendorBountyTable: UITableView!
    
    var vendor: Destiny.Vendor?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        self.loadVendor()
        self.vendorBountyTable.dataSource = self
        self.vendorBountyTable.delegate = self

    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.vendor?.sales.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sale = self.vendor!.sales[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BountyItemCell", for: indexPath) as! VendorBountyItemCell
        cell.setItem(to: sale)
        
        cell.layoutIfNeeded()
        cell.layoutSubviews()
        cell.setNeedsDisplay()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Bounties"
    }
    
    func loadVendor() {
        if let vendor = vendor {
            self.title = vendor.definition!.displayProperties.name
            self.vendorTitle.text = vendor.definition!.displayProperties.name
            self.vendorSubTitle.text = vendor.definition!.displayProperties.subtitle
            self.vendorDescription.text = vendor.definition!.displayProperties.description
            self.vendorImage.setAndCacheImage(withURL: "https://www.bungie.net\(vendor.definition?.displayProperties.icon! ?? "")")
        }
    }

    

}
