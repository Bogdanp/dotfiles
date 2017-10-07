function docker-cleanup
  docker image prune
  docker container prune
  docker volume prune
end
