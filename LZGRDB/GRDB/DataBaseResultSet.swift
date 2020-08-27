//
//  DataBaseResultSet.swift
//  DatabaseDemo
//
//  Created by Mac on 2020/8/12.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

/// 数据库操作结果
public enum DatabaseResult {
    case failed
    case success
    case constraint
}

public class DataBaseResultSet: NSObject {
    public var resultArray: [Any]?
    public var resultCode: DatabaseResult = .failed
}
