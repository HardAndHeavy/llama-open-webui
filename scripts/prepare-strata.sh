#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

fail() {
    printf 'Strata setup: %s\n' "$*" >&2
    exit 1
}

# Use device ownership, not host/container group names: GIDs vary by distro.
shopt -s nullglob
render_devices=(/dev/dri/renderD*)
video_devices=(/dev/dri/card*)
((${#render_devices[@]})) || fail 'No /dev/dri/renderD* devices found. Check the AMD GPU driver on the host.'
((${#video_devices[@]})) || fail 'No /dev/dri/card* devices found. Check the AMD GPU driver on the host.'
[[ -c /dev/kfd ]] || fail 'No /dev/kfd character device found. Check that the AMD ROCm/amdgpu driver is available.'

for device in "${render_devices[0]}" "${video_devices[0]}"; do
    [[ -c "$device" ]] || fail "$device is not a character device."
done
render_gid=$(stat -c '%g' -- "${render_devices[0]}")
video_gid=$(stat -c '%g' -- "${video_devices[0]}")
kfd_gid=$(stat -c '%g' -- /dev/kfd)
for gid in "$render_gid" "$video_gid" "$kfd_gid"; do
    [[ "$gid" =~ ^[0-9]+$ ]] || fail 'Could not determine numeric GPU device group IDs.'
done
[[ "$kfd_gid" == "$render_gid" || "$kfd_gid" == "$video_gid" ]] ||
    fail '/dev/kfd has a different group from the DRM devices. Align GPU device permissions on the host first.'

# Keep existing secrets and other settings; create a key only if absent/empty.
source_env=.env
[[ -f "$source_env" ]] || source_env=.env.example
api_key=''
existing_key=$(sed -n 's/^[[:space:]]*STRATA_API_KEY=//p' "$source_env" | tail -n 1)
existing_key="${existing_key//[[:space:]]/}"
if [[ -z "$existing_key" || "$existing_key" == '""' || "$existing_key" == "''" ]]; then
    command -v openssl >/dev/null || fail 'openssl is required to generate STRATA_API_KEY.'
    api_key=$(openssl rand -hex 24)
fi

umask 077
tmp=$(mktemp .env.tmp.XXXXXX)
trap 'rm -f -- "$tmp"' EXIT
# Do not source .env: it is Compose configuration, not executable shell code.
awk -v render="$render_gid" -v video="$video_gid" -v key="$api_key" '
    BEGIN {
        values["RENDER_GID"] = render
        values["VIDEO_GID"] = video
        if (key != "") values["STRATA_API_KEY"] = key
    }
    {
        name = $0
        sub(/=.*/, "", name)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
        if (name in values) {
            if (!seen[name]++) print name "=" values[name]
        } else print
    }
    END {
        for (name in values)
            if (!seen[name]) print name "=" values[name]
    }
' "$source_env" > "$tmp"
mv -- "$tmp" .env
printf 'Strata GPU groups: render=%s video=%s kfd=%s\n' "$render_gid" "$video_gid" "$kfd_gid"
