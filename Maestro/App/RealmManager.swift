//
//  RealmManager.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 14..
//

import Foundation
import RealmSwift
import Combine

class RealmManager {
    static var shared = RealmManager()
    
    private(set) var application: RealmSwift.App = .init(id: RealmManager.appId)
    private(set) var realm: Realm?
    private      var backupURL: URL { (realm!.configuration.fileURL!.appendingPathExtension("backup")) }
    
    var errorMessage: CurrentValueSubject<String?, Never> = .init(nil)

    private init() {
        setRealm()
    }
    
    private func setRealm() {
        ProcessInfo.isPreview ? realmForPreview() : realmForUser()
        if realm == nil {
            errorMessage.send("Nem sikerült inicializálni az adatbázist!")
        }
        errorMessage.send("Sikerült inicializálni az adatbázist!")
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
////#if DEBUG
//        Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true
//        realm = try! Realm()
//        return
////#else
        guard let user = application.currentUser else { return }
        application.syncManager.errorHandler = syncErrorHandler
        Realm.Configuration.defaultConfiguration = configuration(forUser: user)
        start()
//#endif
    }
    
    private func configuration(forUser user: User) -> Realm.Configuration {
        let clientReset: ClientResetMode = .recoverOrDiscardUnsyncedChanges(beforeReset: beforeClientReset,
                                                                            afterReset: afterClientReset)
        var config = user.flexibleSyncConfiguration(clientResetMode: clientReset,
                                                    initialSubscriptions: syncSubscriptions,
                                                    rerunOnOpen: true)
        config.migrationBlock = migrationBlock
        Realm.Configuration.defaultConfiguration = config
        return config
    }
        
    
    // MARK: - Start/Stop
    
    private func start() {
        if realm != nil { stop() }
        do {
            realm = try Realm()
        } catch let error {
            errorMessage.send("Nem sikerült inicializálni az adatbázist! \(error.localizedDescription)")
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
            errorMessage.send("Nem megfelelő típusú hiba a szinkronizáció hibakezelőjénél!")
            return
        }
        switch syncError.code {
        case .clientResetError:
            if let (_ /* path */, clientResetToken) = syncError.clientResetInfo() {
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
            
        case .invalidFlexibleSyncSubscriptions:
            break
            
        @unknown default:
            errorMessage.send("Ismeretlen szinkronizációs hiba!")
            fatalError("Unknown sync error!")
        }
    }
        
    private func beforeClientReset(before: Realm) {
        // TODO: Éles verziónál mindenképp meg kell oldani
        errorMessage.send("A kliens visszaállítás utáni blokk egyelőre nincs implementálva!")
    }
    
    private func afterClientReset(before: Realm, after: Realm) {
        // TODO: Éles verziónál mindenképp meg kell oldani
        errorMessage.send("A kliens visszaállítás utáni blokk egyelőre nincs implementálva!")
    }
    
    
    // MARK: - Backup
    
    private func backup(realm: Realm? = nil) {
        let realm = realm ?? self.realm
        do {
            try realm?.writeCopy(toFile: backupURL)
        } catch let error {
            errorMessage.send("Nem lehetett biztonsági másolatot készíteni az adatbázisfájlról! \(error.localizedDescription)")
        }
    }
    
    private func deleteBackup() {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: backupURL.path(percentEncoded: false)) else { return }
        do {
            try FileManager.default.removeItem(atPath: backupURL.path(percentEncoded: false))
        } catch {
            errorMessage.send("Nem lehetett törölni a biztonsági másolatot! \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - Migration
    
    func migrationBlock(_ migration: Migration, _ oldSchemaVersion: UInt64) {
        // TODO: Éles verziónál mindenképp meg kell oldani
        errorMessage.send("A migrációs blokk egyelőre nincs implementálva!")
    }
}
