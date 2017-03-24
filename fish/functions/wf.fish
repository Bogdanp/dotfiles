function wf
  find ~/{sandbox,work} -type d -mindepth 1 -maxdepth 1 | xargs basename | fzf --query="$argv[1]" --select-1 --exit-0 | read -l project
  if [ $project ]
    workon $project
  end
end
