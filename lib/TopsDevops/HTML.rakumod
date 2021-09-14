unit module TopsDevops::HTML;

use Sparky;

sub http-root {

  %*ENV<HTTP_ROOT> || "";

}

sub css is export {

  my %conf = get-sparky-conf();

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

sub login-logout ($user) {

  if $user {

    "<a class=\"navbar-item\" href=\"{http-root()}/logout\">
      Log out
    </a>"

  } else {

    "<a class=\"navbar-item\" href=\"{http-root()}/login\">
      Log In
    </a>"
  }

}

sub navbar ($user) is export {

  qq:to /HERE/
    <nav class="navbar" role="navigation" aria-label="main navigation">
      <div class="navbar-brand">
        <a role="button" class="navbar-burger burger" aria-label="menu" aria-expanded="false" data-target="navbarBasicExample">
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
          <span aria-hidden="true"></span>
        </a>
      </div>
      <div id="navbarBasicExample" class="navbar-menu">
        <div class="navbar-start">
          <a class="navbar-item" href="{http-root()}/">
            Home
          </a>
          <a class="navbar-item" href="{http-root()}/about">
            About
          </a>
          {login-logout($user)}
        </div>
      </div>
    </nav>
  HERE

}
