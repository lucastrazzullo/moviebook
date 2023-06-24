//
//  NewToWatchSuggestionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/12/2022.
//

import SwiftUI
import MoviebookCommon

struct NewToWatchSuggestionView: View {

    enum Field {
        case author
        case comment
    }

    enum FieldError: Hashable {
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

        init?(text: String, checking: Set<Self>) {
            for check in checking {
                switch check {
                case .empty:
                    if text.isEmpty {
                        self = check
                        return
                    }
                case .characterLimit(let limit):
                    if text.count > limit {
                        self = check
                        return
                    }
                }
            }

            return nil
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

    @FocusState private var focusedField: Field?

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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 44) {
                if let title {
                    VStack {
                        Text("Why do you want to watch")
                        Text(title).bold()
                    }
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .frame(maxWidth: 300)
                }

                VStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        TextField("Suggested by (required)", text: $suggestedByText)
                            .textFieldStyle(OvalTextFieldStyle())
                            .focused($focusedField, equals: .author)
                            .textContentType(.givenName)
                            .onSubmit { focusedField = nil }
                            .submitLabel(.done)

                        if let error = suggestedByError {
                            Text(error.description)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 22)
                        }
                    }

                    VStack(alignment: .leading) {
                        TextField("Comment", text: $commentText, axis: .vertical)
                            .textFieldStyle(OvalTextFieldStyle())
                            .focused($focusedField, equals: .comment)
                            .lineLimit(10, reservesSpace: true)
                            .onSubmit { focusedField = nil }
                            .submitLabel(.done)

                        if let error = commentError {
                            Text(error.description)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 22)
                        }
                    }
                }
            }
            .padding(.top)
            .padding()
            .foregroundColor(nil)
            .font(.body)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 24) {
                Button(action: save) {
                    Text("Save")
                }
                .buttonStyle(OvalButtonStyle())

                Button(action: dismiss) {
                    Text("Cancel")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
        }
        .onAppear {
            if let toWatchSuggestion = toWatchInfo?.suggestion {
                suggestedByText = toWatchSuggestion.owner
                commentText = toWatchSuggestion.comment ?? ""
            }
        }
        .task {
            switch itemIdentifier {
            case .movie(let id):
                let webService = WebService.movieWebService(requestManager: requestManager)
                let movie = try? await webService.fetchMovie(with: id)
                title = movie?.details.title
            }
        }
    }

    private func save() {
        suggestedByError = FieldError(text: suggestedByText, checking: [.empty, .characterLimit(limit: 20)])
        commentError = FieldError(text: commentText, checking: [.characterLimit(limit: 300)])

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

struct NewToWatchSuggestionView_Previews: PreviewProvider {
    static var previews: some View {
        NewToWatchSuggestionView(itemIdentifier: .movie(id: 954))
            .environmentObject(Watchlist(items: []))
    }
}
