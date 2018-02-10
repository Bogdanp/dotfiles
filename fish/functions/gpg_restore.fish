function gpg_restore
    if test (count $argv) -eq 1;
        set SOURCE $argv[1]
        mkdir -p "$SOURCE"

        gpg --import "$SOURCE/secret-keys.gpg"
        gpg --import-ownertrust "$SOURCE/ownertrust.gpg"
    else;
        echo "usage: gpg_restore SOURCE"
        return 1
    end
end
