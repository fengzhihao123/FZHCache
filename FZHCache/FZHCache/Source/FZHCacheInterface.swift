//
//  FZHCacheInterface.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit


protocol FZHCacheInterface {
    typealias Key = String
    typealias Object = Int
    
    var totalCostLimit: Int { get }
    var countLimit: Int { get }
    
    func object(forKey key: Key) -> Object?
    func setObject(_ obj: Object, forKey key: Key, cost g: Int)
    func removeObject(forKey key: Key)
    func removeAllObjects()
}
