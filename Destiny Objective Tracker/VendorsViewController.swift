//
//  VendorsViewController.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 6/26/19.
//  Copyright © 2019 Russell Richardson. All rights reserved.
//

import UIKit

class VendorsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var vendorTable: UITableView!
    
    private let defaults = UserDefaults.init()
    
    var vendors: [Destiny.Vendor] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vendorTable.dataSource = self
        vendorTable.delegate = self
    }
    
    
    @IBAction func refreshButtonClicked(_ sender: Any) {
        checkVendor()
    }
    
    func checkVendor() {
        var vendorsList: [Int] = []
        
        self.vendors.removeAll()
        
        var alert = UIAlertController(title: "Updating Vendors", message: "Vendor update in progress...", preferredStyle: .alert)

        self.present(alert, animated: true, completion: nil)
        
        do {
            //try Destiny.Vendor.retrieveVendor(withHash: 880202832, fromCharacter: defaults.string(forKey: "selected_char") ?? "0").cauterize()
            try Destiny.Vendor.retrieveVendorList(withCharacter: defaults.string(forKey: "selected_char") ?? "0").done { vendors in
                vendorsList = vendors
                try vendorsList.forEach({ vendor in
                    try Destiny.Vendor.retrieveVendor(withHash: vendor, fromCharacter: self.defaults.string(forKey: "selected_char") ?? "0").done { vendor in
                        if(vendor.enabled ?? false) {
                            self.vendors.append(vendor)
                            self.vendors.sort { $0.hash! < $1.hash! }
                            self.vendorTable.reloadData()
                        }
                        
                    }
                })
            }.done {
                // Vendors finished updating
                alert.dismiss(animated: true, completion: nil)
                
                Destiny.API.init().getCharacters().done { characters in
                    for character in characters {
                        if character.id == (self.defaults.string(forKey: "selected_char") ?? "0") {
                            self.title = "Vendors (\(character.charClass.rawValue))"
                        }
                    }
                }.cauterize()
                
            }.cauterize()
        } catch {
            print("Whoops...")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let destinationVC = segue.destination as! UINavigationController
        let vendorToSend = vendors[self.vendorTable.indexPathForSelectedRow!.row]

        let vendorView = destinationVC.topViewController as! IndividualVendorController
        vendorView.vendor = vendorToSend
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vendors.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VendorViewCell", for: indexPath) as! VendorViewCell
        cell.selectionStyle = .none
        
        cell.setVendor(to: self.vendors[indexPath.row])
        
        cell.layoutIfNeeded()
        cell.layoutSubviews()
        cell.setNeedsDisplay()
        
        return cell
    }

}
