use strict;
use warnings;

use File::Temp qw/tempfile/;
use IO::Socket::INET;
use Net::EmptyPort qw/empty_port/;
use Test::More;
use Test::NoLeaks qw/noleaks/;
use Test::Warnings;

# Non-tolerate way might trigger memory false memory leaks report

# request large array, that should trigger additional memory alloactions
# might trigger or might not on perl 5.8, so we test only for
# Test::Warnings
noleaks(
    code          => sub { my $x = "a" x (10_000_000); },
    track_memory  => 1,
    track_fds     => 0,
    passes        => 5,
    warmup_passes => 0,
);

done_testing;
