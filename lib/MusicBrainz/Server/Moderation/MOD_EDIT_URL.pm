#!/usr/bin/perl -w
# vi: set ts=4 sw=4 :
#____________________________________________________________________________
#
#   MusicBrainz -- the open internet music database
#
#   Copyright (C) 2000 Robert Kaye
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

package MusicBrainz::Server::Moderation::MOD_EDIT_URL;

use ModDefs qw( :modstatus MODBOT_MODERATOR );
use base 'Moderation';

sub Name { "Edit URL" }
(__PACKAGE__)->RegisterHandler;

sub PreInsert
{
	my ($self, %opts) = @_;

	my $urlobj = $opts{'urlobj'} or die;
	my $url = $opts{'url'} or die;
	my $desc = $opts{'desc'};

	my %new;
	$new{'URL'} = $url;
	$new{'Desc'} = $desc;
	
	my %prev;
	$prev{'URL'} = $urlobj->GetURL;
	$prev{'Desc'} = $urlobj->GetDesc;

	my $artist;
	# Get the artist from artist ARs
	my @links = MusicBrainz::Server::Link->FindLinkedEntities(
		$self->{DBH}, $urlobj->GetId, 'url', ('to_type' => 'artist')
	);
	$artist = $links[0]->{link0_id}
		if (@links);
	# Get the artist from release ARs
	if (!$artist)
	{
		@links = MusicBrainz::Server::Link->FindLinkedEntities(
			$self->{DBH}, $urlobj->GetId, 'url', ('to_type' => 'album')
		);
		if (@links)
		{
			my $album = MusicBrainz::Server::Release->new($self->{DBH});
			$album->SetId($links[0]->{link0_id});
			$artist = $album->GetArtist
				if ($album->LoadFromId(0));
		}
	}
	# Get the artist from track ARs
	if (!$artist)
	{
		@links = MusicBrainz::Server::Link->FindLinkedEntities(
			$self->{DBH}, $urlobj->GetId, 'url', ('to_type' => 'track')
		);
		if (@links)
		{
			my $track = MusicBrainz::Server::Track->new($self->{DBH});
			$track->SetId($links[0]->{link0_id});
			$artist = $track->GetArtist
				if ($track->LoadFromId(0));
		}
	}

	$self->SetArtist($artist) if $artist;
	$self->SetPrev($self->ConvertHashToNew(\%prev));
	$self->SetNew($self->ConvertHashToNew(\%new));
	$self->SetTable("url");
	$self->SetColumn("url");
	$self->SetRowId($urlobj->GetId);
}

sub PostLoad
{
	my $self = shift;
	$self->{'_urlobj'} = MusicBrainz::Server::URL->newFromId($self->{DBH}, $self->GetRowId);
	$self->{'new_unpacked'} = $self->ConvertNewToHash($self->GetNew()) or die;
	$self->{'prev_unpacked'} = $self->ConvertNewToHash($self->GetPrev()) or die;
}

sub DetermineQuality
{
	my $self = shift;

    my @links = MusicBrainz::Server::Link->FindLinkedEntities(
        $self->{DBH}, $self->{rowid}, 'url', ('to_type' => 'album')
    );
    # See if we have an album url link
    if (@links)
    {
        my $album = MusicBrainz::Server::Release->new($self->{DBH});
        $album->SetId($links[0]->{link0_id});
        return $album->GetQuality
            if ($album->LoadFromId(0));
    }
    # Get the artist from artist ARs
    @links = MusicBrainz::Server::Link->FindLinkedEntities(
        $self->{DBH}, $self->{rowid}, 'url', ('to_type' => 'artist')
    );
    if (@links)
    {
        my $ar = MusicBrainz::Server::Artist->new($self->{DBH});
        $ar->SetId($links[0]->{link0_id});
        return $ar->GetQuality
            if ($ar->LoadFromId(0));
    }

    return &ModDefs::QUALITY_NORMAL;
}

sub ApprovedAction
{
	my $self = shift;

	my $urlobj = $self->{'_urlobj'};
	if (!defined $urlobj)
	{
		$self->InsertNote(MODBOT_MODERATOR, "This URL has been deleted");
		return STATUS_FAILEDPREREQ;
	}
	if ($urlobj->GetURL ne $self->{'prev_unpacked'}{'URL'} || $urlobj->GetDesc ne $self->{'prev_unpacked'}{'Desc'})
	{
		$self->InsertNote(MODBOT_MODERATOR, "This URL has already been changed");
		return STATUS_FAILEDPREREQ;
	}

	$urlobj->SetURL($self->{'new_unpacked'}{'URL'});
	$urlobj->SetDesc($self->{'new_unpacked'}{'Desc'});
	$urlobj->UpdateURL;

	my @links = MusicBrainz::Server::Link->FindLinkedEntities(
			$self->{DBH}, $urlobj->GetId, 'url', ('to_type' => 'album')
	);
    for my $link (@links)
	{
        # update amazon links
        if ($link->{link_id} == MusicBrainz::Server::CoverArt->GetAsinLinkTypeId($self->{DBH}) &&
            $link->{link0_type} eq 'album' &&
            $link->{link1_type} eq 'url')
        {
            my $al = MusicBrainz::Server::Release->new($self->{DBH});
            $al->SetId($link->{link0_id});
            if ($al->LoadFromId(1))
            {
                MusicBrainz::Server::CoverArt->ParseAmazonURL($link->{link0_name}, $al);
                MusicBrainz::Server::CoverArt->UpdateAmazonData($al, 0);
            }
        }

        # now check to see if we need to tinker with generic cover art
        if ($link->{link_id} == MusicBrainz::Server::CoverArt->GetCoverArtLinkTypeId($self->{DBH}) &&
            $link->{link0_type} eq 'album' &&
            $link->{link1_type} eq 'url')
        {
            my $al = MusicBrainz::Server::Release->new($self->{DBH});
            $al->SetId($link->{link0_id});
            if ($al->LoadFromId(1))
            {
                MusicBrainz::Server::CoverArt->ParseCoverArtURL($link->{link0_name}, $al);
                MusicBrainz::Server::CoverArt->UpdateCoverArtData($al, 0);
            }
        }
	}

	return STATUS_APPLIED;
}

sub ShowModTypeDelegate
{
	my ($self, $m) = @_;
	$m->out('<tr class="entity"><td class="lbl">URL:</td><td>');
	my $urlobj = $self->{'_urlobj'};
	$m->comp('/comp/linkurl', url => $urlobj);
	$m->out('</td></tr>');
}

1;
# eof MOD_EDIT_URL.pm
