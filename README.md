# FZHCache
a easy way to cache

### Performance

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
