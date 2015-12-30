use strict;
use warnings;
use Devel::CheckOS qw/die_unsupported os_is/;
use ExtUtils::MakeMaker;

my $os_supproted = os_is 'Linux';

die_unsupported unless $os_supproted;

WriteMakefile(
    NAME             => 'Test::NoLeaks',
    AUTHOR           => q{binary.com <perl@binary.com>},
    VERSION_FROM     => 'lib/Test/NoLeaks.pm',
    ABSTRACT         => 'Memory and file descriptor leak detector',
    LICENSE          => 'Artistic_2_0',
    MIN_PERL_VERSION => '5.10.0',
    ( eval { ExtUtils::MakeMaker->VERSION(6.64) } ?
        (
            CONFIGURE_REQUIRES => {
                "Devel::CheckOS"      => '0',
                "ExtUtils::MakeMaker" => "6.64",
            },
            PREREQ_PM          => {
                "Test::More" => 0,
                "POSIX"      => 0,
            },
            TEST_REQUIRES      => {
                "File::Temp"     => 0,
                "Test::TCP"      => 0,
                "IO"             => 0,
                "Test::Warnings" => 0,
            },
            META_MERGE => {
                'meta-spec' => { version => 2 },
                resources   => {
                    repository => {
                        type => 'git',
                        url  => 'https://github.com/binary-com/perl-Test-NoLeaks.git',
                        web  => 'https://github.com/binary-com/perl-Test-NoLeaks',
                    },
                }
            }
        ) : (
            PREREQ_PM => {
                "Devel::CheckOS"      => '0',
                "ExtUtils::MakeMaker" => '6.64',
                "Test::More"          => 0,
                "POSIX"               => 0,
                "File::Temp"          => 0,
                "Test::TCP"           => 0,
                "IO"                  => 0,
            },
        )
    ),
);
