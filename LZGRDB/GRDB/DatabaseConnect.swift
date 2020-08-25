//
//  DatabaseConnect.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/12.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import GRDB

typealias DatabaseResultBlock = () -> DataBaseResultSet

class DatabaseConnect: NSObject {
    let dbPath: String
    let readQueue: DispatchQueue
    let writeQueue: DispatchQueue
    
    init(dbPath: String, connectType: DatabaseConnectType) {
        self.dbPath = dbPath
        
        let readLabel = "com.lzgrdb.readQueue".queueLabelWithType(connectType)
        let writeLabel = "com.lzgrdb.writeQueue".queueLabelWithType(connectType)
        var qos: DispatchQoS = .default
        
        if connectType == .low {
            qos = .utility
        } else if connectType == .high {
            qos = .userInteractive
        } else  {
            qos = .default
        }
        
        readQueue = DispatchQueue.init(label: readLabel, qos: qos, attributes: .concurrent)
        writeQueue = DispatchQueue.init(label: writeLabel, qos: qos, attributes: .concurrent)
        
        super.init()
    }
    
    lazy var readDbQueue: DatabaseQueue = {
        let db = try! DatabaseQueue(path: dbPath, configuration: DatabaseConnect.defaultConfiguration)
        db.releaseMemory()
        return db
    }()

    lazy var writeDbQueue: DatabaseQueue = {
        let db = try! DatabaseQueue(path: dbPath, configuration:  DatabaseConnect.defaultConfiguration)
        db.releaseMemory()
        return db
    }()
    
    func readWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: DatabaseCompleteBlock) {
        var result = DataBaseResultSet()
        readQueue.sync {
             result = self.readBlockWithDataMessage(dataMessage)()
        }
        
        completionBlock(result)
    }
    
    func writeWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: DatabaseCompleteBlock) {
        
        var result = DataBaseResultSet()
        writeQueue.sync {
            result = self.writeBlockWithDataMessage(dataMessage)()
        }
        
        completionBlock(result)
    }
    
    func asyncReadWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: @escaping DatabaseCompleteBlock) {
        readQueue.async {
            let result = self.readBlockWithDataMessage(dataMessage)()
            completionBlock(result)
        }
    }
    
    func asyncWriteWithDataMessage(_ dataMessage: DataMessage, _ completionBlock: @escaping DatabaseCompleteBlock) {
        writeQueue.async {
            let result = self.writeBlockWithDataMessage(dataMessage)()
            completionBlock(result)
        }
    }
    
    private func readBlockWithDataMessage(_ dataMessage: DataMessage) -> DatabaseResultBlock {
        let block = { () -> DataBaseResultSet in
            
            let result = DataBaseResultSet()
            if dataMessage.operationType == .query {
                do {
                    try self.readDbQueue.read({ db in
                        
                        if let sql = dataMessage.sqlBuffer?.sql {
                            var resultArray = [Any]()
                            
                            let res = try Row.fetchCursor(db, sql: sql)
                            while let r = try res.next() {
                                var resultDictionary = [String: Any]()
                                for (columnName, dbValue) in r {
                                    resultDictionary[columnName] = dbValue.storage.value
                                }
                                resultArray.append(resultDictionary)
                            }
                            
                            result.resultArray = resultArray
                            result.resultCode = .success
                        }
                    })
                } catch {
                    result.resultCode = .failed
                }
            } else if dataMessage.operationType == .batchQuery {
                if let sqls = dataMessage.mutableSqlBuffer?.batchSqls {
                    var resultArray: [[Any]] = [[Any]]()
                    var success = true
                    do {
                        for sql in sqls {
                            var temp: [Any] = [Any]()
                            try self.readDbQueue.read({ db in
                                let res = try Row.fetchCursor(db, sql: sql)
                                while let r = try res.next() {
                                    var resultDictionary = [String: Any]()
                                    for (columnName, dbValue) in r {
                                        resultDictionary[columnName] = dbValue.storage.value
                                    }
                                    
                                    temp.append(resultDictionary)
                                }
                            })
                            
                            resultArray.append(temp)
                        }
                    } catch {
                        success = false
                    }
                    
                    if success {
                        result.resultArray = resultArray
                        result.resultCode = .success
                    } else {
                        result.resultCode = .failed
                    }
                }
            }
            return result
        }
        
        return block
    }
    
    private func writeBlockWithDataMessage(_ dataMessage: DataMessage) -> DatabaseResultBlock {
        let block = { () -> DataBaseResultSet in
            let result = DataBaseResultSet()
            
            if let sqlBuffers = dataMessage.batchSqlBuffers() {
                var success = true
                var lastErrorCode = ResultCode.SQLITE_OK
                for sqlBuffer in sqlBuffers {
                    if sqlBuffer.sql.count <= 0 {
                        continue
                    }
                    
                    if sqlBuffer.useArguments {
                        do {
                            try self.writeDbQueue.inTransaction { (db) -> Database.TransactionCompletion in
                                do {
                                    let statements = StatementArguments(sqlBuffer.parameterDictionary)
                                    try db.execute(sql: sqlBuffer.sql2, arguments: statements)
                                    success = true
                                    lastErrorCode = db.lastErrorCode
                                    return Database.TransactionCompletion.commit
                                } catch {
                                    success = false
                                    return Database.TransactionCompletion.rollback
                                }
                            }
                        } catch {
                            success = false
                        }
                    } else {
                        do {
                            try self.writeDbQueue.inTransaction { (db) -> Database.TransactionCompletion in
                                do {
                                    try db.execute(sql: sqlBuffer.sql)
                                    success = true
                                    return Database.TransactionCompletion.commit
                                } catch {
                                    success = false
                                    debugPrint("writeDbQueue execute>>>>> err:\(error)")
                                    return Database.TransactionCompletion.rollback
                                }
                            }
                        } catch {
                            debugPrint("writeDbQueue inTransaction>>>>> err:\(error)")
                            success = false
                        }
                    }
                    
                    if !success {
                        if lastErrorCode == .SQLITE_CONSTRAINT {
                            success = true
                            continue
                        }
                        success = false
                        break
                    }
                }
                
                if success {
                    result.resultCode = .success
                } else {
                    result.resultCode = .failed
                }
            }
            
            return result
        }
        
        return block
    }
    
    private static var defaultConfiguration: Configuration = {
        var config = Configuration()
        // 超时时间
        config.busyMode = Database.BusyMode.timeout(5.0)
        // 试图访问锁着的数据
        //configuration.busyMode = Database.BusyMode.immediateError
        config.qos = .default
        return config
    }()
}

extension String {
    func queueLabelWithType(_ type: DatabaseConnectType) -> String {
        switch type {
        case .low:
            return self + ".low"
        case .high:
            return self + ".high"
        default:
            return self + ".normal"
        }
    }
}
