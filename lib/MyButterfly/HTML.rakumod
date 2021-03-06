unit module MyButterfly::HTML;

use MyButterfly::Conf;
use MyButterfly::Utils;

sub gen-token is export {

  ("a".."z","A".."Z",0..9).flat.roll(8).join

}


sub title is export { 

  "My Butterflies - Friendly Software Reviews Network"

}

sub css (Mu $theme) is export {

  my %conf = get-web-conf();

  my $bulma-theme ;

  if $theme eq "dark" {

    if %conf<ui> && %conf<ui><theme><dark> {
      $bulma-theme = %conf<ui><theme><dark>
    } else {
      $bulma-theme = "nuclear";
    }

  } elsif $theme eq "light" {

    if %conf<ui> && %conf<ui><theme><light> {
      $bulma-theme = %conf<ui><theme><light>
    } else {
      $bulma-theme = "flatly";
    }

  } else {

    $bulma-theme = "cerulean";

  }


  qq:to /HERE/
  <meta charset="utf-8">
  <link rel="stylesheet" href="https://unpkg.com/bulmaswatch/$bulma-theme/bulmaswatch.min.css">
  <script defer src="https://use.fontawesome.com/releases/v5.14.0/js/all.js"></script>
  HERE

}

sub login-logout (Mu $user, Mu $token) {

  if check-user($user,$token) == True {

    "<a href=\"{http-root()}/logout?q=123\">
      Log out
    </a>"

  } else {

    "<a href=\"{http-root()}/login-page?q=123\">
      Log In
    </a>"
  }

}

sub messages (Mu $user, Mu $token ){

  if check-user($user,$token) == True and user-messages($user) {

    "<a href=\"{http-root()}/user/messages\">{uniparse('Bell')}</a> |"

  }

}


sub theme-link (Mu $theme) {

  if $theme eq "light" {

    "<a href=\"{http-root()}/set-theme?theme=dark\">
      Dark Theme
    </a>"

  } else {

    "<a href=\"{http-root()}/set-theme?theme=light\">
      Light Theme
    </a>"

  }

}
sub navbar (Mu $user, Mu $token, Mu $theme) is export {
  qq:to /HERE/
      <div class="panel-block">
        <p class="control">
            {uniparse 'BUTTERFLY'} <a href="{http-root()}/">Rating</a> |
            <a href="{http-root()}/add-project"> Add Project </a> |
            <a href="{http-root()}/about">About</a> |
            <a href="{http-root()}/contest-list">Contest</a> |
            <a href="{http-root()}/contest">Contest Rules</a> |
            <a href="{http-root()}/articles">Articles</a> |
            {theme-link($theme)} |
            <a href="https://github.com/melezhik/mybfio/issues/new/choose" target="_blank">Support</a> |
            {messages($user,$token)}
            {login-logout($user, $token)}
        </p>
      </div>
  HERE

}
