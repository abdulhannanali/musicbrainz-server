#!/usr/bin/perl -w
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
#   $Id: Track.pm 8966 2007-03-27 19:13:13Z luks $
#____________________________________________________________________________

use strict;

package MusicBrainz::Server::Handlers::WS::1::Tag;

use Apache::Constants qw( );
use Apache::File ();
use MusicBrainz::Server::Handlers::WS::1::Common;
use Apache::Constants qw( OK BAD_REQUEST DECLINED SERVER_ERROR NOT_FOUND FORBIDDEN);
use MusicBrainz::Server::Tag;
use Data::Dumper;

sub handler
{
	my ($r) = @_;
	# URLs are of the form:
	# GET http://server/ws/1/tag/?entity=<entity>&id=<id>
	# POST http://server/ws/1/tag/?entity=<entity>&id=<id>&tags=<tags>

    return handler_post($r) if ($r->method eq "POST");

	return bad_req($r, "Only GET or POST is acceptable")
		unless $r->method eq "GET";

	my $apr = Apache::Request->new($r);
	my $user = $r->user;
	my $entity = $apr->param('entity');
	my $id = $apr->param('id');
	my $type = $apr->param('type');
	if (!defined($type) || $type ne 'xml')
	{
		return bad_req($r, "Invalid content type. Must be set to xml.");
	}

	if (!MusicBrainz::Server::Validation::IsGUID($id) || 
	    ($entity ne 'artist' && $entity ne 'release' && $entity ne 'track' && $entity ne 'label'))
	{
		return bad_req($r, "Invalid MBID/entity.");
	}

	my $status = eval 
	{
		# Try to serve the request from the database
		{
			my $status = serve_from_db($r, $user, $entity, $id);
			return $status if defined $status;
		}
		undef;
	};

	if ($@)
	{
		my $error = "$@";
		print STDERR "WS Error: $error\n";
		# TODO: We should print a custom 500 server error screen with details about our error and where to report it
		$r->status(Apache::Constants::SERVER_ERROR());
		return Apache::Constants::SERVER_ERROR();
	}
	if (!defined $status)
	{
		$r->status(Apache::Constants::NOT_FOUND());
		return Apache::Constants::NOT_FOUND();
	}

	return Apache::Constants::OK();
}

sub handler_post
{
    my $r = shift;

	# URLs are of the form:
	# POST http://server/ws/1/tag/?name=<user_name>&entity=<entity>&id=<id>&tags=<tags>

    my $apr = Apache::Request->new($r);
    my $user = $r->user;
    my $entity = $apr->param('entity');
    my $id = $apr->param('id');
    my $tags = $apr->param('tags');
    my $type = $apr->param('type');
    if (!defined($type) || $type ne 'xml')
    {
		return bad_req($r, "Invalid content type. Must be set to xml.");
	}

    if (!MusicBrainz::Server::Validation::IsGUID($id) || 
        ($entity ne 'artist' && $entity ne 'release' && $entity ne 'track' && $entity ne 'label'))
    {
		return bad_req($r, "Invalid MBID/entity.");
    }

    # Ensure that the login name is the same as the resource requested 
    if ($r->user ne $user)
    {
		$r->status(FORBIDDEN);
        return FORBIDDEN;
    }

    # Ensure that we're not a replicated server and that we were given a client version
    if (&DBDefs::REPLICATION_TYPE == &DBDefs::RT_SLAVE)
    {
		return bad_req($r, "You cannot submit tags to a slave server.");
    }

	my $status = eval 
    {
		# Try to serve the request from the database
		{
			my $status = serve_from_db_post($r, $user, $entity, $id, $tags);
			return $status if defined $status;
		}
        undef;
	};

	if ($@)
	{
		my $error = "$@";
        print STDERR "WS Error: $error\n";
		$r->status(SERVER_ERROR);
		$r->content_type("text/plain; charset=utf-8");
		$r->print($error."\015\012") unless $r->header_only;
		return SERVER_ERROR;
	}
    if (!defined $status)
    {
        $r->status(NOT_FOUND);
        return NOT_FOUND;
    }

	return OK;
}

