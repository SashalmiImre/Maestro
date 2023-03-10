//
//  IDApplication.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2021. 07. 09..
//

#if os(macOS)
import Foundation
import ScriptingBridge

final class IDApplication {
    static private var preflightOptionsName = "MaestroPreflightOptions"
    internal var application: InDesignApplication
    
    init() throws {
        guard let application = SBApplication(bundleIdentifier: "com.adobe.InDesign")
        else { throw ApplicationError.couldNotConnetToInDesignApplication}
        self.application = application
        self.application.scriptPreferences?.setUserInteractionLevel?(.neverInteract)
        self.cleanUp()
    }
    
    func openDocument(at url: URL) throws -> IDDocument {
        return try IDDocument(application: self, url: url)
    }
    
    
    // MARK: - Export preferences
    
    func setPDFExportPreference() {
        let preference = self.application.PDFExportPreferences!
        
        // Basic PDF output options
        preference.setStandardsCompliance?(.pdfx1a2003Standard)
        preference.setAcrobatCompatibility?(.acrobat6)
        preference.setPageRange?(InDesignEbrf.exportAllPages)
        preference.setExportGuidesAndGrids?(false)
        preference.setExportLayers?(false)
        preference.setExportNonprintingObjects?(false)
        preference.setExportReaderSpreads?(true)
        preference.setGenerateThumbnails?(false)
        preference.setIgnoreSpreadOverrides?(false)
        preference.setIncludeBookmarks?(false)
        preference.setIncludeHyperlinks?(false)
        preference.setIncludeICCProfiles?(.includeAll)
        preference.setIncludeSlugWithPDF?(false)
        preference.setIncludeStructure?(false)
        preference.setInteractiveElementsOption?(.doNotInclude)
        preference.setSubsetFontsBelow?(0)
        
        // Color images
        preference.setColorBitmapCompression?(.jpeg)
        preference.setColorBitmapQuality?(.maximum)
        preference.setColorBitmapSampling?(.bicubicDownsample)
        preference.setColorBitmapSamplingDPI?(150)
        preference.setThresholdToCompressColor?(150)
        
        // Grayscale images
        preference.setGrayscaleBitmapCompression?(.jpeg)
        preference.setGrayscaleBitmapQuality?(.maximum)
        preference.setGrayscaleBitmapSampling?(.bicubicDownsample)
        preference.setGrayscaleBitmapSamplingDPI?(150)
        preference.setThresholdToCompressGray?(150)
        
        // Bitmap images
        preference.setMonochromeBitmapCompression?(.ccit4)
        preference.setMonochromeBitmapSampling?(.downsample)
        preference.setMonochromeBitmapSamplingDPI?(300)
        preference.setThresholdToCompressMonochrome?(300)
        
        // Other compressions
        preference.setCompressionType?(.compressObjects)
        preference.setCompressTextAndLineArt?(true)
        preference.setCropImagesToFrames?(true)
        preference.setOptimizePDF?(true)
        
        // Bleed
        preference.setBleedTop?(0)
        preference.setBleedBottom?(0)
        preference.setBleedInside?(0)
        preference.setBleedOutside?(0)
        
        // Marks & bars
        preference.setBleedMarks?(false)
        preference.setCropMarks?(false)
        preference.setRegistrationMarks?(false)
        preference.setPageInformationMarks?(false)
        preference.setColorBars?(false)
        
        // View PDF after exoprt
        preference.setViewPDF?(false)
    }
    
    
    // MARK: - Preflight
    
    internal func loadPreflightProfile() throws -> InDesignPreflightProfile {
        guard let preflighProfilePath = Bundle.main.path(forResource: IDApplication.preflightOptionsName,
                                                         ofType: "idpp")
        else { throw ApplicationError.couldNotFindPreflightProfileFile }
        
        guard let preflightProfile =  self.application.loadPreflightProfileFrom?(preflighProfilePath)
        else { throw ApplicationError.couldNotLoadPreflightProfile }
        
        return preflightProfile
    }
    
    internal func removePrelightProfile(_ preflightProfile: InDesignPreflightProfile) {
        self.application.preflightProfiles?().remove(preflightProfile)
    }
    
    
    // MARK: - Clenup
    
    func cleanUp() {
        self.closeInvisibleDocuments()
        self.removeUnusedPreflightProfiles()
    }
    
    private func closeInvisibleDocuments() {
        guard let openedDocuments = self.application.documents?() as? [InDesignDocument]
        else { return }
        for openedDocument in openedDocuments {
            guard openedDocument.visible == false else { continue }
            openedDocument.closeSaving?(InDesignSavo.no,
                                       savingIn: nil,
                                       versionComments: nil,
                                       forceSave: true)
        }
    }
    
    private func removeUnusedPreflightProfiles() {
        guard let preflightProfiles = self.application.preflightProfiles?() as? [InDesignPreflightProfile]
        else { return }
        for preflightProfile in preflightProfiles {
            if preflightProfile.name!.hasPrefix(IDApplication.preflightOptionsName) {
                self.application.preflightProfiles?().remove(preflightProfile)
            }
        }
    }
}


// MARK: - Application errors

extension IDApplication {
    enum ApplicationError: Error {
        case couldNotConnetToInDesignApplication
        case couldNotFindPreflightProfileFile
        case couldNotLoadPreflightProfile
    }
}
#endif
