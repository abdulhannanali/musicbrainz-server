#!/usr/bin/perl -w
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 1998 Robert Kaye
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   $Id$
#____________________________________________________________________________

use lib "../../cgi-bin";
use DBI;
use DBDefs;
#use MusicBrainz;
use ModDefs;
#use Moderation;
require "Main.pl";

my $count = 0;

sub Arguments
{
   return "";
}

sub Cleanup
{
   my ($dbh, $fix) = @_;
   my ($sth, @row);

   print("update Artist set modpending = 0 where modpending != 0\n") if (!$quiet);
   $dbh->do("update Artist set modpending = 0 where modpending != 0") if ($fix);

   print("update Album set modpending = 0 where modpending != 0\n") if (!$quiet);
   $dbh->do("update Album set modpending = 0 where modpending != 0") if ($fix);
   print("update Album set attributes[1] = 0 where modpending != 0\n") if ($quiet);
   $dbh->do("update Album set attributes[1] = 0 where modpending != 0") if ($fix);

   print("update Discid set modpending = 0 where modpending != 0\n") if (!$quiet);
   $dbh->do("update Discid set modpending = 0 where modpending != 0") if ($fix);

   print("update AlbumJoin set modpending = 0 where modpending != 0\n") if (!$quiet);
   $dbh->do("update AlbumJoin set modpending = 0 where modpending != 0") if ($fix);

   print("update Track set modpending = 0 where modpending != 0\n") if (!$quiet);
   $dbh->do("update Track set modpending = 0 where modpending != 0") if ($fix);

   print("update AlbumJoin set modpending = 0 where modpending != 0\n") if (!$quiet);
   $dbh->do("update AlbumJoin set modpending = 0 where modpending != 0") if ($fix);

   print("update ArtistAlias set modpending = 0 where modpending != 0\n") if (!$quiet);
   $dbh->do("update ArtistAlias set modpending = 0 where modpending != 0") if ($fix);

   $sth = $dbh->prepare(qq|select rowid, tab, col from moderation 
                           where status = | .  ModDefs::STATUS_OPEN);
   if ($sth->execute && $sth->rows > 0)
   {
       while(@row = $sth->fetchrow_array)
       {
          next if ($row[1] eq 'TRMJoin');
          print("update $row[1] set modpending = modpending + 1 where " .
                "id = $row[0]\n") if (!$quiet);

          if ($row[1] eq 'Album' && $row[2] eq 'Attributes')
          {
               $dbh->do(qq\update Album set attributes[1] = attributes[1] + 1 
                           where id = $row[0]\) if ($fix);
          }
          else
          {
               $dbh->do(qq\update $row[1] set modpending = modpending + 1 where 
                      id = $row[0]\) if ($fix);
          }
          $count++;
       }
   }
   $sth->finish;
}

Main(0);
