use String::Utils:ver<0.0.3>:auth<zef:lizmat>;

my sub short-name(str $identity) is export {
    with $identity.rindex('::') -> int $offset {
        with $identity.index(':', $offset + 2) -> int $chars {
            $identity.substr(0, $chars)
        }
        else {
            $identity
        }
    }
    orwith $identity.index(':') -> int $chars {
        $identity.substr(0, $chars)
    }
    else {
        $identity
    }
}

my sub build(str $short-name,
  :$ver, :$auth, :$api, :$ecosystem = "zef", :$nick
) is export {
    my str @parts = $short-name;
    @parts.push("ver<$ver>") if $ver;
    if $auth {
        @parts.push("auth<$auth>");
    }
    orwith $nick {
        @parts.push("auth<$ecosystem:$nick>");
    }
    @parts.push("api<$api>") if $api && $api ne "0";
    @parts.join(":")
}

my sub ver(str $identity) is export {
    between $identity, ':ver<', '>'
}
my sub without-ver(str $identity) is export {
    around $identity, ':ver<', '>'
}

my sub version(str $identity) is export {
    (.Version with between $identity, ':ver<', '>') // Nil
}

my sub auth(str $identity) is export {
    between $identity, ':auth<', '>'
}
my sub without-auth(str $identity) is export {
    around $identity, ':auth<', '>'
}

my sub ecosystem(str $identity) is export {
    between $identity, ':auth<', ':'
}

my sub nick(str $identity) is export {
    after auth($identity), ':'
}

my sub api(str $identity) is export {
    if between($identity, ':api<', '>') -> $api {
        $api eq "0" ?? Nil !! $api
    }
    else {
        Nil
    }
}
my sub without-api(str $identity) is export {
    around $identity, ':api<', '>'
}

my sub sanitize(str $identity) is export {
    my str @parts = short-name($identity);
    @parts.push("ver<$_>")  with ver($identity);
    @parts.push("auth<$_>") with auth($identity);
    if api($identity) -> $api {
        @parts.push("api<$api>") if $api ne "0";
    }
    @parts.join(":")
}

=begin pod

=head1 NAME

Identity::Utils - Provide utility functions related to distribution identities

=head1 SYNOPSIS

=begin code :lang<raku>

use Identity::Utils;

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";

say short-name($identity);    # Foo::Bar

say ver($identity);           # 0.0.42

say without-ver($identity);   # Foo::Bar:auth<zef:lizmat>:api<2.0>

say version($identity);       # v0.0.42

say auth($identity);          # zef:lizmat

say without-auth($identity);  # Foo::Bar:ver<0.0.42>:api<2.0>

say ecosystem($identity);     # zef

say nick($identity);          # lizmat

say api($identity);           # 2.0

say without-api($identity);   # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>

say sanitize($identity);      # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>

say build("Foo::Bar", :ver<0.0.42>);  # Foo::Bar:ver<0.0.42>

=end code

=head1 DESCRIPTION

Identity::Utils provides some utility functions for inspecting various aspects
of distribution identity strings.  They assume any given string is a
well-formed identity in the form C<name:ver<0.0.1>:auth<eco:nick>> with an
optional C<api:<1>> field.

A general note with regards to C<api>: if it consists of C<"0">, then it is
assumed there is B<no> api field specified.

=head1 SUBROUTINES

=head2 api

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say api($identity); # 2.0

=end code

Returns the C<api> field of the given identity, or C<Nil> if no C<api> field
could be found.

=head2 auth

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say auth($identity); # zef:lizmat

=end code

Returns the C<auth> field of the given identity, or C<Nil> if no C<auth> field
could be found.

=head2 build

=begin code :lang<raku>

my $ver  = "0.0.42";
my $auth = "zef:lizmat";
my $api  = "2.0";
say build("Foo::Bar", :$ver, :$auth, :$api);
  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>

say build("Foo::Bar", :$ver, :nick<lizmat>);
  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>

=end code

Builds an identity string from the given short name and optional named
arguments:

=item ver  - the "ver" value to be used
=item auth - the "auth" value to be used, overrides "ecosystem" and "nick"
=item api  - the "api" value to be used
=item ecosystem - the ecosystem part of "auth", defaults to "zef"
=item nick - the nick part of "auth", unless overridden by "auth"

=head2 ecosystem

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say ecosystem($identity); # zef

=end code

Returns the ecosystem part of the C<auth> field of the given identity, or
C<Nil> if no C<auth> field could be found.

=head2 nick

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say nick($identity); # lizmat

=end code

Returns the nickname part of the C<auth> field of the given identity, or
C<Nil> if no C<auth> field could be found.

=head2 sanitize

=begin code :lang<raku>

my $identity = "Foo::Bar:auth<zef:lizmat>:ver<0.0.42>:api<2.0>";
say sanitize($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>

=end code

Returns a version of the given identity in which any C<ver>, C<auth> and
C<api> fields are put in the correct order.

=head2 short-name

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say short-name($identity);  # Foo::Bar

=end code

Returns the short name part of the given identity, or the identity itself
if no C<ver>, C<auth> or C<api> fields could be found.

=head2 ver

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say ver($identity);  # 0.0.42

=end code

Returns the C<ver> field of the given identity as a C<Str>, or C<Nil> if no
C<ver> field could be found.

=head2 version

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say version($identity);  # v0.0.42

=end code

Returns the C<ver> field of the given identity as a C<Version> object, or
C<Nil> if no C<ver> field could be found.

=head2 without-api

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-api($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>

=end code

Returns the identity B<without> any C<api> field of the given identity

=head2 without-auth

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-auth($identity);  # Foo::Bar:ver<0.0.42>:api<2.0>

=end code

Returns the identity B<without> any C<auth> field of the given identity

=head2 without-ver

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-ver($identity);  # Foo::Bar:auth<zef:lizmat>:api<2.0>

=end code

Returns the identity B<without> any C<ver> field of the given identity

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Identity-Utils . Comments
and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
