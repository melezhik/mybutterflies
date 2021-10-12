set -e

for i in $(find ~/.mbf/projects/ | grep 'reviews/replies/'); do

  raku -e "

    #say '$i';

    #exit;

    exit unless '$i' ~~ /.* \\S+ '_' \\d+ '/' (\\S+) \$\$/;

    my \$u = '$i'.IO.basename;
    my @f = '$i'.split('/').grep({\$_});
    my \$p = @f[4];
    my \$t = '$i'.IO.modified.Int;
    say 'mv -v $i $i', '_' ~ \$t;
  " | bash;

done;

