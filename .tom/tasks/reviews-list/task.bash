set -e

for i in $(find ~/.mbf/projects/ | grep reviews/data/); do 

  raku -I lib -MMyButterfly::Utils -e "say review-from-file('$i')"

done;
