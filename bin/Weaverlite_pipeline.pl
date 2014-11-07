#!/usr/bin/perl
#
#
######
use Getopt::Long ;
use Getopt::Long qw(:config no_ignore_case);
use POSIX;
use FindBin qw($Bin);
use Parallel::ForkManager;
use Cwd 'abs_path';

$RUN_TYPE = shift@ARGV;

GetOptions(
        #MANDATORY
        #OPTIONAL
        'p|thread=i'=>\$P,
        'g|gap=s'=>\$GAP, # with chr [MANDATORY]
	'b|bam=s'=>\$BAM, # [MANDATORY]
	'f|fa=s'=>\$FA, # no .fa [MANDATORY]
	'F|FullFa=s'=>\$FULLFA,
        'h|help' =>\$help,
        'o|output=s'=>\$OUT_DIR,
	'k|onekg=s'=>\$ONEKG, # dir [MANDATORY]
	's|sex=s'=>\$SEX, # M or F
        'C=i'=>\$cov);

#################################
$VERSION = 1.0;
#################################

if($BAM eq "" || $help || $FA eq "" || $ONEKG eq "" || $GAP eq ""){
        if(defined $FA && ! -e "$FA.fa"){
                print "$FA.fa does not exist\n";
        }
        print "Weaver v$VERSION\nUsage:\n
        -p/--thread             number of cores
        -f/--fa			[MANDATORY] bowtie and bwa reference dir/name
        -g/--gap		[MANDATORY] bowtie reference dir/name, thus bowtie index should be dir/name.*.ebwt, reference genome should also be located here, e.g. dir/name.fa; chromosome line for dir/name.fa should be clean and there is no space within it, such as \">XXXXX\\n\"
        -b/--bam                bam file
        -o/--output             output dir
	-k/--onekg		1000 Gemomes Project data dir
	-s/--sex		Female (F) or Male (M). Y chromosome will not be used if the bam is from female tissue.
        -h/--help
        \n\n";

        exit(0);
}

print $RUN_TYPE,"\n";


$P = $P || 50; # default thread
$SEX = $SEX || "M"; # default male

open(RUNLOG,">>RUNLOG");
$NOW = time;
$now_string = localtime;
print RUNLOG "$now_string:\tStart\n";
$bwt = abs_path($bwt);
## SNP SNPLINK 1000_LINK
$now_string = localtime;
print RUNLOG "$now_string:\tSNP\n";

#-------------------
#
#Germline point mutations and number of reads mapped on
#
#-------------------
if($RUN_TYPE == "lite"){
	system("$Bin/pipe.pl $GAP $BAM $FULLFA $P $ONEKG $SEX");
}
else{
	system("$Bin/pipe.pl $GAP $BAM $FULLFA $P $ONEKG $SEX");
}
$now_string = localtime;
print RUNLOG "$now_string:\tSNP done\n";
## SV finding
$now_string = localtime;
print RUNLOG "$now_string:\tSV\n";
system("$Bin/../Weaver_SV/bin/Weaver_SV.pl $BAM $FA $FULLFA $GAP $P");
$now_string = localtime;
print RUNLOG "$now_string:\tSV done\n";
## get wig/bw file
$now_string = localtime;
#-------------------
#
#Generate wiggle file which will be used in Weaver core program as read depth
#
#
#-------------------

print RUNLOG "$now_string:\twig\n";
system("$Bin/bam2bw.pl $BAM $P $SEX");
$now_string = localtime;
print RUNLOG "$now_string:\twig done\n";
