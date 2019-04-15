//
//  Extensions.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/14/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import Foundation
import UIKit

// https://gist.github.com/madcato/c5f237c6b3d9857fc61be30555d2f2e4

//extension Decodable {
//    init(_ any: Any) throws {
//        let data = try JSONSerialization.data(withJSONObject: any, options: .prettyPrinted)
//        let decoder = JSONDecoder()
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:sszzz"
//        decoder.dateDecodingStrategy = .formatted(dateFormatter)
//    
//        self = try decoder.decode(Self.self, from: data)
//    }
//}

// https://stackoverflow.com/a/35876535/1391553
extension UIStackView {
    
    convenience init(axis:NSLayoutConstraint.Axis, spacing:CGFloat) {
        self.init()
        self.axis = axis
        self.spacing = spacing
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func anchorStackView(toView view:UIView, anchorX:NSLayoutXAxisAnchor, equalAnchorX:NSLayoutXAxisAnchor, anchorY:NSLayoutYAxisAnchor, equalAnchorY:NSLayoutYAxisAnchor) {
        view.addSubview(self)
        anchorX.constraint(equalTo: equalAnchorX).isActive = true
        anchorY.constraint(equalTo: equalAnchorY).isActive = true
        
    }
    
}

// https://stackoverflow.com/a/30547710/1391553

extension NSDate: Comparable { }

public func ==(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.isEqual(to: rhs as Date)
}

public func <(lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs as Date) == .orderedAscending
}


let iconCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {

    func setAndCacheImage(withURL urlString: String) {
        let url = URL(string: urlString)
        
        image = nil
        
        if let icon = iconCache.object(forKey: urlString as AnyObject) as? UIImage {
            self.image = icon
            return
        }
        
        DispatchQueue.background(background: {
            URLSession.shared.dataTask(with: url!) {
                data, response, error in
                if data != nil {
                    DispatchQueue.main.async {
                        let imageToCache = UIImage(data: data!)
                        iconCache.setObject(imageToCache!, forKey: urlString as AnyObject)
                        self.image = imageToCache
                        print("Cached \(urlString)")
                    }
                }
            }.resume()
        })
        
    }
}

// https://stackoverflow.com/a/43081054/1391553
extension Optional {
    var orNil : String {
        if self == nil {
            return "nil"
        }
        if "\(Wrapped.self)" == "String" {
            return "\"\(self!)\""
        }
        return "\(self!)"
    }
}


extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

extension DispatchQueue {
    
    static func background(delay: Double = 0.0, background: (()->Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
}
