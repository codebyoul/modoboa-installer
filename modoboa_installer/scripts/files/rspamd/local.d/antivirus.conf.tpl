# Rspamd ClamAV antivirus configuration
# Based on mailcow defaults with adjustments for Modoboa
# Installed by modoboa-installer

clamav {
    # Scan whole message (not just MIME parts)
    scan_mime_parts = false;

    # Symbol to add when virus detected
    symbol = "CLAM_VIRUS";

    # Scanner type
    type = "clamav";

    # Log clean messages too (useful for debugging)
    log_clean = true;

    # ClamAV socket (Modoboa uses Unix socket on Debian)
    servers = "/var/run/clamav/clamd.ctl";

    # Maximum message size to scan (20MB)
    max_size = 20971520;

    # Action when virus detected: reject the message
    action = "reject";

    # Patterns for specific virus signatures
    patterns {
        JUST_EICAR = "Test.EICAR";
    }
}
