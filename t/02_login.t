use strict;
use warnings;

use Test::More tests => 1;

SKIP: {
    skip("environment variables not set", 1) unless(
        defined $ENV{'TELENOR_USERNAME'} and defined $ENV{'TELENOR_PASSWORD'}
    );

    eval { require Net::SMS::TelenorMobil; };
    my $sms = Net::SMS::TelenorMobil->new;

    eval {
        $sms->login(@ENV{'TELENOR_USERNAME', 'TELENOR_PASSWORD'});
    };

    ok(!$@, "login successful");
}
