//
//  RowActionsViewModel.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 02. 15..
//

import Foundation
import SwiftUI

extension RowActions {
        struct RowActionsViewModel: DynamicProperty {
        
        var edge: Edge = .trailing
        
        @GestureState var gestureState: Double = 0
        @State        var showingButton: Bool = false
        @FocusState   var isFocused: Bool
        @State        var contentSize: CGSize = .zero
        private var minimumDisplacement: Double = 50
        
        init(edge: Edge) {
            self.edge = edge
        }
        
        // MARK: Swipe direction
        func swipeDirection(translation: Double) -> SwipeDirection? {
            guard translation != 0 else { return nil }
            return translation < 0 ? .toLeft : .toRight
        }
        
        func isProperSwipeDirection(translation: Double) -> Bool {
            guard let swipeDirection = swipeDirection(translation: translation),
                  !showingButton else { return true }
            return (swipeDirection == .toLeft && edge == .trailing)
            || (swipeDirection == .toRight && edge == .leading)
        }
        
        func isOppositeSwipeDirection(translation: Double) -> Bool {
            let swipeDirection = swipeDirection(translation: translation)
            return (swipeDirection == .toLeft && edge == .leading)
            || (swipeDirection == .toRight && edge == .trailing)
        }
        
        // MARK: Callbacks
        func onUpdate(_ currentState: DragGesture.Value,
                              _ gestureState: inout Double) {
            let translation = currentState.translation.width
            guard isProperSwipeDirection(translation: translation) else { return }
            gestureState = translation
        }
        
        func onChange() {
            let isOpposite = isOppositeSwipeDirection(translation: gestureState)
            switch (isOpposite, showingButton) {
            case (true, true):
                withAnimation { showingButton = false
                    isFocused = false
                }
            case (true, false):
                return
            case (false, false):
                if abs(gestureState) > minimumDisplacement {
                    withAnimation { showingButton = true
                        isFocused = true
                    }
                }
            case (false, true):
                break
            }
            withAnimation(.easeInOut) {
                isFocused = true
            }
        }
    }
}
