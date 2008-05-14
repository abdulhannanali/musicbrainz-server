#!/usr/bin/perl -w
# vi: set ts=4 sw=4 :
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

use FindBin;
use lib "$FindBin::Bin/../../lib";

use strict;
use warnings;

package TRMsWithManyTracks;
use base qw( MusicBrainz::Server::ReportScript );

sub GatherData
{
	my $self = shift;

	$self->Log("Querying database");
	my $sql = $self->SqlObj;

	$sql->AutoCommit;
	$sql->Do(<<'EOF');
		SELECT	
			trm, 
			COUNT(*) AS freq
		INTO TEMPORARY TABLE 
			tmp_trm_collisions
		FROM
			trmjoin
		GROUP BY 
			trm
		HAVING COUNT(*) >= 10
EOF

	my $rows = $sql->SelectListOfHashes(<<'EOF');
		SELECT
			trm.trm, 
			lookupcount, 
			trm.id, 
			freq
		FROM
			trm, tmp_trm_collisions t
		WHERE
			t.trm = trm.id
		ORDER BY 
			freq desc, lookupcount desc, trm.trm
EOF

	$self->Log("Saving results");
	my $report = $self->PagedReport;

	for my $row (@$rows)
	{
		$row->{'tracks'} = $sql->SelectListOfHashes("
			SELECT	
				t.id AS track_id, 
				t.name AS track_name,
				a.id AS artist_id, 
				a.name AS artist_name,
				a.sortname AS artist_sortname, 
				a.resolution AS artist_resolution,
				t.length
			FROM	
				trmjoin j
			INNER JOIN 
				track t ON t.id = j.track
			INNER JOIN 
				artist a ON a.id = t.artist
			WHERE	
				j.trm = ?
			ORDER 
				BY a.sortname, t.name
			",
			$row->{'id'},
		);

		$report->Print($row);
	}
}

__PACKAGE__->new->RunReport;

# eof TRMsWithManyTracks.pl
