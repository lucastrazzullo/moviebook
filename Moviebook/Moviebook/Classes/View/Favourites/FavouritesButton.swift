//
//  FavouritesButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/08/2023.
//

import SwiftUI
import MoviebookCommon

struct FavouritesButton<LabelType>: View where LabelType: View  {

    typealias LabelBuilder = (_ state: FavouriteItemState?) -> LabelType

    @EnvironmentObject var favourites: Favourites

    let favouriteItemIdentifier: FavouriteItemIdentifier

    @ViewBuilder let label: LabelBuilder

    var body: some View {
        Button(action: {
            switch favourites.itemState(id: favouriteItemIdentifier) {
            case .pinned:
                favourites.remove(itemWith: favouriteItemIdentifier)
            case .none:
                favourites.update(state: .pinned, forItemWith: favouriteItemIdentifier)
            }
        }) {
            label(favourites.itemState(id: favouriteItemIdentifier))
        }
    }
}

// MARK: - Common Views

enum FavouritesViewState {
    case pinned, none

    init(itemState: FavouriteItemState?) {
        guard let itemState else {
            self = .none
            return
        }
        switch itemState {
        case .pinned:
            self = .pinned
        }
    }

    var icon: String {
        switch self {
        case .pinned:
            return "star.fill"
        case .none:
            return "star"
        }
    }

    var label: String {
        switch self {
        case .pinned:
            return "Favourited"
        case .none:
            return "Favourite"
        }
    }
}

struct FavouritesIcon: View {

    let itemState: FavouriteItemState?

    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: FavouritesViewState(itemState: itemState).icon)
        }
    }

    init(itemState: FavouriteItemState?) {
        self.itemState = itemState
    }
}

struct FavouritesLabel: View {

    let itemState: FavouriteItemState?

    var body: some View {
        HStack {
            FavouritesIcon(itemState: itemState)
            Text(FavouritesViewState(itemState: itemState).label)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    init(itemState: FavouriteItemState?) {
        self.itemState = itemState
    }
}

// MARK: - Common Buttons

struct IconFavouritesButton: View {

    let favouriteItemIdentifier: FavouriteItemIdentifier

    var body: some View {
        FavouritesButton(
            favouriteItemIdentifier: favouriteItemIdentifier,
            label: { state in
                FavouritesIcon(itemState: state)
                    .frame(width: 18, height: 18, alignment: .center)
                    .ovalStyle(.normal)
            }
        )
    }
}

#if DEBUG
import MoviebookTestSupport

struct FavouritesButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 44) {
            IconFavouritesButton(favouriteItemIdentifier: .artist(id: 287))
                .environmentObject(MockFavouritesProvider.shared.favourites(empty: true))

            IconFavouritesButton(favouriteItemIdentifier: .artist(id: 287))
                .environmentObject(MockFavouritesProvider.shared.favourites())
        }
        .padding(44)
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}
#endif
