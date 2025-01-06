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
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(alignment: .bottom, spacing: 0) {
                
                if pagePair.coverage.lowerBound > 0 {
                    PageView(page: pagePair.leftPage)
                } else {
                    Spacer()
                }
                
                // Jobb oldal
                if pagePair.coverage.upperBound <= manager.maxPageNumber {
                    PageView(page: pagePair.rightPage)
                } else {
                    Spacer()
                }
            }
            
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
