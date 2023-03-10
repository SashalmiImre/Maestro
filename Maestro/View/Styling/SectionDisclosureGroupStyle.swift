//
//  SectionDisclosureGroupStyle.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 25..
//

import SwiftUI

struct SectionDisclosureGroupStyle: DisclosureGroupStyle {
#if os(macOS)
    @State private var onHover: Bool = false
#endif
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation { configuration.isExpanded.toggle() }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    configuration.label
                        .font(.caption.lowercaseSmallCaps())
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Image(systemName: "arrow.down.circle.fill")
                        .rotationEffect(.degrees(configuration.isExpanded ? 0 : -90))
                        .animation(.easeInOut, value: configuration.isExpanded)
#if os(macOS)
                        .foregroundColor(onHover ? .accentColor : .secondary)
                        .opacity(onHover ? 1 : 0.15)
#else
                        .foregroundColor(.accentColor)
#endif
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
#if os(macOS)
            .onHover { hover in
                withAnimation {
                    onHover = hover
                }
            }
#endif
            
            if configuration.isExpanded {
                GroupBox {
                    VStack(alignment: .leading) {
                        configuration.content
                    }
                }
            }
        }
    }
}


// MARK: - Previews

struct SectionDisclosureGroupStyle_Previews: PreviewProvider {
    static var previews: some View {
        DisclosureGroup {
            Text("Content")
        } label: {
            Text("Label")
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
        .previewDevice(PreviewDevice(rawValue: "Mac"))
        .previewDisplayName("SectionDisclosureGroupStyle Mac")
        
        DisclosureGroup {
            Text("Content")
        } label: {
            Text("Label")
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
        .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
        .previewDisplayName("SectionDisclosureGroupStyle iOS")
    }
}
