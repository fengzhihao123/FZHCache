//
//  CacheAware.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/8.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit

/// 内存缓存与磁盘缓存一致行为的接口
protocol CacheBehavior {
    associatedtype Value

    
    /// 将数据添加到缓存
    /// - Parameters:
    ///   - value: 需要缓存的数据
    ///   - key: 缓存数据的键
    ///   - cost: 缓存数据所占容量
    func set(_ value: Value?, forKey key: String, cost: Int) -> Bool
    
    /// 将数据添加到缓存并带有添加完成后的回调
    /// - Parameters:
    ///   - value: 需要缓存的数据
    ///   - key: 缓存数据的键
    ///   - cost: 缓存数据所占容量
    ///   - completionHandler: 数据添加完成的回调
    func set(_ value: Value?, forKey key: String, cost: Int, completionHandler: @escaping((_ key: String, _ finished: Bool) -> Void))
    
    
    /// 根据键获取数据
    /// - Parameter key: 查询数据的键
    func object(forKey key: String) -> Value?
    
    /// 根据键获取数据并带有回调
    /// - Parameters:
    ///   - key: 查询数据的键
    ///   - completionHandler: 查询完成后的回调
    func object(forKey key: String, completionHandler: @escaping((_ key: String, _ value: Value?) -> Void))
    
    
    /// 查看当前缓存是否包含键
    /// - Parameter key: 需要查询的键
    func contains(_ key: String) -> Bool
    /// 查看当前缓存是否包含键并带有回调
    /// - Parameters:
    ///   - key: 需要查询的键
    ///   - completionHandler: 查询完成的回调
    func contains(_ key: String, completionHandler: @escaping((_ key: String, _ contains: Bool) -> Void))
    
    
    /// 清除所有缓存数据
    func removeAll()
    /// 清除所有缓存数据并带有回调
    /// - Parameter completionHandler: 清除所有缓存后的回调
    func removeAll(completionHandler: @escaping(() -> Void))
    
    
    /// 根据键移除相应的缓存
    /// - Parameter key: 需要移除缓存数据的键
    func remove(forKey key: String)
    
    /// 根据键移除相应的缓存并带有回调
    /// - Parameters:
    ///   - key: 需要移除缓存数据的键
    ///   - completionHandler: 移除完成后的回调
    func remove(forKey key: String, completionHandler: @escaping(() -> Void))
}
