//
//  ItemViewCell.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/13/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit

class ItemViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var typeLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var expirationLabel: UILabel!
//    @IBOutlet weak var expirationLabelHeight: NSLayoutConstraint!
    
    @IBOutlet weak var objectives: UIStackView!
    @IBOutlet weak var rewards: UIStackView!
    
    var expirationTimer: Timer?
    var expirationDate: Date?
    
    var item: Destiny.Item?
    var milestone: Destiny.API.MilestoneResponse?
    
    
    func setItem(to item: Destiny.Item) {
        self.item = item
        self.milestone = nil
        self.resetCell()

        
        self.nameLabel.text = item.name
        
        if item.definition?.itemTypeAndTierDisplayName != "" {
            self.typeLabel.text = item.definition?.itemTypeDisplayName
            self.typeLabel.isHidden = false
            self.typeLabelHeight.constant = 20
        } else {
            self.typeLabel.isHidden = true
            self.typeLabelHeight.constant = 0
        }
        
        if item.expirationDate != nil {
            self.expirationLabel.isHidden = false
            self.expirationDate = item.expirationDate
            displayExpirationTimer()
            expirationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(displayExpirationTimer), userInfo: nil, repeats: true)
        } else {
            self.expirationLabel.isHidden = true

            self.expirationLabel.text = ""

        }
        
        self.descriptionLabel.text = item.description
        descriptionLabel.sizeToFit()
        //            cell.descriptionLabel.layoutIfNeeded()
        descriptionLabel.frame.size.height = descriptionLabel.contentSize.height
        
        
        var allObjectivesComplete = false
        for objective in item.objectives {
            self.addObjective(objective)
            allObjectivesComplete = objective.complete
        }
        
        if(allObjectivesComplete) {
            self.expirationLabel.text = ""
            self.expirationLabel.isHidden = true
        }
        
        if let definition = item.definition {
            for reward in definition.rewards {
                self.addReward(reward)
            }
        }
        
        objectives.setNeedsLayout()
        objectives.layoutSubviews()
        objectives.setNeedsDisplay()
        
        rewards.setNeedsLayout()
        rewards.layoutSubviews()
        rewards.setNeedsDisplay()
        
        self.grabImage(icon: item.icon)
        
        self.layoutSubviews()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        self.setNeedsDisplay()
        self.didMoveToSuperview()
    }
    
    func resetCell() {
        objectives.arrangedSubviews.forEach({$0.removeFromSuperview()})
        rewards.arrangedSubviews.forEach({$0.removeFromSuperview()})
        
        
        objectives.arrangedSubviews.forEach({objectives.removeArrangedSubview($0)})
        rewards.arrangedSubviews.forEach({rewards.removeArrangedSubview($0)})
        
        self.nameLabel.text = ""
        self.descriptionLabel.text = ""
        self.expirationLabel.text = ""
        self.typeLabel.text = ""
        self.iconView.image = nil


    }
    
    func setMilestone(to milestone: Destiny.API.MilestoneResponse) {
        self.resetCell()
        self.item = nil
        self.milestone = milestone

        self.nameLabel.text = milestone.definition.displayProperties.name
        self.descriptionLabel.text = milestone.definition.displayProperties.description

        if(milestone.availableQuests.count > 0) {
            print(milestone)
            do {
                let dbItem = try Database.decryptItem(withHash: milestone.availableQuests.first!.questItemHash, fromTable: "DestinyInventoryItemDefinition")
                if(dbItem?.displayProperties.name != nil && dbItem?.displayProperties.name?.isEmpty == false) {
                    self.nameLabel.text = dbItem?.displayProperties.name ?? milestone.definition.displayProperties.name
                }

                if(dbItem?.displayProperties.description != nil && dbItem?.displayProperties.description?.isEmpty == false) {
                    self.descriptionLabel.text = dbItem?.displayProperties.description ?? milestone.definition.displayProperties.description
                }

                if let icon = dbItem?.displayProperties.icon {
                    grabImage(icon: icon)
                }
            } catch {
                print("Couldn't decrypt quest item")
            }
        }

        self.typeLabel.text = "Milestone / Challenge"
        
        if(milestone.definition.displayProperties.icon != nil || milestone.definition.displayProperties.icon?.isEmpty ?? false == false) {
            self.grabImage(icon: milestone.definition.displayProperties.icon)
        } else if(milestone.availableQuests.count > 0) {
            self.grabImage(icon: milestone.availableQuests.first?.questItem?.displayProperties.icon)
        }
        
        self.iconView.backgroundColor = UIColor.black
        
        if milestone.endDate != nil {
            self.expirationLabel.isHidden = false
            self.expirationDate = milestone.endDate
            displayExpirationTimer()
            expirationTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(displayExpirationTimer), userInfo: nil, repeats: true)
        } else {
            self.expirationLabel.isHidden = true
            
            self.expirationLabel.text = ""
            
        }
        
        
        if let rewards = milestone.definition.rewards {
            for reward in rewards {
                if let entries = reward.value.rewardEntries {
                    for entry in entries {
                        if let items = entry.value.items {
                            for item in items {
                                addReward(item)
                            }
                        }
                    }
                }
                
            }
        }
        
        if let activities = milestone.activities {
            var objectiveHashes = [Int]()
            for activity in activities {
                for challenge in activity.challenges {
                    if !objectiveHashes.contains(challenge.objective.objectiveHash) {
                        objectiveHashes.append(challenge.objective.objectiveHash)
                        addObjective(challenge.objective)
                    }
                }
            }
        }
        

            for quest in milestone.availableQuests {
                self.grabImage(icon: quest.questItem?.displayProperties.icon)
                for objective in quest.status.stepObjectives {
                    addObjective(objective)
                }
                
                if let rewards = quest.questItem?.rewards {
                    for reward in rewards {
                        addReward(reward)
                    }
                }
                
            }


        
        self.layoutSubviews()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        self.setNeedsDisplay()
        self.didMoveToSuperview()
        
    }
    
    func grabImage(icon: String?) {
        if icon != nil {
            self.iconView.setAndCacheImage(withURL: "https://www.bungie.net\(icon ?? "default")")
            return
        }

        if item != nil  && item?.displayProperties.icon != nil{
            self.iconView.setAndCacheImage(withURL: "https://www.bungie.net\(item?.displayProperties.icon! ?? "")")
            return
        }

        if milestone != nil && milestone?.definition.displayProperties.icon != nil {
            self.iconView.setAndCacheImage(withURL: "https://www.bungie.net\(milestone?.definition.displayProperties.icon! ?? "")")
            return
        }
    }
    
    @objc func displayExpirationTimer() {
        if let expiration = self.expirationDate {
            let now = Date()
            let calendar = Calendar.current
            let diff = calendar.dateComponents([.hour, .minute, .day, .second], from: now, to: expiration)
            
            var dayDiff = ""
            var hourDiff = ""
            var minuteDiff = ""
            var secondDiff = ""
            
            if diff.day! > 0 {
                dayDiff = "\(diff.day!) days, "
            }
            
            if diff.hour! > 0 {
                hourDiff = "\(diff.hour!) hours, "
            }
            
            if diff.minute! > 0 {
                minuteDiff = "\(diff.minute!) minutes, "
            }
            
            if diff.second! > 0 {
                secondDiff = "\(diff.second!) seconds"
            }
            
            if now < expiration {
                self.expirationLabel.text = "Expires in \(dayDiff)\(hourDiff)\(minuteDiff)\(secondDiff)"
                
                self.expirationLabel.textColor = UIColor.lightGray
                
                if diff.day! == 0 && diff.hour! <= 2 {
                    self.expirationLabel.textColor = UIColor.red

                }

            } else {
                self.expirationLabel.text = "Expired!"
                self.expirationLabel.textColor = UIColor.red
            }
            
        }
        
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        layoutIfNeeded()
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        expirationTimer?.invalidate()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //objectives.autoresizesSubviews = false
        descriptionLabel.isScrollEnabled = false

        objectives.translatesAutoresizingMaskIntoConstraints = false
        rewards.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = UIColor.systemBackground
        self.contentView.backgroundColor = UIColor.systemBackground
    }

        

    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func addObjective(_ objective: Destiny.Objective) {
        let objectiveView = ObjectiveView()
        
        objectiveView.setObjective(to: objective)
        
        self.objectives.addArrangedSubview(objectiveView)
    }
    
    func addReward(_ reward: RewardItemDefinition) {
        let rewardView = RewardItemView()
        
        rewardView.setItem(to: reward)
        self.rewards.addArrangedSubview(rewardView)
    }


}
