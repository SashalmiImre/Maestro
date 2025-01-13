//
//  PagePairView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 27/12/2024.
//

import SwiftUI

/// Egy oldalpár megjelenítése
struct PagePairView: View {
    @EnvironmentObject var manager: PublicationManager
    
    let pagePair: PagePair
    
    private var isSameArticle: Bool {
        pagePair.leftPage.article == pagePair.rightPage.article
    }
    
    private var leftHasFinalPDF: Bool {
        pagePair.leftPage.article?.hasFinalPDF ?? true
    }
    
    private var rightHasFinalPDF: Bool {
        pagePair.rightPage.article?.hasFinalPDF ?? true
    }
    
    var body: some View {
        let sameArticleWithNoFinalPDF = isSameArticle && !leftHasFinalPDF && !rightHasFinalPDF
        let strokeLineWidth = 5 * manager.zoomLevel
        
        VStack(spacing: 2) {
            HStack(alignment: .bottom, spacing: 0) {
                
                if pagePair.coverage.lowerBound > 0 {
                    PageView(page: pagePair.leftPage)
                        .id("Page\(pagePair.leftPage.pageNumber)")
                        .overlay(
                            Rectangle()
                                .stroke(
                                    (!leftHasFinalPDF && (!isSameArticle || rightHasFinalPDF))
                                    ? Color.red : Color.clear,
                                    lineWidth: strokeLineWidth
                                )
                        )
                } else {
                    Spacer()
                }
                
                // Jobb oldal
                if pagePair.coverage.upperBound <= manager.maxPageNumber {
                    PageView(page: pagePair.rightPage)
                        .id("Page\(pagePair.rightPage.pageNumber)")
                        .overlay(
                            Rectangle()
                                .stroke(
                                    (!rightHasFinalPDF && (!isSameArticle || leftHasFinalPDF))
                                    ? Color.red : Color.clear,
                                    lineWidth: strokeLineWidth
                                )
                        )
                } else {
                    Spacer()
                }
            }
            .overlay(
                Rectangle()
                    .stroke(
                        sameArticleWithNoFinalPDF ? Color.red : Color.clear,
                        lineWidth: strokeLineWidth
                    )
            )
            
            // Oldalszámok
            HStack(spacing: 0) {
                let pageNumberFontSize = 24 * manager.zoomLevel
                
                if pagePair.coverage.lowerBound > 0 {
                    Text("\(pagePair.leftPage.pageNumber)")
                        .font(.system(size: pageNumberFontSize))
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
                
                Spacer()
                
                if pagePair.coverage.upperBound <= manager.maxPageNumber {
                    Text("\(pagePair.rightPage.pageNumber)")
                        .font(.system(size: pageNumberFontSize))
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
            }
        }
    }
}
