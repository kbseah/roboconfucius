#!/usr/bin/env perl

# Robot Confucius
# by Brandon Seah (kb.seah@gmail.com)

## MODULES #################################################

use strict;
use warnings;
use utf8;
use Encode;
use Getopt::Long;

## VARS ####################################################

my $infile;
my $monofreq_file;
my $bifreq_file;
my $tries=1;	# Default no. of sentence generation cycles
my $maxlength=25;	# Maximum length of sentences
my $keep_punc;	# Default: strip punctuation
my %char_hash;
my $total_char=0;
my %bigrams_hash;
my %freq_hash;
my $report_entropies = 0;

if (!defined @ARGV) {
	usage();
	exit;
}

GetOptions ("input|i=s"=>\$infile,
			"tries|t=i"=>\$tries,
			"min|m=i"=>\$maxlength,
			"punc|p"=>\$keep_punc,
			"freq1|f=s"=>\$monofreq_file,
			"freq2|g=s"=>\$bifreq_file,
			"entropy|e"=>\$report_entropies
			) or die ("$!\n");

## MAIN ####################################################

count_freqs($infile);
binmode (STDOUT, ":utf8");	# Set output coding to UTF-8
if (defined $monofreq_file) { print_monogram_freqs($monofreq_file); }
if (defined $bifreq_file) { print_bigram_freqs($bifreq_file); }
do_ngram_generation($tries,$maxlength);
if ($report_entropies == 1) {	# Report entropies 
	print "\n";
	my @entropies = calc_entropies();
	my @entropy_header = ("characters","bigrams","mutual");
	print join "\t",@entropy_header;
	print "\n";
	print join "\t", @entropies;
	print "\n";
}

## SUBROUTINES #############################################

