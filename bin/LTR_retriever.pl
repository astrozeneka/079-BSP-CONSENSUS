#!/usr/bin/env perl
use warnings;
use strict;
use File::Basename;

##Supported dependent program versions (or up): GenomeTools/1.5.1, BLAST+/2.2.25, BLAST/2.2.25, HMMER/3.1b1, RepeatMasker/3.3.0, CDHIT/4.5.6, Tandem Repeats Finder 4.07b, and Perl 5.0.0

my $version="v2.9.8";
my $help="
##############################
### LTR_retriever $version ###
##############################

A program for accurate identification of LTR-RTs from outputs of LTRharvest and
	LTR_FINDER, generates non-redundant LTR-RT library for genome annotations.

Shujun Ou (shujun.ou.1\@gmail.com) 03/26/2019

Usage: LTR_retriever -genome genomefile -inharvest LTRharvest_input [options]

【Input Options】
-genome      [File]	Specify the genome sequence file (FASTA)
-inharvest   [File]	LTR-RT candidates from LTRharvest
-infinder    [File]	LTR-RT candidates from LTR_FINDER
-inmgescan   [File]	LTR-RT candidates from MGEScan_LTR
-nonTGCA     [File]	Non-canonical LTR-RT candidates from LTRharvest

【Output options】
-verbose/-v		Retain intermediate outputs (developer mode)
-noanno			Disable whole genome LTR-RT annotation (no GFF3 output)

【Filter options】
-misschar    [CHR]	Specify the ambiguous character (default N)
-Nscreen		Disable filtering ambiguous sequence in candidates
-missmax     [INT]	Maximum number of ambiguous bp allowed in a candidate (default 10)
-missrate    [0-1]	Maximum percentage of ambiguous bp allowed in a candidate (default 0.8)
-minlen      [INT]	Minimum bp of the LTR region (default 100)
-max_ratio   [FLOAT]	Maximum length ratio of internal region/LTR region (default 50)
-minscore    [INT]	Minimum alignment length (INT/2) to identify tandem repeats (default 1000)
-flankmiss   [1-60]	Maximum ambiguous length (bp) allowed in 60bp-flanking sequences (default 25)
-flanksim    [0-100]	Minimum percentage of identity for flanking sequence alignment (default 60)
-flankaln    [0-1]	Maximum alignment portion allowed for 60bp-flanking sequences (default 0.6)
-motif       [[STRING]]	Specify non-canonical motifs to search for
			(default -motif [TCCA TGCT TACA TACT TGGA TATA TGTA TGCA])
-notrunc		Discard truncated LTR-RTs and nested LTR-RTs (will dampen sensitivity)
-procovTE    [0-1]	Maximum portion of allowed for cumulated DNA TE database and LINE database
			lignments (default 0.7)
-procovPL    [0-1]	Maximum portion allowed for cumulated plant protein database alignments (default 0.7)
-prolensig   [INT]	Minimum alignment length (aa) for LINE/DNA transposase/plant protein alignment (default 30)

【Library options】
-blastclust  [[STRING]]	Trigger to use blastclust and customize parameters
			(default -blastclust [-L .9 -b T -S 80])
-cdhit       [[STRING]]	Trigger to use cd-hit-est (default) and customize parameters
			(default -cdhit [-c 0.8 -G 0.8 -s 0.9 -aL 0.9 -aS 0.9 -M 0])
-linelib     [FASTA]	Provide LINE transposase database for LINE TE exclusion
			(default /database/Tpases020812LINE)
-dnalib      [FASTA]	Provide DNA TE transposase database for DNA TE exclusion
			(default /database/Tpases020812DNA)
-plantprolib [FASTA]	Provide plant protein database for coding sequence exclusion
			(default /database/alluniRefprexp082813)
-TEhmm       [Pfam]	Provide Pfam database for TE identification
			(default /database/TEfam.hmm)

【Dependencies】
-repeatmasker [path]	Path to the RepeatMasker program. (default: find from ENV)
-blastplus   [path]	Path to the BLAST+ program. (default: find from ENV)
-blast       [path]	Path to the BLAST program. Required if -blastclust is used. (default: find from ENV)
-cdhit_path  [path]	Path to the CD-HIT program. Required if -cdhit is used. (default: find from ENV)
-hmmer       [path]	Path to the HMMER program. (default: find from ENV)
-trf_path    [path]	Path to the trf program. (default: find from ENV)
-tesorter    [path]	Path to the TEsorter program. (default: find from ENV)

【Miscellaneous】
-u           [FLOAT]	Neutral mutation rate (per bp per ya) (default 1.3e-8 (from rice))
-step	     [STRING]	Restart the program from a particular step. Existing outputs will be overwritten. Options:
				Init (default, from the beginning);
				Major (Tandem repeat cleanup finished, structrual analyses next)
				Trunc (Structural analyses finished, truncated LTR recycle next)
				Promask (Truncated LTR recycle finished, protein contamination cleanup next)
				Library (Protein contamination cleanup finished, initial library construction next)
				Next (Initial library construction finished, non-TGCA analyses next)
-threads     [INT]	Number of threads (≤ total available threads, default 4)
-help/-h		Display this help information

###### For Questions and Issues Please See: https://github.com/oushujun/LTR_retriever ######

";

#obtain the exact path for the program location
my $script_path = dirname(__FILE__);
my $repeatmasker = ''; #path to the RepeatMasker program
my $blastplus=''; #path to the blast+ program
my $blast=''; #path to the blast program
my $cdhit_path=''; #path to the CD-HIT program
my $hmmer=''; #path to the HMMER program
my $trf=""; #path to the trf program
my $TEsorter=''; #path to the TEsorter program

my $inharvest=''; #screen output of LTRharvest with -motif 'TGCA' control
my $infinder=''; #screen output of LTR_finder
my $inmgescan=''; # *.ltrloc output of MGEScan
my $nonTGCA=''; #screen output of LTRharvest without -motif 'TGCA' control
my $genome;
my $Nscreen=" "; #blank enables filtering base on the number of missing characters; "-Nscreen" disable $n_count screening in cleanup.pl
my $misschar="N"; #missing character 'N'
my $missmax=10; #maximum missing characters in a sequence
my $missrate=0.8; #maximum missing rate in a sequence
my $minscore=1000; #minscore of tandem repeats finder
my $minlen=100; #dft=100, minmum LTR region length
my $max_ratio=50; #maximum internal/LTR region length ratio

my $bondcorr=1; #1 means correct the boundary (strongly recommended); 0 means not.
my $flanksim=60; #minimum percent identity of flanking sequence alignment
my $flankmiss=25; #minimum ambiguous characters in 50bp-flanking sequences
my $flankaln=0.6; #
my $tsdaln=" "; #blank means align the TSD (strongly recommended); "-tsdaln" means not.
my @motif=qw/TCCA TGCT TACA TACT TGGA TATA TGTA TGCA/; #known motifs. The last one in the list (default TGCA) will be preferentially identified over the others

my $procovTE=0.7; #for DNA TE and LINE alignment, propotional, cumulated alignment coverage more than this will be treated as protein contained
my $procovPL=0.7; #for plant protein alignment, propotional, cumulated alignment coverage more than this will be treated as protein contained
my $prolensig=30; #aa, hits with alignment length less than this number will not be counted.

