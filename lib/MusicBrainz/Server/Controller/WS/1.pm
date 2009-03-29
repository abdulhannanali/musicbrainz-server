package MusicBrainz::Server::Controller::WS::1;

use strict;
use warnings;
use Catalyst qw(Authentication);
use MusicBrainz::Server::Handlers::WS::1::Artist;
use MusicBrainz::Server::Handlers::WS::1::Release;
use MusicBrainz::Server::Handlers::WS::1::Label;
use MusicBrainz::Server::Handlers::WS::1::Track;
use MusicBrainz::Server::Handlers::WS::1::Rating;
use MusicBrainz::Server::Handlers::WS::1::Collection;
use MusicBrainz::Server::Handlers::WS::1::Tag;
use MusicBrainz::Server::Handlers::WS::1::User;

use base 'MusicBrainz::Server::Controller';

__PACKAGE__->config->{'Plugin::Authentication'} = {
    default_realm => 'webservice',
    realms => {
        webservice => { 
            credential => { 
                class => 'HTTP',
                type  => 'digest',
                password_type  => 'clear',
                password_field => 'password'
            },
            store => {
                class => '+MusicBrainz::Server::Authentication::Store'
            }
        }
    }
};

=head1 NAME

MusicBrainz::Server::Controller::WS::1 - version 1 of the MusicBrainz XML web service

=head1 DESCRIPTION

Handles dispatching calls to the existing Web Service perl modules. TT is not being used for this service.

=head1 METHODS

=head2 artist

Handle artist related web service queries

=cut

sub artist : Path('artist')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Artist::handler($c);
}

=head2 release

Handle release related web service queries

=cut

sub release : Path('release')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Release::handler($c);
}

=head2 track

Handle track related web service queries

=cut

sub track : Path('track')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Track::handler($c);
}

=head2 label

Handle label related web service queries

=cut

sub label : Path('label')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::Label::handler($c);
}

=head2 tag

Handle tag related web service queries

=cut

sub tag : Path('tag')
{
    my ($self, $c) = @_;
    $c->authenticate({ realm => "webservice" });
    return MusicBrainz::Server::Handlers::WS::1::Tag::handler($c);
}

=head2 user

Handle user related web service queries

=cut

sub user : Path('user')
{
    my ($self, $c) = @_;
    return MusicBrainz::Server::Handlers::WS::1::User::handler($c);
}

=head2 rating

Handle rating related web service queries

=cut

sub rating : Path('rating')
{
    my ($self, $c) = @_;
    $c->authenticate({ realm => "webservice" });
    return MusicBrainz::Server::Handlers::WS::1::Rating::handler($c);
}

=head2 collection

Handle collection related web service queries

=cut

sub collection : Path('collection')
{
    my ($self, $c) = @_;
    $c->authenticate({ realm => "webservice" });
    return MusicBrainz::Server::Handlers::WS::1::Collection::handler($c);
}

1;
