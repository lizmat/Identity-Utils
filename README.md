[![Actions Status](https://github.com/lizmat/Identity-Utils/actions/workflows/linux.yml/badge.svg)](https://github.com/lizmat/Identity-Utils/actions) [![Actions Status](https://github.com/lizmat/Identity-Utils/actions/workflows/macos.yml/badge.svg)](https://github.com/lizmat/Identity-Utils/actions) [![Actions Status](https://github.com/lizmat/Identity-Utils/actions/workflows/windows.yml/badge.svg)](https://github.com/lizmat/Identity-Utils/actions)

NAME
====

Identity::Utils - Provide utility functions related to distribution identities

SYNOPSIS
========

```raku
use Identity::Utils;

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>:from<Perl5>";

say short-name($identity);   # Foo::Bar

say ver($identity);          # 0.0.42

say without-ver($identity);  # Foo::Bar:auth<zef:lizmat>:api<2.0>:from<Perl5>

say version($identity);      # v0.0.42

say auth($identity);         # zef:lizmat

say without-auth($identity); # Foo::Bar:ver<0.0.42>:api<2.0>:from<Perl5>

say ecosystem($identity);    # zef

say nick($identity);         # lizmat

say api($identity);          # 2.0

say without-api($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:from<Perl5>

say from($identity);         # Perl5

say without-from($identity); # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>

say sanitize($identity);     # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>:from<Perl5>

say build("Foo::Bar", :ver<0.0.42>);  # Foo::Bar:ver<0.0.42>

# build from a hash of a JSON file
say build(from-json("META6.json".io.slurp);

say is-short-name($identity);   # False
say is-short-name("Foo::Bar");  # True

say is-pinned($identity);   # True
say is-pinned("Foo::Bar");  # False

my $spec        = dependency-specification($identity);
my $compunit    = compunit($identity);
my $meta        = meta($identity, $repo);
my $source-io   = source-io($identity, $repo);
my $source      = source($identity, $repo);
my $bytecode-io = bytecode-io($identity, $repo);
my $bytecode    = bytecode($identity, $repo);

.say for latest-successors(@identities);

say raku-land-url($identity);  # https://raku.land/...
say rea-meta-url($identity);   # https://raw.githubusercontent.com...
say rea-dist-url($identity);   # https://github.com/Raku/REA/...

say "Download of $identity distribution successful"
  if rea-dist($identity);
say rea-meta($identity);  # {"api":"","auth":"zef:lizmat","authors"...

say rea-index-url;  # https://raw.githubusercontent.com/Raku...
my $rea-json = rea-index;

say zef-index-url;  # https://360.zef.pm
my $zef-json = zef-index;

use Identity::Utils <short-name auth>;  # only import "short-name" and "auth"
```

DESCRIPTION
===========

Identity::Utils provides some utility functions for inspecting various aspects of distribution identity strings. They assume any given string is a well-formed identity in the form `name:ver<0.0.1>:auth<eco:nick>` with an optional `api:<1>` field.

A general note with regards to `api`: if it consists of `"0"`, then it is assumed there is **no** api field specified.

SELECTIVE IMPORTING
===================

```raku
use Identity::Utils <short-name auth>;  # only import "short-name" and "auth"
```

By default all utility functions are exported. But you can limit this to the functions you actually need by specifying the names in the `use` statement.

To prevent name collisions and/or import any subroutine with a more memorable name, one can use the "original-name:known-as" syntax. A semi-colon in a specified string indicates the name by which the subroutine is known in this distribution, followed by the name with which it will be known in the lexical context in which the `use` command is executed.

```raku
use Identity::Utils <short-name:name>;  # import "short-name" as "name"

say name("Identity::Utils:auth<zef:lizmat>");  # Identity::Utils
```

SUBROUTINES
===========

api
---

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say api($identity); # 2.0
```

Returns the `api` field of the given identity, or `Nil` if no `api` field could be found.

auth
----

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say auth($identity); # zef:lizmat
```

Returns the `auth` field of the given identity, or `Nil` if no `auth` field could be found.

build
-----

```raku
my $ver  = "0.0.42";
my $auth = "zef:lizmat";
my $api  = "2.0";
my $from = "Perl5";
say build("Foo::Bar", :$ver, :$auth, :$api, :$from);
  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>:from<Perl5>

say build("Foo::Bar", :$ver, :nick<lizmat>);
  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>
```

Builds an identity string from the given short name and optional named arguments:

  * ver - the "ver" value to be used

  * auth - the "auth" value to be used, overrides "ecosystem" and "nick"

  * api - the "api" value to be used

  * from - the "from" value to be used, 'Perl6' and 'Raku' will be ignored

  * ecosystem - the ecosystem part of "auth", defaults to "zef"

  * nick - the nick part of "auth", unless overridden by "auth"

```raku
use String::Utils;
say build(String::Utils);  # String::Utils:ver<0.0.34>:auth<zef:lizmat>
```

An identity string can also be built from a type object.

```raku
# build from a hash of a JSON file
say build(from-json("META6.json".io.slurp);
```

Alternately, an identity string can be built from an `Associative` such as being created from a `META6.json` file.

bytecode
--------

```raku
my $buf = bytecode($identity);       # default: $*REPO

my $buf = bytecode($identity, ".");  # as if with -I.
```

Returns a `Buf` object with the precompiled bytecode of the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)).

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Attempts to create the bytecode file if there isn't one yet.

