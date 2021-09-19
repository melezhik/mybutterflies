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

  "My Butterflies - Independent Software Reviews"

}

sub cache-root is export {

  "{%*ENV<HOME>}/.mbf/";

}

sub http-root is export {

  %*ENV<MBF_HTTP_ROOT> || "";

}

sub css is export {

  my %conf = get-web-conf();

  my $theme ;

  if %conf<ui> && %conf<ui><theme> {
    $theme = %conf<ui><theme>
  } else {
    $theme = "sandstone";
  }

  qq:to /HERE/
  <meta charset="utf-8">
  <link rel="stylesheet" href="https://unpkg.com/bulmaswatch/$theme/bulmaswatch.min.css">
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

sub navbar (Mu $user, Mu $token) is export {
  qq:to /HERE/
      <div class="panel-block">
        <p class="control">
            {uniparse 'BUTTERFLY'} <a href="{http-root()}/">Ratings</a> |
            <a href="{http-root()}/add-project"> Add project </a> |
            <a href="{http-root()}/about">About</a> |
            {login-logout($user, $token)} |
        </p>
      </div>
  HERE

}
