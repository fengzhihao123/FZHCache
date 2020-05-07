//
//  FZHLinkedList.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/5/6.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
class FZHLinkedNode: Equatable {
    static func == (lhs: FZHLinkedNode, rhs: FZHLinkedNode) -> Bool {
        return lhs.key == rhs.key
    }
    
    var val: ObjectType
    var key: KeyType
    var time: TimeInterval = 0.0
    
    var cost = 0
    var prev: FZHLinkedNode?
    var next: FZHLinkedNode?
    
    init(val: ObjectType,
         key: KeyType,
         time: TimeInterval,
         cost: Int = 0,
         prev: FZHLinkedNode? = nil,
         next: FZHLinkedNode? = nil) {
        self.val = val
        self.key = key
        self.time = time
        self.cost = cost
        self.prev = prev
        self.next = next
    }
}

class FZHLinkedList: NSObject {
    var head: FZHLinkedNode? = FZHLinkedNode(val: ObjectType(), key: KeyType(), time: CACurrentMediaTime())
    var rear: FZHLinkedNode? = FZHLinkedNode(val: ObjectType(), key: KeyType(), time: CACurrentMediaTime())
    var content = [KeyType: ObjectType]()
    var totalCost = 0
    var count = 0
    
    func getNode(forKey key: KeyType) -> FZHLinkedNode? {
        return nil
    }
    
    func removeNode(node: FZHLinkedNode) {
        totalCost -= node.cost
        count -= 1
        if node.next != nil {
            node.next?.prev = node.prev
        }
        
        if node.prev != nil {
            node.prev?.next = node.next
        }
        
        if head == node { head = node.next }
        if rear == node { rear = node.prev }
    }
    
    func insertNode(atHead node: FZHLinkedNode) {
        totalCost += node.cost
        count += 1
        
        if head != nil {
            node.next = head
            head?.prev = node
            head = node
        } else {
            head = node
            rear = node
        }
    }
    
    func moveNode(toHead node: FZHLinkedNode) {
        if head == node { return }
        if rear == node {
            rear = node.prev
            rear?.next = nil
        } else {
            node.next?.prev = node.prev
            node.prev?.next = node.next
        }
        
        node.next = head
        node.prev = nil
        head?.prev = node
        head = node
    }
    
    @discardableResult
    func removeRear() -> FZHLinkedNode? {
        if rear == nil { return nil }
        let r = rear
        content.removeValue(forKey: rear!.key)
        totalCost -= rear!.cost
        count -= 1
        
        if head == rear {
            head = nil
            rear = nil
        } else {
            rear = rear?.prev
            rear?.next = nil
        }
        return r
    }
    
    func removeAll() {
        totalCost = 0
        count = 0
        head = nil
        rear = nil
        content.removeAll()
    }
}
