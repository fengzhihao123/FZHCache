//
//  MemoryStorage.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/8.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
/// 双链表的数据结构
class LinkedNode<Value: Codable> {
    var key: String
    var object: Value
    var cost: Int
    weak var prev: LinkedNode?
    weak var next: LinkedNode?
    
    init(key: String, object: Value, cost: Int) {
        self.key = key
        self.object = object
        self.cost = cost
    }
}



extension LinkedNode: Equatable {
    static func == (lhs: LinkedNode<Value>, rhs: LinkedNode<Value>) -> Bool {
        return lhs.key == rhs.key
    }
}



/// MemoryCache 的底层实现数据结构：通过双向链表 + Dictionary 的方式实现 LRU 算法
class MemoryStorage<Value: Codable> {
    var head: LinkedNode<Value>?
    var tail: LinkedNode<Value>?
    
    var totalCostLimit = 0
    var totalCountLimit = 0
    
    var content = [String: LinkedNode<Value>]()
    var currentNode: LinkedNode<Value>?
    
    /// 将 node 插入到链表头部
    /// - Parameter node: 需要插到链表头部的节点
    func insert(atHead node: LinkedNode<Value>) {
        totalCostLimit += node.cost
        totalCountLimit += 1
        
        if head == nil {
            head = node
            tail = head
        } else {
            node.next = head
            head?.prev = node
            head = node
        }
    }
    
    /// 将 node 移动到链表头部
    /// - Parameter node: 需要移动到链表头部的节点
    func move(toHead node: LinkedNode<Value>) {
        if head == node { return }
        if tail == node {
            node.prev?.next = nil
            tail = node.prev
            node.next = head
            head?.prev = node
            head = node
        } else {
            node.prev?.next = node.next
            node.next?.prev = node.prev
            node.next = head
            head?.prev = node
            head = node
        }
    }
    
    /// 移除链表尾部节点
    func removeTail() {
        guard tail != nil else { return }
        
        totalCostLimit -= tail!.cost
        totalCountLimit -= 1
        
        if head == tail {
            head = nil
            tail = nil
        } else {
            if let cur = tail?.key, let node = content.removeValue(forKey: cur) {
                tail?.prev?.next = nil
                tail = tail?.prev
                node.prev = nil
                node.next = nil
            }
        }
    }
    
    /// 从链表中移除 node
    /// - Parameter node: 需要被移除的节点
    func remove(node: LinkedNode<Value>) {
        guard head != nil else { return }
        
        if node.prev != nil && node.next != nil {
            node.prev?.next = node.next
            node.next?.prev = node.prev
            
            node.prev = nil
            node.next = nil
            
            content.removeValue(forKey: node.key)
            
            totalCostLimit -= node.cost
            totalCountLimit -= 1
        } else if node.prev == nil {
            head = node.next
            node.next = nil
            node.prev = nil
            head?.prev = nil
            content.removeValue(forKey: node.key)
            
            totalCostLimit -= node.cost
            totalCountLimit -= 1
        } else {
            removeTail()
        }
    }
    
    /// 移除链表中的所有节点
    func removeAll() {
        totalCountLimit = 0
        totalCostLimit = 0
        
        head = nil
        tail = nil
        currentNode = nil
        
        if content.count > 0 {
            content.removeAll()
        }
    }
    
    /// 获取当前头节点
    func setCurrentNode() {
        currentNode = head
    }
    
    /// 获取当前节点的下一个节点
    func next() -> LinkedNode<Value>? {
        let node = currentNode
        currentNode = currentNode?.next
        return node
    }
}
