# Curtis Donelson, CMSC 416, Spring 2017, PA #5: Basic QA System
# This program is a very basic question-and-answer information retriveal system using
# only Wikipedia.   It accepts a query from the user in the form of a Who,What,Where, or When question,
# parses out the relevant bit, and queries wikipedia for a sequence containing it.  For some questions,
# such as Where and When, the data is first attempted to be pulled straight from the infobox.  Once a passage
# has been identified, it is reformulated into a full sentence and given as the answer.
# The user's query, the actual query sent to Wikipedia, the raw Wikipedia results, and the final answer are output
# to a log file.  The program does nothing in terms of lemmatization or match-ranking; it strictly looks for one 
# basic pattern.  This leaves the program at a barely useable state.  It will need much more work to make it robust.
#
# Command line input: perl qa-system.pl my-log-file.txt
#
# Sample query: Who is Batman?
# Sample Wikipedia query: 'Batman'
# Sample Solution: "Batman is a fictional superhero appearing in American comic books publishedby DC Comics."


#!/usr/local/bin/perl
use warnings;
use WWW::Wikipedia;

#Variable Declarations
my $fullQuery;
my $queryType;
my $queryToBe;
my $queryTemp;
my $queryFinal;
my $article = "";
my $answerFinal;
my $logFile = $ARGV[0];
open(DST, ">$logFile") || die;

print "\nThis system was written by Curtis Donelson and is designed to answer simple WH- questions.  Enter 'exit' to quit.\n";

# Get Original query
print "Enter your question: ";
$fullQuery = <STDIN>;

# Loop through the program until user enters "exit" or "Exit"
while($fullQuery !~ m/[Ee]xit/)
{
	print DST "User Query: $fullQuery.\n";
	chomp $fullQuery;   # Remove the new line character
	chop $fullQuery;    # Remove the question mark from the query
	$answerFinal = "";
	
	# Parses query into type, connecting article, and the subject to search
	if($fullQuery =~ m/(Who|What|Where|When) (is|was|are|were|did|does) (.+)/g)
	{ 
		$queryType = $1;
		$queryToBe = $2;
		$queryTemp = $3;
	}
	
	# Series of if-else statements based on question type and processes it for searching
	if($queryType eq "What")
	{	 
		if($queryTemp =~ m/(\ba\s+|\bthe\s+)/)
		{	 
			$article = $1;
			chop $article;
			$queryTemp =~ s/(\ba\s+|\bthe\s+)//g;
		}
		$queryFinal = ucfirst($queryTemp);

	}
	elsif($queryType eq "Who")
	{	$queryFinal = $queryTemp; }
	elsif($queryType eq "Where")
	{
		if($queryTemp =~ m/(\ba\s+|\bthe\s+)/)
		{ 
			$article = $1;
			chop $article;
			$queryTemp =~ s/(\ba\s+|\bthe\s+)//g;
		}
		$queryFinal = ucfirst($queryTemp);
	}
	elsif($queryType eq "When")
	{
		if($queryTemp =~ m/(\ba\s+|\bthe\s+)/)
		{ 
			$article = $1;
			chop $article;
			$queryTemp =~ s/(\ba\s+|\bthe\s+)//g;
		}
		$queryFinal = ucfirst($queryTemp);
	}
	
	# Query wikipedia and obtain result
	print DST "Search executed: $queryFinal\n";
	my $wiki = WWW::Wikipedia->new();
	$wiki ->clean_html(1);
	my $result = $wiki->search($queryFinal);
	
	# Second set of if-else statements that process the result based on question type.  It searches through
	# the result for a specific pattern or date/location data.  Then it builds the answer using
	# several regex capture groups.
	if($result && $queryType eq "Who") 
	{
		my $text = $result ->text();
		print DST "Raw Wikipedia Data:\n$text\n";
		$text =~ s/\(.*?\)\s//g;
		$text =~ s/,(?:.*?),//g;
		$text =~ s/\'//g;
		my $queryBoth = "$queryTemp $queryToBe";
		if ($text =~ m/(?:.*)($queryBoth)(.*)\n?(.*)\./)
		{  $answerFinal = $1.$2.$3."."; }
	}
	elsif($result && $queryType eq "What")
	{
		my $text = $result ->text();
		print DST "Raw Wikipedia Data:\n$text\n";
		$text =~ s/\(.*?\)\s//g;
		$text =~ s/\'//g;
#		$article = ucfirst($article);
		my $queryBoth = "$queryTemp";
		if ($text =~ m/(?:.*)($queryBoth),?(?:.*),?(\b$queryToBe\b)(.*)\n?(.*)/g)
		{  	$answerFinal = $1." ".$2.$3.$4."."; }
	}
	elsif($result && $queryType eq "Where")
	{
		my $text = $result ->text();
		print DST "Raw Wikipedia Data:\n$text\n";
		$text =~ s/\(.*(\n|\))//g;
		$text =~ s/\'//g;
		if ($text =~ m/(?:location =|location=|address =|address=)(.*)/)
		{ 	$answerFinal = "$queryTemp is located in $1\."; }
		elsif ($text =~ m/(?:.*)($queryTemp)(?:.*)(\b$queryToBe\b)(.*)(located|found|near|at|in)(.*)/g)
		{  	$answerFinal = $1.$2.$3.$4.$5; }
	}
	elsif($result && $queryType eq "When")
	{
		my $text = $result ->text();
		print DST "Raw Wikipedia Data:\n$text\n";
		if ($text =~ m/(?:date =|date=)\n?(.*)/)
		{ 	$answerFinal = "$queryTemp occurs on $1\."; }
	}
	if($answerFinal ne "")
	{ 
		print "\n$answerFinal\n"; 
		print DST "Answer generated: $answerFinal\n";
	}
	else
	{	print "Sorry, but I could not find an answer to your question.  Please try again.\n"; }
	print DST "\n\n------------  NEW QUERY -----------------\n\n";
	
	# Prompts user for another question (or 'exit' command), then repeats loop.
	print "Enter your question: ";
	$fullQuery = <STDIN>;
}