Returns `Nil` if the given identity could not be found, or there is no bytecode file for the short-name of the given identity (probably because it failed to compile).

bytecode-io
-----------

```raku
my $io = bytecode-io($identity);       # default: $*REPO

my $io = bytecode-io($identity, ".");  # as if with -I.
```

Returns an `IO::Path` object of the precompiled bytecode of the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)).

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Attempts to create the bytecode file if there isn't one yet.

Returns `Nil` if the given identity could not be found, or there is no bytecode file for the short-name of the given identity (probably because it failed to compile).

compunit
--------

```raku
my $compunit = compunit($identity);         # default: $*REPO

my $compunit = compunit($identity, ".");    # as if with -I.

my $compunit = compunit($identity, :need);  # make bytecode
```

Returns a [`Compunit`](https://docs.raku.org/type/CompUnit) object for the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)).

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

A boolean named argument `need` can be specified to indicate that a bytecode file should be created if there is none for this compunit yet.

Returns `Nil` if the given identity could not be found.

dependencies-from-depends
-------------------------

```raku
my %meta := from-json "META6.json".IO.slurp;
with %meta<depends> -> $depends {
    .say for dependencies-from-depends($depends);
}
```

Returns an iterable that produces all of the dependencies of the given "depends" value, as usually found in the META6.json file of a distribution. Although this is generally just a list of strings for most distributions, it **can** contain more structured information (which is also handled by this logic).

dependencies-from-identity
--------------------------

```raku
.say for dependencies-from-identity($identity);       # default: $*REPO

.say for dependencies-from-identity($identity, ".");  # as if with -I.
```

Returns an iterable that produces all of the dependencies of the given identity.

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Returns `Empty` if either the given identity could not be found, or there are no dependencies.

dependency-specification
------------------------

```raku
my $spec = dependency-specification($identity);
```

Creates a `CompUnit::DependencySpecification` object for the given identity.

ecosystem
---------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say ecosystem($identity); # zef
```

Returns the ecosystem part of the `auth` field of the given identity, or `Nil` if no `auth` field could be found.

from
----

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>:from<Perl5>";
say from($identity);  # Perl5
```

Returns the `from` field of the given identity as a `Str`, or `Nil` if no `from` field could be found.

is-pinned
---------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say is-pinned($identity);   # True
say is-pinned("Foo::Bar");  # False
```

Returns a boolean indicating whether the given identity is considered to be pinned to a specific release. This implies: having an `auth` and having a version **without** a `+` or a `*` in it.

is-short-name
-------------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say is-short-name($identity);   # False
say is-short-name("Foo::Bar");  # True
```

Returns a boolean indicating whether the given identity consists of just a `short-name`.

latest-successors
-----------------

```raku
.say for latest-successors(@identies);
```

Returns a sorted `Seq` of identities that have been filtered by the same semantics that are used when installing a module without specifying anything other than a short name of an identity.

For instance, taking:

    AccountableBagHash:ver<0.0.3>:auth<cpan:ELIZABETH>
    AccountableBagHash:ver<0.0.6>:auth<zef:lizmat>

would only return `AccountableBagHash:ver<0.0.6>:auth<zef:lizmat>` because it has a higher version number, and the ecosystems are different.

meta
----

```raku
my $meta = meta($identity);       # default: $*REPO

my $meta = meta($identity, ".");  # as if with -I.
```

Returns a hash with the meta information of the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)) as typically found in the `META6.json` file of a distribution.

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Returns `Nil` if the given identity could not be found.

