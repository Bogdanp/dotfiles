function bin_backup
    if test (count $argv) -eq 1
        set TARGET $argv[1]

        set filename "bin-"(date +%Y-%m-%d)".tar.gz"
        tar -cvzf "$filename" ~/bin/*

        gpg -c "$filename"
        mv "$filename.gpg" "$TARGET/$filename.gpg"

        rm "$filename"
    else
        echo "usage: bin_backup TARGET"
        return 1
    end
end
