#!/usr/bin/perl

use strict;
use Getopt::Long;
use Pod::Usage;
use DBI;

my ($help, $boardlist_file);
my ($db_type, $db_host, $db_name, $db_user, $db_pass);

$db_type = "Pg";
$db_host = "localhost";
$db_name = "boardfarm";
$db_user = "postgres";
$db_pass = 'a';

GetOptions( 
    "help|?"        => \$help,
    "boardlist|b=s" => \$boardlist_file
) or pod2usage({'-verbose' => 0, '-exitval' => 1});

pod2usage({'-verbose' => 1, '-exitval' => 0}) if $help;
pod2usage({'-verbose' => 1, '-exitval' => 0}) unless $boardlist_file;

=head1 DESCRIPTION

Connects to database and marks the boards listed in the boardlist file as having been physically verified.

=back

=head1 OPTIONS

=over

=item --help, -?

Prints help and usage information.

=item --boardlist, -b

File containing list of newline delimited board names to mark as verified.

=back

=cut

# read list of verified boards from boardlist file
my @boardlist;
open BOARDLIST_FILE, '<', $boardlist_file or die "Error opening BOARDLIST_FILE '$boardlist_file'";
chomp(@boardlist = <BOARDLIST_FILE>);
close BOARDLIST_FILE;

# connect to database
my $dbh = DBI->connect("dbi:$db_type:dbname=$db_name;host=$db_host", $db_user, $db_pass);

# get list of boards from inventory for ensuring boardnames are valid
my $q = $dbh->prepare("SELECT board FROM inventory");
my $r = $q->execute();
if ($r < 0) {
    die $DBI::errstr;
}

# precompute hash keyed by boardnames for fast check to ensure a particular boardname is valid
my $boardlist_hash = {};
while (my @row = $q->fetchrow_array()) {
    $boardlist_hash->{$row[0]} = 1;
}

# for every board specified in the boardlist file, if the board name is valid, update the verified
# timestamp in the database
foreach (@boardlist) {
    if ($boardlist_hash->{$_}) {
        my $t = time();
        $q = $dbh->prepare("UPDATE inventory SET verified=$t WHERE board=?");
        $q->bind_param(1, $_);
        $q->execute() or die $DBI::errstr;
        print "verified $_\n";
    } else {
        print "$_ not in inventory\n";
    }
}

$dbh->disconnect();
