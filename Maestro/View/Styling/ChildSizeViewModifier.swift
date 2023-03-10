//
//  ChildSizeViewModifier.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 31..
//

import Foundation
import SwiftUI

struct ChildSize: ViewModifier {
    @Binding var size: CGSize
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: SizePreferenceKey.self, value: proxy.size)
                }
            )
            .onPreferenceChange(SizePreferenceKey.self) { preferences in
                self.size = preferences
            }
    }
}

struct SizePreferenceKey: PreferenceKey {
    typealias Value = CGSize
    static var defaultValue: Value = .zero

    static func reduce(value _: inout Value, nextValue: () -> Value) {
        _ = nextValue()
    }
}

// MARK: - View extension

extension View {
    func childSize(size: Binding<CGSize>) -> some View {
        modifier(ChildSize(size: size))
    }
}
