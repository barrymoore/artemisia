package Arty::Schema::Result::genotype;

use strict;
use warnings;
use base qw/DBIx::Class/;
use JSON;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('genotype');
__PACKAGE__->add_columns(qw(bin
			    var_key
			    sample_id
			    gt
			    dp
			    ad
			    gq
			  )
			);

#--------------------------------------------------------------------------------

1;
