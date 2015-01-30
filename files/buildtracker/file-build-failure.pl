#!/usr/bin/perl -w
=head1 NAME

file-build-failure.pl - Show how to talk to Bugzilla via XMLRPC

=head1 SYNOPSIS

C<./file-build-failure.pl >

C<./file-build-failure.pl --help> for detailed help

=cut

use strict;
use lib qw(./lib);
use Getopt::Long;
use Pod::Usage;
use File::Basename qw(dirname fileparse);
use File::Spec;
use HTTP::Cookies;
use XMLRPC::Lite;
use MIME::Base64 qw(encode_base64);

# allows us to write perl hash to file
use Storable;

# If you want, say “use Bugzilla::WebService::Constants” here to get access
# to Bugzilla's web service error code constants.
# If you do this, remember to issue a “use lib” pointing to your Bugzilla
# installation directory, too.

my $token;
my $help;
my $Bugzilla_uri = "http://mirror/bugzilla/xmlrpc.cgi";
my $Bugzilla_login = "dummy\@timesys.com";
my $Bugzilla_password = "dummypassword123";
my $builder;
my $buildnum;
my $package; # corresponds to "changed" software/package in buildbot
my $commit; # corresponds to git revision hash for which commit triggered buildbot build
my $board;
#my $logfull_file_name;
#my $logfull;
my $logtail_file_name;
my $logtail;
my $workorder_file_name;
my $workorder;
my $os;
my $debug;

# used to store the contents of the logtail file
my $summary;
my $bug_desc;
my $bug_id;
my $short_rev;
my @tmp;
my $filename;

GetOptions('help|h|?'       => \$help,
           #'uri=s'          => \$Bugzilla_uri,
           #'login=s'        => \$Bugzilla_login,
           #'password=s'     => \$Bugzilla_password,
           'builder=s'      => \$builder,
           'buildnum=i'     => \$buildnum,
           'package:s'      => \$package,
           'commit:s'       => \$commit,
           'board=s'        => \$board,
           #'logfull=s'      => \$logfull_file_name,
           'logtail=s'      => \$logtail_file_name,
           'workorder=s'    => \$workorder_file_name,
           'os=s'           => \$os, 
           'debug'          => \$debug
          ) or pod2usage({'-verbose' => 0, '-exitval' => 1});

=head1 OPTIONS

=over

=item --help, -h, -?

Print a short help message and exit.

=item --uri

URI to Bugzilla's C<xmlrpc.cgi> script, along the lines of
C<http://your.bugzilla.installation/path/to/bugzilla/xmlrpc.cgi>.

=item --login

Bugzilla login name. Specify this together with B<--password> in order to log in.

Specify this without a value in order to log out.

=item --password

Bugzilla password. Specify this together with B<--login> in order to log in.

=item --builder

Name of Buildbot Builder (e.g. package_testing, workorder)

=item --buildnum

Buildbot build number.

=item --package

Which package within the commit triggered the build.

=item --commit

Revision hash of the specific commit that triggered the build.

=item --board

Board name.

=item --logtail

Text file containing the C<tail> of the build log.

=item --workorder

File containing factory C<.config> workorder tokens.

=item --os

Operating system the build ran on, typically the name of the build-slave.

=item --create

File in which to store anonymous hash with data for the new bug.

=item --debug

Enable tracing at the debug level of XMLRPC requests and responses.

=back

=head1 DESCRIPTION

=cut

pod2usage({'-verbose' => 1, '-exitval' => 0}) if $help;
_syntaxhelp('URI unspecified') unless $Bugzilla_uri;

# We will use this variable for SOAP call results.
my $soapresult;

# We will use this variable for function call results.
my $result;

# Open our cookie jar. We save it into a file so that we may re-use cookies
# to avoid the need of logging in every time. You're encouraged, but not
# required, to do this in your applications, too.
# Cookies are only saved if Bugzilla's rememberlogin parameter is set to one of
#    - on
#    - defaulton (and you didn't pass 0 as third parameter to User.login)
#    - defaultoff (and you passed 1 as third parameter to User.login)
my $cookie_jar =
    new HTTP::Cookies('file' => File::Spec->catdir(dirname($0), 'cookies.txt'),
                      'autosave' => 1);

=head2 Initialization

Using the XMLRPC::Lite class, you set up a proxy, as shown in this script.
Bugzilla's XMLRPC URI ends in C<xmlrpc.cgi>, so your URI looks along the lines
of C<http://your.bugzilla.installation/path/to/bugzilla/xmlrpc.cgi>.

=cut

