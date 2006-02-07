#!/home/httpd/musicbrainz/mb_server/cgi-bin/perl -w
# vi: set ts=4 sw=4 :
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 2004 Robert Kaye
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

use strict;

package MusicBrainz::Server::Handlers::WS::1::Track;

use Apache::Constants qw( );
use Apache::File ();
use MusicBrainz::Server::Handlers::WS::1::Common;

sub handler
{
	my ($r) = @_;
	# URLs are of the form:
	# http://server/ws/1/track or
	# http://server/ws/1/track/MBID 

	return bad_req($r, "Only GET is acceptable")
		unless $r->method eq "GET";

    my $mbid = $1 if ($r->uri =~ /ws\/1\/track\/([a-z0-9-]*)/);

	my %args; { no warnings; %args = $r->args };
    my ($inc, $bad) = convert_inc($args{inc});

    if ($bad)
    {
		return bad_req($r, "Invalid inc options: '$bad'. For usage, please see: http://musicbrainz.org/development/mmd");
	}
	if ((!MusicBrainz::IsGUID($mbid) && $mbid ne '') || $inc eq 'error')
	{
		return bad_req($r, "Incorrect URI. For usage, please see: http://musicbrainz.org/development/mmd");
	}

    if (!$mbid)
    {
		return bad_req($r, "Collections not supported yet.");
    }

	my $status = eval 
    {
		# Try to serve the request from the database
		{
			my $status = serve_from_db($r, $mbid, $inc);
			return $status if defined $status;
		}
        undef;
	};

	if ($@)
	{
		my $error = "$@";
        print STDERR "WS Error: $error\n";
		$r->status(Apache::Constants::SERVER_ERROR());
		$r->send_http_header("text/plain; charset=utf-8");
		$r->print($error."\015\012") unless $r->header_only;
		return Apache::Constants::SERVER_ERROR();
	}
    if (!defined $status)
    {
        $r->status(Apache::Constants::NOT_FOUND());
        return Apache::Constants::NOT_FOUND();
    }

    $r->status(Apache::Constants::OK());
	return Apache::Constants::OK();
}

sub serve_from_db
{
	my ($r, $mbid, $inc) = @_;

	my $ar;
	my $tr;

	require MusicBrainz;
	my $mb = MusicBrainz->new;
	$mb->Login;
	require Track;

	$tr = Track->new($mb->{DBH});
    $tr->SetMBId($mbid);
	return undef unless $tr->LoadFromId(1);

    if ($inc & INC_ARTIST)
    {
        $ar = Artist->new($mb->{DBH});
        $ar->SetId($tr->GetArtist);
        $ar = undef unless $ar->LoadFromId(1);
    }

	my $printer = sub {
		print_xml($mbid, $inc, $ar, $tr);
	};

	send_response($r, $printer);
	return Apache::Constants::OK();
}

sub print_xml
{
	my ($mbid, $inc, $ar, $tr) = @_;

	print '<?xml version="1.0" encoding="UTF-8"?>';
	print '<metadata xmlns="http://musicbrainz.org/ns/mmd-1.0#">';
    print xml_track($ar, $tr, $inc);
	print '</metadata>';
}

1;
# eof Track.pm
