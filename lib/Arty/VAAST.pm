package Arty::VAAST;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);

=head1 NAME

Arty::VAAST - Parse VAAST2 files

=head1 VERSION

This document describes Arty::VAAST version 0.0.1

=head1 SYNOPSIS

    use Arty::VAAST;
    my $vaast = Arty::VAAST->new('output.vaast');

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::VAAST> provides VAAST parsing ability for the artemisia suite
of genomics tools.

=head1 CONSTRUCTOR

New L<Arty::VAAST> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the VAAST filename.  All attributes of the L<Arty::VAAST>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::VAAST->new('output.vaast');

    # This is the same as above
    my $parser = Arty::VAAST->new('file' => 'output.vaast');

The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => output.vaast >>

This optional parameter provides the filename for the file containing
the data to be parsed. While this parameter is optional either it, or
the following fh parameter must be set.

=item * C<< fh => $fh >>

This optional parameter provides a filehandle to read data from. While
this parameter is optional either it, or the previous file parameter
must be set.

=back

=cut

=head2 new

     Title   : new
     Usage   : Arty::VAAST->new();
     Function: Creates a Arty::VAAST object;
     Returns : An Arty::VAAST object
     Args    :

=cut

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->_process_header;
	return $self;
}

#-----------------------------------------------------------------------------
#------------------------------ Private Methods ------------------------------
#-----------------------------------------------------------------------------

=head1 PRIVATE METHODS

= cut

#-----------------------------------------------------------------------------

=head2 _initialize_args

 Title   : _initialize_args
 Usage   : $self->_initialize_args($args);
 Function: Initialize the arguments passed to the constructor.  In particular
           set all attributes passed.
 Returns : N/A
 Args    : A hash or array reference of arguments.

=cut
    
sub _initialize_args {
  my ($self, @args) = @_;

  ######################################################################
  # This block of code handels class attributes.  Use the
  # @valid_attributes below to define the valid attributes for
  # this class.  You must have identically named get/set methods
  # for each attribute.  Leave the rest of this block alone!
  ######################################################################
  my $args = $self->SUPER::_initialize_args(@args);
  # Set valid class attributes here
  my @valid_attributes = qw(scored);
  $self->set_attributes($args, @valid_attributes);
  ######################################################################
}

#-----------------------------------------------------------------------------

=head2 _process_header

  Title   : _process_header
  Usage   : $self->_process_header
  Function: Parse and store header data
  Returns : N/A
  Args    : N/A

=cut

 sub _process_header {
     my $self = shift @_;

   LINE:
     while (my $line = $self->readline) {
	 return undef if ! defined $line;
	 if ($line =~ /^\#/) {
	     chomp $line;
	     push @{$self->{header}}, $line;
	 }
	 else {
	     $self->_push_stack($line);
	     last LINE;
	 }
     }
}

#-----------------------------------------------------------------------------
#--------------------------------- Attributes --------------------------------
#-----------------------------------------------------------------------------

=head1 ATTRIBUTES

=cut
    
=head2 scored

 Title   : scored
 Usage   : $scored = $self->scored($scored_value);
 Function: Get/set scored.  Setting this to a true value
           causes Arty::VAAST to only load scored features.
 Returns : Value of scored attribute
 Args    : A value that evaluates by Perl to True or False

=cut

sub scored {
  my ($self, $scored_value) = @_;

  if ($scored_value) {
    $self->{scored} = $scored_value;
  }

  return $self->{scored};
}

