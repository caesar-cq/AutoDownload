#!/usr/bin/perl -w
use strict;
use warnings;

require "./util.pl";

use constant {
	DB_CPDB 				=> "cpdb",
	DEFAULT_TREE_PARA		=> "-ALIGN -TREE -OUTPUT=NEXUS",
	FILE_SPECIES_NAME 		=> "species.name",
	FILE_16S 				=> "cp_16s.fa",
	FILE_23S				=> "cp_23s.fa",
	FILE_SEQUENCE			=> "Sequence.txt",
	FILE_FEATURE_TABLE		=> "Feature_Table.txt",
	FILE_GENEBANK			=> "GeneBank.gb.txt",
	FILE_CDS_PROTEIN		=> "CDS_Protein.txt",
	FILE_CDS_NUCLEOTIDE 	=> "CDS_Nucleotide.txt"
};

sub clustalw {
	#config
	my $config;
	if ( !defined( $_[0]) ) {
		$config = DEFAULT_TREE_PARA;
	} else {
		$config = $_[0];
	}

	my $os = $^O;
	my $cmd = "";
	if ($os eq "linux") {
		$cmd = "clustalw";
	} else {
		$cmd = "clustalw2";
	}

	$cmd .= " $config";
	return system($cmd);
}

############################
# File Readers and Writers #
############################
sub readFastaToHash {
	#fasta String
	my $fasta = $_[0];

	my @genes = split(/>/, $fasta);
	my %hGenes;

	foreach my $gene ( @genes ) {
		chomp $gene;
		my @lines = split(/\n/, $gene);

		if ( !defined($lines[0]) ) {
			next;
		}

		my $name = $lines[0];
		my $content = "";
		for (my $var = 1; $var <= $#lines; $var++) {
				$content.=$lines[$var];
		}

		$hGenes{$name} = $content;
	}
	return %hGenes;
}

sub shortenGeneName{
    #GeneName
    my $geneName = $_[0];
        
    if($geneName =~ /^lcl.*gene=(.*)\]\s+\[protein=(.*)\]\s+\[protein_id=.*/){
        return "$1";
    }
    
    return 0;
}

sub readDBToHash {
	# list of NC_number
	# cpData = __cpData
	my $nc_number_list = $_[0];
	my $cpData;
	if ( !defined( $_[1]) ) {
		$cpData = DB_CPDB;
	} else {
		$cpData = $_[1];
	}

	my @nc_numbers = split(/,/, $nc_number_list);

	my %re;
	foreach my $nc_number (@nc_numbers) {
		my %data;
		$data{"".FILE_SPECIES_NAME} 	= getSpeciesName($nc_number);
		$data{"".FILE_16S} 				= get16S($nc_number);
		$data{"".FILE_23S} 				= get23S($nc_number);
		$data{"".FILE_SEQUENCE}			= getSequence($nc_number);
		$data{"".FILE_FEATURE_TABLE}	= getFeatureTable($nc_number);
		$data{"".FILE_GENEBANK}			= getGeneBank($nc_number);
		$data{"".FILE_CDS_PROTEIN}		= getCDSProtein($nc_number);
		$data{"".FILE_CDS_NUCLEOTIDE} 	= getCDSNucleotide($nc_number);
		
		$re{$nc_number} = \%data;
	}
	return %re;
}

