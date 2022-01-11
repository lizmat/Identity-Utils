[![Actions Status](https://github.com/lizmat/Identity-Utils/workflows/test/badge.svg)](https://github.com/lizmat/Identity-Utils/actions)

NAME
====

Identity::Utils - Provide utility functions related to distribution identities

SYNOPSIS
========

```raku
use Identity::Utils;

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";

say short-name($identity);  # Foo::Bar

say ver($identity);         # 0.0.42

say version($identity);     # v0.0.42

say auth($identity);        # zef:lizmat

say ecosystem($identity);   # zef

say nick($identity);        # lizmat

say api($identity);         # 2.0
```

DESCRIPTION
===========

Identity::Utils provides some utility functions for inspecting various aspects of distribution identity strings. They assume any given string is a well-formed identity in the form `name:ver<0.0.1>:auth<eco:nick>` with an optional `api:<1>` field.

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

ecosystem
---------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say ecosystem($identity); # zef
```

Returns the ecosystem part of the `auth` field of the given identity, or `Nil` if no `auth` field could be found.

nick
----

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say nick($identity); # lizmat
```

Returns the nickname part of the `auth` field of the given identity, or `Nil` if no `auth` field could be found.

short-name
----------

```raku
my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say short-name($identity);  # Foo::Bar
```

Returns the short name part of the given identity, or the identity itself if no `ver`, `auth` or `api` fields could be found.

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

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Identity-Utils . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

