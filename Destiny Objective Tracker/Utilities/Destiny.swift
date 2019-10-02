//
//  Destiny.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 8/3/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit
import Alamofire
import PromiseKit
import SwiftyJSON

protocol DestinyDisplayableObject {
    var displayProperties: Destiny.DisplayProperties { get set}
    var redacted: Bool { get set }
    var hash: Int { get set }
}

public class Destiny {
    
    
    public class Constants {
        static let BASE_URL = "https://www.bungie.net/Platform/Destiny2/"

        static let TOKEN_ENDPOINT = "https://www.bungie.net/Platform/App/OAuth/Token/"
        
        static let API_KEY = "9d031cfae6b4418691ab95cca9391647"
        static let CLIENT_ID = "24297"
        static let CLIENT_SECRET = "hn8U0WGNAJ3sPOZSEDSj2PPY4wLpZX2JVMWq2qL0dJk"
    }
    
    enum DestinyError: Error {
        case AuthenticationError(String)
        case InternalError(String)
        case RefreshTokenExpiredError
        case InstanceItemNotFound
    }
    
    public enum Race: String {
        case EXO = "Exo", AWOKEN = "Awoken", HUMAN = "Human"
    }
    
    public enum Class: String {
        case HUNTER = "Hunter", WARLOCK = "Warlock", TITAN = "Titan"
    }
    
    
    
    
    public class Item: Codable, CustomDebugStringConvertible, DestinyDisplayableObject {
        
        
        
        public var itemHash: Int?
        public var hash: Int

        public var quantity: Int?
        public var bindStatus: Int?
        public var bucketHash: Int?
        public var transferStatus: Int?
        public var lockable: Bool?
        public var redacted: Bool
        public var state: Int?
        public var displayProperties: DisplayProperties
        
        public var expirationDate: Date?
        
        public var name: String?
        public var description: String?
        public var icon: String?
        
        public var itemInstanceId: String?
        
        public var type: String?
        
        public var objectives: [Objective] = [Objective]()
        public var definition: InventoryItemDefinition?
        
        public var debugDescription: String {
            return "Item Name: \(self.name.debugDescription), Item Hash: \(self.itemHash.debugDescription), Bucket: \(self.bucketHash.debugDescription), Instance ID: \(self.itemInstanceId), Description: \(self.description.debugDescription), Objectives: [\(self.objectives.debugDescription)], Item Type: \(self.definition?.itemType)"
        }
        
        enum CodingKeys: String, CodingKey {
            case rewards = "value"
        }

        public enum Rarity {
            case EXOTIC, LEGENDARY, UNCOMMON, RARE
        }
        
        init(props: DisplayProperties) {
            self.hash = 0
            self.redacted = false
            self.displayProperties = props
        }
        
        init(from json: [String: Any]) {
            self.itemHash = json["itemHash"] as? Int
            self.hash = itemHash ?? 0
            self.quantity = json["quantity"] as? Int
            self.bindStatus = json["bindStatus"] as? Int
            self.bucketHash = json["bucketHash"] as? Int
            self.transferStatus = json["transferStatus"] as? Int
            self.lockable = json["lockable"] as? Bool
            self.state = json["state"] as? Int
            self.itemInstanceId = json["itemInstanceId"] as? String
            self.displayProperties = DisplayProperties()

            if let expDate = json["expirationDate"] as? String {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
                let date = dateFormatter.date(from: expDate)
                if let date = date {
                    self.expirationDate = date
                }
            }
            
            do {
                let invItem = try Database.decryptItem(withHash: self.itemHash!, fromTable: "DestinyInventoryItemDefinition")
                
                self.name = invItem?.displayProperties.name
                self.description = invItem?.displayProperties.description
                self.icon = invItem?.displayProperties.icon
                self.redacted = invItem?.redacted ?? false
                self.type = ""
                
                self.definition = invItem
            } catch {
                print("Oh no :(")
            }
            
            self.redacted = false

        }
        
