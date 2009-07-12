package Net::SMS::TelenorMobil;

use warnings;
use strict;

our $VERSION = '0.01';

use Carp;
use LWP::UserAgent;

use constant {
    URL_FRONT   => 'https://telenormobil.no/',
    URL_LOGIN   => 'https://telenormobil.no/minesider/login.do',
    URL_COMPOSE => 'https://telenormobil.no/ums/compose/sms.do',
    URL_PROCESS => 'https://telenormobil.no/ums/compose/sms/process.do',
    URL_SEND    => 'https://telenormobil.no/ums/compose/send.do',
    URL_LOGOUT  => 'https://telenormobil.no/minesider/logout.do',
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
         'fromweb'    => "undefined",
         'j_username' => $username,
         'j_password' => $password,
         'image1.x'   => 14,
         'image1.y'   => 5
        ]
        );
    
    unless($res->code() == 302 || $res->header("Location") =~ m"^login.do") {
        croak("Login failed. Check password and try again. Response status code: " . $res->code());
    }


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
    # Get token from SMS form page (disabled, no longer required).
    ##
    #my $token = $self->_get_token();


    ###
    # Send the message.
    ##
    my $res = $ua->post(
        URL_PROCESS,
        [
#         'org.apache.struts.taglib.html.TOKEN' => $token,
         'toAddress'                           => $destination,
         'message'                             => $message,
         'multipleMessages'                    => "true",
         "b_send.x"                            => "32",
         "b_send.y"                            => "7",
        ]
        );

    unless($res->code == 200 || $res->code == 302) {
        croak("Failed to send message. Status: " . $res->status_line);
    }

    ###
    # Message isn't actually sent until we redirect.
    ##
    if($res->code == 302) {
        $res = $ua->get(URL_SEND);
    }

    unless ($res->content =~ m"Meldingen er sendt") {
        croak("Probably failed to send message.")
    }

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


sub _get_token {
    my ($self) = @_;
    my $ua = $self->{'ua'};


    ###
    # Get token from SMS form page.
    ##
    my $res = $ua->get(URL_COMPOSE);
    unless($res->code() == 200) {
        croak("Failed to get page containing the org.apache.struts.taglib.html.TOKEN value");
    }

    unless($res->content() =~ /<input type="hidden" name="org.apache.struts.taglib.html.TOKEN" value="([^\"]*)">/) {
        croak("SMS page did not contain the org.apache.struts.taglib.html.TOKEN value.");
    }

    return $1;
}
