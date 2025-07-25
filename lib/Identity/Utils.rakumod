use String::Utils:ver<0.0.35+>:auth<zef:lizmat>
  <after before between between-included text-from-url>;  # UNCOVERABLE

#- helper subs -----------------------------------------------------------------
# Extract the text between a given foo< >
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

#- api -------------------------------------------------------------------------
my sub api(str $identity) {
    extract $identity, ':api'
}

#- auth ------------------------------------------------------------------------
my sub auth(str $identity) {
    extract $identity, ':auth'
}

#- build -----------------------------------------------------------------------
my proto sub build(|) {*}
my multi sub build(%meta) {
    my %args;
    %args<ver>  := $_ with %meta<version>;
    %args<auth> := $_ with %meta<auth>;
    with %meta<api>  {
        if .Str -> $api {
            %args<api> := $api;  # UNCOVERABLE
        }
    }
    build %meta<name>, |%args
}
my multi sub build(Str:D $short-name,
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
my multi build(Any:U $_) {
    build .^name, :ver(.^ver), :auth(.^auth), :api(.^api)
}

#- bytecode --------------------------------------------------------------------
my sub bytecode(str $identity, $REPO?) {
    with bytecode-io($identity, $REPO) {
        .e ?? .slurp(:bin) !! Nil
    }
    else {
        Nil
    }
}

#- bytecode-io -----------------------------------------------------------------
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
        elsif $repo ~~ CompUnit::Repository::FileSystem {  # UNCOVERABLE
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

#- compunit --------------------------------------------------------------------
my sub compunit(str $identity, $REPO? is copy, :$need) {
    if $REPO.defined {
        if $REPO ~~ Str | IO::Path {
            $REPO = CompUnit::Repository::FileSystem.new(
              :prefix($REPO),
              :next-repo($*REPO)
            );
        }
        elsif $REPO ~~ CompUnit::Repository {  # UNCOVERABLE
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

#- dependencies-from-depends ---------------------------------------------------
my sub dependencies-from-depends($depends) {
    if $depends ~~ Positional {
        $depends.grep({ $_ ~~ Str })
    }
    elsif $depends ~~ Associative {
        if $depends<runtime><requires> -> $requires {
            $requires.map: {
                $_ ~~ Associative
                  ?? build .<name> // '',
                       :ver(.<ver>), :auth(.<auth>),
                       :api(.<api>), :from(.<from>)
                  !! $_
            } if $requires ~~ Positional
        }
    }
    elsif $depends ~~ Str {  # UNCOVERABLE
        ($depends,)
    }
}

#- dependencies-from-identity --------------------------------------------------
my sub dependencies-from-identity(str $identity, $REPO?) {
    with meta($identity, $REPO) -> %meta {
        dependencies-from-depends($_) with %meta.<depends>
    }
}

#- dependency-specification ----------------------------------------------------
my sub dependency-specification(str $identity) {
     CompUnit::DependencySpecification.new:
       short-name   => short-name($identity),
       auth-matcher => auth($identity) // True,
       ver-matcher  => ver($identity)  // True,
       api-matcher  => api($identity)  // True
}

#- ecosystem -------------------------------------------------------------------
my sub ecosystem(str $identity) {
    with auth($identity) -> $auth {
        before $auth, ':'
    }
    else {
        Nil
    }
}

#- from ------------------------------------------------------------------------
my sub from(str $identity) {
    extract $identity, ':from'
}

#- is-pinned -------------------------------------------------------------------
my sub is-pinned(str $identity) {
    so auth($identity)
      && (my $version := version $identity)
      && !$version.plus
      && !$version.whatever
}

#- is-short-name ---------------------------------------------------------------
my sub is-short-name(str $identity) {
    short-name($identity) eq $identity
}

#- latest-successors -----------------------------------------------------------
my sub latest-successors(@identities) {
    my %by-short-name;
    %by-short-name{short-name $_}{auth $_} = $_ for @identities;

    %by-short-name.sort(*.key).map: {
        my %by-auth := .value;

        # Only the one, we're done
        if %by-auth == 1 {
            %by-auth.values.head
        }

        else {
            my %by-eco;
            %by-eco{before .key, ":"}.push(.value) for %by-auth;
            (%by-eco<zef> // %by-eco<cpan> // %by-eco<github>).Slip
        }
    }
}

#- meta ------------------------------------------------------------------------
my sub meta(str $identity, $REPO?) {
    with compunit($identity, $REPO) {
        my $d := .distribution;
        $d.meta<foo>; # dummy lookup to vivify full meta hash
        $d.meta
    }
    else {
        Nil
    }
}

#- nick ------------------------------------------------------------------------
my sub nick(str $identity) {
    with auth($identity) -> $auth {
        after $auth, ':'
    }
    else {
        Nil
    }
}

#- raku-land-url ---------------------------------------------------------------
my sub raku-land-url(str $id) {
    "https://raku.land/&auth($id)/&short-name($id)?v=&ver($id)"
}

#-rea-dist ---------------------------------------------------------------------
my sub rea-dist(
  str  $id,
  IO() $io = ".",
  str  $extension = 'tar.gz',
      :$verbose
) {
    my $output := $io.d ?? $io.add("$id.$extension") !! $io;

    my $proc := run
      'curl', '--location', '--fail', '--output', $output,
      rea-dist-url($id, $extension),
      :out, :err
    ;
    if $proc.exitcode {
        put $proc.err.slurp if $verbose;
        False
    }
    else {
        True
    }
}

#-rea-dist-url -----------------------------------------------------------------
my sub rea-dist-url(str $id, str $extension = 'tar.gz') {
    ( "https://github.com/Raku/REA/raw/refs/heads/main/archive",
      $id.substr(0,1), short-name($id), $id
    ).join("/") ~ ".$extension"
}

#-rea-index---------------------------------------------------------------------
my sub rea-index(:$verbose) { text-from-url rea-index-url, :$verbose }

#- rea-index-url ---------------------------------------------------------------
my sub rea-index-url() {
    "https://raw.githubusercontent.com/Raku/REA/refs/heads/main/META.json"  # UNCOVERABLE
}

#-rea-meta ---------------------------------------------------------------------
my sub rea-meta(str $id, :$verbose) {
    text-from-url rea-meta-url($id), :verbose
}

#-rea-meta-url -----------------------------------------------------------------
my sub rea-meta-url(str $id) {
    ( "https://raw.githubusercontent.com/Raku/REA/refs/heads/main/meta",
      $id.substr(0,1), short-name($id), $id
    ).join("/") ~ ".json"
}

#- remove ----------------------------------------------------------------------
my sub remove(str $identity, str $needle) {
    if between-included($identity, $needle ~ '<', '>')
      // between-included($identity, $needle ~ '(', ')') -> str $string {
        $identity.subst($string)
    }
    else {
        $identity
    }
}

#- sanitize --------------------------------------------------------------------
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

#- short-name ------------------------------------------------------------------
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

#- source ----------------------------------------------------------------------
my sub source(str $identity, $REPO?) {
    with source-io($identity, $REPO) {
        .e ?? .slurp !! Nil
    }
    else {
        Nil
    }
}

#- source-io -------------------------------------------------------------------
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
        elsif $repo ~~ CompUnit::Repository::FileSystem {  # UNCOVERABLE
            with $distribution.meta<provides> {
                return $prefix.add(.{short-name($identity)});
            }
        }
    }
    Nil
}

#- ver -------------------------------------------------------------------------
my sub ver(str $identity) {
    extract $identity, ':ver'
}

#- version ---------------------------------------------------------------------
my sub version(str $identity) {
    (.Version with extract $identity, ':ver') // Nil
}

#- without-api -----------------------------------------------------------------
my sub without-api(str $identity) {
    remove $identity, ':api'
}

#- without-auth ----------------------------------------------------------------
my sub without-auth(str $identity) {
    remove $identity, ':auth'
}

#- without-from ----------------------------------------------------------------
my sub without-from(str $identity) {
    remove $identity, ':from'
}

#- without-ver -----------------------------------------------------------------
my sub without-ver(str $identity) {
    remove $identity, ':ver'
}

#-zef-index---------------------------------------------------------------------
my sub zef-index(:$verbose) { text-from-url zef-index-url, :$verbose }

#- zef-index-url ---------------------------------------------------------------
my sub zef-index-url() {
    'https://360.zef.pm'  # UNCOVERABLE
}

#- EXPORT ----------------------------------------------------------------------
my sub EXPORT(*@names) {
    my constant marker = "(Identity::Utils)";
    Map.new: @names
      ?? @names.map: {
             if UNIT::{"&$_"} -> &code {
                 Pair.new("&$_", &code)
                   if &code.file.ends-with(marker);
             }
             else {
                 my ($in,$out) = .split(':', 2);
                 if $out && UNIT::{"&$in"} -> &code {
                     Pair.new("&$out", &code)
                       if &code.file.ends-with(marker);
                 }
             }
         }
      !! UNIT::.grep: {
             .key.starts-with('&')
               && !(.key eq '&EXPORT' | '&extract')
               && .value.file.ends-with(marker)
         }
}

#- hack ------------------------------------------------------------------------
# To allow version / auth / api fetching
module Identity::Utils:ver<0.0.24>:auth<zef:lizmat> { }

# vim: expandtab shiftwidth=4
