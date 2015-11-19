package TestUser;
use strict;
use warnings;
use parent 'Data::ObjectDriver::BaseObject::Schemaless';

use Data::ObjectDriver::Driver::DBI;

our $dbfile = './db/schemaless.db';

__PACKAGE__->install_properties(
    {   columns    => [ 'name', 'age' ],
        indexes    => ['name'],
        datasource => 'user',
        driver     => Data::ObjectDriver::Driver::DBI->new(
            dsn => "dbi:SQLite:dbname=$dbfile",
        ),
    }
);

1;

package main;
use strict;
use warnings;

use Test::More;

my $table_file = './sql/sqlite/user.sql';
my $index_file = './sql/sqlite/index_user.sql';

unlink $TestUser::dbfile;
`sqlite3 $TestUser::dbfile < $table_file`;
`sqlite3 $TestUser::dbfile < $index_file`;

subtest 'insert' => sub {
    my $user = TestUser->new;
    $user->name('James');
    $user->age(30);
    ok( $user->save );

    my @indexes = $user->index_package('name')->search( { id => $user->id } );
    is( scalar @indexes,   1 );
    is( $indexes[0]->name, 'James' );
};

subtest 'lookup' => sub {
    my $user = TestUser->lookup(1);
    ok($user);
    is( $user->name, 'James' );
    is( $user->age,  30 );
};

subtest 'update' => sub {
    {
        my $user = TestUser->lookup(1);
        ok($user);
        $user->name('Akira');
        $user->age(40);
        ok( $user->save );
    }

    my $user = TestUser->lookup(1);
    ok($user);
    is( $user->name, 'Akira' );
    is( $user->age,  40 );
};

subtest 'search' => sub {
    my $user = TestUser->new;
    $user->name('Oliver');
    $user->age(35);
    ok( $user->save );

    my @users = TestUser->search;
    is( scalar @users, 2 );
    for (@users) {
        ok( eval { $_->isa('TestUser') } );
        ok( eval { $_->isa('Data::ObjectDriver::BaseObject::Schemaless') } );
    }
};

subtest 'result' => sub {
    my $result = TestUser->result;
    my @users;
    while ( my $user = $result->next ) {
        push @users, $user;
    }

    is( scalar @users, 2 );
    for (@users) {
        ok( eval { $_->isa('TestUser') } );
        ok( eval { $_->isa('Data::ObjectDriver::BaseObject::Schemaless') } );
    }
};

subtest 'remove' => sub {
    my $user = TestUser->lookup(1);
    ok($user);
    my @indexes = $user->index_package('name')->search( { id => $user->id } );
    is( scalar @indexes, 1 );

    ok( $user->remove );
    ok( !TestUser->lookup(1) );
    @indexes = $user->index_package('name')->search( { id => $user->id } );
    is( scalar @indexes, 0 );
};

done_testing;

