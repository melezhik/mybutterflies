#!bash

id=$(config id)
short=$(config short)
title=$(config title)
tags=$(config tags)

echo "add article [$id] to mbf"

mkdir -p ~/.mbf/articles/$id

mkdir -p ~/.mbf/articles/$id/ups

cat << HERE > ~/.mbf/articles/$id/meta.json
{
  "id" : "$id",
  "title" : "$title",
  "short" : "$short",
  "tags" : "$tags"
}
HERE

cp -r articles/$id/data.md  ~/.mbf/articles/$id/data.md
