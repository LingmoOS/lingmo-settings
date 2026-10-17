# Shared by fingerprint-pam and face-pam (sourced, not run): adding and removing
# our own tagged lines in /etc/pam.d, safely.
#
# Every line we add ends with "# <tag>" (lingmo-fingerprint, lingmo-face), and
# "disable" removes exactly those lines. Before a file is changed a copy is kept
# in /var/lib/lingmo-settings/<helper>/backup (<service>.orig is the copy taken
# the first time, <service>.last the one taken before the latest change); files
# are replaced atomically with their owner and mode kept; symbolic links, files
# without an auth stack and files larger than 64 KiB are left alone.
#
# A service that only exists in /usr/lib/pam.d (polkit-1 on Arch) is copied to
# /etc/pam.d first, since that copy wins. The copy carries a "# lingmo-pam-copy"
# line, and the helper that removes the last tagged line from it deletes it
# again when nothing else changed, even after a package update changed the
# vendor file (the copied vendor file is kept in /var/lib/lingmo-settings/pam-copies).
#
# Before sourcing, the helper sets:
#   TAG_NAME     lingmo-fingerprint or lingmo-face
#   STATE_NAME   directory under /var/lib/lingmo-settings for the backups
#   FOREIGN_RE   extended regex of an auth line someone else added for the same
#                purpose (such a file is left alone)
#   SKIP_RE      extended regex of lines ours goes below (may be empty)
# and defines pam_line <service>, the line to add.
#
# Tests: LINGMO_FINGERPRINT_ROOT=<dir> makes the helpers use <dir>/etc/pam.d,
# <dir>/usr/lib/pam.d, <dir>/usr/lib/security, ... instead of the real system.
# It is refused when running as root.

set -u
umask 022
export LC_ALL=C
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

