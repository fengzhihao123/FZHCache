//
//  ViewController.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
struct Student: Codable {
    var name: String
}

class ViewController: UIViewController {
    let cache = Cache<Int>(cacheName: "cache_test")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cache.memoryCache.totalCountLimit = 3
        testAdd()
        testRemove()
        testOutOfCount()
        testRemoveAll()
    }
}

private extension ViewController {
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
        cache.set(40, forKey: "key4")
        cache.set(50, forKey: "key5")
        
        assert(cache.object(forKey: "key2") == nil)
        assert(cache.object(forKey: "key3") == 30)
        assert(cache.object(forKey: "key4") == 40)
        assert(cache.object(forKey: "key5") == 50)
    }
    
    func testRemoveAll() {
        cache.removeAll()
        
        assert(cache.object(forKey: "key3") == nil)
        assert(cache.object(forKey: "key4") == nil)
        assert(cache.object(forKey: "key5") == nil)
    }
}

