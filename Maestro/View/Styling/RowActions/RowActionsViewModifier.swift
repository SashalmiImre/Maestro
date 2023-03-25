//
//  RowActions.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 27..
//

import SwiftUI

struct RowActions<Button: View>: ViewModifier {
    enum SwipeDirection {
        case toRight
        case toLeft
    }
    
    private var vm: RowActionsViewModel
    var button: Button
    
    init(edge: Edge, @ViewBuilder button: () -> Button) {
        self.vm = RowActionsViewModel(edge: edge)
        self.button = button()
    }

    func body(content: Content) -> some View {
        let swipeGesture  = DragGesture(minimumDistance: 3,
                                        coordinateSpace: .local)
            .updating(vm.$gestureState) { currentState, gestureState, _ in
                vm.onUpdate(currentState, &gestureState)
            }
            .onChanged { _ in vm.onChange() }
        
        HStack {
            // Leading button
            if vm.edge == .leading && vm.showingButton {
                button
                    .focused(vm.$isFocused)
            }
            
            // Content
            content
                .disabled(vm.gestureState != 0 || vm.showingButton)
                .childSize(size: vm.$contentSize)
                .clipped()
                .fixedSize()
                .contentShape(Rectangle())
                .simultaneousGesture(swipeGesture)
                .animation(.easeInOut, value: vm.gestureState)
                .offset(CGSize(width: vm.gestureState, height: 0))
            
            // Trailing button
            if vm.edge == .trailing && vm.showingButton {
                button
                    .focused(vm.$isFocused)
            }
        }
        .frame(width: vm.contentSize.width,
               height: vm.contentSize.height,
               alignment: vm.edge == .trailing ? .trailing : .leading)
        .clipped()
    }
}


// MARK: - View extension

extension View {
    func rowActions(edge: Edge = .trailing, button: () -> some View) -> some View {
        modifier(RowActions(edge: edge, button: button))
    }
}


// MARK: - Previews

struct RowActions_Previews: PreviewProvider {
    static var previews: some View {
        DeadlineListItemView(deadline: DeadlineProjection(projecting: Deadline()))
            .rowActions {
                Button {
                    
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                }
                .buttonStyle(.plain)
            }
            .rowActions(edge: .leading) {
                Button {

                } label: {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("RowActions Mac")
        
        DeadlineListItemView(deadline: DeadlineProjection(projecting: Deadline()))
            .rowActions {
                Button {
                    
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                }
                .buttonStyle(.plain)
            }
            .rowActions(edge: .leading) {
                Button {

                } label: {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("RowActions iOS")
    }
}
