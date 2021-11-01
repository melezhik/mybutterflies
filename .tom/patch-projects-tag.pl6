use JSON::Fast;
use lib "lib/";

use MyButterfly::Conf;


for dir "{cache-root()}/projects" -> $p {

  my %meta = from-json("$p/meta.json".IO.slurp);

  %meta<tags> = [];

  "$p/meta.json".IO.spurt(to-json(%meta));

  say "{$p.basename} patched";

}
