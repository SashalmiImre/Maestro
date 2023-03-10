//
//  ProcessInfo.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 08..
//

import Foundation

extension ProcessInfo {
    static var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
}
