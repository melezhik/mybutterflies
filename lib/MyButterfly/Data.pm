use MyButterfly::Conf;
use JSON::Tiny;
use MyButterfly::Utils;

class MyButterfly::Data {


  has Hash $.project-cache;

  method cache-in-sync ($p) {

  # if a cache does not exist
  # we need to build the one

  return False unless $!project-cache{$p.basename}:exists;

  if "{$p}/updates".IO ~~ :d {

    my @updates = dir "{$p}/updates";

    # updates found, clean updates queue
    # and notify that we need to update cache

    if @updates.elems > 0 {

      say "project $p recieved {@updates.elems} updates, need to update cache";

      for @updates -> $i {
        unlink $i
      }

      return False;

    }

  }

  return True;

  }


method project-from-file ($p, Mu $user, Mu $token) {

      # default values for attributes, 
      # to be calculated using project data

      my $help-wanted = False;

      my $has-recent-release = False;

      my $first-release = False;

      my $recently-created = False;

      my %meta = from-json("$p/meta.json".IO.slurp);

      my $week-ago = DateTime.now() - Duration.new(60*60*24*7);

      my $month-ago = DateTime.now() - Duration.new(60*60*24*30);

      %meta<tags-str> = %meta<tags>.join(", ");
  
      %meta<points> = dir("$p/ups/").elems;

      %meta<reviews-cnt> = dir("$p/reviews/data").elems;

      if check-user($user, $token) and "$p/ups/$user".IO ~~ :e {
        %meta<voted> = True
      } else {
        %meta<voted> = False
      }

      %meta<date> = %meta<creation-date>; # just an alias

      if DateTime.new(%meta<creation-date>) >= $week-ago {
        $recently-created = True
      }

      %meta<creation-date-str> = DateTime.new(
        %meta<creation-date>,
        formatter => {
          sprintf '%02d.%02d.%04d, %02d:%02d', 
          .day, .month, .year, .hour, .minute
        }
      );

      if "$p/state.json".IO ~~ :e {

        %meta<update-date> = "$p/state.json".IO.modified;

        %meta<event> = from-json("$p/state.json".IO.slurp);

        %meta<event><event-str> = event-to-label(%meta<event><action>);

      } else {

        %meta<update-date> = %meta<date>;

        %meta<event> = %( action => "project added" );

        %meta<event><event-str> = event-to-label(%meta<event><action>);

      }

      %meta<date-str> = date-to-x-ago(%meta<update-date>.DateTime);

      %meta<add_by> ||= "melezhik";

      %meta<twitter-hash-tag> = join ",", (
        "mybfio", 
        "FriendlySoftwareReviews",
        %meta<language><>.map({ .subst('+','PLUS',:g).subst('Raku','Rakulang',:g) }),
    );

      if %meta<owners> {
          %meta<owners-str> = %meta<owners><>.join(" ");
      }

    if "$p/state.json".IO ~~ :e {

        %meta<update-date> = "$p/state.json".IO.modified;

        %meta<event> = from-json("$p/state.json".IO.slurp);

        %meta<event><event-str> = event-to-label(%meta<event><action>);

     } else {

        %meta<update-date> = %meta<date>;

        %meta<event> = %( action => "project added" );

        %meta<event><event-str> = event-to-label(%meta<event><action>);

     }

     %meta<releases> = [];

     if "{$p}/releases".IO ~~ :d {

       for dir("{$p}/releases/") -> $r {

          my %data = from-json($r.IO.slurp());

          push %meta<releases>, %data;

          my $r-id; $r.IO.basename ~~ /(\d+) '.'/;

          $r-id = "$0";

          #say $r-id;

          if DateTime.new(Instant.from-posix($r-id)) >= $week-ago {
            $has-recent-release = True
          }

          if %data<data> ~~ /(^^ || \s) '0.0.1' ($$ || \s)/ {
            if DateTime.new(Instant.from-posix($r-id)) >= $week-ago {
              $first-release = True;
            }
          }

       }

     }

    my @reviews;

    for dir("{$p}/reviews/data") -> $r {

      my %meta;

      %meta<data> = $r.IO.slurp;
        
      %meta<data-html> = mini-parser(%meta<data>);
    
      my %rd = review-from-file($r);

      %meta<author> = %rd<author>;

      %meta<date> = %rd<date>;

      %meta<id> = %rd<id>;

      %meta<date-str> = "{%rd<date>}";

      if check-user($user, $token) and $user eq %meta<author> {
        %meta<edit> = True;
      } else {
        %meta<edit> = False
      }

      if "{$p}/reviews/points/{%rd<basename>}".IO ~~ :e {
        %meta<points> = "{$p}/reviews/points/{%rd<basename>}".IO.slurp;
        %meta<points-str> = score-to-label(%meta<points>);

        if %meta<points> == -2 and %meta<date> >= $month-ago {
            $help-wanted = True
        }

      }

      if "{$p}/reviews/ups/{%meta<author>}_{%meta<id>}".IO ~~ :d {
        %meta<ups> = dir("{$p}/reviews/ups/{%meta<author>}_{%meta<id>}").elems;
        if check-user($user, $token) and "{$p}/reviews/ups/{%meta<author>}_{%meta<id>}/{$user}".IO ~~ :e {
          %meta<voted> = True;
        } else {
          %meta<voted> = False;
        }
      } else {
        %meta<ups> = 0;
        %meta<voted> = False;
      }

      %meta<ups-str> = "{uniparse 'TWO HEARTS'} : {%meta<ups>}";

      %meta<replies> = [];

      if "{$p}/reviews/replies/{%rd<basename>}".IO ~~ :d {

        for dir("{$p}/reviews/replies/{%rd<basename>}") -> $rp {

          my %rd = review-from-file($rp);
          
          my %reply;

          %reply<data> = $rp.IO.slurp;

          %reply<data-html> = mini-parser(%reply<data>);

          %reply<author> = %rd<author>;

          %reply<date> = %rd<date>;

          %reply<date-str> = "{%rd<date>}";

          %reply<id> = %rd<id>;

          if check-user($user, $token) and $user eq %reply<author> {
            %reply<edit> = True;
            %meta<replied> = True;
          } else {
            %reply<edit> = False
          }

          push %meta<replies>, %reply;

        }

        %meta<replies> = %meta<replies>.sort({.<date>}).reverse;

      }

      push @reviews, %meta;

    }

    %meta<reviews> = @reviews;

    %meta<first-release> = $first-release;
    %meta<has-recent-release> = $has-recent-release;
    %meta<help-wanted> = $help-wanted;
    %meta<recently-created> = $recently-created;

    %meta<attributes> = []; # this one is reserved for the future
    %meta<attributes-str> = [];

    if $recently-created {
      push %meta<attributes>, "recently-created";
      push %meta<attributes-str>, uniparse "Heavy Asterisk";
    }

    if $help-wanted {
      push %meta<attributes>, "help-wanted";
      push %meta<attributes-str>, uniparse "Raised Hand";
    }

    if $first-release {
      push %meta<attributes>, "first-release";
      push %meta<attributes-str>, uniparse "Slice of Pizza";
    }

    if $has-recent-release {
      push %meta<attributes>, "has-recent-release";   
      push %meta<attributes-str>, uniparse "Package";
    }

    $!project-cache{$p.basename} = %meta; # update cache

    return %meta;

}

method update-cache ($p, %meta) {

    say "project $p - sync cache";

    $!project-cache{$p} = %meta; # update cache

}


} # end of class
