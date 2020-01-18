package Arty::Schema::Result::variant;

use strict;
use warnings;
use base qw/DBIx::Class/;
use JSON;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('variant');
__PACKAGE__->add_columns(qw(bin
			    var_key
			    chrom
			    start
			    end
			    ref
			    alt
			    aa
			    dbsnp
			  )
			);
__PACKAGE__->add_unique_constraints(var_key_uniq_constr  => ['var_key']);

#--------------------------------------------------------------------------------

1;