my $blastclust=0; #1 for using blastclust as clustering method, 0 for no.
my $cdhit=1; #1 for using cdhit as clustering method, 0 for no.
my $set_bclust="-L 0.9 -b T -S 80"; #set parameters for blastclust
my $set_cdhit="-c 0.8 -G 0.8 -s 0.9 -aL 0.9 -aS 0.9 -M 0"; #set parameters for cdhit

my $keep_trunc="1"; #1 will recycle information from truncated LTR-RTs; 0 will disable this module
my $verbose=0; #0 will delete intermediate files after analysis; 1 will not.
my $annotation=1; #1 will perform whole genome LTR-RT annotation; 0 will not

my $LINE="$script_path/database/Tpases020812LINE";
my $DNA="$script_path/database/Tpases020812DNA";
my $PlantP="$script_path/database/alluniRefprexp082813";
my $TEhmm="$script_path/database/TEfam.hmm";

my $miu="1.3e-8"; #neutral mutation rate of the target species (per bp per ya), e.g., rice: 1.3e-8 (Ma and Bennetzen 2004); mammal: 2.2e−9 (S. Kumar 2002); Drosophila: 1.6e-8 (Bowen and McDonald 2001);
my $step = "Init"; #start the program from a particular step. Default: Init (from the beginning).
my $threads=4;

my $k=0;
my $argv='';
foreach (@ARGV){
	$argv.="$_ ";
	$inharvest=$ARGV[$k+1] if /^-inharvest$/i and $ARGV[$k+1]!~/^-/;
	$infinder=$ARGV[$k+1] if /^-infinder$/i and $ARGV[$k+1]!~/^-/;
	$inmgescan=$ARGV[$k+1] if /^-inMGEScan$/i and $ARGV[$k+1]!~/^-/;
	$nonTGCA=$ARGV[$k+1] if /^-nonTGCA$/i and $ARGV[$k+1]!~/^-/;
	$genome=$ARGV[$k+1] if /^-genome$/i and $ARGV[$k+1]!~/^-/;
	$misschar=$ARGV[$k+1] if /^-misschar$/i and $ARGV[$k+1]!~/^-/;
	$Nscreen="-Nscreen" if /^-Nscreen$/i;
	$missmax=$ARGV[$k+1] if /^-missmax$/i and $ARGV[$k+1]!~/^-/;
	$missrate=$ARGV[$k+1] if /^-missrate$/i and $ARGV[$k+1]!~/^-/;
	$minscore=$ARGV[$k+1] if /^-minscore$/i and $ARGV[$k+1]!~/^-/;
	$bondcorr=0 if /^-bondcorr$/i;
	$flanksim=$ARGV[$k+1] if /^-flanksim$/i and $ARGV[$k+1]!~/^-/;
	$flankmiss=$ARGV[$k+1] if /^-flankmiss$/i and $ARGV[$k+1]!~/^-/;
	$flankaln=$ARGV[$k+1] if /^-flankaln$/i and $ARGV[$k+1]!~/^-/;
	$minlen=$ARGV[$k+1] if /^-minlen$/i and $ARGV[$k+1]!~/^-/;
	$max_ratio=$ARGV[$k+1] if /^-max_ratio$/i and $ARGV[$k+1]!~/^-/;
	$tsdaln="-tsdaln" if /^-tsdaln$/i;
	@motif=(split /\s+/, $1) if $argv=~/-motif\s+\[([atcgnx ]+)\]/i;
	$procovPL=$ARGV[$k+1] if /^-procovPL$/i and $ARGV[$k+1]!~/^-/;
	$procovTE=$ARGV[$k+1] if /^-procovTE$/i and $ARGV[$k+1]!~/^-/;
	$prolensig=$ARGV[$k+1] if /^-prolensig$/i and $ARGV[$k+1]!~/^-/;
	$LINE=$ARGV[$k+1] if /^-linelib$/i and $ARGV[$k+1]!~/^-/;
	$DNA=$ARGV[$k+1] if /^-dnalib$/i and $ARGV[$k+1]!~/^-/;
	$PlantP=$ARGV[$k+1] if /^-plantprolib$/i and $ARGV[$k+1]!~/^-/;
	$TEhmm=$ARGV[$k+1] if /^-TEhmm$/i and $ARGV[$k+1]!~/^-/;
	$miu=$ARGV[$k+1] if /^-u$/i and $ARGV[$k+1]!~/^-/;
	$blastclust=1 if /^-blastclust$/i;
	$set_bclust=$1 if $argv=~/-blastclust\s+\[(.+?)\]/i;
	$cdhit=1 if /^-cdhit$/i;
	$set_cdhit=$1 if $argv=~/-cdhit\s+\[(.+?)\]/i;
	$keep_trunc=0 if /^-notrunc$/i;
	$annotation=0 if /^-noanno$/i;
	$step = $ARGV[$k+1] if /^-step$/i and $ARGV[$k+1]!~/^-/;
	$repeatmasker = $ARGV[$k+1] if /^-repeatmasker$/i and $ARGV[$k+1]!~/^-/;
	$blastplus = $ARGV[$k+1] if /^-blastplus$/i and $ARGV[$k+1]!~/^-/;
	$blast = $ARGV[$k+1] if /^-blast$/i and $ARGV[$k+1]!~/^-/;
	$cdhit_path = $ARGV[$k+1] if /^-cdhit_path$/i and $ARGV[$k+1]!~/^-/;
	$hmmer = $ARGV[$k+1] if /^-hmmer$/i and $ARGV[$k+1]!~/^-/;
	$trf = $ARGV[$k+1] if /^-trf_path$/i and $ARGV[$k+1]!~/^-/;
	$TEsorter = $ARGV[$k+1] if /^-tesorter$/i and $ARGV[$k+1]!~/^-/;
	$verbose=1 if /^-verbose|-v$/i;
	$threads=$ARGV[$k+1] if /^-threads$/i and $ARGV[$k+1]!~/^-/;
	die $help if /^--help|-h$/i;
	$k++;
        }

# Print the value of $genome
print "The value of \$genome is $genome\n";
# Print the value of defined $genome
print "The value of defined \$genome is ", defined $genome, "\n";

die "Please specify the input sequence file!\nUse -h for more help info\n" unless (defined $genome);
die "Please specify LTRharvest and/or LTR_finder screen output file!\nUse -h for more help info\n" unless (defined $inharvest or defined $infinder);

#obtain initial LTR-RT candidates from LTRharvest and/or LTR_finder screen outputs
die "\nERROR: The specified file $nonTGCA does not exist.\n\n" if $nonTGCA!~/^$/ and !-e "$nonTGCA";
die "\nERROR: The specified file $infinder does not exist.\n\n" if $infinder!~/^$/ and !-e "$infinder";
die "\nERROR: The specified file $inmgescan does not exist.\n\n" if $inmgescan!~/^$/ and !-e "$inmgescan";
die "\nERROR: The specified file $inharvest does not exist.\n\n" if $inharvest!~/^$/ and !-e "$inharvest";

print "
##########################
### LTR_retriever $version ###
##########################\n
Contributors: Shujun Ou, Ning Jiang\n
For LTR_retriever, please cite:

	Ou S and Jiang N (2018). LTR_retriever: A Highly Accurate and Sensitive Program for Identification of Long Terminal Repeat Retrotransposons. Plant Physiol. 176(2): 1410-1422.

For LAI, please cite:

	Ou S, Chen J, Jiang N (2018). Assessing genome assembly quality using the LTR Assembly Index (LAI). Nucleic Acids Res. 2018;46(21):e126.

