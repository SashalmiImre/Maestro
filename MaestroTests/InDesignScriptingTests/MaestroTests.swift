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
        XCTAssertEqual(report!.notesCount, 0)
    }
    
    func test_InDesignReport_RGBColor() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "rgbColor", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.notes.first!.kind, .colour)
    }
    
    func test_InDesignReport_TextOverflow() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "textOverflow", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.notes.first!.kind, .text)
    }
    
    func test_InDesignReport_imageLink() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "imageLink", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.notes.first!.kind, .links)
    }
    
    func test_InDesignReport_imageResolution() throws {
        let app = try IDApplication()
        let bundle = Bundle(for: Self.self)
        let docURL = bundle.url(forResource: "imageResolution", withExtension: "indd")!
        let doc = try app.openDocument(at: docURL)
        let report = try doc.report()
        doc.close()
        
        XCTAssertNotNil(report)
        XCTAssertEqual(report!.notesCount, 2)
        XCTAssertEqual(report!.notes[0].kind, .colour)
        XCTAssertEqual(report!.notes[1].kind, .imagesAndObjects)
    }
}
