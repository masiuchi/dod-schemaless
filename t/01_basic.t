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

my $sqlfile = './sql/sqlite/user.sql';
unlink $TestUser::dbfile;
`sqlite3 $TestUser::dbfile < $sqlfile`;

subtest 'save' => sub {
    my $user = TestUser->new;
    $user->name('James');
    $user->age(30);
    ok( $user->save );
};

subtest 'lookup' => sub {
    my $user = TestUser->lookup(1);
    ok($user);
    is( $user->name, 'James' );
    is( $user->age,  30 );
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

done_testing;

