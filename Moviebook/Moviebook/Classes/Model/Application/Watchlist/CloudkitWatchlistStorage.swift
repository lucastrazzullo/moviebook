//
//  CloudkitWatchlistStorage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 01/05/2023.
//

import Foundation
import CloudKit

final class CloudkitWatchlistStorage {

    indirect enum Error: Swift.Error {
        case databaseMissing
        case zoneFetching(_ zone: Zone)
        case zoneCreation(_ zone: Zone)
        case movieRecordsFetching(underlyingError: Error?)
        case movieRecordsSaving(underlyingError: Error?)
        case movieRecordsDeleting(underlyingError: Error?)
    }

    enum Zone: String {
        case watchlist
    }


    // MARK: Instsance properties

    private let zone: Zone
    private var container: CKContainer {
        return CKContainer.default()
    }

    private var database: CKDatabase {
        return container.privateCloudDatabase
    }


    // MARK: Object life cycle

    init(zone: Zone = .watchlist) {
        self.zone = zone
        self.subscribeToUpdates()
    }


    // MARK: - Public methods

//    func fetchMovies() -> AnyPublisher<[MoviePreview], AsyncronusWatchlistRepositoryError> {
//        return fetchZoneOrCreateIfNeeded(zone)
//            .flatMap(fetchMovieRecords(inZoneWith:))
//            .tryMap { records in try records.map( CloudKitMoviePreview.init(record:)) }
//            .mapError(CloudKitError.movieRecordsFetching(underlyingError:))
//            .mapError(AsyncronusWatchlistRepositoryError.underlying(error:))
//            .eraseToAnyPublisher()
//    }
//
//
//    func add(movie: MoviePreview) -> AnyPublisher<Bool, AsyncronusWatchlistRepositoryError> {
//        return fetchZoneOrCreateIfNeeded(zone)
//            .map { zoneId in
//                CloudKitMoviePreview(with: movie).makeRecord(zoneId: zoneId)
//            }
//            .flatMap(append(movieRecord:))
//            .mapError(AsyncronusWatchlistRepositoryError.underlying(error:))
//            .eraseToAnyPublisher()
//    }
//
//
//    func save(movies: [MoviePreview]) -> AnyPublisher<Bool, AsyncronusWatchlistRepositoryError> {
//        return fetchZoneOrCreateIfNeeded(zone)
//            .map { zoneId in
//                movies
//                   .map(CloudKitMoviePreview.init(with:))
//                   .map{ $0.makeRecord(zoneId: zoneId) }
//            }
//            .flatMap(save(movieRecords:))
//            .mapError(AsyncronusWatchlistRepositoryError.underlying(error:))
//            .eraseToAnyPublisher()
//    }
//
//
//    func delete(movie: MoviePreview) -> AnyPublisher<Bool, AsyncronusWatchlistRepositoryError> {
//        return fetchZoneOrCreateIfNeeded(zone)
//            .map { zoneId in
//                CloudKitMoviePreview(with: movie).makeRecord(zoneId: zoneId)
//            }
//            .flatMap(delete(movieRecord:))
//            .mapError(AsyncronusWatchlistRepositoryError.underlying(error:))
//            .eraseToAnyPublisher()
//    }
//
//
//    func deleteAllMovies() -> AnyPublisher<Bool, AsyncronusWatchlistRepositoryError> {
//        return fetchZoneOrCreateIfNeeded(zone)
//            .flatMap(deleteAllMovies(inZoneWith:))
//            .mapError(AsyncronusWatchlistRepositoryError.underlying(error:))
//            .eraseToAnyPublisher()
//    }


    // MARK: - Private helper methods

    private func subscribeToUpdates() {
        let subscription = CKDatabaseSubscription.init(subscriptionID: "\(zone)-updates")

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo

        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.qualityOfService = .utility
        database.add(operation)
    }


    // MARK: - Fetch

//    private func fetchMovieRecords(inZoneWith id: CKRecordZone.ID) -> AnyPublisher<[CKRecord], CloudKitError> {
//        let predicate = NSPredicate(value: true)
//        let query = CKQuery(recordType: CloudKitMoviePreview.RecordType.moviePreview, predicate: predicate)
//        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
//
//        return Future<[CKRecord], CloudKitError> { [weak self] promise in
//            guard let database = self?.database else {
//                promise(.failure(CloudKitError.databaseMissing))
//                return
//            }
//
//            database.perform(query, inZoneWith: id, completionHandler: { records, error in
//                guard let records = records else {
//                    promise(.failure(CloudKitError.movieRecordsFetching(underlyingError: error)))
//                    return
//                }
//                promise(.success(records))
//            })
//        }
//        .mapError(CloudKitError.movieRecordsFetching(underlyingError:))
//        .eraseToAnyPublisher()
//    }


