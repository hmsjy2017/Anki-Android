import Foundation

#if canImport(AnkiBackendFFI)
import AnkiBackendFFI

public struct CollectionProbeResult: Decodable, Sendable {
    public let ok: Bool
    public let backendVersion: String?
    public let error: String?
}

/// Thin Swift wrapper over the bundled official Ankitects/Anki Rust backend bridge.
public actor OfficialAnkiRustBackend {
    public init() {}

    public func backendVersion() -> String {
        let string = anki_bridge_backend_version()
        defer { anki_bridge_string_free(string) }
        return decodeBridgeString(string)
    }

    public func probeCollection(at url: URL) throws -> CollectionProbeResult {
        let json = url.path.withCString { path in
            let string = anki_bridge_collection_probe(path)
            defer { anki_bridge_string_free(string) }
            return bridgeData(string)
        }
        return try JSONDecoder().decode(CollectionProbeResult.self, from: json)
    }

    private func decodeBridgeString(_ string: AnkiBridgeString) -> String {
        String(data: bridgeData(string), encoding: .utf8) ?? ""
    }

    private func bridgeData(_ string: AnkiBridgeString) -> Data {
        guard let pointer = string.ptr else { return Data() }
        return Data(bytes: pointer, count: string.len)
    }
}
#endif
