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

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let s = Student(name: "abc")
//
//
//        let decoder = JSONEncoder()
//        let data = try? decoder.encode(s)
//
//        let cachesPath: String? = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
//                                                                     .userDomainMask,
//                                                                     true).last
//        if let path = cachesPath {
//            let url = URL(string: path)!
//            let newPath = url.appendingPathComponent("student.archive")
//            try? data?.write(to: newPath)
//            print(newPath.absoluteString)
//
//            if let d = try? Data(contentsOf: newPath) {
//                let s1 = try? JSONDecoder().decode(Student.self, from: d)
//                print(s1!.name)
//            }
//        }
//
        
        
        let cache = FZHCache(totalCostLimit: 10, countLimit: 3)
        cache.setObject(10, forKey: "key1")
        cache.setObject(20, forKey: "key2")
        cache.setObject(30, forKey: "key3")
        cache.setObject(40, forKey: "key4")
        
        cache.removeAllObjects()
        
        print(cache.object(forKey: "key1"))
        print(cache.object(forKey: "key2"))
        print(cache.object(forKey: "key3"))
        print(cache.object(forKey: "key4"))
        
        
        print(cache.object(forKey: "key1"))
        print(cache.object(forKey: "key2"))
        print(cache.object(forKey: "key3"))
        print(cache.object(forKey: "key4"))
        
        
    }


}

