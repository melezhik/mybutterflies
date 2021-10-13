use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::WebApp::Template;
use Cro::HTTP::Client;

use MyButterfly::Conf;
use MyButterfly::HTML;
use MyButterfly::Utils;

use JSON::Tiny;

my $application = route { 

  get -> :$message, :$filter?, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    my @projects;

    for dir("{cache-root()}/projects/") -> $p {

      my %meta = from-json("$p/meta.json".IO.slurp);

      %meta<points> = dir("$p/ups/").elems;

      %meta<reviews-cnt> = dir("$p/reviews/data").elems;

      if check-user($user, $token) and "$p/ups/$user".IO ~~ :e {
        %meta<voted> = True
      } else {
        %meta<voted> = False
      }

      %meta<date> = "$p/meta.json".IO.modified;

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

      push @projects, %meta;

    }

    my @selected-projects;

    if $filter and $filter eq "new" {

      # week ago

      my $week-ago = DateTime.now() - Duration.new(86400*7);

      @selected-projects = @projects.grep({
        .<date>.DateTime >= $week-ago
      }).sort({ .<date> }).reverse

    } elsif $filter and $filter eq "top" {

      my $week-ago = DateTime.now() - Duration.new(86400*7);

      @selected-projects = @projects.grep({
        .<date>.DateTime >= $week-ago and .<points> >= 1
      }).sort({ .<date> }).reverse

    } else {

      #@selected-projects = @projects.sort({ .<points>, .<reviews-cnt>, .<update-date> }).reverse
      @selected-projects = @projects.sort({ .<update-date> }).reverse

    } 

    template 'templates/main.crotmp', {
      title => title(),
      message => $message,
      http-root => http-root(),
      user => $user, 
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      projects => @selected-projects,
      top => "{uniparse 'ROCKET' }",
      recent => "{uniparse 'HOURGLASS'}",
    }

  }

  get -> 'articles', :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

      my @articles;

      for dir("{cache-root()}/articles/") -> $i {

        my %meta = from-json("{$i}/meta.json".IO.slurp);

        %meta<id> = $i.IO.basename;

        %meta<data> = "{$i}/data.md".IO.slurp;

        %meta<date> = "{$i}/data.md".IO.modified;

        %meta<date-str> = DateTime.new(
          "{$i}/data.md".IO.modified,
          formatter => { sprintf "%02d/%02d/%02d", .day, .month, .year }
        );

        my $ups = 0;

        for dir("{$i}/ups") -> $p {
          $ups++;        
        }

        %meta<points> = $ups;

        %meta<points-str> = "{uniparse 'TWO HEARTS'} : {%meta<points>}";

        push @articles, %meta;

    }

    template 'templates/articles.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      articles => @articles.sort({ .<date> }).reverse
    }
  }

  get -> 'article', $article-id, :$message, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    my %meta = from-json("{cache-root()}/articles/{$article-id}/meta.json".IO.slurp);

    %meta<id> = $article-id;

    %meta<data> = "{cache-root()}/articles/{$article-id}/data.html".IO.slurp;

    %meta<data-short> = %meta<data>.split("\n")[0..5];

    %meta<date> = "{cache-root()}/articles/{$article-id}/data.md".IO.modified;

    %meta<date-str> = DateTime.new(
       "{cache-root()}/articles/{$article-id}/data.md".IO.modified,
       formatter => { sprintf "%02d/%02d/%02d", .day, .month, .year }
    );

    my $ups = 0;

    for dir("{cache-root()}/articles/{$article-id}/ups") -> $p {
       $ups++;        
    }

    %meta<points> = $ups;

    %meta<points-str> = "{uniparse 'TWO HEARTS'}: {%meta<points>}";

    if check-user($user, $token) and "{cache-root()}/articles/{$article-id}/ups/$user".IO ~~ :e {
      %meta<voted> = True
    } else {
      %meta<voted> = False
    }

    template 'templates/article.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css($theme),
      message => $message, 
      navbar => navbar($user, $token, $theme),
      article => %meta
    }

  }


  get -> 'article', $article-id, 'up', :$user is cookie, :$token is cookie  {

    if check-user($user, $token) == True {

      unless "{cache-root()}/articles/{$article-id}/ups/$user".IO ~~ :e {
        say "up {cache-root()}/articles/{$article-id}/ups/$user";
        "{cache-root()}/articles/{$article-id}/ups/$user".IO.spurt("");
      }
    
      redirect :see-other, "{http-root()}/article/{$article-id}?message=article upvoted";

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to upvote article";

    }
      
  }

  get -> 'article', $article-id, 'down', :$user is cookie, :$token is cookie {

    if check-user($user, $token) == True {

      if "{cache-root()}/articles/{$article-id}/ups/$user".IO ~~ :e {
        say "down {cache-root()}/articles/{$article-id}/ups/$user";
        unlink "{cache-root()}/articles/{$article-id}/ups/$user".IO;
      }
    
      redirect :see-other, "{http-root()}/article/{$article-id}?message=article downvoted";

    } else {

      redirect :see-other, "{http-root()}/login-page";

    }
      
  }
  get -> 'project', $project, 'reviews', :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    my @reviews;

    my %project-meta = from-json("{cache-root()}/projects/$project/meta.json".IO.slurp);

    %project-meta<add_by> ||= "melezhik";

    %project-meta<points> = dir("{cache-root()}/projects/$project/ups/").elems;

    %project-meta<reviews-cnt> = dir("{cache-root()}/projects/$project/reviews/data").elems;

    if check-user($user, $token) and "{cache-root()}/projects/$project/ups/$user".IO ~~ :e {
      %project-meta<voted> = True
    } else {
      %project-meta<voted> = False
    }

    for dir("{cache-root()}/projects/$project/reviews/data") -> $r {

      my %meta;

      %meta<data> = $r.IO.slurp;

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

      if "{cache-root()}/projects/$project/reviews/points/{%rd<basename>}".IO ~~ :e {
        %meta<points> = "{cache-root()}/projects/$project/reviews/points/{%rd<basename>}".IO.slurp;
        %meta<points-str> = score-to-label(%meta<points>);
      }

      %meta<replies> = [];

      if "{cache-root()}/projects/$project/reviews/replies/{%rd<basename>}".IO ~~ :d {

        for dir("{cache-root()}/projects/$project/reviews/replies/{%rd<basename>}") -> $rp {

          my %rd = review-from-file($rp);
          
          my %reply;

          %reply<data> = $rp.IO.slurp;

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

    template 'templates/reviews.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      project => $project,
      project-meta => %project-meta,
      reviews => @reviews.sort({ .<date> }).reverse
    }
  }


  get -> 'project', $project, 'edit-review', $review-id = time, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    if check-user($user, $token) {

      my %review; 

      if $review-id ~~ /^^ \d+ $$/ and "{cache-root()}/projects/$project/reviews/data/{$user}_{$review-id}".IO ~~ :e {
        %review<data> = "{cache-root()}/projects/$project/reviews/data/{$user}_{$review-id}".IO.slurp;
        say "read data from {cache-root()}/projects/$project/reviews/data/{$user}_{$review-id}";
      } else {
        %review<data> = ""
      }

      if $review-id ~~ /^^ \d+ $$/ and "{cache-root()}/projects/$project/reviews/points/{$user}_{$review-id}".IO ~~ :e {
        %review<points> = "{cache-root()}/projects/$project/reviews/points/{$user}_{$review-id}".IO.slurp;
        say "read points from {cache-root()}/projects/$project/reviews/points/{$user}_{$review-id} - {%review<points>}";
      }

      template 'templates/edit-review.crotmp', {
        title => title(),
        http-root => http-root(),
        user => $user, 
        css => css($theme), 
        navbar => navbar($user, $token, $theme),
        project => $project,
        review => %review,
        review-id => $review-id,
      }

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to create or edit reviews";

    }
  }

  post -> 'project', $project, 'edit-review', $review-id, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    if check-user($user, $token) {

      request-body -> (:$data, :$points) {

        "{cache-root()}/projects/$project/reviews/data/{$user}_{$review-id}".IO.spurt($data);

        my %review; 

        say "points - $points";

        if defined($points) {
          say "update points {cache-root()}/projects/$project/reviews/points/{$user}_{$review-id} - $points";
          "{cache-root()}/projects/$project/reviews/points/{$user}_{$review-id}".IO.spurt($points);
          %review<points> = $points;
        } else {
          if "{cache-root()}/projects/$project/reviews/points/{$user}_{$review-id}".IO ~~ :e {
            %review<points> = "{cache-root()}/projects/$project/reviews/points/{$user}_{$review-id}".IO.slurp;
            say "read points from {cache-root()}/projects/$project/reviews/points/{$user}_{$review-id} - {%review<points>}";
          }
        }

         created "/project/$project/edit-review/{$review-id}";

         if $points and $points == -1 {
            touch-project($project, %( action => "release create") );
         } elsif $points == 0 {
            touch-project($project, %( action => "comment create") );
         } elsif $points >= 1 {
            touch-project($project, %( action => "review create") );
         } else {
            touch-project($project, %( action => "review create") );
         }
        

         %review<data> = $data;
         
         template 'templates/edit-review.crotmp', {
           title => title(),
           http-root => http-root(),
           user => $user,
           message => "review updated", 
           css => css($theme), 
           navbar => navbar($user, $token, $theme),
           project => $project,
           review => %review,
           review-id => "$review-id", 
        }

      };

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to create or edit reviews";

    }
  }

  get -> 'project', $project, 'edit-reply', $review-author, $review-id, $reply-id = time, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    if check-user($user, $token) {

      my %reply; 

      if "{cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}".IO ~~ :e {
        %reply<data> = "{cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}".IO.slurp;
        say "read data from {cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}";
      } else {
        %reply<data> = ""
      }

      template 'templates/edit-reply.crotmp', {
        title => title(),
        http-root => http-root(),
        user => $user, 
        css => css($theme), 
        navbar => navbar($user, $token, $theme),
        review-author => $review-author,
        review-id => $review-id,
        reply-id => $reply-id,
        project => $project,
        reply => %reply
      }

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to create or edit replies";

    }
  }

  post -> 'project', $project, 'edit-reply', $review-author, $review-id, $reply-id, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    if check-user($user, $token) {

       request-body -> (:$data) {

        mkdir "{cache-root()}/projects/$project/reviews/replies/";

        mkdir "{cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}";

        "{cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}".IO.spurt($data);

        my %reply =  %( data => $data ) ; 

        created "/project/$project/edit-reply";

        touch-project($project, %( action => "reply create") );

        template 'templates/edit-reply.crotmp', {
          title => title(),
          http-root => http-root(),
          user => $user, 
          css => css($theme), 
          navbar => navbar($user, $token, $theme),
          project => $project,
          review-author => $review-author,
          review-id => $review-id,
          reply-id => $reply-id,
          message => "reply updated", 
          reply => %reply

        }

      };

      #redirect :see-other, "{http-root()}/login-page?message=OK";

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to create or edit replies";

    }

  }

  get -> 'add-project', :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    if check-user($user, $token) {

      template 'templates/add-project.crotmp', {
        title => title(),
        http-root => http-root(),
        user => $user,
        css => css($theme), 
        navbar => navbar($user, $token, $theme),
      }

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to add projects";

    }

  }

  post -> 'add-project', :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

      my $msg; my %project-data;

      if check-user($user, $token) {

        request-body -> (:$project, :$description, :$url, :$language, :$category) {

          %project-data =  %(           
              project => $project,
              description => $description,
              url => $url,
              language => $language,
              category => $category
          );

          my %status = validate-project-data %project-data;

          if %status<status>  eq True {

            %project-data<add_by> = $user;
  
            mkdir "{cache-root}/projects/$project";
            mkdir "{cache-root}/projects/$project/reviews";
            mkdir "{cache-root}/projects/$project/reviews/data";
            mkdir "{cache-root}/projects/$project/reviews/points";
            mkdir "{cache-root}/projects/$project/ups";

            if "{cache-root}/projects/$project/meta.json".IO ~~ :e {
              $msg = "project already exists";
            } else {
              "{cache-root}/projects/$project/meta.json".IO.spurt(to-json(%project-data));
              $msg = "project added";
              touch-project($project, %( action => "project create") );
        }
        } else {
          $msg = %status<message>
        }

      }

    } else {

      $msg = "you need to sign in to add projects";

    }

    template 'templates/add-project.crotmp', {
      title => title(),
      http-root => http-root(),
      message => $msg,
      user => $user,
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      %project-data,
    }
  }

  get -> 'about', :$message?, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    template 'templates/about.crotmp', {
      title => title(),
      http-root => http-root(),
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      message => $message,
      butterfly => "{uniparse 'BUTTERFLY'}"
    }
  }

  get -> 'contest', :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    template 'templates/contest.crotmp', {
      title => title(),
      http-root => http-root(),
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      butterfly => "{uniparse 'BUTTERFLY'}"
    }
  }

  get -> 'contest-list', :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    my %list = from-json("{cache-root()}/contest/list.json".IO.slurp);

    for %list.keys -> $cnt {
      for %list{$cnt}<> -> $p {
          my %meta = from-json("{cache-root()}/projects/{$p<id>}/meta.json".IO.slurp);
          $p<meta> = %meta;
          $p<meta><add_by> ||= "melezhik";
      }
    }

    template 'templates/contest-list.crotmp', {
      title => title(),
      http-root => http-root(),
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      butterfly => "{uniparse 'BUTTERFLY'}",
      star => "{uniparse 'BLACK STAR'}",
      list => %list
    }
  }
  get -> 'oauth2', :$state, :$code {

      say "request token from https://github.com/login/oauth/access_token";

      my $resp = await Cro::HTTP::Client.get: 'https://github.com/login/oauth/access_token',
        headers => [
          "Accept" => "application/json"
        ],
        query => { 
          redirect_uri => "https://mybf.io/oauth2",
          client_id => %*ENV<OAUTH_CLIENT_ID>,
          client_secret => %*ENV<OAUTH_CLIENT_SECRET>,
          code => $code,
          state => $state,    
        };


      my $data = await $resp.body-text();

      my %data = from-json($data);

      say "response recieved - {%data.perl} ... ";

      if %data<access_token>:exists {

        say "token recieved - {%data<access_token>} ... ";

        my $resp = await Cro::HTTP::Client.get: 'https://api.github.com/user',
          headers => [
            "Accept" => "application/vnd.github.v3+json",
            "Authorization" => "token {%data<access_token>}"
          ];

        my $data2 = await $resp.body-text();
  
        my %data2 = from-json($data2);

        say "set user login to {%data2<login>}";

        my $date = DateTime.now.later(hours => 10);

        set-cookie 'user', %data2<login>, http-only => True, expires => $date;

        mkdir "{cache-root()}/users";

        mkdir "{cache-root()}/users/{%data2<login>}";

        mkdir "{cache-root()}/users/{%data2<login>}/tokens";

        "{cache-root()}/users/{%data2<login>}/meta.json".IO.spurt($data2);

        my $tk = gen-token();

        "{cache-root()}/users/{%data2<login>}/tokens/{$tk}".IO.spurt("");

        say "set user token to {$tk}";

        set-cookie 'token', $tk, http-only => True, expires => $date;

        redirect :see-other, "{http-root()}/?message=user logged in";

      } else {

        redirect :see-other, "{http-root()}/?message=issues with login";

      }

       
  } 

  get -> 'set-theme', :$message, :$theme, :$user is cookie, :$token is cookie {

    set-cookie 'theme', $theme, http-only => True;

    redirect :see-other, "{http-root()}/?message=theme set to {$theme}";

  }

  get -> 'login-page', :$message, :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    template 'templates/login-page.crotmp', {
      title => title(),
      http-root => http-root(),
      message => $message || "sign in using your github account",
      css => css($theme),
      theme => $theme,
      navbar => navbar($user, $token, $theme),
    }
  }

  get -> 'login' {

    if %*ENV<MB_DEBUG_MODE> {

        say "MB_DEBUG_MODE is set, you need to set MB_DEBUG_USER var as well"
          unless %*ENV<MB_DEBUG_USER>;

        my $user = %*ENV<MB_DEBUG_USER>;

        say "set user login to {$user}";

        set-cookie 'user', $user;

        mkdir "{cache-root()}/users";

        mkdir "{cache-root()}/users/{$user}";

        mkdir "{cache-root()}/users/{$user}/tokens";

        "{cache-root()}/users/{$user}/meta.json".IO.spurt('{}');

        my $tk = gen-token();

        "{cache-root()}/users/$user/tokens/{$tk}".IO.spurt("");

        say "set user token to {$tk}";

        set-cookie 'token', $tk;

        redirect :see-other, "{http-root()}/?message=user logged in";

    } else  {

      redirect :see-other,
        "https://github.com/login/oauth/authorize?client_id={%*ENV<OAUTH_CLIENT_ID>}&state={%*ENV<OAUTH_STATE>}"
    }
  }

  get -> 'logout', :$user is cookie, :$token is cookie {

    set-cookie 'user', Nil;
    set-cookie 'token', Nil;

    if ( $user && $token && "{cache-root()}/users/{$user}/tokens/{$token}".IO ~~ :e ) {

      unlink "{cache-root()}/users/{$user}/tokens/{$token}";
      say "unlink user token - {cache-root()}/users/{$user}/tokens/{$token}";

    }

    redirect :see-other, "{http-root()}/?message=user logged out";
  }

  get -> 'project', $project, 'up', :$user is cookie, :$token is cookie, :$theme is cookie = "light" {

    if check-user($user, $token) == True {

      unless "{cache-root()}/projects/$project/ups/$user".IO ~~ :e {
        say "up {cache-root()}/projects/$project/ups/$user";
        "{cache-root()}/projects/$project/ups/$user".IO.spurt("");
         touch-project($project, %( action => "project upvote") );

      }
    
      redirect :see-other, "{http-root()}/?message=project upvoted";

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to upvote projects";

    }
      
  }

  get -> 'project', $project, 'down', :$user is cookie, :$token is cookie {

    if check-user($user, $token) {

      if "{cache-root()}/projects/$project/ups/$user".IO ~~ :e {
        say "down {cache-root()}/projects/$project/ups/$user";
        touch-project($project, %( action => "project downvote") );
        unlink "{cache-root()}/projects/$project/ups/$user";
      }
    
      redirect :see-other, "{http-root()}/?message=project downvoted";

    } else {

      redirect :see-other, "{http-root()}/login-page";

    }
      
  }

  get -> 'icons', *@path {

    cache-control :public, :max-age(3000);

    static 'icons', @path;

  }

  get -> 'js', *@path {

    cache-control :public, :max-age(3000);

    static 'js', @path;

  }
}

(.out-buffer = False for $*OUT, $*ERR;);

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<0.0.0.0>, :port<2000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}
