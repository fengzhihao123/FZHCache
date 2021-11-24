//
//  FZHCacheTests.swift
//  FZHCacheTests
//
//  Created by Phil.Feng on 2020/9/18.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import XCTest
@testable import FZHCache

class FZHMemoryCacheTests: XCTestCase {

    var mCache: MemoryCache<Int>!
    
    override func setUp() {
        mCache = MemoryCache<Int>()
        mCache.totalCountLimit = 3
        
        mCache.set(10, forKey: "key1")
        mCache.set(20, forKey: "key2")
        mCache.set(30, forKey: "key3")
    }

    override func tearDown() {
        mCache = nil
    }

    func testMemoryCacheAdd() {
        XCTAssert(mCache.object(forKey: "key1") == 10)
        XCTAssert(mCache.object(forKey: "key2") == 20)
        XCTAssert(mCache.object(forKey: "key3") == 30)
    }
    
    func testMemoryCacheIterator() {
        
    }
    
    func testMemoryCacheRemove() {
        mCache.remove(forKey: "key1")
        XCTAssert(mCache.object(forKey: "key1") == nil)
    }
    
    func testMemoryCacheOutOfCount() {
        mCache.set(40, forKey: "key4")
        mCache.set(50, forKey: "key5")
        
        XCTAssert(mCache.object(forKey: "key2") == nil)
        XCTAssert(mCache.object(forKey: "key3") == 30)
        XCTAssert(mCache.object(forKey: "key4") == 40)
        XCTAssert(mCache.object(forKey: "key5") == 50)
    }
    
    func testMemoryCacheRemoveAll() {
        mCache.removeAll()
        
        XCTAssert(mCache.object(forKey: "key3") == nil)
        XCTAssert(mCache.object(forKey: "key4") == nil)
        XCTAssert(mCache.object(forKey: "key5") == nil)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
