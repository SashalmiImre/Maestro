//
//  InDesignScriptingTests.swift
//  MaestroTests
//
//  Created by Sashalmi Imre on 2022. 12. 13..
//

import XCTest
@testable import Maestro

final class InDesignScriptingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_InDesignReport_EmptyFile() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "empty", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.documentName, "empty.indd")
        XCTAssertEqual(report!.profileName, "MaestroPreflightOptions")
        XCTAssertEqual(report!.results.count, 0)
    }
    
    func test_InDesignReport_RGBColor() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "rgbColor", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()

        XCTAssertNotNil(report)
        XCTAssertEqual(report!.documentName, "rgbColor.indd")
        XCTAssertEqual(report!.profileName, "MaestroPreflightOptions")
        XCTAssertEqual(report!.results.first!.category, .colour)
    }
    
    func test_InDesignReport_TextOverflow() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "textOverflow", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.documentName, "textOverflow.indd")
        XCTAssertEqual(report!.profileName, "MaestroPreflightOptions")
        XCTAssertEqual(report!.results.first!.category, .text)
    }
    
    func test_InDesignReport_ImageLink() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "imageLink", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.documentName, "imageLink.indd")
        XCTAssertEqual(report!.profileName, "MaestroPreflightOptions")
        XCTAssertEqual(report!.results.first!.category, .links)
    }
    
    func test_InDesignReport_ImageResolution() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "imageResolution", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.documentName, "imageResolution.indd")
        XCTAssertEqual(report!.profileName, "MaestroPreflightOptions")
        XCTAssertEqual(report!.results.count, 2)
        XCTAssertEqual(report!.results.first!.category, .colour)
        XCTAssertEqual(report!.results.last!.category, .imagesAndObjects)
    }
}
