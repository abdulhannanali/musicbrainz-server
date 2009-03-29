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

use HTTP::Status qw(RC_OK RC_NOT_FOUND RC_BAD_REQUEST RC_INTERNAL_SERVER_ERROR RC_FORBIDDEN RC_SERVICE_UNAVAILABLE);
use MusicBrainz::Server::Handlers::WS::1::Common;
use HTTP::Status qw(RC_OK RC_NOT_FOUND RC_BAD_REQUEST RC_INTERNAL_SERVER_ERROR RC_FORBIDDEN RC_SERVICE_UNAVAILABLE);
use MusicBrainz::Server::Tag;
use MusicBrainz::Server::Editor;

use constant MAX_TAGS_PER_REQUEST => 20;

sub handler
{
    my ($c) = @_;
    my $r = $c->req;

    # URLs are of the form:
    # GET http://server/ws/1/tag/?entity=<entity>&id=<id>
    # POST http://server/ws/1/tag/?entity=<entity>&id=<id>&tags=<tags>
    # POST http://server/ws/1/tag/?entity.0=<entity>&id.0=<mbid>&tags.0=<tags>&entity.1=<entity>&id.1=<mbid>&tags.1=<tags>

    if ($r->method eq "POST")
    {
        my $entity = $r->params->{"entity.0"};
        return handler_post_multiple($c) if ($entity);
        return handler_post($c);
    }

    return bad_req($c, "Only GET or POST is acceptable")
        unless $r->method eq "GET";

    my $user = $r->user;
    if (!defined($user) || !$user)
    {
        return bad_req($c, "A valid username must be provided to retrieve tags.");
    }
    my $name = $r->params->{name};
    my $entity = $r->params->{entity};
    my $id = $r->params->{id};
    my $type = $r->params->{type};
    if (!defined($type) || $type ne 'xml')
    {
        return bad_req($c, "Invalid content type. Must be set to xml.");
    }

    if (!MusicBrainz::Server::Validation::IsGUID($id) || 
        ($entity ne 'artist' && $entity ne 'release' && $entity ne 'track' && $entity ne 'label'))
    {
        return bad_req($c, "Invalid MBID/entity.");
    }

    my $status = eval 
    {
        # Try to serve the request from the database
        {
            my $status = serve_from_db($c, $user, $entity, $id);
            return $status if defined $status;
        }
        undef;
    };

    if ($@)
    {
        my $error = "$@";
        print STDERR "WS Error: $error\n";
        # TODO: We should print a custom 500 server error screen with details about our error and where to report it
        $c->response->status(RC_INTERNAL_SERVER_ERROR);
        return RC_INTERNAL_SERVER_ERROR;
    }
    if (!defined $status)
    {
        $c->response->status(RC_NOT_FOUND);
        return RC_NOT_FOUND;
    }

    return RC_OK;
}

# handle the old style single entity per POST type of call
sub handler_post
{
    my $c = shift;
    my $r = $c->req;

    # URLs are of the form:
    # POST http://server/ws/1/tag/?name=<user_name>&entity=<entity>&id=<id>&tags=<tags>

    my $user = $r->user;
    my $entity = $r->params->{entity};
    my $id = $r->param->{id};
    my $tags = $r->params->{tags};

    if (!MusicBrainz::Server::Validation::IsGUID($id) || 
        ($entity ne 'artist' && $entity ne 'release' && $entity ne 'track' && $entity ne 'label'))
    {
        return bad_req($c, "Invalid MBID/entity.");
    }

    # Ensure that the login name is the same as the resource requested 
    if ($r->user ne $user)
    {
        $c->response->status(RC_FORBIDDEN);
        return RC_FORBIDDEN;
    }

    # Ensure that we're not a replicated server and that we were given a client version
    if (&DBDefs::REPLICATION_TYPE == &DBDefs::RT_SLAVE)
    {
        return bad_req($c, "You cannot submit tags to a slave server.");
    }

    my $status = eval 
    {
        # Try to serve the request from the database
        {
            my $status = serve_from_db_post($c, $user, [{ entity => $entity, id => $id, tags => $tags}]);
            return $status if defined $status;
        }
        undef;
    };

    if ($@)
    {
        my $error = "$@";
        print STDERR "WS Error: $error\n";
        $c->response->status(RC_INTERNAL_SERVER_ERROR);
        $r->content_type("text/plain; charset=utf-8");
        $c->response->body($error."\015\012"); # unless $r->header_only;
        return RC_INTERNAL_SERVER_ERROR
    }
    if (!defined $status)
    {
        $c->response->status(RC_NOT_FOUND);
        return RC_NOT_FOUND;
    }

    return RC_OK;
}

