use Text::Markdown;

=begin comment

for dir("{config()<mbf-root>}/articles/") -> $a {

  $a.IO ~~ :d or next;

  my $md = parse-markdown-from-file("{$a}/data.md");

  "{$a}/data.html".IO.spurt($md.to_html);

  say "{$a}/data.html OK";

}

=end comment

my $art-id = config()<art-id>;

my $md = parse-markdown-from-file("{config()<mbf-root>}/articles/{$art-id}/data.md");

"{config()<mbf-root>}/articles/{$art-id}/data.html".IO.spurt($md.to_html);

say "{config()<mbf-root>}/articles/{$art-id}/data.html OK";