sub serve_from_db_post
{
	my ($r, $user, $entity, $id, $tags) = @_;

	my $printer = sub {
		print_xml_post($user, $entity, $id, $tags);
	};

	send_response($r, $printer);
	return OK();
}

sub print_xml_post
{
	my ($user, $entity, $id, $tags) = @_;

	# Login to the tags DB
	require MusicBrainz;
	my $mb = MusicBrainz->new;
	$mb->Login();

	require UserStuff;
	my $us = UserStuff->new($mb->{DBH});
	$us = $us->newFromName($user) or die "Cannot load user.\n";

    require Sql;
    my $sql = Sql->new($mb->{DBH});

    require MusicBrainz::Server::Artist;
    require MusicBrainz::Server::Release;
    require MusicBrainz::Server::Label;
    require MusicBrainz::Server::Track;

    my $obj;
    if ($entity eq 'artist')
    {
        $obj = MusicBrainz::Server::Artist->new($sql->{DBH});
    }
    elsif ($entity eq 'release')
    {
        $obj = MusicBrainz::Server::Release->new($sql->{DBH});
    }
    elsif ($entity eq 'track')
    {
        $obj = MusicBrainz::Server::Track->new($sql->{DBH});
    }
    elsif ($entity eq 'label')
    {
        $obj = MusicBrainz::Server::Label->new($sql->{DBH});
    }
    $obj->mbid($id);
    unless ($obj->LoadFromId)
    {
        die "Cannot load entity. Bad entity id given?"
    } 

    my $tag = MusicBrainz::Server::Tag->new($mb->{DBH});
    $tag->Update($tags, $us->id, $entity, $obj->id);

	print '<?xml version="1.0" encoding="UTF-8"?>';
	print '<metadata xmlns="http://musicbrainz.org/ns/mmd-1.0#"/>';
}

sub serve_from_db
{
	my ($r, $user_name, $entity_type, $entity_id) = @_;

	# Login to the main DB
	my $main = MusicBrainz->new;
	$main->Login();
	my $maindb = Sql->new($main->{DBH});

	require UserStuff;
	my $user = UserStuff->new($maindb->{DBH});
	$user = $user->newFromName($user_name) or die "Cannot load user.\n";

    require MusicBrainz::Server::Artist;
    require MusicBrainz::Server::Release;
    require MusicBrainz::Server::Label;
    require MusicBrainz::Server::Track;

    my $obj;
    if ($entity_type eq 'artist')
    {
        $obj = MusicBrainz::Server::Artist->new($maindb->{DBH});
    }
    elsif ($entity_type eq 'release')
    {
        $obj = MusicBrainz::Server::Release->new($maindb->{DBH});
    }
    elsif ($entity_type eq 'track')
    {
        $obj = MusicBrainz::Server::Track->new($maindb->{DBH});
    }
    elsif ($entity_type eq 'label')
    {
        $obj = MusicBrainz::Server::Label->new($maindb->{DBH});
    }
    $obj->mbid($entity_id);
    unless ($obj->LoadFromId)
    {
        die "Cannot load entity. Bad entity id given?"
    }

	my $tag = MusicBrainz::Server::Tag->new($maindb->{DBH});
	my $tags = $tag->GetRawTagsForEntity($entity_type, $obj->id, $user->id);

	my $printer = sub {
		print_xml($tags);
	};

	send_response($r, $printer);
	return Apache::Constants::OK();
}

sub print_xml
{
	my ($tags) = @_;

	print '<?xml version="1.0" encoding="UTF-8"?>';
	print '<metadata xmlns="http://musicbrainz.org/ns/mmd-1.0#">';
	print '<tag-list>' if (scalar(@$tags) > 1);
	foreach my $t (@$tags)
	{
		print '<tag>' . xml_escape($t->{name}) . '</tag>';
	}
	print '</tag-list>' if (scalar(@$tags) > 1);
	print '</metadata>';
}

1;
# eof Tag.pm
