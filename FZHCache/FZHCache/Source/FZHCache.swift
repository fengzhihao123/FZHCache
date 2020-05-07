//
//  FZHCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

enum FZHCacheType {
    case all
    case memory
    case disk
}

typealias Key = String
typealias Object = Int

class FZHCache {
    private(set) var totalCostLimit = 0
    private(set) var countLimit = 0
    private let _memCache: FZHMemoryCache
    private let _diskCache: FZHDiskCache
    private var _cacheType: FZHCacheType
    
    init(totalCostLimit: Int, countLimit: Int, cacheType: FZHCacheType = .all, path: String = "") {
        self.totalCostLimit = totalCostLimit
        self.countLimit = countLimit
        _cacheType = cacheType
        
//        assert(cacheType == .disk && !path.isEmpty, "当选择磁盘缓存时，必须提供缓存路径")
        
        _memCache = FZHMemoryCache(totalCostLimit: totalCostLimit, countLimit: countLimit)
        _diskCache = FZHDiskCache(totalCostLimit: totalCostLimit, countLimit: countLimit, path: path)
    }
    
    func object(forKey key: Key) -> Object? {
        if let obj = _memCache.object(forKey: key) {
            return obj
        } else {
            if let obj = _diskCache.object(forKey: key) {
                _memCache.setObject(obj, forKey: key, cost: 0)
                return obj
            }
        }
        return nil
    }
    
    func setObject(_ obj: Object, forKey key: Key) {
        setObject(obj, forKey: key, cost: 0)
    }
    
    func setObject(_ obj: Object, forKey key: Key, cost g: Int) {
        switch _cacheType {
        case .all:
            _memCache.setObject(obj, forKey: key, cost: g)
            _diskCache.setObject(obj, forKey: key, cost: g)
        case .memory:
            _memCache.setObject(obj, forKey: key, cost: g)
        case .disk:
            _diskCache.setObject(obj, forKey: key, cost: g)
        }
    }
    
    func removeObject(forKey key: Key) {
        switch _cacheType {
        case .all:
            _memCache.removeObject(forKey: key)
            _diskCache.removeObject(forKey: key)
        case .memory:
            _memCache.removeObject(forKey: key)
        case .disk:
            _diskCache.removeObject(forKey: key)
        }
    }
    
    func removeAllObjects() {
        switch _cacheType {
        case .all:
            _memCache.removeAllObjects()
            _diskCache.removeAllObjects()
        case .memory:
            _memCache.removeAllObjects()
        case .disk:
            _diskCache.removeAllObjects()
        }
        
    }
}
