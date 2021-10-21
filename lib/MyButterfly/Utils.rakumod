unit module MyButterfly::Utils;

use MyButterfly::Conf;
use JSON::Tiny;
use HTML::Strip;

sub review-from-file ($path) is export {

  if ( $path ~~ /^^ (\S+) '_' (\d+) $$/ ) {
    return %( 
      author => $0.IO.basename, 
      epoch => "$1",
      id => "$1",
      basename => $path.IO.basename,
      date => DateTime.new(
        Instant.from-posix("$1"),
        formatter => {
          sprintf '%02d.%02d.%04d, %02d:%02d', 
          .day, .month, .year, .hour, .minute
        }
      )
    )
  } else {
    die "wrong path: $path";
  }
}

sub date-to-x-ago ($date) is export {

  #DateTime.new(
  #  %meta<update-date>,
  #  formatter => {
  #    sprintf '%02d.%02d.%04d, %02d:%02d', 
  #      .day, .month, .year, .hour, .minute
  #    }
  #)


 my @int = [

  %( label => "> 1 year ago", date => DateTime.now() - Duration.new(60*60*24*7*30*12) ),
  %( label => "> 1 month ago", date => DateTime.now() - Duration.new(60*60*24*7*30) ),
  %( label => "> 1 week ago", date => DateTime.now() - Duration.new(60*60*24*7) ),
  %( label => "> 3 day ago", date => DateTime.now() - Duration.new(60*60*24*3) ),
  %( label => "> 1 day ago", date => DateTime.now() - Duration.new(60*60*24) ),
  %( label => "> 10 hour ago", date => DateTime.now() - Duration.new(60*60*10) ),
  %( label => "> 6 hour ago", date => DateTime.now() - Duration.new(60*60*6) ),
  %( label => "> 3 hour ago", date => DateTime.now() - Duration.new(60*60*3) ),
  %( label => "> 1 hour ago", date => DateTime.now() - Duration.new(60*60) ),
  %( label => "> 15 min ago", date => DateTime.now() - Duration.new(60*15) ),
  %( label => "> 10 min ago", date => DateTime.now() - Duration.new(60*10) ),
  %( label => "> 5 min ago", date => DateTime.now() - Duration.new(60*5) ),
  %( label => "> 1 min ago", date => DateTime.now() - Duration.new(60) ),

 ];

  for (0 .. @int.elems - 1) -> $i {
    return @int[$i]<label> if $date < @int[$i]<date>;
  }
  
  return "few secs ago";  
}



sub touch-project ($project, %event) is export {

  "{cache-root()}/projects/$project/state.json".IO.spurt(
    to-json(%event)
  );

}

sub validate-project-data (%data) is export {

 say "validate project data: {%data.perl}";

 %data<project> ~~ /^^ <[ \w \. \d : \- ]>+ $$/ 
  or return %(
    status => False,
    message => 'project should only consists of: [\w . digits - :]',
  );

  %data<project> ~~ /\S/
    or return %(
      status => False,
      message => q{project can't be empty}
    );

  %data<description> ~~ /^^ <[ \w \. \s \d \/ \\ \, \- \# ~ \' \) \( & : ! \+]>+ $$/
    or return %(
      status => False,
      message => q{description should only consist of: [\w . spaces digits / \ , ~ # ' ) ( & : ! +]}
    );

  %data<description> ~~ /\S/
    or return %(
      status => False,
      message => q{description can't be empty}
    );

  %data<url> ~~ /^^ <[ \w \. \/ \d : \. \- ~]>+ $$/
    or return %(
      status => False,
      message => q{url should only consist of: [\w . / digits : . - ~]}
    );

  %data<url> ~~ /\S/
    or return %(
      status => False,
      message => q{url can't be empty}
    );

  %data<language> ~~ /^^ <[ \w \d \+ ]>+ $$/
    or return %(
      status => False,
      message => q{language should only consist of: [\w digits +]}
    );

  %data<language> ~~ /\S/
    or return %(
      status => False,
      message => q{language can't be empty}
    );
  
  %data<category> ~~ /^^ <[ \w \d \s]>+ $$/
    or return %(
      status => False,
      message => q{category should only consist of: [\w digits spaces]}
    );

  %data<category> ~~ /\S/
    or return %(
      status => False,
      message => q{category can't be empty}
    );


  return %( status => True );
}


sub score-to-label ($points) is export {

  if $points == 0 {
    return "comment"
  }

  if $points == -1 {
    return "release"
  }

  return "{uniparse 'BUTTERFLY'}" x $points

}

sub event-to-label ($event) is export {

  if $event eq "release create" { return uniparse "PACKAGE" };
  if $event eq "project added" { return uniparse "Heavy Asterisk" }; # deprecated
  if $event eq "project create" { return uniparse "Heavy Asterisk" }; # should use this one
  if $event eq "review create" { return uniparse "Eyeglasses" };
  if $event eq "comment create" { return uniparse "Upper Right Pencil" };
  if $event eq "project upvote" { return uniparse "Rightwards Arrow Over Leftwards Arrow" };
  if $event eq "project downvote" { return uniparse "Rightwards Arrow Over Leftwards Arrow" };

}

sub mini-parser ($text) is export {

  my $res = strip_html($text);

  $res ~~ s:g!(http || https) '://' (\S+) !<a href="$0://$1" target="_blank">{$1}</a>!;

  #$res ~~ s:g!\n!<br>\n!;

  $res ~~ s:g! '`' (.*?) '`' !<span class="is-italic has-text-warning">{$0}</span>!;
  $res ~~ s:g! \s ':' (\S+?) ':' \s ! <span class="icon"><i class="fas fa-{$0}"></i></span> !;

  $res ~~ s:g! ^^ ':' (\S+?) ':' \s !<span class="icon"><i class="fas fa-{$0}"></i></span> !;
  $res ~~ s:g! \s ':' (\S+?) ':' $$ ! <span class="icon"><i class="fas fa-{$0}"></i></span>!;

  $res ~~ s:g! ^^ ':' (\S+?) ':' $$ !<span class="icon"><i class="fas fa-{$0}"></i></span>!;

  say $res;

  return $res;

}

