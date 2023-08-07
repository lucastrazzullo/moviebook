//
//  StartView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/08/2023.
//

import SwiftUI

struct StartView: View {

    @State private var opacity: CGFloat = 0
    @State private var textColor: Color = .accentColor

    let onPresented: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image("Icon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100)

            Text("Moviebook".uppercased())
                .font(.hero)
                .foregroundColor(textColor)
        }
        .opacity(opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.thinMaterial)
        .onAppear {
            withAnimation(.linear(duration: 0.4)) { opacity = 1 }
            withAnimation(.linear(duration: 1).repeatForever()) { textColor = .secondaryAccentColor }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onPresented()
            }
        }
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView() {}
    }
}
