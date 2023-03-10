//
//  AppEnvironmentValues.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 14..
//

import Foundation
import RealmSwift

class RealmManager {
    static var shared = RealmManager()
    
    private(set) var application: RealmSwift.App = .init(id: RealmManager.appId)
    private(set) var realm: Realm?
    private      var backupURL: URL { (realm!.configuration.fileURL!.appendingPathExtension("backup")) }
    
    private init() {
        setRealm()
    }
    
    private func setRealm() {
        ProcessInfo.isPreview ? realmForPreview() : realmForUser()
        if realm == nil {
            print("no realm")
        }
    }
    
    
    // MARK: - Setting for preview
    
    private func realmForPreview() {
        Realm.Configuration.defaultConfiguration = Realm.Configuration(inMemoryIdentifier: "previewRealm")
        start()
        do {
            guard let realmObjects = realm?.objects(Publication.self) else { fatalError("Can't retrieve item data!") }
            if realmObjects.isEmpty {
                try realm?.write {
                    realm?.add([Publication.publication1, Publication.publication2, Publication.publication3])
                }
            }
        } catch let error {
            fatalError("Can't bootstrap item data: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - Setting for user
    
    private func realmForUser() {
        guard let user = application.currentUser else { return }
        application.syncManager.errorHandler = syncErrorHandler
        Realm.Configuration.defaultConfiguration = configuration(forUser: user)
        start()
    }
    
    private func configuration(forUser user: User) -> Realm.Configuration {
        let clientReset: ClientResetMode = .recoverOrDiscardUnsyncedChanges(beforeReset: beforeClientReset,
                                                                            afterReset: afterClientReset)
        var config = user.flexibleSyncConfiguration(clientResetMode: clientReset,
                                                    initialSubscriptions: syncSubscriptions,
                                                    rerunOnOpen: true)
#if DEBUG
        // config.deleteRealmIfMigrationNeeded = true
#else
        config.migrationBlock = migrationBlock
#endif
        Realm.Configuration.defaultConfiguration = config
        return config
    }
        
    
    // MARK: - Start/Stop
    
    private func start() {
        if realm != nil { stop() }
        do {
            realm = try Realm()
        } catch let error {
            print(error)
            try? FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
            realm = try! Realm()
        }
    }
    
    private func stop() {
        realm?.invalidate()
        realm = nil
    }
    
    
    // MARK: - Sync
    
    private func syncSubscriptions(subs: SyncSubscriptionSet) {
        guard subs.first(named: "all_publications") == nil else { return }
        subs.append(QuerySubscription<Publication>(name: "all_publications"))
    }
    
    private func syncErrorHandler(error: Error, session: SyncSession?) {
        guard let syncError = error as? SyncError else {
            fatalError("Unexpected error type passed to sync error handler! \(error)")
        }
        switch syncError.code {
        case .clientResetError:
            if let (path, clientResetToken) = syncError.clientResetInfo() {
                backup()
                stop()
                SyncSession.immediatelyHandleError(clientResetToken, syncManager: application.syncManager)
                // showAlertforAppRelaunch()
            }
            
        case .clientInternalError:
            break
            
        case .clientSessionError:
            break
            
        case .clientUserError:
            break
            
        case .underlyingAuthError:
            break
            
        case .permissionDeniedError:
            break
            
        case .writeRejected:
            break
            
        @unknown default:
            fatalError("Unknown sync error!")
        }
    }
    
    
    // MARK: - Backup
    
    private func backup() {
        do {
            try realm?.writeCopy(toFile: backupURL)
        } catch {
            print("Error backing up data")
        }
    }
    
    
    // MARK: - Client reset
    
    private func beforeClientReset(before: Realm) {
        print("BEFORE CLIENT RESET CALLED")
        var recoveryConfig = Realm.Configuration()
        recoveryConfig.fileURL = backupURL
        do {
            print("Trying create backup to path: \(String(describing: recoveryConfig.fileURL))")
            try before.writeCopy(configuration: recoveryConfig)
        } catch {
            // handle error
        }
    }
    
    private func afterClientReset(before: Realm, after: Realm) {
        print("AFTER CLIENT RESET CALLED")
    }
    
    
    // MARK: - Migration
    
    var migrationBlock: MigrationBlock = { migration, oldSchemaVersion in
        print("MIGRATION BLOCK CALLED")
    }
}
