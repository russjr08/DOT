//
//  Database.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/12/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import Alamofire
import PromiseKit
import Zip
import SQLite

class Database {
    
    var destiny: Destiny.API
    static let defaults = UserDefaults.init()
    
    static var itemCache = Dictionary<Int, InventoryItemDefinition>()
    static var objectiveCache = Dictionary<Int, ObjectiveData>()
    static var milestoneCache = Dictionary<Int, MilestoneDefinition>()
    static var vendorCache = Dictionary<Int, VendorDefinition>()
    
    
    init(with destiny: Destiny.API) {
        self.destiny = destiny
    }
    
    func downloadDatabase(progressHandler: @escaping (_ progress: Progress) -> Void) -> Promise<Void> {
        
        return Promise { seal in
            destiny.fetchEndpoint(endpoint: "Manifest", parameters: Parameters(dictionaryLiteral: ("definitions", true))).done( { response in
                print(response.object(forKey: "Response") as! NSDictionary)
                let results = response.object(forKey: "Response") as! NSDictionary
                let mobileWorldContentPaths = results.object(forKey: "mobileWorldContentPaths") as! NSDictionary
                let contentPath = mobileWorldContentPaths.object(forKey: "en") as! String
                
                let currentContentPath = Database.defaults.string(forKey: "currentContentPath") ?? "none"
                print("Local content path is \(currentContentPath)")
                if(currentContentPath != contentPath) {
                    // Download the newest version of mobile world content database
                    let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
                    
                    download("https://www.bungie.net/" + contentPath, to: destination)
                        .downloadProgress { progress in
                            progressHandler(progress)
                        }
                        .responseData(completionHandler: { response in
                            Zip.addCustomFileExtension("content")
                            do {
                                
                                let unzipDirectory = try Zip.quickUnzipFile(response.destinationURL!)
                                print(unzipDirectory)
                                Database.defaults.set(contentPath, forKey: "currentContentPath")
                                seal.fulfill(())
                                
                            } catch {
                                print("Something went wrong...")
                            }
                            
                            
                        })
                    
                    print("Content Path from API is: \(contentPath)")
                    
                } else {
                    seal.fulfill(())
                }
                
            }).cauterize()
        }
        
        
    }
    
    static func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    
    
