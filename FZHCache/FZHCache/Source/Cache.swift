//
//  Cache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/11.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

class CacheGenerator<Value: Codable>: IteratorProtocol {
    typealias Element = (String, Value)
    private let memoryCache: MemoryCache<Value>
    private let diskCache: DiskCache<Value>
    private let memoryCacheGenerator: MCGenerator<Value>
    private let diskCacheGenerator: DCGenerator<Value>
    
    public func next() -> Element? {
        if diskCacheGenerator.index == 0 { diskCache.getAllKeys() }
        guard diskCacheGenerator.index < diskCache.keys.endIndex  else {
            diskCacheGenerator.index = diskCache.keys.startIndex
            return nil
        }
        
        let key = diskCache.keys[diskCacheGenerator.index]
        diskCache.keys.formIndex(after: &diskCacheGenerator.index)
        if let element = memoryCache.object(forKey: key) {
            return (key, element)
        } else if let element = diskCache.object(forKey: key) {
            memoryCache.set(element, forKey: key)
            return (key, element)
        }
        return nil
    }
    
    fileprivate init(memoryCache: MemoryCache<Value>,
                     diskCache: DiskCache<Value>,
                     mcGenerator: MCGenerator<Value>,
                     dcGenerator: DCGenerator<Value>){
        self.memoryCache = memoryCache
        self.diskCache = diskCache
        self.memoryCacheGenerator = mcGenerator
        self.diskCacheGenerator = dcGenerator
    }
}

class Cache<Value: Codable> {
    public let memoryCache = MemoryCache<Value>()
    public let diskCache: DiskCache<Value>
    private var diskCachePath: String
    
    private let queue = DispatchQueue(label: kCacheIdentifier, attributes: DispatchQueue.Attributes.concurrent)
    
    public init(cacheName: String = "default") {
        diskCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        diskCachePath = diskCachePath + ("/\(cacheName)")
        diskCache = DiskCache(path: diskCachePath)
    }
}

extension Cache: Sequence {
    public subscript(key: String) -> Value? {
        set {
            if let newValue = newValue {
                set(newValue, forKey: key)
            }
        } get {
            if let object = object(forKey: key) { return object }
            return nil
        }
    }
    
    public func makeIterator() -> CacheGenerator<Value> {
        let generator = CacheGenerator(memoryCache: memoryCache, diskCache: diskCache, mcGenerator: memoryCache.makeIterator(), dcGenerator: diskCache.makeIterator())
        return generator
    }
}

extension Cache: CacheBehavior {
    
    func contains(_ key: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        queue.async { [weak self] in
            let contains = (self?.memoryCache.contains(key) ?? false) || (self?.diskCache.contains(key) ?? false)
            completionHandler(key, contains)
        }
    }
    
    func contains(_ key: String) -> Bool {
        return memoryCache.contains(key) || diskCache.contains(key)
    }
    
    @discardableResult
    func set(_ value: Value?, forKey key: String, cost: vm_size_t = 0) -> Bool {
        let memoryCacheFin = memoryCache.set(value, forKey: key)
        let diskCacheFin = diskCache.set(value, forKey: key)
        if memoryCacheFin || diskCacheFin {
            return true
        }
        return false
    }
    
    func set(_ value: Value?, forKey key: String, cost: vm_size_t, completionHandler: @escaping ((String, Bool) -> Void)) {
        queue.async { [weak self] in
            let memoryCacheFin = self?.memoryCache.set(value, forKey: key) ?? false
            let diskCacheFin = self?.diskCache.set(value, forKey: key) ?? false
            if memoryCacheFin || diskCacheFin {
                completionHandler(key, true)
            } else {
                completionHandler(key, false)
            }
        }
    }
    
    func object(forKey key: String) -> Value? {
        if let object = memoryCache.object(forKey: key) { return object }
         if let object = diskCache.object(forKey: key) {
            memoryCache.set(object, forKey: key)
            return object
        }
        return nil
    }
    
    func object(forKey key: String, completionHandler: @escaping ((String, Value?) -> Void)) {
        queue.async { [weak self] in
            if let object = self?.memoryCache.object(forKey: key){
                completionHandler(key,object)
            } else if let object = self?.diskCache.object(forKey: key) {
                self?.memoryCache.set(object, forKey: key)
                completionHandler(key,object)
            } else {
                completionHandler(key,nil)
            }
        }
    }
    
    func removeAll() {
        memoryCache.removeAll()
        diskCache.removeAll()
    }
    
    func removeAll(completionHandler: @escaping (() -> Void)) {
        queue.async { [weak self] in
            self?.memoryCache.removeAll()
            self?.diskCache.removeAll()
            completionHandler()
        }
    }
    
    func remove(forKey key: String) {
        memoryCache.remove(forKey: key)
        diskCache.remove(forKey: key)
    }
    
    func remove(forKey key: String, completionHandler: @escaping (() -> Void)) {
        queue.async {
            self.memoryCache.remove(forKey: key)
            self.diskCache.remove(forKey: key)
            completionHandler()
        }
    }
}
