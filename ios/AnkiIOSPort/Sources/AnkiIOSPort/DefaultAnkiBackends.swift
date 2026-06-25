import Foundation

public enum DefaultAnkiBackends {
    public static func collectionBackend() -> any AnkiCollectionBackend {
        #if canImport(AnkiBackendFFI)
        OfficialAnkiRustBackend()
        #else
        OfficialAnkiBackendUnavailable()
        #endif
    }

    public static func syncBackend() -> any AnkiSyncBackend {
        #if canImport(AnkiBackendFFI)
        OfficialAnkiRustBackend()
        #else
        OfficialAnkiBackendUnavailable()
        #endif
    }
}
