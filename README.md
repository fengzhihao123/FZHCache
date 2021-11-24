# FZHCache
一个使用简单、线程安全的缓存库。


<b>iOS 版本支持</b>: `iOS 10+`   <b> 当前版本</b>: `0.0.6`

## Install

将 `pod 'FZHCache', '~> 0.0.6'` 添加到你的 Podfile 中:
```
target 'MyApp' do
  pod 'FZHCache', '~> 0.0.6'
end
```

然后在终端中运行 `pod install` 即可。

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
        
print(memoryInt.contains("num4")) // true
memoryInt.removeAll()
print(memoryInt.object(forKey: "num4") ?? -1) // -1
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

## 支持特性
* 支持LRU算法
* 支持存储遵守 Codable 的自定义类型
* 线程安全
* 支持 for-in 访问元素
* 支持下标语法 set/get 元素
* 支持内存和磁盘缓存
* 支持收到内存警告或 App 进入后台时，缓存可以配置为自动清空

## 性能比较

### Set 
![set](https://github.com/fengzhihao123/FZHCache/blob/master/images/set.png)

### Get
![get](https://github.com/fengzhihao123/FZHCache/blob/master/images/get.png)

### Get - No Exist
![get - noexist](https://github.com/fengzhihao123/FZHCache/blob/master/images/get-noexist.png)
