local shared = odh_shared_plugins

if not shared then return end

if plugin_on_startup then
    shared.plugin_mark_as_verified = "AES_STARLIGHT_256_683"
    return
end

shared.is_premium_user = true
shared.is_exclusive_user = true