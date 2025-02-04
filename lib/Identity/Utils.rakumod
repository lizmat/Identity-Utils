my constant @imports = <after before between between-included>;
my constant %imports = @imports.map(* => True);
use String::Utils:ver<0.0.32+>:auth<zef:lizmat> @imports;

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
        $identity
    }
}

my sub short-name(str $identity) {
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
) {
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

my sub ver(str $identity) {
    extract $identity, ':ver'
}
my sub without-ver(str $identity) {
    remove $identity, ':ver'
}

my sub version(str $identity) {
    (.Version with extract $identity, ':ver') // Nil
}

my sub auth(str $identity) {
    extract $identity, ':auth'
}
my sub without-auth(str $identity) {
    remove $identity, ':auth'
}

my sub ecosystem(str $identity) {
    with auth($identity) -> $auth {
        before $auth, ':'
    }
    else {
        Nil
    }
}

my sub nick(str $identity) {
    with auth($identity) -> $auth {
        after $auth, ':'
    }
    else {
        Nil
    }
}

my sub api(str $identity) {
    extract $identity, ':api'
}
my sub without-api(str $identity) {
    remove $identity, ':api'
}

my sub from(str $identity) {
    extract $identity, ':from'
}
my sub without-from(str $identity) {
    remove $identity, ':from'
}

my sub sanitize(str $identity) {
    my str @parts = short-name($identity);
    @parts.push("ver<$_>")  with ver($identity);
    @parts.push("auth<$_>") with auth($identity);
    if api($identity) -> $api {
        @parts.push("api<$api>") if $api ne "0";
    }
    if from($identity) -> $from {
        @parts.push("from<$from>")
          unless $from eq 'Raku' | 'Perl6';
    }
    @parts.join(":")
}

my sub is-short-name(str $identity) {
    short-name($identity) eq $identity
}

my sub is-pinned(str $identity) {
    so auth($identity)
      && (my $version := version $identity)
      && !$version.plus
      && !$version.whatever
}

my sub dependency-specification(str $identity) {
     CompUnit::DependencySpecification.new:
       short-name   => short-name($identity),
       auth-matcher => auth($identity) // True,
       ver-matcher  => ver($identity)  // True,
       api-matcher  => api($identity)  // True
}

my sub compunit(str $identity, $REPO? is copy, :$need) {
    if $REPO.defined {
        if $REPO ~~ Str | IO::Path {
            $REPO = CompUnit::Repository::FileSystem.new(
              :prefix($REPO),
              :next-repo($*REPO)
            );
        }
        elsif $REPO ~~ CompUnit::Repository {
            # already ok
        }
        else {
            return Nil;
        }
    }
    else {
        $REPO = $*REPO;
    }

    my $spec := dependency-specification($identity);
    with $REPO.resolve($spec) {
        # Make sure a proper bytecode file is there if we need it
        try $REPO.need($spec) if $need;

        $_
    }
    else {
        Nil
    }
}

my sub meta(str $identity, $REPO?) {
    compunit($identity, $REPO) andthen .distribution.meta
}

my sub source-io(str $identity, $REPO?) {
    with compunit($identity, $REPO) -> $compunit {
        my $repo := $compunit.repo;

        # Get rid of installation wrapping
        $repo := $repo.repo
          if $repo ~~ CompUnit::Repository::Distribution;

        my $prefix       := $repo.prefix;
        my $distribution := $compunit.distribution;
        if $repo ~~ CompUnit::Repository::Installation {
            with $distribution.meta<source> {
                return $prefix.add("sources/$_");
            }
        }
        elsif $repo ~~ CompUnit::Repository::FileSystem {
            with $distribution.meta<provides> {
                return $prefix.add(.{short-name($identity)});
            }
        }
    }
    Nil
}

my sub source(str $identity, $REPO?) {
    with source-io($identity, $REPO) {
        .e ?? .slurp !! Nil
    }
    else {
        Nil
    }
}

my sub bytecode-io(str $identity, $REPO?) {
    with compunit($identity, $REPO, :need) {
        my $repo := .repo;

        # Get rid of installation wrapping
        $repo := $repo.repo
          if $repo ~~ CompUnit::Repository::Distribution;

        my $io := $repo.prefix;
        if $repo ~~ CompUnit::Repository::Installation {
            $io := $io.add("precomp");
        }
        elsif $repo ~~ CompUnit::Repository::FileSystem {
            $io := $io.add(".precomp");
        }
        else {
            return Nil;
        }

        my $repo-id := .repo-id;
        $io.add(Compiler.id).add($repo-id.substr(0,2)).add($repo-id)
    }
    else {
        Nil
    }
}

my sub bytecode(str $identity, $REPO?) {
    with bytecode-io($identity, $REPO) {
        .e ?? .slurp(:bin) !! Nil
    }
    else {
        Nil
    }
}

my sub EXPORT(*@names) {
    Map.new: @names
      ?? @names.map: {
             if UNIT::{"&$_"}:exists {
                 UNIT::{"&$_"}:p unless %imports{$_}
             }
             else {
                 my ($in,$out) = .split(':', 2);
                 if $out
                   && !%imports{$in}
                   && UNIT::{"&$in"} -> &code {
                     Pair.new: "&$out", &code
                 }
             }
         }
      !! UNIT::.grep: {
             .key.starts-with('&')
               && !(.key eq '&EXPORT')
               && !%imports{.key.substr(1)}
         }
}

# vim: expandtab shiftwidth=4
