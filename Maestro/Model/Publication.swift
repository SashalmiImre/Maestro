//
//  Publication.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 14..
//

import Foundation
import RealmSwift

class Publication: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String = "Untitled"
    @Persisted var version: String = "0"
    @Persisted var isSpecialIssue: Bool = false
    @Persisted var publicationDate: Date = Date()
    @Persisted var startPageNumber: Int = 1
    @Persisted var endPageNumber: Int = 1
    @Persisted var pageSize: Size? = .init()
    @Persisted var articles: List<Article> = .init()
    @Persisted var deadlines: List<Deadline> = .init()
}

class Article: EmbeddedObject {
    @Persisted var name: String = "Untitled"
    @Persisted var reservations: List<PageReservation> = .init()
}

class Deadline: EmbeddedObject {
    @Persisted var date: Date
    @Persisted var startPageNumber: Int = 1
    @Persisted var endPageNumber: Int = 1
}

class PageReservation: EmbeddedObject {
    enum Orientation: String, PersistableEnum {
        case portrait
        case landscape
    }
    
    @Persisted var pageNumber: Int = 1
    @Persisted var percentage: Int = 100
    @Persisted var pageSize: Size? = Size()
    @Persisted var orientation: Orientation = .portrait
}

class Size: EmbeddedObject {
    @Persisted var width: Int = 205
    @Persisted var height: Int = 275
}


// MARK: - For preview

#if DEBUG
extension Publication {
    static var publication1: Publication {
        let publication = Publication()
        publication.name = "Story46"
        publication.isSpecialIssue = false
        publication.publicationDate = Date()
        publication.startPageNumber = 1
        publication.endPageNumber = 52
        publication.articles.append(Article.article1)
        return publication
    }
    
    static var publication2: Publication {
        let publication = Publication()
        publication.name = "StoryKSZ Tavasz"
        publication.startPageNumber = 1
        publication.endPageNumber = 82
        return publication
    }
    
    static var publication3: Publication {
        let publication = Publication()
        publication.name = "Best46"
        publication.startPageNumber = 1
        publication.endPageNumber = 52
        return publication
    }
}
#endif

#if DEBUG
extension Article {
    static var article1: Article {
        let article = Article()
        article.reservations.append(PageReservation.pageReservation1)
        return article
    }
}
#endif

#if DEBUG
extension PageReservation {
    static var pageReservation1: PageReservation {
        let pageReservation = PageReservation()
        pageReservation.orientation = .portrait
        pageReservation.percentage = 100
        pageReservation.pageNumber = 3
        return pageReservation
    }
}
#endif
