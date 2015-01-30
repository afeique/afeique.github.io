#!/usr/bin/perl

use strict;
use POSIX;
use Math::Complex;

# check args
if ($#ARGV < 0) {
    print "\nUsage:\n\t$0 PACKAGE\n";
    print "\nDescription:\n\tSelects random number of reverse dependencies for the specified package and adds them to ./.config.\n";
    exit;
}

my $package = @ARGV[0];
`./bin/whatrequires.sh $package -all > ./rdep`;

open RDEP, '<', "./rdep" or die "Error reading reverse dependencies for package";
chomp(my @rdeps_raw = <RDEP>);
close RDEP;

`rm -f ./rdep`;

# treat optional reverse deps like normal reverse deps
my @rdeps;
foreach (@rdeps_raw) {
    /([^\s]+)(\s\[Optional\])?/;
    push @rdeps, $1;
}

# implementation of Jerry's algorithm for deciding how many reverse deps to pull
my $num_deps = int(scalar @rdeps);
my $n = $num_deps+1;
my $m = ($n*($n+1))/2;
my $x = int(rand($m));
my $a = floor( (sqrt(8*$x + 1)-1)/2 );
my $f = $num_deps-$a;

#my $i;
#my @rdeps_sel;
#for ($i=0; $i<$f; $i++) {
#    my $j = int(rand($f));
#    push @rdeps_sel, $rdeps[$j];
#}

open CONFIG, '>', ".config.rdep" or die "Error opening .config";
foreach (@rdeps) {
    print CONFIG "TSWO_SOFTWARE_". $_ ."=y\n";
}
close CONFIG;

`cat .config.rdep | sort -R | head -n$f >> .config`;
`rm .config.rdep`;
