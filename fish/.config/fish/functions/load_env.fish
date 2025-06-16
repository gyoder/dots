# Copilot Generated
function load_env --description 'Load environment variables from a .env file (defaults to ./.env)'
    set -l env_file ".env"
    if test (count $argv) -gt 0
        set env_file $argv[1]
    end

    if not test -f "$env_file"
        echo "Error: Environment file not found: $env_file" >&2
        return 1
    end

    for line in (cat -- "$env_file")
        set -l trimmed (string trim -- "$line")
        # Skip empty lines and comments
        if test -z "$trimmed"; or string match -q -r "^\s*#" -- "$trimmed"
            continue
        end

        # Only process lines with =
        if not string match -q -- '*=*' "$trimmed"
            continue
        end

        # Use regex to extract key and value, and preserve quotes in value
        set -l key (string match -r '^[^=]+' "$trimmed")
        set -l rest (string match -r '=[\s\S]*$' "$trimmed")

        if test -z "$key" -o -z "$rest"
            continue
        end

        set -l key (string trim -- "$key")
        set -l value (string trim -- (string sub -s 2 -- "$rest")) # Remove leading '='

        # Validate variable name
        if not string match -q -r '^[a-zA-Z_][a-zA-Z0-9_]*$' "$key"
            echo "Warning: Invalid variable name '$key'. Skipping."
            continue
        end

        # Reconstruct assignment and use eval to preserve value as-is
        eval "set -gx $key $value"
    end
end