        public required init(from decoder: Decoder) throws {
            print("Test decoder")
            let displayProps = try decoder.container(keyedBy: DisplayProperties.CodingKeys.self)
            let name = try displayProps.decode(String.self, forKey: .name)
            let description = try displayProps.decode(String.self, forKey: .description)
            let icon = try displayProps.decode(String.self, forKey: .icon)
            let subtitle = try displayProps.decode(String.self, forKey: .subtitle)
            self.displayProperties = DisplayProperties(name: name, icon: icon, description: description, subtitle: subtitle)
            self.redacted = false
            self.hash = 0
        }
        
        public func encode(to encoder: Encoder) throws {
            
        }
        
        func updateInstance() -> Promise<Void> {
            return Promise { seal in
                
            }
        }
        
        func updateAttributes() {

            do {
                let invItem = try Database.decryptItem(withHash: self.itemHash!, fromTable: "DestinyInventoryItemDefinition")
                
                self.name = invItem?.displayProperties.name
                self.description = invItem?.displayProperties.description
                self.icon = invItem?.displayProperties.icon
                self.redacted = invItem?.redacted ?? false
                self.type = ""
                
                
                self.definition = invItem
            } catch {
                print("Oh no :(")
            }
        }
        
    }
    
    public struct DisplayProperties: Codable {
        var name: String?
        var icon: String?
        var description: String?
        var subtitle: String?
        
        enum CodingKeys: String, CodingKey {
            case name
            case icon
            case description
            case subtitle
        }
        
    }
    
    @objcMembers public class Objective: NSObject, Codable {
        
        public var objectiveHash: Int
        dynamic public var progress = 0
        public var completionValue = 0
        public var complete: Bool = false
        public var visible: Bool?
        public var data: ObjectiveData?
        
        
        override public var debugDescription: String {
            return "Objective [Name: \(data?.displayProperties.name), Description: \(data?.progressDescription)]"
        }
        
        public required init(from decoder: Decoder) throws {
            let response = try decoder.container(keyedBy: CodingKeys.self)
            self.objectiveHash = try response.decode(Int.self, forKey: .objectiveHash)
            self.completionValue = try response.decode(Int.self, forKey: .completionValue)
            self.progress = try response.decode(Int.self, forKey: .progress)
            self.complete = try response.decode(Bool.self, forKey: .complete)
            
            let database = Database.init(with: Destiny.API())
            self.data = try database.decryptObjective(withHash: self.objectiveHash)
            
        }
        
        init(withHash hash: Int) {
            let database = Database(with: Destiny.API.init())
            self.objectiveHash = hash

            do {
                let objData = try database.decryptObjective(withHash: hash)
                self.data = objData
            } catch {
                print("Failed to decode Objective with hash \(hash)")
            }
        }
                
    }
    
    public class Character {
        
        public var race: Race
        public var charClass: Class
        
        public var emblemPath = ""
        
        public var level = 0
        public var light = 0
        
        public var id = ""
        public var membershipId = ""
        public var membershipType: DestinyMembership.MembershipType
        
        public var lastPlayed: Date?
        
        public var inventory = [Item]()
        public var milestones = [Destiny.API.MilestoneResponse]()
        public var storyMilestones = [Destiny.API.MilestoneResponse]()
        public var extendedMilestones = [Destiny.API.MilestoneResponse]()



        init(fromRace race: Race, withClass charClass: Class, withId id: String, withLight light: Int, withLevel level: Int, withEmblem emblem: String, withLastPlayed lastPlayed: Date? = nil, withMembershipId membershipId: String, withMembershipType membershipType: DestinyMembership.MembershipType) {
            self.race = race
            self.charClass = charClass
            self.id = id
            self.light = light
            self.level = level
            self.emblemPath = emblem
            self.lastPlayed = lastPlayed
            self.membershipId = membershipId
            self.membershipType = membershipType
        }
        
        convenience init?(json: [String: Any]) {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
            
            guard let light = json["light"] as? Int,
            let levelProgression = json["levelProgression"] as? [String: AnyObject],
            let level = levelProgression["level"] as? Int,
            let race = json["raceType"] as? Int,
            let charID = json["characterId"] as? String,
            let membershipId = json["membershipId"] as? String,
            let membershipType = DestinyMembership.MembershipType.init(rawValue: json["membershipType"] as! Int),
            let emblemPath = json["emblemPath"] as? String,
            let lastPlayed = dateFormatter.date(from: json["dateLastPlayed"] as! String),
            let classType = json["classType"] as? Int
                else {
                    return nil
            }
            
            
            self.init(fromRace: Character.getRaceFromId(withId: race), withClass: Character.getClassFromId(withId: classType), withId: charID, withLight: light, withLevel: level, withEmblem: emblemPath, withLastPlayed: lastPlayed, withMembershipId: membershipId, withMembershipType: membershipType)
            
        }
        