nick
----

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say nick($identity); # lizmat
```

Returns the nickname part of the `auth` field of the given identity, or `Nil` if no `auth` field could be found.

raku-land-url
-------------

```raku
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>:api<2.0>";
say raku-land-url($identity);  # https://raku.land/zef:lizmat/FOO::Bar?v=0.0.42
```

Returns the [raku.land](https://raku.land) URL of the given identity.

rea-dist
--------

```raku
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>";
say "Download of $identity distribution successful"
  if rea-dist($identity);
```

Attempts to download the distribution tar file of the given identity from the [Raku Ecosystem Archive (REA)](https://github.com/Raku/REA) and returns `True` if this was successful.

Allows specifying a second argument that is either a path or an `IO::Path` object to indicate where the download should be stored: it defaults to "." indicating the current directory.

If the path indicates a directory, then the distribution will be stored in that directory with the identity's long name. Otherwise the path will be taken as the name to store the distribution as.

Assumes the `curl` command-line program is installed and a network connection is available.

Optionally takes a `:verbose` named argument: if specified with a truish value, will show any error information on STDERR if the download failed for some reason.

rea-dist-url
------------

```raku
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>";
say rea-dist-url($identity);
# https://github.com/Raku/REA/raw/refs/heads/main/archive/F/Foo::Bar/Foo::Bar:ver<0.0.42>:auth<zef:lizmat>.tar.gz
```

Returns the URL of the distribution of the given identity in the [Raku Ecosystem Archive (REA)](https://github.com/Raku/REA).

rea-index
---------

```raku
my $json = rea-index;
```

Returns the JSON of the REA (Raku Ecosystem Archive) index.

Assumes the `curl` command-line program is installed and a network connection is available.

rea-index-url
-------------

```raku
say rea-index-url;
# https://raw.githubusercontent.com/Raku/REA/refs/heads/main/META.json
```

Returns the URL of the JSON-index of the REA (Raku Ecosystem Archive).

rea-meta
--------

```raku
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>";
say rea-meta($identity);  # {"api":"","auth":"zef:lizmat","authors"...
```

Attempts to download the meta information file of the given identity from the [Raku Ecosystem Archive (REA)](https://github.com/Raku/REA) and returns that if successful. Otherwise returns `Nil`.

Assumes the `curl` command-line program is installed and a network connection is available.

Optionally takes a `:verbose` named argument: if specified with a truish value, will show any error information on STDERR if the download failed for some reason.

rea-meta-url
------------

```raku
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>";
say rea-meta-url($identity);
# https://raw.githubusercontent.com/Raku/REA/refs/heads/main/meta/F/Foo::Bar/Foo::Bar:ver<0.0.42>:auth<zef:lizmat>.json
```

Returns the URL of the meta information of the given identity in the [Raku Ecosystem Archive (REA)](https://github.com/Raku/REA).

sanitize
--------

```raku
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>:api<2.0>";
say sanitize($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>
```

Returns a version of the given identity in which any `ver`, `auth` and `api` fields are put in the correct order.

short-name
----------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say short-name($identity);  # Foo::Bar
```

Returns the short name part of the given identity, or the identity itself if no `ver`, `auth` or `api` fields could be found.

source
------

```raku
say source($identity);       # default: $*REPO

say source($identity, ".");  # as if with -I.
```

Returns the source-code of the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)) as typically found in the `lib` directory of a distribution.

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Returns `Nil` if the given identity could not be found, or there is no source-file for the short-name of the given identity.

