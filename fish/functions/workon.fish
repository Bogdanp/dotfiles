function workon
        if test (count $argv) -eq 1;
                set PROJECT $argv[1]

                if test -d "$HOME/sandbox/$PROJECT";
                        cd "$HOME/sandbox/$PROJECT";

                else if test -d "$HOME/work/$PROJECT";
                        cd "$HOME/Work/$PROJECT";

                else;
                        echo "'$PROJECT' not found";
                        return 1;

                end;

                if test -d "$HOME/.virtualenvs/$PROJECT";
                        vf activate "$PROJECT"
                end;
        else;
                echo "usage: workon PROJECT"
                return 1
        end
end
