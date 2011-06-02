#!/usr/bin/env perl

# (F)ind (T)he (W)orkflow
# Bernhard Urban and Fabian Ehrentraud, 2011

use strict;
use warnings;
use feature ":5.10"; # for given/when
use Data::Dumper;

my $DEBUG = 1;

my $input_fail = "{ } !x echo lol rofl
!b !l !e !c /home/stuff/[img]_[date].jpg ;
!x echo [[foo]].jpg asdf bla[x][y][[z]] as!df !x echo foo
";
#$_ = "!x !fail echo haha}";

my $input = "!e !e !x echo bla !c !x echo blu !c !x echo bli ";
my $input4 = "{ ;; !b muster[x] !x echo bla [[x]] ; {{{ !x echo bli }}} ;; !x echo bla } ";
my $input3 = "!b muster[x] !x echo bla [[x]] ";
my $input_fail2 = "!b muster[x] !x echo [[x]]";
my $input2 = "{ !x command_xy lol[x] rofl[[x]] ; }";


# lexes the input and produces an array with lexemes stored in a hash
#FIXME input needs space at the end
sub scan {
	my $_ = shift; # take input
	my @token;

	print "scannning \"$_\":\n\n" if $DEBUG;
	my $validlex = 1;
	my $lastpos = 0;

	# http://perldoc.perl.org/perlop.html#Regexp-Quote-Like-Operators
	# subsection "\G assertion"
	while ($validlex) {
		if (/\G!x\s+/gc) {
			print "prim\n" if $DEBUG;
			push @token, {tokentype => "prim"};
		} elsif (/\G!b\s+/gc) {
			print "batch\n" if $DEBUG;
			push @token, {tokentype => "batch"};
		} elsif (/\G!l\s+/gc) {
			print "loop\n" if $DEBUG;
			push @token, {tokentype => "loop"};
		} elsif (/\G!e\s+/gc) {
			print "exception\n" if $DEBUG;
			push @token, {tokentype => "exception"};
		} elsif (/\G!c\s+/gc) {
			print "catch\n" if $DEBUG;
			push @token, {tokentype => "catch"};
		} elsif (/\G{\s*/gc) {
			print "seq_start\n" if $DEBUG;
			push @token, {tokentype => "seq_start"};
		} elsif (/\G}\s*/gc) {
			print "seq_end\n" if $DEBUG;
			push @token, {tokentype => "seq_end"};
		} elsif (/\G;\s*/gc) {
			print "delim\n" if $DEBUG;
			push @token, {tokentype => "delim"};
		} elsif (/\G(([\w\/\.])+)\s+/gc) {
			#TODO " ' and `
			my $id = $1;
			print "id: $id\n" if $DEBUG;
			push @token, {tokentype => "id", content => $id};
		} elsif (/\G(([\w\/\.]|\[\[\w+\]\])+)\s+/gc) {
			#TODO " ' and `
			my $id = $1;
			print "ref: $id\n" if $DEBUG;

			my @patterns = ();
			while ($id =~ /\[(\[\w+\])\]/g) {
				push @patterns, $1;
			}
			if (@patterns > 0) {
				print "\twith ref-pattern: @patterns\n" if $DEBUG;
			}
			push @token, {tokentype => "ref", content => $id, patterns => \@patterns};
		} elsif (/\G(([\w\/\.]|\[\w+\])+)\s+/gc) { # only a pattern in a batch, thus after ref matching above
			#TODO " ' and `
			my $id = $1;
			my $idmod = $id; # actually the replacing is not interesting until execution as the name of the patterns is still needed until then
			$idmod =~ s/\[\w+\]/\*/g;
			print "pattern: $idmod\n" if $DEBUG;

			my @patterns = ();
			while ($id =~ /(\[\w+\])/g) {
				push @patterns, $1;
			}
			if (@patterns > 0) {
				print "\twith pattern: @patterns\n" if $DEBUG;
			}
			push @token, {tokentype => "pattern", content => $id, patterns => \@patterns};
		} elsif (/\G\s*$/gc) {
			print "all done.\n" if $DEBUG;
			$validlex = 0;
		} else {
			print "syntax error: \"", substr($_, $lastpos), "\"\n";
			exit 1;
		}
		$lastpos = pos $_;
	}
	return \@token;
}


