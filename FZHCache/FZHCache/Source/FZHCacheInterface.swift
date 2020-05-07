//
//  FZHCacheInterface.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

protocol FZHCacheInterface {
    var totalCostLimit: Int { get }
    var countLimit: Int { get }
    
    func object(forKey key: KeyType) -> ObjectType?
    func setObject(_ obj: ObjectType, forKey key: KeyType, cost g: Int)
    func removeObject(forKey key: KeyType)
    func removeAllObjects()
}
