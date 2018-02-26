# Curtis Donelson, CMSC 416, Spring 2017, PA #3
# This program is part 2 of a 2-part, part-of-speech tagger.  It accepts as input two text files,
# already tagged, and calculates the accuracy between them.  The first file is one tagged using
# part 1 of this project - tagger.pl.  This is the program-generated tagged text.  The second input
# is a "key" text file and is the gold standard for comparison.
# The algorithm first creates a hash of the mismatches between tags in the test file and the key file.
# Accuracy is calculated from this hash.  The program then generates a hash of relative error frequencies 
# and displays it in a confusion matrix.
#
# Sample input showing a sentence from each of the input files.
# Testing file: "No/DT ,/, it/PRP was/VBD n't/RB Black/NNP Monday/NNP ./. 
# But/CC while/IN the/DT New/NNP York/NNP Stock/NNP Exchange/NNP did/VBD n't/RB fall/NN apart/NN Friday/NNP as/IN 
# the/DT Dow/NNP Jones/NNP Industrial/NNP Average/NNP plunged/VBD 190.58/CD points/NNS --/: most/JJS of/IN it/PRP 
# in/IN the/DT final/JJ hour/NN --/: it/PRP barely/RB managed/VBN to/TO stay/VB this/DT side/NN of/IN chaos/NNS ./. 
#
# Key text file: No/RB ,/, it/PRP was/VBD n't/RB Black/NNP Monday/NNP ./. 
# But/CC while/IN the/DT New/NNP York/NNP Stock/NNP Exchange/NNP did/VBD n't/RB fall/VB apart/RB Friday/NNP as/IN 
# the/DT Dow/NNP Jones/NNP Industrial/NNP Average/NNP plunged/VBD 190.58/CD points/NNS --/: most/JJS of/IN it/PRP 
# in/IN the/DT final/JJ hour/NN --/: it/PRP barely/RB managed/VBD to/TO stay/VB this/DT side/NN of/IN chaos/NN ./.
#



#!/usr/local/bin/perl
use warnings;

# Variable declarations
my $writeData = $ARGV[0];
my $keyData = $ARGV[1];
my @writeArray = ();
my @keyArray = ();
my @tempArray = ();
my %tempHash = ();
my %tagHash = ();
my $tempErrorTotal = 0;
my $tempAcc = 0;
my $printAcc = 0;
my $printString = "";
my $corpus = "";
local $/;

# Build the two arrays to contain the testing data (words/POS) and the key data (words/POS)
@writeArray = PosArray($writeData);
@keyArray = PosArray($keyData);

%tempHash = BuildMistagHash(\@writeArray, \@keyArray);  # Creates a hash showing mismatches between the arrays
$tempErrorTotal = CalcErrorTotal(%tempHash);   # Calculate total number of mismatches
$tempAcc = CalcAcc($tempErrorTotal, $#writeArray/2);   # Calculate accuracy of test data
%tempHash = BuildFreqHash(%tempHash);   # Builds a hash containing relative frequencies of word-POS
$printAcc = sprintf("%.2f%%", $tempAcc);
$printString = "Tagger program accuracy: ";
%tagHash = BuildTagHash(%tempHash);       # Builds a hash containing one copy of each tag (mostly for formatting)
PrintHash(\%tagHash,\%tempHash, $printString, $printAcc);


# Function creates a one-dimensional hash from the first "layer" of keys in a multidimensional hash.  Lets the program know what individual tags are used
sub BuildTagHash
{
	my %holdHash = @_;
	my %returnHash = ();
	foreach $tag (keys %holdHash)
	{ $returnHash{$tag}++ }
	return %returnHash;
}
		

# Function takes in 2 arrays (one tagged by model and one tagged by a "key") containing words (index i) and their tags (index i+1),
#  then returns a hash of the mismatches in tags.
sub BuildMistagHash
{
	my ($inArray1, $inArray2) = @_;
	my @writeArray = @$inArray1;
	my @keyArray = @$inArray2;
	my %mistagHash = ();
	my $mistagTotal = 0;
	for(my $j = 0; $j <= $#writeArray; $j = $j+2)
	{
		if($writeArray[$j+1] ne $keyArray[$j+1])
		{
			my $writeTag = $writeArray[$j+1];
			my $keyTag = $keyArray[$j+1];
			$mistagHash{$writeTag}{$keyTag}++;
			$mistagTotal++;
		}
	}
	return %mistagHash;
}

# Function accepts a hash containing total tag mismatches,then constructs and returns a relative frequency of errors hash.
sub BuildFreqHash
{
	my %tagHash = @_;
	my %returnHash = ();
	foreach my $writeTag (keys %tagHash)
	{
		my $keyTotal = 0;
		foreach my $keyTag (keys $tagHash{$writeTag})
		{ $keyTotal += $tagHash{$writeTag}{$keyTag}; }
		foreach my $keyTag (keys $tagHash{$writeTag})
		{ $returnHash{$writeTag}{$keyTag} = $tagHash{$writeTag}{$keyTag}/$keyTotal; }
	}

	return  %returnHash;
}
	
# Function takes in a error frequency hash and returns the total number of errors it contains
sub CalcErrorTotal
{
	my %tagHash = @_;
	my $tagErrors = 0;
	my $errorTotal = 0;
	foreach my $writeTag (keys %tagHash)
	{
		foreach my $keyTag (keys $tagHash{$writeTag})
		{ $errorTotal = $errorTotal + $tagHash{$writeTag}{$keyTag}; }
	}
	return $errorTotal;
}

# Function to calculate accuracy of tagger.  Takes as input the total number of tag mismatches and the total number of tagged words.
sub CalcAcc
{
	my $errorTotal = $_[0];
	my $wordTotal = $_[1];
	return 100 * (1-$errorTotal/$wordTotal);
}

# Function that format prints two hashes: %tagNames is a one-dimensional hash containing names of PoS for rows/columns.
# %tagFreqHash is a two-dimensional hash containing the frequencies to be printed, with the first hash being the model-selected tag,
# and the second hash being the key-selected tag.  It returns nothing.
sub PrintHash
{
	my ($tagNamesRef, $tagFreqRef, $printStringRef, $printAccRef) = @_;
	my %tagNames = %{$tagNamesRef};
	my %tagFreqHash = %{$tagFreqRef};
	my $printAcc = $printStringRef;
	my $accuracy = $printAccRef;	
	print "     ";
	foreach my $firstTag (keys %tagNames)
	{ 
		$firstTag =~ s/\s+//g;
		if($firstTag =~ m/\b\w{2}\b/)
		{	print $firstTag."    "; }
		elsif($firstTag =~ m/\$/ || $firstTag =~m/\w{4}/)
		{ print $firstTag."  "; }
		else
		{ print $firstTag."   "; }
	}
	print "\n";
	print "----";
	foreach my $firstTag (keys %tagNames)
	{ print "------";}
	print "\n";
	foreach my $firstTag (keys %tagNames)
	{
		if($firstTag =~ m/\b\w{2}\b/)
		{ print $firstTag."  |"; }
		elsif($firstTag =~ m/\$/ || $firstTag =~ m/\w{4}/)
		{ print $firstTag."|"; }
		else
		{ print $firstTag." |"; }
		foreach my $secondTag (keys %tagNames)
		{ 
			if(exists $tagFreqHash{$firstTag}{$secondTag})
			{ printf("%.3f|", $tagFreqHash{$firstTag}{$secondTag}); }
			else
			{ print "     |"; }
		}
		print "\n";
	}
	print $printAcc." ".$accuracy."\n";
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
