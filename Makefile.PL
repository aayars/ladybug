use ExtUtils::MakeMaker;

my $prereqs = {
  Cache::Memcached::Fast => 0.16,
  Clone                  => 0.31,
  Data::GUID             => 0.045,
  Digest::SHA1           => 2.12,
  Error                  => 0.17015,
  File::HomeDir          => 0.86,
  File::Tempdir          => 0.02,
  GlobalDBI              => 0.21,
  Math::VecStat          => 0.08,
  Rcs                    => 1.05,
  Test::Simple           => 0.94,
  Time::Piece            => 1.12, # CPAN won't remove Darwin's older version?
  Unicode::String        => 2.09,
  URI                    => 1.40,
  YAML::Syck             => 1.07,
};

WriteMakefile(
  VERSION_FROM => 'lib/Devel/Ladybug.pm',
  NAME         => 'Devel::Ladybug',
  PREREQ_PM    => $prereqs,
  LICENSE      => 'open_source',
  AUTHOR       => 'Alex Ayars <pause@nodekit.org>',
  EXE_FILES =>
    [ 'bin/ladybug-conf', 'bin/ladybug-edit', 'bin/ladybug-dump' ],
);