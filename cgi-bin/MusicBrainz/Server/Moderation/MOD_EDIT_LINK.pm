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

package MusicBrainz::Server::Moderation::MOD_EDIT_LINK;

use ModDefs qw( :modstatus MODBOT_MODERATOR );
use base 'Moderation';
use MusicBrainz::Server::Link;

sub Name { "Edit Relationship" }
(__PACKAGE__)->RegisterHandler;

sub PreInsert
{
	my ($self, %opts) = @_;

	my $entities = $opts{'newentities'} or die;    	  # a list of Album/Track/Artist objects, etc
	my $oldentities = $opts{'oldentities'} or die;    	  # a list of Album/Track/Artist objects, etc
	my $link = $opts{'node'} or die;              # a Link object
	my $newlinktype = $opts{'newlinktype'} or die;# new LinkType 
	my $oldlinktype = $opts{'oldlinktype'} or die;# old LinkType 
	my $newattrs = $opts{'newattributes'};
	my $oldattrs = $opts{'oldattributes'};

	my $begindate = &MusicBrainz::MakeDisplayDateStr(join('-', $opts{'begindate'}->[0], $opts{'begindate'}->[1], $opts{'begindate'}->[2]));
	my $enddate = &MusicBrainz::MakeDisplayDateStr(join('-', $opts{'enddate'}->[0], $opts{'enddate'}->[1], $opts{'enddate'}->[2]));

	my $oldlinkphrase = $oldlinktype->{linkphrase};
	my $newlinkphrase = $newlinktype->{linkphrase};
    if (scalar(@$newattrs))
	{
		my $dummy;
		my $attr = MusicBrainz::Server::Attribute->new(
			$self->{DBH},
			scalar($newlinktype->Types)
		);
		$attr = $attr->newFromLinkId($link->GetId());
		($oldlinkphrase, $dummy) = $attr->ReplaceAttributes($oldlinkphrase, '');
		$attr->SetAttributes([map { $_->{value} } @$newattrs]);
		($newlinkphrase, $dummy) = $attr->ReplaceAttributes($newlinkphrase, '');
	}

    $self->SetArtist(@$entities[0]->{type} eq 'artist' ? @$entities[0]->{obj}->GetId : @$entities[0]->{obj}->GetArtist());
    $self->SetTable($link->Table);
    $self->SetColumn("id");
    $self->SetRowId($link->GetId);

    my %new = (
        linkid=>$link->GetId,
        oldlinktypeid=>$oldlinktype->{id},
        newlinktypeid=>$newlinktype->{id},
        oldlinktypephrase=>$oldlinkphrase,
        newlinktypephrase=>$newlinkphrase,
        oldentity0id=>@$oldentities[0]->{id},
        oldentity0type=>@$oldentities[0]->{type},
        oldentity0name=>@$oldentities[0]->{name},
        oldentity1id=>@$oldentities[1]->{id},
        oldentity1type=>@$oldentities[1]->{type},
        oldentity1name=>@$oldentities[1]->{name},
        newentity0id=>@$entities[0]->{id},
        newentity0type=>@$entities[0]->{type},
        newentity0name=>@$entities[0]->{name},
        newentity1id=>@$entities[1]->{id},
        newentity1type=>@$entities[1]->{type},
        newentity1name=>@$entities[1]->{name},
        newbegindate=>$begindate,
        newenddate=>$enddate,
		oldbegindate=>$link->GetBeginDate(),
		oldenddate=>$link->GetEndDate(),
		newattrs=>join(" ", map { $_->{value} } @$newattrs)
    );
    $self->SetNew($self->ConvertHashToNew(\%new));
}

sub PostLoad
{
	my $self = shift;
	$self->{'new_unpacked'} = $self->ConvertNewToHash($self->GetNew)
		or die;
}

sub ApprovedAction
{
  	my $self = shift;
	my $new = $self->{'new_unpacked'};

	my $link = MusicBrainz::Server::Link->new($self->{DBH}, [$new->{oldentity0type}, $new->{oldentity1type}]);
	$link = $link->newFromId($new->{linkid});
	if ($link)
	{
		my $attr = MusicBrainz::Server::Attribute->new(
			$self->{DBH},
			[$new->{oldentity0type}, $new->{oldentity1type}],
			$link->GetId
		);
		if ($attr)
		{
			$attr = undef if (!$attr->Update([split(' ',$new->{newattrs})]));
    	}
		if (!$attr)
		{
			$self->InsertNote(MODBOT_MODERATOR, "The attributes for this link could not be updated.");
			return STATUS_ERROR;
        }

		$link->SetLinks([$new->{newentity0id}, $new->{newentity1id}]);
		$link->SetLinkType($new->{newlinktypeid});
		$link->SetBeginDate($new->{newbegindate});
		$link->SetEndDate($new->{newenddate});
		if (!$link->Update)
		{
			$self->InsertNote(MODBOT_MODERATOR, "This link could not be updated.");
			return STATUS_ERROR;
		}
	}
	return STATUS_APPLIED;
}

1;
# eof MOD_EDIT_LINK.pm
