unit module MyButterfly::Conf;

use YAMLish;

sub cache-root is export {

  "{%*ENV<HOME>}/.mbf/";

}

sub http-root is export {

  %*ENV<MBF_HTTP_ROOT> || "";

}

sub get-web-conf is export {

  my $conf-file = %*ENV<HOME> ~ '/mbf.yaml';

  my %conf = $conf-file.IO ~~ :f ?? load-yaml($conf-file.IO.slurp) !! Hash.new;

  %conf;

}
