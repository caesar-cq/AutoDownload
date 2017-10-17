#!/usr/bin/perl
    use strict;
    use warnings;
    use Date::Manip;
    require "./handle.pl";
    
    #download counter
    my $count=3;

    #get latest date
    #my $date=getdate();
    # my $date="1986/11/18";
    my $date="2017/04/20";

    #download genomes_organelles.txt
    system("python download.py");

    #download data
    my $newdate=getdate();
    my $flag = Date_Cmp($newdate, $date);
    if($flag&&$flag>0)
    {
       getnc($date);
       system("perl CPbatchDownload.pl -i ../temp/nc_cp.txt -o ../data/cpdb");
       for(my $i=0;$i<$count-1;$i++)
       {
          if(!(-z "../temp/normal_list.txt"))
          {
            Format("../temp/normal_list.txt");
            system("perl CPbatchDownload.pl -i ../temp/list.txt -o ../data/cpdb");
          }
       }
       classify();
       system("perl MTbatchDownload.pl -i ../temp/nc_mt.txt -o ../data/mtdb");
       while(!(-z "../temp/mt_error.txt")) 
       { 
          Format("../temp/mt_error.txt");
          system("perl MTbatchDownload.pl -i ../temp/list.txt -o ../data/mtdb");
       }
    }
  else
  {
   print "genomes_organelles.txt download error\n";
  }
  system("perl fileConvert.pl -i ../data/mtdb");
  system("perl fileConvert.pl -i ../data/cpdb");
