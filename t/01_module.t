use strict;
use warnings;

use Test::More tests => 2;

use Net::SMS::TelenorMobil;

can_ok("Net::SMS::TelenorMobil", qw{ new login send logout });

my $sms = Net::SMS::TelenorMobil->new();
isa_ok($sms, "Net::SMS::TelenorMobil");
