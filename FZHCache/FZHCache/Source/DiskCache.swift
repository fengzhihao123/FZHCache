//
//  DiskCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/11.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

class DiskCache<Value: Codable> {
    /// 磁盘缓存的最大容量
    public var maxSize = 0
    /// 磁盘缓存的最大数量
    public var maxCountLimit = 0
    /// 磁盘缓存的过期时间
    public var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7
    public var autoInterval: TimeInterval = 120
    
    var keys = [String]()
    
    fileprivate let storage: DiskStorage<Value>
    
    private let semaphoreSignal = DispatchSemaphore(value: 1)
    private let convertible = ConvertibleFactory<Value>()
    private let dataMaxSize = 20 * 1024
    private let queue = DispatchQueue(label: kDCIdentifier, attributes: DispatchQueue.Attributes.concurrent)
    
    init(path: String) {
        storage = DiskStorage(currentPath: path)
        recursively()
    }
    
    /// 递归删除超出限制或者过期的数据
    private func recursively() {
        DispatchQueue.global().asyncAfter(deadline: .now() + autoInterval) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.revokeData()
            strongSelf.recursively()
        }
    }
    
    /// 移除数据
    private func revokeData() {
        queue.async {
            self.semaphoreSignal.wait()
            self.revokeCost()
            self.revokeCount()
            self.removeExpired()
            self.semaphoreSignal.signal()
        }
    }
    
    /// 当超出数量限制时，移除数据
    private func revokeCount() {
        if maxCountLimit == 0 { return }
        var totalCount = storage.dbTotalItemCount()
        if totalCount <= maxCountLimit{ return }
        var fin = false
        
        repeat {
            let items = storage.dbGetSizeExceededValues()
            for item in items {
                if totalCount > maxCountLimit {
                    if let filename = item?.fileName {
                        if storage.removeFile(fileName: filename) {
                            if let key = item?.key { fin = storage.dbRemoveItem(key: key) }
                        }
                    } else if let key = item?.key {
                        fin = storage.dbRemoveItem(key: key)
                    }
                    if fin {
                        totalCount -= 1
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
            
        } while totalCount > maxCountLimit
        if fin { storage.dbCheckpoint() }
    }
    
    /// 当超出容量限制时，移除数据
    private func revokeCost() {
        if maxSize == 0 { return }
        var totalCost = storage.dbTotalItemSize()
        if totalCost < maxSize { return }
        var fin = false
        repeat {
            let items = storage.dbGetSizeExceededValues()
            for item in items {
                if totalCost > maxSize {
                    if let filename = item?.fileName {
                        if storage.removeFile(fileName: filename) {
                            if let key = item?.key{ fin = storage.dbRemoveItem(key: key) }
                        }
                    } else if let key = item?.key {
                        fin = storage.dbRemoveItem(key: key)
                    }
                    
                    if fin {
                        totalCost -= item!.size
                    } else {
                        break
                    }
                } else {
                    break
                }
            }
        } while totalCost > maxSize
        if fin{ storage.dbCheckpoint() }
    }
    
    /// 移除过期数据
    @discardableResult
    private func removeExpired() -> Bool {
        var currentTime = Date().timeIntervalSince1970
        currentTime -= maxCachePeriodInSecond
        let fin = storage.dbRemoveAllExpiredData(time: currentTime)
        return fin
    }
    
    /// 移除过期数据
    @discardableResult
    public func removeAllExpired() -> Bool {
        semaphoreSignal.wait()
        let fin = removeExpired()
        semaphoreSignal.signal()
        return fin
    }
}



extension DiskCache {
    /// 获取所有的键
    func getAllKeys() {
        semaphoreSignal.wait()
        if let keys = storage.dbGetAllkeys() {
            self.keys = keys
        }
        semaphoreSignal.signal()
    }
    
    /// 获取所有缓存数据的数量
    public func getTotalItemCount() -> Int {
        semaphoreSignal.wait()
        let count = storage.dbTotalItemCount()
        semaphoreSignal.signal()
        return Int(count)
    }
    
    /// 获取所有缓存数据的数量，并带有回调
    /// - Parameter completionHandler: 获取数量后的回调
    public func getTotalItemCount(completionHandler: @escaping((_ count: Int) -> Void)) {
        queue.async {
            let count = self.getTotalItemCount()
            completionHandler(count)
        }
    }
    
    /// 获取所有缓存数据的容量
    public func getTotalItemSize() -> Int32 {
        self.semaphoreSignal.wait()
        let size = storage.dbTotalItemSize()
        self.semaphoreSignal.signal()
        return size
    }
    
    /// 获取所有缓存数据的容量，并带有回调
    /// - Parameter completionHandler: 获取容量后的回调
    public func getTotalItemSize(completionHandler: @escaping((_ size: Int32) -> Void)) {
        queue.async {
            let size = self.getTotalItemSize()
            completionHandler(size)
        }
    }
}

extension DiskCache: CacheBehavior {
    func contains(_ key: String) -> Bool {
        semaphoreSignal.wait()
        let exists = self.storage.dbIsExistsForKey(forKey: key)
        semaphoreSignal.signal()
        return exists
    }
    
    public func contains(_ key: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        queue.async {
            let exists = self.contains(key)
            completionHandler(key, exists)
        }
    }
    
    @discardableResult
    func set(_ value: Value?, forKey key: String, cost: Int = 0) -> Bool {
        guard let object = value else { return false }
        guard let encodedData = try? convertible.toData(value: object) else { return false }
        var filename:String? = nil
        if encodedData.count > dataMaxSize {
            filename = storage.generateSHA256(forKey: key)
        }
        semaphoreSignal.wait()
        let fin = storage.save(forKey: key, value: encodedData,fileName: filename)
        semaphoreSignal.signal()
        return fin
    }
    
    func set(_ value: Value?, forKey key: String, cost: Int, completionHandler: @escaping((_ key: String, _ finished: Bool) -> Void)) {
        queue.async {
            let success =  self.set(value, forKey: key)
            completionHandler(key, success)
        }
    }
    
    public func object(forKey key: String) -> Value? {
        semaphoreSignal.wait()
        let item = storage.dbGetItemForKey(forKey: key)
        semaphoreSignal.signal()
        guard let value = item?.data else{ return nil }
        return try? convertible.fromData(data: value)
    }
    
    public func object(forKey key: String, completionHandler: @escaping((_ key: String, _ value: Value?) -> Void)){
        queue.async {
            if let object = self.object(forKey: key) {
                completionHandler(key,object)
            } else {
                completionHandler(key,nil)
            }
        }
    }
    
    public func removeAll() {
        semaphoreSignal.wait()
        storage.removeAll()
        semaphoreSignal.signal()
    }
    
    public func removeAll(completionHandler: @escaping (() -> Void)) {
        queue.async {
            self.removeAll()
            completionHandler()
        }
    }
    
    public func remove(forKey key: String) {
        semaphoreSignal.wait()
        storage.remove(key: key)
        semaphoreSignal.signal()
    }
    
    public func remove(forKey key: String, completionHandler: @escaping(() -> Void)) {
        queue.async {
            self.remove(forKey: key)
            completionHandler()
        }
    }
}



/// 用来编码解码
class ConvertibleFactory<Value: Codable> {
    func toData(value: Value) throws -> Data? {
        let data = try? JSONEncoder().encode(value)
        return data
    }
    
    func fromData(data: Data) throws -> Value? {
        let object = try? JSONDecoder().decode(Value.self, from: data)
        return object
    }
}



/// 用来使 DiskCache 支持下标语法及 for-in 循环
extension DiskCache: Sequence {
    subscript(key: String) -> Value? {
        set {
            if let newValue = newValue {
                set(newValue, forKey: key)
            }
        }
        get {
            if let obj = object(forKey: key) {
                return obj
            }
            return nil
        }
    }
    
    func makeIterator() -> DCGenerator<Value> {
        semaphoreSignal.wait()
        let generator = DCGenerator(diskCache: self)
        semaphoreSignal.signal()
        return generator
    }
}



/// 用来支持 for-in 循环
class DCGenerator<Value: Codable>: IteratorProtocol {
    typealias Element = (key: String, value: Value)
    private let diskCache: DiskCache<Value>
    
    var index: Int
    func next() -> Element? {
        if index == 0 {
            diskCache.getAllKeys()
        }
        
        guard index < diskCache.keys.endIndex else {
            index = diskCache.keys.startIndex
            return nil
        }
        
        let key = diskCache.keys[index]
        diskCache.keys.formIndex(after: &index)
        if let e = diskCache.object(forKey: key) {
            return (key, e)
        }
        return nil
    }
    
    init(diskCache: DiskCache<Value>) {
        self.diskCache = diskCache
        self.index = diskCache.keys.startIndex
    }
}
