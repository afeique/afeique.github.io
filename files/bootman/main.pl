#!/usr/bin/perl

use strict;
use Net::OpenSSH;
use Getopt::Long;
use Pod::Usage;
use Net::Telnet;
use DBI;
use File::Fetch;
use File::Basename;

# need to run as root because setup.sh requires root for NFS operations
die "error: script must be run as root\n" unless $> == 0;

my ($help, $use_dburis_flag, $take_inventory_flag, $do_boottest_flag, $out);
my ($barn_host, $barn_user, $barn_pass);
my ($db_type, $db_host, $db_name, $db_user, $db_pass, $dbh, $q, $r, @row);
my ($uris_file, @urilist, $uris);
my (@boardlist, $boards, $statuses);

$barn_host = "someserver";
$barn_user = "testuser";
$barn_pass = "abc123";

$db_type = "Pg";
$db_host = "localhost";
$db_name = "bootman";
$db_user = "postgres";
$db_pass = 'a';

# connect to database
$dbh = DBI->connect("dbi:$db_type:dbname=$db_name;host=$db_host", $db_user, $db_pass);

# set trace level so all prepared queries are captured
open my $stdout, '>&', STDOUT;
$dbh->trace('SQL', $stdout);

# getopt long
# http://perldoc.perl.org/Getopt/Long.html
GetOptions( 
    "help|?"            => \$help,
    "uris-file|u=s"     => \$uris_file,
    "inventory|i"       => \$take_inventory_flag,
    "boottest|b"        => \$do_boottest_flag
) or pod2usage({'-verbose' => 0, '-exitval' => 1});

pod2usage({'-verbose' => 1, '-exitval' => 0}) if $help;
pod2usage({'-verbose' => 1, '-exitval' => 0}) if (!$take_inventory_flag and !$do_boottest_flag);

=head1 SYNOPSIS

=over

At least one operation must be specified: --inventory (-i) or --boottest (-b). Regardless of operation, connects to board farm via SSH to get a list of all boards. 

For the boottest operation, when no URIs file is specified, database URIs are used instead. Kernel images, RFS tarballs, and device-tree blobs are downloaded locally using Perl's File::Fetch library. The setup.sh script transfers these files to the barn via NFS and then updates barn symlinks. Both before and after the boottest, shellcheck.sh is used to retrieve hostname and uname information. 

Results of all operationss are stored to the database.

=back

=head1 OPTIONS

=over

=item -?, --help

Prints help and usage information.


=item -u, --uris-file=FILE

File containing paths to images and RFS tarballs to boottest for specified boards. If no file is specified, database URIs will be used instead.

=item -i, --inventory

Take inventory of all the boards in the boardfarm.

=item -b, --boottest

Perform boottests for all the boards in the URIs file and log the results. Uses database URIs if no file is specified.

=back

=cut

#
# COMMON LOGIC
#

# this is logic common to both the inventory and boottest operations

print "-- establishing SSH connection to barn...";

$main::barn_ssh = Net::OpenSSH->new(
    $barn_host,
    user        => $barn_user,
    password    => $barn_pass
);

$main::barn_ssh->error and die "\nerror: ". $main::barn_ssh->error;

print " ok\n";

print "-- validating board names\n";

print "querying barn for list of boards\n";

# get list of boards in the barn
$out = run_bf_cmd("list");
die "error: could not retrieve list of boards, try running script again\n" unless $out;
@boardlist = split "\n", $out;

print "generating boardlist hash from barn list\n";

# use the @boardlist array to generate a hash keyed by boardname
# we will use this hash as a fast lookup to see if a particular boardname is valid
my $boards = {};
foreach (@boardlist) {
    $boards->{$_} = 1;
}

#
# BOOTTEST LOGIC
#

