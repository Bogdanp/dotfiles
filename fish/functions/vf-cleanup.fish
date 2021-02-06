function vf-cleanup
    for e in (vf ls)
        if not test -d "$HOME/sandbox/$e"; and not test -d "$HOME/work/$e"
            vf rm "$e"
        end
    end
end
