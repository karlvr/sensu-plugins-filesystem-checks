#!/usr/bin/perl -w
# This plugin checks a given file's modified time.
# Based on https://github.com/sensu-plugins/sensu-plugins-filesystem-checks/blob/master/bin/check-mtime.rb

use Getopt::Long qw(:config no_auto_abbrev no_ignore_case);
use Pod::Usage;
use File::stat;

my $file; # File to check last modified time
my $warning_age; # Warn if mtime greater than provided age in seconds
my $critical_age; # Critical if mtime greater than provided age in seconds
my $ok_no_exist = 0; # OK if file does not exist
my $ok_zero_size = 0; # OK if file has zero size

GetOptions(
	'file|f=s' => \$file,
	'warning|w=i' => \$warning_age,
	'critical|c=i' => \$critical_age,
	'ok-no-exist|o' => \$ok_no_exist,
	'ok-zero-size|z' => \$ok_zero_size,
) or pod2usage(2);

my $now = time();

if (!$file) {
	print "No file specified\n";
	exit 3;
}
if (!$warning_age && !$critical_age) {
	print "No warn or critical age specified\n";
	exit 3;
}

if (-e $file) {
	my $sb = stat($file);
	if ($sb->size == 0 && !$ok_zero_size) {
		print "file $file has zero size\n";
		exit 2;
	}
}

my @files = glob($file);
my $sb = stat($files[0]);
if ($sb) {
	if ($sb->size == 0 && !$ok_zero_size) {
		print "file ${files[0]} has zero size\n";
		exit 2;
	}
	my $age = $now - $sb->mtime;
	if ($critical_age && $age > $critical_age) {
		print "file ${files[0]} is @{[$age - $critical_age]} seconds past critical\n";
		exit 2;
	} elsif ($warning_age && $age > $warning_age) {
		print "file ${files[0]} is @{[$age - $warning_age]} seconds past warning\n";
		exit 1;
	} else {
		print "file ${files[0]} is $age seconds old\n";
		exit 0;
	}
} else {
	if ($ok_no_exist) {
		print "file $file does not exist\n";
		exit 0;
	} else {
		print "file $file not found\n";
		exit 2;
	}
}