        func updateInventory(withAPI api: Destiny.API) -> Promise<Void> {
            
            let buckets = [1345459588, 1585787867, 14239492, 20886954, 3448274439, 3551918588]
            
            return Promise { seal in
                let endpoint = "\(self.membershipType.rawValue)/Profile/\(String(describing: self.membershipId))/Character/\(self.id)/"
                DispatchQueue.global(qos: .background).async {
                    api.fetchEndpoint(endpoint: endpoint, parameters: Parameters(dictionaryLiteral: ("components", "200,202,102,201,205,301"))).done({ (response) in
                        print(response)
                        self.inventory.removeAll()
                        self.milestones.removeAll()
                        guard let res = response.value(forKey: "Response") as? [String: AnyObject],
                            let inv = res["inventory"] as? [String: AnyObject],
                            let character = res["character"] as? [String: AnyObject],
                            let progressions = res["progressions"] as? [String: AnyObject],
                            let equipment = res["equipment"] as? [String: AnyObject],
                            let progressionData = progressions["data"] as? [String: AnyObject],
                            let milestones = progressionData["milestones"] as? [String: AnyObject],
                            let characterData = character["data"] as? [String: AnyObject],
                            let data = inv["data"] as? [String: AnyObject],
                            let items = data["items"] as? [AnyObject],
                            let equipmentData = equipment["data"] as? [String: AnyObject],
                            let equipmentItems = equipmentData["items"] as? [AnyObject]
                            else {
                                print("Something failed...")
                                return
                        }
                        
                        self.light = characterData["light"] as! Int
                        
                        for item in items {
                            
                            let itemData = Item(from: item as! [String: AnyObject])
                            
                            
                            if(buckets.contains(itemData.bucketHash!) && !(itemData.redacted)) {
                                self.inventory.append(itemData)
                            }

                            
                            // TODO: Weapons
                        }
                        
                        // Currently equipped items (Armor/Weapons)
                        for item in equipmentItems {
                            let itemData = Item(from: item as! [String: AnyObject])

                            if(buckets.contains(itemData.bucketHash!) && !(itemData.redacted)) {
                                self.inventory.append(itemData)
                            }
                        }
                        
                        guard let componentsTree = res["itemComponents"] as? [String: AnyObject],
                            let objTree = componentsTree["objectives"] as? [String: AnyObject],
                            let dataTree = objTree["data"] as? [String: AnyObject]
                            else {
                                print("Something failed...")
                                return
                        }
                        
                        for (itemInstanceId, value) in dataTree {
                            
                            if let objList = (value["objectives"] as? [AnyObject]) {
                                if let itemEntryIndex = self.inventory.firstIndex(where: {$0.itemInstanceId == itemInstanceId}) {
                                    
                                    for objective in objList {
                                        let obj = Objective(withHash: objective["objectiveHash"] as! Int)
                                        obj.progress = objective["progress"] as? Int ?? 0
                                        obj.completionValue = objective["completionValue"] as? Int ?? 0
                                        obj.complete = objective["complete"] as? Bool ?? false
                                        obj.visible = objective["visible"] as? Bool
                                        self.inventory[itemEntryIndex].objectives.append(obj)
                                    }
                                    
                                    
                                }
                            }
                        }
                        
                        var sortedMilestones: [Destiny.API.MilestoneResponse] = []
                        
                        for milestone in milestones {
                            if let milestoneJSON = try? JSONSerialization.data(withJSONObject: milestone.value, options: .prettyPrinted) {
                                let text = String(data: milestoneJSON, encoding: .ascii)
                                
                                let decoder = JSONDecoder()
                                let milestoneResponse = try decoder.decode(Destiny.API.MilestoneResponse.self, from: ((text?.data(using: .utf8)!)!))
                                
                                sortedMilestones.append(milestoneResponse)
                            }
                        }

                        sortedMilestones.sort(by: { $0.milestoneHash > $1.milestoneHash })

                        for milestoneResponse in sortedMilestones {
                            if(milestoneResponse.milestoneHash == 534869653) {
                                // Always whitelist Xur
                                milestoneResponse.definition.showInMilestones = true
                            }
                            if milestoneResponse.definition.showInMilestones {
                                self.milestones.append(milestoneResponse)
                                print("Added milestone to character: \(milestoneResponse.definition.displayProperties.name?.description) -- \(milestoneResponse.definition.hash.description)")
                            }

                            if(milestoneResponse.milestoneType == 2) {
                                // These are usually story milestones

                                self.milestones.append(milestoneResponse)
                            }

                            if(milestoneResponse.milestoneType != 2 && milestoneResponse.definition.showInMilestones == false) {
                                // All other milestones

                                self.extendedMilestones.append(milestoneResponse)
                            }
                        }

                        print("Done retrieving milestones!")

                        seal.fulfill(())
                    }).cauterize()
                }
                
            }
        }
        
