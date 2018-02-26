# Curtis Donelson, CMSC 416, Spring 2017, PA #3
# This program is part 1 of a 2-part, part-of-speech tagger.  It takes in a text file with the words already tagged
# and uses this to build a baseline frequency hash.  This hash is then used to tag a separate, untagged text file with
# the most likely part of speech.  The baseline accuracy was calculated at this point.  Then five grammer rules are added 
# to the tagger, resulting in an increased accuracy of over 5%.  The accuracies are included below.  Part 2 of this 
# program (scorer.pl) compares the tagged file with a pre-tagged key.
#
# Baseline accuracy: 84.39%
# Rules-implemented accuracy: 89.55%
#
# Sample input showing a sentence from each of the input files.
# Training text file: "Pierre/NNP Vinken/NNP ,/, 61/CD years/NNS old/JJ ,/, will/MD join/VB the/DT board/NN as/IN 
# a/DT nonexecutive/JJ director/NN Nov./NNP 29/CD ./."
#
# Testing text file: "No , it was n't Black Monday . But while the New York Stock Exchange did n't fall apart 
# Friday as the Dow Jones Industrial Average plunged 190.58 points -- most of it in the final hour -- it 
# barely managed to stay this side of chaos ."
#
# Sample output showing the testing file after tagging: "No/DT ,/, it/PRP was/VBD n't/RB Black/NNP Monday/NNP ./. 
# But/CC while/IN the/DT New/NNP York/NNP Stock/NNP Exchange/NNP did/VBD n't/RB fall/NN apart/NN Friday/NNP as/IN 
# the/DT Dow/NNP Jones/NNP Industrial/NNP Average/NNP plunged/VBD 190.58/CD points/NNS --/: most/JJS of/IN it/PRP 
# in/IN the/DT final/JJ hour/NN --/: it/PRP barely/RB managed/VBN to/TO stay/VB this/DT side/NN of/IN chaos/NNS ./. 


#!/usr/local/bin/perl
use warnings;

# Variable declarations
my $trainData = $ARGV[0];    
my $testData = $ARGV[1];
my $writeData = $ARGV[2];
my @trainArray = ();
my @testArray = ();
my @writeArray = ();
my @tempArray = ();     
my %posHash = ();
my %posHashUpdated = ();
my %relFreqTable = ();  # hash to hold relative frequencies of POS/word
local $/;

