//
//  DiskStorage.swift
//  FZHCache
//
//  Created by Phil.Feng on 2020/6/8.
//  Copyright © 2020 Phil.Feng. All rights reserved.
//

import UIKit
import SQLite3
import CommonCrypto

class DiskStorageItem {
    var key: String?
    var data: Data?
    var fileName: String?
    var size: Int32 = 0
    var accessTime = 0
}

private extension Date {
    var timeStamp: Int { return Int(timeIntervalSince1970) }
}

private extension String {
    var md5: String {
        let utf8 = cString(using: .utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        #warning("方法过时，需替换")
        CC_MD5(utf8, CC_LONG(utf8!.count - 1), &digest)
        return digest.reduce("") { $0 + String(format:"%02x", $1) }
    }
    
}
class DiskStorage<Value: Codable> {
    private let dbFileName = "default.sqlite"
    private let dbWalFileName = "default.sqlite-wal"
    private let dbShmFileName = "default.sqlite-shm"
    private let folderName = "data"
    var filePath: String
    var dbPath: String
    var db: OpaquePointer?
    let dataMaxSize = 1024 * 20
    var dbStmtCache = [String:OpaquePointer]()
    let fileManager = FileManager.default
    
    init(path: String) {
        filePath = path
        dbPath = filePath
        filePath = filePath + "/\(folderName)"
    }
    
    convenience init(currentPath: String) {
        self.init(path: currentPath)
        guard generateDictionary() else { return }
        guard openDatabase() else { return }
        guard createTable() else { return }
    }
    
    deinit {
        closeDatabase()
    }
}



extension DiskStorage {
    func generateMD5(forKey key: String) -> String {
        return key.md5
    }
    
    /// 创建缓存文件目录
    func generateDictionary() -> Bool {
        do {
            try fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }
        return true
    }
    
    func append(fileName: String) -> String {
        return filePath + "/\(fileName)"
    }
    
    func exists() -> Bool {
        return fileManager.fileExists(atPath: filePath)
    }
    
    func generateFile(fileName: String?, data: Data) -> Bool {
        if let fn = fileName {
            let path = append(fileName: fn)
            let succ = (try? data.write(to: URL(fileURLWithPath: path))) != nil
            return succ
        }
        return false
    }
    
    /// 获取缓存数据
    /// - Parameter fileName: 缓存文件名
    func read(fileName: String) -> Data? {
        let path = append(fileName: fileName)
        guard let data = fileManager.contents(atPath: path) else { return nil }
        return data
    }
    
        @discardableResult
    /// 移除缓存
    /// - Parameter key: 需要被移除的缓存文件名
    func remove(key: String) -> Bool {
        if let fn = dbGetFileName(key: key) {
            removeFile(fileName: fn)
        }
        return dbRemoveItem(key: key)
    }
}



extension DiskStorage {
    
    /// 打开数据库
    func openDatabase() -> Bool {
        let fn = dbPath + "/\(dbFileName)"
        
        if sqlite3_open(fn, &db) == SQLITE_OK {
            return true
        } else {
            return false
        }
    }
    
