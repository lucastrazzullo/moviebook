//
//  WatchlistAddToWatchView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/12/2022.
//

import SwiftUI

struct WatchlistAddToWatchView: View {

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

    @EnvironmentObject var watchlist: Watchlist

    @State private var suggestedByText: String = ""
    @State private var suggestedByError: FieldError?
    @State private var commentText: String = ""
    @State private var commentError: FieldError?

    let item: WatchlistContent.Item

    private var toWatchReason: Watchlist.ToWatchReason {
        let state = watchlist.itemState(item: item)
        switch state {
        case .none:
            return .none
        case .toWatch(let reason):
            return reason
        case .watched(let reason, _):
            return reason
        }
    }

    var body: some View {
        VStack {
            Text("Add to watchlist")
                .font(.title)

            Form {
                Section("Reason") {
                    VStack(alignment: .leading) {
                        TextField("Suggested by", text: $suggestedByText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(addToWatch)

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
                            .onSubmit(addToWatch)

                        if let error = commentError {
                            Text(error.description)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Button(action: addToWatch) {
                        Text("Save")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .listRowSeparator(.hidden)

                Section {
                    Divider()

                    Button(action: { addToWatch(with: .none) }) {
                        Text("Add with no info")
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
        }
        .padding(.top)
        .foregroundColor(nil)
        .font(.body)
        .onAppear {
            switch toWatchReason {
            case .suggestion(let from, let comment):
                suggestedByText = from
                commentText = comment
            case .none:
                break
            }
        }
    }

    private func addToWatch() {
        suggestedByError = FieldError(text: suggestedByText)
        commentError = FieldError(text: commentText)

        guard suggestedByError == nil, commentError == nil else {
            return
        }

        addToWatch(with: .suggestion(from: suggestedByText, comment: commentText))
    }

    private func addToWatch(with reason: Watchlist.ToWatchReason) {
        watchlist.update(state: .toWatch(reason: reason), for: item)
        presentationMode.wrappedValue.dismiss()
    }
}

#if DEBUG
struct WatchlistAddToWatchView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistAddToWatchView(item: .movie(id: 954))
            .environmentObject(Watchlist(items: [:]))
    }
}
#endif
