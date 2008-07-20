package MusicBrainz::Server::Controller::Release;

use strict;
use warnings;

use base 'Catalyst::Controller';

use ModDefs;
use MusicBrainz;
use MusicBrainz::Server::Adapter qw(LoadEntity);
use MusicBrainz::Server::Adapter::Relations qw(LoadRelations);
use MusicBrainz::Server::Adapter::Tag qw(PrepareForTagCloud);
use MusicBrainz::Server::CoverArt;
use MusicBrainz::Server::Release;
use MusicBrainz::Server::Tag;
use MusicBrainz::Server::Track;
use MusicBrainz::Server::Validation;

=head1 NAME

MusicBrainz::Server::Controller::Release - Catalyst Controller for
working with Release entities

=head1 DESCRIPTION

This controller handles user interaction, both read and write, with
L<MusicBrainz::Server::Release> objects. This includes displaying
releases, editing releases and creating new releases.

=head1 METHODS

=head2 release

Chained action to load the release

=cut

sub release : Chained CaptureArgs(1)
{
    my ($self, $c, $mbid) = @_;

    my $release = MusicBrainz::Server::Release->new($c->mb->{DBH});
    LoadEntity($release, $mbid);

    $c->stash->{_release} = $release;
    $c->stash->{release}  = $release->ExportStash;
}

sub perma : Chained('release')
{
}

sub details : Chained('release')
{
}

sub google : Chained('release')
{
}

=head2 tags

Show all of this release's tags

=cut

sub tags : Chained('release')
{
    my ($self, $c) = @_;
    my $release = $c->stash->{_release};

    my $t = MusicBrainz::Server::Tag->new($c->mb->{DBH});
    my $tags = $t->GetTagHashForEntity('release', $release->GetId, 200);

    $c->stash->{tagcloud} = PrepareForTagCloud($tags);

    $c->stash->{template} = 'releases/tags.tt';
}

=head2 relations

Show all relationships attached to this release

=cut

sub relations : Chained('release')
{
    my ($self, $c) = @_;
    my $release = $c->stash->{_release};

    $c->stash->{relations} = LoadRelations($release, 'album');

    $c->stash->{template} = 'releases/relations.tt';
}

=head2 show

Display a release to the user.

This loads a release from the database (given a valid MBID or database row
ID) and displays it in full, including a summary of advanced relations,
tags, tracklisting, release events, etc.

=cut

sub show : Chained('release') PathPart('')
{
    my ($self, $c) = @_;
    my $release = $c->stash->{_release};

    my $show_rels = $c->req->query_params->{rel};

    $c->stash->{show_artists}       = $c->req->query_params->{artist};
    $c->stash->{show_relationships} = defined $show_rels ? $show_rels : 1;

    # Load Release
    #
    $c->stash->{release} = $release->ExportStash qw( puids   track_count
                                                     quality language
                                                     type                );


    # Load Release Relationships
    #
    $c->stash->{relations} = LoadRelations($release, 'album');

    # Load Artist
    #
    my $artist = MusicBrainz::Server::Artist->new($c->mb->{DBH});
    LoadEntity($artist, $release->GetArtist);

    # Export enough to display the artist header
    $c->stash->{artist} = $artist->ExportStash qw/ name mbid type date quality
                                                   resolution /;
    

    # Tracks
    my $puid_counts = $release->LoadPUIDCount;
    my @tracks = $release->LoadTracks;

    $c->stash->{tracks} = [];

    for my $track (@tracks)
    {
        my $trackStash = $track->ExportStash qw/number duration artist/;

        $trackStash->{puids}     = $puid_counts->{ $track->GetId };
        $trackStash->{relations} = LoadRelations($track, 'track')
            if $c->stash->{show_relationships};

        push @{ $c->stash->{tracks} }, $trackStash;
    }


    # Tags
    my $t    = MusicBrainz::Server::Tag->new($c->mb->{DBH});
    my $num  = 5;
    my $tags = $t->GetTagHashForEntity('release', $release->GetId, $num + 1);

    $c->stash->{tags}      = [ sort { $tags->{$b} <=> $tags->{$a}; } keys %{$tags} ];
    $c->stash->{more_tags} = scalar(keys %$tags) > $num;

    $c->stash->{template} = 'releases/show.tt';
}

=head1 LICENSE

This software is provided "as is", without warranty of any kind, express or
implied, including  but not limited  to the warranties of  merchantability,
fitness for a particular purpose and noninfringement. In no event shall the
authors or  copyright  holders be  liable for any claim,  damages or  other
liability, whether  in an  action of  contract, tort  or otherwise, arising
from,  out of  or in  connection with  the software or  the  use  or  other
dealings in the software.

GPL - The GNU General Public License    http://www.gnu.org/licenses/gpl.txt
Permits anyone the right to use and modify the software without limitations
as long as proper  credits are given  and the original  and modified source
code are included. Requires  that the final product, software derivate from
the original  source or any  software  utilizing a GPL  component, such  as
this, is also licensed under the GPL license.

=cut

1;
