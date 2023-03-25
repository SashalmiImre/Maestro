//
//  Article.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 16..
//

import Foundation
import RealmSwift

class Article: PageReservation {
    @Persisted(originProperty: "articles") var publication: LinkingObjects<Publication>
}


// MARK: - For preview

extension Article {
    static var article1: Article {
        let article = Article(value: PageReservation.pageReservation1)
        article.name = "Teszt article"
        return article
    }
}
