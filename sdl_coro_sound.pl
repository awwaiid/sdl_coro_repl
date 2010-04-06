#!/usr/local/bin/perl

use strict;
use lib 'lib';

use Coro;
use Coro::EV;
use AnyEvent;

use SDL;
use SDL::App;
use SDL::Game::Rect;
use SDL::Event;
use SDL::Events;

use SDL::Rect;
use SDL::Video;
use SDL::Event;
use SDL::Events;
use SDL::Surface;
use SDL::Audio;
use SDL::Mixer;
use SDL::Mixer::Music;
use SDL::Mixer::Effects;


use Carp;

croak 'Cannot init ' . SDL::get_error()
  if ( SDL::init( SDL_INIT_AUDIO | SDL_INIT_VIDEO ) == -1 );

my $app = SDL::Video::set_video_mode( 800, 600, 32,
  SDL_HWSURFACE | SDL_DOUBLEBUF | SDL_HWACCEL );

SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 1024 );


my $rect = SDL::Rect->new( 0,0, $app->w, $app->h);
 
my $pixel_format = $app->format;
my $blue_pixel = SDL::Video::map_RGB( $pixel_format, 0x00, 0x00, 0xff );
my $red_pixel = SDL::Video::map_RGB( $pixel_format, 0xf0, 0x00, 0x33 );
my $green_pixel = SDL::Video::map_RGB( $pixel_format, 0x00, 0xf0, 0x33 );
 
# Initial background
SDL::Video::fill_rect( $app, $rect, $blue_pixel );

my $music_paused = 0;
 
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
        if($music_paused) {
          SDL::Mixer::Music::resume_music();
          $music_paused = 0;
        } else {
          SDL::Mixer::Music::pause_music();
          $music_paused = 1;
        }
        # my $tmp = $red_pixel;
        # $red_pixel = $green_pixel;
        # $green_pixel = $tmp;
        # make_box(0.01, (int rand 630) + 1, (int rand 470) + 1);
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

# my $count = $ARGV[0] || 1;
# make_box((rand 1)/2, (int rand 630) + 1, (int rand 470) + 1) for 1..$count;


# $repl->eval('my $app = $::app');

SDL::Mixer::open_audio( 44100, AUDIO_S16, 2, 1024 );

my ( $status, $freq, $format, $channels ) = @{ SDL::Mixer::query_spec() };

my $audiospec =
  sprintf( "%s, %s, %s, %s\n", $status, $freq, $format, $channels );

carp ' Asked for freq, format, channels ',
  join( ' ', ( 44100, AUDIO_S16, 2, ) );
carp ' Got back status, freq, format, channels ',
  join( ' ', ( $status, $freq, $format, $channels ) );

my $event = SDL::Event->new();
my $song = SDL::Mixer::Music::load_MUS('01-PC-Speaker-Sorrow.ogg');
SDL::Mixer::Music::play_music( $song, 0 );


EV::loop();