Parameters: @ARGV\n\n\n";

chomp (my $date=`date`);
print "$date\tDependency checking: ";

open Path, "<$script_path/paths" or die "Fail to locate the paths file!\n";
my %path = ("BLAST+"=>'', "HMMER"=>'', "BLAST"=>'', "CDHIT"=>'', "RepeatMasker"=>'');
while (<Path>){
	next if /^#/;
	next if /^\s+$/;
	next unless /=/;
	chomp;
	my ($program, $path)=(split /=/, $_, 2);
	$path=~s/(\s+)?#.*$//;
	$path=~s/\s+//g;
	$path="$path"."/" if $path!~/\/$/;
	$path='' if $path eq '/';
	$path{$program}=$path;
	}
close Path;

#define dependencies based on the path file if unspecified
$blastplus=$path{"BLAST+"} if $blastplus eq '';
$repeatmasker=$path{"RepeatMasker"} if $repeatmasker eq '';
$hmmer=$path{"HMMER"} if $hmmer eq '';
$blast=$path{"BLAST"} if $blast eq '';
$cdhit_path=$path{"CDHIT"} if $cdhit_path eq '';
$TEsorter=$path{"TEsorter"} if $TEsorter eq '';

##test paths to dependent programs
#makeblastdb, blastn, blastx
chomp ($blastplus=`which makeblastdb 2>/dev/null`) if $blastplus eq '';
$blastplus=~s/makeblastdb\n?$//;
$blastplus=~s/blastn\n?$//;
$blastplus=~s/blastx\n?$//;
$blastplus="$blastplus/" if $blastplus ne '' and $blastplus !~ /\/$/;
die "Error: makeblastdb does not exist in the BLAST+ path $blastplus!\n" unless -X "${blastplus}makeblastdb";
die "Error: blastn does not exist in the BLAST+ path $blastplus!\n" unless -X "${blastplus}blastn";
die "Error: blastx does not exist in the BLAST+ path $blastplus!\n" unless -X "${blastplus}blastx";
#blastclust
chomp ($blast=`which blastclust 2>/dev/null`) if $blast eq '';
$blast=~s/blastclust\n?$// unless -d $blast;
$blast="$blast/" if $blast ne '' and $blast !~ /\/$/;
die "Error: blastclust is not found in the BLAST path $blast!\n" if (!(-X "${blast}blastclust") and $blastclust);

#RepeatMasker
my $rand=int(rand(1000000));
chomp ($repeatmasker=`which RepeatMasker 2>/dev/null`) if $repeatmasker eq '';
$repeatmasker=~s/RepeatMasker\n?$// unless -d $repeatmasker;
$repeatmasker="$repeatmasker/" if $repeatmasker ne '' and $repeatmasker !~ /\/$/;
die "Error: RepeatMasker is not found in the RepeatMasker path $repeatmasker!\n" unless -X "${repeatmasker}RepeatMasker";
`cp $script_path/database/dummy060817.fa ./dummy060817.fa.$rand`;
`${blastplus}makeblastdb -in ./dummy060817.fa.$rand -dbtype nucl`;
my $RM_test=`${repeatmasker}RepeatMasker -e ncbi -q -pa 1 -no_is -norna -nolow dummy060817.fa.$rand -lib dummy060817.fa.$rand 2>/dev/null`;
die "Error: The RMblast engine is not installed in RepeatMasker!\n" unless $RM_test=~s/(done|No repetitive sequences were detected)//gi;
`rm dummy060817.fa.$rand* 2>/dev/null`;

#cd-hit-est
chomp ($cdhit_path=`which cd-hit-est 2>/dev/null`) if $cdhit_path eq '';
$cdhit_path=~s/cd-hit-est\n?$//;
$cdhit_path="$cdhit_path/" if $cdhit_path ne '' and $cdhit_path !~ /\/$/;
die "Error: cd-hit-est is not found in the CDHIT path $cdhit_path!\n" if (!(-X "${cdhit_path}cd-hit-est") and $cdhit);
die "Error: neither the path of CDHIT nor BLAST is specified!\n" unless (-X "${blast}blastclust" or -X "${cdhit_path}cd-hit-est");
#hmmsearch
chomp ($hmmer=`which hmmsearch 2>/dev/null`) if $hmmer eq '';
$hmmer=~s/hmmsearch\n?$//;
$hmmer="$hmmer/" if $hmmer ne '' and $hmmer !~ /\/$/;
die "Error: hmmsearch is not found in the HMMER path $hmmer!\n" unless -X "${hmmer}hmmsearch";
#trf
chomp ($trf=`which trf 2>/dev/null`) if $trf eq '';
die "Error: Tandem Repeat Finder is not found in the TRF path $trf!\n" unless -e $trf && -X $trf;
#TEsorter
chomp ($TEsorter=`which TEsorter 2>/dev/null`) if $TEsorter eq '';
die "Error: TEsorter is not found in the TEsorter path $TEsorter!\n" unless -e $TEsorter && -X $TEsorter;

print "All passed!\n";

my ($LINE_base, $LINE_path)=fileparse($LINE);
my ($DNA_base, $DNA_path)=fileparse($DNA);
my ($PlantP_base, $PlantP_path)=fileparse($PlantP);
`cp $LINE ./$LINE_base.$rand`;
`cp $DNA ./$DNA_base.$rand`;
`cp $PlantP ./$PlantP_base.$rand`;
$LINE="$LINE_base.$rand";
$DNA="$DNA_base.$rand";
$PlantP="$PlantP_base.$rand";

`${blastplus}makeblastdb -in $LINE -dbtype prot`;
`${blastplus}makeblastdb -in $DNA -dbtype prot`;
`${blastplus}makeblastdb -in $PlantP -dbtype prot`;
chomp ($date=`date +"%m-%d-%y_%H%M"`);
if ($step eq "Init" and `ls $genome*|wc -l`>15){
	print "\n\t\t\t\tPrevious LTR_retriever results found, backed up to LTRretriever-pre$date\n\n";
	`mkdir LTRretriever-pre$date; mv $genome*.out $genome*.out.gff* $genome*.LAI $genome*.LTRlib* $genome*defalse $genome*.ltrTE* $genome*.retriever.* $genome*.prelib* $genome*.pass.list* $genome*.out*size.list $genome.out.LTR.distribution.txt LTRretriever-pre$date/ 2>/dev/null`;
}

## check if genome writable

if (not -w $genome and $annotation==1){
	die "$genome is not writable, which may raise RepeatMask error\n\n";
}


####################################################################
######### To retrieve high quality LTR-RTs with TGCA motif #########
####################################################################

# make a softlink to the user-provided files
my $genome_file = basename($genome);
`ln -s $genome $genome_file` unless -e $genome_file;
$genome = $genome_file;

#start of the analysis
my $index=$genome;
chomp ($date=`date`);
print "$date\tLTR_retriever is starting from the $step step.\n";
goto $step;
Init:

##check the length of genome sequence IDs, if longer than 13bp, chop it.
my $id_mode=0; #record the mode of id conversion.
my $id_len=`grep \\> $genome|perl -ne 'chomp; s/>//g; my \$len=length \$_; \$max=\$len if \$max<\$len; print "\$max\\n"'`;
$id_len=~s/\s+$//;
$id_len=(split /\s+/, $id_len)[-1];
my $raw_id=`grep \\> $genome|wc -l`;
my $old_id=`grep \\> $genome|sort -u|wc -l`;