readonly PROG=${0##*/}
readonly TAG="# $TAG_NAME"
# Lines we own: a "# <tag>" comment, at the end of a line or as a line of its
# own (optionally followed by ":" and text).
readonly TAG_RE="#[[:space:]]*${TAG_NAME}([[:space:]:]|$)"
# Lines any of the Lingmo helpers owns
readonly ANY_TAG_RE='#[[:space:]]*lingmo-(fingerprint|face)([[:space:]:]|$)'
readonly COPY_TAG='# lingmo-pam-copy'
readonly COPY_RE='^#[[:space:]]*lingmo-pam-copy([[:space:]:]|$)'

die() {
    echo "$PROG: $*" >&2
    exit 2
}

warn() {
    echo "$PROG: $*" >&2
}

ROOT=""
if [ -n "${LINGMO_FINGERPRINT_ROOT:-}" ]; then
    [ "$(id -u)" -eq 0 ] && die "LINGMO_FINGERPRINT_ROOT is only for tests and is refused as root"
    ROOT=${LINGMO_FINGERPRINT_ROOT%/}
    [ -d "$ROOT" ] || die "$ROOT is not a directory"
fi

readonly PAM_DIR="$ROOT/etc/pam.d"
readonly VENDOR_DIR="$ROOT/usr/lib/pam.d"
readonly SETTINGS_STATE="$ROOT/var/lib/lingmo-settings"
readonly STATE_DIR="$SETTINGS_STATE/$STATE_NAME"
readonly BACKUP_DIR="$STATE_DIR/backup"
readonly COPIES_DIR="$SETTINGS_STATE/pam-copies"
readonly MODULE_DIRS=(
    "$ROOT/usr/lib/security"
    "$ROOT/usr/lib64/security"
    "$ROOT/lib/security"
    "$ROOT/usr/lib/x86_64-linux-gnu/security"
    "$ROOT/lib/x86_64-linux-gnu/security"
)

TMP_FILES=()
cleanup() {
    local f
    for f in "${TMP_FILES[@]}"; do
        [ -n "$f" ] && rm -f -- "$f"
    done
}
trap cleanup EXIT

# have_module pam_fprintd.so
have_module() {
    local d
    for d in "${MODULE_DIRS[@]}"; do
        [ -f "$d/$1" ] && return 0
    done
    return 1
}

has_tag() {
    grep -Eq -- "$TAG_RE" "$1"
}

# An auth line for the same purpose that someone else added (not tagged by us).
has_foreign() {
    grep -v -E -- "$TAG_RE" "$1" |
        grep -E '^[[:space:]]*-?[Aa][Uu][Tt][Hh][[:space:]]' |
        grep -Eq -- "$FOREIGN_RE"
}

has_auth_line() {
    grep -Eiq '^[[:space:]]*-?auth[[:space:]]' "$1"
}

strip_tagged() {
    grep -v -E -- "$TAG_RE" "$1"
    return 0
}

# Print $1 with our line inserted before the first auth line, but below the
# lines matching SKIP_RE (another helper's lines that must come first).
insert_line() {
    awk -v line="$(pam_line "$2")" -v skip="$SKIP_RE" '
        !done && tolower($0) ~ /^[ \t]*-?auth[ \t]/ && !(skip != "" && $0 ~ skip) { print line; done = 1 }
        { print }
        END { if (!done) exit 3 }
    ' "$1"
}

# Check that $1 is a PAM file we are willing to touch.
check_file() {
    local f=$1
    if [ -L "$f" ]; then
        warn "$f is a symbolic link, leaving it alone"
        return 1
    fi
    if [ ! -f "$f" ]; then
        warn "$f is not a regular file"
        return 1
    fi
    if [ ! -r "$f" ]; then
        warn "$f can't be read"
        return 1
    fi
    if [ "$(stat -c %s -- "$f")" -gt 65536 ]; then
        warn "$f is unexpectedly large, leaving it alone"
        return 1
    fi
    return 0
}

make_state_dir() {
    mkdir -p -- "$1" || return 1
    chmod 700 -- "$SETTINGS_STATE/$STATE_NAME" "$1" 2>/dev/null
    return 0
}

backup() {
    local svc=$1 f=$2
    make_state_dir "$BACKUP_DIR" || return 1
    if [ ! -e "$BACKUP_DIR/$svc.orig" ]; then
        cp -p -- "$f" "$BACKUP_DIR/$svc.orig" || return 1
    fi
    cp -p -- "$f" "$BACKUP_DIR/$svc.last" || return 1
}

# Atomically replace $1 with the content of $2, keeping owner and mode of
# $3 (the file being replaced, or the vendor file it is copied from).
replace_file() {
    local target=$1 content=$2 ref=$3 tmp
    tmp=$(mktemp -- "$PAM_DIR/.${target##*/}.lingmo.XXXXXX") || return 1
    TMP_FILES+=("$tmp")
    cat -- "$content" >"$tmp" || return 1
    chmod --reference="$ref" -- "$tmp" 2>/dev/null || chmod 644 -- "$tmp"
    chown --reference="$ref" -- "$tmp" 2>/dev/null
    sync -- "$tmp" 2>/dev/null
    mv -f -- "$tmp" "$target" || return 1
}

new_tmp() {
    local t
    t=$(mktemp) || die "can't create a temporary file"
    TMP_FILES+=("$t")
    echo "$t"
}

# Our copy of a vendor file: the neutral copy line, or the one fingerprint-pam
# wrote before it was shared ("# lingmo-fingerprint: copy of ...").
is_copy() {
    grep -Eq -- "$COPY_RE" "$1" || grep -Eq -- '^#[[:space:]]*lingmo-fingerprint:[[:space:]]*copy of' "$1"
}

# The vendor file as it was when copied (the copy of it we kept)
saved_vendor() {
    local svc=$1 f
    for f in "$COPIES_DIR/$svc.vendor" "$SETTINGS_STATE/fingerprint-pam/backup/$svc.vendor"; do
        [ -f "$f" ] && { echo "$f"; return 0; }
    done
    return 1
}

service_state() {
    local svc=$1 f="$PAM_DIR/$1" src
    if [ -e "$f" ] || [ -L "$f" ]; then
        src=$f
    elif [ -f "$VENDOR_DIR/$svc" ]; then
        src="$VENDOR_DIR/$svc"
    else
        echo missing
        return
    fi
    if [ "$src" = "$f" ] && has_tag "$f"; then
        echo enabled
    elif has_foreign "$src"; then
        echo external
    else
        echo disabled
    fi
}

enable_service() {
    local svc=$1 f="$PAM_DIR/$1" vendor="$VENDOR_DIR/$1" src ref copied=0 out orig

    if [ -e "$f" ] || [ -L "$f" ]; then
        check_file "$f" || return 1
        src=$f
        ref=$f
    elif [ -f "$vendor" ]; then
        check_file "$vendor" || return 1
        src=$vendor
        ref=$vendor
        copied=1
    else
        echo "$svc: missing (not installed), skipped"
        return 0
    fi

    if [ $copied -eq 0 ] && has_tag "$f"; then
        echo "$svc: already enabled"
        return 0
    fi
    if has_foreign "$src"; then
        echo "$svc: already configured by the administrator, left alone"
        return 0
    fi
    if ! has_auth_line "$src"; then
        warn "$src has no auth line, leaving it alone"
        return 1
    fi

    out=$(new_tmp)
    if ! insert_line "$src" "$svc" >"$out"; then
        warn "couldn't add our line to $src"
        return 1
    fi

    # Sanity check: the new file is the old one plus our tagged line.
    orig=$(new_tmp)
    strip_tagged "$out" >"$orig"
    if ! strip_tagged "$src" | cmp -s - "$orig"; then
        warn "unexpected result for $svc, nothing changed"
        return 1
    fi

    if [ $copied -eq 1 ]; then
        echo "$COPY_TAG: copy of ${vendor#"$ROOT"}, deleted again when the Lingmo lines are removed" >>"$out"
        # Remember what was copied, so the copy is still recognized after a
        # package update changed the vendor file.
        make_state_dir "$COPIES_DIR" && chmod 700 -- "$COPIES_DIR" 2>/dev/null
        cp -p -- "$vendor" "$COPIES_DIR/$svc.vendor" || { warn "couldn't back up $vendor, nothing changed"; return 1; }
    else
        backup "$svc" "$f" || { warn "couldn't back up $f, nothing changed"; return 1; }
    fi
    replace_file "$f" "$out" "$ref" || { warn "couldn't write $f"; return 1; }
    echo "$svc: enabled"
}

disable_service() {
    local svc=$1 f="$PAM_DIR/$1" vendor="$VENDOR_DIR/$1" out base saved

    if [ ! -e "$f" ] && [ ! -L "$f" ]; then
        echo "$svc: nothing to do"
        return 0
    fi
    check_file "$f" || return 1
    if ! has_tag "$f"; then
        echo "$svc: already disabled"
        return 0
    fi

    out=$(new_tmp)
    strip_tagged "$f" >"$out"

    backup "$svc" "$f" || { warn "couldn't back up $f, nothing changed"; return 1; }

    if is_copy "$f" && ! grep -Eq -- "$ANY_TAG_RE" "$out"; then
        # Our own copy of the vendor file, with no Lingmo line left: delete it
        # if nothing else changed in it.
        base=$(new_tmp)
        grep -v -E -- "$COPY_RE" "$out" >"$base"
        saved=$(saved_vendor "$svc") || saved=""
        if { [ -f "$vendor" ] && cmp -s -- "$base" "$vendor"; } ||
                { [ -n "$saved" ] && cmp -s -- "$base" "$saved"; }; then
            rm -f -- "$f" || { warn "couldn't remove $f"; return 1; }
            [ -n "$saved" ] && rm -f -- "$saved"
            echo "$svc: disabled (removed the copy of ${vendor#"$ROOT"})"
            return 0
        fi
    fi
    if [ ! -s "$out" ] || ! has_auth_line "$out"; then
        warn "$f would be left without an auth line, nothing changed"
        return 1
    fi
    # A copy made by the old fingerprint-pam that still carries other Lingmo
    # lines keeps being recognized as a copy
    if is_copy "$f" && ! is_copy "$out"; then
        echo "$COPY_TAG: copy of ${vendor#"$ROOT"}, deleted again when the Lingmo lines are removed" >>"$out"
    fi
    replace_file "$f" "$out" "$f" || { warn "couldn't write $f"; return 1; }
    echo "$svc: disabled"
}

# write_marker <file> <text>
write_marker() {
    local marker=$1 out
    mkdir -p -- "${marker%/*}" || return 1
    out=$(new_tmp)
    {
        echo "# Written by $PROG: $2"
        echo "# Remove it with \"$PROG disable\"."
    } >"$out"
    install -m 644 -- "$out" "$marker"
}

# One helper at a time changes /etc/pam.d
lock() {
    mkdir -p -- "$SETTINGS_STATE" || die "can't create $SETTINGS_STATE"
    exec 9>"$SETTINGS_STATE/pam.lock" || die "can't open the lock file"
    flock -w 30 9 || die "another instance is running"
}

need_root() {
    if [ -z "$ROOT" ] && [ "$(id -u)" -ne 0 ]; then
        die "must be run as root (pkexec $0 $1)"
    fi
}