sub count_freqs {	# Read input and hash the chars and bigrams
	my ($file) = @_;
	my $curr_char;
	my $prev_char;
	open (INPUT, "<", $file) or die ("$!\n");
	while (<INPUT>) {
		chomp;
		my $line = $_;
		$line = decode_utf8($line);
		if (!defined $keep_punc) {
			$line =~ s/[.,;"'?!#()“”‘’。，、！？﹔；：「」『』【】（）()\d\s]//g; # strip punctuation and spaces and numbers
		}
		elsif ($keep_punc == 1) {
			$line =~ s/\s//g;	# strip only spaces
		}
		elsif ($keep_punc == 2) {	# Experimental
			$line =~ s/[.,;"'?!#()]//g;	# strip only non-word and non-word chars
		}
		my @theline = split "", $line;	# split line to indiv characters
		foreach my $thechar (@theline) {
			$char_hash{$thechar}++;	# running count for that character
			$total_char++;	# running count for all characters
			$prev_char = $curr_char;
			$curr_char = $thechar;
			$bigrams_hash{$prev_char}{$curr_char}++ unless (!defined $prev_char);	# running count for bigrams
		}
	}
	close (INPUT);
}

sub print_monogram_freqs {
	my ($outfile) = @_;
	open (OUTFILE, ">", $outfile) or die ("$!\n");
	binmode (OUTFILE, ":utf8");	# Output encoding in UTF-8
	foreach my $thechar (sort {$char_hash{$b} <=> $char_hash{$a}} keys %char_hash) {
		print OUTFILE $thechar."\t". $char_hash{$thechar}."\n";
	}
	close (OUTFILE);
}

sub calc_entropies {
	my $charcount = 0; # counter for characters
	my $bigramcount = 0; # counter for bigrams
	my $entropy_char = 0;
	my $entropy_bigram = 0;
	my $entropy_bigram_mutual = 0;
	# Total up char counts
	foreach my $key (keys %char_hash) {
		$charcount += $char_hash{$key};
	}
	# Total up bigram counts
	foreach my $key1 (keys %bigrams_hash) {
		foreach my $key2 (keys %{$bigrams_hash{$key1}}) {
			$bigramcount += $bigrams_hash{$key1}{$key2};
		}
	}
	# Calculate entropy of single characters
	foreach my $key (keys %char_hash) {
		my $pm = $char_hash{$key} / $charcount;
		$entropy_char += - $pm * log2($pm);
	}
	# Calculate entropy and mutual info of bigrams
	foreach my $key1 (keys %bigrams_hash) {
		foreach my $key2 (keys %{$bigrams_hash{$key1}}) {
			my $pb = $bigrams_hash{$key1}{$key2} / $bigramcount;
			my $pm1 = $char_hash{$key1} / $charcount;
			my $pm2 = $char_hash{$key2} / $charcount;
			$entropy_bigram += - $pb * log2($pb);
			$entropy_bigram_mutual += $pb * log2($pb/($pm1*$pm2));
		}
	}
	return ($entropy_char, $entropy_bigram, $entropy_bigram_mutual);
}

sub log2 {
	my ($val) = @_;
	return log($val)/log(2);
}

sub print_bigram_freqs {
	my ($outfile) = @_;
	my %rehash;
	foreach my $char1 (keys %bigrams_hash) {
		foreach my $char2 (keys %{$bigrams_hash{$char1}}) {
			$rehash{$char1.$char2} = $bigrams_hash{$char1}{$char2};
		}
	}
	open (OUTFILE, ">", $outfile) or die ("$!\n");
	binmode (OUTFILE, ":utf8");	# Ouptut encoding in UTF-8
	foreach my $thebigram (sort {$rehash{$b} <=> $rehash{$a}} keys %rehash) {
		print OUTFILE $thebigram."\t".$rehash{$thebigram}."\n";
	}
	close (OUTFILE);
}

sub pick_rand_key { #pick the first character randomly weighted by char freqs
	my (%inhash) = @_;
	my $firstchar;
	my $rc = 0; # running count
	my %refreq;	
	for my $char (keys %inhash) { 
		my $rc_old = $rc;
		$rc += $inhash{$char};
		$refreq{$rc_old}{$rc} = $char;
#		print $rc_old."\t".$rc."\t";	# diagnostic
	}
	
	my $rn = int(rand($rc)) + 1; # random number
#	print $rn."\n";	# diagnostic
	# go through hash of frequencies and find for which character
	# the random number falls in the range thereof
	for my $key1 (keys %refreq) {
		if ($rn > $key1) {
			for my $key2 (keys %{$refreq{$key1}}) {
				if ($rn <= $key2) { 
					$firstchar = $refreq{$key1}{$key2};
				}
			}
		}
	}
	return $firstchar;
}

sub rehash_bigrams { # subset of bigram hash by first character
	my ($firstchar, %inhash) = @_;
	my %outhash;
	foreach my $key (keys %{$inhash{$firstchar}}) {
		$outhash{$firstchar.$key} = $inhash{$firstchar}{$key};
	}
	return %outhash;
}

sub do_ngram_generation {
	my ($tt, $ml) = @_;
	my $char;
	$char = pick_rand_key(%char_hash);
	#$char = "具";	# diagnostic
	for (my $i=0; $i<$tt; $i++) {
		for (my $k=0; $k<$ml; $k++) {
			print STDOUT $char;
			my %bigram_rehash = rehash_bigrams($char, %bigrams_hash);
			my $bigram = pick_rand_key(%bigram_rehash);
			if (defined $bigram) {
				my @bigram_split = split "", $bigram;
				$char = $bigram_split[1];

			}
			elsif (!defined $bigram) {
				print "END";
				last;	# Break out of loop if this character doesn't have a bigram
			}
		}
		print STDOUT $char;	# last character
		print "\n";
	}
}

sub usage {
	print "\n\tRobot Confucius\n";
	print "\tRandom generation of Confucian classics from bigram frequencies\n\n";
	print "\tUsage: perl $0 -i INPUT -t $tries -m $maxlength \\ \n";
	print "\t\t\t[-f OUT1] [-g OUT2] [-p]\n";
	print "\n";
	print "\t\t-i\tInput file, UTF-8 encoded\n";
	print "\t\t-t\tNumber of sentence generation cycles (default $tries)\n";
	print "\t\t-m\tMaximum sentence length (default $maxlength)\n";
	print "\t\t-f\tOutput file of character counts (optional)\n";
	print "\t\t-g\tOutput file of bigram counts (optional)\n";
	print "\t\t-p\tKeep punctuation in bigrams (default: no)\n";
	print "\n";
}