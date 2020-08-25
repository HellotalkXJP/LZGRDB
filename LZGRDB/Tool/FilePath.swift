//
//  FilePath.swift
//  GRDB_Database
//
//  Created by Mac on 2020/8/14.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

class FilePath: NSObject {
    
    static func documentPath() -> String {
        let documentPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documnetPath = documentPaths[0]
        
        return documnetPath
    }
    
    static func userPathWith(userId: String) -> String {
        let path = FilePath.documentPath() + "/" + userId
        
        if !FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        
        return path
    }
}
