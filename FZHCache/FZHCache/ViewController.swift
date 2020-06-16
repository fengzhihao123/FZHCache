//
//  ViewController.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let mTest = MemoryCacheTest()
    let cacheTest = CacheTest()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let perTest = PerformanceTest()
        perTest.testDictionaryTime()
        perTest.testNSCacheTime()
        perTest.testFZHMemoryCacheTime()
    }
}


/*
 Set - : Dictionary: 206.93399908486754, NSCache: 1600.2097990131006, FZHMemory: 550.689937081188
 Get - : Dictionary: 150.29098803643137, NSCache: 235.5958860134706, FZHMemory: 576.6196550102904
 Get - Not exist: Dictionary: 128.97773506119847, NSCache: 217.62683207634836, FZHMemory: 153.00241799559444
 
 
 Set - : Dictionary: 194.71085409168154, NSCache: 1706.4215389546007, FZHMemory: 543.2781979907304
 Get - : Dictionary: 140.306702000089, NSCache: 224.91873695980757, FZHMemory: 531.8616119911894
 Get - Not exist: Dictionary: 125.59954298194498, NSCache: 220.2507599722594, FZHMemory: 152.42595598101616
 */
