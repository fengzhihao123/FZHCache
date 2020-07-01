# FZHCache
a easy way to cache


## 基本使用
### MemoryCache - 基本类型
```
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
```
### MemoryCache - 自定义类型
```
        // 自定义对象
        let memoryStu = MemoryCache<Student>()
        memoryStu.totalCountLimit = 3
        memoryStu.set(Student(age: 10, name: "name1"), forKey: "stu1")
        memoryStu.set(Student(age: 20, name: "name2"), forKey: "stu2")
        memoryStu.set(Student(age: 30, name: "name3"), forKey: "stu3")
        
        print(memoryStu.object(forKey: "stu1")?.age ?? -1) // 10
        memoryStu.set(Student(age: 40, name: "name4"), forKey: "stu4")
        print(memoryStu.object(forKey: "stu2")?.age ?? -1) // -1
```

### MemoryCache - for-in 访问
```
for stu in memoryStu {
    print(stu.value.name)
}
```

### MemoryCache - 通过下标set、get
```
        // 支持下标访问
        memoryStu["stu1"] = Student(age: 50, name: "name5")
        print(memoryStu["stu1"]?.age ?? 0) // 50
```

### 性能比较

#### Set 
![set](https://github.com/fengzhihao123/FZHCache/blob/master/images/set.png)

#### Get
![get](https://github.com/fengzhihao123/FZHCache/blob/master/images/get.png)

#### Get - No Exist
![get - noexist](https://github.com/fengzhihao123/FZHCache/blob/master/images/get-noexist.png)



## 问题记录
* 磁盘缓存方式
* 如何支持泛型
* 双向链表的释放问题
* 为什么要使用双向链表？`答：因为我们需要删除操作。删除一个节点不光要得到该节点本身的指针，也需要操作其前驱节点的指针，而双向链表才能支持直接查找前驱，保证操作的时间复杂度 O(1)`
* SHA256 VS MD5
* CommonCrypto 库的作用
