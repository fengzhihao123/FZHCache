//
//  PerformanceTest.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/16.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

class PerformanceTest: NSObject {
    var keys = [String]()
    var values = [Data]()
    let count = 20_0000
    var dict = [String: Data]()
    let cache = NSCache<NSString, NSData>()
    let mCache = MemoryCache<Data>()
    
    override init() {
        for i in 0..<count {
            keys.append("\(i)")
            
            var num = i
            values.append(Data(bytes: &num, count: 8))
        }
    }
    
    func testDictionaryTime() {
        let begin = CACurrentMediaTime()
        for i in 0..<count {
            dict[keys[i]] = values[i]
        }
        let end = CACurrentMediaTime()
        let time = end - begin
        
        let begin1 = CACurrentMediaTime()
        for i in 0..<count {
            cache.setObject(values[i] as NSData, forKey: keys[i] as NSString)
            
        }
        let end1 = CACurrentMediaTime()
        let time1 = end1 - begin1
        
        let begin2 = CACurrentMediaTime()
        for i in 0..<count {
            mCache[keys[i]] = values[i]
        }
        let end2 = CACurrentMediaTime()
        let time2 = end2 - begin2
        
        print("Set - : Dictionary: \(time * 1000), NSCache: \(time1 * 1000), FZHMemory: \(time2 * 1000)")
        
    }
    
    func testNSCacheTime() {
        let begin = CACurrentMediaTime()
        for i in 0..<count {
            let _ = dict[keys[i]]
        }
        let end = CACurrentMediaTime()
        let time = end - begin
        
        let begin1 = CACurrentMediaTime()
        for i in 0..<count {
            cache.object(forKey: keys[i] as NSString)
        }
        let end1 = CACurrentMediaTime()
        let time1 = end1 - begin1
        
        
        let begin2 = CACurrentMediaTime()
        for i in 0..<count {
            let _ = mCache[keys[i]]
        }
        let end2 = CACurrentMediaTime()
        let time2 = end2 - begin2
        
        print("Get - : Dictionary: \(time * 1000), NSCache: \(time1 * 1000), FZHMemory: \(time2 * 1000)")
    }
    
    func testFZHMemoryCacheTime() {
        let begin = CACurrentMediaTime()
        for i in 0..<count {
            let _ = dict["\(-i)"]
        }
        let end = CACurrentMediaTime()
        let time = end - begin
        
        let begin1 = CACurrentMediaTime()
        for i in 0..<count {
            let _ = cache.object(forKey: "\(-i)" as NSString)
        }
        let end1 = CACurrentMediaTime()
        let time1 = end1 - begin1
        
        let begin2 = CACurrentMediaTime()
        for i in 0..<count {
            let _ = mCache["\(-i)"]
        }
        let end2 = CACurrentMediaTime()
        let time2 = end2 - begin2
        
        print("Get - Not exist: Dictionary: \(time * 1000), NSCache: \(time1 * 1000), FZHMemory: \(time2 * 1000)")
    }
    
}
