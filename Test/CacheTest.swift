//
//  CacheTest.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/12.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

class CacheTest: NSObject {
    let cache = Cache<Int>(cacheName: "cache_test")
    func test() {
        testAdd()
        testRemove()
        testOutOfCount()
        testRemoveAll()
        
        print("===== Cache Test Finish ====")
    }
    
}

private extension CacheTest {
    
    func testAdd() {
        cache.set(10, forKey: "key1")
        cache.set(20, forKey: "key2")
        cache.set(30, forKey: "key3")
        
        assert(cache.object(forKey: "key1") == 10)
        assert(cache.object(forKey: "key2") == 20)
        assert(cache.object(forKey: "key3") == 30)
    }
    
    func testRemove() {
        cache.remove(forKey: "key1")
        assert(cache.object(forKey: "key1") == nil)
    }
    
    func testOutOfCount() {
//        cache.set(40, forKey: "key4")
//        cache.set(50, forKey: "key5")
//
//        assert(cache.object(forKey: "key2") == nil)
//        assert(cache.object(forKey: "key3") == 30)
//        assert(cache.object(forKey: "key4") == 40)
//        assert(cache.object(forKey: "key5") == 50)
    }
    
    func testRemoveAll() {
        cache.removeAll()
        
        assert(cache.object(forKey: "key3") == nil)
        assert(cache.object(forKey: "key4") == nil)
        assert(cache.object(forKey: "key5") == nil)
    }
}
