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

package MusicBrainz::Server::Moderation::MOD_REMOVE_LINK_TYPE;

use ModDefs qw( :modstatus DARTIST_ID MODBOT_MODERATOR );
use base 'Moderation';

sub Name { "Remove Relationship Type" }
sub moderation_id   { 38 }

sub edit_conditions
{
    return {
        ModDefs::QUALITY_LOW => {
            duration     => 4,
            votes        => 1,
            expireaction => ModDefs::EXPIRE_ACCEPT,
            autoedit     => 1,
            name         => $_[0]->Name,
        },  
        ModDefs::QUALITY_NORMAL => {
            duration     => 14,
            votes        => 3,
            expireaction => ModDefs::EXPIRE_ACCEPT,
            autoedit     => 1,
            name         => $_[0]->Name,
        },
        ModDefs::QUALITY_HIGH => {
            duration     => 14,
            votes        => 4,
            expireaction => ModDefs::EXPIRE_REJECT,
            autoedit     => 0,
            name         => $_[0]->Name,
        },
    }
}

sub PreInsert
{
	my ($self, %opts) = @_;

	my $node = $opts{'node'} or die; # a LinkType object
	my $linktype = $opts{'linktype'} or die; # the human readable link type

	if ($node->InUse)
	{
		my $note = "This relationship type is in use and cannot be deleted.";
		$self->SetError($note);
		die $self;
	}

	if ($node->Children)
	{
		my $note = "This relationship type has child relationship types - you must delete those first.";
		$self->SetError($note);
		die $self;
	}

	$self->artist(DARTIST_ID);
	$self->table($node->{_table}); # FIXME internal field
	$self->SetColumn("name");
	$self->row_id($node->id);
	$self->SetPrev($node->name);

	my %new = (
		types 	        => $linktype,
		old_name        => $node->name(),
		old_linkphrase  => $node->GetLinkPhrase(),
		old_rlinkphrase => $node->GetReverseLinkPhrase(),
		old_description => $node->description(),
		old_attribute   => $node->attributes(),
	);

	$node->Delete;
	$self->SetNew($self->ConvertHashToNew(\%new));
}

sub PostLoad
{
	my $self = shift;
	$self->{'new_unpacked'} = $self->ConvertNewToHash($self->GetNew)
		or die;
}

1;
# eof MOD_REMOVE_LINK_TYPE.pm
