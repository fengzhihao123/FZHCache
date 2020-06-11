//
//  DiskCache.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/11.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
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
    
    fileprivate init(diskCache: DiskCache<Value>) {
        self.diskCache = diskCache
        self.index = diskCache.keys.startIndex
    }
}

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

private let kCacheIdentifier = "com.swiftcache.disk"

class DiskCache<Value: Codable> {
    public var maxSize: vm_size_t = 0
    public var maxCountLimit: vm_size_t = 0
    public var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7
    fileprivate let storage: DiskStorage<Value>
    private let semaphoreSignal = DispatchSemaphore(value: 1)
    private let convertible = ConvertibleFactory<Value>()
    private let dataMaxSize = 20 * 1024
    public var autoInterval: TimeInterval = 120
    var keys = [String]()
    private let queue = DispatchQueue(label: kCacheIdentifier, attributes: DispatchQueue.Attributes.concurrent)
    
    init(path: String) {
        storage = DiskStorage(currentPath: path)
        recursively()
    }
    
    private func recursively() {
        DispatchQueue.global().asyncAfter(deadline: .now() + autoInterval) {[weak self] in
            guard let strongSelf = self else { return }
            strongSelf.discardedData()
            strongSelf.recursively()
        }
    }
    
    private func discardedData() {
        queue.async {
            self.semaphoreSignal.wait()
            self.discardedToCost()
            self.discardedToCount()
            self.removeExpired()
            self.semaphoreSignal.signal()
        }
    }
    
    private func discardedToCount(){
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
                        totalCount -= 1 } else { break }
                } else {
                    break
                }
            }
            
        } while totalCount > maxCountLimit
        if fin { storage.dbCheckpoint() }
    }
    
    private func discardedToCost() {
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
    
    @discardableResult
    private func removeExpired() -> Bool {
        var currentTime = Date().timeIntervalSince1970
        currentTime -= maxCachePeriodInSecond
        let fin = storage.dbRemoveAllExpiredData(time: currentTime)
        return fin
    }
    
    @discardableResult
    public func removeAllExpired() -> Bool {
        semaphoreSignal.wait()
        let fin = removeExpired()
        semaphoreSignal.signal()
        return fin
    }
}

extension DiskCache: Sequence {
    
    public subscript(key:String) ->Value? {
        set {
            if let newValue = newValue {
                set(newValue, forKey: key)
            }
        } get {
            if let obj = object(forKey: key) {
                return obj
            }
            return nil
        }
    }
    
    public func makeIterator() -> DCGenerator<Value> {
        semaphoreSignal.wait()
        let generator = DCGenerator(diskCache: self)
       semaphoreSignal.signal()
        return generator
    }
}

extension DiskCache {
    func getAllKeys(){
         semaphoreSignal.wait()
         keys = storage.dbGetAllkeys()!
         semaphoreSignal.signal()
     }
     
     public func getTotalItemCount() -> Int {
         semaphoreSignal.wait()
         let count = storage.dbTotalItemCount()
         semaphoreSignal.signal()
         return Int(count)
     }
     
     public func getTotalItemCount(completionHandler:@escaping((_ count:Int)->Void)){
         queue.async {
             let count = self.getTotalItemCount()
             completionHandler(count)
         }
     }
     
     public func getTotalItemSize()->Int32{
         self.semaphoreSignal.wait()
         let size = storage.dbTotalItemSize()
         self.semaphoreSignal.signal()
         return size
     }
     
     public func getTotalItemSize(completionHandler:@escaping((_ size:Int32)->Void)){
         queue.async {
             let size = self.getTotalItemSize()
             completionHandler(size)
         }
     }
}

extension DiskCache: CacheBehavior {
    func contains(_ key: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        queue.async {
            let exists = self.contains(key)
            completionHandler(key, exists)
        }
    }
    
    func contains(_ key: String) -> Bool {
        semaphoreSignal.wait()
        let exists = self.storage.dbIsExistsForKey(forKey: key)
        semaphoreSignal.signal()
        return exists
    }
    
    @discardableResult
    func set(_ value: Value?, forKey key: String, cost: vm_size_t = 0) -> Bool {
        guard let object = value else { return false }
        guard let encodedData = try? convertible.toData(value: object) else{ return false }
        var filename:String? = nil
        if encodedData.count > dataMaxSize{
            filename = storage.generateMD5(forKey: key)
            
        }
        semaphoreSignal.wait()
        let fin = storage.save(forKey: key, value: encodedData,fileName: filename)
        semaphoreSignal.signal()
        return fin
    }
    
    func set(_ value: Value?, forKey key: String, cost: vm_size_t, completionHandler: @escaping((_ key: String, _ finished: Bool) -> Void)) {
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
   
    public func object(forKey key:String,completionHandler:@escaping((_ key:String,_ value:Value?) -> Void)){
        queue.async {
            if let object = self.object(forKey: key){ completionHandler(key,object) }
            else { completionHandler(key,nil) }
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
