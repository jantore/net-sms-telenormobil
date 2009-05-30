use inc::Module::Install;
use strict;
use warnings;

name          'Net-SMS-TelenorMobil';
license       'perl';
requires      'LWP::UserAgent';
requires      'Crypt::SSLeay';
test_requires 'Test::More';

WriteAll;
