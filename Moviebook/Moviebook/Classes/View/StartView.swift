//
//  StartView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/08/2023.
//

import SwiftUI

struct StartView: View {

    let colors: [Color] = [
        .accentColor,
        .secondaryAccentColor,
        .tertiaryAccentColor
    ]

    let colorsDuration: TimeInterval = 1

    @State private var logo1Opacity: CGFloat = 0
    @State private var logo2Opacity: CGFloat = 0
    @State private var logo3Opacity: CGFloat = 0
    @State private var textColorIndex = 0

    let onPresented: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Image("Logo-1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(logo1Opacity)
                    .scaleEffect(x: logo1Opacity, y: logo1Opacity)

                Image("Logo-2")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(logo2Opacity)
                    .scaleEffect(x: logo2Opacity, y: logo2Opacity)

                Image("Logo-3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(logo3Opacity)
                    .scaleEffect(x: logo3Opacity, y: logo3Opacity)
            }
            .frame(width: 80)

            TimelineView(.periodic(from: .now, by: colorsDuration)) { context in
                VStack {
                    Text("Moviebook".uppercased())
                        .font(.hero)


                    Text("loading")
                        .font(.subheadline)
                        .foregroundColor(colors[Int(context.date.timeIntervalSince1970) % colors.count])
                        .animation(.easeInOut(duration: colorsDuration))
                }
            }
        }
        .opacity(logo3Opacity)
        .scaleEffect(x: logo3Opacity, y: logo3Opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) { logo1Opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeInOut(duration: 0.6)) { logo2Opacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.easeInOut(duration: 0.8)) { logo3Opacity = 1 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        onPresented()
                    }
                }
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView() {}
    }
}
