#!/usr/bin/env bash
# Pins the fix for the 2026-09-03 outage: steamcmd printed
# "Error! App '258550' state is 0x486 after update job." (Facepunch's monthly depot was
# mid-rollout), exited 0, and start_rust.sh carried on to install an Oxide built for the
# NEW Rust over the OLD one. RustDedicated then hung at boot — no exit, so the container's
# restart policy never fired — for five days. install_or_update must treat anything but
# steamcmd's own success line as a failure and exit non-zero, so the restart policy retries
# until Steam serves the update.
#
# Runs anywhere: the function is extracted from start_rust.sh and pointed at a stub steamcmd.
set -u
cd "$(dirname "$0")/.."

# $1: what the stub steamcmd prints. Returns install_or_update's exit status.
run() {
	local stub
	stub=$(mktemp)
	printf 'echo "%s"\nexit 0\n' "$1" > "$stub"
	(
		export STEAMCMD_SH=$stub STEAMCMD_RETRY_DELAY=0
		eval "$(sed -n '/^install_or_update()/,/^}/p' start_rust.sh)"
		install_or_update > /dev/null 2>&1
	)
}

if run "Error! App '258550' state is 0x486 after update job."; then
	echo "FAIL: a failed update (steamcmd exit 0, no success line) must exit non-zero"
	exit 1
fi
if ! run "Success! App '258550' fully installed."; then
	echo "FAIL: a successful update must carry on"
	exit 1
fi
echo "ok"
