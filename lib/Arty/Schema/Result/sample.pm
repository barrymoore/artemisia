package Arty::Schema::Result::sample;

use strict;
use warnings;
use base qw/DBIx::Class/;
use JSON;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('sample');
__PACKAGE__->add_columns(qw(sample_id
			  )
                        );
__PACKAGE__->add_unique_constraints(sample_id_uniq_constr  => ['sample_id']);

#--------------------------------------------------------------------------------

1;
