use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::WebApp::Template;

use TopsDevops::HTML;


my $application = route { 

  get -> {

    template 'templates/main.crotmp', {
      css => css(), 
      navbar => navbar(),
      projects => [
        %(
          project => "cro",
          description => "elegant reactive services in Raku",
          category => "web",
          language => "Raku",
          rating => %( 
            'sssss' => 100,
            'ssss' => 50,
            'sss' => 0,
            'ss' => 0,
            's' => 0,
          ),
          reviews-cnt => "100"
        ),
      ] 
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
