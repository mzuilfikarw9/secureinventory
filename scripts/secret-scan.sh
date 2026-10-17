#!/usr/bin/env bash
# Scan the Git history and the working tree for secrets with Gitleaks.
#
# Exit codes: 0 = no findings, 1 = potential secrets found, 2 = scan error.
# Secret values are redacted in console output and in the JSON reports.
set -uo pipefail

GITLEAKS_IMAGE="ghcr.io/gitleaks/gitleaks:v8.30.1@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f"
LEAKS_EXIT_CODE=10

repo_root="$(git rev-parse --show-toplevel)" || exit 2
report_dir="$repo_root/reports/gitleaks"
mkdir -p "$report_dir" || exit 2

# Runs one gitleaks command; the repository is mounted read-only and the
# container has no network access.
run_gitleaks() {
    docker run --rm --network none \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -e GIT_CONFIG_COUNT=1 \
        -e GIT_CONFIG_KEY_0=safe.directory \
        -e GIT_CONFIG_VALUE_0=/repo \
        -v "$repo_root:/repo:ro" \
        -v "$report_dir:/reports" \
        -w /repo \
        "$GITLEAKS_IMAGE" "$@" \
        --config /repo/.gitleaks.toml \
        --redact \
        --no-banner \
        --exit-code "$LEAKS_EXIT_CODE" \
        --report-format json
}

status=0

scan() {
    local name="$1"
    shift
    echo "==> Gitleaks $name scan"
    run_gitleaks "$@" --report-path "/reports/$name.json"
    local code=$?
    case "$code" in
        0) echo "    no findings" ;;
        "$LEAKS_EXIT_CODE")
            echo "    potential secrets found; see reports/gitleaks/$name.json (values redacted)"
            [ "$status" -eq 2 ] || status=1
            ;;
        *)
            echo "    scan failed (exit $code)" >&2
            status=2
            ;;
    esac
}

scan git git /repo
scan dir dir /repo

exit "$status"
