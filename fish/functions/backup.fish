function backup
    tarsnap -c -f "mbp-"(date +%Y-%m-%d_%H-%M-%S) ~/.ssh ~/Documents ~/Mail
end