        static func getRaceFromId(withId id: Int) -> Race {
            switch id {
            case 0:
                return Race.HUMAN
            case 1:
                return Race.AWOKEN
            case 2:
                return Race.EXO
            default:
                return Race.HUMAN
            }
        }
        
        static func getClassFromId(withId id: Int) -> Class {
            switch id {
            case 0:
                return Class.TITAN
            case 1:
                return Class.HUNTER
            case 2:
                return Class.WARLOCK
            default:
                return Class.TITAN
            }
        }
    }

    public class DestinyMembership {

        public enum MembershipType: Int, CustomStringConvertible {
            case PC = 4, XBOX = 1, PS = 2

            public var description: String {
                switch self {
                case .PC: return "Battle.net"
                case .XBOX: return "Xbox One"
                case .PS: return "PlayStation 4"
                }
            }
        }

        var iconPath: String
        var membershipType: MembershipType
        var membershipId: String
        var displayName: String

        init(fromIcon icon: String, withType type: MembershipType, withId id: String, withName displayName: String) {
            self.iconPath = icon
            self.membershipType = type
            self.membershipId = id
            self.displayName = displayName
        }

    }
    
    /// Wrapper class for accessing the Destiny 2 API.
    public class API {
        
        private let defaults = UserDefaults.init()
        
        
        public static var API_INSTANCE: Destiny.API?
        
        init() {
            Destiny.API.API_INSTANCE = self
        }
        
        public struct MilestoneResponse: Codable {
            public var milestoneHash: Int
            public var definition: MilestoneDefinition
            public var rewards: [RewardCollection]?
            public var startDate: Date?
            public var endDate: Date?
            public var activities: [Activity]?
            public var availableQuests: [Quest] = []
            public var milestoneType: Int?
            
            public struct Activity: Codable {
                public var activityHash: Int
                public var challenges: [Challenge]
                
                public struct Challenge: Codable {
                    public var objective: Objective
                }

            }
            
            public struct Quest: Codable {
                public var questItemHash: Int
                public var status: QuestStep
                
                public var questItem: InventoryItemDefinition? {
                    get {
                        do {
                            return try Database.decryptItem(withHash: self.questItemHash, fromTable: "DestinyInventoryItemDefinition")
                        } catch {
                            print("Could not auto decrypt quest item with hash \(self.questItemHash) due to \(error)")
                            return nil
                        }
                    }
                }
                
                public struct QuestStep: Codable {
                    public var stepHash: Int
                    public var stepObjectives: [Objective]
                }
                
            }
            