##check if duplicated sequences found
if ($raw_id>$old_id){
	$date=`date`;
	die "$date\tDuplicated sequence found in the provided genome! Please remove the duplicated sequece and regenerate input candidates for LTR_retriever\n";
	}

if ($id_len>13){
	chomp ($date=`date`);
	print "$date\tThe longest sequence ID in the genome contains $id_len characters, which is longer than the limit (13)\n";
	print "\t\t\t\tTrying to reformat seq IDs...\n\t\t\t\tAttempt 1...\n";
	`perl -lne 'chomp; if (s/^>+//) {s/^\\s+//; \$_=(split)[0]; s/(.{1,13}).*/>\$1/g;} print "\$_"' $genome > $genome.mod`;
	my $new_id=`grep \\> $genome.mod|sort -u|wc -l`;
	chomp ($date=`date`);
	if ($old_id==$new_id){
		$id_mode=1;
		$index="$genome.mod";
		$genome="$genome.mod";
		print "$date\tSeq ID conversion successful!\n\n";
		} else {
		print "\t\t\t\tAttempt 2...\n";
		`perl -ne 'chomp; if (/^>/) {\$_=">\$1" if /([0-9]+)/;} print "\$_\n"' $genome > $genome.mod`;
		$new_id=`grep \\> $genome.mod|sort -u|wc -l`;
		if ($old_id==$new_id){
			$id_mode=2;
			$index="$genome.mod";
			$genome="$genome.mod";
			print "$date\tSeq ID conversion successful!\n\n";
			} else {
			`rm $genome.mod`;
			die "$date\tERROR: Fail to convert seq IDs to ≤ 13 characters! Please provide a genome with shorter seq IDs.\n\n";
			}
		}
	}

chomp ($date=`date`);
print "$date\tStart to convert inputs...\n";
`perl $script_path/bin/convert_ltr_finder.pl $infinder $id_mode > $index.retriever.scn` if -s $infinder;
`perl $script_path/bin/convert_MGEScan.pl $inmgescan >> $index.retriever.scn` if -s $inmgescan;
`cat $inharvest >> $index.retriever.scn` if -s $inharvest;
die "\nERROR: No candidate is found in the file(s) you specified.\n\n" unless `grep -c -v \'#\' $index.retriever.scn`>0;
`perl $script_path/bin/get_range.pl $index.retriever.scn $genome -f -g -max_ratio $max_ratio`;
`cat $index.retriever.scn.full|sort -fu >$index.retriever.scn.full.uniq; mv $index.retriever.scn.full.uniq $index.retriever.scn.full`;
`perl $script_path/bin/call_seq_by_list.pl $index.retriever.scn.full -C $genome > $index.ltrTE.fa`;

#update status
my $total_candidate=`grep -v -c '#' $index.retriever.scn`;
$total_candidate=~s/\s+//g;
my $uniq_candidate=`wc -l $index.retriever.scn.full`;
$uniq_candidate=~s/^\s+//;
$uniq_candidate=(split /\s+/, $uniq_candidate)[0];
print "\t\t\t\tTotal candidates: $total_candidate
\t\t\t\tTotal uniq candidates: $uniq_candidate\n\n";

##cleanup the NNNs and tandem sequence
my $stg1_count=&cleanTandem($index);

#update status
chomp ($date=`date`);
print "$date\t$stg1_count clean candidates remained\n\n";
goto NEXT if $stg1_count==0;

##Major program, align the boundaries
Major:
my $pass_count=&Identifier($index);
chomp ($date=`date`);
print "$date\tIntact LTR-RT found: $pass_count\n\n";
goto NEXT if $pass_count==0;

##Recycle truncated candidates, mask candidates by false LTR
Trunc:
&trunc($index);

##clean up protein coding sequence from DNA TE, LINE, and normal plant genes
Promask:
&proMask($index);

##generate non-redudant library for pass LTR-RT candidates
Library:
chomp ($date=`date`);
my $prelib_size=-s "$index.ltrTE";
die "ERROR: $pass_count intact LTR-RTs have found, but the pre-library file $index.ltrTE is empty.
Something is wrong at this point. Please report the bug to https://github.com/oushujun/LTR_retriever/issues
Program halt!\n" unless $prelib_size>0;

print "$date\tSequence clustering for $index.ltrTE ...\n";
&makeLib("$index.ltrTE");
`perl $script_path/bin/annotate_lib.pl $index.retriever.scn.adj $index.ltrTE.clust > $index.prelib`;
my $lib_count=`grep -c \\> $index.prelib`;
print "$date\tUnique lib sequence: $lib_count\n";

####################################################################
####### To retrieve high quality LTR-RTs with non-TGCA motif #######
####################################################################
NEXT:
goto End if $nonTGCA eq '';
chomp ($date=`date`);
print "$date\tModule 7: Start to analyze non-TGCA LTR-RT candidates...\n";

my $index2="$index.nmtf";
`cp $nonTGCA $index2.retriever.scn`;
$total_candidate=`grep -v -c \'#\' $index2.retriever.scn`;
$total_candidate=~s/\s+//g;
$total_candidate=0 if $total_candidate!~/[0-9]+/;
print "\t\t\t\tTotal non-TGCA candidates: $total_candidate\n";
goto End if $total_candidate eq 0;
print "$date\tStart to remove non-TGCA candidates that are >=60% identical to TGCA LTRs...\n";

##get LTR regions from non-TGCA raw candidates (original internal boundary)
&getLTR($index2);
goto End unless -s "$index2.ltrTE.LTR";

if (`grep -c -v \'#\' $index.ltrTE.pass.list`>0){
##get LTR regions from TGCA pass candidates and mask LTR regions (no internal regions) from non-TGCA raw candidates
	`perl $script_path/bin/get_range.pl $index.retriever.scn.adj $index.ltrTE.pass.list -N -max_ratio $max_ratio`;
	`cat $index.retriever.scn.adj.list|sort -fu > $index.retriever.scn.adj.list.unq; mv $index.retriever.scn.adj.list.unq $index.retriever.scn.adj.list`;
	`perl $script_path/bin/call_seq_by_list.pl $index.retriever.scn.adj.list -C $genome itself > $index.ltrTE.pass.LTR`;

##condense the pass.LTR lib if size exceed 15M to enhance speed
	&makeLib("$index.ltrTE.pass.LTR") if (-s "$index.ltrTE.pass.LTR")>15000000;
	`mv $index.ltrTE.pass.LTR.clust $index.ltrTE.pass.LTR` if -s "$index.ltrTE.pass.LTR.clust";
	`${blastplus}makeblastdb -in $index.ltrTE.pass.LTR -dbtype nucl`;
	`${repeatmasker}RepeatMasker -e ncbi -qq -pa $threads -no_is -norna -nolow -div 40 -lib $index.ltrTE.pass.LTR -cutoff 225 $index2.ltrTE.LTR 2>/dev/null`;
	`rm $index.ltrTE.pass.LTR.* 2>/dev/null`;
	}

##cleanup highly masked sequence and tandem sequence from masked LTR regions (no internal)
	if (-s "$index2.ltrTE.LTR.masked"){
		`perl $script_path/bin/cleanup.pl -trf 1 -trf_path $trf -minscore 150 -Nscreen -nr 0.6 -minlen $minlen -f $index2.ltrTE.LTR.masked > $index2.ltrTE.stg1`;
		} else {
		`cp $index2.ltrTE.LTR $index2.ltrTE.stg1`;
		}

