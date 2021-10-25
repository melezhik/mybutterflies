use lib "./lib";

use MyButterfly::Conf;
use JSON::Fast;

for dir "{cache-root()}/projects" -> $p {

  my $int = "$p/meta.json".IO.modified;

  my $date = DateTime.new(
        $int,
        #formatter => {
        #  sprintf '%02d.%02d.%04d, %02d:%02d', 
        #  .day, .month, .year, .hour, .minute
        #}
  );

  my $s = "$date";

  my $date-after = DateTime.new($s);

  #say $p.basename, " --> ", $s, " ", $date-after;

  my %meta = from-json("$p/meta.json".IO.slurp);

  %meta<creation-date> = $s;

  #say %meta;

  "$p/meta.json".IO.spurt(to-json(%meta));

  #say to-json(%meta);

}
