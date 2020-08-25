//
//  DataMessage.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/12.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

enum DatabaseConnectType {
    case normal     // 正常读取连接
    case low        // 低优先级的读写连接，队列的优先级都是low
    case high       // 高优先级的读写连接，队列的优先级都是high
}

enum DatabaseOperationType {
    case insert
    case delete
    case update
    case query
    case batchQuery   // 批量查询
}

enum DatabaseLogicType {
    case null
    case insertUser
    case updateUser
    case deleteUser
    case queryUser
}

class DataMessage: NSObject {
    // 是否已经返回数据库执行结果
    var responded = false
    
    // 是否是同步
    var sync = false
    
    // 数据库操作sql语句
    var sqlBuffer: SQLBuffer?
    
    // 数据库批量操作sql语句
    var mutableSqlBuffer: MutableSQLBuffer?
    
    // 业务逻辑类型
    var logicType: DatabaseLogicType = .null
    
    // 数据库操作类型
    var operationType: DatabaseOperationType = .query
    
    // 数据库连接类型
    var databaseConnectType: DatabaseConnectType = .normal
    
    // 数据库操作结果
    var resultSet: DataBaseResultSet?
    
    // 消息唯一标识
    var identifier: String = ""
    
    // 是否批量操作
    private var batch = false
    
    init(withSQLBuffer sqlBuffer: SQLBuffer) {
        self.sqlBuffer = sqlBuffer
        
        if sqlBuffer.sql.hasPrefix("INSERT") {
            operationType = .insert
        } else if sqlBuffer.sql.hasPrefix("DELETE") {
            operationType = .delete
        } else if sqlBuffer.sql.hasPrefix("UPDATE") || sqlBuffer.sql.hasPrefix("REPLACE") {
            operationType = .update
        } else if sqlBuffer.sql.hasPrefix("SELECT") {
            operationType = .query
        } else {
            operationType = .query
        }
        
        super.init()
    }
    
    init(withMutalbeSQLBuffer mutableSQLBuffer: MutableSQLBuffer) {
        self.mutableSqlBuffer = mutableSQLBuffer
        self.batch = true
        if let sqlBuffer = mutableSQLBuffer.batchSqlBuffers.last {
            if sqlBuffer.sql.hasPrefix("INSERT") {
                operationType = .insert
            } else if sqlBuffer.sql.hasPrefix("DELETE") {
                operationType = .delete
            } else if sqlBuffer.sql.hasPrefix("UPDATE") || sqlBuffer.sql.hasPrefix("REPLACE") {
                operationType = .update
            } else if sqlBuffer.sql.hasPrefix("SELECT") {
                operationType = .query
            } else {
                operationType = .query
            }
        }
        
        super.init()
    }
    
    func batchSqls() -> [String]? {
        if batch {
            return mutableSqlBuffer?.batchSqls
        } else {
            return [sqlBuffer?.sql ?? ""]
        }
    }
    
    func batchSqlBuffers() -> [SQLBuffer]? {
        if batch {
            return mutableSqlBuffer?.batchSqlBuffers
        } else {
            if let sqlBuffer = sqlBuffer {
                return [sqlBuffer]
            }
        }
        
        return nil
    }
}
