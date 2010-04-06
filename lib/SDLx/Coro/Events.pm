package SDLx::Events::Coro;

=head1 NAME

SDLx::Events::Coro - Make SDL::Events invoke pending Coro routines

=cut

use Coro;
use AnyEvent;

# Asyncronous code #3 -- watch for events
async {
  # print "Waiting for event...\n";
  my $event = SDL::Event->new();
  while(1) {
   while( SDL::Events::poll_event($event) )
   {
    # print "Got event!\n";
      if($event->type == SDL_QUIT) {
        print "All done!\n";
        exit;
      }
      if($event->type == SDL_MOUSEBUTTONDOWN) {
        print "New Box Time!\n";
        my $tmp = $red_pixel;
        $red_pixel = $green_pixel;
        $green_pixel = $tmp;
        make_box(0.01, (int rand 630) + 1, (int rand 470) + 1);
      }
       # cede();
    # my $done = AnyEvent->condvar;
    # my $delay = AnyEvent->timer( after => 0.00000001, cb => sub {  $done->send; cede();} );
    # # print "... waiting ...\n";
    # $done->recv;
   }
    # cede();
    my $done = AnyEvent->condvar;
    my $delay = AnyEvent->timer( after => 0.00000001, cb => sub {  $done->send; cede();} );
    $done->recv;
  }
};

1;

