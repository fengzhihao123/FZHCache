//
//  Cache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/11.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

public class Cache<Value: Codable> {
    public let memoryCache = MemoryCache<Value>()
    public let diskCache: DiskCache<Value>
    
    private var _diskCachePath: String
    private let _queue = DispatchQueue(label: kCacheIdentifier, attributes: DispatchQueue.Attributes.concurrent)
    
    public init(cacheName: String = "default") {
        _diskCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
        _diskCachePath = _diskCachePath + ("/\(cacheName)")
        diskCache = DiskCache(path: _diskCachePath)
    }
}



extension Cache: CacheBehavior {
    public func contains(_ key: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        _queue.async { [weak self] in
            let contains = (self?.memoryCache.contains(key) ?? false) || (self?.diskCache.contains(key) ?? false)
            completionHandler(key, contains)
        }
    }
    
    public func contains(_ key: String) -> Bool {
        return memoryCache.contains(key) || diskCache.contains(key)
    }
    
    @discardableResult
    public func set(_ value: Value?, forKey key: String, cost: Int = 0) -> Bool {
        let memoryCacheFin = memoryCache.set(value, forKey: key)
        let diskCacheFin = diskCache.set(value, forKey: key)
        if memoryCacheFin || diskCacheFin {
            return true
        }
        return false
    }
    
    public func set(_ value: Value?, forKey key: String, cost: Int, completionHandler: @escaping ((String, Bool) -> Void)) {
        _queue.async { [weak self] in
            let memoryCacheFin = self?.memoryCache.set(value, forKey: key) ?? false
            let diskCacheFin = self?.diskCache.set(value, forKey: key) ?? false
            if memoryCacheFin || diskCacheFin {
                completionHandler(key, true)
            } else {
                completionHandler(key, false)
            }
        }
    }
    
    public func object(forKey key: String) -> Value? {
        if let object = memoryCache.object(forKey: key) { return object }
         if let object = diskCache.object(forKey: key) {
            memoryCache.set(object, forKey: key)
            return object
        }
        return nil
    }
    
    public func object(forKey key: String, completionHandler: @escaping ((String, Value?) -> Void)) {
        _queue.async { [weak self] in
            if let object = self?.memoryCache.object(forKey: key) {
                completionHandler(key,object)
            } else if let object = self?.diskCache.object(forKey: key) {
                self?.memoryCache.set(object, forKey: key)
                completionHandler(key, object)
            } else {
                completionHandler(key, nil)
            }
        }
    }
    
    public func removeAll() {
        memoryCache.removeAll()
        diskCache.removeAll()
    }
    
    public func removeAll(completionHandler: @escaping (() -> Void)) {
        _queue.async { [weak self] in
            self?.memoryCache.removeAll()
            self?.diskCache.removeAll()
            completionHandler()
        }
    }
    
    public func remove(forKey key: String) {
        memoryCache.remove(forKey: key)
        diskCache.remove(forKey: key)
    }
    
    public func remove(forKey key: String, completionHandler: @escaping (() -> Void)) {
        _queue.async {
            self.memoryCache.remove(forKey: key)
            self.diskCache.remove(forKey: key)
            completionHandler()
        }
    }
}



/// 用来使 Cache 支持下标语法及 for-in 循环
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



/// 用来使 Cache 支持 for - in
public class CacheGenerator<Value: Codable>: IteratorProtocol {
    public typealias Element = (String, Value)
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
