//
//  ObjectiveView.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/15/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit

@IBDesignable
class ObjectiveView: UIView {

        
    @IBOutlet var container: UIView!
    @IBOutlet weak var descriptionLbl: UILabel!
    
    @IBOutlet weak var progressLbl: UILabel!
    @IBOutlet weak var completionBox: CompletionBox!
    
    @IBOutlet weak var progressBar: ProgressBar!
    
    
    var objective: Destiny.Objective? {
        didSet {
            if let objective = self.objective {
                descriptionLbl.text = objective.data?.progressDescription
                
                completionBox.completed = (objective.progress >= objective.completionValue) || objective.complete
                
                if(!completionBox.completed) {
                    switch objective.data?.inProgressValueStyle {
                    case ObjectiveData.DisplayUIStyle.percentage.rawValue:
                        let percentage: Float = Float((Float(objective.progress) / Float(objective.completionValue)) * 100)
                        
                        progressBar.progressValue = CGFloat(percentage)
                        
                        progressLbl.text = "\(percentage)%"
                        
                        break
                    
                    case ObjectiveData.DisplayUIStyle.number.rawValue:
                        let percentage: Float = Float((Float(objective.progress) / Float(objective.completionValue)) * 100)
                        
                        progressBar.progressValue = CGFloat(percentage)
                        
                        progressLbl.text = "\(objective.progress) / \(objective.completionValue)"
                        break
                        
                    case ObjectiveData.DisplayUIStyle.checkbox.rawValue:
                        progressLbl.text = ""
                        progressBar.progressValue = 0
                        break
                        
                    default:
                        let percentage: Float = Float((Float(objective.progress) / Float(objective.completionValue)) * 100)
                        
                        progressBar.progressValue = CGFloat(percentage)
                        
                        progressLbl.text = "\(objective.progress) / \(objective.completionValue)"
                        break
                    }
                } else {
                    let percentage: Float = Float((Float(objective.progress) / Float(objective.completionValue)) * 100)
                    
                    progressBar.progressValue = CGFloat(percentage)
                    
                    progressLbl.text = ""
                }
            }
            
        }
    }
    
    var observation: NSKeyValueObservation?
    
    func disableProgressBackground() {
        container.backgroundColor = UIColor.clear
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        loadNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }
    
    func setObjective(to objective: Destiny.Objective) {
        self.objective = objective
        

      
        self.observation = self.objective?.observe(\.progress, changeHandler: {(objective, change) in
            self.objective = objective
            // TODO: Add notification when objective completed
        })
        
    }
    
    func loadNib() {
        let bundle = Bundle(for: ObjectiveView.self)
        bundle.loadNibNamed("ObjectiveView", owner: self, options: nil)
        addSubview(container)
        container.frame = bounds
        container.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.completionBox.layer.borderColor = UIColor.white.cgColor
        self.completionBox.layer.borderWidth = 1
        self.heightAnchor.constraint(equalToConstant: 35).isActive = true
        
//        self.autoresizesSubviews = false
        
    }

    
    


}
