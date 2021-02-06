function vf-cleanup
    for e in (vf-3.8 ls)
        if not test -d "$HOME/sandbox/$e"; and not test -d "$HOME/work/$e"
            vf-3.8 rm "$e"
        end
    end
end
