//
//  MemoryCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/8.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

/// 用来进行内存缓存操作的类
class MemoryCache<Value: Codable> {
    /// 内存缓存的最大容量限制，默认为 0，即无限制
    var totalCostLimit = 0
    /// 内存缓存的最大数量限制，默认为 0，即无限制
    var totalCountLimit = 0
    
    /// 当接受到内存警告时，是否自动移除所有内存缓存，默认为 true
    var autoRemoveWhenMemoryWarning = true
    /// 当 APP 进入后台时，是否自动移除所有内存缓存， 默认为 true
    var autoRemoveWhenEnterBackground = true
    
    fileprivate let storage = MemoryStorage<Value>()
    var _lock = pthread_mutex_t()
    
    private let queue = DispatchQueue(label: kMCIdentifier, attributes: DispatchQueue.Attributes.concurrent)
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func didReceiveMemoryWarningNotification() {
        if self.autoRemoveWhenMemoryWarning {
            removeAll()
        }
    }
       
    @objc func didEnterBackgroundNotification() {
        if self.autoRemoveWhenEnterBackground{
            removeAll()
        }
    }
}



private extension MemoryCache {
    /// 当前缓存的数量超过最大限制时，移除尾部节点
    func revokeCount() {
        if totalCountLimit != 0 {
            if storage.totalCountLimit > totalCountLimit {
                storage.removeTail()
            }
        }
    }
    
    /// 当前缓存的容量超过最大限制时，循环移除尾部节点，直至小于最大限制为止
    func revokeCost() {
        if totalCostLimit != 0 {
            while storage.totalCostLimit > totalCostLimit {
                storage.removeTail()
            }
        }
    }
}



extension MemoryCache: CacheBehavior {
    @discardableResult
    func set(_ value: Value?, forKey key: String, cost: Int = 0) -> Bool {
        guard let obj = value else { return false }
        pthread_mutex_lock(&_lock)
        
        if let node = storage.content[key] {
            node.object = obj
            node.cost = cost
            storage.move(toHead: node)
        } else {
            let node = LinkedNode(key: key, object: obj, cost: cost)
            storage.content[key] = node
            storage.insert(atHead: node)
        }
        
        revokeCost()
        revokeCount()
        pthread_mutex_unlock(&_lock)
        return true
    }
    
    func set(_ value: Value?, forKey key: String, cost: Int, completionHandler: @escaping ((String, Bool) -> Void)) {
        queue.async {
            let success = self.set(value, forKey: key, cost: cost)
            completionHandler(key, success)
        }
    }
    
    func object(forKey key: String) -> Value? {
        pthread_mutex_lock(&_lock)
        guard let node = storage.content[key] else {
            pthread_mutex_unlock(&_lock)
            return nil
        }
        
        storage.move(toHead: node)
        pthread_mutex_unlock(&_lock)
        return node.object
    }
    
    func object(forKey key: String, completionHandler: @escaping ((String, Value?) -> Void)) {
        queue.async {
            if let obj = self.object(forKey: key) {
                completionHandler(key, obj)
            } else {
                completionHandler(key, nil)
            }
        }
    }
    
    func contains(_ key: String) -> Bool {
        pthread_mutex_lock(&_lock)
        let exists = storage.content.keys.contains(key)
        pthread_mutex_unlock(&_lock)
        return exists
        
    }
    
    func contains(_ key: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        queue.async {
            let exists = self.contains(key)
            completionHandler(key, exists)
        }
    }
    
    func removeAll()  {
        guard !storage.content.isEmpty else {
            return
        }
        pthread_mutex_lock(&_lock)
        storage.removeAll()
        pthread_mutex_unlock(&_lock)
    }
    
    func removeAll(completionHandler: @escaping (() -> Void)) {
        queue.async {
            self.removeAll()
            completionHandler()
        }
    }
    
    func remove(forKey key: String) {
        pthread_mutex_lock(&_lock)
        if let node = storage.content[key] {
            storage.remove(node: node)
        }
        pthread_mutex_unlock(&_lock)
    }
    
    func remove(forKey key: String, completionHandler: @escaping (() -> Void)) {
        queue.async {
            self.remove(forKey: key)
            completionHandler()
        }
    }
}



/// 用来使 MemoryCache 支持下标语法，及支持 for-in 循环
extension MemoryCache: Sequence {
    subscript(key: String) -> Value? {
        set {
            if let newValue = newValue {
                set(newValue, forKey: key)
            }
        }
        get {
            if let object = object(forKey: key) { return object }
            return nil
        }
    }
    
    func makeIterator() -> MCGenerator<Value> {
        pthread_mutex_lock(&_lock)
        self.storage.setCurrentNode()
        let generator = MCGenerator(memoryCache: self)
        pthread_mutex_unlock(&_lock)
        return generator
    }
}



/// 用来支持 for-in 循环
class MCGenerator<Value: Codable>: IteratorProtocol {
    typealias Element = (key: String, value: Value)
    private var memoryCache: MemoryCache<Value>
    
    init(memoryCache: MemoryCache<Value>) {
        self.memoryCache = memoryCache
    }
    
    func next() -> Element? {
        guard let node = memoryCache.storage.next() else {
            return nil
        }
        memoryCache.storage.move(toHead: node)
        return (node.key, node.object)
    }
}