sub buildDBFromNCBI {
	# NC_number
	# cpData = __cpData
	my $nc_number = $_[0];
	my $cpData;
	if ( !defined( $_[1]) ) {
		$cpData = DB_CPDB;
	} else {
		$cpData = $_[1];
	}

	my $gi_number = nc2gi($nc_number);

	my $cpDir = "$cpData/$nc_number";
	mkdir $cpDir;
        my $flag=0;
	if ( saveAsFile(getSpeciesName($nc_number)		, $cpDir."/".FILE_SPECIES_NAME   ) ==-1) { $flag=1 };
	if ( saveAsFile(get16S($nc_number)				, $cpDir."/".FILE_16S 			 ) ==-1) { $flag=1};
	if ( saveAsFile(get23S($nc_number)				, $cpDir."/".FILE_23S 			 ) ==-1) { $flag=1};
	if ( saveAsFile(getSequence($nc_number)		, $cpDir."/".FILE_SEQUENCE		 ) ==-1) {$flag=1};
	if ( saveAsFile(getFeatureTable($nc_number)	, $cpDir."/".FILE_FEATURE_TABLE  ) ==-1) { $flag=1 };
	if ( saveAsFile(getGeneBank($nc_number)		, $cpDir."/".FILE_GENEBANK		 ) ==-1) { $flag=1};
	if ( saveAsFile(getCDSProtein($nc_number)		, $cpDir."/".FILE_CDS_PROTEIN	 ) ==-1) { $flag=1 };
	if ( saveAsFile(getCDSNucleotide($nc_number)	, $cpDir."/".FILE_CDS_NUCLEOTIDE )==-1 ) {$flag=1 };
        if($flag&&$flag==1){
            addToFile("$nc_number,","../temp/normal_list.txt");
        }
	my $name = getSpeciesName("$nc_number");
}

####################
# getCDSNucleotide #
####################
sub getCDSNucleotide {
	# NCNumber
	my $nc_number = $_[0];

	my $re = getCDSNucleotideFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return getCDSNucleotideFromNCBI($nc_number);
	}
}
sub getCDSNucleotideFromNCBI {
	# NCNumber
	my $nc_number = $_[0];
	my $gi_number = nc2gi($nc_number);

	my $url_base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?";
	my $file_url = $url_base."db=nuccore&id=$gi_number&rettype=fasta_cds_na";
	my $data = get($file_url);
	return $data;
}
sub getCDSNucleotideFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_CDS_NUCLEOTIDE);
}

#################
# getCDSProtein #
#################
sub getCDSProtein {
	# NCNumber
	my $nc_number = $_[0];

	my $re = getCDSProteinFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return getCDSProteinFromNCBI($nc_number);
	}
}
sub getCDSProteinFromNCBI {
	# NCNumber
	my $nc_number = $_[0];
	my $gi_number = nc2gi($nc_number);

	my $url_base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?";
	my $file_url = $url_base."db=nuccore&id=$gi_number&rettype=fasta_cds_aa";
	my $data = get($file_url);
	return $data;
}
sub getCDSProteinFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_CDS_PROTEIN);
}

###############
# getGeneBank #
###############
sub getGeneBank {
	# NCNumber
	my $nc_number = $_[0];

	my $re = getGeneBankFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return getGeneBankFromNCBI($nc_number);
	}
}
sub getGeneBankFromNCBI {
	# NCNumber
	my $nc_number = $_[0];

	my $url_base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?";
	my $file_url = $url_base."db=nuccore&id=$nc_number&rettype=gb&retmode=text";
	my $data = get($file_url);
	return $data;
}
sub getGeneBankFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_GENEBANK);
}

###################
# getFeatureTable #
###################
sub getFeatureTable {
	# NCNumber
	my $nc_number = $_[0];

	my $re = getFeatureTableFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return getFeatureTableFromNCBI($nc_number);
	}
}
sub getFeatureTableFromNCBI {
	# NCNumber
	my $nc_number = $_[0];

	my $url_base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?";
	my $file_url = $url_base."db=nuccore&id=$nc_number&rettype=ft&retmode=text";
	my $data = get($file_url);
	return $data;
}
sub getFeatureTableFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_FEATURE_TABLE);
}

###############
# getSequence #
###############
sub getSequence {
	# NCNumber
	my $nc_number = $_[0];

	my $re = getSequenceFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return getSequenceFromNCBI($nc_number);
	}
}
sub getSequenceFromNCBI {
	# NCNumber
	my $nc_number = $_[0];

	my $url_base = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?";
	my $file_url = $url_base."db=nuccore&id=$nc_number&rettype=fasta&retmode=text";
	my $data = get($file_url);
	return $data;
}
sub getSequenceFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_SEQUENCE);
}

