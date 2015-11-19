package Data::ObjectDriver::BaseObject::Schemaless;
use strict;
use warnings;
use parent 'Data::ObjectDriver::BaseObject';

use Data::UUID ();
use JSON       ();

our $PRIMARY_KEY = 'added_id';
our @KEYS = ( $PRIMARY_KEY, 'id', 'attributes' );

__PACKAGE__->add_trigger(
    'post_load' => sub {
        shift->inflate_attributes;
    }
);

sub install_properties {
    my ( $class, $props ) = @_;
    $props->{columns} = [ @{ $props->{columns} }, @KEYS ];
    $props->{primary_key} = $PRIMARY_KEY;
    $class->SUPER::install_properties($props);
}

sub reset_column {
    my ( $obj, $col ) = @_;
    delete $obj->{column_values}{$col};
    delete $obj->{changed_cols}{$col};
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
        $obj->reset_column($col);
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
    local $obj->properties->{columns} = \@KEYS;
    $obj->SUPER::save(@_);
}

1;