# #-----------------------------------------------------------------------------
# 
#  sub _initialize_args {
#    my ($self, @args) = @_;
# 
# @@ -137,15 +137,28 @@ sub _initialize_args {
# 
#     LINE:
#       while (my $line = $self->readline) {
# 	  - return undef if ! defined $line;
# 	  - if ($line =~ /^\#/) {
# 	      -     chomp $line;
# 	      -     push @{$self->{header}}, $line;
# 	      - }
# 	  - else {
# 	      -     $self->_push_stack($line);
# 	      -     last LINE;
# 	      - }
# +         return undef if ! defined $line;
# +         if ($line =~ /^\#/) {
# +             chomp $line;
# +             push @{$self->{header}}, $line;
# +             if ($line =~ /##\s+COMMAND\s+VAAST/) {
# +                     if ($line =~ /\s+\-m\s+pvaast/) {
# +                             $self->mode('pvaast');
# +                     }
# +                     elsif ($line =~ /\s+\-m\s+lrt/) {
# +                             $self->mode('lrt');
# +                     }
# +                     else {
# +                             info_msg('vaast_mode_unknown',
# +                                      "Unable to determine VAAST " .
# +                                      "mode from $line\n");
# +                     }
# +             }
# +     }
# +         else {
# +             $self->_push_stack($line);
# +             last LINE;
# +         }
#       }
#  }
# 
# @@ -156,7 +169,7 @@ sub _initialize_args {
#  =head1 ATTRIBUTES
# 
#  =cut
# -
# +
#  =head2 scored
# 
#   Title   : scored
# @@ -180,6 +193,34 @@ sub scored {
# 
#  #-----------------------------------------------------------------------------
# 
# +=head2 mode
# +
# +  Title   : mode
# +  Usage   : $mode = $self->mode($mode_value);
# +  Function: Get/set the value of the --mode option used to produce the given
# +            VAAST analysis.
# +  Returns : The mode value
# +  Args    : A mode value.  Valid values are 'pvaast' and 'lrt'.
# +
# +=cut
# +
# +sub mode {
# +        my ($self, $mode) = @_;
# +
# +        if ($mode) {
# +                if ($mode ne 'pvaast' && $mode ne 'lrt') {
# +                        throw_msg('invalid_vaast_mode', "VAAST mode $mode " .
# +                                  "not supported.  Check spelling then " .
# +                                  "request support.");
# +                }
# +                $self->{mode} = $mode;
# +        }
# +
# +        return $self->{mode};
# +}
# +
# +#-----------------------------------------------------------------------------
# +


# =head2 attribute
#
#   Title   : attribute
#   Usage   : $attribute = $self->attribute($attribute_value);
#   Function: Get/set attribute
#   Returns : An attribute value
#   Args    : An attribute value
#
# =cut
#
#  sub attribute {
#    my ($self, $attribute_value) = @_;
#
#    if ($attribute) {
#      $self->{attribute} = $attribute;
#    }
#
#    return $self->{attribute};
#  }

=head1 METHODS

=head2 next_record

 Title   : next_record
 Usage   : $record = $vaast->next_record();
 Function: Return the next record from the VAAST file.
 Returns : A hash (or reference) of VAAST record data.
 Args    : N/A

=cut

sub next_record {

  my $self = shift @_;

  my @record_lines;
 OUTER:
  while (my $outer = $self->readline) {
      last OUTER if ! defined $outer;
      next OUTER if $outer =~ /^\#[^\#]/;
      next OUTER if $outer =~ /^\s*$/;
      chomp $outer;
    if ($outer !~ /^>/) {
      throw_msg('invalid_file_structure', "Begining at: $outer");
    }
    push @record_lines, $outer;
  INNER:
    while (my $inner = $self->readline) {
      next INNER if $inner =~ /^\#[^\#]/;
      next INNER if $inner =~ /^\s*$/;
      chomp $inner;
      if ($inner =~ /^>/) {
	$self->_push_stack($inner);
	last OUTER;
      }
      push @record_lines, $inner;
    }
  }
  return undef unless defined $record_lines[0];
  my $record = $self->parse_vaast_record(\@record_lines);
  return undef if $self->{scored} && $record->{score} <= 0;
  return wantarray ? %{$record} : $record;
}

#-----------------------------------------------------------------------------

=head2 parse_vaast_record

 Title    : parse_vaast_record
 Usage    : my $record = $self->parse_vaast($record_txt);
 Function : Parse a single VAAST record.
 Returns  : A hash reference containing the record data.
 Args     : An array reference with the line for a single VAAST record.

=cut