##########
# get16S #
##########
sub get16S {
	# NCNumber
	my $nc_number = $_[0];

	my $re = get16SFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return get16SFromNCBI($nc_number);
	}
}
sub get16SFromNCBI {
	# NCNumber
	my $nc_number = $_[0];

	my $url1="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$_[0]&rettype=ft&retmode=text";
	my $line = get($url1);

	my $fa_16s;
	
	if ($line =~ /(\d+)\s+(\d+)\s+rRNA\s+product\s+16S/g) {
		if ($1<$2) 
		{
			my $url2="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=".$_[0]."&strand=1&seq_start=".$1."&seq_stop=".$2."&rettype=fasta&retmode=text";
			my $ss=get($url2);
			$ss =~ s/[\n\r]*//g;
			if($ss =~ />.*(\d+)\s+(.*)\s+chlo.*genome(.*)/)
			{
				$fa_16s = ">$nc_number\n$3\n";
			}
		}elsif($1>$2){
			my $url2="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=".$_[0]."&strand=0&seq_start=".$1."&seq_stop=".$2."&rettype=fasta&retmode=text";
			my $ss=get($url2);
			$ss =~ s/[\n\r]*//g;
			if($ss =~ />.*(\d+)\s+(.*)\s+chlo.*genome(.*)/)
			{
				$fa_16s = ">$nc_number\n$3\n";
			}
		}
	}
	return $fa_16s;
}
sub get16SFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_16S);
}

##########
# get23S #
##########
sub get23S {
	# NCNumber
	my $nc_number = $_[0];

	my $re = get23SFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return get23SFromNCBI($nc_number);
	}
}
sub get23SFromNCBI {
	# NCNumber
	my $nc_number = $_[0];
	
	my $url1="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=$_[0]&rettype=ft&retmode=text";
	my $line = get($url1);

	my $fa_23s;
	
	if ($line =~ /(\d+)\s+(\d+)\s+rRNA\s+product\s+23S/g) {
		if ($1<$2) 
		{
			my $url2="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=".$_[0]."&strand=1&seq_start=".$1."&seq_stop=".$2."&rettype=fasta&retmode=text";
			my $ss=get($url2);
			$ss =~ s/[\n\r]*//g;
			if($ss =~ />.*(\d+)\s+(.*)\s+chlo.*genome(.*)/)
			{
				$fa_23s = ">$nc_number\n$3\n";
			}
		}elsif($1>$2){
			my $url2="http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=".$_[0]."&strand=0&seq_start=".$1."&seq_stop=".$2."&rettype=fasta&retmode=text";
			my $ss=get($url2);
			$ss =~ s/[\n\r]*//g;
			if($ss =~ />.*(\d+)\s+(.*)\s+chlo.*genome(.*)/)
			{
				$fa_23s = ">$nc_number\n$3\n";
			}
		}
	}
	return $fa_23s;
}
sub get23SFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_23S);
}

##################
# getSpeciesName #
##################
sub getSpeciesName {
	# NCNumber
	my $nc_number = $_[0];

	my $re = getSpeciesNameFromLocal($nc_number);
	if ( $re ) {
		return $re;
	} else {
		return getSpeciesNameFromNCBI($nc_number);
	}
}
sub getSpeciesNameFromNCBI {
	# NCNumber
	my $url = "http://www.ncbi.nlm.nih.gov/nuccore/$_[0]";
	my $genome = get($url);
	if ($genome =~ /(.*)<title>(.*)\s+(mitochondrion|chloroplast|plastid).*/) {
		my $name = $2;
		$name =~ s/\s+/_/g;
		return $name;
	}
	return 0;
}
sub getSpeciesNameFromLocal {
	# NCNumber
	# cpData = __cpData
	return getCPFileFromLocal($_[0], $_[1], FILE_SPECIES_NAME);
}

######################
# getCPFileFromLocal #
######################
sub getCPFileFromLocal {
	# NCNumber
	# cpData = __cpData
	# FileName
	my $nc_number = $_[0];

	my $cpData;
	if ( !defined( $_[1]) ) {
		$cpData = DB_CPDB;
	} else {
		$cpData = $_[1];
	}

	my $fileName = $_[2];

	return file2str("$cpData/$nc_number/$fileName");
}

sub nc2gi {
	#nc_number

	my $nc_number = $_[0];
	my $gi_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=".$nc_number."&rettype=gi";

	my $ncbi_gi = '';
	$ncbi_gi = get($gi_url);
	return $ncbi_gi;
}

1;
