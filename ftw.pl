#!/usr/bin/env perl

# (F)ind (T)he (W)orkflow
# Bernhard Urban and Fabian Ehrentraud, 2011

use strict;
use warnings;


my $input_fail = "{ } !x echo lol rofl
!b !l !e !c /home/stuff/[img]_[date].jpg ;
!x echo [[foo]].jpg asdf bla[x][y][[z]] as!df !x echo foo
";
#$_ = "!x !fail echo haha}";

my $input = "{ !x command_xy lol[x] rofl[[x]] ; }";


# lexes the input and produces an array with lexemes stored in a hash
sub scan {
	
	my $_ = shift; # take input
	my @token;

	print "scannning \"$_\":\n\n";
	my $validlex = 1;
	my $lastpos = 0;

	# http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators
	# subsection "\G assertion"
	while ($validlex) {
		if (/\G!x\s+/gc) {
			print "prim\n";
			push @token, {tokentype => "prim"};
		} elsif (/\G!b\s+/gc) {
			print "batch\n";
			push @token, {tokentype => "batch"};
		} elsif (/\G!l\s+/gc) {
			print "loop\n";
			push @token, {tokentype => "loop"};
		} elsif (/\G!e\s+/gc) {
			print "exception\n";
			push @token, {tokentype => "exception"};
		} elsif (/\G!c\s+/gc) {
			print "catch\n";
			push @token, {tokentype => "catch"};
		} elsif (/\G{\s*/gc) {
			print "seq_start\n";
			push @token, {tokentype => "seq_start"};
		} elsif (/\G}\s*/gc) {
			print "seq_end\n";
			push @token, {tokentype => "seq_end"};
		} elsif (/\G;\s*/gc) {
			print "delim\n";
			push @token, {tokentype => "delim"};
		} elsif (/\G(([\w\/\.]|\[\[\w+\]\])+)\s+/gc) {
			my $id = $1;
			print "ref: $id\n";

			my @patterns = ();
			while ($id =~ /\[\[(\w+)\]\]/g) {
				push @patterns, $1;
			}
			if (@patterns > 0) {
				print "\twith ref-pattern: @patterns\n";
			}
			push @token, {tokentype => "ref", content => $id, patterns => \@patterns};
		} elsif (/\G(([\w\/\.]|\[\w+\])+)\s+/gc) { # only a pattern in a batch, thus after ref matching above
			my $id = $1;
			my $idmod = $id; # actually the replacing is not interesting until execution as the name of the patterns is still needed until then
			$idmod =~ s/\[\w+\]/\*/g;
			print "pattern: $idmod\n";

			my @patterns = ();
			while ($id =~ /(\[\w+\])/g) {
				push @patterns, $1;
			}
			if (@patterns > 0) {
				print "\twith pattern: @patterns\n";
			}
			push @token, {tokentype => "pattern", content => $id, patterns => \@patterns};
		} elsif (/\G\s*$/gc) {
			print "all done.\n";
			$validlex = 0;
		} else {
			print "syntax error: \"", substr($_, $lastpos), "\"\n";
			exit 1;
		}
		$lastpos = pos $_;
	}
	return \@token;
}


#TODO read real input


# lex input
my $token = scan($input);


# test print output
print "\ntoken:\n\n";
for my $tok (@{$token}) {
	for my $key (keys %{$tok}) {
		if(ref(${$tok}{$key}) eq 'ARRAY'){
			print "\t$key => ARRAY: ";
			for my $arrit (@{${$tok}{$key}}){
				print "$arrit, ";
			}
			print "\n";
		}else{
			print "\t$key => ${$tok}{$key}\n";
		}
	}
	print "\n";
}
