#!/usr/bin/env perl

# (F)ind (T)he (W)orkflow
# Bernhard Urban and Fabian Ehrentraud, 2011

use strict;
use warnings;


my $input = "{ } !x echo lol rofl
!b !l !e !c /home/stuff/[img]_[date].jpg ;
!x echo [[foo]].jpg asdf as!df !x echo foo
";
#$_ = "!x !fail echo haha}";

#TODO return array with lexem-constants
sub scan {
	
	my $_ = shift;

	print "scannning \"$_\":\n\n";
	my $validlex = 1;
	my $lastpos = 0;

	# http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators
	# subsection "\G assertion"
	while ($validlex) {
		if (/\G!x\s+/gc) {
			print "prim\n";
		} elsif (/\G!b\s+/gc) {
			print "batch\n";
		} elsif (/\G!l\s+/gc) {
			print "loop\n";
		} elsif (/\G!e\s+/gc) {
			print "exception\n";
		} elsif (/\G!c\s+/gc) {
			print "catch\n";
		} elsif (/\G{\s*/gc) {
			print "seq_start\n";
		} elsif (/\G}\s*/gc) {
			print "seq_end\n";
		} elsif (/\G;\s*/gc) {
			print "delim\n";
		} elsif (/\G(([\w\/\.]|\[\w+\])+)\s+/gc) {
			my $id = $1;
			my $idmod = $id;
			$idmod =~ s/\[\w+\]/\*/g;
			print "id: $idmod\n";

			my @patterns = ();
			while ($id =~ /(\[\w+\])/g) {
				push @patterns, $1;
			}
			if (@patterns > 0) {
				print "\twith pattern: @patterns\n";
			}
		} elsif (/\G(([\w\/\.]|\[\[\w+\]\])+)\s+/gc) {
			my $id = $1;
			my $idmod = $id;
			print "ref: $id\n";

			my @patterns = ();
			while ($id =~ /\[\[(\w+)\]\]/g) {
				push @patterns, $1;
			}
			if (@patterns > 0) {
				print "\twith ref-pattern: @patterns\n";
			}
		} elsif (!/\G[^.\n]*/gc) {
			print "all done.\n";
			$validlex = 0;
		} else {
			print "syntax error: \"", substr($_, $lastpos, length($_) - $lastpos), "\"\n";
			exit 1;
		}
		$lastpos = pos $_;
	}

}

scan($input);
