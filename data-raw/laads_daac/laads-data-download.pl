#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw( :config posix_default bundling no_ignore_case no_auto_abbrev);
use LWP::UserAgent;
use LWP::Simple;
use JSON;

my $source      = undef;
my $destination = undef;
my $token       = undef;

GetOptions( 's|source=s' => \$source, 'd|destination=s' => \$destination, 't|token=s' => \$token) or die usage();

sub usage {
  print "Usage:\n";
  print "  $0 [options]\n\n";
  print "Description:\n";
  print "  This script will recursively download all files if they don't exist\n";
  print "  from a LAADS URL and stores them to the specified path\n\n";
  print "Options:\n";
  print "  -s|--source [URL]         Recursively download files at [URL]\n";
  print "  -d|--destination [path]   Store directory structure to [path]\n";
  print "  -t|--token [token]        Use app token [token] to authenticate\n";
}

sub recurse {
  my $src   = $_[0];
  my $dest  = $_[1];
  my $token = $_[2];
  my $ua = LWP::UserAgent->new;
  print "Recursing $dest\n";
  my $req = HTTP::Request->new(GET => $src.".json");
  $req->header('Authorization' => 'Bearer '.$token);
  my $resp = $ua->request($req);
  if ($resp->is_success) {
    my $message = $resp->decoded_content;
    my $listing = decode_json($message);
    for my $entry (@$listing){
      if($entry->{size} == 0){
        mkdir($dest."/".$entry->{name});
        recurse($src.'/'.$entry->{name}, $dest.'/'.$entry->{name}, $token);
      }
    }

    for my $entry (@$listing){
      # Set below to 1 for download progress, or consider LWP::UserAgent::ProgressBar
      $ua->show_progress(0);
      if($entry->{size} != 0 and ! -e $dest.'/'.$entry->{name}){
        print "Downloading $dest/$entry->{name}\n";
        my $req = HTTP::Request->new(GET => $src.'/'.$entry->{name});
        $req->header('Authorization' => 'Bearer '.$token);
        my $resp = $ua->request($req, $dest.'/'.$entry->{name});
      } else {
        print "Skipping $entry->{name} ...\n";
      }
    }
  }
  else {
    print "HTTP GET error code: ", $resp->code, "\n";
    print "HTTP GET error message: ", $resp->message, "\n";
  }
}


if(!defined($source)){
  print "Source not set\n";
  usage();
  die;
}

if(!defined($destination)){
  print "Destination not set\n";
  usage();
  die;
}

if(!defined($token)){
  print "Token not set\n";
  usage();
  die
}

recurse($source, $destination, $token);