    static func decryptItem(withHash hash: Int, fromTable table: String) throws -> InventoryItemDefinition? {
        
        
        if let definition = itemCache[hash] {
            return definition
        }
        
        
        let fileManager = FileManager.default
        let currentContentPath = UserDefaults.init().string(forKey: "currentContentPath") ?? "none"

        let matched = Database.matches(for: "(world_sql_content)\\w+", in: currentContentPath)
        
        
        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let dbURL = documentDirectory.appendingPathComponent("\(matched[0])")
        
        
    
        let db = try Connection(dbURL.absoluteString + "/" + matched[0] + ".content")

        
        for item in try db.prepare("SELECT * FROM \(table) WHERE id + 4294967296 = \(hash) OR id = \(hash)") {
            do {

                let decoder = JSONDecoder()
                let invItem = try decoder.decode(InventoryItemDefinition.self, from: (item[1].unsafelyUnwrapped as! String).data(using: .utf8)!)
                
                itemCache[hash] = invItem
                print("Cached item definition for \(hash) -- \(invItem.displayProperties.name)")
                return invItem
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
        
        return nil
            
    }
    
    func decryptObjective(withHash hash: Int) throws -> ObjectiveData? {

        if let objData = Database.objectiveCache[hash] {
            return objData
        }
        
        let fileManager = FileManager.default
        let currentContentPath = Database.defaults.string(forKey: "currentContentPath") ?? "none"
        
        let matched = Database.matches(for: "(world_sql_content)\\w+", in: currentContentPath)
        
        
        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let dbURL = documentDirectory.appendingPathComponent("\(matched[0])")
        
        
        
        let db = try Connection(dbURL.absoluteString + "/" + matched[0] + ".content")
        
        
        for item in try db.prepare("SELECT * FROM DestinyObjectiveDefinition WHERE id + 4294967296 = \(hash) OR id = \(hash)") {
            do {
                
                let decoder = JSONDecoder()
                let objData = try decoder.decode(ObjectiveData.self, from: (item[1].unsafelyUnwrapped as! String).data(using: .utf8)!)
                
                Database.objectiveCache[hash] = objData
                print("Cached Objective Definition for \(hash) -- \(objData.displayProperties.description)")
                return objData
            } catch {
                print("Error!")
            }
        }
        
        return nil
    }
    
    func decryptMilestone(withHash hash: Int) throws -> MilestoneDefinition? {
        
        if let milestoneData = Database.milestoneCache[hash] {
            return milestoneData
        }
        
        let fileManager = FileManager.default
        let currentContentPath = Database.defaults.string(forKey: "currentContentPath") ?? "none"
        
        let matched = Database.matches(for: "(world_sql_content)\\w+", in: currentContentPath)
        
        
        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let dbURL = documentDirectory.appendingPathComponent("\(matched[0])")
        
        
        
        let db = try Connection(dbURL.absoluteString + "/" + matched[0] + ".content")
        
        
        for item in try db.prepare("SELECT * FROM DestinyMilestoneDefinition WHERE id + 4294967296 = \(hash) OR id = \(hash)") {
            do {
                
                let decoder = JSONDecoder()
                let milestoneData = try decoder.decode(MilestoneDefinition.self, from: (item[1].unsafelyUnwrapped as! String).data(using: .utf8)!)
                
                Database.milestoneCache[hash] = milestoneData
                print("Cached Milestone Definition for \(hash) -- \(milestoneData.displayProperties.name)")
                return milestoneData
            } catch {
                print("Error! \(error)")
            }
        }
        
        return nil
    }
    
    func decryptVendor(withHash hash: Int) throws -> VendorDefinition? {
        
        if let vendorData = Database.vendorCache[hash] {
            return vendorData
        }
        
        let fileManager = FileManager.default
        let currentContentPath = Database.defaults.string(forKey: "currentContentPath") ?? "none"
        
        let matched = Database.matches(for: "(world_sql_content)\\w+", in: currentContentPath)
        
        
        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let dbURL = documentDirectory.appendingPathComponent("\(matched[0])")
        
        
        
        let db = try Connection(dbURL.absoluteString + "/" + matched[0] + ".content")
        
        
        for item in try db.prepare("SELECT * FROM DestinyVendorDefinition WHERE id + 4294967296 = \(hash) OR id = \(hash)") {
            do {
                
                let decoder = JSONDecoder()
                let vendorData = try decoder.decode(VendorDefinition.self, from: (item[1].unsafelyUnwrapped as! String).data(using: .utf8)!)
                
                Database.vendorCache[hash] = vendorData
                print("Cached Vendor Definition for \(hash) -- \(vendorData.displayProperties.name)")
                return vendorData
            } catch {
                print("Error! \(error)")
            }
        }
        
        return nil
    }
    
    

}

public class InventoryItemDefinition: Codable, CustomDebugStringConvertible {
    var displayProperties: Destiny.DisplayProperties
    public var inventory: InventoryData
    public var hash: Int
    public var redacted: Bool
    public var rewards = [RewardItemDefinition]()
    public var itemTypeDisplayName: String
    public var itemTypeAndTierDisplayName: String
    public var displaySource: String
    public var itemType: Int
    
    public static var BOUNTY_TYPE = 26
    
    public var debugDescription: String {
        return "InventoryItemDefinition [Hash: \(hash), DisplayProperties: \(displayProperties)]"
    }

    public struct InventoryData: Codable {
        var tierTypeName: String
        var maxStackSize: Int
    }
    
    enum CodingKeys: String, CodingKey {
        case rewards = "value"
        case hash = "hash"
        case displayProperties
        case inventory
        case redacted
        case itemTypeDisplayName
        case itemTypeAndTierDisplayName
        case displaySource
        case itemType
    }
    
    enum RewardsKeys: String, CodingKey {
        case itemHash
        case quantity
    }
    
    public required init(from decoder: Decoder) throws {
        let item = try decoder.container(keyedBy: CodingKeys.self)
        self.hash = try item.decode(Int.self, forKey: InventoryItemDefinition.CodingKeys.hash)

        self.displayProperties = try item.decode(Destiny.DisplayProperties.self, forKey: CodingKeys.displayProperties)
        self.inventory = try item.decode(InventoryData.self, forKey: CodingKeys.inventory)
        self.redacted = try item.decode(Bool.self, forKey: CodingKeys.redacted)
        self.itemTypeDisplayName = try item.decode(String.self, forKey: CodingKeys.itemTypeDisplayName)
        self.itemTypeAndTierDisplayName = try item.decode(String.self, forKey: CodingKeys.itemTypeAndTierDisplayName)
        self.displaySource = try item.decode(String.self, forKey: CodingKeys.displaySource)
        self.itemType = try item.decode(Int.self, forKey: CodingKeys.itemType)
        
        do {
            if let rewards = try item.decodeIfPresent(RewardData.self, forKey: CodingKeys.rewards) {
                    rewards.items.forEach({
                    if($0.item != nil) {
                        self.rewards.append($0)
                    }
                })
            }
            
        }
        
    }
    
    public func encode(to encoder: Encoder) throws {
        print("Test encoder")
    }
    
}

public class MilestoneDefinition: DestinyDisplayableObject, Codable {
    
    var displayProperties: Destiny.DisplayProperties
    
    var redacted: Bool
    
    var hash: Int
    
    public var milestoneType: Int
    public var showInMilestones: Bool
    
    public var rewards: [String: MilestoneRewardDefinition]?
    
    public struct MilestoneRewardEntryDefinition: Codable {
        public var rewardEntryIdentifier: String
        public var displayProperties: Destiny.DisplayProperties
        public var rewardEntryHash: Int
        public var items: [RewardItemDefinition]?
    }
    
    public struct MilestoneRewardDefinition: Codable {
        public var categoryHash: Int
        public var displayProperties: Destiny.DisplayProperties
        public var categoryIdentifier: String
        
        public var rewardEntries: [String: MilestoneRewardEntryDefinition]?
    }
    
}


struct RewardData: Codable {
    public var items: [RewardItemDefinition]
    
    enum CodingKeys: String, CodingKey {
        case items = "itemValue"
    }
    
    
}

public class RewardItemDefinition: Codable {

    public var quantity: Int
    public var item: InventoryItemDefinition?
    
    enum RewardKeys: String, CodingKey {
        case quantity
        case itemHash
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RewardKeys.self)
        self.quantity = try container.decode(Int.self, forKey: .quantity)
        let itemHash = try container.decode(Int.self, forKey: .itemHash)
        if(itemHash == 0) {
            self.item = nil
        } else {
            if let item = try Database.decryptItem(withHash: itemHash, fromTable: "DestinyInventoryItemDefinition") {
                self.item = item
            } else {
                self.item = nil
            }
        }
    }

}

public class VendorDefinition: Codable {
    public var displayProperties: Destiny.DisplayProperties