source-io
---------

```raku
my $io = source-io($identity);       # default: $*REPO

my $io = source-io($identity, ".");  # as if with -I.
```

Returns an `IO::Path` object of the source of the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)) as typically found in the `lib` directory of a distribution.

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Returns `Nil` if the given identity could not be found, or there is no source-file for the short-name of the given identity.

ver
---

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say ver($identity);  # 0.0.42
```

Returns the `ver` field of the given identity as a `Str`, or `Nil` if no `ver` field could be found.

version
-------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say version($identity);  # v0.0.42
```

Returns the `ver` field of the given identity as a `Version` object, or `Nil` if no `ver` field could be found.

without-api
-----------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-api($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>

=head2 raku-land-url

=begin code :lang<raku>
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>:api<2.0>";
say raku-land-url($identity);  # https://raku.land/zef:lizmat/FOO::Bar?v=0.0.42
```

Returns the [raku.land](https://raku.land) URL of the given identity.

sanitize
--------

```raku
my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>:api<2.0>";
say sanitize($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>
```

Returns a version of the given identity in which any `ver`, `auth` and `api` fields are put in the correct order.

short-name
----------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say short-name($identity);  # Foo::Bar
```

Returns the short name part of the given identity, or the identity itself if no `ver`, `auth` or `api` fields could be found.

source
------

```raku
say source($identity);       # default: $*REPO

say source($identity, ".");  # as if with -I.
```

Returns the source-code of the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)) as typically found in the `lib` directory of a distribution.

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Returns `Nil` if the given identity could not be found, or there is no source-file for the short-name of the given identity.

source-io
---------

```raku
my $io = source-io($identity);       # default: $*REPO

my $io = source-io($identity, ".");  # as if with -I.
```

Returns an `IO::Path` object of the source of the given identity and the currently active repository ([`$*REPO`](https://docs.raku.org/language/compilation#$*REPO)) as typically found in the `lib` directory of a distribution.

It is also possible to override the repository (chain) by specifying a second argument, this can be an object of type:

  * `Str` - indicate a path for a ::FileSystem repo, just as with -I.

  * `IO::Path` - indicate a path for a ::FileSystem repo

  * `CompUnit::Repository` - the actual repo to use

Returns `Nil` if the given identity could not be found, or there is no source-file for the short-name of the given identity.

ver
---

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say ver($identity);  # 0.0.42
```

Returns the `ver` field of the given identity as a `Str`, or `Nil` if no `ver` field could be found.

version
-------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say version($identity);  # v0.0.42
```

Returns the `ver` field of the given identity as a `Version` object, or `Nil` if no `ver` field could be found.

without-api
-----------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-api($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>
```

Returns the identity **without** any `api` field of the given identity.

without-auth
------------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-auth($identity);  # Foo::Bar:ver<0.0.42>:api<2.0>
```

Returns the identity **without** any `auth` field of the given identity.

without-from
------------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:from<Perl5>";
say without-from($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>
```

Returns the identity **without** any `from` field of the given identity.

without-ver
-----------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-ver($identity);  # Foo::Bar:auth<zef:lizmat>:api<2.0>
```

Returns the identity **without** any `ver` field of the given identity.

zef-index
---------

```raku
my $json = zef-index;
```

Returns the JSON of the zef index.

Assumes the `curl` command-line program is installed and a network connection is available.

zef-index-url
-------------

```raku
say zef-index-url;  # https://360.zef.pm
```

Returns the URL of the JSON-index of the zef ecosystem.

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Identity-Utils . Comments and Pull Requests are welcome.

If you like this module, or what I’m doing more generally, committing to a [small sponsorship](https://github.com/sponsors/lizmat/) would mean a great deal to me!

COPYRIGHT AND LICENSE
=====================

Copyright 2022, 2024, 2025 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

