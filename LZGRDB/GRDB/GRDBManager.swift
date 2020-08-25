//
//  GRDBManager.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/7.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import GRDB

/// 数据库连接
class GRDBManager: NSObject {
    // 数据库路径
    let dbPath: String
    
    var deletegate: DatabaseInterfaceDelegate?

    private static var defaultConfiguration: Configuration = {
        var config = Configuration()
        // 超时时间
        config.busyMode = Database.BusyMode.timeout(30.0)
        // 试图访问锁着的数据
        //configuration.busyMode = Database.BusyMode.immediateError
        config.qos = .default
        return config
    }()
    
    // MARK: 创建数据 多线程
    /// 数据库 用于多线程事务处理
    lazy var dbQueue: DatabaseQueue = {
        // 创建数据库
        let db = try! DatabaseQueue(path: dbPath, configuration: GRDBManager.defaultConfiguration)
        db.releaseMemory()
        return db
    }()
    
    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        
        migrator.registerMigration("v1") { db in
            self.createDefaultTable(db)
        }
        
        // 数据升级版本
        
        return migrator
    }
    
    init(dbName: String, path: String, deletegate: DatabaseInterfaceDelegate? = nil) {
        dbPath = (path.hasSuffix("/") ? path : path + "/") + dbName
        debugPrint("数据库地址：", dbPath)
        self.deletegate = deletegate
        
        super.init()
        
        if FileManager.default.fileExists(atPath: dbPath) {
            // 数据库存在,判断是否需要升级
            do {
                // 查询数据库版本
                try dbQueue.read({ [weak self] db in
                    guard let self = `self` else {
                        return
                    }
                    
                    let appliedIdentifiers = try self.migrator.appliedMigrations(db)
                    
                    print("数据库版本:\(appliedIdentifiers)")
                    
                })
            } catch let error {
                debugPrint(error)
            }
            
            /*
            do {
                // 执行
                try migrator.migrate(dbQueue, upTo: "v2")
            } catch {
                print("error migrator")
            }
            */
        } else {
            // 不存在,则创建数据库创建默认表
            do {
                // 执行
                try migrator.migrate(dbQueue, upTo: "v1")
            } catch {
                print("error migrator")
            }
        }
    }
    
    // 初始化数据库表
    func createDefaultTable(_ db: Database) {
        if let path = Bundle.main.path(forResource: "defaultSql", ofType: "sql"), let string = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) {
            let sqls = string.components(separatedBy: ";")
            
            for string in sqls {
                let sql = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if sql.count > 0 {
                    // 执行默认sql语句
                    do {
                        try db.execute(sql: sql)
                    } catch {
                        debugPrint("createDefaultTable>>> error:\(error)")
                    }
                }
            }
        } else {
            //
            debugPrint("GRDBManager ===> 找不到defaulSql")
        }
    }
    
    func executeDataMessage(_ message: inout DataMessage) {
        // 先判断同步还是异步操作，在判断是读写操作
        if message.sync {
            // 同步操作
            if message.operationType == .query || message.operationType == .batchQuery {
                databaseService.readWithDataMessage(message) { result in
                    message.resultSet = result
                    message.responded = true
                }
            } else {
                databaseService.writeWithDataMessage(message) { (result) in
                    message.resultSet = result
                    message.responded = true
                }
            }
        } else {
            // MARK: TODO 异步操作
            var localMessage = message

            defer {
                print("message >>>>> 1")
                message = localMessage
                print("message >>>>> 2")
            }
            
            if message.operationType == .query || message.operationType == .batchQuery {
                databaseService.asyncReadWithDataMessage(localMessage) { [weak self] result in
                    print("sync >>>>> no")
                    guard let self = `self` else {
                        return
                    }
                    
                    localMessage.resultSet = result
                    localMessage.responded = true
                    
                    if self.deletegate != nil {
                        self.deletegate?.executeFinishWithDataMessage(localMessage)
                    }
                }
            } else {
                databaseService.asyncWriteWithDataMessage(localMessage) { [weak self] result in
                    guard let self = `self` else {
                        return
                    }
                    
                    localMessage.resultSet = result
                    localMessage.responded = true
                    
                    if self.deletegate != nil {
                        self.deletegate?.executeFinishWithDataMessage(localMessage)
                    }
                }
            }
            
            print("message >>>>> responded:\(message.responded)")
        }
    }
    
    lazy var databaseService: DatabaseService = {
        let service = DatabaseService(dbPath: dbPath)
        return service
    }()
}
