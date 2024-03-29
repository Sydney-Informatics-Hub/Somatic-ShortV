
#!/usr/bin/perl

use strict;
use warnings;

my $logdir=$ARGV[0];
my $out="$logdir/interval_duration_memory.txt";

`rm -rf $out`;

open(OUT,'>',"$out") or die "Could not write to $out: $!\n";

print OUT "#Interval\tDuration\tMemory_Gb\n";

for(my $i=0000; $i <3200; $i++){
	my $interval=sprintf("%04d",$i);
	my $file="$logdir\/$interval\.log";
	if(-s $file){
		# Check for errors first, because errors will still print done and mem
		my $errors =`grep -i ERROR $file`;
		if($errors){
			print OUT "$interval\tNA\tNA\n";
		}
		else{
			my $timelog=`tail -50 $file | grep " done. Elapsed time:"`;
			$timelog=~ m/([0-9]+\.[0-9]+) minutes\.\n$/;
			my $duration=$1;
			my $memory=`tail -50 $file | grep "Runtime.totalMemory"`;
			$memory=~ m/([0-9]+)\n$/;
			my $bytes=$1;
			if($memory && $bytes){
				my $gigabytes=$bytes/1000000000;
				print OUT "$interval\t$duration\t$gigabytes\n";
			}
			else{
				print OUT "$interval\tNA\tNA\n";
			}
		}
	}
	else{
		print OUT "$interval\tNA\tNA\n";
	}
}
close OUT;
exit;
