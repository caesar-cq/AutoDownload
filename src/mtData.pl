#!/usr/bin/perl -w
use strict;
use warnings;
use LWP::Simple;

require "./util.pl";

use constant {
	DB_MTDB 				=> "mtdb",
	DEFAULT_TREE_PARA		=> "-ALIGN -TREE -OUTPUT=NEXUS",
	FILE_SPECIES_NAME 		=> "species.name",
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
	# mtData = __mtData
	my $nc_number_list = $_[0];
	my $mtData;
	if ( !defined( $_[1]) ) {
		$mtData = DB_MTDB;
	} else {
		$mtData = $_[1];
	}

	my @nc_numbers = split(/,/, $nc_number_list);

	my %re;
	foreach my $nc_number (@nc_numbers) {
		my %data;
		$data{"".FILE_SPECIES_NAME} 	= getSpeciesName($nc_number);
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
	# mtData = __mtData
	my $nc_number = $_[0];
	my $mtData;
	if ( !defined( $_[1]) ) {
		$mtData = DB_MTDB;
	} else {
		$mtData = $_[1];
	}

	my $gi_number = nc2gi($nc_number);

	my $mtDir = "$mtData/$nc_number";
	mkdir $mtDir;
        my $flag=0;
	if ( saveAsFile(getSpeciesName($nc_number)		, $mtDir."/".FILE_SPECIES_NAME   )==-1 ) {$flag=1};
	if ( saveAsFile(getSequence($nc_number)		, $mtDir."/".FILE_SEQUENCE		 )==-1 ) {$flag=1};
	if ( saveAsFile(getFeatureTable($nc_number)	, $mtDir."/".FILE_FEATURE_TABLE  )==-1 ) { $flag=1};
	if ( saveAsFile(getGeneBank($nc_number)		, $mtDir."/".FILE_GENEBANK		 )==-1 ) {$flag=1 };
	if ( saveAsFile(getCDSProtein($nc_number)		, $mtDir."/".FILE_CDS_PROTEIN	 )==-1 ) { $flag=1 };
	if ( saveAsFile(getCDSNucleotide($nc_number)	, $mtDir."/".FILE_CDS_NUCLEOTIDE )==-1 ) { $flag=1 };
        if($flag&&$flag==1)
        {
          addToFile("$nc_number,","../temp/mt_error.txt");
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
	# mtData = __mtData
	return getMTFileFromLocal($_[0], $_[1], FILE_CDS_NUCLEOTIDE);
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
	# mtData = __mtData
	return getMTFileFromLocal($_[0], $_[1], FILE_CDS_PROTEIN);
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
	# mtData = __mtData
	return getMTFileFromLocal($_[0], $_[1], FILE_GENEBANK);
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
	# mtData = __mtData
	return getMTFileFromLocal($_[0], $_[1], FILE_FEATURE_TABLE);
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
	# mtData = __mtData
	return getMTFileFromLocal($_[0], $_[1], FILE_SEQUENCE);
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
	my $url = "https://www.ncbi.nlm.nih.gov/nuccore/$_[0]";
	#print mylog("DEBUG_", $url);
	my $genome = get($url);
	#print mylog("DEBUG_", $genome);
	if ($genome =~ /(.*)<title>(.*)\s+(mitochondrion|chloroplast|plastid).*/) {
		my $name = $1;
		$name =~ s/\s+/_/g;
		return $name;
	}
	return 0;
}
sub getSpeciesNameFromLocal {
	# NCNumber
	# mtData = __mtData
	return getMTFileFromLocal($_[0], $_[1], FILE_SPECIES_NAME);
}

######################
# getMTFileFromLocal #
######################
sub getMTFileFromLocal {
	# NCNumber
	# mtData = __mtData
	# FileName
	my $nc_number = $_[0];

	my $mtData;
	if ( !defined( $_[1]) ) {
		$mtData = DB_MTDB;
	} else {
		$mtData = $_[1];
	}

	my $fileName = $_[2];

	return file2str("$mtData/$nc_number/$fileName");
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
