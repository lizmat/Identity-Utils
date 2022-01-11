use String::Utils:ver<0.0.2>:auth<zef:lizmat>;

my sub short-name(str $identity) is export {
    (before $identity, ':ver<')
      // (before $identity, ':auth<')
      // (before $identity, ':api<')
      // $identity
}

my sub ver(str $identity) is export {
    between $identity, ':ver<', '>'
}

my sub version(str $identity) is export {
    (.Version with between $identity, ':ver<', '>') // Nil
}

my sub auth(str $identity) is export {
    between $identity, ':auth<', '>'
}

my sub ecosystem(str $identity) is export {
    between $identity, ':auth<', ':'
}

my sub nick(str $identity) is export {
    after auth($identity), ':'
}

my sub api(str $identity) is export {
    between $identity, ':api<', '>'
}

=begin pod

=head1 NAME

Identity::Utils - Provide utility functions related to distribution identities

=head1 SYNOPSIS

=begin code :lang<raku>

use Identity::Utils;

my $identity = "Foo::Bar:ver<0.0.42>:auth<zef:lizmat>:api<2.0>";

say short-name($identity);  # Foo::Bar

say ver($identity);         # 0.0.42

say version($identity);     # v0.0.42

say auth($identity);        # zef:lizmat

say ecosystem($identity);   # zef

say nick($identity);        # lizmat

say api($identity);         # 2.0

=end code

=head1 DESCRIPTION

Identity::Utils provides some utility functions for inspecting various aspects
of distribution identity strings.  They assume any given string is a
well-formed identity in the form C<name:ver<0.0.1>:auth<eco:nick>> with an
optional C<api:<1>> field.

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

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Identity-Utils . Comments
and Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
