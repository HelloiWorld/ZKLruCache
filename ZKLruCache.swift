//  ZKLRUCache.swift
//  TestDemo
//
//  Created by pengzk on 2022/9/16.
//

import Foundation

/// 链表
final class DoubleLinkedList<T> {
    /// 链表节点
    final class Node<T> {
        var content: T
        var pre: Node<T>?
        var next: Node<T>?
        
        init(content: T) {
            self.content = content
        }
    }
    
    private(set) var count: Int = 0
    private var head: Node<T>?
    private var tail: Node<T>?
    
    func addHead(_ node: T) -> Node<T> {
        let node = Node(content: node)
        defer {
            head = node
            count += 1
        }
        
        guard let head = head else {
            tail = node
            return node
        }

        head.pre = node
        
        node.pre = nil
        node.next = head
        
        return node
    }
    
    func moveToHead(_ node: Node<T>) {
        guard node !== head else { return }
        let previous = node.pre
        let next = node.next
        
        previous?.next = next
        next?.pre = previous
        
        node.next = head
        node.pre = nil
        
        if node === tail {
            tail = previous
        }
        
        self.head = node
    }
    
    func delete(_ node: Node<T>) {
        node.pre?.next = node.next
        node.next?.pre = node.pre
        count -= 1
    }
    
    func removeLast() -> Node<T>? {
        guard let tail = self.tail else { return nil }
        
        let previous = tail.pre
        previous?.next = nil
        self.tail = previous
        
        if count == 1 {
            head = nil
        }
        count -= 1
        return tail
    }
}

final class ZKLRUCache<K:Hashable, V> {
    private struct CacheContent {
        var key: K?
        var value: V?
    }
    
    private let list = DoubleLinkedList<CacheContent>()
    private let capacity: Int
    typealias LinkedListNode<T> = DoubleLinkedList<T>.Node<T>
    private var cacheDict = [K: LinkedListNode<CacheContent>]()
    private var lock = NSLock()
    
    var count:Int {
        lock.lock()
        defer {
            lock.unlock()
        }
        return cacheDict.count
    }

    init(_ capacity: Int) {
        self.capacity = max(0, capacity)
    }
    
    subscript(key: K) -> V? {
        get {
            return get(key)
        }
        set {
            if let v = newValue {
                put(key, v)
            } else {
                remove(key)
            }
        }
    }
    
    private func get(_ key: K) -> V? {
        lock.lock()
        defer {
            lock.unlock()
        }
        guard let node = cacheDict[key] else {
            return nil
        }
        list.moveToHead(node)
        return node.content.value
    }
    
    private func put(_ key: K, _ value: V) {
        lock.lock()
        defer {
            lock.unlock()
        }
        let cacheContent = CacheContent(key: key, value: value)
        
        if let node = cacheDict[key] {
            node.content = cacheContent
            list.moveToHead(node)
        } else {
            let node = list.addHead(cacheContent)
            cacheDict[key] = node
        }
        
        if list.count > capacity {
            if let node = list.removeLast(), let key = node.content.key {
                cacheDict[key] = nil
            }
        }
    }
    
    func contains( _ key:K) -> Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        let r = cacheDict.contains { element in
            return element.key == key
        }
        return r
    }
    
    func remove(_ key:K) {
        lock.lock()
        defer {
            lock.unlock()
        }
        if let node = cacheDict[key] {
            list.delete(node)
            cacheDict[key] = nil
        }
    }
    
    func removeAll() {
        lock.lock()
        defer {
            lock.unlock()
        }
        cacheDict.removeAll()
        while list.removeLast() != nil {
            
        }
    }
    
    func enumerateAll(_ handler: (_ value: V) -> ()) {
        lock.lock()
        defer {
            lock.unlock()
        }
        var iter = cacheDict.makeIterator()
        while let next = iter.next(),
              let p = next.value.content.value {
            handler(p)
        }
    }
}
