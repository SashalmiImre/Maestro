//
//  URL+isSubfolder.swift
//  Maestro
//
//  Created by Sashalmi Imre on 14/12/2024.
//
import Foundation

extension URL {
    /// Ellenőrzi, hogy az aktuális URL egy adott szülő URL subfolder-e.
    ///
    /// - Parameter parent: A szülő URL, amelyhez viszonyítva ellenőrizni szeretnénk.
    /// - Returns: `true`, ha az aktuális URL a megadott szülő URL subfolder-e; különben `false`.
    func isSubfolder(of parent: URL) -> Bool {
        // Ellenőrizzük, hogy mindkét URL fájlrendszerbeli URL-e
        guard self.isFileURL, parent.isFileURL else {
            return false
        }

        // Szimbolikus linkek feloldása és path-ek standardizálása
        let standardizedSelfPath   = self.resolvingSymlinksInPath().standardizedFileURL.path
        let standardizedParentPath = parent.resolvingSymlinksInPath().standardizedFileURL.path

        // Ellenőrizd, hogy az aktuális path a parent path prefixe-e
        return standardizedSelfPath.hasPrefix(standardizedParentPath) && (standardizedSelfPath != standardizedParentPath)
    }
}
