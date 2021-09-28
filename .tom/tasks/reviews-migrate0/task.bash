set -e

echo "backup data to ~/.mbf/backup"

#mkdir -p ~/.mbf/backup

#cp -r ~/.mbf/projects ~/.mbf/backup

for i in $(find ~/.mbf/projects/ | grep reviews/data/); do
  raku -e "
    my \$u = '$i'.IO.basename;
    my @f = '$i'.split('/').grep({\$_});
    my \$p = @f[4];;
    my \$t = '$i'.IO.modified.Int;
    my \$new-name = \$u ~ '_' ~ \$t;
    say 'mv -v ~/.mbf/projects/',\$p, '/reviews/data/',\$u, 
        ' ~/.mbf/projects/', \$p, '/reviews/data/', \$new-name;

    if ('$HOME/.mbf/projects/' ~ \$p ~ '/reviews/replies/' ~ \$u).IO ~~ :d {
      say 'mv -v ~/.mbf/projects/',\$p, '/reviews/replies/',\$u, 
          ' ~/.mbf/projects/', \$p, '/reviews/replies/', \$new-name;
    }

    if ('$HOME/.mbf/projects/' ~ \$p ~ '/reviews/points/' ~ \$u).IO ~~ :f {
      say 'mv -v ~/.mbf/projects/',\$p, '/reviews/points/',\$u, 
          ' ~/.mbf/projects/', \$p, '/reviews/points/', \$new-name;
    }

  " | bash;

done;