sub parse_vaast_record {

    my ($self, $record_lines) = @_;

    my %record;
  LINE:
    while (my $line = shift @{$record_lines}) {
	
	## VAAST_VERSION 2.1.4
	## COMMAND	VAAST --less_ram -q 40 -m lrt -k -d 10000000 -j 0.0000024 -fast_gp --iht r ...
	## TOTAL_RUN_TIME	24171 seconds
	# >NM_005961	MUC6
	# chr11	-	1013456;1013633;-;chr11	1013899;1014001;-;chr11	...
	# TU:	168.82	1017981@chr11	T|H	N|0-6|A:A|L:L
	# T:        99.98   ins-chrX-101395783-1 ~ 0|!:G|!:AP 4|!:G|!:P 1|G:G|AP:AP 2-3,5-8|G:G|P:P
	# TR:	0.00	1018374@chr11	T|N	B|5|A:A|I:I	B|4|A:T|I:N
	# BR:	1013922@chr11	C|E	358,614,618,733,773,776,798,812,840,888,890,950,952-954,979,991|C:T|E:E
	# BR:	1013992@chr11	C|S	898|C:T|S:N
	# BR:	1015786@chr11	C|G	100,843,847,953|C:T|G:R
	# RANK:0
	# SCORE:168.82330347
	# genome_permutation_p:2.65314941903305e-18
	# genome_permutation_0.95_ci:2.65314941903305e-18,2.25166330953082e-06
	
	
	#---------------------------------------
	# Parse Variant Line
	#---------------------------------------
	# TU: 168.82 1017981@chr11 T|H N|0-6|A:A|L:L
	# T: 99.98 ins-chrX-101395783-1 ~ 1|G:G|AP:AP 2-3,5-8|G:G|P:P
	# BR: 1013992@chr11	C|S 898|C:T|S:N
	if ($line =~ /^(T|TR|TU|P|PR|B|BR):\s+/) {
	    my @fields = split /\s+/, $line;
	    my ($tag, $score, $lod_score, $locus, $ref_seqs, @genotype_data);
	    
	    my %type_map = (ins => 'insertion',
			    del => 'deletion',
			    mnp => 'MNP',
		);
	    
	    #---------------------------------------
	    # Parse Target Variants
	    #---------------------------------------
	    # TU: 168.82 1017981@chr11 T|H N|0-6|A:A|L:L
	    # T: 99.98 ins-chrX-101395783-1 ~ 1|G:G|AP:AP 2-3,5-8|G:G|P:P
	    if ($line =~ /^T[RU]?:\s+/) {
		($tag, $score, $locus, $ref_seqs, @genotype_data) = @fields;
		if ($score =~ /\(.*\)/) {
		    $score =~ s/\(.*\)//;
		    $lod_score = $1;
		}
	    }
	    #---------------------------------------
	    # Parse Background Variants
	    #---------------------------------------
	    # BR: 1013992@chr11	C|S 898|C:T|S:N
	    elsif ($line =~ /^[BP]R?:\s+/) {
		($tag, $locus, $ref_seqs, @genotype_data) = @fields;
	    }
	    #---------------------------------------
	    # Handle Nonstandard Variants
	    #---------------------------------------
	    else {
		throw_msg('invalid_vaast_record', $line);
	    }

	    #---------------------------------------
	    # Set Target/Background tags
	    #---------------------------------------
	    # TU: 168.82 1017981@chr11 T|H N|0-6|A:A|L:L
	    $tag =~ s/:$//;
	    my ($short_tag) = substr($tag, 0, 1);

	    #---------------------------------------
	    # Parse variant details
	    #---------------------------------------
	    # T: 99.98 ins-chrX-101395783-1 ~ 1|G:G|AP:AP 2-3,5-8|G:G|P:P
	    my ($type, $start, $chrom, $length);
	    if ($tag =~ '^(T|P|B)$') {
		($type, $chrom, $start, $length) = split /\-/, $locus;
		$type = exists $type_map{$type} ? $type_map{$type} :
		    $type;
	    }
	    # TU: 168.82 1017981@chr11 T|H N|0-6|A:A|L:L
	    # BR: 1013992@chr11	C|S 898|C:T|S:N
	    else {
		($start, $chrom) = split /\@/, $locus;
		$type = 'SNV';
	    }
	    
	    #---------------------------------------
	    # Parse REF and create var_key
	    #---------------------------------------
	    my ($ref_nt, $ref_aa) = split /\|/, $ref_seqs;
	    my $var_key = join ':', $chrom, $start, $ref_nt;

	    #---------------------------------------
	    # Parse Genotypes
	    #---------------------------------------
	    my %genotypes;
	    my %allele_counts;
	  GENOTYPE:
	    for my $genotype_datum (@genotype_data) {

		#---------------------------------------
		# Genotype flag
		#---------------------------------------
		# N|0-6|A:A|L:L
		# 100,843,847,953|C:T|G:R
		my @fields = split /\|/, $genotype_datum;
		my $flag = shift @fields if $tag =~ /^T[RU]/;
		$flag ||= '';

		#---------------------------------------
		# Genotype nts & aas
		#---------------------------------------
		my ($set, $gt_nt_txt, $gt_aa_txt) = @fields;
		$gt_aa_txt ||= '';
		my @gt_nts = split /:/, $gt_nt_txt;
		my @gt_aas = split /:/, $gt_aa_txt;
		my @indvs;

		#---------------------------------------
		# Parse sample set string
		#---------------------------------------
		for my $indv (split /,/, $set) {
		    if ($indv =~ /(\d+)\-(\d+)/) {
			push @indvs, ($1..$2);
		    }
		    else {
			push @indvs, $indv;
		    }
		}
		
		#---------------------------------------
		# Count alleles
		#---------------------------------------
		my $indv_count = scalar @indvs;
		map {$allele_counts{nt}{$_}{$short_tag} += $indv_count} @gt_nts;
		# map {$allele_counts{aa}{$_}{$short_tag} += $indv_count} @gt_aas;
		$allele_counts{gt}{$gt_nt_txt}{$short_tag} += $indv_count;
		
		#---------------------------------------
		# Build & store genotype data
		#---------------------------------------	
		
		my %genotype = (flag  => $flag,
				indvs => \@indvs,
				gt_nt => \@gt_nts,
				gt_aa => \@gt_aas,
		    );
		$genotypes{$gt_nt_txt} = \%genotype;
	    }
	    #---------------------------------------
	    # ^^^ END GENOTYPE LOOP ^^^
	    #---------------------------------------
	    
	    # Remove REF from allele list
	    # delete $allele_counts{nt}{$ref_nt} if $ref_nt;
	    # delete $allele_counts{aa}{$ref_aa} if $ref_aa;
	    
	    # Check for biallelic
	    # throw_msg('biallelic_nt_alt', $line) if scalar keys %{$allele_counts{nt}} > 1;
	    # throw_msg('biallelic_nt_alt', $line) if scalar keys %{$allele_counts{nt}} > 1;
	    
	    # my ($alt_nt) = keys %{$allele_counts{nt}};
	    # my ($alt_aa) = keys %{$allele_counts{aa}};
	    
	    #---------------------------------------
	    # Aggregate nt allele data
	    #---------------------------------------
	    my %alt_nt_hash;
	    for my $nt (keys %{$allele_counts{nt}}) {
		$record{vars}{$var_key}{ac}{$nt}{$short_tag} +=
		    $allele_counts{nt}{$nt}{$short_tag};
		$record{vars}{$var_key}{type}  = $type
		    if defined $type;
		$record{vars}{$var_key}{score} = defined $score ?
		    $score : $record{vars}{$var_key}{score};
		if ($nt ne $ref_nt && $nt ne '^') {
		    $alt_nt_hash{$nt}++;
		}
	    }

	    #---------------------------------------
	    # Find the ALT nt
	    #---------------------------------------
	    my $alt_nt;
	    if (scalar keys %alt_nt_hash > 1 ) {
		my $alt_nts = join ',', keys  %alt_nt_hash;
		warn_msg('multi_allelic_variant', "($alt_nts) $line");
	    }
	    else {
		($alt_nt) = keys %alt_nt_hash;
	    }
	    $alt_nt ||= '.';
	    # my $var_key_alt = join ':', $var_key, $alt_nt;

	    # #---------------------------------------
	    # # Aggregate aa allele data
	    # #---------------------------------------
	    # my %alt_aa_hash;
	    # for my $aa (keys %{$allele_counts{aa}}) {
	    # 	$record{vars}{$var_key}{aac}{$aa}{$short_tag} +=
	    # 	    $allele_counts{aa}{$aa}{$short_tag};
	    # 	if ($aa ne $ref_aa && $aa ne '^' && $aa ne '-') {
	    # 	    $alt_aa_hash{$aa}++;
	    # 	}
	    # }
	    # 
	    # #---------------------------------------
	    # # Find the ALT aa
	    # #---------------------------------------
	    # my $alt_aa;
	    # if (scalar keys %alt_aa_hash > 1 ) {
	    # 	my $alt_aas = join ',', keys  %alt_aa_hash;
	    # 	warn_msg('multi_allelic_variant', "($alt_aas) $line");
	    # 	print '';
	    # }
	    # else {
	    # 	($alt_aa) = keys %alt_aa_hash;
	    # }
	
	    #---------------------------------------
	    # Aggregate gt allele data
	    #---------------------------------------
	    for my $gt (keys %{$allele_counts{gt}}) {
		$record{vars}{$var_key}{gc}{$gt}{$short_tag} +=
		    $allele_counts{gt}{$gt}{$short_tag};
	    }

	    # #---------------------------------------
	    # # Build & store variant data
	    # #---------------------------------------
	    # my $var_data = {start     => $start,
	    # 		    score     => $score,
	    # 		    ref_nt    => $ref_nt,
	    # 		    ref_aa    => $ref_aa,
	    # 		    alt_nt    => $alt_nt,
	    # 		    tag       => $tag,
	    # 		    # alt_aa    => $alt_aa,
	    # 		    genotypes => \@genotypes
	    # };
	    # $var_data->{lod_score} = $lod_score if defined $lod_score;
	    # $var_data->{type}   = $type   if $type;
	    # $var_data->{length} = $length if $length;
	    # push @{$record{$tag}}, $var_data;
	    
	    #---------------------------------------
	    # Build & store variant data
	    #---------------------------------------
	    $record{vars}{$var_key}{start}  = $start
		unless exists $record{vars}{$var_key}{start};
	    $record{vars}{$var_key}{score} = ($score || 0)
		unless exists $record{vars}{$var_key}{score};
	    $record{vars}{$var_key}{ref_nt} = $ref_nt
		unless exists $record{vars}{$var_key}{ref_nt};
	    $record{vars}{$var_key}{ref_aa} = $ref_aa
		unless exists $record{vars}{$var_key}{ref_aa};
	    $record{vars}{$var_key}{alt_nt} = $alt_nt
		unless exists $record{vars}{$var_key}{alt_nt};
	    $record{vars}{$var_key}{lod_score} = $lod_score
		if defined $lod_score;
	    $record{vars}{$var_key}{type} = $type
		if $type;
	    $record{vars}{$var_key}{length} = $length
		if $length;
	    for my $gt (keys %genotypes) {
		#(flag  => $flag,
		# indvs => \@indvs,
		# gt_nt => \@gt_nts,
		# gt_aa => \@gt_aas)
		$record{vars}{$var_key}{gts}{$gt}{gt_nt} = $genotypes{$gt}{gt_nt}
		unless exists $record{vars}{$var_key}{gts}{$gt}{gt_nt};
		$record{vars}{$var_key}{gts}{$gt}{gt_aa} = $genotypes{$gt}{gt_aa}
		unless exists $record{vars}{$var_key}{gts}{$gt}{gt_aa};
		$record{vars}{$var_key}{gts}{$gt}{$short_tag}{flag}  = $genotypes{$gt}{flag};
		$record{vars}{$var_key}{gts}{$gt}{$short_tag}{indvs} = $genotypes{$gt}{indvs};
	    }
	    print '';
	}
	#---------------------------------------
	# ^^^ END VARIANT LINE BLOCK ^^^
	#---------------------------------------

	#---------------------------------------
	# Parse Record Header
	#---------------------------------------
	# >NM_005961	MUC6
	elsif ($line =~ /^>/) {
	    my ($feature_id, $gene) = split /\s+/, $line;
	    $feature_id =~ s/^>//;
	    $record{feature_id} = $feature_id;
	    $record{gene} = $gene;
	    # chr11	-	1013456;1013633;-;chr11	1013899;1014001;-;chr11	...
	    $line = shift @{$record_lines};
	    my ($chrom, $strand, @cds_text) = split /\s+/, $line;
	    my @cds;
	    for my $cds (@cds_text) {
		my ($start, $end, $strand, $chrom) = split /;/, $cds;
		$record{start} ||= $start;
		$record{end}   ||= $end;
		$record{start} = $start < $record{start} ? $start : $record{start};
		$record{end}   = $end   > $record{end}   ? $end   : $record{end};
		push @cds, [$start, $end];
	    }
	    $record{chrom} = $chrom;
	    $record{strand} = $strand;
	    $record{cds} = \@cds;
	}
	#---------------------------------------
	# Parse Rank
	#---------------------------------------
	# RANK:0
	elsif ($line =~ /^RANK:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
	    }
	    if ($value !~ /^\d+$/) {
		warn_msg('invalid_value', $line);
	    }
	    $record{rank} = $value;
	}
	#---------------------------------------
	# Parse Score
	#---------------------------------------
	# SCORE:168.82330347
	elsif ($line =~ /^SCORE:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /^\d+(\.\d+)?$/) {
		warn_msg('invalid_value', $line);
	    }
	    $record{score} = $value;
	}
	#---------------------------------------
	# Parse UPF
	#---------------------------------------
	# UPF:0
	elsif ($line =~ /^UPF:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /^\d+$/) {
		warn_msg('invalid_value', $line);
	    }
	    $record{upf} = $value;
	}
	#---------------------------------------
	# Parse genome_permutation_p
	#---------------------------------------
	# genome_permutation_p:2.65314941903305e-18
	elsif ($line =~ /^genome_permutation_p:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /[0-9\.e\-]+/) {
		warn_msg('invalid_value', $line);
	    }
	    $record{p_value} = $value;
	}
	#---------------------------------------
	# Parse genome_permutation_0.95_ci
	#---------------------------------------
	# genome_permutation_0.95_ci:2.65314941903305e-18,2.25166330953082e-06
	elsif ($line =~ /^genome_permutation_0\.95_ci:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /[0-9\.e\-]+,[0-9\.e\-]+/) {
		warn_msg('invalid_value', $line);
	    }
	    my @values = split /,/, $value;
	    #@values ||= ('', '');
	    $record{confidence_interval} = \@values;
	}
	#---------------------------------------
	# Parse Running_time
	#---------------------------------------
	# Running_time:14
	elsif ($line =~ /^Running_time:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /^\d+$/) {
		warn_msg('invalid_value', $line);
	    }
	    $record{running_time} = $value;
	}
	#---------------------------------------
	# Parse num_permutations
	#---------------------------------------
	# num_permutations:1638301
	elsif ($line =~ /^num_permutations:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /^\d+$/) {
		warn_msg('invalid_value', $line);
	    }
	    $record{num_permutations} = $value;
	}
	#---------------------------------------
	# Parse total_success
	#---------------------------------------
	# total_success:1
	elsif ($line =~ /^total_success:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /^\d+$/) {
		warn_msg('invalid_value', $line);
	    }
	    $record{total_success} = $value;
	}
	#---------------------------------------
	# Parse LOD_SCORE
	#---------------------------------------
	# LOD_SCORE:0.7269,0.0526315789473684
	elsif ($line =~ /^LOD_SCORE:/) {
	    my ($tag, $value) = split /\s*:\s*/, $line;
	    if (! defined $value) {
		warn_msg('missing_value', $line);
		$value = '';
	    }
	    if ($value !~ /^\d+/) {
		warn_msg('invalid_value', $line);
	    }
	    my @values = split /,/, $value;
	    $record{lod_score} = \@values;
	}
	#---------------------------------------
	# Handle non-standard lines
	#---------------------------------------
	# Warn and skip on any line not recognized
	else {
	    warn_msg('invalid_data_line', $line);
	}
	print '';
    }
    #---------------------------------------
    # ^^^ END LINE LOOP ^^^
    #---------------------------------------

    #---------------------------------------
    # Finalize allele count data 
    #---------------------------------------
    for my $var_key (keys %{$record{vars}}) {
	my $var = $record{vars}{$var_key};
	$var->{score} ||= 0;
	for my $nt_key (keys %{$var->{ac}}) {
	    my $nt = $var->{ac}{$nt_key};
	    $nt->{T} ||= 0;
	    $nt->{B} ||= 0;
	}
	for my $gt_key (keys %{$var->{gc}}) {
	    my $gt = $var->{gc}{$gt_key};
	    $gt->{T} ||= 0;
	    $gt->{B} ||= 0;
	}
    }
    
    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::VAAST> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::VAAST> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Arty::Base>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to:
barry.moore@genetics.utah.edu

=head1 AUTHOR

Barry Moore <barry.moore@genetics.utah.edu>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, Barry Moore <barry.moore@genetics.utah.edu>.
All rights reserved.

    This module is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself (See LICENSE).

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

1;
