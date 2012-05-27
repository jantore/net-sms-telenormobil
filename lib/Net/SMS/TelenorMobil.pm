package Net::SMS::TelenorMobil;

use warnings;
use strict;

our $VERSION = '0.2.0';

use Carp;
use LWP::UserAgent;
use Mojo::DOM;

use constant {
    URL_FRONT   => 'https://www.telenor.no/privat/minesider/logginnfelles.cms',
    URL_LOGIN   => 'https://www.telenor.no/privat/minesider/auth/login',
    URL_INIT_UMS => 'https://www.telenor.no/privat/minesider/abonnement/mobil/umstjeneste/initUmsTjeneste.cms?setCurrentLocationToReturnOfFlow=true&umsUrl=SEND_SMS',
    URL_PROCESS => 'https://telenormobil.no/norm/win/sms/send/process.do',
    URL_SHOW    => 'https://telenormobil.no/norm/win/sms/send/result/show.do',
    URL_LOGOUT  => 'https://telenormobil.no/norm/win/sms/logout.do',
};

sub new {
    my ($class) = @_;

    my $self = {
        ua => undef,
    };
    
    return bless($self, $class);
}


sub login {
    my ($self, $username, $password) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->agent("");
    $ua->timeout(30);
    $ua->env_proxy;
    $ua->cookie_jar( {} );

    ###
    # A simple request to fetch cookies.
    ##
    my $res = $ua->get(URL_FRONT);

    unless($res->code == 200 || $res->code == 301) {
        croak("Failed to get cookies. Request status: " . $res->code());
    }

    ###
    # Log in to the system.
    ##
    $res = $ua->post(
        URL_LOGIN,
        [
            'usr_name'     => $username,
            'usr_password' => $password,
        ]
    );

    # login.action redirects to the following on failure/success, respectively:
    # - https://www.telenor.no/privat/minesider/logginn.cms?submitted=true
    # - https://www.telenor.no/privat/minesider/minside/minSide.cms
    if($res->code() == 302 && $res->header("Location") =~ m{logginnfelles\.cms}) {
        croak("Login failed. Check password and try again. Response status code: " . $res->code());
    }

    # Go through a bunch of redirects to get token for telenormobil.no and
    # fetch cookies.
    $res = $ua->get(URL_INIT_UMS);

    ###
    # Assuming success.
    ##
    $self->{'ua'} = $ua;
}

sub send {
    my ($self, $destination, $message) = @_;
    my $ua = $self->{'ua'};

    croak("Not logged in, please login() before sending messages.") unless defined $ua;

    $destination = join(', ', @{ $destination }) if (ref($destination) eq 'ARRAY');

    ###
    # Send the message.
    ##
    my $res = $ua->post(
        URL_PROCESS,
        [
            'toAddress' => $destination,
            'message'   => $message,
            'b_send'    => "b_send",
        ]
    );

    unless($res->code == 200 || $res->code == 302) {
        croak("Failed to send message. Status: " . $res->status_line);
    }

    ###
    # We need to redirect to get the results of the send attempt.
    ##
    if($res->code == 302) {
        $res = $ua->get(URL_SHOW);
    }

    my $dom = Mojo::DOM->new->parse($res->content);
    my $rows = $dom->find('div.section > div.elegant > table > tbody > tr');

    my @result = map {
        {
            name   => $_->td->[0]->text,
            status => ($_->td->[1]->text =~ /^Sendt/) ? 1 : 0
        }
    } $rows->each;

    croak("No send attempts found on result page (site format changed?)") if scalar(@result) == 0;

    return @result if wantarray;
    return 0       if grep { $_->{status} == 0 } @result;

    return 1;
}

sub logout {
    my ($self) = @_;
    my $ua = $self->{'ua'};

    return unless defined $ua; # not logged in!

    my $res = $ua->get(URL_LOGOUT);

    unless($res->code() == 200) {
        croak("Failed to log out.");
    }

    $self->{'ua'} = undef;
    return 1;
}

1;
