import Foundation

/// Az `Array` típus kiterjesztése, amely lehetővé teszi a tömbök darabolását meghatározott méretű részekre.
extension Array {
    /// Felosztja a tömböt kisebb részekre, ahol minden rész a megadott méretű.
    ///
    /// - Parameter size: Az egyes részek maximális mérete.
    /// - Returns: Egy tömb, amely a kisebb részeket tartalmazza.
    ///
    /// Példa használat:
    /// ```swift
    /// let numbers = [1, 2, 3, 4, 5, 6, 7]
    /// let chunked = numbers.chunked(into: 3)
    /// // chunked: [[1, 2, 3], [4, 5, 6], [7]]
    /// ```
    func chunked(into size: Int) -> [[Element]] {
        // Ellenőrizzük, hogy a méret pozitív
        guard size > 0 else { return [] }
        
        // Felosztjuk a tömböt a megadott méretű részekre
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
} 