    /// 关闭数据库
    @discardableResult
    func closeDatabase() -> Bool {
        var isContinue = true
        guard db == nil else {
            let res = sqlite3_close(db)
            if res == SQLITE_BUSY || res == SQLITE_LOCKED {
                var stmt: OpaquePointer?
                while isContinue {
                    stmt = sqlite3_next_stmt(db, nil)
                    if stmt != nil {
                        sqlite3_finalize(stmt)
                    } else {
                        isContinue = false
                    }
                }
            } else if res != SQLITE_OK {
                print("sqlite close failed \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
                return false
            }
            db = nil
            return true
        }
        return true
    }
    
    /// 创建表
    func createTable() -> Bool {
        let sql = "pragma journal_mode = wal; pragma synchronous = normal; create table if not exists detailed (key text primary key,filename text,inline_data blob,size integer,last_access_time integer); create index if not exists last_access_time_idx on detailed(last_access_time);"
        guard dbExcuSql(sql: sql) else { return false }
        return true
    }
    
    @discardableResult
    func dbExcuSql(sql: String) -> Bool {
        guard sqlite3_exec(db, sql.cString(using: .utf8), nil, nil, nil) == SQLITE_OK else {
            print("sqlite exec error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
            return false
        }
        return true
    }
    
    @discardableResult
    func save(forKey key: String, value: Data, fileName: String?) -> Bool {
        if fileName != nil {
            guard generateFile(fileName: fileName, data: value) else { return false }
            guard dbSave(forKey: key, value: value, fileName: fileName) else { return removeFile(fileName: fileName!) }
            return true
        }
        if let currentFileName = dbGetFileName(key: key) {
            removeFile(fileName: currentFileName)
        }
        guard dbSave(forKey: key, value: value, fileName: fileName) else {
            return false
        }
        return true
    }
    
    func dbSave(forKey key: String, value: Data, fileName: String?) -> Bool {
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let sql = "insert or replace into detailed" + "(key,filename,inline_data,size,last_access_time)" + "values(?1,?2,?3,?4,?5);"
        guard let stmt = dbPrepareStmt(sql: sql) else { return false }
        sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, transient)
        if let fn = fileName {
            sqlite3_bind_text(stmt, 2, fn, -1, transient)
            sqlite3_bind_blob(stmt, 3, nil, 0, transient)
        } else {
            sqlite3_bind_text(stmt, 2, nil, -1, transient)
            sqlite3_bind_blob(stmt, 3, [UInt8](value), Int32(value.count), transient)
        }
        sqlite3_bind_int(stmt, 4, Int32(value.count))
        sqlite3_bind_int(stmt, 5, Int32(Date().timeStamp))
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            print("sqlite insert error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
            return false
        }
        return true
    }
    
    func dbGetAllkeys() -> [String]? {
        let sql = "select key from detailed;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return nil }
        
        var keys = [String]()
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                let key = String(cString: sqlite3_column_text(stmt, 0))
                keys.append(key)
            } else if result == SQLITE_DONE {
                break
            } else {
                print("sqlite query keys error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
                break
            }
        }
        return keys
    }
    
    func dbGetFileName(key: String) -> String? {
        let sql = "select filename from detailed where key = ?1;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return nil }
        sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return nil
        }
        guard let fn = sqlite3_column_text(stmt, 0) else { return nil }
        return String(cString: fn)
    }
    
    func dbGetItemForKey(forKey key: String) -> DiskStorageItem? {
        guard let item = dbQuery(forKey: key) else { return nil }
        dbUpdateLastAccessTime(key: key)
        if let fn = item.fileName {
            item.data = read(fileName: fn)
        }
        return item
    }
    
    func dbUpdateLastAccessTime(key: String) {
        let sql = "update detailed set last_access_time=?1 where key=?2;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return }
        sqlite3_bind_int(stmt, 1, Int32(Date().timeStamp))
        sqlite3_bind_text(stmt, 2, key.cString(using: .utf8), -1, nil)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            print("sqlite update accessTime error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
            return
        }
    }
    
