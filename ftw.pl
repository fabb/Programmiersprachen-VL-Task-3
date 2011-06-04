#!/usr/bin/env perl

# (F)ind (T)he (W)orkflow
# Bernhard Urban and Fabian Ehrentraud, 2011

use strict;
use warnings;
use feature ":5.10"; # for given/when and %+
use Data::Dumper;

my $DEBUG = 0;

my $input = "!e !e !x echo bla !c !x echo blu !c !x echo bli ";
my $input4 = "{ ;; !b muster[x] !x echo bla [[x]] ; {{{ !x echo bli }}} ;; !x echo bla } ";
my $input3 = "!b muster[x] !x echo bla [[x]] ";
my $input_fail2 = "!b muster[x] !x echo [[x]]";
my $input2 = "{ !x command_xy lol[x] rofl[[x]] ; }";
# testcases for execute
my $input5 = "!e !e !x false !c !x false !c !x echo bli ";
my $input6 = "!b tst/pat[xxx]-[zzz] !b tst/foo[yyy] !e !e !x false !c !x echo asdf muh [[yyy]][[xxx]] b1 b2 b3 [[zzz]] b4 !c !x echo bli ";
my $input7 = "!b tst/[xxx]-[yyy] !x echo wtf bla[[xxx]] ";
my $input8 = "{!x echo abc ; !x echo 123 }";
my $input9 = "!l !b tst/rofl[x] !x echo ups [[x]] ";


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
		if (/\G\#[ \t\S]*\n\s*/gc) {
			print "comment\n" if $DEBUG;
		} elsif (/\G!x\s+/gc) {
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
		} elsif (/\G(([\[\\\;\-\w\/\.])+)\s+/gc) {
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
		} elsif (/\G(([\w\-_\/\.]|\[\w+\])+)\s+/gc) { # only a pattern in a batch, thus after ref matching above
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
					print "error: argument of wrong type: ", $arg->{'tokentype'}, "\n"; #TODO more information
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
			$prog{'action'} = \@actions;
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
		default {
			print "error: unexpected token \"$curtok\"\n"; #TODO more information on content of @token
			exit 1;
		}
	}
	
	return \%prog;
}

