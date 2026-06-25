import Foundation

enum AppLocations {
    static let appGroupIdentifier = "group.com.screenwritter.shared"

    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var sessionsDirectory: URL {
        documentsDirectory.appendingPathComponent("Sessions", isDirectory: true)
    }

    static var importsDirectory: URL {
        documentsDirectory.appendingPathComponent("Imports", isDirectory: true)
    }

    static var sharedInboxDirectory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("Inbox", isDirectory: true)
    }

    static func prepareLocalDirectories() throws {
        try FileManager.default.createDirectory(at: sessionsDirectory, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: importsDirectory, withIntermediateDirectories: true)
        if let sharedInboxDirectory {
            try FileManager.default.createDirectory(at: sharedInboxDirectory, withIntermediateDirectories: true)
        }
    }
}
