#!/usr/bin/perl -w

use lib "../cgi-bin";
use strict;
use DBI;
use DBDefs;
use MusicBrainz;

my $line;
my $tracks;
my $artist;
my $title;
my @ttitles;
my $arg;
my $file;
my $cd;
my $crc;
my $toc;

sub ReadOffsets
{
   my $i = 0;
   my $line;
   my $crc;
   my $str;

   while(defined($line = <FILE>))
   {
       $line =~ tr/0-9//cd;
       
       if ($line eq '')
       {
           last;
       }
       $str .= $line . " ";
       $i++
   }
   chop($str);

   $str = "1 $i 0 $str";

   return ($i, $str);
}

sub ReadTitleAndArtist
{
   my $i = 0;
   my $line;
   my $artist;
   my $title;
   my $saved;

   while(defined($line = <FILE>))
   {
       if ($line =~ m/^DTITLE/)
       {
           last;
       }
   }
   if (!defined($line))
   {
       print("Got EOF error\n");
       return [];
   }

   while(defined($line))
   {
       if (!($line =~ m/^DTITLE/))
       {
          last;
       }

       $line =~ s/DTITLE=//;
       chop($line);
       $saved .= $line;
       $line = <FILE>;
   }

   ($artist, $title) = split /\//, $saved, 2;
   chop($artist);
   if (!defined($title))
   {
      $title = "(Various)";
   }

   $title =~ s/^ //;

   return ($title, $artist, $line);
}

sub ReadTitles
{
   my $i = 0;
   my $line = $_[1];
   my @titles;
   my @parts;
   my @dummy;

   for($i = 0; $i < $_[0]; $i++)
   {
       if (!defined($line))
       {
           return [];
       }
       @parts = split /=/, $line, 2;
       chop($parts[1]);

       $line = $parts[0];
       $line =~ tr/0-9//cd;
     
       if ($line eq '')
       {
           printf("Something weird in '$title'. Skipping...\n");
           return @dummy
       }
       if ($line == $i - 1)
       {
           $titles[$i - 1] .= $parts[1];
           $i--;
       }
       else
       {
           $titles[$i] = $parts[1];
       }
      
       if ($line != $i)
       {
           printf("Something weird in '$title'. Skipping...\n");
           return @dummy;
       }

       $line = <FILE>;
   }

   return @titles;
}

sub ProcessFile
{
   my $i = 0;
   my $line;

   $file = $_[0];

   open(FILE, $file)
      or die "Cannot open $file";

   while(defined($line = <FILE>))
   {
      if (!($line =~ m/Track frame offsets/i))   
      {
         next;
      }

      ($tracks, $toc) = ReadOffsets;
      if (defined($tracks))
      {
          ($title, $artist, $line) = ReadTitleAndArtist;
          if (defined($artist) && defined($title) && defined($line))
          {
              my @data;

              @ttitles = ReadTitles($tracks, $line);
              if (scalar(@ttitles) > 0)
              {   
                  @data = ($cd, $tracks, $title, $artist, $toc);
                  push @data, @ttitles;
                  EnterRecord(@data);
                  $i++;
              }
          }
      }
   }

   close FILE;
   
   return $i;
}

sub EnterRecord
{
    my $cd = shift @_;
    my $tracks = shift @_;
    my $title = shift @_;
    my $artistname = shift @_;
    my $toc = shift @_;
    my $artist;
    my ($sql, $sql2);
    my $album;
    my $i;

    if ($artistname eq '')
    {
        $artistname = "Unknown";
    }

    $artist = $cd->InsertArtist($artistname);
    if ($artist < 0)
    {
        print "Cannot insert artist.\n";
        exit 0;
    }

    $album = $cd->InsertAlbum($title, $artist, $tracks);
    if ($album < 0)
    {
        print "Cannot insert album.\n";
        exit 0;
    }
    for($i = 0; $i < $tracks; $i++)
    {
        $title = shift @_;
        $title = "Unknown" if $title eq '';

        $cd->InsertTrack($title, $artist, $album, $i);
        $cd->InsertDiskId("", $album, $toc);
    }
}

sub Recurse
{
    my ($dir) = @_;
    my $count = 0;
    my (@files, $path);

    opendir(DIR, $dir) or die "Can't open $dir";
    @files = readdir(DIR);
    closedir(DIR);

    foreach $file (@files)
    {
        next if ($file eq '.' || $file eq '..');

        $path = $dir . "/" . $file;
        if (-d $path)
        {
            $count += Recurse($path);
            next;
        }
        print "Import: '$path'\n";
        $count += ProcessFile($path);
    }

    return $count;
}

my $count = 0;

$cd = new MusicBrainz;
if (!$cd->Login(1))
{
    printf("Cannot log into database.\n");
    exit(0);
}

while($arg = shift)
{
   print "Processing dir $arg\n";
   $count += Recurse($arg);
}
$cd->Logout;