    // MARK: - Save

//    private func append(movieRecord: CKRecord) -> AnyPublisher<Bool, CloudKitError> {
//        return Future<Bool, CloudKitError> { [weak self] promise in
//            guard let database = self?.database else {
//                promise(.failure(CloudKitError.databaseMissing))
//                return
//            }
//
//            database.save(movieRecord) { record, error in
//                guard record != nil else {
//                    promise(.failure(CloudKitError.movieRecordsSaving(underlyingError: error)))
//                    return
//                }
//                promise(.success(true))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//
//    private func save(movieRecords: [CKRecord]) -> AnyPublisher<Bool, CloudKitError> {
//        return Future<Bool, CloudKitError> { [weak self] promise in
//            guard let database = self?.database else {
//                promise(.failure(CloudKitError.databaseMissing))
//                return
//            }
//
//            let operation = CKModifyRecordsOperation(recordsToSave: movieRecords, recordIDsToDelete: nil)
//            operation.savePolicy = CKModifyRecordsOperation.RecordSavePolicy.changedKeys
//            operation.qualityOfService = QualityOfService.userInitiated
//            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
//                guard savedRecords?.count == movieRecords.count else {
//                    promise(.failure(CloudKitError.movieRecordsSaving(underlyingError: error)))
//                    return
//                }
//                promise(.success(true))
//            }
//
//            database.add(operation)
//        }
//        .eraseToAnyPublisher()
//    }


    // MARK: - Delete

//    private func deleteAllMovies(inZoneWith id: CKRecordZone.ID) -> AnyPublisher<Bool, CloudKitError> {
//        return fetchMovieRecords(inZoneWith: id)
//            .flatMap(delete(movieRecords:))
//            .eraseToAnyPublisher()
//    }
//
//
//    private func delete(movieRecord: CKRecord) -> AnyPublisher<Bool, CloudKitError> {
//        return Future<Bool, CloudKitError> { [weak self] promise in
//            guard let database = self?.database else {
//                promise(.failure(CloudKitError.databaseMissing))
//                return
//            }
//
//            database.delete(withRecordID: movieRecord.recordID) { record, error in
//                guard record != nil else {
//                    promise(.failure(CloudKitError.movieRecordsDeleting(underlyingError: error)))
//                    return
//                }
//                promise(.success(true))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//
//    private func delete(movieRecords: [CKRecord]) -> AnyPublisher<Bool, CloudKitError> {
//        let recordIds = movieRecords.map(\.recordID)
//        return Future<Bool, CloudKitError> { [weak self] promise in
//            guard let database = self?.database else {
//                promise(.failure(CloudKitError.databaseMissing))
//                return
//            }
//
//            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIds)
//            operation.qualityOfService = QualityOfService.userInitiated
//            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
//                guard deletedRecordIDs?.count == movieRecords.count else {
//                    promise(.failure(CloudKitError.movieRecordsDeleting(underlyingError: error)))
//                    return
//                }
//                promise(.success(true))
//            }
//
//            database.add(operation)
//        }
//        .eraseToAnyPublisher()
//    }


    // MARK: - Zone

    private func fetchZoneOrCreateIfNeeded(_ zone: Zone) async throws -> CKRecordZone.ID {
        do {
            return try await fetchZoneID(for: zone)
        } catch {
            return try await createZoneID(for: zone)
        }
    }


    private func fetchZoneID(for zone: Zone) async throws -> CKRecordZone.ID {
        let zones = try await database.allRecordZones()
        let recordZoneIdComparison = CKRecordZone.ID(zoneName: zone.rawValue, ownerName: CKCurrentUserDefaultName)
        guard let recordZone = zones.first(where: { $0.zoneID == recordZoneIdComparison }) else {
            throw Error.zoneFetching(zone)
        }

        return recordZone.zoneID
    }

    private func createZoneID(for zone: Zone) async throws -> CKRecordZone.ID {
        let recordZoneID = CKRecordZone.ID(zoneName: zone.rawValue, ownerName: CKCurrentUserDefaultName)
        let customZone = CKRecordZone(zoneID: recordZoneID)

        let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [])
        createZoneOperation.qualityOfService = .userInitiated

        return try await withCheckedThrowingContinuation { continuation in
            createZoneOperation.modifyRecordZonesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: recordZoneID)
                case .failure:
                    continuation.resume(throwing: Error.zoneCreation(zone))
                }
            }

            database.add(createZoneOperation)
        }
    }
}

//extension CloudkitWatchlistStorage: WatchlistStorage {
//
//    func save(content: WatchlistContent) async {
//
//    }
//
//    func load() -> WatchlistContent {
//        let content = WatchlistContent(items: [:])
//        return content
//    }
//}
