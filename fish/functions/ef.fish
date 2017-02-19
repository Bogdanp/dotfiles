function ef
  fzf-tmux --query="$1" --multi --select-1 --exit-0 | read -l filename
  if [ $filename ]
    ec $filename
  end
end
