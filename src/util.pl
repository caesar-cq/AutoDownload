#!/usr/bin/perl

use strict;
use POSIX qw(strftime);

my @__ignore = ("DEBUG_");

sub mylog {
	# Level
	# Message
	my $time = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
	my $level = $_[0];
	my $message = $_[1];

	if ( grep /$level/, @__ignore ) {
		return "";
	} else {
		return "[$time] $level : $message\n";
	}
}

sub file2str {
	# fileName
	my $filename = $_[0];

	open (IN, "<$filename") or return 0;
	my $data="";
	while (my $line = <IN>) {
		$data = $data.$line;
	}
	close IN;

	return $data;
}

sub saveAsFile {
	# content string
	# fileName

	my $content = $_[0];
	my $filename = $_[1];

	if ( !$content ) {
		print mylog("DEBUG", "$filename is empty. Ignored." );
		return -1;
	}

	open (OUT, ">$filename");
	print OUT "$content";
	close OUT;

	return 1;
}

sub addToFile {
	# content string
	# fileName

	my $content = $_[0];
	my $filename = $_[1];

	if ( !$content ) {
		print mylog("DEBUG", "$filename is empty. Ignored." );
		return -1;
	}

	open (OUT, ">>$filename");
	print OUT "$content";
	close OUT;

	return 1;
}

1;