            public struct RewardCollection: Codable {
                public var entries: [RewardEnrty]
                public struct RewardEnrty: Codable {
                    public var rewardEntryHash: Int
                    public var redeemed: Bool
                    public var earned: Bool
                }
            }
            public init(from decoder: Decoder) throws {
                let response = try decoder.container(keyedBy: CodingKeys.self)
                self.milestoneHash = try response.decode(Int.self, forKey: CodingKeys.milestoneHash)
                self.rewards = try response.decodeIfPresent([RewardCollection].self, forKey: CodingKeys.rewards)
                self.activities = try response.decodeIfPresent([Activity].self, forKey: CodingKeys.activities)
                self.availableQuests = try response.decodeIfPresent([Quest].self, forKey: .availableQuests) ?? []
                let startDateStr = try response.decodeIfPresent(String.self, forKey: CodingKeys.startDate)
                let endDateStr = try response.decodeIfPresent(String.self, forKey: CodingKeys.endDate)
                self.milestoneType = try response.decodeIfPresent(Int.self, forKey: CodingKeys.milestoneType)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                dateFormatter.locale = Locale.init(identifier: "en_US_POSIX")
                
                if let startDateStr = startDateStr {
                    self.startDate = dateFormatter.date(from: startDateStr)
                }
                
                if let endDateStr = endDateStr {
                    self.endDate = dateFormatter.date(from: endDateStr)
                }
                
                let database = Database(with: Destiny.API.init())

                
                self.definition = try database.decryptMilestone(withHash: self.milestoneHash)!
            }
            
        }
        
        var membershipID: String {
            get {
                return defaults.string(forKey: "membership_id") ?? "unknown"
            }
            
            set {
                defaults.set(newValue, forKey: "membership_id")
            }
        }
        
        var access_token: String {
            get {
                return defaults.string(forKey: "access_token") ?? "unknown"
            }
            
            set {
                defaults.set(newValue, forKey: "access_token")
            }
        }
        
        var refresh_token: String {
            get {
                return defaults.string(forKey: "refresh_token") ?? "unknown"
            }
            
            set {
                defaults.set(newValue, forKey: "refresh_token")
            }
        }

        var platform: DestinyMembership.MembershipType {
            get {
                return DestinyMembership.MembershipType.init(rawValue: defaults.integer(forKey: "platform")) ?? DestinyMembership.MembershipType.PC
            }

            set {
                defaults.set(newValue.rawValue, forKey: "platform")
            }
        }
        
        
        /// Checks to see if the current access token is valid (or in other words, hasn't expired).
        /// - returns: Whether the saved access token is valid. Can also be false if no token was found.
        func checkAccessToken() -> Bool {
            
            // Check if we currently have an access token. If we do, check to see if it is still current.
            
            if(defaults.string(forKey: "access_token") != nil) {
                let now = Date.init()
                let access_expiration = defaults.object(forKey: "access_token_expiration") as? Date
                
                if(access_expiration == nil) {
                    return false
                }
                
                return !(now > access_expiration!)
            }
            
            return false
            
        }
        
        /// Checks to see if the current refresh token is valid (or in other words, hasn't expired).
        /// - returns: Whether the saved refresh token is valid. Can also be false if no token was found.
        func checkRefreshToken() -> Bool {
            
            // Check if we currently have an refresh token. If we do, check to see if it is still current.
            
            if(defaults.string(forKey: "access_token") != nil) {
                let now = Date.init()
                let access_expiration = defaults.object(forKey: "refresh_token_expiration") as? Date
                
                if(access_expiration == nil) {
                    return false
                }
                
                return !(now > access_expiration!)
            }
            
            return false
            
        }
        
