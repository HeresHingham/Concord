//
//  PlaceAnnotationView.swift
//  Here's Concord!
//
//  Created by Cameron Conway on 9/1/26.
//

import SwiftUI

struct PlaceAnnotationView: View {
  let placeName: String
  let shortName: String
  let specials: String
  let type: Int
  let iconSize: CGFloat
  let selected: Bool
  let opacity: Double
  var iconResizePercent: Double
  let placeFilter: PlaceFilter
  let imagery3DMode: Bool
  let showLabels: Bool
  @Environment(\.colorScheme) var colorScheme
  @State private var isRotated = false

  var body: some View {
    var name = placeFilter != .None ? placeName : shortName == "Nesting" ? "Nesting            " : shortName
    let fontWeight = Font.Weight.regular
    var zIndex = 0.0
    let titlePadding = 0.0
    var newIconSize = 0.0
    var foregroundColor: Color = .clear
    let signWaveDuration = Double.random(in: 0.5...1.0)
    let rotationDistance = Double.random(in: 0.0...15.0)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    @AppStorage("ShowSpecial") var showSpecial: Bool = true

    if selected == true {
      foregroundColor = colorScheme == .dark ? .white : imagery3DMode == true ? .white : .black
      name = placeName      
      zIndex = 100.0
    } else {
      foregroundColor = imagery3DMode == true || colorScheme == .dark ? .white : .black
    }

    let specialImageName = imageNameIfSpecialIsToday(special: specials, showSpecial: showSpecial)
    
    let resizePercent = iconResizePercent
    let zoomAdjustedIconSize = iconSize * 2
    newIconSize = resizePercent != 0 ? zoomAdjustedIconSize * resizePercent : zoomAdjustedIconSize
    @AppStorage("ShowSpecials") var showSpecials: Bool = true
    
    return ZStack {
      if specialImageName != "" && showSpecials == true {
        VStack() {
          Image("Specials/\(specialImageName)")
            .resizable()
            .scaledToFit()
            .frame(width: max(40, newIconSize), height: max(40, newIconSize))
            .rotationEffect(.degrees(isRotated ? rotationDistance : -rotationDistance))
            .animation(
              Animation.easeInOut(duration: signWaveDuration)
                .repeatForever(autoreverses: true),
              value: isRotated
            )
        }
        .onAppear {
          isRotated = true
        }
        .zIndex(zIndex + 1)
      }
      VStack(spacing: 0) {
        if type >= 20 {
          Text(name)
            .foregroundColor(Color(white: 1.0))
            .font(Font.caption)
            .fontWeight(fontWeight)
            .background(Color.clear)
            .customStroke(color: .black, width: 0.2)
            .opacity(opacity)
            .blur(radius: 0.0)
        } else {
          if imagery3DMode == true {
            Image("Blank")
              .resizable()
              .scaledToFit()
              .frame(width: newIconSize, height: newIconSize)
              .zIndex(zIndex)
          } else {
            Image("\(placeName.replacingOccurrences(of: "/", with: ""))/icon")
              .resizable()
              .scaledToFit()
              .frame(width: newIconSize, height: newIconSize)
              .zIndex(zIndex)
              .opacity(opacity)
          }
          
          if showLabels == true && name != "" {
            Text(name)
              .foregroundStyle(foregroundColor)
              .font(Font.caption)
              .fontWeight(fontWeight)
              .padding(.top, titlePadding)
              .opacity(opacity)
          }
        }
      }
      .zIndex(zIndex)
    }
  }
}

struct StrokeModifier: ViewModifier {
    var strokeSize: CGFloat = 1
    var strokeColor: Color = .blue

    func body(content: Content) -> some View {
        content
            .padding(strokeSize)
            .background(
                Rectangle()
                    .foregroundStyle(strokeColor)
                    .mask(outline(context: content))
            )
    }

    private func outline(context: Content) -> some View {
        Canvas { context, size in
            context.addFilter(.alphaThreshold(min: 0.01))
            context.drawLayer { layer in
              if let text = context.resolveSymbol(id: 0) {
                layer.draw(text, at: CGPoint(x: size.width / 2, y: size.height / 2))
              }
            }
        } symbols: {
            context.tag(0).blur(radius: strokeSize)
        }
    }
}

extension View {
    func customStroke(color: Color, width: CGFloat) -> some View {
        self.modifier(StrokeModifier(strokeSize: width, strokeColor: color))
    }
}