my $proxy = XMLRPC::Lite->proxy($Bugzilla_uri,
                                'cookie_jar' => $cookie_jar);

=head2 Debugging

Enable tracing at the debug level of XMLRPC requests and responses if requested.

=cut

if ($debug) {
   $proxy->import(+trace => 'debug');
}

=head2 Logging In and Out

=head3 Using Bugzilla's Environment Authentication

Use a
C<http://login:password@your.bugzilla.installation/path/to/bugzilla/xmlrpc.cgi>
style URI.
You don't log out if you're using this kind of authentication.

=head2 Creating A Bug

Create the file specified by the C<create> parameter. An anonymous hash 
containing data for the new bug being will be stored in this file. This
file will then be passed to C<Bug.create>. The call will return a hash 
with a bug id for the newly created bug.

=cut

# read in log files
# http://www.perlmonks.org/?node_id=287647

# read in full build log and encode using base64
#open LOGFILE, '<', $logfull_file_name or die "Could not read build log.";
#$logfull = do {
#    local $/; # also undef, alt. syntax
#    <LOGFILE>;
#};
#close LOGFILE;

# http://www.perlmonks.org/?node_id=746566 
#$logfull = encode_base64($logfull);

open LOGFILE, '<', $logtail_file_name or die "Could not read build log tail.";
$logtail = do {
    # $/ is perl's "Record Separator" variable. Setting it to undef makes perl not
    # treat \n as a record separator when reading the file, thus it reads the whole
    # file to the end.
    local $/ = undef;
    <LOGFILE>;
};
close LOGFILE;

# load workorder .config into string
open LOGFILE, '<', $workorder_file_name or die "Could not read workorder log.";
$workorder = do {
    local $/ = undef;
    <LOGFILE>;
};
close LOGFILE;

$short_rev = substr $commit, 0, 7;
$summary = "$board $package ($os, rev $short_rev, $builder build #$buildnum)";

$bug_desc = <<"BUG_DESC";
======
COMMIT
======
http://engservices/cgi-bin/cgit/cgit.cgi/factory.git/commit/?id=$commit

BUG_DESC

$soapresult = $proxy->call('Bug.create', {
    #Bugzilla_token     => "",
    Bugzilla_login     => $Bugzilla_login,
    Bugzilla_password  => $Bugzilla_password,
    product     => "Factory",
    component   => "Desktop Factory",
    summary     => $summary,
    version     => "XP",
    description => $bug_desc,
    op_sys      => "Linux",
    platform    => "PC"
});

_die_on_fault($soapresult);
$result = $soapresult->result;

#if (ref($result) eq 'HASH') {
#    foreach (keys(%$result)) {
#        print "$_: $$result{$_}\n";
#    }
#}
#else {
#    print "$result\n";
#}

$bug_id = $$result{id};
print "Created new bug with id $bug_id\n";

#@tmp = fileparse($logfull_file_name);
#$soapresult = $proxy->call("Bug.add_attachment", {
#    ids             => ($bug_id),
#    data            => $logfull,
#    file_name       => $tmp[0],
#    summary         => "full build log",
#    content_type    => "application/x-gzip"
#});

#_die_on_fault($soapresult);

@tmp = fileparse($logtail_file_name);
$soapresult = $proxy->call("Bug.add_attachment", {
    #Bugzilla_token      => "",
    Bugzilla_login      => $Bugzilla_login,
    Bugzilla_password   => $Bugzilla_password,
    ids             => ($bug_id),
    data            => $logtail,
    file_name       => $tmp[0],
    summary         => "build log tail -n 1000",
    content_type    => "text/plain"
});

_die_on_fault($soapresult);
print "Attached build log tail to Bug $bug_id\n";

@tmp = fileparse($workorder_file_name);
$soapresult = $proxy->call("Bug.add_attachment", {
    #Bugzilla_token      => "",
    Bugzilla_login      => $Bugzilla_login,
    Bugzilla_password   => $Bugzilla_password,
    ids             => ($bug_id),
    data            => $workorder,
    file_name       => $tmp[0],
    summary         => "workorder (factory .config)",
    content_type    => "text/plain"
});

_die_on_fault($soapresult);
print "Attached workorder log to Bug $bug_id\n";

sub _die_on_fault {
    my $soapresult = shift;

    if ($soapresult->fault) {
        my ($package, $filename, $line) = caller;
        die $soapresult->faultcode . ' ' . $soapresult->faultstring .
            " in SOAP call near $filename line $line.\n";
    }
}

sub _syntaxhelp {
    my $msg = shift;

    print "Error: $msg\n";
    pod2usage({'-verbose' => 0, '-exitval' => 1});
}
