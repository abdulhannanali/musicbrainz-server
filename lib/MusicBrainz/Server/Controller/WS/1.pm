package MusicBrainz::Server::Controller::WS::1;

use strict;
use warnings;
use MusicBrainz::Server::Handlers::WS::1::Artist;

use base 'MusicBrainz::Server::Controller';

=head1 NAME

MusicBrainz::Server::Controller::WS::1 - version 1 of the MusicBrainz XML web service

=head1 DESCRIPTION

Handles dispatching calls to the existing Web Service perl modules. TT is not being used for this service.

=head1 METHODS

=head2 artist

Handle artist related web service queries

=cut

sub artist : Path('')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Artist::handler($c);
}

=head2 release

Handle release related web service queries

=cut

sub release : Path('')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Release::handler($c);
}

=head2 track

Handle track related web service queries

=cut

sub track : Path('')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Track::handler($c);
}

=head2 tag

Handle tag related web service queries

=cut

sub tag : Path('')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Tag::handler($c);
}

=head2 user

Handle user related web service queries

=cut

sub user : Path('')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::User::handler($c);
}


1;
