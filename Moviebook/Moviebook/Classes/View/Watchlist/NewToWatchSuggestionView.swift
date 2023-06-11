//
//  NewToWatchSuggestionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/12/2022.
//

import SwiftUI
import MoviebookCommons

struct NewToWatchSuggestionView: View {

    enum FieldError {
        case empty
        case characterLimit(limit: Int)

        var description: String {
            switch self {
            case .empty:
                return "Please fill this field"
            case .characterLimit(let limit):
                return "You reached the character limit of \(limit)"
            }
        }

        init?(text: String) {
            if text.isEmpty {
                self = .empty
            } else if text.count > 300 {
                self = .characterLimit(limit: 300)
            } else {
                return nil
            }
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.requestManager) var requestManager

    @EnvironmentObject var watchlist: Watchlist

    @State private var title: String?
    @State private var suggestedByText: String = ""
    @State private var suggestedByError: FieldError?
    @State private var commentText: String = ""
    @State private var commentError: FieldError?

    let itemIdentifier: WatchlistItemIdentifier

    private var toWatchInfo: WatchlistItemToWatchInfo? {
        guard let state = watchlist.itemState(id: itemIdentifier) else {
            return nil
        }
        switch state {
        case .toWatch(let info):
            return info
        case .watched(let info):
            return info.toWatchInfo
        }
    }

    var body: some View {
        VStack {
            VStack {
                Text("Why do you want to watch")
                if let title {
                    Text(title).bold()
                }
            }
            .font(.title)

            Form {
                VStack(alignment: .leading) {
                    TextField("Suggested by", text: $suggestedByText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(save)

                    if let error = suggestedByError {
                        Text(error.description)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading) {
                    TextField("Comment", text: $commentText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(10, reservesSpace: true)
                        .onSubmit(save)

                    if let error = commentError {
                        Text(error.description)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)

            VStack(spacing: 24) {
                Button(action: save) {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: dismiss) {
                    Text("Cancel")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top)
        .padding()
        .foregroundColor(nil)
        .font(.body)
        .onAppear {
            if let toWatchSuggestion = toWatchInfo?.suggestion {
                suggestedByText = toWatchSuggestion.owner
                commentText = toWatchSuggestion.comment
            }
        }
        .task {
            switch itemIdentifier {
            case .movie(let id):
                let webService = MovieWebService(requestManager: requestManager)
                let movie = try? await webService.fetchMovie(with: id)
                title = movie?.details.title
            }
        }
    }

    private func save() {
        suggestedByError = FieldError(text: suggestedByText)
        commentError = FieldError(text: commentText)

        guard suggestedByError == nil, commentError == nil else {
            return
        }

        guard var toWatchInfo else {
            return
        }

        toWatchInfo.suggestion = WatchlistItemToWatchInfo.Suggestion(owner: suggestedByText, comment: commentText)
        watchlist.update(state: .toWatch(info: toWatchInfo), forItemWith: itemIdentifier)
        dismiss()
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

#if DEBUG
struct NewToWatchSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        NewToWatchSuggestionView(itemIdentifier: .movie(id: 954))
            .environmentObject(Watchlist(items: []))
    }
}
#endif
