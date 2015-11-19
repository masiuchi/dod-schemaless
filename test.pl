use strict;
use warnings;

my $abc;

$abc = ABC->new;

make_package('ABC');

$abc = ABC->new;
die ref $abc;

sub make_package {
    my $name = shift;

    eval <<__EVAL__;
package $name;
use strict;
use warnings;
use parent 'Data::ObjectDriver::BaseObject';

1;
__EVAL__

    $@ ? die $@ : 1;
}

