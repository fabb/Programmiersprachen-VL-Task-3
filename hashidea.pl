
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
	              };
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
												  };
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
																	 })
												}
								}
                 },
	catch   =>  {
	                actiontype  =>  "batch",
	                pattern   =>  {
			                        string  =>  "deleteme[[mywild]]",
			                        wildcards  =>  ("mywild"),
	                              };
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
									                 })
                                }
                }
};




sub parse{
    @token = shift;
	
	my %prog;
	
	given(unshift @token -> {'actiontype'}) {
		when ("prim") {
		                   %prog {'actiontype'} = "prim";
		                   %prog {'comargs'} = makecomargs(@token); # puts *all* token from @token as concatenated string into comargs, if a wrong token is found, error out
		              }
		when ("seq") {
		                   %prog {'actiontype'} = "seq";
		                   %prog {'actions'} = makeactions(@token); # separates *all* token from @token into single actions by ";" (taking care of "units" enclosed in {}), and calls parse() for each such token group and thus produces an array of actions
		             }
		when ("batch") {
		                   %prog {'actiontype'} = "batch";
						   my @pattern_plus_rest = breakpattern(@token); # returns an array with two elements, first is filled with tokens that build a pattern, second is the unused rest of @token
						   my @pattern = @pattern_plus_rest[0];
						   my @token = @pattern_plus_rest[1];
		                   %prog {'pattern'} = makepattern(@pattern); # puts *all* token from @pattern as concatenated string into pattern->string and the found wildcards into pattern->wildcards, if a wrong token is found, error out
		                   %prog {'action'} = parse(@token);
		               }
		when ("loop") {
		                   %prog {'actiontype'} = "loop";
		                   %prog {'action'} = parse(@token);
		              }
		when ("error") {
		                   %prog {'actiontype'} = "error";
						   my @action_plus_rest = breakcatch(@token); # returns an array with two elements, first is filled with tokens that build an action, second is the unused rest of @token
						   my @action = @action_plus_rest[0];
						   my @token = @action_plus_rest[1];
		                   %prog {'action'} = parse(@action);
		                   %prog {'catch'} = parse(@token);
		               }
		when (undef) { print "error";
				        exit 1;
				      }
		default { print "error";
				  exit 1;
				}
	}
}


