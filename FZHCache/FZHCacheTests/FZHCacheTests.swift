//
//  FZHCacheTests.swift
//  FZHCacheTests
//
//  Created by Phil.Feng on 2020/9/18.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import XCTest
@testable import FZHCache

class FZHCacheTests: XCTestCase {
    var cache: Cache<Int>!
    let count = 20_0000
    
    override func setUp() {
        cache = Cache<Int>(cacheName: "cache_test")
        cache.set(10, forKey: "key1")
        cache.set(20, forKey: "key2")
        cache.set(30, forKey: "key3")
    }
    
    override func tearDown() {
        cache = nil
    }
    
    func testAdd() {
        XCTAssert(cache.object(forKey: "key1") == 10)
        XCTAssert(cache.object(forKey: "key2") == 20)
        XCTAssert(cache.object(forKey: "key3") == 30)
    }
    
    func testRemove() {
        cache.remove(forKey: "key1")
        XCTAssert(cache.object(forKey: "key1") == nil)
    }
    
    func testOutOfCount() {
//        cache.set(40, forKey: "key4")
//        cache.set(50, forKey: "key5")
//
//        XCTAssert(cache.object(forKey: "key2") == nil)
//        XCTAssert(cache.object(forKey: "key3") == 30)
//        XCTAssert(cache.object(forKey: "key4") == 40)
//        XCTAssert(cache.object(forKey: "key5") == 50)
    }
    
    func testRemoveAll() {
        cache.removeAll()
        
        XCTAssert(cache.object(forKey: "key3") == nil)
        XCTAssert(cache.object(forKey: "key4") == nil)
        XCTAssert(cache.object(forKey: "key5") == nil)
    }
    
    func testPerformanceExample() {
        self.measure {
            for i in 0..<count {
                cache.set(i, forKey: "\(i)")
            }
        }
    }
    
}
