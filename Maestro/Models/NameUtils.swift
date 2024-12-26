import Foundation

enum NameUtils {
    static func isNameTooSimilar(_ fileName: String, to existingFiles: [URL]) -> Bool {
        for existingFile in existingFiles {
            let existingName = existingFile.deletingPathExtension().lastPathComponent
            if fileName.calculateSimilarity(with: existingName) > 0.9 {
                return true
            }
        }
        return false
    }
}

