use strict;
use warnings;
use ExtUtils::MakeMaker;

my $os_supproted = $^O eq 'linux';

die("OS unsupported\n") unless $os_supproted;

# Test::TCP has socket leaks in 2.15, lets avoid using it for testing
$test_tcp_minimum_version = 0;
if (eval { require Test::TCP; $Test::TCP::VERSION == 2.15 }) {
    $test_tcp_minimum_version = '2.16';
}

WriteMakefile(
    NAME             => 'Test::NoLeaks',
    AUTHOR           => q{binary.com <perl@binary.com>},
    VERSION_FROM     => 'lib/Test/NoLeaks.pm',
    ABSTRACT         => 'Memory and file descriptor leak detector',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.10.0',
    clean            => { FILES => 'Test-NoLeaks-*' },
    ( eval { ExtUtils::MakeMaker->VERSION(6.64) } ?
        (
            CONFIGURE_REQUIRES => {
                "ExtUtils::MakeMaker" => "6.64",
            },
            PREREQ_PM          => {
                "Test::More" => 0,
                "POSIX"      => 0,
            },
            TEST_REQUIRES      => {
                "File::Temp"     => 0,
                "Test::TCP"      => $test_tcp_minimum_version,
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
