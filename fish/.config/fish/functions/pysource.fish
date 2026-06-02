function pysource --wraps='source .venv/bin/activate.fish' --description 'alias pysource=source .venv/bin/activate.fish'
    source .venv/bin/activate.fish $argv
end
