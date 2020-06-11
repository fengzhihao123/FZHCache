//
//  MemoryStorage.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/8.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
class LinkedNode<Value: Codable> {
    var key: String
    var object: Value
    // why vm_size_t?
    var cost: vm_size_t
    weak var prev: LinkedNode?
    weak var next: LinkedNode?
    
    init(key: String, object: Value, cost: vm_size_t) {
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

class MemoryStorage<Value: Codable> {
    var head: LinkedNode<Value>?
    var tail: LinkedNode<Value>?
    
    var totalCostLimit: vm_size_t = 0
    var totalCountLimit: vm_size_t = 0
    
    var content = [String: LinkedNode<Value>]()
    typealias Element = (String, Value)
    var currentNode: LinkedNode<Value>?
    
    
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
    
    @discardableResult
    func removeTail() -> Bool {
        if tail == nil {
            head = tail
            totalCostLimit = 0
            totalCountLimit = 0
            return false
        } else {
            if let cur = tail?.key, let node = content.removeValue(forKey: cur) {
                tail?.prev?.next = nil
                tail = tail?.prev
                node.prev = nil
                node.next = nil
                totalCostLimit -= node.cost
                totalCountLimit -= 1
                return true
            }
        }
        return false
    }
    
    
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
            #warning("totalCostLimit/totalCountLimit 为什么没有做－操作")
            content.removeValue(forKey: node.key)
        } else {
            removeTail()
        }
    }
    
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
    
    func setCurrentNode() {
        currentNode = head
    }
    
    func next() -> LinkedNode<Value>? {
        let node = currentNode
        currentNode = currentNode?.next
        return node
    }
}
