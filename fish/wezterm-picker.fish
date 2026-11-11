set -l choice (
    begin
        printf '%s\n' $argv
        zoxide query --list | while read -l directory
            printf 'directory\t%s\n' "$directory"
        end
    end | while read -l line
        set -l entry (string split \t -- "$line")
        switch "$entry[1]"
            case workspace
                set entry[2] (set_color magenta)"$entry[2]"(set_color normal)
            case ssh
                set entry[2] (set_color cyan)"$entry[2]"(set_color normal)
            case directory
                set entry[2] (set_color green)"$entry[2]"(set_color normal)
        end
        string join \t -- $entry
    end | fzf --ansi --no-sort --delimiter=\t --with-nth=2 --print-query --expect=enter,alt-enter \
        --prompt='Workspace> ' --header='Enter: select or create · Alt+Enter: force new workspace'
)
or exit 0

set -l name "$choice[1]"
set -l cwd ''
set -l host ''

if test "$choice[2]" != alt-enter; and test (count $choice) -ge 3
    set -l entry (string split \t -- "$choice[3]")
    set name "$entry[2]"
    switch "$entry[1]"
        case ssh
            set host "$entry[3]"
        case directory
            set cwd "$entry[2]"
            set name (path basename -- "$cwd")
    end
else
    set -l directory (string replace -r '^~/' "$HOME/" -- "$name")
    if test -d "$directory"
        set cwd (path resolve -- "$directory")
        set name (path basename -- "$cwd")
    else if string match -q '*:*' -- "$name"
        set -l parts (string split -m 1 : -- "$name")
        test -n "$parts[1]"; and test -n "$parts[2]"; or exit 0
        set host "$parts[2]"
        for candidate in $argv
            set -l entry (string split \t -- "$candidate")
            if test "$entry[1]" = ssh; and test "$entry[2]" = "$host"
                set host "$entry[3]"
                break
            end
        end
    end
end

test -n "$name"; or exit 0
set -l target (jq -cn --arg name "$name" --arg cwd "$cwd" --arg host "$host" \
    '{name: $name, cwd: $cwd, host: $host}' | base64 | string join '')
printf '\e]1337;SetUserVar=workspace_picker=%s\a' "$target"
# Keep the picker pane alive until WezTerm handles the selection and closes it.
read -l ignored
