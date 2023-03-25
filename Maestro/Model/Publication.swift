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
    @Persisted var advertisements: List<Advertising> = .init()
    @Persisted var deadlines: List<Deadline> = .init()
    
    func articles(for pageNumber: Int) -> Results<Article> {
        return articles.where { $0.pageNumber == pageNumber }
    }
    
    func advertising(for pageNumber: Int) -> Results<Advertising> {
        return advertisements.where { $0.pageNumber == pageNumber }
    }
}


// MARK: - For preview

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
