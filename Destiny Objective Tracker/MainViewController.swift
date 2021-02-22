//
//  MainViewController.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 8/3/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit
import Alamofire
import Zip
import SQLite
import PromiseKit
import Fabric
import Crashlytics

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    enum ItemDisplayType: Int {
        case pursuit = 0, weeklyChallenge, story, armor, all
    }
    
    let sectionHeaderSize: CGFloat = 25

    @IBOutlet weak var statusButton: UIBarButtonItem!
    @IBOutlet weak var debugButton: UIBarButtonItem!
    var filterButton: UIBarButtonItem?
    private var statusLabel = StatusLabel(frame: CGRect.zero)
    
    @IBOutlet weak var itemTable: UITableView!
    
    
    let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
    let searchControl = UISearchController(searchResultsController: nil)
    
    
    let defaults = UserDefaults.init()
    let destiny = Destiny.API.init()
    var database: Database
    var characters = [Destiny.Character]()
    var character: Destiny.Character?
    
    var pursuitFilter = "" {
        didSet {
            UIView.transition(with: self.itemTable,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: { self.itemTable.reloadData() })
        }
    }

    var search = "" {
        didSet {
            self.itemTable.reloadData()
        }
    }
    
    var scope: ItemDisplayType = ItemDisplayType.all {
        didSet {
            self.itemTable.reloadData()
        }
    }
    
    var cellHeightCache: [IndexPath : CGFloat] = [:]
    
    @IBOutlet weak var characterButton: UIButton!
    
    var refreshTimer: Timer?
    
    var selectedCharId: String = "" {
        didSet {
            itemTable.reloadData()
            if let character = characters.first(where: {$0.id == selectedCharId}) {
                characterButton.setTitle("\(character.charClass.rawValue) - \(character.light)", for: .normal)
                characterButton.sizeToFit()
                self.character = character
                defaults.set(self.selectedCharId, forKey: "selected_char")
                self.activityIndicator.startAnimating()
                self.statusLabel.text = "Updating Inventory..."
                DispatchQueue.global(qos: .background).async {
                    self.character?.updateInventory(withAPI: self.destiny).done {
                        print("Done updating inventory")
                        DispatchQueue.main.async {
                            UIView.transition(with: self.itemTable,
                                              duration: 0.35,
                                              options: .transitionCrossDissolve,
                                              animations: { self.itemTable.reloadData() })
                            self.statusLabel.text = "Done!"
                            self.activityIndicator.stopAnimating()
                            
                        }
                    }.catch({ (error) in
                        print("Error updating inventory")
                        print(error)
                        self.presentError(withText: error.localizedDescription)
                        DispatchQueue.main.async {
                            self.statusLabel.text = "Failed to retrieve inventory!"
                            self.activityIndicator.stopAnimating()
                        }
                    })
                }
                
            }
        }
    }
    
    @IBOutlet weak var toolbar: UIToolbar!
    
    required init?(coder aDecoder: NSCoder) {
        self.database = Database(with: self.destiny)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        
//        itemTable.rowHeight = UITableView.automaticDimension
        itemTable.estimatedRowHeight = 120
        itemTable.delegate = self
        itemTable.dataSource = self
        
        itemTable.backgroundColor = UIColor.systemBackground

//        #if !DEBUG
//        navigationController?.tabBarController?.viewControllers?.remove(at: 2)
//        self.navigationItem.rightBarButtonItem = nil
//        #endif


        searchControl.searchBar.tintColor = UIColor.white
        searchControl.searchResultsUpdater = self
        searchControl.searchBar.delegate = self
        searchControl.obscuresBackgroundDuringPresentation = false
        searchControl.searchBar.placeholder = "Search Pursuits / Change Visibility"
        
        searchControl.searchBar.scopeButtonTitles = ["All", "Pursuits", "Weekly", "Story", "Armor"]
        searchControl.searchBar.selectedScopeButtonIndex = 0
        
        navigationItem.searchController = searchControl
        definesPresentationContext = true
    }
    
    @objc func refreshCurrentCharacter() {
        self.activityIndicator.startAnimating()
        self.statusLabel.text = "Updating Inventory..."
        
        DispatchQueue.global(qos: .default).async {
            self.character?.updateInventory(withAPI: self.destiny).done {
                self.activityIndicator.stopAnimating()
                self.statusLabel.text = "Done!"
                
                if let character = self.character {
                    self.characterButton.setTitle("\(character.charClass.rawValue) - \(character.light)", for: .normal)
                    self.characterButton.sizeToFit()
                }
                
                self.itemTable.reloadData()
                
            }.catch({error in
                self.activityIndicator.stopAnimating()
                self.statusLabel.text = "Error!"
                self.presentError(withText: error.localizedDescription)
            })
        }
        
    }
    
    
    @IBAction func debugDetails(_ sender: Any) {
        print(getEligibleItemsFromList())
        let alert = UIAlertController.init(title: "Debug", message: getEligibleItemsFromList().description, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func refreshData(_ sender: Any) {
        refreshCurrentCharacter()
    }
    
    
    @IBAction func showCharacterSelection(_ sender: Any) {
        let dialog = UIAlertController(title: "Select a character", message: nil, preferredStyle: .actionSheet)
        dialog.popoverPresentationController?.barButtonItem = UIBarButtonItem(customView: characterButton)
        dialog.popoverPresentationController?.sourceView = self.view
        for character in characters {
            dialog.addAction(UIAlertAction.init(title: "\(character.charClass.rawValue) - \(character.light)", style: .default, handler: { (_) in
                dialog.dismiss(animated: true, completion: nil)
                self.selectedCharId = character.id
            }))
        }
        self.present(dialog, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        filterButton = UIBarButtonItem.init(title: "Filter", style: .plain, target: self, action: #selector(openFilterDialog))
        
        statusLabel.backgroundColor = UIColor.clear
        statusLabel.textAlignment = .center
        statusButton.customView = statusLabel
        
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        activityIndicator.hidesWhenStopped = true
        
        toolbar.setItems([UIBarButtonItem.init(customView: activityIndicator), flex, statusButton, flex, filterButton!], animated: true)
        
        statusLabel.text = "Checking Access..."
        

        verifyAndCheckLogin().done {

            let platformPreference = self.defaults.integer(forKey: "platform")



            self.destiny.getDestinyMemberships().done({ memberships in
                if(platformPreference != 0) {
                    self.destiny.platform = Destiny.DestinyMembership.MembershipType.init(rawValue: platformPreference)!
                    self.destiny.membershipID = self.defaults.string(forKey: "membership_id") ?? "unknown"

                    self.downloadDatabase().done {
                        self.retrieveCharacters()
                        self.itemTable.reloadData()
                        self.refreshTimer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(self.refreshCurrentCharacter), userInfo: nil, repeats: true)
                    }.cauterize()

                } else {

                    if (memberships.count > 1) {
                        let alert = UIAlertController.init(title: "Multiple platforms detected!", message: "Looks like you play on multiple platforms, choose a platform to load. You can change this later in settings.", preferredStyle: .alert)
                        for membership in memberships {
                            alert.addAction(.init(title: membership.membershipType.description, style: .default, handler: { (_) in
                                self.destiny.membershipID = membership.membershipId
                                self.destiny.platform = membership.membershipType

                                self.defaults.set(self.destiny.platform.rawValue, forKey: "platform")
                                self.defaults.set(self.destiny.membershipID, forKey: "membership_id")

                                self.downloadDatabase().done {
                                    self.retrieveCharacters()
                                    self.itemTable.reloadData()
                                    self.refreshTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.refreshCurrentCharacter), userInfo: nil, repeats: true)
                                }.cauterize()

                                alert.dismiss(animated: true)

                            }))
                        }

                        self.present(alert, animated: true, completion: nil)
                    } else {
                        let membership = memberships[0]

                        self.destiny.membershipID = membership.membershipId
                        self.destiny.platform = membership.membershipType

                        self.defaults.set(self.destiny.platform.rawValue, forKey: "platform")
                        self.defaults.set(self.destiny.membershipID, forKey: "membership_id")

                        self.downloadDatabase().done {
                            self.retrieveCharacters()
                            self.itemTable.reloadData()
                            self.refreshTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(self.refreshCurrentCharacter), userInfo: nil, repeats: true)
                        }.cauterize()
                    }

                }
            }).catch({ (error) in
                self.presentError(withText: (error as NSError).userInfo.description)
                print(error)

            })
        }.cauterize()
        

        

    }
    
    @objc func openFilterDialog() {
        let dialog = UIAlertController(title: "Select a pursuit type", message: nil, preferredStyle: .actionSheet)
        
        dialog.popoverPresentationController?.barButtonItem = self.filterButton
        dialog.popoverPresentationController?.sourceView = self.view
        
        for filter in getAvailablePursuitTypes() {
            dialog.addAction(UIAlertAction.init(title: filter, style: .default, handler: { (_) in
                dialog.dismiss(animated: true, completion: nil)
                self.pursuitFilter = filter
            }))
        }
        dialog.addAction(UIAlertAction.init(title: "All", style: .cancel, handler: { (_) in
            dialog.dismiss(animated: true, completion: nil)
            self.pursuitFilter = ""
        }))
        self.present(dialog, animated: true, completion: nil)
    }
    

    
    func verifyAndCheckLogin() -> Promise<Void> {
        
        return firstly { Promise<Void> { seal in
            print("Checking to see if access token has been created yet")
            if(self.defaults.string(forKey: "access_token") == nil || self.defaults.object(forKey: "access_token_expiration") == nil) {
                // No access token has been created yet.
                print("Token has not been created yet")
                destiny.createAccessToken(withOAuthToken: defaults.string(forKey: "oauthtoken")!).done { _ in
                    self.downloadDatabase().cauterize()
                    seal.fulfill(())
                }.done {
                        seal.fulfill(())
                }.cauterize()
            } else {
                seal.fulfill(())
            }}.then{ Promise<Void> { seal in
                print("Access refresh")
                if(!self.destiny.checkAccessToken()) {
                    if(!self.destiny.checkRefreshToken()) {
                        // Both Access and Refresh Tokens are expired. Return to Login Screen.
                        self.promptLoginExpiredAndReturnToLogin()
                        return
                    }
                    self.statusLabel.text = "Refreshing Access..."
                    self.statusLabel.setNeedsDisplay()
                    
                    self.destiny.refreshAccessToken().tap { result in
                        switch result {
                        case .rejected(let error):
                            print(error)
                            self.promptLoginExpiredAndReturnToLogin()
                            break
                        case .fulfilled(_):
                            seal.fulfill(())
                            break
                        }
                        
                        }.cauterize()
                } else {
                    seal.fulfill(())
                }
            }}

            
            
        }
        
        
    }

    func promptLoginExpiredAndReturnToLogin() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)


        let alert = UIAlertController.init(title: "Login Expired", message: "Whoops! Looks like your session has expired. You'll now be returned to the login screen.", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (action) in
            let storyBoard: UIStoryboard = UIStoryboard(name: "Login", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "Login") as! LoginViewController
            self.present(newViewController, animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func downloadDatabase() -> Promise<Void> {
        
        statusLabel.text = "Checking for updates..."
        activityIndicator.startAnimating()

        self.statusLabel.text = "Loading Destiny Database..."
        
        return Promise { seal in
            database.downloadDatabase { (progress) in
                print("Download Progress: \(progress.fractionCompleted)")
                self.statusLabel.text = "Download Progress: \((progress.fractionCompleted * 100).rounded())"
            }.done {
                print("All done")
                seal.fulfill(())
                
                }.catch({ (error) in
                    self.statusLabel.text = "Failed to update database!"
                    self.activityIndicator.stopAnimating()
                    self.presentError(withText: error.localizedDescription)
                })
            
            }
    }

    
    func retrieveCharacters() {
        
        DispatchQueue.main.async {
            self.statusLabel.text = "Retrieving Characters..."
            self.statusLabel.setNeedsDisplay()
        }
        
        DispatchQueue.global().async {
            var charPlayedDates = [Date]()
            self.destiny.getCharacters().done { (characters) in
                
                print("We're logged in! Retrieved characters: \(characters)")
                self.characters.removeAll()
                for character in characters {
                    self.characters.append(character)
                    charPlayedDates.append(character.lastPlayed!)
                }

                
                self.statusLabel.text = "Updating Inventory..."
                self.statusLabel.setNeedsDisplay()
                
                
                let latestPlayedDate = charPlayedDates.max()
                self.selectedCharId = (self.characters[charPlayedDates.lastIndex(of: latestPlayedDate!)!].id)
                
                
                
                }.catch({ (error) in
                    self.statusLabel.text = "Failed to retrieve characters!"
                    self.activityIndicator.stopAnimating()
                    self.presentError(withText: (error as NSError).userInfo.description)
                    self.refreshTimer?.invalidate()
                })
        }
    }
    
    func presentError(withText error: String) {
        let alert = UIAlertController.init(title: "Error!", message: "There was an error while trying to load game data: \(error)", preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    // Table View
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.section == 0) {

            performSegue(withIdentifier: "OpenModalTooltip", sender: indexPath.row)

        }

        tableView.deselectRow(at: indexPath, animated: true)

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "OpenModalTooltip" {
            if let popup = segue.destination as? ItemTooltip {
                let item = getEligibleItemsFromList()[sender as! Int]
                popup.associate(with: item)
                print(item)
            }
        }

    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(characters.count > 0) {
            switch section {
            case 0:
                if(scope == ItemDisplayType.pursuit || scope == ItemDisplayType.all) {
                    return getEligibleItemsFromList().count
                } else {
                    return 0
                }
            case 1:
                if(scope == ItemDisplayType.weeklyChallenge || scope == ItemDisplayType.all) {
                    return self.character?.milestones.filter({$0.definition.milestoneType == 3}).count ?? 0
                } else {
                    return 0
                }
                
            case 2:
                if(scope == ItemDisplayType.story || scope == ItemDisplayType.all) {
                    return self.character?.milestones.filter({$0.definition.milestoneType == 2 || $0.definition.milestoneType == 5}).count ?? 0
                } else {
                    return 0
                }
            case 3:
                if(scope == ItemDisplayType.armor || scope == ItemDisplayType.all) {
                    return getAvailableArmorPieces().count
                } else {
                    return 0
                }
            default:
                return 0
            }

        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemViewCell", for: indexPath) as! ItemViewCell
        
        if indexPath.section == 0 {
            cell.setItem(to: getEligibleItemsFromList()[indexPath.row])
        } else if indexPath.section == 1 && !getWeeklyMilestones().isEmpty {
            cell.setMilestone(to: getWeeklyMilestones()[indexPath.row])
        } else if indexPath.section == 2 && !getStoryMilestones().isEmpty {
            cell.setMilestone(to: getStoryMilestones()[indexPath.row])
        } else if indexPath.section == 3 && !getAvailableArmorPieces().isEmpty {
            cell.setItem(to: (getAvailableArmorPieces()[indexPath.row]))
        }

        cell.layoutIfNeeded()
        cell.layoutSubviews()
        cell.setNeedsDisplay()
        
        return cell

    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeightCache[indexPath] = cell.bounds.size.height
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = cellHeightCache[indexPath] {
            return height
        }
        return 180.0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "Pursuits \(getEligibleItemsFromList().count) / 63"
            case 1:
                return "Weekly Challenges"
            case 2:
                return "Story / Special Milestones"
            case 3:
                return "Armor Objectives"
            default:
                return "Unknown"
        }

    }
    
    func getAvailableArmorPieces() -> [Destiny.Item] {
        var eligible = [Destiny.Item]()
        let armorBuckets = [1585787867, 14239492, 20886954, 3448274439, 3551918588]

        if let character = characters.first(where: {$0.id == selectedCharId}) {
            for item in (character.inventory) {
                if(armorBuckets.contains(item.bucketHash!)) {
                    if(item.objectives.count > 0) {
                        eligible.append(item)
                    }
                }
            }
        }
        
        return eligible
    }
    
    func getAvailablePursuitTypes() -> [String] {
        var types = [String]()
        
        if let character = self.character {
            for item in character.inventory {
                if let definition = item.definition {
                    if definition.itemTypeDisplayName != "" && !types.contains(definition.itemTypeDisplayName) {
                        types.append(definition.itemTypeDisplayName)
                    }
                }
            }
        }
        
        return types
    }
    
    func getEligibleItemsFromList() -> [Destiny.Item] {
        let armorBuckets = [1585787867, 14239492, 20886954, 3448274439, 3551918588]
        var eligible = [Destiny.Item]()
        if let character = characters.first(where: {$0.id == selectedCharId}) {
            for item in (character.inventory) {
                if(item.name != nil && !item.redacted) {
                    
                    if(armorBuckets.contains(item.bucketHash!)) {
                        continue // Don't add armor items if it doesn't contain an objective
                    }
                    
                    if(self.pursuitFilter != "") {
                        if(item.definition?.itemTypeDisplayName == self.pursuitFilter) {
                            eligible.append(item)
                        }
                    } else if(self.search != "") {
                        if((item.name?.contains(search))! || (item.description?.contains(search))!) {
                            eligible.append(item)
                        }
                    } else if(self.pursuitFilter != "" && self.search != "") {
                        if(item.definition?.itemTypeDisplayName == self.pursuitFilter) {
                            if((item.name?.contains(search))! || (item.description?.contains(search))!) {
                                eligible.append(item)
                            }
                        }
                    } else {
                        eligible.append(item)
                    }
                } else {
                    print("Invalid item \(item)")
                }
            }
        }
       
        return eligible
    }
    
    func getWeeklyMilestones() -> [Destiny.API.MilestoneResponse] {
        var milestones = [Destiny.API.MilestoneResponse]()
        if let character = self.character {
            if character.milestones.count > 0 {
                milestones.append(contentsOf: character.milestones.filter({$0.definition.milestoneType == 3}))
                return milestones
            }
        }
        return milestones
    }
    
    func getStoryMilestones() -> [Destiny.API.MilestoneResponse] {
        var milestones = [Destiny.API.MilestoneResponse]()
        if let character = self.character {
            if character.milestones.count > 0 {
                milestones.append(contentsOf: character.milestones.filter({$0.definition.milestoneType == 2 || $0.definition.milestoneType == 5}))
                return milestones
            }
        }
        return milestones
    }

    func updateSearch(searchParams: String) {
        self.search = searchParams
    }
   
}

extension MainViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        self.updateSearch(searchParams: searchControl.searchBar.text ?? "")
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        print(selectedScope)
        switch(selectedScope) {
        case 0:
            scope = ItemDisplayType.all
        case 1:
            scope = ItemDisplayType.pursuit
        case 2:
            scope = ItemDisplayType.weeklyChallenge
        case 3:
            scope = ItemDisplayType.story
        case 4:
            scope = ItemDisplayType.armor
        default:
            scope = ItemDisplayType.all
        }
    }
    
}
