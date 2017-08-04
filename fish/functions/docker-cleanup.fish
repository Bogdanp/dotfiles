function docker-cleanup
  echo " * Removing dangling images..."
  docker images -f dangling=true -q | xargs docker rmi -f

  echo " * Removing exited containers..."
  docker ps --filter status=dead --filter status=exited -aq | xargs docker rm -v

  echo " * Removing dangling volumes..."
  docker volume ls -qf dangling=true | xargs docker volume rm
end
