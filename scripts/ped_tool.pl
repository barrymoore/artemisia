#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Arty::PED;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

ped2vaastcl.pl kindreds.ped

Description:

Convert a PED file into a list of VAAST3 command lines.

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if ! $opt_success;
print $usage if $help;

my $ped_file = shift;
die $usage unless $ped_file;

my $ped = Arty::PED->new(file => $ped_file);

my %kindreds;
 RECORD:
while (my $record = $ped->next_record) {

    # * -i    filename      VVP formatted input from VVP -o option.  Can be 'stdin'
    # * -d    filename      Database prefix
    # * -t    int           Number of target samples
    # * -b    int           Number of background samples
    # -e      char          Inheritance.  n = no ihneritance model (default), r = recessive, d = dominant interitance, x = x-linked recessive
    # -p      char          Penetrance.  i = incomplete (default), c = complete penetrance
    # -f      char          Inheritance filter. n = None (default), t = trio, q = quad
    # -m      int           Mother sample index.  Need to set if using inheritance filters
    # -w      int           Father sample index.  Need to set if using inheritance filters
    # -r      int           Proband sample index.  Need to set if using inheritance filters
    # -s      int           Sibling sample index.  Need to set if using quad inheritance filter
    # -u      int           Sibling affected status, 0 or 1.  Need to set if using quad inheritance filter
    # -n      int           Number of threads to use, default = 1

    # Quad      -e r -f q -t 4 -r 0 -m 3 -w 2 -s 1 -u 1
    # Trio      -e r -f t -t 3 -r 2 -m 1 -w 0
    # Singleton -e d -t 1

    # 0  HASH(0x55a416ae0918)
    #    'father' => 912373
    #    'kindred' => 204560
    #    'mother' => 912372
    #    'phenotype' => 2
    #    'sample' => 912371
    #    'sex' => 1
    
    my $kindred_id = $record->{kindred};
    my $sample = $record->{sample};

    # Skip duplicate kindred_id samples_id
    if (exists $kindreds{$kindred_id}{samples}{$sample}) {
	warn "WARN : skipping_duplicate_record : $kindred_id $sample\n";
	next RECORD;
    }

    # Store record
    $kindreds{$kindred_id}{samples}{$sample} = $record;
    
    # Record father
    my $father = $record->{father};
    if ($record->{father} != 0) {
	$kindreds{$kindred_id}{fathers}{$father}++;
	$kindreds{$kindred_id}{children}{$sample}++;
	$kindreds{$kindred_id}{parents}{$father}++;
	$kindreds{$kindred_id}{graph}{$sample}{$father}++;
    }
    # Record mother
    my $mother = $record->{mother};
    if ($record->{mother} != 0) {
	$kindreds{$kindred_id}{mothers}{$mother}++;
	$kindreds{$kindred_id}{children}{$sample}++;
	$kindreds{$kindred_id}{parents}{$mother}++;
	$kindreds{$kindred_id}{graph}{$sample}{$mother}++;
    }
    # Record Phenotype
    ## Affected
    if ($record->{phenotype} == 2) {
	$kindreds{$kindred_id}{affected}{$sample}++;
	$kindreds{$kindred_id}{affected_count}++;
    }
    ## Unaffected
    elsif ($record->{phenotype} == 1) {
	$kindreds{$kindred_id}{unaffected}{$sample}++;
	$kindreds{$kindred_id}{unaffected_count}++;	
    }
    ## Unknown
    else {
	$kindreds{$kindred_id}{unknown_affection}{$sample}++;
	$kindreds{$kindred_id}{unknown_affection_count}++;	
    }
    print '';
}
print '';


