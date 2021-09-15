use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::WebApp::Template;

use TopsDevops::HTML;

use JSON::Tiny;


my $application = route { 

  get -> :$user is cookie {

    my @projects;

    for dir("{cache-root()}/projects/") -> $p {

      my %meta = from-json("$p/meta.json".IO.slurp);

      %meta<points> = dir("$p/ups/").elems;

      %meta<reviews-cnt> = dir("$p/reviews/").elems;

      if $user and "$p/ups/$user".IO ~~ :e {
        %meta<voted> = True
      } else {
        %meta<voted> = False
      }

      push @projects, %meta;

    }

    template 'templates/main.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css(), 
      navbar => navbar($user),
      projects => @projects.sort({ .<points> }).reverse
    }

  }

  get -> 'project', $project, 'reviews', :$user is cookie {

    my @reviews;

    my $has-user-review = False;

    for dir("{cache-root()}/projects/$project/reviews") -> $r {

      my %meta;

      %meta<data> = $r.IO.slurp;

      %meta<author> = $r.IO.basename;

      %meta<date> = $r.IO.modified;

      %meta<date-str> = DateTime.new(
        $r.IO.modified,
        formatter => { sprintf "%02d:%02d %02d/%02d/%02d", .hour, .minute, .day, .month, .year }
      );

      if $user and $user eq %meta<author> {
        %meta<edit> = True;
        $has-user-review = True;
      } else {
        %meta<edit> = False
      }

      push @reviews, %meta;

    }

    template 'templates/reviews.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css(), 
      navbar => navbar($user),
      project => $project,
      has-user-review => $has-user-review,
      reviews => @reviews.sort({ .<date> }).reverse
    }
  }


  get -> 'project', $project, 'edit-review', :$user is cookie {

    if $user {

      my %review; 

      %review<data> = "{cache-root()}/projects/$project/reviews/$user".IO.slurp;

      template 'templates/edit-review.crotmp', {
        title => title(),
        http-root => http-root(),
        user => $user, 
        css => css(), 
        navbar => navbar($user),
        project => $project,
        review => %review
      }

    } else {

      redirect :permanent, "/login-page?message=you need to sign in to edit reviews";

    }
  }

  post -> 'project', $project, 'edit-review', :$user is cookie {

    if $user {

      request-body -> (:$data) {
        "{cache-root()}/projects/$project/reviews/$user".IO.spurt($data);
        redirect "/";
      };

    } else {

      redirect :permanent, "/login-page?message=you need to sign in to edit reviews";

    }
  }
  get -> 'login-page', :$message {

    template 'templates/login-page.crotmp', {
      title => title(),
      http-root => http-root(),
      message => $message || "sign in using your github account",
      css => css(), 
      navbar => navbar(""),
    }
  }

  get -> 'login' {
    set-cookie 'user', 'melezhik';
    redirect :permanent, "/";
  }

  get -> 'logout' {
    set-cookie 'user', Nil;
    redirect :permanent, "/";
  }

  get -> 'project', $project, 'up', :$user is cookie {

    if $user {

      unless "{cache-root()}/projects/$project/ups/$user".IO ~~ :e {
        say "up {cache-root()}/projects/$project/ups/$user";
        "{cache-root()}/projects/$project/ups/$user".IO.spurt("");
      }
    
      redirect :permanent, "/";

    } else {

      redirect :permanent, "/login-page?message=you need to sign in to vote";

    }
      
  }

  get -> 'project', $project, 'down', :$user is cookie {

    if $user {

      if "{cache-root()}/projects/$project/ups/$user".IO ~~ :e {
        say "down {cache-root()}/projects/$project/ups/$user";
        unlink "{cache-root()}/projects/$project/ups/$user";
      }
    
      redirect :permanent, "/";

    } else {

      redirect :permanent, "/login-page";

    }
      
  }

  get -> 'icons', *@path {

    cache-control :public, :max-age(3000);

    static 'icons', @path;

  }
}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<0.0.0.0>, :port<5000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}
