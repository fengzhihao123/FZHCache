//
//  MemoryCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/8.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

/// 用来进行内存缓存操作的类
public class MemoryCache<Value: Codable> {
    /// 内存缓存的最大容量限制，默认为 0，即无限制
    public var totalCostLimit = 0
    /// 内存缓存的最大数量限制，默认为 0，即无限制
    public var totalCountLimit = 0
    
    /// 当接受到内存警告时，是否自动移除所有内存缓存，默认为 true
    public var autoRemoveWhenMemoryWarning = true
    /// 当 APP 进入后台时，是否自动移除所有内存缓存， 默认为 true
    public var autoRemoveWhenEnterBackground = true
    
    fileprivate let _storage = MemoryStorage<Value>()
    private var _lock = os_unfair_lock()
    private let _queue = DispatchQueue(label: kMCIdentifier, attributes: DispatchQueue.Attributes.concurrent)
    
    public init() {
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
            if _storage.totalCountLimit > totalCountLimit {
                _storage.removeTail()
            }
        }
    }
    
    /// 当前缓存的容量超过最大限制时，循环移除尾部节点，直至小于最大限制为止
    func revokeCost() {
        if totalCostLimit != 0 {
            while _storage.totalCostLimit > totalCostLimit {
                _storage.removeTail()
            }
        }
    }
}



extension MemoryCache: CacheBehavior {
    @discardableResult
    public func set(_ value: Value?, forKey key: String, cost: Int = 0) -> Bool {
        guard let obj = value else { return false }
        guard os_unfair_lock_trylock(&_lock) else { return false }
        
        if let node = _storage.content[key] {
            node.object = obj
            node.cost = cost
            _storage.move(toHead: node)
        } else {
            let node = LinkedNode(key: key, object: obj, cost: cost)
            _storage.content[key] = node
            _storage.insert(atHead: node)
        }
        
        revokeCost()
        revokeCount()
        os_unfair_lock_unlock(&_lock)
        return true
    }
    
    public func set(_ value: Value?, forKey key: String, cost: Int, completionHandler: @escaping ((String, Bool) -> Void)) {
        _queue.async {
            let success = self.set(value, forKey: key, cost: cost)
            completionHandler(key, success)
        }
    }
    
    public func object(forKey key: String) -> Value? {
        guard os_unfair_lock_trylock(&_lock) else { return nil}
        guard let node = _storage.content[key] else {
            os_unfair_lock_unlock(&_lock)
            return nil
        }
        
        _storage.move(toHead: node)
        os_unfair_lock_unlock(&_lock)
        return node.object
    }
    
    public func object(forKey key: String, completionHandler: @escaping ((String, Value?) -> Void)) {
        _queue.async {
            if let obj = self.object(forKey: key) {
                completionHandler(key, obj)
            } else {
                completionHandler(key, nil)
            }
        }
    }
    
    public func contains(_ key: String) -> Bool {
        guard os_unfair_lock_trylock(&_lock) else { return false }
        let exists = _storage.content.keys.contains(key)
        os_unfair_lock_unlock(&_lock)
        return exists
        
    }
    
    public func contains(_ key: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        _queue.async {
            let exists = self.contains(key)
            completionHandler(key, exists)
        }
    }
    
    public func removeAll()  {
        guard !_storage.content.isEmpty else {
            return
        }
        guard os_unfair_lock_trylock(&_lock) else { return }
        _storage.removeAll()
        os_unfair_lock_unlock(&_lock)
    }
    
    public func removeAll(completionHandler: @escaping (() -> Void)) {
        _queue.async {
            self.removeAll()
            completionHandler()
        }
    }
    
    public func remove(forKey key: String) {
        guard os_unfair_lock_trylock(&_lock) else { return }
        if let node = _storage.content[key] {
            _storage.remove(node: node)
        }
        os_unfair_lock_unlock(&_lock)
    }
    
    public func remove(forKey key: String, completionHandler: @escaping (() -> Void)) {
        _queue.async {
            self.remove(forKey: key)
            completionHandler()
        }
    }
}



/// 用来使 MemoryCache 支持下标语法，及支持 for-in 循环
extension MemoryCache: Sequence {
    public subscript(key: String) -> Value? {
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
    
    public func makeIterator() -> MCGenerator<Value> {
        os_unfair_lock_lock(&_lock)
        self._storage.setCurrentNode()
        let generator = MCGenerator(memoryCache: self)
        os_unfair_lock_unlock(&_lock)
        return generator
    }
}



/// 用来支持 for-in 循环
public class MCGenerator<Value: Codable>: IteratorProtocol {
    public typealias Element = (key: String, value: Value)
    private var memoryCache: MemoryCache<Value>
    
    init(memoryCache: MemoryCache<Value>) {
        self.memoryCache = memoryCache
    }
    
    public func next() -> Element? {
        guard let node = memoryCache._storage.next() else {
            return nil
        }
        memoryCache._storage.move(toHead: node)
        return (node.key, node.object)
    }
}
