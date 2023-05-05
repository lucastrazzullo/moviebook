//
//  Storage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/05/2023.
//

import Foundation
import CoreData

actor Storage {

    private let persistentContainer: NSPersistentContainer

    init() {
        persistentContainer = NSPersistentContainer(name: "Moviebook")
    }

    func load() async throws {
        try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
            persistentContainer.loadPersistentStores(completionHandler: { description, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}