# Creates the baseline probability hash using training data.
@trainArray = PosArray($trainData); # words (index i) and tags (index i+1)
for (my $i = 0; $i < $#trainArray; $i=$i+2)
{ 
	my $inWord = $trainArray[$i];
	my $inTag = $trainArray[$i+1];
	$posHash{$inWord}{$inTag}++; 
}

# Calculate relative frequencies of words/tags in the model.
foreach my $inWord (keys %posHash)
{
	my $keyTotal = 0;
	foreach my $inTag (keys $posHash{$inWord})
	{ $keyTotal += $posHash{$inWord}{$inTag}; }
	foreach my $inTag (keys $posHash{$inWord})
	{ $relFreqTable{$inWord}{$inTag} = $posHash{$inWord}{$inTag}/$keyTotal; }
}

@testArray = PosArrayNoTags($testData); # testArray holds the words from a text file
WriteFile(\@testArray, $writeData);  # Writes those words to a separate text file.
TagFile(\%posHash, \@testArray, $writeData);  # Tags that file using basic frequencies of word/POS


# Use rules to improve accuracy of tagging
@writeArray = PosArray($writeData);   #writeArray holds the words and tags from a text file

# Rule 1 implementation:  If a word is capitalized and tagged as NN, tag it as NNP
for(my $j = 0; $j < $#writeArray; $j = $j+2)
{
	my $ucWrite = ucfirst($writeArray[$j]);
	if($writeArray[$j] eq $ucWrite && $writeArray[$j+1] eq "NN")
	{ $writeArray[$j+1] = "NNP"; }
}

# Rule 2 implementation:  If a word contains a digit, tag it as CD
for(my $j = 0; $j < $#writeArray; $j = $j+2)
{
	if($writeArray[$j] =~ m/\d+/)
	{ $writeArray[$j+1] = "CD"; }
}

# Rule 3 implementation; If a word contains a dash and tagged as NN, tag it as JJ
for(my $j = 0; $j < $#writeArray; $j = $j+2)
{
	if($writeArray[$j] =~ m/-/ && $writeArray[$j+1] eq "NN")
	{ $writeArray[$j+1] = "JJ"; }
}

# Rule 4 implementation: If a word ends in 's' and tagged as NN, tag it as NNS
for(my $j = 0; $j < $#writeArray; $j = $j+2)
{
	if($writeArray[$j] =~ /s$/ && $writeArray[$j+1] eq "NN")
	{ $writeArray[$j+1] = "NNS";}
}

# Rule 5 implementation: If a word ends in 'ly' and tagged as NN, tag it as RB
for(my $j = 0; $j < $#writeArray; $j = $j+2)
{
	if($writeArray[$j] =~ m/ly$/ && $writeArray[$j+1] eq "NN")
	{ $writeArray[$j+1] = "RB"; }
}

# Updates posHash with new word/POS hash including implemented rules, then retags the test-with-tags file
for (my $i = 0; $i < $#writeArray; $i=$i+2)
{ 
	my $inWord = $writeArray[$i];
	my $inTag = $writeArray[$i+1];
	$posHashUpdated{$inWord}{$inTag}++; 
}
TagFile(\%posHashUpdated, \@testArray, $writeData);

# Function accepts a text file that hasn't been tagged and returns an array of the individual words.
sub PosArrayNoTags
{
	my $corpus = "";
	open(SRC, $_[0]) || die;
	while(<SRC>) 
	{ 
		chomp;
		$corpus = "$_"; 
	}
	close (SRC);
	my @array = split(/\s+/, $corpus);
	my @returnArray = ();
	foreach $element(@array)
	{
		if($element !~ /[\[\]]/)
		{
			$element =~ s/\s+//g;
			push(@returnArray, $element);
		}
	}
	return @returnArray;
}

# Function accepts an array of words and writes them to a given text file.	
sub WriteFile
{
	my ($writeArrayRef, $writeDataRef) = @_;
	my @writeArray = @{$writeArrayRef};
	my $writeData = $writeDataRef;
	open(DST, ">$writeData") || die;
	for(my $i = 0; $i <= $#writeArray; $i++)
	{ print DST $writeArray[$i]." "; }
}


# Function accepts 3 arguments: posHash containing a two-layer frequency hash of words and their tags, 
# writeArray containing text to be written, and $writeData containing the name of the destination file.
sub TagFile
{
	my ($posHashRef, $writeArrayRef, $writeDataRef) = @_;
	my %posHash = %{$posHashRef};
	my @writeArray = @{$writeArrayRef};
	my $writeData = $writeDataRef;
	open(DST, ">$writeData") || die;
	for (my $i = 0; $i <= $#writeArray; $i=$i+1) # move through writeArray and tag words with most likely PoS tag
	{
		my $maxTag = "";
		my $maxTagValue = 0;
		if(exists $posHash{$writeArray[$i]})      # if a word from writeArray exists in trained data...
		{
			foreach my $inTag(keys $posHash{$writeArray[$i]})    # ...find the most likely tag for the given word
			{ 
				if($posHash{$writeArray[$i]}{$inTag} > $maxTagValue)
				{ 
					$maxTag = $inTag; 
					$maxTagValue = $posHash{$writeArray[$i]}{$inTag};
				}
			}
		}
		else
		{ $maxTag = "NN"; }
		print DST $writeArray[$i]."\/"."$maxTag ";
	}
	close(DST);
	print "\n";
}


# Function that takes in a string representing a text file to be opened.  The function returns an array
# of each word (index i) followed by the part of speech (index i+1) that was tagged to it.
sub PosArray
{
	my $corpus = "";
	open(SRC, $_[0]) || die;
	while(<SRC>) 
	{ 
		chomp;
		$corpus = "$_"; 
	}
	close (SRC);
	my @array = split(/\s+/, $corpus);
	my @returnArray = ();
	foreach $element(@array)
	{
		if($element !~ /[\[\]]/)
		{
			$element =~ s/\s+//g;
			$element =~ s/^(\w+)/$1/e;
			$element =~ s/\\\//SLASH/g;
			push(@returnArray, split(/\//, $element));
			$returnArray[$#returnArray] =~ s/SLASH/\\\//;
		}
	}
	return @returnArray;
}