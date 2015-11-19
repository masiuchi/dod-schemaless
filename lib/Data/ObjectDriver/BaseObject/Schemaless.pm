package Data::ObjectDriver::BaseObject::Schemaless;
use strict;
use warnings;
use parent 'Data::ObjectDriver::BaseObject';

use Data::UUID ();
use JSON       ();

our $PRIMARY_KEY = 'added_id';
our @KEYS = ( $PRIMARY_KEY, 'id', 'attributes' );

__PACKAGE__->add_trigger(
    post_load => sub {
        my $obj = shift;
        $obj->inflate_attributes;
    },
);

sub install_properties {
    my ( $class, $props ) = @_;
    $props->{columns} = [ @{ $props->{columns} }, @KEYS ];
    $props->{primary_key} = $PRIMARY_KEY;
    my $ret = $class->SUPER::install_properties($props);
    $class->create_index_packages;
    $ret;
}

sub lookup {
    my $class = shift;
    local $class->properties->{columns} = \@KEYS;
    $class->SUPER::lookup(@_);
}

sub search {
    my ( $class, $terms, $args ) = @_;
    if ( my $id = delete $terms->{id} ) {
        $terms->{added_id} = $id;
    }
    local $class->properties->{columns} = \@KEYS;
    $class->SUPER::search( $terms, $args );
}

sub attributes {
    my $obj = shift;
    if (@_) {
        my $json = eval { JSON::to_json( $_[0] ) } || '{}';
        $obj->column( 'attributes', $json );
    }
    else {
        eval { JSON::from_json( $obj->column('attributes') ) } || {};
    }
}

sub inflate_attributes {
    my $obj  = shift;
    my $attr = $obj->attributes;
    for my $col ( keys %$attr ) {
        next if grep { $_ eq $col } @KEYS;
        $obj->$col( $attr->{$col} );
    }
}

sub deflate_attributes {
    my $obj  = shift;
    my $attr = $obj->attributes;
    for my $col ( @{ $obj->column_names } ) {
        next if grep { $_ eq $col } @KEYS;
        $attr->{$col} = $obj->$col;
    }
    $obj->attributes($attr);
}

sub id {
    my $obj = shift;
    if (@_) {
        $obj->column( 'id', @_ );
    }
    else {
        $obj->column('id') || $obj->column( 'id', Data::UUID->new->create );
    }
}

sub save {
    my $obj = shift;
    $obj->deflate_attributes;
    $obj->id;
    my $ret;
    {
        local $obj->properties->{columns} = \@KEYS;

        local $obj->{column_values}
            = { map { $_ => $obj->{column_values}{$_} } @KEYS };
        local $obj->{changed_cols}
            = { map { $_ => $obj->{changed_cols}{$_} } @KEYS };

        $ret = $obj->SUPER::save(@_);
    }
    $obj->update_indexes;
    $ret;
}

sub remove {
    my $obj = shift;
    my $ret = $obj->SUPER::remove(@_);
    $obj->remove_indexes if ref $obj;
    $ret;
}

sub create_index_packages {
    my $class = shift;
    for my $index ( $class->indexes ) {
        $class->create_index_package($index);
    }
}

sub create_index_package {
    my ( $class, $index ) = @_;
    my $datasource = $class->index_datasource($index);
    my $package    = $class->index_package($index);
    eval <<__EVAL__;
package $package;
use strict;
use warnings;
use parent 'Data::ObjectDriver::BaseObject';

__PACKAGE__->install_properties({
    columns     => [qw( name id )],
    primary_key => [qw( name id )],
    datasource  => '$datasource',
    driver      => $class->driver,
});

1;
__EVAL__
    die $@ if $@;
}

sub index_datasource {
    my ( $class, $index ) = @_;
    'index_' . $class->properties->{datasource} . "_on_$index";
}

sub index_package {
    my ( $class, $index ) = @_;
    __PACKAGE__ . "::$index";
}

sub indexes {
    my $class = shift;
    @{ $class->properties->{indexes} || [] };
}

sub update_indexes {
    my $obj = shift;
    for my $index ( $obj->indexes ) {
        $obj->remove_index($index);
        $obj->create_index($index);
    }
}

sub create_index {
    my ( $obj, $index ) = @_;
    my $package = $obj->index_package($index);
    my $record  = $package->new;
    $record->set_values(
        {   id   => $obj->id,
            name => $obj->$index,
        }
    );
    $record->save or die $@;
}

sub remove_indexes {
    my $obj = shift;
    for my $index ( $obj->indexes ) {
        $obj->remove_index($index);
    }
}

sub remove_index {
    my ( $obj, $index ) = @_;
    my $package = $obj->index_package($index);
    my $terms = { id => $obj->id };
    if ( my @records = $package->search($terms) ) {
        $package->remove($terms) or die $@;
    }
}

1;

