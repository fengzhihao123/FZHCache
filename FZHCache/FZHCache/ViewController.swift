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
        mTest.test()
        cacheTest.test()
    }
}


