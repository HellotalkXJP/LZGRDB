//
//  MutableSQLBuffer.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/12.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

class MutableSQLBuffer: NSObject {
    
    var sqlBuffers = [SQLBuffer]()
    
    var batchSqls: [String] {
        var sqls = [String]()
        if sqlBuffers.count > 0 {
            let sqlBuffers = self.sqlBuffers
            for sqlBuffer in sqlBuffers {
                sqls.append(sqlBuffer.sql)
            }
        }
        
        return sqls
    }
    
    var batchSqlBuffers: [SQLBuffer] {
        if sqlBuffers.count > 0 {
            let sqlBuffers = self.sqlBuffers
            return sqlBuffers
        }
        
        return [SQLBuffer]()
    }
    
    let lock = NSLock()
    
    override init() {
        super.init()
    }
    
    func addBuffer(_ sqlBuffer: SQLBuffer) {
        lock.lock()
        sqlBuffers.append(sqlBuffer)
        lock.unlock()
    }
    
    
}
