#!/usr/bin/env bash
# Report versions of tools whose configuration is managed by chezmoi.

set -uo pipefail

readonly REPORT_DIRECTORY="$HOME/.config/chezmoi-sync"

# ZTE machines can reach each other over SSH. The standalone Mac is never
# included in this list: it exchanges configuration only through GitHub.
# Format: report label|hostname|SSH alias.
readonly -a ZTE_MACHINES=(
    'NewStarOS|LIN-23E4CE90673|NewStarOS'
    '187vm|187vm|187vm'
    '187host|baseband-ironic-64c512g-ubuntu-022|187host'
    '18host|ubuntu22-sv18|18host'
    '18vm|dev|18vm'
)

# Keep this inventory aligned with ~/.config, ~/.bash*, and ~/.pi/agent.
# btm is Bottom's executable; pip3 uses ~/.config/pip/pip.conf.
readonly -a TOOLS=(
    chezmoi bash
    btm code eza fzf gitui htop navi neovide nvim opencode pi pip3
    ruff tmux ty uv yazi
)

usage() {
    cat <<'EOF'
Usage: versions.sh [--all] [--output FILE]
       versions.sh --local [--machine NAME]

  --all           Check the current scope: all ZTE machines, or only a Mac.
  --local         Print one machine's Markdown section to stdout.
  --machine NAME  Override the local machine label for --local.
  --output FILE   Override the scope-specific managed report path.
  -h, --help      Show this help.
EOF
}

# Non-interactive SSH shells do not necessarily source the user's PATH setup.
add_tool_directories_to_path() {
    local directory
    for directory in \
        "$HOME/.pi/agent/bin" \
        "$HOME/.opencode/bin" \
        "$HOME/.cargo/bin" \
        "$HOME/.bun/bin" \
        "/opt/homebrew/bin" \
        "$HOME/.local/bin" \
        "$HOME/bin"
    do
        [[ ":$PATH:" == *":$directory:"* ]] || PATH="$directory:$PATH"
    done
    export PATH
}

query_version() {
    local tool=$1 output version rc status
    local -a command

    # Avoid mapfile so this also works with macOS's default Bash 3.2.
    case "$tool" in
        tmux) command=(tmux -V) ;;
        *)    command=("$tool" --version) ;;
    esac
    if ! command -v "${command[0]}" >/dev/null 2>&1; then
        printf '%s\t%s\n' NOT_FOUND '-'
        return
    fi

    if output=$("${command[@]}" </dev/null 2>&1); then
        rc=0
    else
        rc=$?
    fi

    # Remove terminal control characters. Some tools print descriptions or
    # warnings before their actual version, so select a tool-specific line.
    output=$(printf '%s\n' "$output" | sed $'s/\033\\[[0-9;]*m//g; s/\r//g')
    case "$tool" in
        eza)
            version=$(printf '%s\n' "$output" | awk '/^v?[0-9]+\.[0-9]+/ { print; exit }')
            ;;
        htop)
            version=$(printf '%s\n' "$output" | awk '/^htop [0-9]+\./ { print; exit }')
            ;;
        pip3)
            version=$(printf '%s\n' "$output" | awk '/^pip [0-9]+\./ { print; exit }')
            ;;
        yazi)
            version=$(
                printf '%s\n' "$output" | awk '
                    /^Yazi [0-9]+\./ { print; exit }
                    /^[[:space:]]*Version:[[:space:]]*/ {
                        sub(/^[[:space:]]*Version:[[:space:]]*/, "")
                        print "Yazi " $0
                        exit
                    }'
            )
            ;;
        *)
            version=$(
                printf '%s\n' "$output" | awk '{
                    sub(/^[[:space:]]+/, "")
                    sub(/[[:space:]]+$/, "")
                    if (length($0)) { print; exit }
                }'
            )
            ;;
    esac

    # Preserve unexpected output, especially diagnostics from failed commands.
    if [[ -z "$version" ]]; then
        version=$(
            printf '%s\n' "$output" | awk '{
                sub(/^[[:space:]]+/, "")
                sub(/[[:space:]]+$/, "")
                if (length($0)) { print; exit }
            }'
        )
    fi

    if ((rc != 0)); then
        status="ERROR($rc)"
    elif [[ -z "$version" ]]; then
        status=EMPTY
    else
        status=OK
    fi
    printf '%s\t%s\n' "$status" "${version:--}"
}

