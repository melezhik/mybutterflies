use Text::Markdown;

for dir("{config()<mbf-root>}/articles/") -> $a {

  $a.IO ~~ :d or next;

  my $md = parse-markdown-from-file("{$a}/data.md");

  "{$a}/data.html".IO.spurt($md.to_html);

  say "{$a}/data.html OK";

}

