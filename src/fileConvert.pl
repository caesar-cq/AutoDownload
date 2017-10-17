#!/usr/bin/perl -w use strict; 
use LWP::Simple; 
use Getopt::Long;  
#bp_genbank2gff3 -f GenBank $src_file -out $dst_file
#drawgenemap --infile xxx.gb --format pdf --outfile=out --useconfig OGDraw_plastid_set.xml 
#OGDraw/bin/drawgenemap --infile $db/NC_000932.1/GeneBank.gb.txt --format pdf --outfile=out --useconfig OGDraw/OGDraw_plastid_set.xml #drawgenemap --infile $db/NC_000932.1/GeneBank.gb.txt --format ps --outfile=$db/NC_000932.1/out.ps --useconfig OGDraw/OGDraw_plastid_set.xml  
require "./util.pl"; 

my $db; 
GetOptions(
	"input|i=s" => \$db,
); 
my $fileExist1;
my $fileExist2;
print mylog("FILE", "Opening databst: $db");  
opendir DH, $db or die "Cannot open $db: $!";  
foreach my $dir (readdir DH)  
{  	
  next if $dir eq "." or $dir eq "..";  	
  next if $dir =~ /^\./;  	
  next if $dir =~ /.csv$/; 	
  print mylog("FILE", "Entering $dir");      
  print mylog("FILE", "Preparing Genebank Data"); 	
  system("cp $db/$dir/GeneBank.gb.txt $db/$dir/GeneBank.gb");  	
  print mylog("INFO", "Generating Figure");     
  #system("drawgenemap --infile $db/NC_035243.1/GeneBank.gb --format ps --outfile=$db/$dir/tmp.ps --useconfig OGDraw_plastid_set.xml" );
  if($db eq"../data/mtdb")
  {
    system("drawgenemap --infile $db/$dir/GeneBank.gb --format ps --outfile=$db/$dir/tmp.ps --useconfig OGDraw_chondriom_set.xml" );
  }
  if($db eq"../data/cpdb")
  {
    system("drawgenemap --infile $db/$dir/GeneBank.gb --format ps --outfile=$db/$dir/tmp.ps --useconfig OGDraw_plastid_set.xml" );
  }    
  $fileExist1=-e "$db/$dir/tmp.ps";
  $fileExist2=-e "$db/$dir/tmp.ps.ps";
  if($fileExist1)
  {
  system("ps2pdf $db/$dir/tmp.ps $db/$dir/tmp.pdf" ); 
  system("rm $db/$dir/tmp.ps");
  }
  if($fileExist2)
  {
  system("ps2pdf $db/$dir/tmp.ps.ps $db/$dir/tmp.pdf" ); 
  system("rm $db/$dir/tmp.ps.ps"); 
  system("rm $db/$dir/tmp.ps_legend.ps "); 
  }    
  system("pdf2svg $db/$dir/tmp.pdf $db/$dir/fig.svg" );  	
  print mylog("FILE", "Generating GFF");    
  system("bp_genbank2gff3 -f GenBank $db/$dir/GeneBank.gb -out $db/$dir/");      
  print mylog("FILE", "Clearing temp file.");     
  system("rm $db/$dir/GeneBank.gb");     
  #system("rm $db/$dir/tmp.ps");     
  system("rm $db/$dir/tmp.pdf"); 
} 
 closedir DH; #NC_024714.1

