//
// Created by Russell Richardson on 2018-11-28.
// Copyright (c) 2018 Russell Richardson. All rights reserved.
//

import Foundation
import UIKit
import PromiseKit

class SettingsViewController: UITableViewController {

    let defaults = UserDefaults.init()

    let destiny = Destiny.API.init()

    @IBOutlet var settingsTable: UITableView!
    @IBOutlet weak var selectedPlatformLabel: UILabel!

    @IBOutlet weak var memberIdLabel: UILabel!
    @IBOutlet weak var accessTokenLabel: UILabel!
    
    @IBOutlet weak var accessTokenCell: UITableViewCell!
    
    @IBOutlet weak var signoutCell: UITableViewCell!
    
    override func viewDidAppear(_ animated: Bool) {

        loadSettings()
        settingsTable.delegate = self
        accessTokenCell.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(accessTokenCellTapped(_:))))
        signoutCell.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(signout(_:))))
    }

    func loadSettings() {
        let platformPreference = defaults.integer(forKey: "platform")

        if let platformType = Destiny.DestinyMembership.MembershipType.init(rawValue: platformPreference) {
            self.selectedPlatformLabel.text = platformType.description
        }

        memberIdLabel.text = destiny.membershipID
        accessTokenLabel.text = destiny.access_token
    }
    
    @objc func accessTokenCellTapped(_ recognizer: UIGestureRecognizer) {
        print("Cell clicked")
        UIPasteboard.general.string = destiny.access_token
    }
    
    @objc func signout(_ recognizer: UIGestureRecognizer) {
        
        let alert = UIAlertController.init(title: "Sign Out?", message: "Are you sure you would like to sign out? You will be taken to the login screen, and will need to authenticate with Bungie again.", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { action in
            let domain = Bundle.main.bundleIdentifier!
            UserDefaults.standard.removePersistentDomain(forName: domain)
            UserDefaults.standard.synchronize()
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let vc = storyBoard.instantiateViewController(withIdentifier: "Login") as! LoginViewController
            
            self.present(vc, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Nevermind!", style: .cancel, handler: nil))
        
        self.present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 0) { // App Settings Section
            switch indexPath.row {
            case 0:
                // Platform selection
                destiny.getDestinyMemberships().done { memberships in
                    let alert = UIAlertController.init(title: "Platform Select", message: "Select a platform to use within the app:", preferredStyle: .actionSheet)
                    for membership in memberships {
                        alert.addAction(UIAlertAction.init(title: membership.membershipType.description, style: .default, handler: { (_) in
                            self.defaults.set(membership.membershipType.rawValue, forKey: "platform")
                            self.defaults.set(membership.membershipId, forKey: "membership_id")

                            alert.dismiss(animated: true)
                            self.loadSettings()
                        }))
                    }

                    self.present(alert, animated: true)
                }
                break
            default:
                break
            }
        }


        tableView.deselectRow(at: indexPath, animated: true)
    }
}
