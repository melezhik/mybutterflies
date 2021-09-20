#!bash

project=$(config project)
description=$(config description)
url=$(config url)
language=$(config language)
category=$(config category)

echo "add project [$project] to mbf"

mkdir -p ~/.mbf/projects/$project

mkdir -p ~/.mbf/projects/$project/reviews
mkdir -p ~/.mbf/projects/$project/reviews/data
mkdir -p ~/.mbf/projects/$project/reviews/points

mkdir -p ~/.mbf/projects/$project/ups


cat << HERE > ~/.mbf/projects/$project/meta.json
{
  "project" : "$project",
  "description" : "$description",
  "category" : "$category",
  "language" : "$language",
  "url" : "$url"
}
HERE
