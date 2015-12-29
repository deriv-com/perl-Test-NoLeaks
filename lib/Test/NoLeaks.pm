package Test::NoLeaks;

use strict;
use warnings;
use POSIX qw/sysconf _SC_PAGESIZE/;
use Test::Builder;
use Test::More;

our $VERSION = '0.01_1';

use base qw(Exporter);

our @EXPORT = qw/test_noleaks/;
our @EXPORT_OK = qw/noleaks/;

my $PAGE_SIZE;

BEGIN {
    no strict "subs";
    *_platform_mem_size = _linux_mem_size;
    *_platform_fds = _linux_fds;
    $PAGE_SIZE = sysconf(_SC_PAGESIZE)
      or die("page size cannot be determined, Test::NoLeaks cannot be used");
}

sub _linux_mem_size {
    my $class = shift;

    open(my $fh, '<', '/proc/self/statm')
        or die("couldn't access /proc/self/status : $!");

    my $line = <$fh>;
    my ($pages) = (split / /, $line)[0];
    return $pages * $PAGE_SIZE;
}

sub _linux_fds {
    my $fd_dir = '/proc/self/fd';
    opendir(my $dh, $fd_dir) || die "can't opendir $fd_dir: $!";
    my $open_fd_count = () = readdir($dh);
    closedir $dh;
    return $open_fd_count;
}


sub _noleaks(%) {
    my %args = @_;

    # check arguments
    my $code = $args{code};
    die("code argument (CODEREF) isn't provided")
        if (!$code || !(ref($code) eq 'CODE'));

    my $track_memory = $args{'track_memory'};
    my $track_fds    = $args{'track_fds'};
    die("don't know what to track (i.e. no 'track_memory' nor 'track_fds' are specified)")
        if (!$track_memory && !$track_fds);

    my $passes = $args{passes} || 100;
    die("passes count too small (should be at least 2)")
        if $passes < 2;

    my $warmup_passes = $args{warmup_passes} || 0;
    die("warmup_passes count too small (should be non-negative)")
        if $passes < 0;

    my %leaked_at; # key: pass, value array[$mem_leak, $fds_leak]

    # warm-up phase
    # a) warm up code
    $code->() for (1 .. $warmup_passes);

    # b) warm-up package itself, as it might cause additional memory (re) allocations
    # (ignore results)
    _platform_mem_size if $track_memory;
    _platform_fds if $track_fds;
    %leaked_at = map { $_ => [0, 0] } (1 .. $passes);

    # reset warmed-up leaked_at hash
    %leaked_at = ();

    my ($total_mem_leak, $total_fds_leak, $memory_hits) = (0, 0, 0);

    # execution phase
    for my $pass (1 .. $passes) {
        my ($mem_t0, $fds_t0, $mem_t1, $fds_t1) = (0, 0, 0, 0);
        $mem_t0 = _platform_mem_size if $track_memory;
        $fds_t0 = _platform_fds if $track_fds;
        $code->();
        $mem_t1 = _platform_mem_size if $track_memory;
        $fds_t1 = _platform_fds if $track_fds;

        my $leaked_mem = $mem_t1 - $mem_t0;
        $leaked_mem = 0 if ($leaked_mem < 0);

        my $leaked_fds = $fds_t1 - $fds_t0;
        $leaked_fds = 0 if ($leaked_fds < 0);

        if (($leaked_mem > 0) || ($leaked_fds > 0)) {
            $leaked_at{$pass} = [$leaked_mem, $leaked_fds];
            $total_mem_leak += $leaked_mem;
            $total_fds_leak += $leaked_fds;
        }
        $memory_hits++ if ($leaked_mem > 0);
    }

    return ($total_mem_leak, $total_fds_leak, $memory_hits, \%leaked_at);
}



sub noleaks(%) {
    my %args = @_;

    my ($mem, $fds, $mem_hits, $details) = _noleaks(%args);

    my $tolerate_hits = $args{tolerate_hits} || 0;
    my $track_memory  = $args{'track_memory'};
    my $track_fds     = $args{'track_fds'};

    my $has_fd_leaks = $track_fds && ($fds > 0);
    my $has_mem_leaks = $track_memory && ($mem > 0) && ($mem_hits > $tolerate_hits);
    return !($has_fd_leaks || $has_mem_leaks);
}

sub test_noleaks(%) {
    my %args = @_;
    my ($mem, $fds, $mem_hits, $details) = _noleaks(%args);

    my $tolerate_hits = $args{tolerate_hits} || 0;
    my $track_memory  = $args{'track_memory'};
    my $track_fds     = $args{'track_fds'};

    my $has_fd_leaks = $track_fds && ($fds > 0);
    my $has_mem_leaks = $track_memory && ($mem > 0) && ($mem_hits > $tolerate_hits);
    my $has_leaks = $has_fd_leaks || $has_mem_leaks;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if (!$has_leaks) {
        pass("no leaks have been found");
    } else {
      my $summary = "Leaked "
        . ($track_memory ? "$mem bytes ($mem_hits hits) " : "")
        . ($track_fds    ? "$fds file descriptors" : "");

      my @lines;
      while (my ($pass, $v) = each(%$details)) {
        my $line = "pass $pass, leacked: "
          . ($track_memory ? $v->[0] . " bytes " : "")
          . ($track_fds    ? $v->[1] . "file descriptors" : "");
        push @lines, $line;
      }
      my $report = join("\n", @lines);

      note($report);
      fail("$summary");
    }
}

1;
