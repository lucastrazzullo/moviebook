//
//  WatchlistUndoView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 10/07/2023.
//

import SwiftUI
import MoviebookCommon

struct WatchlistUndoView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @ObservedObject var undoViewModel: WatchlistUndoViewModel

    var body: some View {
        VStack {
            if let removedItem = undoViewModel.removedItem {
                HStack {
                    RemoteImage(
                        url: removedItem.imageUrl,
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(4)
                        },
                        placeholder: {
                            Color.clear
                                .frame(width: 0)
                        }
                    )

                    VStack(alignment: .leading) {
                        Text("Removed")
                        Text("undo")
                            .bold()
                            .foregroundColor(.accentColor)
                    }
                    .font(.caption)
                }
                .onTapGesture {
                    undoViewModel.undo(watchlist: watchlist, removedItem: removedItem)
                }
                .id(removedItem.id)
                .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
        .frame(height: 52)
        .onAppear {
            undoViewModel.start(watchlist: watchlist, requestLoader: requestLoader)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct WatchlistUndoView_Previews: PreviewProvider {
    static let watchlist = MockWatchlistProvider.shared.watchlist()
    static let viewModel = WatchlistUndoViewModel()
    static var previews: some View {
        NavigationView {
            WatchlistUndoView(undoViewModel: viewModel)
                .onAppear {
                    watchlist.remove(itemWith: watchlist.items.first!.id)
                }
        }
        .environment(\.requestLoader, MockRequestLoader.shared)
        .environmentObject(watchlist)
    }
}
#endif