    func dbQuery(forKey key: String) -> DiskStorageItem? {
        let sql = "select key,filename,inline_data,size,last_access_time from detailed where key=?1;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return nil }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, transient)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return nil
        }
        let item = dbGetItemFromStmt(stmt: stmt)
        return item
    }
    
    /*
     Get
     */
    
    func dbIsExistsForKey(forKey key:String) -> Bool {
        let sql = "select count(key) from detailed where key = ?1;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return false }
        
        sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return false
        }
        return Int(sqlite3_column_int(stmt, 0)) > 0
    }
    
    func dbTotalItemSize() -> Int32 {
        let sql = "select sum(size) from detailed;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return -1 }
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return -1
        }
        return sqlite3_column_int(stmt, 0)
    }
    
    func dbTotalItemCount() -> Int32 {
        let sql = "select count(*) from detailed;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return -1 }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return -1 }
        return sqlite3_column_int(stmt, 0)
    }
    
    func dbGetItemFromStmt(stmt: OpaquePointer?) -> DiskStorageItem {
        let item = DiskStorageItem()
        let currentKey = String(cString: sqlite3_column_text(stmt, 0))
        if let name = sqlite3_column_text(stmt, 1) {
            let fn = String(cString: name)
            item.fileName = fn
        }
        let size = sqlite3_column_int(stmt, 3)
        if let blob = sqlite3_column_blob(stmt, 2) {
            item.data = Data(bytes: blob, count: Int(size))
        }
        let lastAccessTime = sqlite3_column_int(stmt, 4)
        item.key = currentKey
        item.size = size
        item.accessTime = Int(lastAccessTime)
        return item
    }
    
    func dbGetSizeExceededValueFromStmt(stmt: OpaquePointer?) -> DiskStorageItem {
        let item = DiskStorageItem()
        let currentKey = String(cString: sqlite3_column_text(stmt, 0))
        if let name = sqlite3_column_text(stmt, 1) {
            let fn = String(cString: name)
            item.fileName = fn
        }
        let size = sqlite3_column_int(stmt, 2)
        item.key = currentKey
        item.size = size
        return item
    }
    
    func dbPrepareStmt(sql: String) -> OpaquePointer? {
        guard !sql.isEmpty || !dbStmtCache.isEmpty else {
            return nil
        }
        
        var stmt = dbStmtCache[sql]
        guard stmt != nil else {
            if sqlite3_prepare_v2(db, sql.cString(using: .utf8), -1, &stmt, nil) != SQLITE_OK {
                print("sqlite stmt prepare error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
                return nil
            }
            dbStmtCache[sql] = stmt
            return stmt
        }
        sqlite3_reset(stmt)
        return stmt
    }
    
    func dbGetExpiredFiles(time: TimeInterval) -> [String]? {
        let sql = "select filename from detailed where last_access_time < ?1 and filename is not null;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return nil }
        
        var fileNames = [String]()
        sqlite3_bind_int(stmt, 1, Int32(time))
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                let fn = String(cString: sqlite3_column_text(stmt, 0))
                fileNames.append(fn)
            } else if result == SQLITE_DONE {
                break
            } else {
                print("sqlite query expired file error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
                break
            }
        }
        return fileNames
    }
    
    func dbCheckpoint() {
        sqlite3_wal_checkpoint(db, nil)
    }
    
    /*
     Remove
     */
    
    func removeAll() {
        if !dbRemoveAllItem() { return }
        if dbStmtCache.count > 0 { dbStmtCache.removeAll(keepingCapacity: true) }
        if !closeDatabase() { return }
        if ((try? fileManager.removeItem(atPath: self.filePath)) == nil) { return }
        if !generateDictionary() { return }
        if !openDatabase() { return }
        if !createTable() { return }
    }
    
    func dbRemoveAllExpiredData(time: TimeInterval) -> Bool {
        guard let fileNames = dbGetExpiredFiles(time: time) else {
            return false
        }
        
        fileNames.forEach { removeFile(fileName: $0) }
        if dbRemoveExpired(time: time) {
            dbCheckpoint()
            return true
        }
        return false
    }
    
    func dbRemoveExpired(time: TimeInterval) -> Bool {
        let sql = "delete from detailed where last_access_time < ?1;"
        guard let stmt = dbPrepareStmt(sql: sql) else { return false }
        sqlite3_bind_int(stmt, 1, Int32(time))
        
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            print("sqlite remove expired data error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
            return false
        }
        return true
    }
    
    func dbRemoveItem(key: String) -> Bool {
        let sql = "delete from detailed where key = ?1"
        guard let stmt = dbPrepareStmt(sql: sql) else { return false }
        
        sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            print("sqlite remove data error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
            return false
        }
        return true
    }
    
    @discardableResult
    func removeFile(fileName: String) -> Bool {
        return true
    }
    
    func dbRemoveAllItem() -> Bool {
        let sql = "delete from detailed"
        guard let stmt = dbPrepareStmt(sql: sql) else { return false }
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            print("sqlite remove data error \(String(describing: String(validatingUTF8: sqlite3_errmsg(db))))")
            return false
        }
        return true
    }
    
    func dbGetSizeExceededValues() -> [DiskStorageItem?] {
        let sql = "select key,filename,size from detailed order by last_access_time asc limit ?1;"
        let stmt = dbPrepareStmt(sql: sql)
        let count = 16
        var items = [DiskStorageItem]()
        sqlite3_bind_int(stmt, 1, Int32(count))
        while true {
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                let item = dbGetSizeExceededValueFromStmt(stmt: stmt)
                items.append(item)
            } else if result == SQLITE_OK {
                break
            } else {
                print("dbGetSizeExceededValues")
                break
            }
        }
       
        return items
    }
}
