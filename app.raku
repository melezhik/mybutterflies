use Cro::HTTP::Server;
use Cro::HTTP::Router;
use Cro::WebApp::Template;
use Cro::HTTP::Client;

use MyButterfly::Conf;
use MyButterfly::HTML;
use MyButterfly::Utils;
use MyButterfly::Data;

use JSON::Tiny;
use Text::Markdown;

my $project-data = MyButterfly::Data.new();

my $application = route { 

  get -> :$message, :$filter?, :$language?, :$tags?, :$category?, :$user is cookie, :$token is cookie, :$lang is cookie,  :$theme is cookie = default-theme() {

    my @projects;

    if $language and $language ne 'Any' {

      my $date = DateTime.now.later(years => 100);
      set-cookie 'lang', $language, http-only => True, expires => $date;

    }


    if $language and $language eq 'Any' {
      set-cookie 'lang', Nil
    }

    my $lang-filter = $language || $lang;

    for dir("{cache-root()}/projects/") -> $p {

      my %meta;

      %meta = $project-data.project-from-file($p,$user,$token);
      
      if $lang-filter and $lang-filter ne "Any" {
        next unless $lang-filter ~~ any %meta<language><>
      }

      if $category and $category ne "Any" {
        next unless $category ~~ any %meta<category><>
      }

      push @projects, %meta;

    }

    my @selected-projects;

    if $filter and $filter eq "new" {

      # 3 days ago

      my $time-ago = DateTime.now() - Duration.new(60*60*24*3);

      @selected-projects = @projects.grep({
        .<date>.DateTime >= $time-ago
      }).sort({ .<update-date> }).reverse

    } elsif $filter and $filter eq "top" {

      # week ago

      my $week-ago = DateTime.now() - Duration.new(60*60*24*7);

      @selected-projects = @projects.grep({
        .<update-date>.DateTime >= $week-ago
      }).sort({ .<update-date> }).reverse

    } else {

      #@selected-projects = @projects.sort({ .<points>, .<reviews-cnt>, .<update-date> }).reverse
      @selected-projects = @projects.sort({ .<update-date> }).reverse

    } 

    if $tags {
      @selected-projects = @selected-projects.grep({ 
        my @tags = .<tags><>;
        my $select = False;
        LINE: for (split ",", $tags)<> -> $t {
          if grep $t, @tags {
            $select = True;
            last LINE;
          }
        }
        $select == True;
      });
    }

    template 'templates/main.crotmp', {
      title => title(),
      message => $message,
      http-root => http-root(),
      user => $user, 
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      projects => @selected-projects,
      all => "{uniparse 'Cookie'}",
      top => "{uniparse 'ROCKET' }",
      created => "{uniparse 'Heavy Asterisk'}",
      recent => "{uniparse 'HOURGLASS'}",
      first-release => "{uniparse 'Slice of Pizza'}",
      release => "{uniparse 'PACKAGE'}",
      help-wanted => "{uniparse 'Raised Hand'}",
      settings => "{uniparse 'GEAR'}",
      cnt-users => "{cache-root()}/users.cnt".IO.slurp,
    }

  }

  get -> 'articles', :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

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

  get -> 'article', $article-id, :$message, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    my %meta = from-json("{cache-root()}/articles/{$article-id}/meta.json".IO.slurp);

    %meta<id> = $article-id;

    my $md = parse-markdown-from-file("{cache-root()}/articles/{$article-id}/data.md");

    %meta<data> = $md.to_html;

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


  get -> 'review', $project, $author, $review-id, 'up', :$user is cookie, :$token is cookie  {

    if check-user($user, $token) == True {

      unless "{cache-root()}/projects/$project/reviews/ups/{$author}_{$review-id}/$user".IO ~~ :e {
        mkdir "{cache-root()}/projects/$project/reviews/ups/";
        mkdir "{cache-root()}/projects/$project/reviews/ups/{$author}_{$review-id}";
        say "up {cache-root()}/projects/$project/reviews/ups/{$author}_{$review-id}/$user";
        "{cache-root()}/projects/$project/reviews/ups/{$author}_{$review-id}/$user".IO.spurt("");
      }
    
      redirect :see-other, "{http-root()}/project/$project/reviews?message=review upvoted";

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to upvote reviews";

    }
      
  }

get -> 'review', $project, $author, $review-id, 'down', :$user is cookie, :$token is cookie  {

    if check-user($user, $token) == True {

      if "{cache-root()}/projects/$project/reviews/ups/{$author}_{$review-id}/$user".IO ~~ :e {
        say "downvote {cache-root()}/projects/$project/reviews/ups/{$author}_{$review-id}/$user";
        unlink "{cache-root()}/projects/$project/reviews/ups/{$author}_{$review-id}/$user";
      }
    
      redirect :see-other, "{http-root()}/project/$project/reviews?message=review downvoted";

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to downvote reviews";

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
  get -> 'project', $project, 'reviews', :$message?, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    my %meta = $project-data.project-from-file("{cache-root()}/projects/$project".IO,$user,$token);

    template 'templates/reviews.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user, 
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      project => $project,
      project-meta => %meta,
      reviews => %meta<reviews>.sort({ .<date> }).reverse,
      message => $message, 
      link => uniparse("Link Symbol"),  
    }
  }


  get -> 'project', $project, 'edit-review', $review-id = time, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

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

  post -> 'project', $project, 'edit-review', $review-id, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    if check-user($user, $token) {

      request-body -> (:$data, :$points) {

        if "{cache-root()}/projects/$project/reviews/data/{$user}_{$review-id}".IO ~~ :e {

          "{cache-root()}/projects/$project/reviews/data/{$user}_{$review-id}".IO.spurt($data);

        } else {

            my %meta = $project-data.project-from-file("{cache-root()}/projects/$project".IO,$user,$token);

            "{cache-root()}/projects/$project/reviews/data/{$user}_{$review-id}".IO.spurt($data);

            add-notification(
              %meta<add_by>,
              "op_review_{$user}_{$review-id}",
              %( 
                project => $project,
                author => $user, 
                type => "owner-project-review", 
                date => "{DateTime.now}",
                review-id => $review-id,
                review-author => $user,
              )
            );

            add-irc-bot-notification(
              "butterflieble",
              "op_review_{$user}_{$review-id}",
              %( 
                project => $project,
                project-meta => %meta,
                author => $user, 
                type => "owner-project-review", 
                date => "{DateTime.now}",
                review-id => $review-id,
                review-author => $user,
              )
            );

        }

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

         if $points and $points != -1 { 
          unlink "{cache-root()}/projects/$project/releases/{$review-id}.json"
          if "{cache-root()}/projects/$project/releases/{$review-id}.json".IO ~~ :f;
         }
 
         if $points and $points == -1 {
            touch-project($project, $user, %( action => "release create") );
            create-release($project, $review-id, %( data => $data ) );
         } elsif $points == -2 {
            touch-project($project, $user, %( action => "help wanted create") );
         } elsif $points == 0 {
            touch-project($project, $user, %( action => "comment create") );
         } elsif $points >= 1 {
            touch-project($project, $user, %( action => "review create") );
         } else {
            touch-project($project, $user, %( action => "review create") );
         }
        
         %review<data> = $data;

         for ($data ~~ m:g/(\s || ^^)  "@" (<[ \w \d \_ \- \. ]>+) (\s || $$ || ':' || '!' || '?' || ',') /).map({ "{$_[1]}" }).unique -> $i { 
          unless "{cache-root()}/users/{$i}/notifications/mentions/reviews/{$user}_{$review-id}".IO ~~ :f {
            mkdir "{cache-root()}/users/{$i}/notifications/mentions/";
            mkdir "{cache-root()}/users/{$i}/notifications/mentions/reviews/";
            "{cache-root()}/users/{$i}/notifications/mentions/reviews/{$user}_{$review-id}".IO.spurt("");
            add-notification(
              $i,
              "review_mention_{$user}_{$review-id}",
              %( 
                project => $project,
                author => $user, 
                type => "review-mention", 
                date => "{DateTime.now}",
                review-id => $review-id,
                review-author => $user,
              )
            );          
          }
         }         
        
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

  get -> 'project', $project, 'edit-reply', $review-author, $review-id, $reply-id = time, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

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

  post -> 'project', $project, 'edit-reply', $review-author, $review-id, $reply-id, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    if check-user($user, $token) {

       request-body -> (:$data) {

        mkdir "{cache-root()}/projects/$project/reviews/replies/";

        mkdir "{cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}";

        unless "{cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}".IO ~~ :e {

          add-notification(
            $review-author,
            "review_reply_{$review-id}_{$reply-id}",
            %( 
              project => $project,
              author => $user, 
              type => "review-reply", 
              date => "{DateTime.now}",
              review-id => $review-id,
              reply-id => $reply-id,
              review-author => $review-author,
            )
          );

          my %meta = $project-data.project-from-file("{cache-root()}/projects/$project".IO,$user,$token);

          add-notification(
            %meta<add_by>,
            "op_review_reply_{$review-id}_{$reply-id}",
            %( 
              project => $project,
              author => $user, 
              type => "owner-project-reply", 
              date => "{DateTime.now}",
              review-id => $review-id,
              reply-id => $reply-id,
              review-author => $review-author,
            )
          );

        }

        for ($data ~~ m:g/(\s || ^^)  "@" (<[ \w \d \_ \- \. ]>+) (\s || $$ || ':' || '!' || '?' || ',' ) /).map({ "{$_[1]}" }).unique -> $i { 
          unless "{cache-root()}/users/{$i}/notifications/mentions/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}/{$i}".IO ~~ :f {
            mkdir "{cache-root()}/users/{$i}/notifications/mentions/";
            mkdir "{cache-root()}/users/{$i}/notifications/mentions/reviews/";
            mkdir "{cache-root()}/users/{$i}/notifications/mentions/reviews/replies";
            mkdir "{cache-root()}/users/{$i}/notifications/mentions/reviews/replies/{$review-author}_{$review-id}";
            mkdir "{cache-root()}/users/{$i}/notifications/mentions/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}";
            "{cache-root()}/users/{$i}/notifications/mentions/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}/{$i}".IO.spurt("");
              add-notification(
                $i,
                "review_reply_mention_{$review-author}_{$review-id}_{$user}_{$reply-id}",
                %( 
                  project => $project,
                  author => $user, 
                  type => "review-reply-mention", 
                  date => "{DateTime.now}",
                  review-id => $review-id,
                  reply-id => $reply-id,
                  review-author => $review-author,
                )
              );          
          }
        }

        "{cache-root()}/projects/$project/reviews/replies/{$review-author}_{$review-id}/{$user}_{$reply-id}".IO.spurt($data);

        my %reply =  %( data => $data ) ; 

        created "/project/$project/edit-reply";

        touch-project($project, $user, %( action => "reply create") );

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

  get -> 'customize', :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    template 'templates/customize.crotmp', {
      title => title(),
      http-root => http-root(),
      user => $user,
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
    }

  }

  get -> 'add-project', :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    if check-user($user, $token) {

      template 'templates/add-project.crotmp', {
        title => title(),
        http-root => http-root(),
        user => $user,
        css => css($theme), 
        navbar => navbar($user, $token, $theme),
        languages => array-to-html-option("",languages()),
        categories => array-to-html-option("",categories()),
      }

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to add projects";

    }

  }

  post -> 'add-project', :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

      my $msg; 

      my %project-data;

      if check-user($user, $token) {

        request-body -> (:$project, :$description, :$url, :$language, :$category, :$tags?) {

          %project-data =  %(           
            project => $project,
            description => $description,
            url => $url,
            language => $language,
            category => $category,
            tags => $tags ?? ((split ",", $tags).map({ $_.subst(/\s/, "", :g ) })) !! [],
            creation-date => "{DateTime.now}",
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
              touch-project($project, $user, %( action => "project create") );
            }
        } else {
          $msg = %status<message>
        }

      }

    } else {

      $msg = "you need to sign in to add projects";

    }

    %project-data<tags> = join ", ", %project-data<tags><>;

    template 'templates/add-project.crotmp', {
      title => title(),
      http-root => http-root(),
      message => $msg,
      user => $user,
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      %project-data,
      languages => array-to-html-option(%project-data<language>||"",languages()),
      categories => array-to-html-option(%project-data<category>||"",categories()),
    }
  }

  get -> 'about', :$message?, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    template 'templates/about.crotmp', {
      title => title(),
      http-root => http-root(),
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      message => $message,
      butterfly => "{uniparse 'BUTTERFLY'}"
    }
  }

  get -> 'contest', :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    template 'templates/contest.crotmp', {
      title => title(),
      http-root => http-root(),
      css => css($theme), 
      navbar => navbar($user, $token, $theme),
      butterfly => "{uniparse 'BUTTERFLY'}"
    }
  }

  get -> 'contest-list', :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    my %list = from-json("{cache-root()}/contest/list.json".IO.slurp);

    for %list.keys -> $cnt {

      for %list{$cnt}<> -> $p {

          my %meta = from-json("{cache-root()}/projects/{$p<id>}/meta.json".IO.slurp);

          $p<meta> = %meta;

          $p<meta><add_by> ||= "melezhik";

          $p<meta><points> = dir("{cache-root()}/projects/{$p<id>}/ups/").elems;

          $p<meta><reviews-cnt> = dir("{cache-root()}/projects/{$p<id>}/reviews/data").elems;

          $p<meta><points-delta> = $p<meta><points> - $p<score><points>;

          $p<meta><reviews-delta> = $p<meta><reviews-cnt> - $p<score><reviews>;

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

    my $date = DateTime.now.later(days => 1000);

    set-cookie 'theme', $theme, http-only => True, expires => $date;

    redirect :see-other, "{http-root()}/?message=theme set to {$theme}";

  }

  get -> 'login-page', :$message, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

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

  get -> 'project', $project, 'up', :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    if check-user($user, $token) == True {

      unless "{cache-root()}/projects/$project/ups/$user".IO ~~ :e {
        say "up {cache-root()}/projects/$project/ups/$user";
        "{cache-root()}/projects/$project/ups/$user".IO.spurt("");
         touch-project($project, $user, %( action => "project upvote") );

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
        touch-project($project, $user, %( action => "project downvote") );
        unlink "{cache-root()}/projects/$project/ups/$user";
      }
    
      redirect :see-other, "{http-root()}/?message=project downvoted";

    } else {

      redirect :see-other, "{http-root()}/login-page";

    }
      
  }

  get -> 'user', 'messages', :$message?, :$user is cookie, :$token is cookie, :$theme is cookie = default-theme() {

    if check-user($user, $token) {

      my @messages;

      if "{cache-root()}/users/$user/notifications/inbox".IO ~~ :d {
        for dir("{cache-root()}/users/$user/notifications/inbox") -> $m {
          my %meta = message-from-file($m);
          push @messages, %meta;
        }
      }
    
      template 'templates/messages.crotmp', {
        title => title(),
        message => $message,
        http-root => http-root(),
        user => $user, 
        css => css($theme), 
        navbar => navbar($user, $token, $theme),
        messages => @messages.sort({ .<creation-date> }).reverse,
        messages-cnt => @messages.elems,
      }


    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign in to see your messages";

    }

  }

  get -> 'user', 'message', 'mark-as-read', :$path, :$user is cookie, :$token is cookie  {

    if check-user($user, $token) == True {

      if "{cache-root()}/users/$user/notifications/inbox/$path".IO ~~ :f {
        say "mark {cache-root()}/users/$user/notifications/inbox/$path as read";
        mkdir "{cache-root()}/users/$user/notifications/old";
        move 
          "{cache-root()}/users/$user/notifications/inbox/$path",
          "{cache-root()}/users/$user/notifications/old/$path"
      }

      redirect :see-other, "{http-root()}/user/messages?message=message marked as read";

    } else {

      redirect :see-other, "{http-root()}/login-page?message=you need to sign to manage messages";

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
