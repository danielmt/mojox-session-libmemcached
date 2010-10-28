use Test::More;

BEGIN {
    eval "use Memcached::libmemcached";
    plan skip_all => "Memcached::libmemcached is required to run this test" if $@;
}

use lib 't/lib';

plan tests => 10;

use_ok('MojoX::Session');

my $session = MojoX::Session->new(store => [libmemcached => { servers => ['localhost:11211'] }]);

# create
my $sid = $session->create;
ok($sid);
ok($session->flush);

# load
ok($session->load($sid));
is($session->sid, $sid);

# update
$session->data(foo => 'bar');
ok($session->flush);
ok($session->load($sid));
is($session->data('foo'), 'bar');

# delete
$session->expire;
ok($session->flush);
ok(not defined $session->load($sid));
