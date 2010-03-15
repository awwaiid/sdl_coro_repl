#!/usr/local/bin/perl

use strict;
use lib 'lib';
BEGIN { $ENV{PERL_RL} = 'Perl' }
use Devel::REPL;

use Coro;
use Coro::EV;
use AnyEvent;

use Term::ReadLine::readline;
{
  package readline;

  no warnings 'redefine';
  sub rl_getc {
    my $key;
    # $Term::ReadLine::Perl::term->Tk_loop if $Term::ReadLine::toloop && defined &Tk::DoOneEvent;
    until(defined ($key = Term::ReadKey::ReadKey(-1, $readline::term_IN))) {
      # print "Waiting for key...\n";
      my $done = AnyEvent->condvar;
      my $timer = AnyEvent->timer( after => 0.01, cb => sub {$done->send;Coro::cede();} );
      $done->recv;
    }
    return $key;
  }

  $readline::rl_getc = \&rl_getc;
}



# use perl5i;
use vars qw( $repl );
$repl = Devel::REPL->new;
$repl->load_plugin($_) for qw(
  History
  DumpHistory
  OutputCache
  LexEnv
  Colors MultiLine::PPI
  FancyPrompt
  DDS Refresh Interrupt Packages
  ShowClass
);
  # Completion CompletionDriver::LexEnv
  # CompletionDriver::Keywords

$repl->fancy_prompt(sub {
  my $self = shift;
  sprintf '%s:%03d%s> ',
    $self->can('current_package') ? $self->current_package : 'main',
    $self->lines_read,
    $self->can('line_depth') ? ':' . $self->line_depth : '';
});

$repl->fancy_continuation_prompt(sub {
  my $self = shift;
  my $pkg = $self->can('current_package') ? $self->current_package : 'main';
  $pkg =~ s/./ /g;
  sprintf '%s     %s* ',
    $pkg,
    $self->lines_read,
    $self->can('line_depth') ? $self->line_depth : '';
});

$repl->current_package('main');
$repl->eval('use lib "lib"');
# $repl->eval('use perl5i');


async {
  # print "Startin REPL\n";
  while(1) {
    # print "Running once...\n";
    $repl->run_once_safely;
    my $done = AnyEvent->condvar;
    my $delay = AnyEvent->timer( after => 0.00000001, cb => sub {  $done->send; cede();} );
    $done->recv;
  }
};


use SDL;
use SDL::App;
use SDL::Game::Rect;
use SDL::Event;
use SDL::Events;

our $app = SDL::App->new(
  -title => 'rectangle',
  -width => 640,
  -height => 480,
);
 
my $rect = SDL::Rect->new( 0,0, $app->w, $app->h);
 
my $pixel_format = $app->format;
my $blue_pixel = SDL::Video::map_RGB( $pixel_format, 0x00, 0x00, 0xff );
my $red_pixel = SDL::Video::map_RGB( $pixel_format, 0xf0, 0x00, 0x33 );
my $green_pixel = SDL::Video::map_RGB( $pixel_format, 0x00, 0xf0, 0x33 );
 
# Initial background
SDL::Video::fill_rect( $app, $rect, $blue_pixel );

# Make an async box
sub make_box {
  my ($speed, $initial_x, $initial_y) = @_;
  my $color = SDL::Video::map_RGB( $pixel_format, int rand 256, int rand 256, int rand 256 );
 
  async {
    my $grect = SDL::Game::Rect->new($initial_x, $initial_y, 10, 10);
    my $x_direction = 1;
    my $y_direction = 1;
    while(1) {
      #$grect = $grect->move($x_direction,$y_direction);
      $grect->x($grect->x + $x_direction);
      $grect->y($grect->y + $y_direction);
      # print "X: " . $grect->x . " Y: " . $grect->y . " speed: $speed\n";
      $x_direction = -1*$x_direction if $grect->x > 630 || $grect->x < 1;
      $y_direction = -1*$y_direction if $grect->y > 470 || $grect->y < 1;
      SDL::Video::fill_rect( $app, $grect, $color );
      # SDL::Video::update_rect($app, 0, 0, 640, 480);

      my $done = AnyEvent->condvar;
      my $delay = AnyEvent->timer( after => $speed, cb => sub { $done->send;  } );
      $done->recv;
    }
  };

}
 
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

# Redraw the screen about 60 times a second
async {
  # print "Starting screen draw loop.\n";
  while(1) {
    my $done = AnyEvent->condvar;
    my $delay = AnyEvent->timer( after => 0.033, cb => sub {  $done->send; cede();} );
    $done->recv;
    SDL::Video::update_rect($app, 0, 0, 640, 480);
  }
};

# Fast moving red box
#make_box(0.001, 1, 1);

my $count = $ARGV[0] || 1;
make_box((rand 1)/2, (int rand 630) + 1, (int rand 470) + 1) for 1..$count;


$repl->eval('my $app = $::app');



EV::loop();

