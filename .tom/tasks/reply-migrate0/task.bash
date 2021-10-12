set -e

for i in $(find ~/.mbf/projects/ | grep 'reviews/replies/'); do

  raku -e "

    #say '$i';

    exit unless '$i' ~~ /.* \\S+ '_' \\d+ '/' (\\S+) \$\$/;

    say '\$0';

    my \$u = '$i'.IO.basename;
    my @f = '$i'.split('/').grep({\$_});
    my \$p = @f[4];
    my \$t = '$i'.IO.modified.Int;
    my \$new-name = \$u ~ '_' ~ \$t;
    say 'mv -v ~/.mbf/projects/',\$p, '/reviews/data/',\$u, 
        ' ~/.mbf/projects/', \$p, '/reviews/data/', \$new-name;


  ";

done;

