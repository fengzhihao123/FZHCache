//
//  FZHCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
struct ObjectType {
    
}

struct KeyType {
    
}


class FZHCache: NSObject {
    var totalCostLimit = 0
    var countLimit = 0
    
    func object(forKey key: KeyType) -> String? {
        return nil
    }
    
    func setObject(_ obj: ObjectType, forKey key: KeyType) {
        setObject(obj, forKey: key, cost: 0)
    }
    
    func setObject(_ obj: ObjectType, forKey key: KeyType, cost g: Int) {
        
    }
    
    func removeObject(forKey key: KeyType) {
        
    }
    
    func removeAllObjects() {
        
    }
}
