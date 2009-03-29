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
#   $Id: User.pm 9763 2008-03-11 11:32:23Z luks $
#____________________________________________________________________________

use strict;

package MusicBrainz::Server::Handlers::WS::1::User;

use HTTP::Status qw(RC_OK RC_NOT_FOUND RC_BAD_REQUEST RC_INTERNAL_SERVER_ERROR RC_FORBIDDEN RC_SERVICE_UNAVAILABLE);
use MusicBrainz::Server::Handlers::WS::1::Common;
use Data::Dumper;

sub handler
{
    my $c = shift;
    my $r = $c->req;

    # URLs are of the form:
    # http://server/ws/1/user/?name=<user_name>

    return bad_req($c, "Only GET is acceptable")
        unless $r->method eq "GET";

    my $user = $r->params->{name};
    # Ensure that the login name is the same as the resource requested
    if ($r->user ne $user)
    {
        $c->response->status(RC_FORBIDDEN);
        return RC_FORBIDDEN;
    }

    my $status = eval 
    {
        # Try to serve the request from the database
        {
            my $status = serve_from_db($c, $user);
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

sub serve_from_db
{
    my ($c, $user) = @_;

    my $printer = sub {
        print_xml($user);
    };

    send_response($c, $printer);
    return RC_OK;
}

sub print_xml
{
    my ($user) = @_;

    require MusicBrainz;
    my $mb = MusicBrainz->new;
    $mb->Login(db => 'READWRITE');
    require MusicBrainz::Server::Artist;

    require UserStuff;
    my $us = UserStuff->new($mb->{dbh});
    $us = $us->newFromName($user) or die "Cannot load user.\n";

    my @types;
    push @types, "AutoEditor" if ($us->IsAutoEditor($us->GetPrivs));
    push @types, "RelationshipEditor" if $us->IsLinkModerator($us->GetPrivs);
    push @types, "Bot" if $us->IsBot($us->GetPrivs);
    push @types, "NotNaggable" if $us->DontNag($us->GetPrivs);
    my ($nag, $days) = $us->NagCheck;

    print '<?xml version="1.0" encoding="UTF-8"?>';
    print '<metadata xmlns="http://musicbrainz.org/ns/mmd-1.0#" xmlns:ext="http://musicbrainz.org/ns/ext-1.0#">';
    print '<ext:user-list><ext:user type="'. join(' ', @types) . '">';
    print '<name>'.$user.'</name>';
    print '<ext:nag show="' . ($nag ? 'true' : 'false') . '"/>';
    print '</ext:user></ext:user-list>';
    print '</metadata>';
}

1;
# eof User.pm
