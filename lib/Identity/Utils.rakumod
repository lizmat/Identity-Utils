use String::Utils:ver<0.0.5>:auth<zef:lizmat>;

my sub extract(str $identity, str $needle) {
    if between $identity, $needle ~ '<', '>' -> str $string {
        $string
    }
    elsif between $identity, $needle ~ '(', ')' -> $code {
        try $code.EVAL
    }
    else {
        Nil
    }
}
my sub remove(str $identity, str $needle) {
    if between-included($identity, $needle ~ '<', '>')
      // between-included($identity, $needle ~ '(', ')') -> str $string {
        $identity.subst($string)
    }
    else {
        Nil
    }
}

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
  :$ver, :$auth, :$api, :$ecosystem = "zef", :$nick, :$from
) is export {
    my str @parts = $short-name;
    @parts.push("ver<$ver>") if $ver;
    if $auth {
        @parts.push("auth<$auth>");
    }
    orwith $nick {
        @parts.push("auth<$ecosystem:$nick>");
    }
    @parts.push("api<$api>")   if $api  && $api  ne "0";
    @parts.push("from<$from>") if $from && $from ne "Perl6" | "Raku";
    @parts.join(":")
}

my sub ver(str $identity) is export {
    extract $identity, ':ver'
}
my sub without-ver(str $identity) is export {
    remove $identity, ':ver'
}

my sub version(str $identity) is export {
    (.Version with extract $identity, ':ver') // Nil
}

my sub auth(str $identity) is export {
    extract $identity, ':auth'
}
my sub without-auth(str $identity) is export {
    remove $identity, ':auth'
}

my sub ecosystem(str $identity) is export {
    with auth($identity) -> $auth {
        before $auth, ':'
    }
    else {
        Nil
    }
}

my sub nick(str $identity) is export {
    with auth($identity) -> $auth {
        after $auth, ':'
    }
    else {
        Nil
    }
}

my sub api(str $identity) is export {
    extract $identity, ':api'
}
my sub without-api(str $identity) is export {
    remove $identity, ':api'
}

my sub from(str $identity) is export {
    extract $identity, ':from'
}
my sub without-from(str $identity) is export {
    remove $identity, ':from'
}

my sub sanitize(str $identity) is export {
    my str @parts = short-name($identity);
    @parts.push("ver<$_>")  with ver($identity);
    @parts.push("auth<$_>") with auth($identity);
    if api($identity) -> $api {
        @parts.push("api<$api>") if $api ne "0";
    }
    if from($identity) -> $from {
        @parts.push("from<$from>") if $from ne "Perl6";
    }
    @parts.join(":")
}

my sub is-short-name(str $identity) is export {
    for <:ver :auth :api :from> -> str $needle {
        with $identity.index($needle) -> int $index {
            my int $pos = $index + $needle.chars;
            return False
              if $identity.substr-eq('<',$pos) || $identity.substr-eq('(',$pos);
        }
    }
    True
}

=begin pod

=head1 NAME

Identity::Utils - Provide utility functions related to distribution identities

=head1 SYNOPSIS

=begin code :lang<raku>

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

say is-short-name($identity);   # False
say is-short-name("Foo::Bar");  # True

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
my $from = "Perl5";
say build("Foo::Bar", :$ver, :$auth, :$api, :$from);
  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>:from<Perl5>

say build("Foo::Bar", :$ver, :nick<lizmat>);
  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>

=end code

Builds an identity string from the given short name and optional named
arguments:

=item ver  - the "ver" value to be used
=item auth - the "auth" value to be used, overrides "ecosystem" and "nick"
=item api  - the "api" value to be used
=item from - the "from" value to be used, 'Perl6' and 'Raku' will be ignored
=item ecosystem - the ecosystem part of "auth", defaults to "zef"
=item nick - the nick part of "auth", unless overridden by "auth"

=head2 ecosystem

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say ecosystem($identity); # zef

=end code

Returns the ecosystem part of the C<auth> field of the given identity, or
C<Nil> if no C<auth> field could be found.

=head2 from

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>:from<Perl5>";
say from($identity);  # Perl5

=end code

Returns the C<from> field of the given identity as a C<Str>, or C<Nil> if no
C<from> field could be found.

=head2 is-short-name

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say is-short-name($identity);   # False
say is-short-name("Foo::Bar");  # True

=end code

Returns a boolean indicating whether the given identity consists of just a
C<short-name>.

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

Returns the identity B<without> any C<api> field of the given identity.

=head2 without-auth

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-auth($identity);  # Foo::Bar:ver<0.0.42>:api<2.0>

=end code

Returns the identity B<without> any C<auth> field of the given identity.

=head2 without-from

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:from<Perl5>";
say without-from($identity);  # Foo::Bar:ver<0.0.42>:auth<zef:lizmat>

=end code

Returns the identity B<without> any C<from> field of the given identity.

=head2 without-ver

=begin code :lang<raku>

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";
say without-ver($identity);  # Foo::Bar:auth<zef:lizmat>:api<2.0>

=end code

Returns the identity B<without> any C<ver> field of the given identity.

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Identity-Utils . Comments
and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
