//
//  AnimatableBackground.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 15..
//

import SwiftUI

#if os(OSX)
typealias OSColor = NSColor
#else
typealias OSColor = UIColor
#endif

struct AnimatableGradientModifier: AnimatableModifier {

    let fromGradient: Gradient
    let toGradient: Gradient
    var progress: CGFloat = 0.0
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func body(content: Content) -> some View {
        var gradientColors = [Color]()
        
        for i in 0..<fromGradient.stops.count {
                let fromColor = OSColor(fromGradient.stops[i].color)
                let toColor   = OSColor(toGradient.stops[i].color)
            gradientColors.append(colorMixer(fromColor: fromColor, toColor: toColor, progress: progress))
        }
        
        return LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    func colorMixer(fromColor: OSColor, toColor: OSColor, progress: CGFloat) -> Color {
        guard let fromColor = fromColor.cgColor.components else { return Color(fromColor) }
        guard let toColor   = toColor.cgColor.components else { return Color(toColor) }
        
        let red   = fromColor[0] + (toColor[0] - fromColor[0]) * progress
        let green = fromColor[1] + (toColor[1] - fromColor[1]) * progress
        let blue  = fromColor[2] + (toColor[2] - fromColor[2]) * progress
        
        
        return Color(red: Double(red), green: Double(green), blue: Double(blue))
    }
}


extension View {
    func animatableGradient(fromGradient: Gradient, toGradient: Gradient, progress: CGFloat) -> some View {
        self.modifier(AnimatableGradientModifier(fromGradient: fromGradient, toGradient: toGradient, progress: progress))
    }
}
