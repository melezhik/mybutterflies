unit module MyButterfly::HTML;

use YAMLish;

sub gen-token is export {

  ("a".."z","A".."Z",0..9).flat.roll(8).join

}


sub check-user (Mu $user, Mu $token) is export {

  return False unless $user;

  return False unless $token;

  if "{cache-root()}/users/{$user}/tokens/{$token}".IO ~ :f {
    say "user $user, token - $token - validation passed";
    return True
  } else {
    say "user $user, token - $token - validation failed";
    return False
  }

}

sub get-web-conf is export {

  my $conf-file = %*ENV<HOME> ~ '/mbf.yaml';

  my %conf = $conf-file.IO ~~ :f ?? load-yaml($conf-file.IO.slurp) !! Hash.new;

  %conf;

}

sub title is export { 

  "My Butterflies - Independent Reviews of Sortware Projects"

}

sub cache-root is export {

  "{%*ENV<HOME>}/.mbf/";

}

sub http-root is export {

  %*ENV<MBF_HTTP_ROOT> || "";

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
      $bulma-theme = "sandstone";
    }

  } else {

    $bulma-theme = "nuclear";

  }


  qq:to /HERE/
  <meta charset="utf-8">
  <link rel="stylesheet" href="https://unpkg.com/bulmaswatch/$bulma-theme/bulmaswatch.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/markdown-it/12.0.4/markdown-it.min.js" integrity="sha512-0DkA2RqFvfXBVeti0R1l0E8oMkmY0X+bAA2i02Ld8xhpjpvqORUcE/UBe+0KOPzi5iNah0aBpW6uaNNrqCk73Q==" crossorigin="anonymous"></script>
  <script defer src="https://use.fontawesome.com/releases/v5.14.0/js/all.js"></script>
  <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/highlight.js/10.4.1/styles/default.min.css">
  <script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/10.4.1/highlight.min.js"></script>
  <script>hljs.initHighlightingOnLoad();</script>
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

sub theme-link (Mu $theme) {

  if $theme eq "light" {

    "<a href=\"{http-root()}/set-theme?theme=dark\">
      Dark theme
    </a>"

  } else {

    "<a href=\"{http-root()}/set-theme?theme=light\">
      Light theme
    </a>"

  }

}
sub navbar (Mu $user, Mu $token, Mu $theme) is export {
  qq:to /HERE/
      <div class="panel-block">
        <p class="control">
            {uniparse 'BUTTERFLY'} <a href="{http-root()}/">Ratings</a> |
            <a href="{http-root()}/add-project"> Add project </a> |
            <a href="{http-root()}/articles">Editor's articles</a> |
            <a href="{http-root()}/about">About</a> |
            {login-logout($user, $token)} |
            {theme-link($theme)}
        </p>
      </div>
  HERE

}
