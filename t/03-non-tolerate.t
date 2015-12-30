use strict;
use warnings;

use File::Temp qw/tempfile/;
use IO::Socket::INET;
use Net::EmptyPort qw/empty_port/;
use Test::More;
use Test::NoLeaks qw/noleaks/;
use Test::Warnings;

# request large array, that should trigger additional memory alloactions
ok !noleaks(
    code          => sub {
        my @list;
        for (my $i = 0; $i < 25000; $i++) {
            push @list, map { rand } (1 .. 10);
        }
    },
    track_memory  => 1,
    track_fds     => 0,
    passes        => 5,
    warmup_passes => 0,
  ), "non-tolerate way might trigger memory false memory leaks report";


done_testing;
