function workon
    vf deactivate >/dev/null || true

    if test (count $argv) -eq 1
        set PROJECT $argv[1]

        if test -d "$HOME/sandbox/$PROJECT"
            cd "$HOME/sandbox/$PROJECT"

        else if test -d "$HOME/work/$PROJECT"
            cd "$HOME/work/$PROJECT"

        else if test -d "$HOME/common-lisp/$PROJECT"
            cd "$HOME/common-lisp/$PROJECT"

        else if test -d (find "$HOME/sandbox/golang/src" -type d -name "$PROJECT")
            cd (find "$HOME/sandbox/golang/src" -type d -name "$PROJECT")

        else
            echo "'$PROJECT' not found"
            return 1

        end

        if test -d "$HOME/.virtualenvs/$PROJECT"
            vf activate "$PROJECT"
        end

        if test -f ".nvmrc"
            nvm use (cat .nvmrc)
        else if test -f "package.json"
            nvm use 12
        end

        tmux rename-window "$PROJECT"
    else;
        echo "usage: workon PROJECT"
        return 1
    end
end
