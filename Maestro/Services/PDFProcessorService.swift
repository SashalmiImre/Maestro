import Foundation
import PDFKit
import AppKit

public enum PDFProcessorService {
    public static func processFolder(_ url: URL) async throws -> Publication? {
        return Publication(folderURL: url)
    }
}

