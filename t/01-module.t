use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok("Net::SMS::TelenorMobil");
}
require_ok("Net::SMS::TelenorMobil");

can_ok("Net::SMS::TelenorMobil", qw{ new login send logout });

my $sms = Net::SMS::TelenorMobil->new();

isa_ok($sms, "Net::SMS::TelenorMobil");

