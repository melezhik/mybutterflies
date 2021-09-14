use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::WebApp::Template;

use TopsDevops::HTML;

use JSON::Tiny;


my $application = route { 

  my @projects;

  for dir("{cache-root()}/projects/") -> $p {

    my %meta = from-json("$p/meta.json".IO.slurp);

    %meta<points> = dir("$p/ups/").elems;

    %meta<reviews-cnt> = dir("$p/reviews/").elems;

    push @projects, %meta;

  }

  get -> :$user is cookie {

    template 'templates/main.crotmp', {
      http-root => http-root(),
      user => $user, 
      css => css(), 
      navbar => navbar($user),
      projects => @projects
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
        say "bump {cache-root()}/projects/$project/ups/$user";
        "{cache-root()}/projects/$project/ups/$user".IO.spurt("");
      }
    
      redirect :permanent, "/";

    } else {

      redirect :permanent, "/login";

    }
      
  }

}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<0.0.0.0>, :port<5000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}