if ($do_boottest_flag) {
    # hash to keep track of all board statuses
    $statuses = {};

    # hash to store paths to kernel images, rfs tarballs, and device-tree blobs
    $uris = {};

    # read each line of the URIs file into an array and validate the boardnames
    # if no URIs file was specified, read URIs from the database
    if ($uris_file) {
        print "-- reading URIs from file...";
        open URIS_FILE, '<', $uris_file or die "error opening URIS_FILE '$uris_file'";
        chomp(@urilist = <URIS_FILE>);
        close URIS_FILE;

        # parse each line from the URIs file into a hash of hashes keyed by boardname
        foreach (@urilist) {
            if ($_ =~ m/^([^\|]+)\|([^\|]+)\|([^\|]+)|(.+)$/) {
                $uris->{$1} = {
                    "kernel_image_uri"  => $2,
                    "rfs_tarball_uri"   => $3,
                    "devicetree_uri"    => $4
                };
            }
        }

        print "checking board names against boardlist hash\n";

        # loop through all the images in the imagelist, print a warning for every invalid boardname,
        # then delete invalid boardnames from our internal list of images ($uris)
        # use the hash we generated earlier $boards as a fast lookup for valid boardnames
        foreach (keys $uris) {
            if ($boards->{$_}) {
                print "'$_' is a valid board name\n";

                # get board status from boardfarm
                my $status = getBoardStatus($_);
                printStatus($status);

                if ($status->{free} == 0 && $status->{user} != $main::barn_user) {
                    print "$_ is not free, board will be skipped during boottest\n";
                    delete $uris->{$_};
                }

                $statuses->{$_} = {};
                $statuses->{$_}->{before} = $status;

            } else {
                print "warning: '$_' is not a valid board name, board will be skipped during boottest\n";
                delete($uris->{$_});
            }
        }
    } else {
        print "-- reading URIs from database\n";
        print "db: querying database for all boards in the inventory and their URIs\n";
        $q = $dbh->prepare("SELECT i.board,u.kernel_image,u.rfs_tarball,u.devicetree FROM inventory i LEFT JOIN uris u ON i.id=u.inventory_id");
        $r = $q->execute();
        if ($r < 0) {
            die $DBI::errstr;
        }

        while (@row = $q->fetchrow_array()) {
            my $board = $row[0];
            my $kernel_image = $row[1];
            my $rfs_tarball = $row[2];
            my $devicetree = $row[3];
            if (!$kernel_image || !$rfs_tarball) {
                print "warning: no URIs found for $board, skipping\n";
                next;
            } else {
                print "found URIs for $board\n";
            }
            $uris->{$board} = {
                "kernel_image_uri"  => $kernel_image,
                "rfs_tarball_uri"   => $rfs_tarball,
                "devicetree_uri"    => $devicetree
            };
        }

        $q->finish();
    }

    print "-- downloading kernel images, tarballs, and device-tree blobs\n";

    # download all the images, tarballs, and device-tree blobs using the URIs specified in the imagelist to the ./downloads folder
    foreach (keys $uris) {
        my $dir = `pwd`;
        chomp $dir;
        $dir = "$dir/downloads/$_";
        `mkdir -p $dir`;

        print "downloading files for $_\n";
        $uris->{$_}->{kernel_image}   = download_uri($uris->{$_}->{kernel_image_uri}, $dir);
        $uris->{$_}->{rfs_tarball}    = download_uri($uris->{$_}->{rfs_tarball_uri}, $dir);

        if (!$uris->{$_}->{kernel_image}) {
            print "warning: problem downloading $_ kernel image, board will be skipped during boottest\n";
            delete $uris->{$_};
            next;
        }
        if (!$uris->{$_}->{rfs_tarball}) {
            print "warning: problem downloading $_ rfs tarball, board will be skipped during boottest\n";
            delete $uris->{$_};
            next;
        }

        # only attempt to download device-tree blob if one was specified in the imagelist
        if ($uris->{$_}->{devicetree_uri}) {
            $uris->{$_}->{devicetree} = download_uri($uris->{$_}->{devicetree_uri}, $dir);
            if (!$uris->{$_}->{devicetree}) {
                print "warning: problem downloading $_ device-tree blob, board will be skipped during boottest\n";
                delete $uris->{$_};
                next;
            }    
        }
    }

    print "-- checking kernel images, tarballs, and device-tree blobs\n";

    # die if downloaded kernel images, rfs tarballs, or device-tree blobs do not exist or have zero size
    foreach (keys $uris) {
        if (-e $uris->{$_}->{kernel_image}) {
            print "$_ kernel image found\n";
        } else {
            print "warning: $_ kernel image not found, board will be skipped during boottest\n";
            delete $uris->{$_};
            next;
        }

        if (-z $uris->{$_}->{kernel_image}) {
            print "warning: $_ kernel image is zero bytes, board will be skipped during boottest\n";
            delete $uris->{$_};
            next;
        }

        if (-e $uris->{$_}->{rfs_tarball}) {
            print "$_ rfs tarball found\n";
        } else {
            print "warning: $_ rfs tarball not found, board will be skipped during boottest\n";
            delete $uris->{$_};
            next;
        }

        if (-z $uris->{$_}->{rfs_tarball}) {
            print "warning: $_ rfs tarball is zero bytes, board will be skipped during boottest\n";
            delete $uris->{$_};
            next;
        }

        # only check for device-tree blob if a URI was specified
        if ($uris->{$_}->{devicetree}) {
            if (-e $uris->{$_}->{devicetree}) {
                print "$_ devicetree blob found\n";
            } else {
                print "warning: $_ device-tree blob not found, board will be skipped during boottest\n";
                delete $uris->{$_};
                next;
            }

            if (-z $uris->{$_}->{devicetree}) {
                print "warning: $_ device-tree blob is zero bytes, board will be skipped during boottest\n";
                delete $uris->{$_};
                next;
            }
        }
    }

    print "-- allocating free boards\n";
    foreach (keys $uris) {
        run_bf_cmd("allocate $_");
    }

    # run setup.sh to copy images, tarballs, and device-tree blobs over to barn and setup symlinks
    print "-- setting up downloaded kernel images, rfs tarballs, and device-tree blobs\n";
    foreach (keys $uris) {
        run_cmd("./setup.sh $_ $uris->{$_}->{kernel_image} $uris->{$_}->{rfs_tarball} $uris->{$_}->{devicetree}");
    }

    # use `bf off` and then `bf on` to power cycle boards
    # `bf cycle` seems to have some issues
    print "-- power cycling boards\n";
    foreach (keys $uris) {
        run_bf_cmd("off $_");
        run_bf_cmd("on $_");
    }

    print "-- determining updated board statuses\n";
    foreach (keys $uris) {
        my $status = getBoardStatus($_);
        $statuses->{$_}->{after} = $status;
        printStatus($status);
    }

    print "-- releasing boards\n";
    foreach (keys $uris) {
        run_bf_cmd("release $_");
    }

    print "-- logging boottest results to database\n";
    foreach (keys $uris) {
        my $status_before = $statuses->{$_}->{before};
        my $status_after = $statuses->{$_}->{after};
        printBeforeAfterStatus($status_before, $status_after);

        my $hostname = "$statuses->{$_}->{after}->{hostname}";
        my $uname_before = "$status_before->{uname}";
        my $uname_after = "$status_after->{uname}";
        my $kernel_image_uri = "$uris->{$_}->{kernel_image_uri}";
        my $rfs_tarball_uri = "$uris->{$_}->{rfs_tarball_uri}";
        my $devicetree_uri = "$uris->{$_}->{devicetree_uri}";
        my $t = time();

        print "db: inserting entry for $_ boottest\n";
        $q = $dbh->prepare("INSERT INTO logs (inventory_id, hostname, uname_before, uname_after, kernel_image_uri, rfs_tarball_uri, devicetree_uri, time) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $q->bind_param(1, $boards->{$_});
        $q->bind_param(2, $hostname);
        $q->bind_param(3, $uname_before);
        $q->bind_param(4, $uname_after);
        $q->bind_param(5, $kernel_image_uri);
        $q->bind_param(6, $rfs_tarball_uri);
        $q->bind_param(7, $devicetree_uri);
        $q->bind_param(8, $t);
        $q->execute() or die $DBI::errstr;
        $q->finish();
    }
}


#
# INVENTORY LOGIC
#

if ($take_inventory_flag) {
    print "-- taking inventory of all boards in boardfarm\n";

    # get board statuses and take inventory
    foreach (@boardlist) {
        my $status = getBoardStatus($_);
        printStatus($status);

        my $rack = int($status->{rack});
        my $port = int($status->{port});
        my $uname = "$status->{uname}";
        my $hostname = "$status->{hostname}";
        my $telnet_addr = "$status->{telnet_addr}";
        my $telnet_port = int($status->{telnet_port});

        # fetch the specified board from the inventory to see if it is already in the database
        print "db: querying inventory for $_\n";
        $q = $dbh->prepare("SELECT id FROM inventory WHERE board=?");
        $q->bind_param(1, $_);
        $r = $q->execute() or die $DBI::errstr;
        if ($r < 0) {
            print $DBI::errstr;
        }
        @row = $q->fetchrow_array();
        $q->finish();

        # if the board is already in the database, UPDATE its entry in the inventory, else INSERT new row for the board
        my $t = time();
        if (@row) {
            # store the board id in the boardlist hash
            $boards->{$_} = $row[0];

            print "db: inventory entry found for $_, updating entry\n";
            $q = $dbh->prepare("UPDATE inventory SET hostname=?, uname=?, telnet_addr=?, telnet_port=?, rack=?, port=?, time=? WHERE board=?");
        } else {
            print "db: no inventory entry for $_, inserting new entry\n";
            $q = $dbh->prepare("INSERT INTO inventory (hostname, uname, telnet_addr, telnet_port, rack, port, time, board) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");    
        }

        $q->bind_param(1, $hostname);
        $q->bind_param(2, $uname);
        $q->bind_param(3, $telnet_addr);
        $q->bind_param(4, $telnet_port);
        $q->bind_param(5, $rack);
        $q->bind_param(6, $port);
        $q->bind_param(7, $t);
        $q->bind_param(8, $_);
        $q->execute() or die $DBI::errstr;
        $q->finish();

        # if we inserted a new entry, query the db again for the new inventory id
        # thought: shouldn't the query result return the newly inserted primary key? oh well...
        if (!@row) {
            print "db: querying inventory for $_\n";
            $q = $dbh->prepare("SELECT id FROM inventory WHERE board=?");
            $q->bind_param(1, $_);
            $r = $q->execute() or die $DBI::errstr;
            if ($r < 0) {
                print $DBI::errstr;
            }
            @row = $q->fetchrow_array();
            $q->finish();

            # store the new inventory id in the boardlist hash
            $boards->{$_} = $row[0];
        }
    }
}

# disconnect from database
$dbh->disconnect();


# download file given a URI to the specified directory and return the
# downloaded file's full path
sub download_uri {
    my $uri = shift;
    my $dir = shift;

    print "downloading $uri\n";

    my $ff = File::Fetch->new(uri => $uri);
    if (!$ff) {
        print "error: could not create File::Fetch object.\n";
        return 0;
    }
    
    # download
    my $file = $ff->fetch(to => $dir);
    if ($file) {
        print "saved to $file\n";
    } else {
        print "error: ". $ff->error();
        return 0;
    }

    return $file;
}

# print a command, execute it, and then print its output
sub run_cmd {
    my $cmd = shift;
    print "cmd: $cmd\n";
    my $out = `$cmd`;
    print "output:\n$out";

    return $out;
}

# same as run_cmd, except executes the command on barn via ssh
sub run_barn_cmd {
    my $cmd = shift;
    print "cmd: $cmd\n";
    my ($out, $err);
    ($out, $err) = $main::barn_ssh->capture2($cmd);
    print "output:\n$out";

    return $out;
}

# specifically runs a bf command on barn
sub run_bf_cmd {
    my $bf_cmd = shift;
    my $out = run_barn_cmd("/BoardFarm/bin/bf $bf_cmd");

    return $out;
}

sub getBoardStatus {
    my $board = shift;


    my $status = {};
    my $out = run_bf_cmd("status $board");
    my @line = split "\n", $out;

    # on/off status
    $line[0] =~ m/^[^\s]+ is (on|off)/;
    $status->{on} = ($1 eq "on") ? 1 : 0;
    
    # determine if board is allocated (and to whom)
    $status->{free} = 1;
    $status->{user} = '';
    if ($line[0] =~ m/allocated to ([^\s]+)/) {
        $status->{free} = 0;
        $status->{user} = $1;
    }

    # board's physical location
    $line[0] =~ m/pgh_rack(\d+) port (\d+)\.$/;
    $status->{location} = "pgh rack $1 port $2";
    $status->{rack} = $1;
    $status->{port} = $2;
    
    # kernel symlink and image paths
    $line[1] =~ m/kernel path:\s+([^\s]+) -> ([^\s]+)/;
    $status->{kernel_sym} = "/tftpboot/$1";
    $status->{kernel_img} = "/tftpboot/$2";

    # rfs symlink and directory paths
    $line[2] =~ m/rfs path:\s+([^\s]+) -> ([^\s]+)/;
    $status->{rfs_sym} = $1;
    $status->{rfs_dir} = $2;
    
    # telnet and ssh connection info

    # telnet tuple: ip, port
    $line[5] =~ m/telnet ([\d\.]+) (\d+)/;
    $status->{telnet} = "$1 $2";
    $status->{telnet_addr} = $1;
    $status->{telnet_port} = int($2);

    # ssh tuple: port, ip
    $line[7] =~ m/ssh -p (\d+) ([\d\.]+)/;
    $status->{ssh} = "$1 $2";
    
    # shellcheck.sh telnets into the specified addr+port and uses expect blocks
    # to send `uname -a` and `hostname` commands
    # we capture the output from that shell script then parse it to obtain
    # the uname and hostname for a particular board
    # we only perform these steps if the `bf status` indicated that the board is ON
    $status->{uname} = '';
    $status->{hostname} = '';
    if ($status->{on}) {
        $out = run_cmd("./shellcheck.sh $status->{telnet_addr} $status->{telnet_port}");
        my @h = split "\n", $out;

        # loop through all the captured lines from shellcheck.sh
        # we loop by index instead of using foreach so we can reference the next
        # line from the captured output at any time
        # if a particular line contains "uname" or "hostname" (command), the next
        # line will naturally contain the uname or hostname respectively
        for my $i (0 .. $#h) {
            if ($h[$i] =~ /uname/) {
                $status->{uname} = $h[$i+1];
            }
            if ($h[$i] =~ /hostname/) {
                $status->{hostname} = $h[$i+1];
            }
        }
    }

    return $status;
}

# simple sub to sort the keys of a given status and print out key-value pairs
sub printStatus {
    my $status = shift;

    foreach (sort(keys %$status)) {
        print "$_: $status->{$_}\n";
    }
}

# simple sub that takes the before and after statuses, then prints side-by-side
# outputs to see how values changed
sub printBeforeAfterStatus {
    my $status_before = shift;
    my $status_after = shift;

    foreach (sort(keys %$status_before)) {
        print "$_: $status_before->{$_} -> $status_after->{$_}\n";
    }
}



