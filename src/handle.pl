#!/usr/bin/perl -w
use strict;
use LWP::Simple;
use Getopt::Long;
use Date::Manip;
require "./cpData.pl";

#get the latest date
sub getdate{
   #get file handle
   my $ncbi_file="../temp/genomes_organelles.txt";

   #the new date
   my $date1;

   #read file
   my $ncbi_data = file2str($ncbi_file);

   #handle string and compare date
   my @lines = split('\n', $ncbi_data);
   for (my $i=1; $i<$#lines; $i++) 
   {
	  my @line = split('\t', $lines[$i]);
      if($i==1)
      {
      	$date1=$line[15];
      }
	  my $date2 = $line[15];
      my $flag = Date_Cmp($date1, $date2);
      if($line[4]ne"-"&&$flag&&$flag<0)
      {
        $date1=$date2;
      }
   }

   #return the latest date
   return $date1;
}

#get the data required updated
sub getnc{
    #the first parameter is old date
    my $date1 =$_[0];

    #get file handle
    my $ncbi_file="../temp/genomes_organelles.txt";
    
    #result string
    my $mt;
    my $cp;
    my $nc_mt;
    my $nc_cp;
    
    #counter
    my $cpsum = 0;
    my $mtsum = 0;
    
    #read file
    my $ncbi_data = file2str($ncbi_file);

    #handle string
    my @lines = split('\n', $ncbi_data);
    $mt=$mt."$lines[0]\n";
    $cp=$cp."$lines[0]\n";
    for (my $i=1; $i<$#lines; $i++) 
    {
      my @line = split('\t', $lines[$i]);
      my $date2 = $line[15];
      my $flag = Date_Cmp($date1, $date2);
      if($line[4]ne"-"&&$flag&&$flag<0){
        if($line[3]eq"mitochondrion"){
          if($mtsum>0)
          {
            $nc_mt=$nc_mt.",";
          }
           $nc_mt=$nc_mt."$line[4]";
           $mt=$mt."$lines[$i]\n";
           $mtsum++;
        }
        if($line[3]eq"chloroplast"||$line[3]eq"plastid"){
          if($cpsum>0)
          {
            $nc_cp=$nc_cp.",";
          }
           $nc_cp=$nc_cp."$line[4]";
           $cp=$cp."$lines[$i]\n";
           $cpsum++;
        }
      }
    }

    #write result string to file
    saveAsFile($mt,"../temp/mt.txt");
    saveAsFile($cp,"../temp/cp.txt");
    saveAsFile($nc_mt,"../temp/nc_mt.txt");
    saveAsFile($nc_cp,"../temp/nc_cp.txt");
}

#classify normal and fast
sub classify {
    #latest cp file
    #the nc number of normal
    my $ncbi_file="cp.txt";
    my $ncbi_number="normal_list.txt";
    
    #read file
    my $ncbi_data = file2str($ncbi_file);
    my $nc_number = file2str($ncbi_number);
    
    #result string
    my $normal;
    my $fast;

    #get nc number of normal
    my @nc = split(',' , $nc_number);
    
    #handle string
    my @lines = split('\n', $ncbi_data);
    $normal=$normal."$lines[0]";
    $fast=$fast."$lines[0]";
    for (my $i=1; $i<$#lines; $i++) 
    {
      my @line = split('\t', $lines[$i]);
      
       my $flag=0;
       for(my $j=0;$j<$#nc;$j++)
       {
        if($line[4]eq$nc[$j])
        {
         $normal=$normal."$lines[$i]";
      
         $flag=1;
        }
       }
     if($flag==0)
     {
      $fast=$fast."$lines[$i]";
     }
    
   }

   #write file
   saveAsFile($normal,"../temp/cp_normal.txt");
   saveAsFile($fast,"../temp/cp_fast.txt");
}

sub Format{
    #the file of store nc number of download error or normal
    my $error_list=$_[0];

    #read file
    my $nc_number = file2str($error_list);
    my $list;
    my @nc = split(',' , $nc_number);
    $list=$list."$nc[0]";
    for (my $i=1; $i<$#nc; $i++)
    {
       $list=$list.",$nc[$i]";  
    }
    saveAsFile($list,"../temp/list.txt");
}
1;