for my $kindred_id (keys %kindreds) {
    my $kindred = $kindreds{$kindred_id};
    $kindred->{sample_count}   = keys %{$kindred->{samples}};
    $kindred->{parent_count}   = keys %{$kindred->{parents}};
    $kindred->{children_count} = keys %{$kindred->{children}};

    # Find mother
    if (scalar keys %{$kindred->{mothers}} == 0) {
	# Do nothing
    }
    elsif (scalar keys %{$kindred->{mothers}} == 1) {
	($kindred->{mother}) = keys %{$kindred->{mothers}};
    }
    elsif (scalar keys %{$kindred->{mothers}} > 1) {
	warn("WARN : pedigree_notice : $kindred_id has " .
	     "multiple mothers\n");
    }
    else {
	warn("WARN : pedigree_error : $kindred_id has unusual " .
	     "error in detemining mother\n");
    }

    # Find father
    if (scalar keys %{$kindred->{fathers}} == 0) {
	# Do nothing
    }
    elsif (scalar keys %{$kindred->{fathers}} == 1) {
	($kindred->{father}) = keys %{$kindred->{fathers}};
    }
    elsif (scalar keys %{$kindred->{fathers}} > 1) {
	warn("WARN : pedigree_notice : $kindred_id has " .
	     "multiple fathers\n");
    }
    else {
	warn("WARN : pedigree_error : $kindred_id has unusual " .
	     "error in detemining father\n");
    }

    # Count affected children
    $kindred->{affected_child_count} = 0;
    for my $child_id (keys %{$kindred->{children}}) {
	$kindred->{affected_child_count}++
	    if $kindred->{samples}{$child_id}{phenotype} == 2;
    }

    # Count affected parents
    $kindred->{affected_parent_count} = 0;
    for my $parent_id (keys %{$kindred->{parents}}) {
	$kindred->{affected_parent_count}++
	    if $kindred->{samples}{$parent_id}{phenotype} == 2;
    }
    
    # Quads
    if ($kindred->{sample_count} == 4) {
	$kindred->{family_type} = 'family_4-members';
	if ($kindred->{children_count} == 2 &&
	    $kindred->{parent_count}   == 2) {
	    $kindred->{family_type} = 'quad';
	    if ($kindred->{affected_count} == 0) {
		$kindred->{family_type} = 'quad_no_affected_members';
		warn("WARN : pedigree_error : $kindred_id is " .
		     "_no_affected_members, did you really mean " .
		     "to have an unaffected kindred?");
	    }
	    elsif ($kindred->{affected_count} == 1) {
		$kindred->{family_type} = 'quad_two_affected_members';
                # Quad 1 affected kids, 0 affected parents
                if ($kindred->{affected_child_count}  == 1 &&
                    $kindred->{affected_parent_count} == 0) {
                    $kindred->{family_type} = 'quad_proband_unaffected_sib';
                }
                if ($kindred->{affected_child_count}  == 0 &&
                    $kindred->{affected_parent_count} == 1) {
                    $kindred->{family_type} = 'quad_1_affected_parent_unaffected_sibs';
                }
	    }
	    elsif ($kindred->{affected_count} == 2) {
		$kindred->{family_type} = 'quad_two_affected_members';
		# Quad 2 affected kids, 0 affected parents
		if ($kindred->{affected_child_count}  == 2 &&
		    $kindred->{affected_parent_count} == 0) {
		    $kindred->{family_type} = 'quad_two_affected_sibs';
		}
		# Quad 1 affected kid, 1 affected parent
		elsif ($kindred->{affected_child_count} == 1 &&
		       $kindred->{affected_parent_count} == 1) {
		    $kindred->{family_type} = 'quad_dominant_proband_affected_parent';
		    
		    if ($kindred->{samples}{$kindred->{mother}}{phenotype} == 2) {
			$kindred->{family_type} = 'quad_dominant_maternal';			
		    }
		    elsif ($kindred->{samples}{$kindred->{father}}{phenotype} == 2) {
			$kindred->{family_type} = 'quad_dominant_paternal';			
		    }
		    else {
			warn("WARN : pedigree_error : $kindred_id is "  .
			     "quad_dominant_affected_parent but can't " .
			     "determine paternal/maternal\n");
		    }
		}
		elsif ($kindred->{affected_child_count} == 0 &&
		       $kindred->{affected_parent_count} == 2) {
		    $kindred->{family_type} = 'quad_two_affected_parents';
		}
		else {
		    warn("WARN : pedigree_error : $kindred_id is " .
			 "quad_two_affected_members but can't "    .
			 "determine specific_type\n");
		}
	    }
	    elsif ($kindred->{affected_count} == 3) {
		$kindred->{family_type} = 'quad_three_affected_members';
		# Quad 2 affected kids, 1 affected parent
		if ($kindred->{affected_child_count}  == 2 &&
		    $kindred->{affected_parent_count} == 1) {
		    $kindred->{family_type} = 'quad_dominant_two_affected_sibs';
		    if ($kindred->{samples}{$kindred->{mother}}{phenotype} == 2) {
			$kindred->{family_type} = 'quad_dominant_maternal_two_affected_sibs';			
		    }
		    elsif ($kindred->{samples}{$kindred->{father}}{phenotype} == 2) {
			$kindred->{family_type} = 'quad_dominant_paternal_two_affected_sibs';			
		    }
		    else {
			warn("WARN : pedigree_error : $kindred_id is "  .
			     "quad_dominant_affected_parent but can't " .
			     "determine paternal/maternal\n");
		    }
		}
	    }
	    elsif ($kindred->{affected_count} == 4) {
		$kindred->{family_type} = 'quad_four_affected_members';
		# Quad 2 affected kids, 0 affected parents
		if ($kindred->{affected_child_count}  == 2 &&
		    $kindred->{affected_parent_count} == 2) {
		    $kindred->{family_type} = 'quad_two_affected_sibs';
		}
	    }
	    else {
		warn("WARN : pedigree_error : $kindred_id is " .
		     "quad but affected count is $kindred->{affected_count}, " .
		     "this looks like pedigree error\n");
	    }
	}
    }
    # Trios
    elsif ($kindred->{sample_count} == 3) {
	$kindred->{family_type} = 'family_three_member';	
	# Zero affected
	if ($kindred->{affected_count} == 0) {
	    warn("WARN : pedigree_error : $kindred_id is " .
		 "family_three_member but affected count is " .
		 "$kindred->{affected_count}, did you mean " .
		 "to have an unaffected kindred\n");
	    $kindred->{family_type} = 'family_three_member_unaffected_error';
	}
	# One affected
	elsif ($kindred->{affected_count} == 1) {
	    # Zero children
	    if ($kindred->{children_count} == 0) {
		warn("WARN : pedigree_error : $kindred_id is " .
		     "family_three_member but children count is " .
		     "$kindred->{children_count}");
		$kindred->{family_type} = 'family_three_member_error';	
	    }
	    # One child
	    elsif ($kindred->{children_count} == 1) {
		($kindred->{child}) = keys %{$kindred->{children}};
		# Two parents
		if ($kindred->{parent_count} == 2) {
		    $kindred->{family_type} = 'trio';	
		    # Confirm parent/child relationship in pedigree

		    # Unaffected child
		    if ($kindred->{affected_child_count}  == 0) {
			# One affected parent
			if ($kindred->{affected_parent_count} == 1) {
			    $kindred->{family_type} = 'trio_affected_parent';
			    # Add maternal/paternal logic
			    warn("INFO : code_developmenmt : $kindred_id type " .
				 "could improve (maternal/paternal) with code " .
				 "development");
			}
			# Pedigree error
			else {
			    warn("WARN : pedigree_error : $kindred_id is " .
				 "family_three_member but affected counts " .
				 "don't add up");
			    $kindred->{family_type} = 'family_three_member_error';	
			}
		    }
		    # Affected child
		    elsif ($kindred->{affected_child_count}  == 1) {
			# Unaffected parents
			if ($kindred->{affected_parent_count} == 0) {
			    $kindred->{family_type} = 'trio_true';
			}
			# Pedigree error
			else {
			    warn("WARN : pedigree_error : $kindred_id is " .
				 "family_three_member but affected counts " .
				 "don't add up");
			    $kindred->{family_type} = 'family_three_member_error';	
			}
		    }
		    else {
			warn("WARN : pedigree_error : $kindred_id is " .
			     "family_three_member but affected counts " .
			     "don't add up");
			$kindred->{family_type} = 'family_three_member_error';	
		    }
		}
		else {
		    warn("WARN : pedigree_error : $kindred_id is " .
			 "family_three_member but parent counts " .
			 "don't add up");
		    $kindred->{family_type} = 'family_three_member_error';	
		}
	    }
	    elsif ($kindred->{children_count} == 2) {
		# Praent count != 1 Error
		# One child affected
		# One parent affected
		## Maternal/Paternal
	    }
	    # Three sibs
	    elsif ($kindred->{children_count} == 3) {
		# One sib affected count
	    }
	    # Pedigree error
	    else {
		# Add error
	    }
	}
	elsif ($kindred->{affected_count} == 2) {
	    # Code needed
	    # Dominant Trios Parent/child affected
	    ## Maternal/Paternal
	    # Two parents affected
	    # One parent two affected sibs
	    ## Maternal/Paternal
	}
	# Three affected
	elsif ($kindred->{affected_count} == 3) {
	    # Code needed
	    # All affected
	}
	# More than 3 affeted
	else {
	    warn("WARN : pedigree_error : $kindred_id is " .
		 "family_three_member but affected counts " .
		 "don't add up");
	    $kindred->{family_type} = 'family_three_member_error';	
	}
    }
    elsif ($kindred->{sample_count} == 2) {
	$kindred->{family_type} = 'duo';
    }
    elsif ($kindred->{sample_count} == 1) {
	$kindred->{family_type} = 'singleton';	
    }
    else {
	warn "WARN : complex_family_type : $kindred_id\n";
	$kindred->{family_type} = 'complex_family_structure';
    }
    
    print join "\t", ($kindred_id,
		      $kindred->{family_type},
	);
    print "\n";
    print '';
}
print '';
