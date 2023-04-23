//
//  ArtistCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI

struct ArtistCardView: View {

    @State private var isOverviewExpanded: Bool = false

    @Binding var navigationPath: NavigationPath

    let artist: Artist

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HeaderView(details: artist.details)
                .padding(.horizontal)
            
            if let biography = artist.details.biography, !biography.isEmpty {
                OverviewView(isExpanded: $isOverviewExpanded, overview: biography)
                    .padding(.horizontal)
            }

            SpecsView(title: "Specs", items: specs)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.12), radius: 4, y: -8)
        .animation(.default, value: isOverviewExpanded)
    }

    private var specs: [SpecsView.Item] {
        var items: [SpecsView.Item] = []

        if let birthday = artist.details.birthday {
            items.append(.date(birthday, label: "Birthday"))
        }

        if let deathday = artist.details.deathday {
            items.append(.date(deathday, label: "Death"))
        }

        return items
    }
}

private struct HeaderView: View {

    let details: ArtistDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(details.name).font(.title)

            HStack {
                if let birthday = details.birthday {
                    Text(birthday, format: .dateTime.year()).font(.caption)
                }

                if let deathday = details.deathday {
                    Text("-")
                    Text(deathday, format: .dateTime.year()).font(.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct OverviewView: View {

    @Binding var isExpanded: Bool

    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.title2)

            Text(overview)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { isExpanded.toggle() }) {
                Text(isExpanded ? "Less" : "More")
            }
        }
        .padding(.horizontal)
    }
}

struct ArtistCardView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistCardView(navigationPath: .constant(.init()),
                       artist: MockWebService.artist(with: 287))
    }
}
