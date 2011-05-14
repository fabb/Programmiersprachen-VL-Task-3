#!/usr/bin/env perl

# (F)ind (T)he (W)orkflow
# Bernhard Urban and Fabian Ehrentraud, 2011

use strict;
use warnings;
use feature ":5.10"; # for given/when
use Data::Dumper;


my $input_fail = "{ } !x echo lol rofl
!b !l !e !c /home/stuff/[img]_[date].jpg ;
!x echo [[foo]].jpg asdf bla[x][y][[z]] as!df !x echo foo
";
#$_ = "!x !fail echo haha}";

my $input = "!b muster[x] !x echo bla [[x]] ";
my $input_fail2 = "!b muster[x] !x echo [[x]]";
my $input2 = "{ !x command_xy lol[x] rofl[[x]] ; }";


# lexes the input and produces an array with lexemes stored in a hash
#FIXME input needs space at the end
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
		} elsif (/\G(([\w\/\.])+)\s+/gc) {
			#TODO " ' and `
			my $id = $1;
			print "id: $id\n";
			push @token, {tokentype => "id", content => $id};
		} elsif (/\G(([\w\/\.]|\[\[\w+\]\])+)\s+/gc) {
			#TODO " ' and `
			my $id = $1;
			print "ref: $id\n";

			my @patterns = ();
			while ($id =~ /\[(\[\w+\])\]/g) {
				push @patterns, $1;
			}
			if (@patterns > 0) {
				print "\twith ref-pattern: @patterns\n";
			}
			push @token, {tokentype => "ref", content => $id, patterns => \@patterns};
		} elsif (/\G(([\w\/\.]|\[\w+\])+)\s+/gc) { # only a pattern in a batch, thus after ref matching above
			#TODO " ' and `
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


# separates *all* token from @token into tokenarrays by ";" (taking care of "units" enclosed in {})
# ';' are no more contained afterwards
sub makeactions{
	#TODO
	#needs to call parse() for each found action
	return ()
}

# returns an array with two elements, first is filled with tokens that build an action, second is the unused rest of @token
sub breakcatch{
	#TODO
	# watch out for the !c but take care of units in {}
	return ()
}


# parses the given token list and produces a hash with the executable program structure
sub parse{
    my $token = shift;
    my $wvars = shift;
	
	my %prog;
	
	if(@$token == 0){
		print "error: missing a token";
		exit 1;
	}
	
	my $curtok = (shift @$token) -> {'tokentype'};
	
	given($curtok) {
		when ("prim") {
			$prog{'actiontype'} = "prim";
			if(@$token == 0){
				print "error: missing command name";
				exit 1;
			}
			
			my $commandtok = shift @$token;
			
			if($commandtok -> {'tokentype'} ne "id"){
				print "error: command name of wrong type"; #TODO more information
				exit 1;
			}
			
			$prog{'command'} = $commandtok -> {'content'};
			
			my @args;
			for my $arg (@$token){
				if($arg -> {'tokentype'} eq "id"){
					push @args, {argcontent => ($arg -> {'content'}), wildcards => []};
				}
				elsif($arg -> {'tokentype'} eq "ref"){
					my @vars;
					for my $v (@{$arg -> {'patterns'}}){
						if((grep {$_ eq $v;} @$wvars) == 0){
							print "error: in argument used wildcard variable $v was never defined in a batch pattern";
							exit 1;
						}
						push @vars, $v
					}
					push @args, {argcontent => ($arg -> {'content'}), wildcards => \@vars};
				}
				else{
					print "error: argument of wrong type"; #TODO more information
					exit 1;
				}
			}
			$prog{'args'} = \@args;
		}
		when ("seq_start") {
			if((pop @$token) -> {'tokentype'} ne "seq_end"){ # also catches token which has not got any tokentype key
				print "error: matching } missing";
				exit 1;
			}
			$prog{'actiontype'} = "seq";
			my @actiontokens = makeactions($token); # separates *all* token from @token into tokenarrays by ";" (taking care of "units" enclosed in {})
			my @actions;
			for my $actiontoken (@actiontokens){
				push @actions, parse($actiontoken,$wvars);
			}
			$prog{'actions'} = @actions;
		}
		when ("batch") {
			$prog{'actiontype'} = "batch";
			my $pattern = shift @$token;
			
			if($pattern -> {'tokentype'} eq "pattern"){				
				my @wvarsnew = @$wvars; #copy wvars
				my @w;
				for my $v (@{$pattern -> {'patterns'}}){
					# check if wildcard variable name is already used
					if ((grep {$_ eq $v;} @wvarsnew) > 0) {
						print "error: wildcard variable $v was already used before in a batch pattern";
						exit 1;
					}
					push @wvarsnew, $v;
					push @w, $v;
				}
				
				$prog{'pattern'}{'string'} = $pattern -> {'content'};
				$prog{'pattern'}{'wildcards'} = \@w;
				$prog{'action'} = parse($token,\@wvarsnew);
			}
			elsif($pattern -> {'tokentype'} eq "id"){ # no new wildcard variables
				$prog{'pattern'}{'string'} = $pattern -> {'content'};
				$prog{'pattern'}{'wildcards'} = [];
				$prog{'action'} = parse($token,$wvars);
			}
			else{
				print "error: not a pattern";
				exit 1;
			}
		}
		when ("loop") {
			$prog{'actiontype'} = "loop";
			$prog{'action'} = parse($token,$wvars);
		}
		when ("exception") {
			$prog{'actiontype'} = "error";
			my @action = breakcatch($token); # TODO (desc) returns an array with two elements, first is filled with tokens that build an action, second is the unused rest of @token
			$prog{'action'} = parse(\@action,$wvars);
			$prog{'catch'} = parse($token,$wvars);
		}
		when (undef) {
			print "error: unexpected token"; #TODO more information on content of @token
			exit 1;
		}
		default {
			print "error: $curtok"; #TODO more information on content of @token
			exit 1;
		}
	}
	
	return \%prog;
}


# executes the given program hash
sub exec{
	#TODO
}


#TODO read real input


# lex input
my $token = scan($input);


# test print output
print "\ntoken:\n\n";
print Dumper($token);


# parse token array - eats up $token
my $prog = parse($token,[]);


# test print output
print "\nprog ref:\n\n";
print Dumper($prog);

