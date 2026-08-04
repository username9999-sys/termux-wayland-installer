#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - YAML Config Parser
# Simple YAML parser for bash (subset used in our config)
# Supports nested keys and arrays
# Stores arrays as pipe-delimited strings
# ============================================================

# Parse YAML config and export as CFG_* variables
# Usage: parse_yaml "config/install.yaml"
parse_yaml() {
    local yaml_file="$1"
    local prefix="${2:-CFG_}"

    [[ -f "${yaml_file}" ]] || { log_error "Config file not found: ${yaml_file}"; return 1; }

    # Stack to track current path at each indent level
    local -a path_stack=()

    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "${line}" =~ ^[[:space:]]*# ]] && continue
        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue

        # Calculate indent level (2 spaces per level)
        local indent=0
        while [[ "${line:$indent:2}" == "  " ]]; do
            indent=$((indent + 2))
        done
        local level=$((indent / 2))

        # Trim leading spaces
        local trimmed="${line#"${line%%[![:space:]]*}"}"

        # Pop stack to current level
        while [[ ${#path_stack[@]} -gt $level ]]; do
            unset 'path_stack[${#path_stack[@]}-1]'
        done

        # Detect array items (starting with -)
        if [[ "${trimmed}" =~ ^-[[:space:]]+(.+)$ ]]; then
            local value="${BASH_REMATCH[1]}"
            value=$(echo "${value}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//;s/^'"'"'//;s/'"'"'$//')

            # Current key is the last element in path_stack (parent of array)
            if [[ ${#path_stack[@]} -gt 0 ]]; then
                local array_var="${prefix}$(IFS=_ ; echo "${path_stack[*]}")"
                array_var="${array_var^^}"
                # Store array items as pipe-delimited string
                local existing="${!array_var:-}"
                if [[ -n "${existing}" ]]; then
                    export "${array_var}=${existing}|${value}"
                else
                    export "${array_var}=${value}"
                fi
            fi
            continue
        fi

        # Parse key: value pairs
        if [[ "${trimmed}" =~ ^([a-zA-Z_][a-zA-Z0-9_]*):[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Remove inline comments
            value=$(echo "${value}" | sed 's/[[:space:]]*#.*$//')

            # Trim whitespace and quotes
            value=$(echo "${value}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//;s/^'"'"'//;s/'"'"'$//')

            # Push to path stack at this level
            path_stack[$level]="${key}"
            # Truncate stack to current level + 1
            path_stack=("${path_stack[@]:0:$((level + 1))}")

            # Build full key path
            local full_key=$(IFS=_ ; echo "${path_stack[*]}")
            full_key="${full_key^^}"

            # Export ALL values, including empty strings
            export "${prefix}${full_key}"="${value}"
        fi
    done < "${yaml_file}"

    log_debug "Parsed config from ${yaml_file}"
}

# Get pinned version for a package
# Usage: get_pinned_version "package-name"
get_pinned_version() {
    local pkg="$1"
    # Convert package name to variable format (hyphens to underscores, uppercase)
    local var_name="CFG_REPOSITORIES_PINNED_${pkg//-/_}"
    var_name="${var_name^^}"
    echo "${!var_name:-}"
}

# Get config value with default
# Usage: cfg_get "general.theme" "catppuccin"
cfg_get() {
    local key="$1"
    local default="${2:-}"

    # Convert dots to underscores, then uppercase
    local temp="${key//./_}"
    local var_name="CFG_${temp^^}"
    local value="${!var_name:-}"

    if [[ -n "${value}" ]]; then
        echo "${value}"
    else
        echo "${default}"
    fi
}

# Get config array as space-separated string
# Usage: cfg_get_array "packages.wayland_core"
cfg_get_array() {
    local key="$1"
    local temp="${key//./_}"
    local var_name="CFG_${temp^^}"
    local value="${!var_name:-}"

    # Convert pipe delimiter to space
    echo "${value//|/ }"
}

# Check if config value is truthy
cfg_is_true() {
    local key="$1"
    local value
    value=$(cfg_get "${key}" "false")
    [[ "${value}" == "true" || "${value}" == "yes" || "${value}" == "1" || "${value}" == "on" ]]
}

# Export functions
export -f parse_yaml cfg_get cfg_get_array cfg_is_true get_pinned_version