//
//  DiscoverView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@MainActor private final class Content: ObservableObject {

    // MARK: Types

    enum Section: Identifiable, CaseIterable {
        case upcoming
        case popular

        var id: String {
            return self.name
        }

        var name: String {
            switch self {
            case .upcoming:
                return NSLocalizedString("MOVIE.UPCOMING", comment: "")
            case .popular:
                return NSLocalizedString("MOVIE.POPULAR", comment: "")
            }
        }
    }

    // MARK: Instance Properties

    var sections: [Section] {
        return Section.allCases
    }

    @Published var movies: [Section.ID: [MoviePreview]] = [:]

    // MARK: Instance methods

    func refresh(requestManager: RequestManager) async {
        do {
            movies[Section.upcoming.id] = try await UpcomingWebService(requestManager: requestManager).fetch()
            movies[Section.popular.id] = try await PopularWebService(requestManager: requestManager).fetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

struct DiscoverView: View {

    @Environment(\.requestManager) var requestManager
    @StateObject private var content: Content = Content()

    var body: some View {
        List {
            ForEach(content.sections) { section in
                SwiftUI.Section(header: Text(section.name)) {
                    ForEach(content.movies[section.id] ?? []) { movie in
                        Text(movie.title)
                    }
                }
            }
        }
        .task {
            await content.refresh(requestManager: requestManager)
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView().environment(\.requestManager, MockRequestManager())
    }
}
