//
//  FZHMemoryCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
class FZHMemoryCache: FZHCacheInterface {
    var totalCostLimit: Int
    var countLimit: Int
    private var _lock = os_unfair_lock()
    private var _linkedList: FZHLinkedList
    init(totalCostLimit: Int, countLimit: Int) {
        self.totalCostLimit = totalCostLimit
        self.countLimit = countLimit
        
        _linkedList = FZHLinkedList()
        _linkedList.totalCost = totalCostLimit
        _linkedList.count = countLimit
    }
    
    func object(forKey key: KeyType) -> ObjectType? {
        os_unfair_lock_lock(&_lock)
        defer {
            os_unfair_lock_unlock(&_lock)
        }
        
        if let obj = _linkedList.content[key] {
            return obj
        }
        return nil
    }
    
    func setObject(_ obj: ObjectType, forKey key: KeyType, cost g: Int) {
        os_unfair_lock_lock(&_lock)
        defer {
            os_unfair_lock_unlock(&_lock)
        }
        
        if let node = _linkedList.getNode(forKey: key) {
            let newCost = node.cost - g
            _linkedList.totalCost += newCost
            node.time = CACurrentMediaTime()
            node.val = obj
            _linkedList.moveNode(toHead: node)
        } else {
            let node = FZHLinkedNode(val: obj, key: key, time: CACurrentMediaTime(), cost: g)
            _linkedList.insertNode(atHead: node)
        }
        
        if _linkedList.totalCost > totalCostLimit {
            reduce(ToCostLimit: totalCostLimit)
        }
        
        if _linkedList.count > countLimit {
            _linkedList.removeRear()
        }
    }
    
    func removeObject(forKey key: KeyType) {
        os_unfair_lock_lock(&_lock)
        defer {
            os_unfair_lock_unlock(&_lock)
        }
        
        if let node = _linkedList.getNode(forKey: key) {
            _linkedList.content.removeValue(forKey: key)
            _linkedList.removeNode(node: node)
        }
    }
    
    func removeAllObjects() {
        os_unfair_lock_lock(&_lock)
        defer {
            os_unfair_lock_unlock(&_lock)
        }
        
        _linkedList.removeAll()
    }
    
    private func reduce(ToCostLimit costLimit: Int) {
        _linkedList.removeRear()
    }
}
