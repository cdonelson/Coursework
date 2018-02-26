# Curtis Donelson, CMSC 416, Spring 2017, PA #4: Word Sense Disambiguation  
# This program is part 1 of a 2-part, word sense disambiguation program.  Its purpose is to decide the sense of a given word,
# in this case "line", between 1 of 2 senses: either "phone" or "product".  After reading in a set of training data, the program
# builds a frequency model.  This model is then used to determine the most likely sense of an occurence of "line" given the other words
# in its context.  Initial cleaning involved lemmatization, removal of stop words, changing all words to lower-case, and removal
# of punctuation.  After this, a set of test "contexts" are given to the program for it to choose a sense.  Each context serves as the
# basis for constructing a feature vector and compared to the training model to decide appropriate sense.  Part 2 of this program scores the output.
#
# Baseline accuracy: 88.8%    This is the initial accuracy after cleaning
#
# After determining baseline accuracy, several other features are calculated (previous word, following word, surrounding words, and offset words).
# These additions always resulted in a drop of accuracy for unknown reasons.
# K, K+1 accuracy: 88.1%
# K-1, K accuracy: 88.1%
# K-1, K ,K+1 accuracy: 88.1%
# K, K+1, K+2 accuracy: 88.1%
#
# Command line input: perl decision-list.pl line-train.txt line-test.txt my-decision-list.txt > my-line-answers.txt
# Sample training input: 
#	<instance id="line-n.w7_114:11070:">
#	<answer instance="line-n.w7_114:11070:" senseid="product"/>
#	<context>
#	<s> The group also said it would consider filing with federal antitrust regulators for clearance to boost its stake. </s> <@> </p> <@> <p> <@> <s> The group, which has held talks with investment 
#		bankers regarding some of the possible actions, said it would consider selling certain Atlas <head>lines</head> and properties, should it gain control. </s> 
#	</context>
#	</instance>
#
# Sample testing input: 
# 	<instance id="line-n.w9_16:217:">
#	<context>
#	<s> Its 10 million people are burdened with an $18 billion debt, stuck with a defunct infrastructure and a technologically untrained work force. </s> <@> </p> <@> <p> <@> <s> 
#	    In Budapest offices, secretaries often work in groups to make a single call on one of the country's huge, pea-green telephone "machines," which have plenty of levers and flashing lights
#	    but a poor record of finding a free <head>line</head> . </s> 
#	</context>
#	</instance>
#
# Sample output:  <answer instance="line-n.w7_098:12684:" senseid="phone"/>


#!/usr/local/bin/perl
use warnings;
use Data::Dumper;
local $/;

my $trainCorpus = $ARGV[0];
my $testCorpus = $ARGV[1];
my $decisionList = $ARGV[2];


# Variable declarations
my %featureHash = ();  # Hash that holds features and their scores
my %senseHash = ();    # Hash that holds features, scores, and senses
my %tempHash = ();     # Hash used to hold features defined from added rules
my @featureArray = ();   # Array that holds feature in index i, score in i+1
my @featureVector = ();  # Array for a test context whose elements contain 0 or 1 based on their match to @featureArray
my @corpusArray = ();    # Array to hold the training corpus 
my @testArray = ();     # Array to hold the text being tested
my @printArray = ();   # Array to hold the formatted output
my $featureSense = "";

# Read in the text from the training corpus and construct a frequency hash of its features
@corpusArray = ReadIntoArray($trainCorpus);
%featureHash = BuildFeatureHash(\@corpusArray);

# Rules added to expand on baseline feature identification: adding k+1 features, k-1 and k+1 features, and k+1 and k+2 features.
# featureHash is updated after each rule is implemented.
%tempHash = BuildKPlusOne(\@corpusArray);
foreach my $tempFeature(keys %tempHash)
{ $featureHash{$tempFeature} = $tempHash{$tempFeature}; }
%tempHash = BuildKPlusMinusOne(\@corpusArray);
foreach my $tempFeature(keys %tempHash)
{ $featureHash{$tempFeature} = $tempHash{$tempFeature}; }
%tempHash = BuildKPlusOnePlusTwo(\@corpusArray);
foreach my $tempFeature(keys %tempHash)
{ $featureHash{$tempFeature} = $tempHash{$tempFeature}; }

# Create a senseHash from the feature data, put that into an array for easy comparison, and create an array for the test instances.
%senseHash = BuildSenseHash(\%featureHash);
@featureArray = BuildFeatureArray(\%senseHash);
@testArray = ReadIntoArray($testCorpus);

