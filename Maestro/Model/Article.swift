//
//  Article.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 16..
//

import Foundation
import RealmSwift

class Article: PageReservation {
    
}


// MARK: - For preview

#if DEBUG
extension Article {
    static var article1: Article {
        let article = Article(value: PageReservation.pageReservation1)
        return article
    }
}
#endif
