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
    
    override func viewDidAppear(_ animated: Bool) {

        loadSettings()
        settingsTable.delegate = self
    }

    func loadSettings() {
        let platformPreference = defaults.integer(forKey: "platform")

        if let platformType = Destiny.DestinyMembership.MembershipType.init(rawValue: platformPreference) {
            self.selectedPlatformLabel.text = platformType.description
        }

        memberIdLabel.text = destiny.membershipID
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