# This structure creates a feature vector from each instance being tested.  If the vector returns a 1, the appropriate sense is attached to the test instance for output and stored into @printArray
for (my $j = 1; $j <=$#testArray; $j=$j+2)
{ 
	@featureVector = BuildFeatureVector(\@featureArray, $testArray[$j]);
	for (my $k = 0; $k <=$#featureVector; $k++)
	{
		if($featureVector[$k] == 1)
		{
			push(@printArray,$testArray[$j-1]." senseid=\"".$senseHash{$featureArray[2*$k]}{"sense"}."\"\/>\n");
			last;
		}
		if($k == $#featureVector)
		{ push(@printArray,  $testArray[$j-1]." senseid=\" NULL SET "."\"\/>\n"); }
	}
}

# Output the decision list and appropriate sense responses
WriteDecisionList(\%senseHash, $decisionList);
WriteLineAnswers(\@printArray);
	 
	 
# Function to output sense answers	 
sub WriteLineAnswers
{
	my ($printArrayRef) = @_;
	my @printArray = @{$printArrayRef};
	print @printArray;
}

# Function to output the decision list, unsorted
sub WriteDecisionList
{
	my ($senseHashRef, $decisionList) = @_;
	my %senseHash = %{$senseHashRef};
	open(DST, ">$decisionList") || die;
	print DST Dumper(\%senseHash);
	close (DST);
}

# Function creates a feature vector by splitting the incoming context into an array and comparing that to @featureArray
sub BuildFeatureVector
{
	my ($featureArrayRef, $testArrayText) = @_;
	my @featureArray = @{$featureArrayRef};
	my @testArray = ();
	my @featureVector = ();
	push(@testArray,split(/\s+/,$testArrayText));
	for (my $i = 0; $i <= $#featureArray; $i=$i+2)
	{
		for (my $j=0; $j <= $#testArray; $j++)
		{
			if($testArray[$j] eq $featureArray[$i])
			{ 
				$featureVector[$i/2] = 1;
				last;
			}
			$featureVector[$i/2] = 0;
		}
	}
	return @featureVector;
}


# Function that populates an array with text from a context.  Identifies if incoming instance is from
# training or test data and processes text appropriately.  Returns the array.	
sub ReadIntoArray
{
	my $corpus = "";
	my @returnArray = ();
	open(SRC, $_[0]) || die;
	while(<SRC>) 
	{ 
		chomp;
		$corpus = "$_"; 
	}
	close (SRC);
	my @holdArray = split(/<context>|<\/context>/, $corpus);
	foreach $element(@holdArray)
	{
		 if ($element =~ m/.*(<answer.*>)/)
		 { push(@returnArray, $1); }
		 elsif ($element =~ /.*<instance id=(.*)>/)
		 { 
		 	push(@returnArray, "<answer instance=$1");
		 	next; 
		 }
		 elsif($element =~ m/<\/corpus>/)
		 { next; }
		 else
		 {
		 	$element =~ s/\s<s>\s|\s<\/s>|<head>|<\/head>|<@>|<p>\s|<\/p>\s//g;
		 	$element =~ s/!|\?|\.|,|;|:|\'|\"//g;
		 	$element = lc($element);
		 	$element =~ s/\ba\b|\ban\b|\band\b|\bare\b|\bas\b|\bat\b|\bbe\b|\bby\b|\bfor\b|\bfrom\b|\bhas\b|\bhe\b|\bin\b|\bis\b//g;
		 	$element =~ s/\bit\b|\bits\b|\bof\b|\bon\b|\bthat\b|\bthe\b|\bto\b|\bwas\b|\bwere\b|\bwill\b|\bwith\b//g;
		 	$element =~ s/^\s+|\s+$//g;
		 	$element =~ s/ing\b//g;
		 	$element =~ s/ed\b//g;
			push(@returnArray, $element);
		 }
	}
	return @returnArray;
}

# Function to build a frequency hash based off of features identified from the given text, in this case
# it will come from the training data.
sub BuildFeatureHash
{
	my $corpusArrayRef = $_[0];
	my @corpusArray = @{$corpusArrayRef};
	my @instanceArray = ();
	my %featureHash = ();
	my $senseID = "";
	for (my $i=1;$i<=$#corpusArray;$i=$i+2)
	{
		@instanceArray = split(/\s+/,$corpusArray[$i]);
		foreach $element(@instanceArray)
		{
			$wordSense = substr($corpusArray[$i-1], index($corpusArray[$i-1],"senseid=\"")+9);
			$wordSense =~ s/(.*)\"\/>/$1/g;
			$wordSense =~ s/\s+//g;
			$featureHash{$element}{$wordSense}++;
		}
	}
	return %featureHash
}

# Function to build a feature hash based off of a word and its predecessor
sub BuildKPlusOne
{
	my $corpusArrayRef = $_[0];
	my @corpusArray = @{$corpusArrayRef};
	my @instanceArray = ();
	my @holdArray = ();
	my @tempArray = ();
	my %featureHash = ();
	my $senseID = "";
	for (my $i=1;$i<=$#corpusArray;$i=$i+2)
	{
		@holdArray = split(/\s+/,$corpusArray[$i]);
		for (my $j=0; $j<$#holdArray; $j++)
		{
			push(@tempArray, $holdArray[$j]." ".$holdArray[$j+1]);
		}
		foreach $element(@tempArray)
		{	
			$wordSense = substr($corpusArray[$i-1], index($corpusArray[$i-1],"senseid=\"")+9);
			$wordSense =~ s/(.*)\"\/>/$1/g;
			$wordSense =~ s/\s+//g;
			$featureHash{$element}{$wordSense}++;
		}
		@tempArray = ();
	}
	return %featureHash;
}

# Function to build a featureHash based off a word, its predecessor, and its successor
sub BuildKPlusMinusOne
{
	my $corpusArrayRef = $_[0];
	my @corpusArray = @{$corpusArrayRef};
	my @instanceArray = ();
	my @holdArray = ();
	my @tempArray = ();
	my %featureHash = ();
	my $senseID = "";
	for (my $i=1;$i<=$#corpusArray;$i=$i+2)
	{
		@holdArray = split(/\s+/,$corpusArray[$i]);
		for (my $j=1; $j<$#holdArray; $j++)
		{
			push(@tempArray, $holdArray[$j-1]." ".$holdArray[$j]." ".$holdArray[$j+1]);
		}
		foreach $element(@tempArray)
		{	
			$wordSense = substr($corpusArray[$i-1], index($corpusArray[$i-1],"senseid=\"")+9);
			$wordSense =~ s/(.*)\"\/>/$1/g;
			$wordSense =~ s/\s+//g;
			$featureHash{$element}{$wordSense}++;
		}
		@tempArray = ();
	}
	return %featureHash;
}

# Function to build a featureHash based off the two successors to a given word
sub BuildKPlusOnePlusTwo
{
	my $corpusArrayRef = $_[0];
	my @corpusArray = @{$corpusArrayRef};
	my @instanceArray = ();
	my @holdArray = ();
	my @tempArray = ();
	my %featureHash = ();
	my $senseID = "";
	for (my $i=1;$i<=$#corpusArray;$i=$i+2)
	{
		@holdArray = split(/\s+/,$corpusArray[$i]);
		for (my $j=0; $j<$#holdArray-1; $j++)
		{
			push(@tempArray, $holdArray[$j]." ".$holdArray[$j+1]." ".$holdArray[$j+2]);
		}
		foreach $element(@tempArray)
		{	
			$wordSense = substr($corpusArray[$i-1], index($corpusArray[$i-1],"senseid=\"")+9);
			$wordSense =~ s/(.*)\"\/>/$1/g;
			$wordSense =~ s/\s+//g;
			$featureHash{$element}{$wordSense}++;
		}
		@tempArray = ();
	}
	return %featureHash;
}

# Function that builds a hash containing features, scores, and senses.  If a feature sense does not exist, it is initially
# assigned a zero.  Plus 1 smoothing is then applied because values of zero could cause division by zero or an undefined logarithm.
# Senses are assigned based off the log-likelihood score.  If the probabilities are equal, meaning the log-likelihood is zero,
# then a rand() picks between one of the two equally likely senses.
sub BuildSenseHash
{
	my $featureHashRef = $_[0];
	my %featureHash = %{$featureHashRef};
	my %senseHash = ();
	my %probHash = ();
	my $score = 0;
	foreach my $feature(keys %featureHash)
	{
		if(exists $featureHash{$feature}{"product"})
		{}
		else
		{ $featureHash{$feature}{"product"} = 0; }
		if(exists $featureHash{$feature}{"phone"})
		{}
		else
		{ $featureHash{$feature}{"phone"} = 0; }
		$probHash{$feature}{"product"} = ($featureHash{$feature}{"product"} + 1)/($featureHash{$feature}{"product"}+$featureHash{$feature}{"phone"}+2);
		$probHash{$feature}{"phone"} = ($featureHash{$feature}{"phone"} + 1)/($featureHash{$feature}{"product"}+$featureHash{$feature}{"phone"}+2);
	}
	foreach my $feature(keys %featureHash)
	{
		$score = log($probHash{$feature}{"phone"}/$probHash{$feature}{"product"})/log(2);
		if($score > 0)
		{ $senseHash{$feature}{"sense"} = "phone"; }
		elsif($score == 0 && rand() > 0.5)
		{ $senseHash{$feature}{"sense"} = "phone"; }
		else
		{ $senseHash{$feature}{"sense"} = "product"; }
		$senseHash{$feature}{"score"} = abs($score);
	}
	return %senseHash;
}

# Function to build an array that holds a feature and its log-likelihood score.  The array can be easily sorted
# based off of this score and is returned.
sub BuildFeatureArray
{
	my $senseHashRef = $_[0];
	my %senseHash = %{$senseHashRef};
	my %tempHash = ();
	my @featureVector = ();
	my @returnVector = ();
	my $tempValue = 0;
	foreach my $feature(keys %senseHash)
	 { 
	 	$tempValue = $senseHash{$feature}{"score"};
	 	$tempHash{$tempValue}{$feature}++;
	 }

	foreach my $score(sort keys %tempHash)
	{
		foreach my $feature(keys $tempHash{$score})
		{
			push(@featureVector, $feature);
			push(@featureVector, $score);
		}

	}
	for (my $i = $#featureVector-1; $i>0; $i=$i-2)
	{
		push(@returnVector,$featureVector[$i]);
		push(@returnVector,$featureVector[$i+1]);
	}
	return @returnVector;
}