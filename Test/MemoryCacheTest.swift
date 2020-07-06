//
//  MemoryCacheTest.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/12.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

struct MemoryCacheTest {
    let mCache = MemoryCache<Int>()
    func test() {
        mCache.totalCountLimit = 3
        testMemoryCacheAdd()
        testMemoryCacheIterator()
//        testMemoryCacheRemove()
//        testMemoryCacheOutOfCount()
//        testMemoryCacheRemoveAll()
        print("===== MemoryCache Test Finish ====")
    }
}

private extension MemoryCacheTest {
    func testMemoryCacheAdd() {
        mCache.set(10, forKey: "key1")
        mCache.set(20, forKey: "key2")
        mCache.set(30, forKey: "key3")
        
        assert(mCache.object(forKey: "key1") == 10)
        assert(mCache.object(forKey: "key2") == 20)
        assert(mCache.object(forKey: "key3") == 30)
    }
    
    func testMemoryCacheIterator() {
        for node in mCache {
            print(node.key, node.value)
        }
    }
    
    func testMemoryCacheRemove() {
        mCache.remove(forKey: "key1")
        assert(mCache.object(forKey: "key1") == nil)
    }
    
    func testMemoryCacheOutOfCount() {
        mCache.set(40, forKey: "key4")
        mCache.set(50, forKey: "key5")
        
        assert(mCache.object(forKey: "key2") == nil)
        assert(mCache.object(forKey: "key3") == 30)
        assert(mCache.object(forKey: "key4") == 40)
        assert(mCache.object(forKey: "key5") == 50)
    }
    
    func testMemoryCacheRemoveAll() {
        mCache.removeAll()
        
        assert(mCache.object(forKey: "key3") == nil)
        assert(mCache.object(forKey: "key4") == nil)
        assert(mCache.object(forKey: "key5") == nil)
    }
}