# handle multiple entities per post
sub handler_post_multiple
{
    my $c = shift;
    my $r = $c->req;

    # URLs are of the form:
    # POST http://server/ws/1/tag/?entity.0=<entity>&id.0=<mbid>&tags.0=<tags>&entity.1=<entity>&id.1=<mbid>&tags.1=<tags>

    my $user = $r->user;
    my @batch;

    # Ensure that the login name is the same as the resource requested 
    if ($r->user ne $user)
    {
        $c->response->status(RC_FORBIDDEN);
        return RC_FORBIDDEN;
    }

    # Ensure that we're not a replicated server and that we were given a client version
    if (&DBDefs::REPLICATION_TYPE == &DBDefs::RT_SLAVE)
    {
        return bad_req($c, "You cannot submit tags to a slave server.");
    }

    my ($entity, $id, $tags, $count);
    for($count = 0;; $count++)
    {
        my $entity = $r->params->{"entity.$count"};
        my $id = $r->params->{"id.$count"};
        my $tags = $r->params->{"tags.$count"};

        last if (!$entity || !$id || !$tags);

        if (!MusicBrainz::Server::Validation::IsGUID($id) || 
            ($entity ne 'artist' && $entity ne 'release' && $entity ne 'track' && $entity ne 'label'))
        {
            return bad_req($c, "Invalid MBID/entity for set $count.");
        }
        push @batch, { entity => $entity, id => $id, tags => $tags };
    }
    if (!$count)
    {
        return bad_req($c, "No valid tags were specified in this request.");
    }
    if ($count > MAX_TAGS_PER_REQUEST)
    {
        return bad_req($c, "Too many tags for one request. Max " . MAX_TAGS_PER_REQUEST . " tags per request.");
    }

    my $status = eval 
    {
        # Try to serve the request from the database
        {
            my $status = serve_from_db_post($c, $user, \@batch);
            return $status if defined $status;
        }
        undef;
    };

    if ($@)
    {
        my $error = "$@";
        print STDERR "WS Error: $error\n";
        $c->response->status(RC_INTERNAL_SERVER_ERROR);
        $r->content_type("text/plain; charset=utf-8");
        $c->response->body($error."\015\012"); # unless $r->header_only;
        return RC_INTERNAL_SERVER_ERROR
    }
    if (!defined $status)
    {
        $c->response->status(RC_NOT_FOUND);
        return RC_NOT_FOUND;
    }

    return RC_OK;
}

sub serve_from_db_post
{
    my ($c, $user, $tags) = @_;

    my $printer = sub {
        print_xml_post($c, $user, $tags);
    };

    send_response($c, $printer);
    return RC_OK;
}

sub print_xml_post
{
    my ($c, $user, $tags) = @_;

    # Login to the tags DB
    require MusicBrainz;
    my $mb = MusicBrainz->new;
    $mb->Login();

    require MusicBrainz::Server::Editor;
    my $us = MusicBrainz::Server::Editor->new($mb->{dbh});
    $us = $us->newFromName($user) or die "Cannot load user.\n";

    require Sql;
    my $sql = Sql->new($mb->{dbh});

    require MusicBrainz::Server::Artist;
    require MusicBrainz::Server::Release;
    require MusicBrainz::Server::Label;
    require MusicBrainz::Server::Track;

    my $obj;

    foreach my $tag (@{$tags})
    {
        if ($tag->{entity} eq 'artist')
        {
            $obj = MusicBrainz::Server::Artist->new($sql->{dbh});
        }
        elsif ($tag->{entity} eq 'release')
        {
            $obj = MusicBrainz::Server::Release->new($sql->{dbh});
        }
        elsif ($tag->{entity} eq 'track')
        {
            $obj = MusicBrainz::Server::Track->new($sql->{dbh});
        }
        elsif ($tag->{entity} eq 'label')
        {
            $obj = MusicBrainz::Server::Label->new($sql->{dbh});
        }
        $obj->mbid($tag->{id});
        unless ($obj->LoadFromId)
        {
            return bad_req($c, "Cannot load " . $tag->{entity} . ' ' . $tag->{id} . ". Bad entity id given?");
        } 

        my $t = MusicBrainz::Server::Tag->new($mb->{dbh});
        $t->Update($tag->{tags}, $us->GetId, $tag->{entity}, $obj->GetId);
    }

    print '<?xml version="1.0" encoding="UTF-8"?>';
    print '<metadata xmlns="http://musicbrainz.org/ns/mmd-1.0#"/>';
}

sub serve_from_db
{
    my ($c, $user_name, $entity_type, $entity_id) = @_;

    # Login to the main DB
    my $main = MusicBrainz->new;
    $main->Login();
    my $maindb = Sql->new($main->{dbh});

    require MusicBrainz::Server::Editor;
    my $user = MusicBrainz::Server::Editor->new($maindb->{dbh});
    $user = $user->newFromName($user_name) or die "Cannot load user.\n";

    require MusicBrainz::Server::Artist;
    require MusicBrainz::Server::Release;
    require MusicBrainz::Server::Label;
    require MusicBrainz::Server::Track;

    my $obj;
    if ($entity_type eq 'artist')
    {
        $obj = MusicBrainz::Server::Artist->new($maindb->{dbh});
    }
    elsif ($entity_type eq 'release')
    {
        $obj = MusicBrainz::Server::Release->new($maindb->{dbh});
    }
    elsif ($entity_type eq 'track')
    {
        $obj = MusicBrainz::Server::Track->new($maindb->{dbh});
    }
    elsif ($entity_type eq 'label')
    {
        $obj = MusicBrainz::Server::Label->new($maindb->{dbh});
    }
    $obj->mbid($entity_id);
    unless ($obj->LoadFromId)
    {
        die "Cannot load entity. Bad entity id given?"
    }

    my $tag = MusicBrainz::Server::Tag->new($maindb->{dbh});
    my $tags = $tag->GetRawTagsForEntity($entity_type, $obj->GetId, $user->GetId);

    my $printer = sub {
        print_xml($tags);
    };

    send_response($c, $printer);
    return RC_OK;
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
