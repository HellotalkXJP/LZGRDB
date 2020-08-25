//
//  DataBaseResultSet.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/12.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

/// 数据库操作结果
enum DatabaseResult {
    case failed
    case success
    case constraint
}

class DataBaseResultSet: NSObject {
    var resultArray: [Any]?
    var resultCode: DatabaseResult = .failed
}
