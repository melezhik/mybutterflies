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
      http-root => http-root(),
      user => $user, 
      css => css(), 
      navbar => navbar($user),
      projects => @projects
    }

  }

  get -> 'login-page', :$message {

    template 'templates/login-page.crotmp', {
      http-root => http-root(),
      message => $message,
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

      redirect :permanent, "/login-page";

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
