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

            SpecsView(artistDetails: artist.details)
                .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.12), radius: 4, y: -8)
        .animation(.default, value: isOverviewExpanded)
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

private struct SpecsView: View {

    private static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()

    let artistDetails: ArtistDetails

    var body: some View {
        VStack(alignment: .leading) {
            Text("Specs")
                .font(.title2)
                .padding(.leading)

            VStack(alignment: .leading, spacing: 12) {

                if let birthday = artistDetails.birthday {
                    SpecsRow(label: "Birthday") {
                        Text(birthday, style: .date)
                    }
                }

                if let deathday = artistDetails.deathday {
                    SpecsRow(label: "Death") {
                        Text(deathday, style: .date)
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(.thinMaterial))
        }
    }
}

private struct SpecsRow<ContentType: View>: View {

    let label: String
    let content: () -> ContentType

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label).bold()
            Spacer()
            content()
        }
    }
}

struct ArtistCardView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistCardView(navigationPath: .constant(.init()),
                       artist: MockWebService.artist(with: 287))
    }
}
