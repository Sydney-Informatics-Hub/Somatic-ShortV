#!/usr/bin/perl

use strict;
use warnings;

# We want to see how long each interval in HC took to compute
# to identify regions that are difficult to call and take longer walltime
# if these are "predicatable" regions, e.g. unplaced/unlocalized contigs
# this script gets duration per task using GATK logs
# will tell us time for all intervals in 1 sample, but not task + duration 

my $logdir=$ARGV[0];

my @files = <$logdir/*.oe>;

print "#Interval\tDuration\tMemory_GB\n";

foreach my $file (@files){
        $file =~ m/(\d+).oe/;
        my $interval = $1;
        my $timelog=`grep " done. Elapsed time:" $file`;
        $timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
	my $duration=$1;
	my $Memory=`grep "Runtime.totalMemory()" $file`;
	$Memory=~ m/(\d+)/;
	my $Memory2 = $1;
	my $Memory_GB= $Memory2 / 1024 / 1024 / 1024;
	$Memory_GB = sprintf("%.2f",$Memory_GB);
	print "$interval\t$duration\t$Memory_GB\n";
        
}