markdown_cell() {
    local value=${1//|/\\|}
    printf '%s' "$value"
}

local_report() {
    local machine=$1 tool result status version hostname
    hostname=$(hostname)

    printf '## %s\n\n' "$machine"
    printf -- '- Hostname: `%s`\n' "$hostname"
    printf -- '- Kernel: `%s`\n\n' "$(uname -srm)"
    printf '| Tool | Status | Version |\n'
    printf '| --- | --- | --- |\n'

    for tool in "${TOOLS[@]}"; do
        result=$(query_version "$tool")
        status=${result%%$'\t'*}
        version=${result#*$'\t'}
        printf '| `%s` | %s | %s |\n' \
            "$tool" "$status" "$(markdown_cell "$version")"
    done
    printf '\n'
}

unavailable_report() {
    local machine=$1 reason=$2
    printf '## %s\n\n' "$machine"
    printf '**Version check failed:** %s\n\n' "$(markdown_cell "$reason")"
}

sync_scope() {
    if [[ -n "${USER_TAG:-}" ]]; then
        printf '%s\n' zte
    elif [[ "$(uname -s)" == Darwin ]]; then
        printf '%s\n' mac
    else
        printf '%s\n' standalone
    fi
}

default_report_path() {
    printf '%s/software-versions-%s.md\n' "$REPORT_DIRECTORY" "$1"
}

local_machine_name() {
    if [[ -n "${USER_TAG:-}" ]]; then
        case "$USER_TAG" in
            NewStarOS|NewStartOS) printf '%s\n' NewStarOS ;;
            *) printf '%s\n' "$USER_TAG" ;;
        esac
    elif [[ "$(uname -s)" == Darwin ]]; then
        printf '%s\n' MacBook
    else
        hostname
    fi
}

all_report() {
    local scope=$1
    local entry machine machine_hostname ssh_host current_hostname output
    current_hostname=$(hostname)

    printf '# Chezmoi-managed software versions (%s)\n\n' "$scope"
    printf 'Generated: %s\n\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
    if [[ "$scope" == zte ]]; then
        printf 'Scope: all ZTE machines; no standalone Mac access.\n\n'
    else
        printf 'Scope: this standalone machine only; no ZTE machine access.\n\n'
    fi
    local_report "$(local_machine_name)"

    # Mac and other standalone machines are local/GitHub-only. Never attempt
    # cross-group SSH, even to record an unreachable-machine placeholder.
    [[ "$scope" == zte ]] || return 0

    for entry in "${ZTE_MACHINES[@]}"; do
        IFS='|' read -r machine machine_hostname ssh_host <<< "$entry"
        [[ "$machine_hostname" == "$current_hostname" ]] && continue

        if ! ssh -o BatchMode=yes -o ConnectTimeout=8 "$ssh_host" 'exit 0' >/dev/null 2>&1; then
            unavailable_report "$machine" 'passwordless SSH login failed or timed out.'
            continue
        fi

        # Send this script over stdin so the pre-sync check also works before
        # the newly managed script has been applied on a remote machine. An
        # interactive parent loads the user's normal PATH and library paths;
        # the inner non-interactive Bash executes the script from stdin.
        if output=$(ssh -o BatchMode=yes -o ConnectTimeout=8 "$ssh_host" \
            "bash -ic 'bash -s -- --local --machine $machine'" < "${BASH_SOURCE[0]}" 2>/dev/null)
        then
            printf '%s\n\n' "$output"
        else
            unavailable_report "$machine" 'remote version script failed.'
        fi
    done
}

main() {
    local mode=all machine scope output_path report
    machine=$(local_machine_name)
    scope=$(sync_scope)
    output_path=$(default_report_path "$scope")

    while (($#)); do
        case "$1" in
            --all) mode=all; shift ;;
            --local) mode=local; shift ;;
            --machine)
                (($# >= 2)) || { printf '%s: --machine needs a value\n' "$0" >&2; return 2; }
                machine=$2
                shift 2
                ;;
            --output)
                (($# >= 2)) || { printf '%s: --output needs a value\n' "$0" >&2; return 2; }
                output_path=$2
                shift 2
                ;;
            -h|--help) usage; return 0 ;;
            *) printf '%s: unknown option: %s\n' "$0" "$1" >&2; usage >&2; return 2 ;;
        esac
    done

    add_tool_directories_to_path
    if [[ "$mode" == local ]]; then
        local_report "$machine"
        return
    fi

    report=$(all_report "$scope")
    mkdir -p -- "$(dirname "$output_path")"
    printf '%s\n' "$report" > "$output_path"
    printf '%s\n' "$report"
    printf '\nReport saved to `%s`.\n' "$output_path"
}

main "$@"
