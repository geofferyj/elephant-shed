#!/usr/bin/perl

use strict;
use warnings;
use PgCommon;
use Template;

my $pgbadgerdir = "/var/lib/pgbadger";
my $backupstatusdir = "/var/www/html/pgbackrest";
my $systemdstatusdir = "/etc/systemd/system/multi-user.target.wants";

# get PostgreSQL cluster information
my @clusters;
foreach my $version (get_versions()) {
  foreach my $cluster (get_version_clusters($version)) {
    my %info = cluster_info($version, $cluster);
    $info{version} = $version;
    $info{cluster} = $cluster;
    $info{owner} = (getpwuid $info{'owneruid'})[0];

    # pgbadger report
    if (-e "$pgbadgerdir/$version-$cluster/LAST_PARSED") {
      $info{pgbadger} = "/pgbadger/$version-$cluster/";
    }

    # pgbackrest status
    if (-e "$backupstatusdir/$version-$cluster.backup") {
      $info{backup} = "/pgbackrest/$version-$cluster.backup";
    }
    if (not system("systemctl status pgbackrest\@$version-$cluster.timer | grep -q 'Active: active'")) {
      $info{backup_enabled} = 1;
    }
    if (not system("systemctl status pgbackrest-incr\@$version-$cluster.timer | grep -q 'Active: active'")) {
      $info{backup_incr_enabled} = 1;
    }

    # archive status
    if (not system("pg_conftool $version $cluster show archive_command | grep -q pgbackrest")) {
      $info{archive_enabled} = 1;
    }

    push @clusters, \%info;
  }
}

my $template = Template->new({
  INCLUDE_PATH => '/usr/share/elephant-shed/template',
  POST_CHOMP => 1,
});

# Extract base domain from SERVER_NAME for subdomain routing
my $server_name = $ENV{SERVER_NAME} || 'localhost';
my $omnidb_subdomain = '';

# Remove port number if present
$server_name =~ s/:\d+$//;

# Construct OmniDB subdomain URL
# Use the same protocol as the current request
my $protocol = ($ENV{HTTPS} && $ENV{HTTPS} eq 'on') ? 'https' : 'http';
$omnidb_subdomain = "${protocol}://omnidb.${server_name}/";

print "Content-type: text/html\n\n";

$template->process('portalmain.html', {
  CLUSTERS => \@clusters,
  SERVER_NAME => $ENV{SERVER_NAME},
  OMNIDB_SUBDOMAIN => $omnidb_subdomain,
  REMOTE_USER => $ENV{REMOTE_USER},
  TITLE => "Dashboard - PostgreSQL",
  HEADLINE => "PostgreSQL Appliance Dashboard",
}) or die $template->error();
