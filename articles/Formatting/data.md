# mybfio reviews formatting rules

## Mentioning users

Simply use `@user`:

```
Hello @user ! An interesting review ...
```

## Italic, designated color

Use back quote symbols, to have a text in italic style with a designated color, 
for example:

```
Such languages as `Raku`, `Perl` and `C++`
```

## Block quotes

Use `|` symbols to designate blocks of quotes. For example:

```
The raku.org says:

| Hi, my name is Camelia. 
| I'm the spokesbug for the Raku Programming Language.

```

## Unicode symbols

Use `:unicode name,:` to insert unicode symbols, for example::

```
What a beautiful :Butterfly::
Use :Fire Extinguisher: to snuff out :Fire:
```

For unicode names follow the [unicode-table.com](https://unicode-table.com/) web site.

## HTTP links

Referencing `#mybfio` projects.

Use `[project-name]` to reference mybfio project. For example:

    [teddy-bear] 

Referencing [raku.land](https://raku.land) projects.

Use `land[author distro-name]` to reference raku.land project. For example:

    land[cpan:JNTHN cro]

Referencing [github.com](https://github.com) projects.

Use `hub[author project]` to reference github project. For example:

    hub[melezhik rakudist-teddy-bear]

Referencing external sites.

Use standard URL syntax, which will be rendered as a http link tag.

For example:

```
https://mybf.io is a friendly reviews system
```

## Other rules

Any HTML tags will be removed
