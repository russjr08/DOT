//
//  Observable.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 9/20/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import Foundation

class Observable<T>{
    typealias WillSet = (_ currentValue:T?, _ tobeValue:T?)->()
    typealias DidSet = (_ oldValue:T?,_ currentValue:T?)->()
    typealias Observer = (pre:WillSet,post:DidSet)
    
    var observers = Dictionary<String,Observer>()
    
    var observableProperty:T?{
        willSet(newValue){
            for (_,observer) in observers{
                observer.pre(observableProperty,newValue)
            }
        }
        didSet{
            for (_,observer) in observers{
                observer.post(oldValue,observableProperty)
            }
        }
    }
    
    func addObserver(identifier:String, observer:Observer){
        observers[identifier] = observer
    }
    
    func removeObserver(identifer:String){
        observers.removeValue(forKey: identifer)
    }
}
