use anki::collection::CollectionBuilder;
use anki::version;
use libc::c_char;
use serde_json::json;
use std::ffi::{CStr, CString};
use std::path::PathBuf;

#[repr(C)]
pub struct AnkiBridgeString {
    ptr: *const c_char,
    len: usize,
}

fn owned_string(value: String) -> AnkiBridgeString {
    let c_string = CString::new(value).unwrap_or_else(|_| CString::new("{\"ok\":false,\"error\":\"interior nul byte\"}").unwrap());
    let len = c_string.as_bytes().len();
    let ptr = c_string.into_raw();
    AnkiBridgeString { ptr, len }
}

#[no_mangle]
pub extern "C" fn anki_bridge_backend_version() -> AnkiBridgeString {
    owned_string(version::version().to_owned())
}

#[no_mangle]
pub unsafe extern "C" fn anki_bridge_collection_probe(collection_path: *const c_char) -> AnkiBridgeString {
    if collection_path.is_null() {
        return owned_string(json!({ "ok": false, "error": "collection_path is null" }).to_string());
    }

    let path = match CStr::from_ptr(collection_path).to_str() {
        Ok(path) => PathBuf::from(path),
        Err(error) => {
            return owned_string(json!({ "ok": false, "error": error.to_string() }).to_string());
        }
    };

    let result = CollectionBuilder::new(path)
        .build()
        .and_then(|collection| collection.close(None));

    match result {
        Ok(()) => owned_string(json!({ "ok": true, "backendVersion": version::version() }).to_string()),
        Err(error) => owned_string(json!({ "ok": false, "error": error.to_string() }).to_string()),
    }
}

#[no_mangle]
pub unsafe extern "C" fn anki_bridge_string_free(string: AnkiBridgeString) {
    if !string.ptr.is_null() {
        drop(CString::from_raw(string.ptr as *mut c_char));
    }
}
