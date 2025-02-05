use String::Utils:ver<0.0.32+>:auth<zef:lizmat>
  <after before between between-included>;

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
               && !(.key eq '&EXPORT')
               && .value.file.ends-with(marker)
         }
}

my @auths = q:to/AUTHS/.lines;
ABC:ver<0.6.13>:auth<zef:colomon>
ACME::Fez:ver<1>:auth<zef:zef>
ACME::Fez:ver<3>:auth<zef:tony-o>
ADT:ver<0.5>:auth<github:timo>
AI::Agent:ver<0.2.10>:auth<cpan:KOBOLDWIZ>:api<1>
AI::FANN:ver<0.0.1>:auth<github:perlpilot>
AI::FANN:ver<0.1.0>:auth<github:jjatria>
AI::FANN:ver<0.1.0>:auth<github:raku-community-modules>
AI::FANN:ver<0.2.0>:auth<zef:jjatria>
AI::NLP:ver<0.1.5>:auth<cpan:KOBOLDWIZ>:api<1>
Abbreviations:ver<0.3.3>:auth<cpan:TBROWDER>
Abbreviations:ver<1.0.0>:auth<cpan:TBROWDER>:api<2>
Abbreviations:ver<2.2.2>:auth<zef:tbrowder>:api<2>
AccessorFacade:ver<0.1.0>:auth<cpan:JSTOWE>:api<1.0>
AccessorFacade:ver<0.1.2>:auth<zef:jonathanstowe>:api<1.0>
AccountableBagHash:ver<0.0.3>:auth<cpan:ELIZABETH>
AccountableBagHash:ver<0.0.6>:auth<zef:lizmat>
Acme::Addslashes:ver<0.1.2>:auth<github:xfix>
Acme::Advent::Highlighter:ver<1.002002>:auth<github:raku-community-modules>
Acme::Anguish:ver<1.001002>:auth<github:raku-community-modules>
Acme::Anguish:ver<1.2>:auth<zef:raku-community-modules>
Acme::BaseCJK:ver<0.0.1>:auth<zef:Kaiepi>
Acme::Cow6:ver<0.0.1>:auth<cpan:ELIZABETH>
Acme::Cow:ver<0.0.4>:auth<cpan:ELIZABETH>
Acme::Cow:ver<0.0.5>:auth<zef:lizmat>
Acme::Cow:ver<0.2>:auth<github:hankache>
Acme::DSON:ver<0.2.1>:auth<github:xfix>
Acme::Don't:ver<0.0.2>:auth<cpan:ELIZABETH>
Acme::Don't:ver<0.0.3>:auth<zef:lizmat>
Acme::Flutterby:ver<0.01>:auth<github:byterock>
Acme::Insult::Lala:ver<0.0.5>:auth<cpan:JSTOWE>:api<1.0>
Acme::Insult::Lala:ver<0.0.7>:auth<zef:jonathanstowe>:api<1.0>
Acme::Mangle:ver<v0.1.0>:auth<github:MadcapJake>
Acme::Meow:ver<0.1>:auth<cpan:TADZIK>
Acme::Meow:ver<0.1>:auth<github:tadzik>
Acme::Meow:ver<0.2>:auth<zef:raku-community-modules>
Acme::Overreact:ver<0.0.1>:auth<zef:FCO>
Acme::OwO:ver<0.2>:auth<github:kawaii>
Acme::Polyglot::Levenshtein::Damerau:ver<0.1>:auth<cpan:UGEXE>
Acme::Rautavistic::Sort:ver<0.0.1>:auth<zef:renormalist>
Acme::Scrub:ver<0.2.1>:auth<github:thundergnat>
Acme::Scrub:ver<0.2.1>:auth<zef:thundergnat>
Acme::Skynet:ver<0.0.3>:auth<github:kmwallio>
Acme::Sudoku:ver<0.0.2>:auth<github:pierre-vigier>
Acme::Test::Module::Zef:ver<0.0.5>:auth<zef:skaji>
Acme::Test::Module:ver<1.0.4>:auth<cpan:SKAJI>
Acme::Text::UpsideDown:ver<0.0.4>:auth<cpan:ELIZABETH>:api<perl6>
Acme::Text::UpsideDown:ver<0.0.9>:auth<zef:lizmat>:api<perl6>
Acme::WTF:ver<1.0>:auth<github:Skarsnik>
Acme::ಠ_ಠ:ver<0.0.1>:auth<cpan:ELIZABETH>
Actor:ver<0.0.1>:auth<cpan:LEONT>
Adventure::Engine:ver<0.4.0>:auth<github:masak>
Adverb::Eject:ver<0.0.1>:auth<cpan:ELIZABETH>
Adverb::Eject:ver<0.0.4>:auth<zef:lizmat>
Algorithm::AhoCorasick:ver<0.0.13>:auth<cpan:TITSUKI>
Algorithm::BinaryIndexedTree:ver<0.0.8>:auth<zef:titsuki>
Algorithm::BinaryIndexedTree:ver<0.05>:auth<github:titsuki>
Algorithm::BloomFilter:ver<0.1.0>:auth<github:yowcow>
Algorithm::DawkinsWeasel:ver<0.1.1>:auth<github:jaldhar>
Algorithm::Diff:ver<0.0.1>:auth<github:Takadonet>
Algorithm::Diff:ver<0.0.4>:auth<zef:raku-community-modules>
Algorithm::Elo:ver<0.1.0>:auth<github:hoelzro>
Algorithm::Elo:ver<0.1.1>:auth<zef:raku-community-modules>
Algorithm::Evolutionary::Simple:ver<0.0.8>:auth<cpan:JMERELO>
Algorithm::Evolutionary::Simple:ver<0.0.8>:auth<zef:jjmerelo>
Algorithm::Genetic:ver<0.0.2>:auth<github:samgwise>
Algorithm::GooglePolylineEncoding:ver<1.0.3>:auth<cpan:SCIMON>
Algorithm::Heap::Binary:ver<0.0.1>:auth<cpan:CONO>
Algorithm::HierarchicalPAM:ver<0.0.2>:auth<cpan:TITSUKI>
Algorithm::KDimensionalTree:ver<0.0.3>:auth<zef:antononcube>
Algorithm::KDimensionalTree:ver<0.1.1>:auth<zef:antononcube>:api<1>
Algorithm::KdTree:ver<0.0.8>:auth<zef:titsuki>
Algorithm::KdTree:ver<0.05>:auth<github:titsuki>
Algorithm::Kruskal:ver<0.0.1>:auth<zef:titsuki>
Algorithm::LBFGS:ver<0.0.6>:auth<cpan:TITSUKI>
Algorithm::LCS:ver<0.1.0>:auth<github:hoelzro>
Algorithm::LCS:ver<0.1.1>:auth<zef:raku-community-modules>
Algorithm::LDA:ver<0.0.10>:auth<cpan:TITSUKI>
Algorithm::LibSVM:ver<0.0.16>:auth<cpan:TITSUKI>
Algorithm::LibSVM:ver<0.0.18>:auth<zef:titsuki>
Algorithm::Manacher:ver<0.0.1>:auth<cpan:TITSUKI>
Algorithm::MinMaxHeap:ver<0.13.5>:auth<cpan:TITSUKI>
Algorithm::NaiveBayes:ver<0.0.5>:auth<cpan:TITSUKI>
Algorithm::SetUnion:ver<0.0.1>:auth<cpan:TITSUKI>
Algorithm::SkewHeap:ver<0.0.1>:auth<cpan:JEFFOBER>
Algorithm::Soundex:ver<0.2>:auth<zef:raku-community-modules>
Algorithm::SpiralMatrix:ver<0.6.0>:auth<github:mj41>
Algorithm::Tarjan:ver<0.01>:auth<github:finanalyst>
Algorithm::TernarySearchTree:ver<0.0.5>:auth<zef:titsuki>
Algorithm::TernarySearchTree:ver<0.04>:auth<github:titsuki>
Algorithm::Treap:ver<0.10.0>:auth<github:titsuki>
Algorithm::Treap:ver<0.10.3>:auth<zef:titsuki>
Algorithm::Trie::libdatrie:ver<0.2>:auth<github:zengargoyle>
Algorithm::XGBoost:ver<0.0.5>:auth<cpan:TITSUKI>
Algorithm::XGBoost:ver<0.0.6>:auth<zef:titsuki>
actions:ver<0.0.2>:auth<zef:lizmat>
ake:ver<0.1.0>:auth<github:Raku>
ake:ver<0.1.3>:auth<zef:raku-community-modules>
AUTHS

.say for latest-successors(@auths);

# vim: expandtab shiftwidth=4
