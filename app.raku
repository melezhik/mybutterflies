use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::WebApp::Template;
use Cro::HTTP::Client;

use MyButterfly::HTML;

use JSON::Tiny;


my $application = route { 

  get -> :$message, :$user is cookie, :$token is cookie {

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

      push @projects, %meta;

    }

    template 'templates/main.crotmp', {
      title => title(),
      message => $message,
      http-root => http-root(),
      user => $user, 
      css => css(), 
      navbar => navbar($user, $token),
      projects => @projects.sort({ .<points> }).reverse
    }

  }

  get -> 'articles', :$user is cookie, :$token is cookie {

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

        %meta<points-str> = "{uniparse 'TWO HEARTS'}: {%meta<points>}";

        push @articles, %meta;

    }

    template 'templates/articles.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css(), 
      navbar => navbar($user, $token),
      articles => @articles.sort({ .<date> }).reverse
    }
  }

  get -> 'article', $article-id, :$message, :$user is cookie, :$token is cookie {

    my %meta = from-json("{cache-root()}/articles/{$article-id}/meta.json".IO.slurp);

    %meta<id> = $article-id;

    %meta<data> = "{cache-root()}/articles/{$article-id}/data.md".IO.slurp;

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
      css => css(),
      message => $message, 
      navbar => navbar($user, $token),
      article => %meta
    }

  }


  get -> 'article', $article-id, 'up', :$user is cookie, :$token is cookie {

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
  get -> 'project', $project, 'reviews', :$user is cookie, :$token is cookie {

    my @reviews;

    my $has-user-review = False;

    my %project-meta;

    %project-meta<points> = dir("{cache-root()}/projects/$project/ups/").elems;

    %project-meta<reviews-cnt> = dir("{cache-root()}/projects/$project/reviews/data").elems;

    for dir("{cache-root()}/projects/$project/reviews/data") -> $r {

      my %meta;

      %meta<data> = $r.IO.slurp;

      %meta<author> = $r.IO.basename;

      %meta<date> = $r.IO.modified;

      %meta<date-str> = DateTime.new(
        $r.IO.modified,
        formatter => { sprintf "%02d:%02d %02d/%02d/%02d", .hour, .minute, .day, .month, .year }
      );

      if check-user($user, $token) and $user eq %meta<author> {
        %meta<edit> = True;
        $has-user-review = True;
      } else {
        %meta<edit> = False
      }

      if "{cache-root()}/projects/$project/reviews/points/{%meta<author>}".IO ~~ :e {
        %meta<points> = "{cache-root()}/projects/$project/reviews/points/{%meta<author>}".IO.slurp;
        %meta<points-str> = "{uniparse 'BUTTERFLY'}" x %meta<points>;
      }

      push @reviews, %meta;

    }

    template 'templates/reviews.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css(), 
      navbar => navbar($user, $token),
      project => $project,
      project-meta => %project-meta,
      has-user-review => $has-user-review,
      reviews => @reviews.sort({ .<date> }).reverse
    }
  }


  get -> 'project', $project, 'edit-review', :$user is cookie, :$token is cookie {

    if check-user($user, $token) {

      my %review; 

      if "{cache-root()}/projects/$project/reviews/data/$user".IO ~~ :e {
        %review<data> = "{cache-root()}/projects/$project/reviews/data/$user".IO.slurp;
        say "read data from {cache-root()}/projects/$project/reviews/data/$user";
      } else {
        %review<data> = ""
      }

      if "{cache-root()}/projects/$project/reviews/points/$user".IO ~~ :e {
        %review<points> = "{cache-root()}/projects/$project/reviews/points/$user".IO.slurp;
        say "read points from {cache-root()}/projects/$project/reviews/points/$user - {%review<points>}";
      }

      template 'templates/edit-review.crotmp', {
        title => title(),
        http-root => http-root(),
        user => $user, 
        css => css(), 
        navbar => navbar($user, $token),
        project => $project,
        review => %review
      }

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to edit or write reviews";

    }
  }

  post -> 'project', $project, 'edit-review', :$user is cookie, :$token is cookie {

    if check-user($user, $token) {

      request-body -> (:$data, :$points) {

        "{cache-root()}/projects/$project/reviews/data/$user".IO.spurt($data);

        my %review; 

        say "points - $points";

        if $points {
          say "update points {cache-root()}/projects/$project/reviews/points/$user - $points";
          "{cache-root()}/projects/$project/reviews/points/$user".IO.spurt($points);
          %review<points> = $points;
        } else {

          if "{cache-root()}/projects/$project/reviews/points/$user".IO ~~ :e {
            %review<points> = "{cache-root()}/projects/$project/reviews/points/$user".IO.slurp;
            say "read points from {cache-root()}/projects/$project/reviews/points/$user - {%review<points>}";
          }

        }

         created "/project/$project/edit-review";

         %review<data> = $data;
         
         template 'templates/edit-review.crotmp', {
           title => title(),
           http-root => http-root(),
           user => $user,
           message => "review updated", 
           css => css(), 
           navbar => navbar($user, $token),
           project => $project,
           review => %review
        }

      };

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to edit reviews";

    }
  }

  get -> 'add-project', :$user is cookie, :$token is cookie {
    template 'templates/add-project.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user,
      css => css(), 
      navbar => navbar($user, $token),
    }
  }

  post -> 'add-project', :$user is cookie, :$token is cookie {

      my $msg;

      request-body -> (:$project, :$description, :$url, :$language, :$category) {

        if $project ~~ /^^ <[ \w \. \d : ]>+ $$/ 
          and $description ~~ /^^ <[ \w \. \s \d \/ \\ \, \- \# ~ ]>+ $$/ 
          and $url ~~ /^^ <[ \w \. \/ \d : \. \- ~]>+ $$/
          and $language ~~ /^^ <[ \w \d \+ ]>+ $$/ 
          and $category ~~ /^^ <[ \w \d \s]>+ $$/ 
        {

          mkdir "{cache-root}/projects/$project";
          mkdir "{cache-root}/projects/$project/reviews";
          mkdir "{cache-root}/projects/$project/reviews/data";
          mkdir "{cache-root}/projects/$project/reviews/points";
          mkdir "{cache-root}/projects/$project/ups";

          if "{cache-root}/projects/$project/meta.json".IO ~~ :e {
            $msg = "project already exits";
          } else {
            "{cache-root}/projects/$project/meta.json".IO.spurt(qq:to/END/);
            \{
              \"project\" : \"$project\",
              \"description\" : \"$description\",
              \"category\" : \"$category\",
              \"language\" : \"$language\",
              \"url\" : "$url\"
            \}
            END
            $msg = "project added"
          }
        } else {
          $msg = "incorrect input data"
        }

      }

      template 'templates/add-project.crotmp', {
        title => title(),
        http-root => http-root(),
        message => $msg,
        user => $user,
        css => css(), 
        navbar => navbar($user, $token),
      }

  }

  get -> 'about', :$user is cookie, :$token is cookie {

    template 'templates/about.crotmp', {
      title => title(),
      http-root => http-root(),
      css => css(), 
      navbar => navbar($user, $token),
      butterfly => "{uniparse 'BUTTERFLY'}"
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

        my $date = DateTime.now.later(hours => 1);

        set-cookie 'user', %data2<login>, http-only => True, max-age => Duration.new(3600), expires => $date;

        mkdir "{cache-root()}/users";

        mkdir "{cache-root()}/users/{%data2<login>}";

        mkdir "{cache-root()}/users/{%data2<login>}/tokens";

        "{cache-root()}/users/{%data2<login>}/meta.json".IO.spurt($data2);

        my $tk = gen-token();

        "{cache-root()}/users/{%data2<login>}/tokens/{$tk}".IO.spurt("");

        say "set user token to {$tk}";

        set-cookie 'token', $tk, http-only => True, max-age => Duration.new(3600), expires => $date;

        redirect :see-other, "{http-root()}/?message=user logged in";

      } else {

        redirect :see-other, "{http-root()}/?message=issues with login";

      }

       
  } 

  get -> 'login-page', :$message, :$user is cookie, :$token is cookie {

    template 'templates/login-page.crotmp', {
      title => title(),
      http-root => http-root(),
      message => $message || "sign in using your github account",
      css => css(), 
      navbar => navbar($user, $token),
    }
  }

  get -> 'login' {

    if %*ENV<MB_DEBUG_MODE> {

        say "set user login to melezhik";

        set-cookie 'user', "melezhik";

        mkdir "{cache-root()}/users";

        mkdir "{cache-root()}/users/melezhik";

        mkdir "{cache-root()}/users/melezhik/tokens";

        "{cache-root()}/users/melezhik/meta.json".IO.spurt('{}');

        my $tk = gen-token();

        "{cache-root()}/users/melezhik/tokens/{$tk}".IO.spurt("");

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

  get -> 'project', $project, 'up', :$user is cookie, :$token is cookie {

    if check-user($user, $token) == True {

      unless "{cache-root()}/projects/$project/ups/$user".IO ~~ :e {
        say "up {cache-root()}/projects/$project/ups/$user";
        "{cache-root()}/projects/$project/ups/$user".IO.spurt("");
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

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<0.0.0.0>, :port<2000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}
