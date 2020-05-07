//
//  FZHDiskCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

class FZHDiskCache: FZHCacheInterface {
    var totalCostLimit: Int
    var countLimit: Int
    
    init(totalCostLimit: Int, countLimit: Int, path: String) {
        self.totalCostLimit = totalCostLimit
        self.countLimit = countLimit
    }
    
    func object(forKey key: Key) -> Object? {
        return nil
    }
    
    func setObject(_ obj: Object, forKey key: Key, cost g: Int) {
        
    }
    
    func removeObject(forKey key: Key) {
        
    }
    
    func removeAllObjects() {
        
    }
    

}
