use v5.14;

use Test::More;
use Data::Dumper;

use Core::System::ServiceManager qw( get_service );

my $client = get_service('client')->id(1);
is ( $client->id, 1);

my $user = get_service('user', $client->user_db )->id(40092);
is ( $user->id, 40092 );

my $us = get_service('us', _id => 101 );
is ( $us->id, 101 );

my $us_parent = $us->parent;
is ( $us_parent->id, 99 );

my $ss_1 = get_service('service', _id => 1 );
my $ss_2 = get_service('service', _id => 2 );

is ( $ss_1->id, 1 );
is ( $ss_2->id, 2 );
is ( get_service('service', _id => 1)->id,  1 );
 
is ( get_service('service', _id => 1)->get->{service_id},  1 );

done_testing();
