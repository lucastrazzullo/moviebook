//
//  EmptyWatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/05/2023.
//

import SwiftUI

struct EmptyWatchlistView: View {

    @MainActor
    private final class ViewModel: ObservableObject {

        @Published var results: [MovieDetails] = []

        func start(requestManager: RequestManager) {
            let webService = MovieWebService(requestManager: requestManager)
            Task {
                let response = try await webService.fetchPopular(page: nil)
                self.results = response.results
            }
        }
    }

    @Environment(\.requestManager) var requestManager

    @StateObject private var viewModel: ViewModel = ViewModel()

    var onStartDiscoverySelected: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Your watchlist is empty")
                .font(.title2.bold())
                .foregroundColor(.primary.opacity(0.7))

            ZStack {
                ListView(items: viewModel.results)
                    .allowsHitTesting(false)
                    .mask(LinearGradient(gradient: Gradient(colors: [.gray, .gray.opacity(0)]),
                                         startPoint: .top,
                                         endPoint: .bottom))
            }


            Button(action: onStartDiscoverySelected) {
                HStack {
                    Image(systemName: "rectangle.and.text.magnifyingglass")
                    Text("Start your discovery").bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding(.vertical)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
        .padding()
        .onAppear {
            viewModel.start(requestManager: requestManager)
        }
    }
}

private struct ListView: View {

    let items: [MovieDetails]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem()]) {
                ForEach(items, id: \.self) { movieDetails in
                    AsyncImage(url: movieDetails.media.posterPreviewUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

#if DEBUG
struct EmptyWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyWatchlistView(onStartDiscoverySelected: {})
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: []))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
    }
}
#endif