#update status
chomp ($date=`date`);
$uniq_candidate=`grep -c \\> $index2.ltrTE.stg1`;
$uniq_candidate=~s/\s+//g;
$uniq_candidate=int($uniq_candidate/2);
print "$date\tTotal uniq non-TGCA candidates: $uniq_candidate\n\n";

##cleanup the NNNs and tandem sequence from candidates (including internal regions)
$minscore=150;
`cp $index2.ltrTE.stg1 $index2.ltrTE.fa`;
$stg1_count=&cleanTandem($index2);
$stg1_count=int($stg1_count/2);
chomp ($date=`date`);
print "$date\t$stg1_count clean non-TGCA candidates remained\n\n";
goto End if $stg1_count==0;

##Major program, align the boundaries
$pass_count=&Identifier($index2);
chomp ($pass_count);
chomp ($date=`date`);
print "$date\tIntact non-TGCA LTR-RT found: $pass_count\n\n";

#Aggregate all candidates into one list
`cat $index.retriever.scn.adj $index2.retriever.scn.adj > $index.retriever.all.scn`;
goto End if $pass_count==0;

##Recycle truncated candidates, mask candidates by false LTR
&trunc($index2);

##DNA TE element and LINE protein masking
&proMask($index2);

##All passed LTR-RT candidates, including internal region and the longer LTR region for truncated LTR-RT candidates
`perl $script_path/bin/annotate_lib.pl $index2.retriever.scn.adj $index2.ltrTE >> $index.prelib`; #contains both TGCA and nmtf LTR-RT

############################
####### Final stage ########
############################

End:
`cp $index.retriever.scn.adj $index.retriever.all.scn` unless (-s "$index.retriever.all.scn");

##obtain good nmtf entries from index.ltrTE and index2.ltrTE using $genome.nmtf.pass.list
`touch $genome.nmtf.pass.list`;
if (`grep -c -v \'#\' $genome.nmtf.pass.list`>0){
	`perl $script_path/bin/get_range.pl $index.retriever.all.scn $genome.nmtf.pass.list -i -N`;
	`perl $script_path/bin/output_by_list.pl 1 $index.ltrTE 2 $index.retriever.all.scn.list -FA -MSU0 -MSU1 > $index.ltrTE.nmtf`;
	`perl $script_path/bin/output_by_list.pl 1 $index2.ltrTE 2 $index.retriever.all.scn.list -FA -MSU0 -MSU1 >> $index.ltrTE.nmtf` if defined $index2;
	`perl $script_path/bin/annotate_lib.pl $index.retriever.all.scn $index.ltrTE.nmtf > $index.nmtf.prelib`;
	}

