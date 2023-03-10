//
//  Report.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2021. 07. 11..
//

#if os(macOS)
import Foundation
import RegexBuilder

extension IDApplication.IDDocument {
    struct Report {
        var documentName: String
        var profileName: String
        var results: Array<PreflightResult> = .init()
                
        fileprivate init(documentName: String, profileName: String) {
            self.documentName = documentName
            self.profileName  = profileName
        }
        
        struct PreflightResult {
            enum Category: String {
                case links            = "LINKS"
                case colour           = "COLOUR"
                case imagesAndObjects = "IMAGES and OBJECTS"
                case text             = "TEXT"
                case unknown          = "UNKNOWN"
            }
            
            var parentNodeID: Int?
            var category: Category
            var pageNumber: String?
            var objectType: String?
            var errorInfo: String?
            var errorDetail: Array<PreflightDetail> = .init()
            
            init(category: String) {
                let regex = /^(LINKS|COLOUR|IMAGES and OBJECTS|TEXT)/
                let result = try? regex.prefixMatch(in: category)
                let category = String(result?.1 ?? Substring(stringLiteral: "UNKNOWN"))
                self.category = Category(rawValue: category)!
            }
        }
        
        struct PreflightDetail {
            var label: String
            var description: String
        }
        
        
       /*
        The aggregated results found by the process.
        Can return: Ordered array containing
               documentName: String,
               profileName: String,
               results: Array of Ordered array containing
                       parentNodeID: Long Integer,
                       errorName: String,
                       pageNumber: String,
                       errorInfo: String,
                       errorDetail: Array of Ordered array containing
                               label: String,
                               description: String.
        */
        static func build(from aggregatedResults: NSArray) throws -> Report {
            var report = Report(documentName: aggregatedResults[0] as! String,
                                 profileName: aggregatedResults[1] as! String)
            
            guard let results = aggregatedResults[2] as? NSArray
            else { throw ReportError.couldNotCastPreflightResultArray }
            
            try results.forEach { result in
                guard let resultBlock = result as? NSArray
                else { throw ReportError.couldNotCastResultBlock }
                guard let typeCode = resultBlock[0] as? Int
                else { throw ReportError.couldNotCastTypecode }
                
                switch typeCode {
                case 1:
                    guard let category = resultBlock[1] as? String
                    else { throw ReportError.couldNotCastCategory }
                    report.results.append(PreflightResult(category: category))
                    
                case 2:
                    guard var errorInfo = resultBlock[1] as? String
                    else { throw ReportError.couldNotCastErrorInfo}
                    errorInfo = errorInfo.replacing(/\ \([0-9]{1,3}\)/, with: { _ in "" })
                    report.results.lastElement.errorInfo = errorInfo
                    
                case 3:
                    guard let objectType = resultBlock[1] as? String,
                          let pageNumber = resultBlock[2] as? String,
                          let info       = resultBlock[3] as? String
                    else { throw ReportError.couldNotCastDetails }
                    report.results.lastElement.pageNumber = pageNumber
                    report.results.lastElement.objectType = objectType
                    info.split { $0 == "\n" }.forEach { substring in
                        let parts = substring.split { $0 == ":" }
                        report.results.lastElement.errorDetail.append(PreflightDetail(label: String(parts[0]),
                                                                                      description: String(parts[1])))
                    }
                default:
                    break
                }
            }
            return report
        }
    }
}


// MARK: - Preflight errors

extension IDApplication.IDDocument.Report {
    enum ReportError: Error {
        case couldNotCastPreflightResultArray
        case couldNotCastResultBlock
        case couldNotCastTypecode
        case couldNotCastCategory
        case couldNotCastErrorInfo
        case couldNotCastDetails
        case logicalErrorItemCouldNotBeNil
    }
}
#endif
