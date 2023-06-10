//
//  LegacyWatchlistStorage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/05/2023.
//

import Foundation
import CloudKit
import Combine
import MoviebookCommons

actor LegacyWatchlistStorage {

    indirect enum Error: Swift.Error {
        case zoneFetching(_ zone: String)
    }

    // MARK: Instsance properties

    private let zone: String
    private var zoneIDs: [String: CKRecordZone.ID]

    private var container: CKContainer {
        return CKContainer.default()
    }

    private var database: CKDatabase {
        return container.privateCloudDatabase
    }

    // MARK: Object life cycle

    init() {
        self.zone = "watchlist"
        self.zoneIDs = [:]
    }


    // MARK: - Internal methods

    func fetchWatchlistItems() async throws -> [WatchlistItem] {
        let zone = try await fetchZoneID(for: zone)
        let movieRecords = try await fetchMovieRecords(inZoneWith: zone)
        return movieRecords.enumerated()
            .compactMap { index, record -> WatchlistItem? in
                guard let rawMovieId = record.object(forKey: "id") as? Int else {
                    return nil
                }

                let id = WatchlistItemIdentifier.movie(id: Movie.ID(rawMovieId))
                let date = Date.now.addingTimeInterval(TimeInterval(index))
                let info = WatchlistItemToWatchInfo(date: date, suggestion: nil)
                return WatchlistItem(id: id, state: .toWatch(info: info))
            }
    }

    func deleteAllMovies() async throws {
        let zone = try await fetchZoneID(for: zone)
        let movieRecords = try await fetchMovieRecords(inZoneWith: zone)
        try await delete(movieRecords: movieRecords)
    }

    // MARK: - Private helper methods

    private func fetchMovieRecords(inZoneWith id: CKRecordZone.ID) async throws -> [CKRecord] {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "MoviePreview", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        return try await withCheckedThrowingContinuation { continuation in
            database.fetch(withQuery: query, inZoneWith: id) { result in
                switch result {
                case .success(let content):
                    let records = content.matchResults.compactMap { result in
                        switch result.1 {
                        case .success(let record):
                            return record
                        case .failure:
                            return nil
                        }
                    }
                    continuation.resume(returning: records)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func delete(movieRecords: [CKRecord]) async throws {
        let recordIds = movieRecords.map(\.recordID)
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIds)
        operation.qualityOfService = QualityOfService.userInitiated

        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            database.add(operation)
        }
    }

    private func fetchZoneID(for zone: String) async throws -> CKRecordZone.ID {
        return try await withCheckedThrowingContinuation { continuation in
            database.fetchAllRecordZones { zones, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let recordZoneIdComparison = CKRecordZone.ID(zoneName: zone, ownerName: CKCurrentUserDefaultName)
                    if let recordZone = zones?.first(where: { $0.zoneID == recordZoneIdComparison }) {
                        continuation.resume(returning: recordZone.zoneID)
                    } else {
                        continuation.resume(throwing: Error.zoneFetching(zone))
                    }
                }
            }
        }
    }
}

