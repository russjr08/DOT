import Foundation

extension Destiny {

    class Vendor {

        var name: String?
        var icon: String?
        var description: String?

        var nextRefreshDate: Date?

        var enabled: Bool?

    }

    class VendorItem {
        var saleStatus: Bool?
        var quantity: Int?
        var itemHash: Int?
    }

}


