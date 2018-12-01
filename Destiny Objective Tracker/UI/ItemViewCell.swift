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
    }
    
    func setMilestone(to milestone: Destiny.API.MilestoneResponse) {
        self.resetCell()
        self.milestone = milestone
        
        self.nameLabel.text = milestone.definition.displayProperties.name
        self.descriptionLabel.text = milestone.definition.displayProperties.description
        self.typeLabel.text = "Milestone / Challenge"
        
        self.grabImage(icon: milestone.definition.displayProperties.icon)
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
        
        if let quests = milestone.availableQuests {
            for quest in quests {
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
        }

        
        self.layoutSubviews()
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        self.setNeedsDisplay()
        self.didMoveToSuperview()
        
    }
    
    func grabImage(icon: String?) {
        if item != nil {
            self.iconView.setAndCacheImage(withURL: "https://www.bungie.net\(icon ?? "default")")
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
