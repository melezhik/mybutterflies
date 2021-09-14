use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::WebApp::Template;

use TopsDevops::HTML;


my $application = route { 

  get -> :$user is cookie {

    template 'templates/main.crotmp', {
      user => $user, 
      css => css(), 
      navbar => navbar($user),
      projects => [
        %(
          project => "cro",
          description => "elegant reactive services in Raku",
          category => "web",
          language => "Raku",
          points => "1000",
          reviews-cnt => 10,
          url => "http://cro.services"
        ),
        %(
          project => "ansible",
          description => "Red Hat Ansible Automation Platform",
          category => "automation",
          language => "Python",
          points => "100",
          reviews-cnt => 2,
          url => "https://github.com/ansible/ansible"
        ),        
      ] 
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
}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<0.0.0.0>, :port<5000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}
