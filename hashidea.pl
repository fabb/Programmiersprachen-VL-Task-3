
use strict;
use warnings;
use feature ":5.10"; # for given/when


my $prim = {
	actiontype  =>  "prim",
	comargs   =>  "rm [mywild]"
};

my $seq = {
	actiontype  =>  "seq",
	actions   =>  ($prim, $prim, $prim)
};

my $batch = {
	actiontype  =>  "batch",
	pattern   =>  {
			        string  =>  "deleteme[[mywild]]",
			        wildcards  =>  ("mywild"),
	              },
	action  =>  $seq
};

my $loop = {
	actiontype  =>  "loop",
	action   =>  $batch
};

my $error = {
	actiontype  =>  "error",
	action   =>  $loop,
	catch   =>  $batch
};




my $prog = {
	actiontype  =>  "error",
	action   =>  {
	                actiontype  =>  "loop",
                 	action   =>  {
									actiontype  =>  "batch",
									pattern   =>  {
													string  =>  "deleteme[[mywild]]",
													wildcards  =>  ("mywild"),
												  },
									action  =>  {
													actiontype  =>  "seq",
													actions   =>  (
																	 {
																		 actiontype  =>  "prim",
																		 comargs   =>  "rm [mywild]"
																	 },
																	 {
																		 actiontype  =>  "prim",
																		 comargs   =>  "rm [mywild]"
																	 },
																	 {
																		 actiontype  =>  "prim",
																		 comargs   =>  "rm [mywild]"
																	 }
																  )
												}
								}
                 },
	catch   =>  {
	                actiontype  =>  "batch",
	                pattern   =>  {
			                        string  =>  "deleteme[[mywild]]",
			                        wildcards  =>  ("mywild"),
	                              },
                	action  =>  {
	                                actiontype  =>  "seq",
	                                actions   =>  (
									                 {
										                 actiontype  =>  "prim",
										                 comargs   =>  "rm [mywild]"
									                 },
													 {
										                 actiontype  =>  "prim",
										                 comargs   =>  "rm [mywild]"
									                 },
													 {
										                 actiontype  =>  "prim",
										                 comargs   =>  "rm [mywild]"
									                 }
												  )
                                }
                }
};


sub makecomargs{
	return "xxx"
}

sub makeactions{
	return []
}

sub breakpattern{
	return [[],[]]
}

sub makepattern{
	return {}
}

sub breakcatch{
	return [[],[]]
}



sub parse{
    my @token = shift;
	
	my %prog;
	
	 given((shift @token) -> {'actiontype'}) {
		when ("prim") {
		                   $prog{'actiontype'} = "prim";
		                   $prog{'comargs'} = makecomargs(@token); # puts *all* token from @token as concatenated string into comargs, if a wrong token is found, error out
		              }
		when ("seq") {
		                   $prog{'actiontype'} = "seq";
						   # actually @
		                   $prog{'actions'} = makeactions(@token); # separates *all* token from @token into single actions by ";" (taking care of "units" enclosed in {}), and calls parse() for each such token group and thus produces an array of actions
		             }
		when ("batch") {
		                   $prog{'actiontype'} = "batch";
						   my @pattern_plus_rest = breakpattern(@token); # returns an array with two elements, first is filled with tokens that build a pattern, second is the unused rest of @token
						   my @pattern = $pattern_plus_rest[0];
						   @token = $pattern_plus_rest[1];
						   # actually %
		                   $prog{'pattern'} = makepattern(@pattern); # puts *all* token from @pattern as concatenated string into pattern->string and the found wildcards into pattern->wildcards, if a wrong token is found, error out
						   # actually %
		                   $prog{'action'} = parse(@token);
		               }
		when ("loop") {
		                   $prog{'actiontype'} = "loop";
						   # actually %
		                   $prog{'action'} = parse(@token);
		              }
		when ("error") {
		                   $prog{'actiontype'} = "error";
						   my @action_plus_rest = breakcatch(@token); # returns an array with two elements, first is filled with tokens that build an action, second is the unused rest of @token
						   my @action = $action_plus_rest[0];
						   @token = $action_plus_rest[1];
						   # actually %
		                   $prog{'action'} = parse(@action);
						   # actually %
		                   $prog{'catch'} = parse(@token);
		               }
		when (undef) { print "error";
				        exit 1;
				      }
		default { print "error";
				  exit 1;
				}
	}
	
	return \%prog;
}


my %primtoken = ( # this could be a current token in the token array
	tokentype  => 1, # must be given and bla
	actiontype  => "prim" # any additional keys giving details specific to the token type
);


my @tokentest = (\%primtoken);

my $progtest = parse(@tokentest);

print "progtest ref: $progtest\n";

for my $key (keys %{$progtest}) {
	print "$key => ${$progtest}{$key}\n";
}

