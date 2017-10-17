#!/usr/bin/perl -w
use strict;
use LWP::Simple;
use Getopt::Long;

require "./mtData.pl";

# build DB: perl batchDownload.pl -i list.txt -o mtdb

my $outputFolder;
my $nc_num_file;
print mylog("INFO", "Download Start...");

GetOptions(
	"input|i=s" => \$nc_num_file,
	"output|o=s" => \$outputFolder
);
mkdir $outputFolder;
print mylog("FILE", "Download folder created.");

open (IN,"<$nc_num_file") or die "Can not read this file:$!\n";
print mylog("FILE", "Name list file opened.");

my $total;
my @re = readpipe("sed 's/,/ /g' $nc_num_file | wc -w");
$total = substr( $re[0],0) ;
chomp $total;

my $input_content = <IN>;
my @nc_numbers_in = split(/,/, $input_content);

my $i=1;
foreach my $nc_number (@nc_numbers_in) {
	chomp $nc_number;

	print mylog("DEBUG", "$nc_number");

	my $name = getSpeciesName("$nc_number");
	print mylog("DEBUG", "$name");
        print mylog("INFO", "Downloading: $nc_number($name) [ $i / $total ]");
	buildDBFromNCBI("$nc_number", $outputFolder);
	
	$i++;
}
print mylog("INFO", "Download End...");
