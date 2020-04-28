function forward-plex
    if test (count $argv) -eq 1
        ssh -L7878:127.0.0.1:7878 -L8989:127.0.0.1:8989 -L9091:127.0.0.1:9091 -L9117:127.0.0.1:9117 "$argv[1]"
    else
        echo "usage: forward-plex [IP_ADDRESS]" >&2
        return 1
    end
end
