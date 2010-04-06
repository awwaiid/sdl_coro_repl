package SDLx::Coro::Game;

use strict;
use base 'SDLx::Game';

use Coro;
use AnyEvent;

sub _event {
    my $self = shift;

    $self->SUPER::_event(@_);

    # Magical cede to other anyEvent stuff
    my $done = AnyEvent->condvar;
    my $delay = AnyEvent->timer( after => 0.00000001, cb => sub {  $done->send; cede();} );
    $done->recv;
}

sub run {
  my $self = shift;
  async { $self->SUPER::run(@_); };
  EV::loop();
}

1;

