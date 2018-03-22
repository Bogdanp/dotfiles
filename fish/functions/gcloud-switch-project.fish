function gcloud-switch-project
    if test (count $argv) -eq 1;
        set PROJECT $argv[1]
        gcloud auth login; and gcloud auth application-default login; and gcloud config set project "$PROJECT"
    else;
        echo "usage: gcloud-switch-project PROJECT" >&2
        return 1
    end
end