`touch $index.prelib`;
my $prelib_count=`grep -c \\> $index.prelib`;
$prelib_count=~s/\s+//g;
if ($prelib_count>0){

chomp ($date=`date`);
print "$date\tModule 6: Start to remove nested insertions in internal regions...\n";

##get rid of solo LTR nested in internal regions
`perl -nle 'next unless /\\>/; print \$_ if /INT#LTR/i' $index.prelib|sort -u > $index.prelib.INT.list`;
`perl -nle 'next unless /\\>/; print \$_ unless /INT#LTR/i' $index.prelib|sort -u > $index.prelib.LTR.list`;
if (-s "$index.prelib.INT.list" and -s "$index.prelib.LTR.list"){
	`perl $script_path/bin/output_by_list.pl 1 $index.prelib 1 $index.prelib.INT.list -FA > $index.prelib.INT`;
	`perl $script_path/bin/output_by_list.pl 1 $index.prelib 1 $index.prelib.LTR.list -FA > $index.prelib.LTR`;
	&makeLib("$index.prelib.LTR");
	`${blastplus}makeblastdb -in $index.prelib.LTR.clust -dbtype nucl`;
	`${repeatmasker}RepeatMasker -e ncbi -q -pa $threads -no_is -norna -nolow -div 40 -lib $index.prelib.LTR.clust -cutoff 225 $index.prelib.INT > /dev/null 2>&1`;
	`rm $index.prelib.LTR.clust.* > /dev/null 2>&1`;
	if (-e "$index.prelib.INT.masked"){
		`perl $script_path/bin/cleanup.pl -nr 0.8 -minlen $minlen -trf 1 -trf_path $trf -cleanN 1 -f $index.prelib.INT.masked > $index.prelib.INT.cln`; #only non-solo-LTR-nested IN regions
		} else {
		`cp $index.prelib.INT $index.prelib.INT.cln`;
		}
	`perl $script_path/bin/cleanup_nestedIN.pl -in $index.prelib.INT.cln -minlen $minlen -cov 0.95 -blastplus $blastplus -threads $threads > $index.prelib.INT.cln2`;
	`perl $script_path/bin/cleanup_nestedIN.pl -in $index.prelib.INT.cln2 -minlen $minlen -cov 0.95 -blastplus $blastplus -threads $threads > $index.prelib.INT.cln3`;
	`cat $index.prelib.LTR $index.prelib.INT.cln3 > $index.LTRlib`;

#update status
	chomp ($date=`date`);
	my $ori_size=-s "$index.prelib.INT";
	my $cln_size=-s "$index.prelib.INT.cln3";
	print "\nWarning: RepeatMasker seems to be not running correctly! Please check this program by running:
	RepeatMasker -e ncbi -q -pa $threads -no_is -norna -nolow -div 40 -lib $index.prelib.LTR.clust -cutoff 225 $index.prelib.INT
	Please report any errors to https://github.com/oushujun/LTR_retriever/issues\n\n" if $ori_size>0 and $cln_size==0;
	print "$date\tRaw internal region size (bit): $ori_size\n\t\t\t\tClean internal region size (bit): $cln_size\n\n";
	} else {
	`cp $index.prelib $index.LTRlib`;
	}
if ( -s "$index.nmtf.prelib"){
	`perl $script_path/bin/output_by_list.pl 1 $index.prelib.INT.cln 1 $index.nmtf.prelib -FA > $index.nmtf.LTRlib.fa`;
	`grep INT $index.nmtf.prelib|perl $script_path/bin/output_by_list.pl 1 $index.nmtf.prelib 1 - -FA -ex >> $index.nmtf.LTRlib.fa`;
	}

##make the redundant lib (contains TGCA and non-TGCA LTR-RTs. LTR nested insertion and non-LTR protease are not removed, but plant protein is removed)
`perl -i -nle 's/>(.*)\\|(.*)\\[(.+)\\]/>\$2\\|LTR_\$3/g;print "\$_"' $genome.LTRlib.raw`;
`perl $script_path/bin/output_by_list.pl 1 $genome.LTRlib.raw 2 $genome.LTRlib.exclude.tgt -FA -ex | perl $script_path/bin/annotate_lib.pl $genome.retriever.all.scn - > $genome.LTRlib.redundant.fa`;

##update status
my $redun_count=`grep -c \\> $genome.LTRlib.redundant.fa`;
$redun_count=~s/\s+//g;
my $redun_size=-s "$genome.LTRlib.redundant.fa";
chomp ($date=`date`);
print "$date\tSequence number of the redundant LTR-RT library: $redun_count
\t\t\t\tThe redundant LTR-RT library size (bit): $redun_size\n\n";

#update status
chomp ($date=`date`);
print "$date\tModule 8: Start to make non-redundant library...\n\n";

##make non-redundant library and format output
&makeLib("$index.LTRlib");
if (-s "$index.LTRlib.clust"){
	`perl $script_path/bin/fasta-reformat.pl $index.LTRlib.clust 50 > $index.LTRlib.fa`;
	`rm $index.LTRlib.clust`;
	} else {
	chomp ($date=`date`);
	print "$date\tMake library for $index.LTRlib failed! Please check the file\n\n";
	}

#update status
my $lib_count=`grep -c \\> $index.LTRlib.fa`;
$lib_count=~s/\s+//g;
my $lib_size=-s "$index.LTRlib.fa";
chomp ($date=`date`);
print "$date\tFinal LTR-RT library entries: $lib_count
\t\t\t\tFinal LTR-RT library size (bit): $lib_size\n\n";

##Format outputs and cleanup intermediate files
`echo '\#LTR_loc        Category        Motif   TSD     5'_TSD        3'_TSD       Internal        Identity      Strand  SuperFamily  TE_type     Insertion_Time' > $genome.pass.list.unq`;
`sort -uV -k1,4 $genome.pass.list >> $genome.pass.list.unq; mv $genome.pass.list.unq $genome.pass.list`;
`echo '\#LTR_loc	Category	Motif	TSD	5'_TSD	3'_TSD	Internal	Identity	Strand	SuperFamily	TE_type	Insertion_Time' > $genome.nmtf.pass.list.unq`;
`sort -uV -k1,4 $genome.nmtf.pass.list >> $genome.nmtf.pass.list.unq; mv $genome.nmtf.pass.list.unq $genome.nmtf.pass.list`;

#update status
my $pass_count=`grep -c -v \'#\' $genome.pass.list`;
my $nmtf_count=`grep -c -v \'#\' $genome.nmtf.pass.list`;
$pass_count=~s/\s+//g;
$nmtf_count=~s/\s+//g;
chomp ($date=`date`);
print "$date\tTotal intact LTR-RTs found: $pass_count
\t\t\t\tTotal intact non-TGCA LTR-RTs found: $nmtf_count\n\n";

`perl $script_path/bin/make_gff3.pl $genome $genome.pass.list`;
##Annotate LTR-RT in the genome
chomp ($date=`date`);
if ($annotation==1){
	chomp ($date=`date`);
	print "$date\tStart to annotate whole-genome LTR-RTs...\n\t\t\t\tUse -noanno if you don't want whole-genome LTR-RT annotation.\n\n";
	`${blastplus}makeblastdb -in $genome.LTRlib.fa -dbtype nucl`;
	`${repeatmasker}RepeatMasker -e ncbi -pa $threads -q -no_is -norna -nolow -div 40 -lib $genome.LTRlib.fa -cutoff 225 $genome > /dev/null 2>&1`;
	`rm $genome.LTRlib.fa.* > /dev/null 2>&1`;
	my $genome_size=`grep "total length" $genome.tbl|awk '{print \$3}'`;
	chomp $genome_size;

	# summarize LTR distributions
	`perl $script_path/bin/fam_coverage.pl $genome.LTRlib.fa $genome.out $genome_size > $genome.out.fam.size.list`;
	`perl $script_path/bin/fam_summary.pl $genome.out.fam.size.list $genome_size > $genome.out.superfam.size.list`;
	`perl $script_path/bin/LTR_sum.pl -genome $genome -all $genome.out > $genome.out.LTR.distribution.txt`;

	# combine homology-based and strutrual-based annotation
	`perl $script_path/bin/RMout2bed.pl $genome.out > $genome.out.bed`; # a regular enriched bed
	`perl $script_path/bin/bed2gff.pl $genome.out.bed LTR_annot > $genome.out.gff3`;
	`perl $script_path/bin/gff2bed.pl $genome.out.gff3 homology > $genome.out.bed`; # add the last column to this bed
	`perl $script_path/bin/gff2bed.pl $genome.pass.list.gff3 structural > $genome.pass.list.bed`;
	`perl $script_path/bin/combine_overlap.pl $genome.pass.list.bed $genome.pass.list.bed.cmb 5`;

	`perl $script_path/bin/get_frag.pl $genome.out.bed $genome.pass.list.bed.cmb $threads`;
	`perl $script_path/bin/keep_nest.pl $genome.pass.list.bed $genome.out.bed $threads`;
	`grep homology $genome.pass.list.bed-$genome.out.bed > $genome.pass.list.bed-$genome.out.bed.homo`;
	`sort -suV $genome.pass.list.bed-$genome.out.bed.homo $genome.out.bed-$genome.pass.list.bed.cmb > $genome.LTR.homo.bed`;
	`perl $script_path/bin/bed2gff.pl $genome.LTR.homo.bed LTR_homo > $genome.LTR.homo.gff3`;
	`cat $genome.pass.list.gff3 $genome.LTR.homo.gff3 > $genome.LTR.gff3.raw`;
	`grep -v '^#' $genome.LTR.gff3.raw | sort -sV -k1,1 -k4,4 | perl -0777 -ne '\$date=\`date\`; \$date=~s/\\s+\$//; print "##gff-version 3\\n##date \$date\\n##Identity: Sequence identity (0-1) between the library sequence and the target region.\\n##ltr_identity: Sequence identity (0-1) between the left and right LTR regions.\\n##tsd: target site duplication.\\n##seqid source sequence_ontology start end score strand phase attributes\\n\$_"' - > $genome.LTR.gff3`;
	`rm $genome.LTR.gff3.raw`;

	# calculate LAI
	my $info=`perl $script_path/LAI -genome $genome -intact $genome.pass.list -all $genome.out -t $threads -q -blast $blastplus`;
	print "$info";
	}
} else {
chomp ($date=`date`);
print "$date\tNo LTR-RT was found in your data.\n\n";
}

`perl $script_path/bin/cleanOutput.pl $genome $LINE $DNA $PlantP` if $verbose==0;
chomp ($date=`date`);
print "$date\tAll analyses were finished!\n";
if ($prelib_count>0){
print "
##############################
####### Result files #########
##############################

Table output for intact LTR-RTs (detailed info)
	$genome.pass.list (All LTR-RTs)
	$genome.nmtf.pass.list (Non-TGCA LTR-RTs)
	$genome.pass.list.gff3 (GFF3 format for intact LTR-RTs)\n";

print "
LTR-RT library
	$genome.LTRlib.redundant.fa (All LTR-RTs with redundancy)
	$index.LTRlib.fa (All non-redundant LTR-RTs)
	$index.nmtf.LTRlib.fa (Non-TGCA LTR-RTs)
";

print "
Whole-genome LTR-RT annotation by the non-redundant library
	$genome.LTR.gff3 (GFF3 format)
	$genome.out.fam.size.list (LTR family summary)
	$genome.out.superfam.size.list (LTR superfamily summary)
" if $annotation==1;

print "
LTR Assembly Index (LAI)\n\t$genome.out.LAI
\n" if -s "$genome.out.LAI";
}


###################################################################
################# A collection of subroutines #####################
###################################################################

