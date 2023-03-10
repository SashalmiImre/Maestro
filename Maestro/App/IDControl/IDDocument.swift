//
//  IDDocument.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2021. 07. 09..
//

#if os(macOS)
import Foundation
import ScriptingBridge

extension IDApplication {
    public final class IDDocument {
        private var application: IDApplication
        private var document: InDesignDocument
        
        
        // MARK: - Initialization/deinitialization
        
        internal init(application: IDApplication, url: URL) throws {
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: url.path)
            else { throw DocumentError.pathNotExists }
            
            guard let document = application.application.open?(url.path, showingWindow: false, openOption: .openOriginal) as? InDesignDocument
            else { throw DocumentError.couldNotOpenTheDocument }
            self.document = document
            self.application = application
        }
        
        deinit {
            self.close()
        }
        
        
        // MARK: - Export
        
        func export(to url: URL) {
            self.application.setPDFExportPreference()
            self.document.exportFormat?(InDesignEXft.pdfType.rawValue,
                                        to: url.path,
                                        showingOptions: false,
                                        using: nil,
                                        versionComments: nil,
                                        forceSave: true)
        }
        
        
        // MARK: - Close
        
        func close() {
            self.document.closeSaving?(InDesignSavo.no,
                                       savingIn: nil,
                                       versionComments: nil,
                                       forceSave: true)
        }
        
        
        // MARK: - Report
        
        func report() throws -> Report? {
            let profile = try setProfile()
            defer { remove(profile: profile) }
            
            guard let process = document.activeProcess else {
                throw DocumentError.noActivePreflightProcess
            }
            
            var wait = true
            var resultsObject: Any?
            repeat {
                if wait { wait = process.waitForProcessWaitTime!(1) }
                resultsObject = (process.aggregatedResults as? SBObject)?.get()
            } while wait || resultsObject == nil
            guard let aggregatedResults = resultsObject as? NSArray else { return nil }
            
            return try Report.build(from: aggregatedResults)
        }
        
        private func setProfile() throws -> InDesignPreflightProfile {
            let profile = try self.application.loadPreflightProfile()
            self.document.preflightOptions!.setPreflightWorkingProfile?(profile)
            self.document.preflightOptions!.setPreflightOff!(false)
            return profile
        }
        
        private func remove(profile: InDesignPreflightProfile) {
            self.document.preflightOptions?.setPreflightOff?(true)
            self.application.removePrelightProfile(profile)
        }
        
        
        // MARK: - Volume check
        
        func isRequiredVolumesConnected() throws -> Bool {
            let fileManager = FileManager.default
            guard var mountedVolumes = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: nil),
                  let links = self.document.links?()
            else { throw DocumentError.connectedVolumesCannotBeChecked }
            
            mountedVolumes.removeAll { !$0.pathComponents.contains("Volumes") }
            for link in links {
                guard let link = link as? InDesignLink
                else { throw DocumentError.connectedVolumesCannotBeChecked }
                guard link.status == .linkMissing,
                      var filePath = link.filePath else { continue }
                filePath = "/" + filePath.replacingOccurrences(of: ":", with: "/")

                if mountedVolumes.allSatisfy({ mountedVolume in
                    !filePath.hasPrefix(mountedVolume.path)
                }) { return false }
            }
            return true
        }
    }
}


// MARK: - Document errors

extension IDApplication.IDDocument {
    enum DocumentError: Error {
        case pathNotExists
        case couldNotOpenTheDocument
        case failedToRetrievePreflightData
        case connectedVolumesCannotBeChecked
        case noActivePreflightProcess
    }
}
#endif
