function set_deployment_target
    if test (count $argv) -eq 1
        set -xg MACOSX_DEPLOYMENT_TARGET $argv[1]
    else
        echo "usage: set_deployment_target VERSION"
        return 1
    end
end
