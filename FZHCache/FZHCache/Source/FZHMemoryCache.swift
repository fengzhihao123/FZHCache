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
    private let _linkedList = FZHLinkedList()
    private var removeAllOnMemoryWarning = true
    private var removeAllOnEnterBackground = true
    
    init(totalCostLimit: Int, countLimit: Int, removeAllOnMemoryWarning: Bool = true, removeAllOnEnterBackground: Bool = true) {
        self.totalCostLimit = totalCostLimit
        self.countLimit = countLimit
        self.removeAllOnMemoryWarning = removeAllOnMemoryWarning
        self.removeAllOnEnterBackground = removeAllOnEnterBackground
        
        NotificationCenter.default.addObserver(self, selector: #selector(_appDidReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_appDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func object(forKey key: Key) -> Object? {
        os_unfair_lock_lock(&_lock)
        defer {
            os_unfair_lock_unlock(&_lock)
        }
        
        if let node = _linkedList.content[key] {
            node.time = CACurrentMediaTime()
            _linkedList.moveNode(toHead: node)
            return node.val
        }
        return nil
    }
    
    func setObject(_ obj: Object, forKey key: Key, cost g: Int) {
        os_unfair_lock_lock(&_lock)
        defer {
            os_unfair_lock_unlock(&_lock)
        }
        if let node = _linkedList.content[key] {
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
            _reduce(ToCostLimit: totalCostLimit)
        }
        
        if _linkedList.count > countLimit {
            _linkedList.removeRear()
        }
    }
    
    func removeObject(forKey key: Key) {
        os_unfair_lock_lock(&_lock)
        defer {
            os_unfair_lock_unlock(&_lock)
        }
        
        if let node = _linkedList.content[key] {
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeAllObjects()
    }
    
    @objc private func _appDidReceiveMemoryWarningNotification() {
        if removeAllOnMemoryWarning {
            removeAllObjects()
        }
    }
    
    @objc private func _appDidEnterBackgroundNotification() {
        if removeAllOnEnterBackground {
            removeAllObjects()
        }
    }
    
    private func _reduce(ToCostLimit costLimit: Int) {
        _linkedList.removeRear()
    }
}