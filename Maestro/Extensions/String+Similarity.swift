import Foundation

/// String típus kiterjesztése szöveg-hasonlósági funkciókkal
extension String {
    /// Kiszámítja a hasonlóság mértékét két string között.
    /// A visszatérési érték 0 és 1 között van, ahol:
    /// - 0 jelenti, hogy a két string teljesen különböző
    /// - 1 jelenti a tökéletes egyezést
    /// - köztes értékek a részleges hasonlóság mértékét jelzik
    ///
    /// - Parameter other: A string, amivel össze szeretnénk hasonlítani
    /// - Returns: A hasonlóság mértéke 0 és 1 között
    ///
    /// Példa használat:
    /// ```swift
    /// let similarity = "hello".calculateSimilarity(with: "helo")  // 0.8
    /// ```
    func calculateSimilarity(with other: String) -> Double {
        let distance = self.levenshteinDistance(with: other)
        let maxLength = Double(max(self.count, other.count))
        return 1 - (Double(distance) / maxLength)
    }
    
    /// Kiszámítja a Levenshtein távolságot két string között.
    /// A Levenshtein távolság azt mutatja meg, hogy minimum hány karakter beszúrás,
    /// törlés vagy csere művelet szükséges ahhoz, hogy az egyik stringből
    /// a másikat megkapjuk.
    ///
    /// - Parameter other: A string, amivel össze szeretnénk hasonlítani
    /// - Returns: A Levenshtein távolság (minimum szükséges műveletek száma)
    ///
    /// Implementációs részletek:
    /// - Dinamikus programozást használ a távolság kiszámítására
    /// - A d[i][j] mátrix tárolja a részeredményeket
    /// - Három műveletet vesz figyelembe: beszúrás, törlés, csere
    /// - Minden művelet költsége 1
    private func levenshteinDistance(with other: String) -> Int {
        // Inicializáljuk a dinamikus programozási mátrixot
        let empty = Array(repeating: Array(repeating: 0, count: other.count + 1), count: self.count + 1)
        var d = empty
        
        // Karaktertömbbé alakítjuk a stringeket a hatékonyabb indexelés érdekében
        let selfArray = Array(self)
        let otherArray = Array(other)
        
        // Inicializáljuk az első sort és oszlopot
        for i in 0...selfArray.count {
            d[i][0] = i  // törlési költség az első oszlopban
        }
        
        for j in 0...otherArray.count {
            d[0][j] = j  // beszúrási költség az első sorban
        }
        
        // Kitöltjük a mátrixot
        for i in 1...selfArray.count {
            for j in 1...otherArray.count {
                if selfArray[i-1] == otherArray[j-1] {
                    // Ha a karakterek megegyeznek, nincs szükség műveletre
                    d[i][j] = d[i-1][j-1]
                } else {
                    // A három lehetséges művelet közül a legkisebb költségűt választjuk
                    d[i][j] = Swift.min(
                        d[i-1][j] + 1,    // deletion (törlés)
                        d[i][j-1] + 1,    // insertion (beszúrás)
                        d[i-1][j-1] + 1   // substitution (csere)
                    )
                }
            }
        }
        
        // A jobb alsó sarok tartalmazza a végső távolságot
        return d[selfArray.count][otherArray.count]
    }
} 
