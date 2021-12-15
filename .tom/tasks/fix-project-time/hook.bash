for i in $(ls -1 ~/.mbf/projects); do
  run_task fix p $i
done