        /// Performs a call to the Bungie API to attempt to gain an access token.
        ///
        /// - returns: A Promise which is resolved when the access token operation is completed.
        ///
        func createAccessToken(withOAuthToken: String) -> Promise<Void> {
            print("Creating access token with OAuthToken \(withOAuthToken)")
            return Promise { seal in
                let parameters: Parameters = [
                    "grant_type": "authorization_code",
                    "client_id": Destiny.Constants.CLIENT_ID,
                    "client_secret": Destiny.Constants.CLIENT_SECRET,
                    "code": withOAuthToken
                ]
                
                request(Destiny.Constants.TOKEN_ENDPOINT, method: .post, parameters: parameters)
                    .responseJSON { response in switch response.result {
                    case .success(let JSON):
                        let response = JSON as! NSDictionary
                        print(response)
                        
                        // Check if we received an invalid auth error, and if so, return to login screen.
                        if(response.object(forKey: "error") != nil) {
                            seal.reject(DestinyError.AuthenticationError(response.object(forKey: "error") as! String))
                            break
                        }
                        
                        // Save & Persist Access/Refresh Tokens
                        self.defaults.set(response.object(forKey: "access_token"), forKey: "access_token")
                        self.defaults.set(response.object(forKey: "refresh_token"), forKey: "refresh_token")
                        self.defaults.set(response.object(forKey: "membership_id"), forKey: "membership_id")
                        do {
                            self.defaults.set(try Date.init(timeIntervalSinceNow: TimeInterval.init(Double.init(response.object(forKey: "expires_in") as! Int64))), forKey: "access_token_expiration")
                            self.defaults.set(try Date.init(timeIntervalSinceNow: TimeInterval.init(Double.init(response.object(forKey: "refresh_expires_in") as! Int64))), forKey: "refresh_token_expiration")
                        } catch {
                            print("Error occurred while trying to parse time/date")
                        }

                        self.defaults.synchronize()
                        
                        seal.fulfill(())
                        break
                        
                        
                    case .failure(let error):
                        print("Uh oh... \(error)")
                        seal.reject(DestinyError.InternalError(error.localizedDescription))
                        break
                    }
                }
            }
            
        }
        
        /// Performs a call to the Bungie API to refresh an access token.
        ///
        /// - parameters:
        ///   - completion: The completion handler for this call. A Bool is passed in which is the result of whether the operation was successful or not.
        ///
        func refreshAccessToken() -> Promise<Void> {
            return Promise { seal in
                if(defaults.string(forKey: "refresh_token") != nil) {
                    let now = Date.init()
                    let access_expiration = defaults.object(forKey: "refresh_token_expiration") as! Date
                    
                    if(now > access_expiration) {
                        seal.reject(DestinyError.RefreshTokenExpiredError)
                        return
                    }
                }
                
                let parameters: Parameters = [
                    "grant_type": "refresh_token",
                    "client_id": Destiny.Constants.CLIENT_ID,
                    "client_secret": Destiny.Constants.CLIENT_SECRET,
                    "refresh_token": refresh_token
                ]
                
                request(Destiny.Constants.TOKEN_ENDPOINT, method: .post, parameters: parameters)
                    .responseJSON { response in switch response.result {
                    case .success(let JSON):
                        let response = JSON as! NSDictionary
                        print(response)
                        
                        // Check if we received an invalid auth error, and if so, return to login screen.
                        if(response.object(forKey: "error") != nil) {
                            seal.reject(DestinyError.AuthenticationError(response.object(forKey: "error") as! String))
                            break
                        }
                        
                        // Save & Persist Refresh Tokens
                        self.defaults.set(response.object(forKey: "access_token"), forKey: "access_token")
                        self.defaults.set(Date.init(timeIntervalSinceNow: TimeInterval.init(Double.init(response.object(forKey: "expires_in") as! Int))), forKey: "access_token_expiration")
                        
                        seal.fulfill(())
                        break
                        
                        
                    case .failure(let error):
                        print("Uh oh... \(error)")
                        seal.reject(DestinyError.InternalError(error.localizedDescription))
                    }
                }
            }
            
            
        }
        
        func fetchEndpoint(endpoint: String, parameters: Parameters?) -> Promise<NSDictionary> {
            if(!checkAccessToken()) {
                refreshAccessToken().then {
                    return self.fetchEndpointInternal(endpoint: endpoint, parameters: parameters)
                }.cauterize()
            }
            
            return self.fetchEndpointInternal(endpoint: endpoint, parameters: parameters)
        }
        
        private func fetchEndpointInternal(endpoint: String, parameters: Parameters?) -> Promise<NSDictionary> {
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(access_token)",
                "X-API-KEY": Destiny.Constants.API_KEY
            ]
            let url = Destiny.Constants.BASE_URL + endpoint
            return Promise { seal in
        
                request(url, parameters: parameters, encoding: URLEncoding(destination: .methodDependent), headers: headers)
                    .responseJSON { response in
                        switch response.result {
                        case .success(let JSON):
                            let response = JSON as! NSDictionary
                            if(response["ErrorStatus"] as! String == "Success") {
                                seal.fulfill(response)
                            } else {

                                seal.reject(NSError.init(domain: "", code: 500, userInfo: ["Bungie Error": response["Message"] as! String]))
                            }
                            break
                        default:
                            seal.reject(DestinyError.InternalError("Failed to fetch endpoint \(endpoint)"))
                            break
                        }
                }
            }
        }
        
