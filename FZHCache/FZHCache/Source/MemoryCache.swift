//
//  MemoryCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/8.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

public class MCGenerator<Value: Codable>: IteratorProtocol{
    public typealias Element = (key: String, value: Value)
    
    private var memoryCache: MemoryCache<Value>
    
    fileprivate init(memoryCache: MemoryCache<Value>) {
        self.memoryCache = memoryCache
    }
    
    public func next() -> Element? {
        guard let node = memoryCache.storage.next() else {
            memoryCache.storage.setCurrentNode()
            return nil
        }
        memoryCache.storage.remove(node: node)
        return (node.key, node.object)
    }
    
}

class MemoryCache<Value: Codable> {
    var totalCostLimit: vm_size_t = 0
    var totalCountLimit: vm_size_t = 0
    
    var autoRemoveWhenMemoryWarning = true
    var autoRemoveWhenEnterBackground = true
    
    let storage = MemoryStorage<Value>()
    let semaphoreSingal = DispatchSemaphore(value: 1)
    private let queue = DispatchQueue(label: kMCIdentifier, attributes: DispatchQueue.Attributes.concurrent)
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func didReceiveMemoryWarningNotification(){
        if self.autoRemoveWhenMemoryWarning {
            removeAll()
        }
    }
       
    @objc func didEnterBackgroundNotification(){
        if self.autoRemoveWhenEnterBackground{
            removeAll()
        }
    }
    
}

private extension MemoryCache {
    func revokeCount() {
        if totalCountLimit != 0 {
            if storage.totalCountLimit > totalCountLimit {
                storage.removeTail()
            }
        }
    }
    
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
    func set(_ value: Value?, forKey key: String, cost: vm_size_t = 0) -> Bool {
        guard let obj = value else { return false }
        semaphoreSingal.wait()
        
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
        semaphoreSingal.signal()
        return true
    }
    
    func set(_ value: Value?, forKey key: String, cost: vm_size_t, completionHandler: @escaping ((String, Bool) -> Void)) {
        queue.async {
            let success = self.set(value, forKey: key, cost: cost)
            completionHandler(key, success)
        }
    }
    
    func object(forKey key: String) -> Value? {
        semaphoreSingal.wait()
        guard let node = storage.content[key] else {
            semaphoreSingal.signal()
            return nil
        }
        
        storage.move(toHead: node)
        semaphoreSingal.signal()
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
        semaphoreSingal.wait()
        let exists = storage.content.keys.contains(key)
        semaphoreSingal.signal()
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
        semaphoreSingal.wait()
        storage.removeAll()
        semaphoreSingal.signal()
    }
    
    func removeAll(completionHandler: @escaping (() -> Void)) {
        queue.async {
            self.removeAll()
            completionHandler()
        }
    }
    
    func remove(forKey key: String) {
        semaphoreSingal.wait()
        if let node = storage.content[key] {
            storage.remove(node: node)
        }
        semaphoreSingal.signal()
    }
    
    func remove(forKey key: String, completionHandler: @escaping (() -> Void)) {
        queue.async {
            self.remove(forKey: key)
            completionHandler()
        }
    }
}

extension MemoryCache: Sequence {
    /**
    通过下标方式set和get
    @param key: value关联的键
    @return Value:根据key查询对应的value，如果查询到则返回对应value，否则返回nil
    */
    public subscript(key:String) ->Value?{
        set {
            if let newValue = newValue {
                set(newValue, forKey: key)
            }
        } get {
            if let object = object(forKey: key) { return object }
            return nil
        }
    }
    
    /**
    返回该序列元素迭代器
    */
    public func makeIterator() -> MCGenerator<Value> {
        semaphoreSingal.wait()
        self.storage.setCurrentNode()
        let generator = MCGenerator(memoryCache: self)
        semaphoreSingal.signal()
        return generator
    }
}
