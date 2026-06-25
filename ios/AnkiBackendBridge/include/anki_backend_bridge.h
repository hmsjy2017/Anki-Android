#ifndef ANKI_BACKEND_BRIDGE_H
#define ANKI_BACKEND_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct AnkiBridgeString {
    const char *ptr;
    uintptr_t len;
} AnkiBridgeString;

/// Returns the upstream Ankitects/Anki Rust backend version compiled into the bridge.
AnkiBridgeString anki_bridge_backend_version(void);

/// Opens or creates an Anki collection with the official Rust CollectionBuilder, then closes it.
/// Returns an owned UTF-8 JSON result string. Call anki_bridge_string_free() when done.
AnkiBridgeString anki_bridge_collection_probe(const char *collection_path);

/// Frees strings returned by this bridge.
void anki_bridge_string_free(AnkiBridgeString string);

#ifdef __cplusplus
}
#endif

#endif