    public var visible: Bool
    
    enum CodingKeys: String, CodingKey {
        case displayProperties
        case visible
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.visible = try container.decode(Bool.self, forKey: .visible)
        self.displayProperties = try container.decode(Destiny.DisplayProperties.self, forKey: .displayProperties)
    }

}

public struct ObjectiveData: Codable, CustomDebugStringConvertible {
    
    public var displayProperties: Destiny.DisplayProperties
    public var hash: Int
    public var redacted: Bool
    public var isCountingDownward: Bool
    public var progressDescription: String?
    public var showValueOnComplete: Bool
    public var completionValue: Int
    public var inProgressValueStyle: Int
    public var valueStyle: Int
    
    public var debugDescription: String {
        return "ObjectiveData [Hash: \(hash), displayProperties: \(displayProperties)]"
    }
    
    public enum DisplayUIStyle: Int, Codable {
        case number = 0
        case checkbox = 2
        case percentage = 3
        case hidden = 8
        case multiplier = 9
    }
    
    init() {
        self.displayProperties = Destiny.DisplayProperties()
        self.hash = 0
        self.isCountingDownward = false
        self.showValueOnComplete = false
        self.completionValue = 5
        self.inProgressValueStyle = 0
        self.valueStyle = 5
        self.redacted = false
    }
    
}

enum CompletionDisplayType: Int {
    case Automatic = 0
    case Fraction = 1
    case Checkbox = 2
    case Percentage = 3
    case DateTime = 4
    case FractionFloat = 5
    case Integer = 6
    case TimeDuration = 7
}


