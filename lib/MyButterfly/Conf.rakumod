unit module MyButterfly::Conf;

use YAMLish;

sub cache-root is export {

  "{%*ENV<HOME>}/.mbf/";

}

sub http-root is export {

  %*ENV<MBF_HTTP_ROOT> || "";

}

sub get-web-conf is export {

  my $conf-file = %*ENV<HOME> ~ '/mbf.yaml';

  my %conf = $conf-file.IO ~~ :f ?? load-yaml($conf-file.IO.slurp) !! Hash.new;

  %conf;

}

sub languages is export {
 qw { 
      Raku
      Perl
      C++
      Python
      Golang
      Ruby
      Rust
      Lua
      Java
      Powershell
      Shell
      Javascript
      Typescript
      Design
      Unknown
      NotApplicable
  }
}

sub categories is export {
  (
    "package manager",
    "libraries",
    "cicd",
    "data engineering",
    "cloud",
    "tools",
    "databases",
    "web",
    "automation",
    "testing",
    "infrastructure as code",
    "configuration management",
    "task runner",
    "build tool",
    "applications",
    "job queue",
    "service",
    "programming language",
    "design",
  )
}

sub array-to-html-option ($active, @list) is export {

    @list.map({
      my $i = $_;
      ($i eq $active) ?? 
      "<option value=\"{$i}\" selected=\"1\">{$i}</option>" !!
      "<option value=\"{$i}\">{$i}</option>" 
    }).join("\n")
}
