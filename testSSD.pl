#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: testSSD.pl
#
#        USAGE: ./testSSD.pl --debug --verbose --file <filename> --out <outfilename>  --test_number 1 --thread_number 20  
#
#  DESCRIPTION: 
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Dan Slov (), dan.slov@gmail.com
# ORGANIZATION: Intel
#      VERSION: 1.0
#      CREATED: 05/10/2015 20:40:17
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

#!/usr/bin/env perl

use strict;
use warnings;
use AutoLoader qw/AUTOLOAD/;
use Data::Dumper;
use English;
use IO::File;
use Getopt::Long;
use DateTime;
use threads ('yield', 'stringify');
#use FindBin::Real;

our $verbose = '';	# default value (false)
our $debug = '';	    # default value (false)

sub println {
    $\ = "\n";
    @_ = ($_) unless @_;
    print @_;
}

sub read_write {
	my ($filename, $number_of_tests, $number ) = @_;
	my $tid = threads->tid;
	for (my $i=0; $i < $number_of_tests; $i++ ) {
		my $fh = IO::File->new($filename, "r");
		my $fwh = IO::File->new("${filename}.$number.$i","w");
		print $fwh DateTime->now;
		print $fwh "Test read/write speed. Thread number in test: $i, tid:  $tid \n";
		foreach my $line (<$fh>) {
			print $fwh $line;
		}
		print $fwh "\nFinalizing write test: ";
		print $fwh DateTime->now;
		$fh->close();
		$fwh->close();
	}

}

sub main {
	my ($filename, $outfile, $number_of_tests, $number_of_threads) = @_;
	my @metrics;
	my @start;
	my @end;
	my @thr;
	for (my $i=0; $i < $number_of_threads; $i++ ) {
		$start[$i] = time;
		$thr[$i] = threads->create('read_write', ($filename,$number_of_tests, $i) );
	}
	#TODO:: I know, waiting for threads following the same order is a bug
	# detach() should be used
	for (my $i=0; $i < $number_of_threads; $i++ ) {
		$thr[$i]->join();
		#read_write($filename,$number_of_tests, $i);
		sleep 5 if $debug;
		$end[$i] = time;
		$metrics[$i] = $end[$i] - $start[$i];
	}
	my $ts = DateTime->now;
	my $fh = IO::File->new($outfile, "w");
	print $fh "Test read/write speed summary. Timestamp: $ts \n";
	print $fh "Total time elapsed: \n";
	{
		local $" ="\n";
		print $fh "@metrics ";
		print $fh "\n" ;
	}
	$fh->close();

}
################# MAIN #################
my $filename = '';	
my $number_of_tests = 1;	
my $number_of_threads = 1;	
my $outfile = "";
GetOptions ('verbose' => \$verbose, 'debug' => \$debug, 'file=s' => \$filename,'test_number=f' => \$number_of_tests,
			'thread_number=f' => \$number_of_threads, 'out=s' => \$outfile);
print "Arguments expected verbose, debug, filename, outfile, number_of_tests, number_of_threads \n" if $verbose;
print "Arguments received: $verbose, $debug, $filename, $outfile, $number_of_tests, $number_of_threads \n" if $verbose;
if ($outfile eq "") {
	my $ts = DateTime->now;
	$outfile = "ReadWriteTestReport_$ts.txt"
}
main ($filename, $outfile, $number_of_tests, $number_of_threads);

