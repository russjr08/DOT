import Foundation
import Alamofire
import PromiseKit

import SwiftyJSON

extension Destiny {

    class Vendor {

        var nextRefreshDate: Date?

        var enabled: Bool?
        var hash: Int?

        var sales = [VendorItem]()
        var definition: VendorDefinition?
        
        static func retrieveVendor(withHash hash: Int, fromCharacter char: String) throws -> Promise<Vendor> {
            return Promise { seal in

            if let api = Destiny.API.API_INSTANCE {
                
                    let vendor = Vendor()
                    let database = Database(with: api)
                    
                    let endpoint = "\(api.platform.rawValue)/Profile/\(String(describing: api.membershipID))/Character/\(char)/Vendors/\(hash)/"
                    vendor.definition = try database.decryptVendor(withHash: hash)
                    
                    api.fetchEndpointWithRawJSONResponse(endpoint: endpoint, parameters: Parameters(dictionaryLiteral: ("components", "400,402"))).done { (response) in
                        let vendorJSON = JSON(response.result.value!)
                        
                        let jsonDateTimeFormatter = ISO8601DateFormatter()
                        
                        vendor.nextRefreshDate = jsonDateTimeFormatter.date(from: vendorJSON["Response"]["vendor"]["data"]["nextRefreshDate"].string ?? "0")
                        vendor.hash = hash
                        vendor.enabled = vendorJSON["Response"]["vendor"]["data"]["enabled"].bool
                        
                        
                        for (_, subJSON): (String, JSON) in vendorJSON["Response"]["sales"]["data"] {
                            print(subJSON["itemHash"])
                            let item = VendorItem()
                            if(subJSON["saleStatus"].int == 0) {
                                item.saleStatus = true
                            } else {
                                item.saleStatus = false
                            }
                            
                            item.itemHash = subJSON["itemHash"].int
                            item.item = try Database.decryptItem(withHash: item.itemHash ?? 0, fromTable: "DestinyInventoryItemDefinition")
                            
                            vendor.sales.append(item)
                        }
                        
                        seal.fulfill(vendor)
                        
                    }.cauterize()
                    
            } else {
                seal.reject(NSError(domain:"VendorFailedToRetrieve", code:400, userInfo:nil))

            }
            
            }
            
            
        }
        
        static func retrieveVendorList(withCharacter char: String) throws -> Promise<[Int]> {
            return Promise { seal in
                
                if let api = Destiny.API.API_INSTANCE {
                    var vendorList: [Int] = []
                    
                    let endpoint = "\(api.platform.rawValue)/Profile/\(String(describing: api.membershipID))/Character/\(char)/Vendors/"

                    api.fetchEndpointWithRawJSONResponse(endpoint: endpoint, parameters: Parameters(dictionaryLiteral: ("components", "400,402"))).done { (response) in
                        let vendorJSON = JSON(response.result.value!)
                        
                        for (id, _): (String, JSON) in vendorJSON["Response"]["vendors"]["data"] {
                            vendorList.append(Int(id) ?? 0)
                        }
                        
                        seal.fulfill(vendorList)
                    }
                } else {
                    seal.reject(NSError(domain:"VendorListFailedToRetrieve", code:400, userInfo:nil))

                }
                

            }
        }
        
    }

    class VendorItem {
        var saleStatus: Bool?
        var itemHash: Int?
        var item: InventoryItemDefinition?
        var costs = [VendorCostSet]()
    }
    
    class VendorCostSet {
        var quantity: Int
        var itemHash: Int
        
        init(quantity: Int, itemHash: Int) {
            self.itemHash = itemHash
            self.quantity = quantity
        }
    }

}


