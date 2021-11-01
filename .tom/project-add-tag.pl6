use JSON::Fast;
use lib "lib/";

my $p = %*ENV<project> or die "project env variable is required";

my $tag = %*ENV<tag> or die "tag env variable is required";

use MyButterfly::Conf;

my %meta = from-json("{cache-root()}/projects/$p/meta.json".IO.slurp);

if grep $tag, %meta<tags><> {

  say "tag=$tag already exists in $p";

} else {

  say "push tag=$tag to $p";
  push %meta<tags>, $tag;
  "{cache-root()}/projects/$p/meta.json".IO.spurt(to-json(%meta));
  say "{cache-root()}/projects/$p/meta.json patched";

}