sub cleanTandem {
##cleanup the NNNs and tandem sequence
chomp ($date=`date`);
print "$date\tModule 1: Start to clean up candidates...
\t\t\t\tSequences with $missmax missing bp or $missrate missing data rate will be discarded.
\t\t\t\tSequences containing tandem repeats will be discarded.\n\n";

my $index=$_[0];
`perl $script_path/bin/cleanup.pl $Nscreen -trf 1 -trf_path $trf -misschar $misschar -nc $missmax -nr $missrate -minlen $minlen -minscore $minscore -f $index.ltrTE.fa > $index.ltrTE.stg1`;
my $count=0;
$count=`grep -c \\> $index.ltrTE.stg1`;
$count=~s/\s+//g;
return $count;
}

sub Identifier {
##Major program, align the boundaries
chomp ($date=`date`);
print "$date\tModules 2-5: Start to analyze the structure of candidates...
\t\t\t\tThe terminal motif, TSD, boundary, orientation, age, and superfamily will be identified in this step.\n\n";
my $index=$_[0];
`perl $script_path/bin/get_range.pl $index.retriever.scn $index.ltrTE.stg1 -x`;
`cat $index.retriever.scn.extend |sort -fu > $index.retriever.scn.extend.unq; mv $index.retriever.scn.extend.unq $index.retriever.scn.extend`;
`perl $script_path/bin/call_seq_by_list.pl $index.retriever.scn.extend -C $genome > $index.retriever.scn.extend.fa`; #full TE sequence with 50bp-extended on each side

# use TE HMM to classify candidates
`perl $script_path/bin/Six-frame_translate.pl $index.retriever.scn.extend.fa > $index.retriever.scn.extend.fa.aa`; ##six-frame translate candidate sequences
`${hmmer}hmmsearch --tblout $index.retriever.scn.extend.fa.aa.tbl --notextw --cpu $threads -E 0.05 --domE 0.05 --noali $TEhmm $index.retriever.scn.extend.fa.aa > $index.retriever.scn.extend.fa.aa.scn`;
`touch $index.retriever.scn.extend.fa.aa.tbl` unless -s "$index.retriever.scn.extend.fa.aa.tbl";
`perl $script_path/bin/annotate_TE.pl $index.retriever.scn.extend.fa.aa.tbl > $index.retriever.scn.extend.fa.aa.anno`;

# use more TE HMM from TEsorter to classify candidates
`$TEsorter $index.retriever.scn.extend.fa --disable-pass2 -p $threads 2>/dev/null`;
`touch $index.retriever.scn.extend.fa.rexdb.cls.tsv` unless -s "$index.retriever.scn.extend.fa.rexdb.cls.tsv";
`awk '{print \$1"\\t"\$2"\\t"\$3"\\t"\$6"\\t"\$7}' $index.retriever.scn.extend.fa.rexdb.cls.tsv | perl -nle 's/([0-9]+\\.\\.[0-9]+)_(.*:[0-9]+\\.\\.[0-9]+)/\$1\\|\$2/; print \$_' >> $index.retriever.scn.extend.fa.aa.anno 2>/dev/null`;

# identify intact LTR retrotransposons
`perl $script_path/bin/LTR.identifier.pl $index -list $index.retriever.scn -seq $index.retriever.scn.extend.fa -anno $index.retriever.scn.extend.fa.aa.anno -flanksim $flanksim -flankmiss $flankmiss -flankaln $flankaln -minlen $minlen $tsdaln -u $miu -threads $threads -blastplus $blastplus -motif @motif > $index.defalse`;
`perl -nle 'next unless /pass/i; print \$_ unless /notLTR/i or /mixture/i' $index.defalse > $index.ltrTE.pass.list`;
my $count=0;
$count=`grep -v -c \'#\' $index.ltrTE.pass.list`;
$count=~s/\s+//g;
return $count;
}

sub trunc {
my $index=$_[0];
##get lLTR, rLTR, and IN from pass and clusterize
`perl $script_path/bin/get_range.pl $index.retriever.scn.adj $index.ltrTE.pass.list -i -N`;
`cat $index.retriever.scn.adj.list|sort -fu > $index.retriever.scn.adj.list.unq; mv $index.retriever.scn.adj.list.unq $index.retriever.scn.adj.list`;
`cat $index.retriever.scn.adj.list >> $genome.LTRID.list`;
`perl $script_path/bin/call_seq_by_list.pl $index.retriever.scn.adj.list -C $genome > $index.ltrTE.pass`; #lLTR, rLTR, and IN regions seperated of pass entries
`cat $index.ltrTE.pass >> $genome.LTRlib.raw`;
&makeLib("$index.ltrTE.pass");
`mv $index.ltrTE.pass.clust $index.ltrTE.stg2`; #lLTR, rLTR, and IN from pass

if ($keep_trunc){
chomp ($date=`date`);
print "$date\tModule 6: Start to analyze truncated LTR-RTs...
\t\t\t\tTruncated LTR-RTs without the intact version will be retained in the LTR-RT library.
\t\t\t\tUse -notrunc if you don't want to keep them.\n\n";

##get longer LTR and IN from trunc and masked by pass
`perl -nle 'next unless /trunc/i; next if /notLTR/i or /mixture/i or /\\s+NA/i; s/^\\s+//; my \$loc=(split)[0]; print "\$loc\\t\$loc"' $index.defalse > $index.ltrTE.trunc.list`;
my $trunc=0;
$trunc=`wc -l $index.ltrTE.trunc.list`;
$trunc=~s/^\s+//;
$trunc=(split /\s+/, $trunc)[0];
chomp ($date=`date`);
print "$date\t$trunc truncated LTR-RTs found\n";
if ($trunc>0){
`perl $script_path/bin/get_range.pl $index.retriever.scn.adj $index.ltrTE.trunc.list -i -N -L`;
`cat $index.retriever.scn.adj.list|sort -fu > $index.retriever.scn.adj.list.unq; mv $index.retriever.scn.adj.list.unq $index.retriever.scn.adj.list`;
`perl $script_path/bin/call_seq_by_list.pl $index.retriever.scn.adj.list -C $genome > $index.ltrTE.trunc`; #IN and the longer LTR region
`perl -i -nle 's/>(.*)\\|(.*)\\[(.+)\\]/>\$2\\|LTR_\$3/g;print "\$_"' $index.ltrTE.trunc`;

`perl -nle 'next unless /false/i; next unless /notLTR/i; print \$_ unless /motif:TGCA/i;' $index.defalse > $index.ltrTE.veryfalse.list`;
`awk '{print \$1"\\t"\$1}\' $index.ltrTE.veryfalse.list > $index.ltrTE.veryfalse`;
`perl $script_path/bin/call_seq_by_list.pl $index.ltrTE.veryfalse -C $genome > $index.ltrTE.veryfalse.fa`;
`cat $index.ltrTE.stg2 $index.ltrTE.veryfalse.fa > $index.ltrTE.mask.lib`;
`${blastplus}makeblastdb -in $index.ltrTE.mask.lib -dbtype nucl`;
my $info=`${repeatmasker}RepeatMasker -e ncbi -q -pa $threads -no_is -norna -nolow -div 40 -lib $index.ltrTE.mask.lib -cutoff 225 $index.ltrTE.trunc 2>/dev/null`;
`rm $index.ltrTE.mask.lib.* 2>/dev/null`;
`cp $index.ltrTE.trunc $index.ltrTE.trunc.masked` if $info=~/No repetitive sequences were detected/;

#file checking
die "ERROR: RepeatMasker is not running properly!
	Please check the file $index.ltrTE.mask.lib and $index.ltrTE.trunc and test run:
		RepeatMasker -e ncbi -q -pa $threads -no_is -norna -nolow -div 40 -lib $index.ltrTE.mask.lib -cutoff 225 $index.ltrTE.trunc
	Please report errors to https://github.com/oushujun/LTR_retriever/issues\nProgram halt!\n" unless -s "$index.ltrTE.trunc.masked";

`perl $script_path/bin/cleanup.pl -nr 0.8 -minlen $minlen -trf 1 -trf_path $trf -cleanN 1 -f $index.ltrTE.trunc.masked > $index.ltrTE.trunc.cln`;
`cat $index.ltrTE.stg2 $index.ltrTE.trunc.cln > $index.ltrTE.stg3.cln`;
`cat $index.ltrTE.trunc.cln >> $genome.LTRlib.raw`;
	} else {
	`cp $index.ltrTE.stg2 $index.ltrTE.stg3.cln`;
	}
my $trunc_lib=0;
$trunc_lib=`grep -c \\> $index.ltrTE.trunc.cln` if -s "$index.ltrTE.trunc.cln";
$trunc_lib=~s/\s+//g;
chomp ($date=`date`);
print "$date\t$trunc_lib truncated LTR sequences have added to the library\n\n";

} else {
print "Attention: No truncated LTR-RTs will be saved in the final LTR-RT library.\n\n";
`cp $index.ltrTE.stg2 $index.ltrTE.stg3.cln`;
}
}