        func fetchEndpointWithRawJSONResponse(endpoint: String, parameters: Parameters?) -> Promise<DataResponse<Any>> {
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(access_token)",
                "X-API-KEY": Destiny.Constants.API_KEY
            ]
            let url = Destiny.Constants.BASE_URL + endpoint
            return Promise { seal in
                
                request(url, parameters: parameters, encoding: URLEncoding(destination: .methodDependent), headers: headers)
                    .responseJSON { response in
                       
                        if(response.result.isSuccess) {
                            seal.fulfill(response)
                        } else {
                            
                            seal.reject(NSError.init(domain: "", code: 500, userInfo: ["Bungie Error": "Not Yet Implemented"]))
                        }
                }
            }
        }

        private func fetchEndpointOutsideOfDestiny(endpoint: String, parameters: Parameters?) -> Promise<String> {
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(access_token)",
                "X-API-KEY": Destiny.Constants.API_KEY
            ]
            let url = "https://www.bungie.net/Platform/\(endpoint)"
            return Promise { seal in

                request(url, parameters: parameters, encoding: URLEncoding(destination: .methodDependent), headers: headers)

                        .responseString { response in
                            switch(response.result) {
                            case .success(_):
                                if let data = response.result.value {
                                    seal.fulfill(data)
                                }
                            case .failure(_):
                                if let error = response.result.error {
                                    seal.reject(error)
                                }
                            }
                        }
            }
        }
        
        func getCharacters() -> Promise<[Character]> {
            var characters = [Character]()
            
            return Promise { seal in
                self.fetchEndpoint(endpoint: "\(self.platform.rawValue)/Profile/\(self.membershipID)", parameters: Parameters(dictionaryLiteral: ("components", "100, 200"))).done( { response in
                    
                    if let dictionary = response.object(forKey: "Response") as? [String: Any] {
                        if let charData = dictionary["characters"] as? [String: Any] {
                            if let data = charData["data"] as? [String: AnyObject] {
                                for (id, char) in data {
                                    print("Found character \(id) with data: \(char)")
                                    if let character = Character(json: char as! [String: AnyObject]) {
                                        characters.append(character)
                                    }
                                }
                                
                            }
                        }
                    }
                    
                }).done {
                    seal.fulfill(characters)
                }.catch({ (error) in
                    switch error {
                    case Destiny.DestinyError.InternalError(let errorMessage):
                        seal.reject(error)
                    default:
                        seal.reject(error)
                    }
                })
            }
            
        }

        /// Makes a call to the Bungie API to check what platforms a player is registered to.
        func getDestinyMemberships() -> Promise<[DestinyMembership]> {
            var memberships = [DestinyMembership]()
            return Promise { seal in
                self.fetchEndpointOutsideOfDestiny(endpoint: "User/GetMembershipsById/\(self.membershipID)/-1/", parameters: nil).done({ response in
                    do {
                        let json = try JSON(data: response.data(using: .utf8)!)
                        if let membershipList = json["Response"]["destinyMemberships"].arrayObject {
                            print(membershipList)

                            for(key, subJSON) in json["Response"]["destinyMemberships"] {

                                guard let iconPath = subJSON["iconPath"].string,
                                      let id = subJSON["membershipId"].string,
                                      let memberType = subJSON["membershipType"].int,
                                      let name = subJSON["displayName"].string
                                else {
                                    print("Error extracting profile data!")
                                    return
                                }

                                memberships.append(.init(fromIcon: iconPath, withType: DestinyMembership.MembershipType.init(rawValue: memberType)!, withId: id, withName: name))

                            }

                            print(memberships)

                            seal.fulfill(memberships)

                        }
                    } catch {
                        print("Failed to fetch list of memberships!")
                    }

                })
            }

        }
        
    }
    
}
