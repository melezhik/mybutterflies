
my $art-id = config()<art-id>;

copy 
  "articles/{$art-id}/data.md",
  "{config()<mbf-root>}/articles/{$art-id}/data.md";

say "{config()<mbf-root>}/articles/{$art-id}/data.md OK";

