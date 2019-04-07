function ssh_backup
    if test (count $argv) -eq 1
        set TARGET $argv[1]

        set filename "keys-"(date +%Y-%m-%d)".tar.gz"
        tar -cvzf "$filename" ~/.ssh/*

        gpg -c "$filename"
        mv "$filename.gpg" "$TARGET/$filename.gpg"

        rm "$filename"
    else
        echo "usage: ssh_backup TARGET"
        return 1
    end
end