sub proMask {
my $index=$_[0];
my $raw_lib_count=`grep -c \\> $index.ltrTE.stg3.cln`;
$raw_lib_count=~s/\s+//g;
chomp ($date=`date`);
print "$date\tModule 5: Start to remove DNA TE and LINE transposases, and remove plant protein sequences...
\t\t\t\tTotal library sequences: $raw_lib_count\n";

##DNA TE transposase, LINE transposase, and plant protein masking
`${blastplus}blastx -word_size 3 -outfmt 6 -max_target_seqs 10 -num_threads $threads -query $index.ltrTE.stg3.cln -db $LINE -out $index.ltrTE.stg3.line.out`;
`${blastplus}blastx -word_size 3 -outfmt 6 -max_target_seqs 10 -num_threads $threads -query $index.ltrTE.stg3.cln -db $DNA -out $index.ltrTE.stg3.dna.out`;
`cat $index.ltrTE.stg3.line.out $index.ltrTE.stg3.dna.out > $index.ltrTE.stg3.otherTE.out`;
`perl $script_path/bin/purger.pl -blast $index.ltrTE.stg3.otherTE.out -seq $index.ltrTE.stg3.cln -cov $procovTE -purge 0 -len $prolensig`;

`${blastplus}blastx -word_size 3 -outfmt 6 -max_target_seqs 10 -num_threads $threads -query $index.ltrTE.stg3.cln.clean -db $PlantP -out $index.ltrTE.stg3.plantP.out`;
`perl $script_path/bin/purger.pl -blast $index.ltrTE.stg3.plantP.out -seq $index.ltrTE.stg3.cln.clean -cov $procovPL -purge 1 -len $prolensig`;

#use the purger generated exclude target to get the element ID
`touch $index.ltrTE.stg3.cln.clean.exclude` unless -e "$index.ltrTE.stg3.cln.clean.exclude";
`for i in \`perl -nle 's/\\|.*//; print \$_' $index.ltrTE.stg3.cln.clean.exclude\`; do grep \$i $genome.LTRID.list; done\|perl -ne 's/\\[.*//; print \$_'|sort -u > $index.ltrTE.stg3.cln.clean.exclude.father`;

#use the element ID to get the IDs of LTR1, LTR2, and IN
`for i in \`cat $index.ltrTE.stg3.cln.clean.exclude.father\`; do grep \$i $genome.LTRID.list; done\|sort -u > $index.ltrTE.stg3.cln.clean.exclude.child`;

#exclude the child sequences
`perl $script_path/bin/output_by_list.pl 1 $index.ltrTE.stg3.cln.clean.clean 2 $index.ltrTE.stg3.cln.clean.exclude.child -FA -ex > $index.ltrTE.stg3.cln.clean.clean.clean`;

#aggregate child exclude targets to a list
`cat $index.ltrTE.stg3.cln.clean.exclude.child >> $genome.LTRlib.exclude.tgt`;

`mv $index.ltrTE.stg3.cln.clean.clean.clean $index.ltrTE`;

#generate clean pass.list without plant protein contamination
`perl $script_path/bin/output_by_list.pl 1 $index.ltrTE.pass.list 1 $index.ltrTE.stg3.cln.clean.exclude.father -ex > $index.ltrTE.pass.list.cln`;
`mv $index.ltrTE.pass.list.cln $index.ltrTE.pass.list`;
`perl -nle 'next if /motif:TGCA/i; next unless /motif:T...\\s+/i; next unless /TSD:.....\\s+/i; print \$_ unless /TSD:NA/i;' $index.ltrTE.pass.list > $index.ltrTE.pass.nmtf.list`;
`cat $index.ltrTE.pass.nmtf.list >> $genome.nmtf.pass.list` ;
`cat $index.ltrTE.pass.list >> $genome.pass.list`;
chomp ($date=`date`);
my $cln_lib_count=`grep -c \\> $index.ltrTE`;
$cln_lib_count=~s/\s+//g;
print "$date\tRetained clean sequence: $cln_lib_count\n\n";
}

sub makeLib {
##generate non-redudant library for input sequences
my $seq=$_[0];
print "ERROR: $seq is empty, please check the last file\n" unless -s "$seq";
if ($blastclust==1){
	`cp $seq $seq.tmp`;
	`${blast}blastclust -i $seq.tmp -o $seq.clust.info -a $threads -p F $set_bclust`;
	`cp $seq.clust.info $seq.clust.info.all`;
	my $head=`head -1 $seq.clust.info`;
	$head=~s/^\s+//;
	my @head=(split /\s+/, $head);
	my $i=1;
	while (@head>1 and $i<=10){
		`perl $script_path/bin/make_lib.pl $seq.list $seq.tmp $seq.clust.info`;
		`mv $seq.tmp.clust $seq.tmp`;
		`${blast}blastclust -i $seq.tmp -o $seq.clust.info -a $threads -p F $set_bclust`;
		`cat $seq.clust.info >> $seq.clust.info.all`;
		$head=`head -1 $seq.clust.info`;
		$head=~s/^\s+//;
		@head=(split /\s+/, $head);
		$i++;
		}
	print "$i\n";
	if (-e "$seq.tmp.clust"){
		`mv $seq.tmp.clust $seq.clust`;
		} else {
		`mv $seq.tmp $seq.clust`;
		}
	}
if ($cdhit==1){
	`${cdhit_path}cd-hit-est -i $seq -o $seq.clust $set_cdhit -T $threads`;
	}
`perl -i -nle 's/>(.*)\\|(.*)\\[(.+)\\]/>\$2\\|LTR_\$3/g;print "\$_"' $seq.clust`;
}

sub getLTR {
##get LTR regions from raw candidates (original internal boundary)
my $index=$_[0];
`perl $script_path/bin/get_range.pl $index.retriever.scn $genome -N -g -max_ratio $max_ratio`;
`perl $script_path/bin/call_seq_by_list.pl $index.retriever.scn.list -C $genome itself > $index.ltrTE.LTR`;
`perl -i -nle 's/>(.*)\\\|(.*)/>\$2/g;print "\$_"' $index.ltrTE.LTR`;
}
