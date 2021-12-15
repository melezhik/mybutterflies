my $p = task_var("p");

say "say fix time for project $p";
say "===========================";

my @times;

for dir("{%*ENV<HOME>}/.mbf/projects/{$p}/reviews/data/") -> $i {

  next unless $i ~~ :f;

  #say $i.basename;

  $i.basename ~~ / .* '_' (\d+) $$/;

  say $0.Str;

  push @times, $0.Str;

}

my $max-time = @times.sort().tail;

if $max-time {

  say "max time: {$max-time}";

  if "{%*ENV<HOME>}/.mbf/projects/$p/state.json" ~~ :f {
    say "run touch --date \@{$max-time} {%*ENV<HOME>}/.mbf/projects/$p/state.json";
    shell "touch --date \@{$max-time} {%*ENV<HOME>}/.mbf/projects/$p/state.json";
  } else {
    "{%*ENV<HOME>}/.mbf/projects/$p/state.json".IO.spurt('{ "action" : "create"}');
  }
}



say "===========================";
