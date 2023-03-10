//
//  StringFormatStyle+StringParseStrategy.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 24..
//

import Foundation

struct StringFormatStyle: ParseableFormatStyle {
    public var parseStrategy: StringParseStrategy {
        return .init()
    }
 
    public func format(_ value: String) -> String {
        return value
    }
}

extension StringFormatStyle {
    struct StringParseStrategy: ParseStrategy {
        public func parse(_ value: String) throws -> String {
            return value
        }
    }
}
