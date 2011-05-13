#!/usr/bin/env perl

# (F)ind (T)he (W)orkflow
# Bernhard Urban and Fabian Ehrentraud, 2011

use strict;
use warnings;
use feature ":5.10"; # for given/when


my $input_fail = "{ } !x echo lol rofl
!b !l !e !c /home/stuff/[img]_[date].jpg ;
!x echo [[foo]].jpg asdf bla[x][y][[z]] as!df !x echo foo
";
#$_ = "!x !fail echo haha}";

my $input = "!b muster[x] !x echo bla ";
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
		} elsif (/\G(([\w\/\.]|\[\[\w+\]\])+)\s+/gc) {
			#TODO " ' and `
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


# puts *all* token from @token as concatenated string into comargs, if a wrong token is found, error out
sub makecomargs{
	#TODO
	#TODO check wildcard pattern variable names for correct use
	#only eats tokentype => "ref", nothing should be left in the end (error if there is)
	#checking for wildcard pattern usage is still an issue
	return "xxx"
}

# separates *all* token from @token into tokenarrays by ";" (taking care of "units" enclosed in {})
# ';' are no more contained afterwards
sub makeactions{
	#TODO
	#needs to call parse() for each found action
	return ()
}

# puts *all* token from @pattern as concatenated string into pattern->string and the found wildcards into pattern->wildcards, if a wrong token is found, error out
sub makepattern{
	#TODO
	# this function can also be omitted, as scan() already stores the pattern array
	#pattern   =>  {
	#		        string  =>  "deleteme[[mywild]]",
	#		        wildcards  =>  ("mywild"),
	#              },
	return {}
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
	
	given((shift @$token) -> {'tokentype'}) {
		when ("prim") {
			$prog{'actiontype'} = "prim";
			$prog{'comargs'} = makecomargs($token,$wvars); # puts *all* token from @token as concatenated string into comargs, if a wrong token is found, error out
			#TODO check wildcard pattern variable names for correct use
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
			if(($pattern -> {'tokentype'} ne "pattern") && ($pattern -> {'tokentype'} ne "ref")){ #TODO change scan()
				print "error: not a pattern";
				exit 1;
			}
			
			print "batch\n";
			#{tokentype => "pattern", content => $id, patterns => \@patterns}
			for my $v ($pattern -> {'patterns'}){
				#TODO add new wildcards and check if none of the existing are reused
				print "$v\n";
			}
			
			$prog{'pattern'} = makepattern($pattern); # puts *all* token from @pattern as concatenated string into pattern->string and the found wildcards into pattern->wildcards, if a wrong token is found, error out
			my @wvarsnew = @$wvars; #copy wvars
			$prog{'action'} = parse($token,\@wvarsnew);
			#TODO store wildcard pattern variables and check their correct use
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
			print "error"; #TODO more information on content of @token
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



# parse token array - eats up $token
my $prog = parse($token,[]);


# test print output (yet nonrecursive)
print "prog ref: $prog\n";
for my $key (keys %{$prog}) {
	print "$key => ${$prog}{$key}\n";
}