# executes the given program hash
# ret: 1 "success", -1 "cmd failed", x > 0 "amount of executed prim actions"
sub execute {
	my ($ast, $wcards) = @_;

	print "====== EXEC ======\n" if $DEBUG;
	print "wcards: ", Dumper($wcards) if $DEBUG;
	my $atype = $ast->{'actiontype'};
	my $action = $ast->{'action'};
	print "atype: ", $atype, "\n" if $DEBUG;

	given ($atype) {
		when ("prim") {
			print "== prim  ==\n" if $DEBUG;
			my $command = $ast->{'command'};
			print "command: ", $command, "\n" if $DEBUG;
			print "args-dump: ", Dumper($ast->{'args'}) if $DEBUG;

			my @localargs = ();
			my $args = $ast->{'args'};
			foreach my $arg (@{$args}) {
				if (@{$arg->{'wildcards'}}) { # array not empty
					$_ = $arg->{'argcontent'};
					foreach my $wc (@{$arg->{'wildcards'}}) {
						my $twc = $wc;
						$twc =~ s/[\[\]]//g;
						s/\[\[$twc\]\]/$wcards->{$wc}/g;
					}
				} else {
					$_ = $arg->{'argcontent'};
				}
				push @localargs, $_;
			}

			unshift @localargs, $command;
			print "localargs: ", (join " ", @localargs), "\n" if $DEBUG;
			system(@localargs);
			return -1 if $? != 0;
			return 1;
		}
		when ("batch") {
			print "== batch ==\n" if $DEBUG;
			my $pattern = $ast->{'pattern'};
			my %wcardsnew = %{$wcards};

			my $filepath = $pattern->{'string'};
			$filepath =~ s/\[\w+\]/\*/g;

			my @files = split('\n',`ls $filepath 2> /dev/null`);
			if ($? != 0) { # pattern doesn't match (anymore)
				return 0;
			}

			$filepath = $pattern->{'string'};
			my @twildcards = @{$pattern->{'wildcards'}};

			# replace wildcards with regex magic (named capturing)
			foreach my $wc (@twildcards) {
				my $wco = $wc;
				$wc =~ s/\[/\(\?</g;
				$wc =~ s/\]/>\[\\w\\\.\]\+\)/g;
				$wco =~ s/\[/\\\[/g;
				$wco =~ s/\]/\\\]/g;
				$filepath =~ s/$wco/$wc/g;
			}
			print "filepath: ", $filepath, "\n" if $DEBUG;

			# extract each match for wildcard and store it for later use
			my %localwcards = ();
			foreach my $file (@files) {
				if ($file =~ m/$filepath/) {
					my %phash = %-;
					@twildcards = @{$pattern->{'wildcards'}};
					foreach my $t (@twildcards) {
						my $tt = $t;
						# remove '[' and ']' for hash access of the named
						# capture hash
						$t =~ s/(\[|\])//g; 
						my @x = $phash{$t};
						if ($x[0][0]) { # does it exists?
							if (!$localwcards{$tt}) { # empty?
								$localwcards{$tt} = [];
							}
							push @{$localwcards{$tt}}, $x[0][0];
						}
					}
				}
				print "file: ", $file, "\n" if $DEBUG;
			}

			# tricky part: suppose you have 'echo abc t[[xx]] o[[yy]][[zz]]'
			# and you have xx = {a,b,c}, yy = {1,2}, zz = {i,j} then you get
			# |xx| * |yy| * |zz| = 3 * 2 * 2 = 12 calls, i.e.
			# > echo abc ta o1i
			# > echo abc ta o1j
			# > echo abc ta o2i
			# > echo abc ta o2j
			# > echo abc tb o1i
			# ... and so forth
			my @crossproduct = ();
			push @crossproduct, \%wcardsnew;
			@twildcards = @{$pattern->{'wildcards'}};
			foreach my $t (@twildcards) {
				my @tcp = ();
				my @lwcards = @{$localwcards{$t}};
				foreach my $entry (@crossproduct) {
					foreach my $wc (@lwcards) {
						my %newentry = %{$entry};
						$newentry{$t} = $wc;
						push @tcp, \%newentry;
					}
				}
				@crossproduct = @tcp;
			}

			print "crossproduct: ", Dumper(@crossproduct) if $DEBUG;

			foreach my $href (@crossproduct) {
				my $ret = execute($ast->{'action'}, $href);
				return -1 if $ret == -1;
			}
			return 1;
		}
		when ("seq") {
			print "== seq   ==\n" if $DEBUG;
			#my $actions = $ast->{'action'};
			my $allret = 0;
			foreach my $cmdcall (@{$action}) {
				my $ret = execute($cmdcall, $wcards);
				return -1 if $ret == -1;
				$allret += $ret;
			}
			return $allret;
		}
		when ("loop") {
			while (1) {
				my %wcardsold = %{$wcards};
				my $ret = execute($action, \%wcardsold);
				print "loopret: ", $ret, "\n" if $DEBUG;
				return 1 if $ret == 0;
				return -1 if $ret == -1;
			}
		}
		when ("error") {
			print "== error ==\n" if $DEBUG;
			my $catch = $ast->{'catch'};
			my $ret = execute($action, $wcards);
			return $ret if $ret != -1;
			return execute($catch, $wcards);
		}
		when (undef) {
			print "error: unexpected token\n"; #TODO: does this ever happen?
			exit 1;
		}
		default {
			print "error: $atype (maybe not implemented yet)\n"; #TODO: provide more information
			# exit 1;
		}
	}
	print "TODO: should never happen?\n";
	return 0;
}

# MAIN

# read input (file or stdin)
$_ = shift;
my @lines;
if ($_) {
	open(my $in, "<", $_) or die "can't open $_: $!";
	@lines = <$in>;
	close($in);
} else {
	@lines = <STDIN>;
}

# lex input
my $token = scan(join("", @lines));


# test print output
print "\ntoken:\n\n" if $DEBUG;
print Dumper($token) if $DEBUG;


# parse token array - eats up $token
my $prog = parse($token,[]);


# test print output
print "\nprog ref:\n\n" if $DEBUG;
print Dumper($prog) if $DEBUG;

my %dummy = ();
exit -1 if execute($prog, \%dummy) == -1;

exit 0;