# parses the given token list and produces a hash with the executable program structure
sub parse{
    my ($token,$wvars) = @_;
	my %prog;
	
	if (@$token == 0){
		print "error: missing a token\n";
		exit 1;
	}
	
	my $curtok = (shift @$token) -> {'tokentype'};
	
	given ($curtok) {
		when ("prim") {
			$prog{'actiontype'} = "prim";
			if (@$token == 0){
				print "error: missing command name\n";
				exit 1;
			}
			
			my $commandtok = shift @$token;
			
			if ($commandtok -> {'tokentype'} ne "id") {
				print "error: command name of wrong type\n"; #TODO more information
				exit 1;
			}
			
			$prog{'command'} = $commandtok -> {'content'};
			
			my @args;
			for my $arg (@$token) {
				if ($arg -> {'tokentype'} eq "id") {
					push @args, {argcontent => ($arg -> {'content'}), wildcards => []};
				}
				elsif ($arg -> {'tokentype'} eq "ref") {
					my @vars;
					for my $v (@{$arg -> {'patterns'}}) {
						if((grep {$_ eq $v;} @$wvars) == 0) {
							print "error: in argument used wildcard variable $v was never defined in a batch pattern\n";
							exit 1;
						}
						push @vars, $v
					}
					push @args, {argcontent => ($arg -> {'content'}), wildcards => \@vars};
				}
				else {
					print "error: argument of wrong type\n"; #TODO more information
					exit 1;
				}
			}
			$prog{'args'} = \@args;
		}
		when ("seq_start") {
			if ((pop @$token) -> {'tokentype'} ne "seq_end") { # also catches token which has not got any tokentype key
				print "error: matching } missing\n";
				exit 1;
			}
			$prog{'actiontype'} = "seq";
			
			# separates all token from @token into tokenarrays by ";" (taking care of "units" enclosed in {}), ';' are no more contained afterwards
			my @actiontokens;
			while (@$token > 0) {
				my $seqdepth = 0;
				my @atok;
				
				while (@$token > 0 && (($$token[0] -> {'tokentype'}) eq "delim")) { # eat unnecessary ; tokens
					shift @$token;
				}
				
				while (@$token > 0) {
					my $curtok = shift @$token;
					
					if (($curtok -> {'tokentype'}) eq "seq_start") {
						$seqdepth = $seqdepth + 1;
					}
					elsif (($curtok -> {'tokentype'}) eq "seq_end") {
						$seqdepth = $seqdepth - 1;
						if ($seqdepth < 0) {
							print "error: too many closing curly braces }\n"; #TODO more information
							exit 1;
						}
					}
					
					if ($seqdepth == 0 && ($curtok -> {'tokentype'}) eq "delim") {
						last; # same as break
					}
					else { # token still belongs to current action
						push @atok, $curtok;
					}
				}
				
				while (@$token > 0 && (($$token[0] -> {'tokentype'}) eq "delim")) { # eat unnecessary ; tokens
					shift @$token;
				}
				
				if (@$token == 0 && $seqdepth > 0) {
					print "error: too many opening curly braces }\n"; #TODO more information
					exit 1;
				}
				
				push @actiontokens, \@atok;
			}
			
			# test print output
			# print "\nactions:\n\n";
			# print Dumper(\@actiontokens), "\n";
			
			my @actions;
			for my $actiontoken (@actiontokens) {
				push @actions, parse($actiontoken,$wvars);
			}
			$prog{'actions'} = \@actions;
		}
		when ("batch") {
			$prog{'actiontype'} = "batch";
			my $pattern = shift @$token;
			
			if ($pattern -> {'tokentype'} eq "pattern") {
				my @wvarsnew = @$wvars; #copy wvars
				my @w;
				for my $v (@{$pattern -> {'patterns'}}) {
					# check if wildcard variable name is already used
					if ((grep {$_ eq $v;} @wvarsnew) > 0) {
						print "error: wildcard variable $v was already used before in a batch pattern\n";
						exit 1;
					}
					push @wvarsnew, $v;
					push @w, $v;
				}
				
				$prog{'pattern'}{'string'} = $pattern -> {'content'};
				$prog{'pattern'}{'wildcards'} = \@w;
				$prog{'action'} = parse($token,\@wvarsnew);
			}
			elsif ($pattern -> {'tokentype'} eq "id") { # no new wildcard variables
				$prog{'pattern'}{'string'} = $pattern -> {'content'};
				$prog{'pattern'}{'wildcards'} = [];
				$prog{'action'} = parse($token,$wvars);
			}
			else {
				print "error: not a pattern\n";
				exit 1;
			}
		}
		when ("loop") {
			$prog{'actiontype'} = "loop";
			$prog{'action'} = parse($token,$wvars);
		}
		when ("exception") {
			$prog{'actiontype'} = "error";
			
			if (@$token == 0){
				print "error: unexpected end of input\n"; #TODO more information
				exit 1;
			}			
			
			# collect all token that belong to action part of error action
			my @action;
			my $errdepth = 1; # !e token was already eaten, but not the matching !c token
						
			while (@$token > 0) {
				my $curtok = shift @$token;
				
				if (($curtok -> {'tokentype'}) eq "exception") {
					$errdepth = $errdepth + 1;
				}
				elsif (($curtok -> {'tokentype'}) eq "catch") {
					$errdepth = $errdepth - 1;
					if ($errdepth < 0) {
						print "error: too many !c commands\n"; #TODO more information
						exit 1;
					}
				}
				
				if ($errdepth == 0 && ($curtok -> {'tokentype'}) eq "catch") {
					last; # same as break
				}
				else { # token still belongs to action part
					push @action, $curtok;
				}
			}
			
			if (@$token == 0 && $errdepth > 0) {
				print "error: too many opening !e commands\n"; #TODO more information
				exit 1;
			}
			
			$prog{'action'} = parse(\@action,$wvars);
			
			$prog{'catch'} = parse($token,$wvars);
		}
		when (undef) {
			print "error: unexpected token\n"; #TODO more information on content of @token
			exit 1;
		}
		default {
			print "error: $curtok\n"; #TODO more information on content of @token
			exit 1;
		}
	}
	
	return \%prog;
}


# executes the given program hash
sub exec{
	#my ($token,$wvars) = @_;
	print @_;
}


#TODO read real input


# lex input
my $token = scan($input);


# test print output
print "\ntoken:\n\n" if $DEBUG;
print Dumper($token) if $DEBUG;


# parse token array - eats up $token
my $prog = parse($token,[]);


# test print output
print "\nprog ref:\n\n" if $DEBUG;
print Dumper($prog) if $DEBUG;

print "w00t\n" if $DEBUG;
