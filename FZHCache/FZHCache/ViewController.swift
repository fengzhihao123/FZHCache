//
//  ViewController.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

struct Student: Codable {
    var age: Int
    var name: String
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        memoryExample()
        print("==================")
        cacheExample()
    }
    
}

private extension ViewController {
    func memoryExample() {
        // 基本类型
        let memoryInt = MemoryCache<Int>()
        memoryInt.totalCountLimit = 3
        memoryInt.totalCostLimit = 1024
        memoryInt.set(10, forKey: "num1")
        memoryInt.set(20, forKey: "num2")
        memoryInt.set(30, forKey: "num3")
        
        print(memoryInt.object(forKey: "num3") ?? -1) // 30
        memoryInt.set(40, forKey: "num4")
        print(memoryInt.object(forKey: "num1") ?? -1) // -1
        
        
        
        // 自定义对象
        let memoryStu = MemoryCache<Student>()
        memoryStu.totalCountLimit = 3
        memoryStu.set(Student(age: 10, name: "name1"), forKey: "stu1")
        memoryStu.set(Student(age: 20, name: "name2"), forKey: "stu2")
        memoryStu.set(Student(age: 30, name: "name3"), forKey: "stu3")
        
        print(memoryStu.object(forKey: "stu1")?.age ?? -1) // 10
        memoryStu.set(Student(age: 40, name: "name4"), forKey: "stu4")
        print(memoryStu.object(forKey: "stu2")?.age ?? -1) // -1
        
        
        
        // for - in
        for stu in memoryStu {
            print(stu.value.name)
        }
        
        
        
        // 支持下标访问
        memoryStu["stu1"] = Student(age: 50, name: "name5")
        print(memoryStu["stu1"]?.age ?? 0) // 50
    }
    
    func cacheExample() {
        // 基本类型
        let cacheInt = Cache<Int>()
        cacheInt.set(10, forKey: "num1")
        cacheInt.set(20, forKey: "num2")
        cacheInt.set(30, forKey: "num3")
        
        print(cacheInt.object(forKey: "num3") ?? -1) // 30
        cacheInt.set(40, forKey: "num4")
        print(cacheInt.object(forKey: "num1") ?? -1) // 10
        
        
        
        // 自定义对象
        let cacheStu = Cache<Student>()
        cacheStu.set(Student(age: 10, name: "name1"), forKey: "stu1")
        cacheStu.set(Student(age: 20, name: "name2"), forKey: "stu2")
        cacheStu.set(Student(age: 30, name: "name3"), forKey: "stu3")
        
        print(cacheStu.object(forKey: "stu1")?.age ?? -1) // 10
        cacheStu.set(Student(age: 40, name: "name4"), forKey: "stu4")
        print(cacheStu.object(forKey: "stu2")?.age ?? -1) // 20
        
        
        
        // for - in
        for stu in cacheStu {
            print(stu.1.name)
        }
        
        
        
        // 支持下标访问
        cacheStu["stu1"] = Student(age: 50, name: "name5")
        print(cacheStu["stu1"]?.age ?? 0) // 50
    }
}

