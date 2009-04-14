package MusicBrainz::Server::Controller::Doc;

use strict;
use warnings;
use DBDefs;

use base 'MusicBrainz::Server::Controller';

sub load : Regex('^doc/([^/]*)(/.*)??$')
{
    my ($self, $c) = @_;
    my ($page_id, $bare);

    my ($a, $b) = @{ $c->req->snippets };
    if ($a eq 'bare')
    {
        $page_id = $b;
        $bare = 1;
    }
    else
    {
        $page_id = $a.($b || '');
        $bare = 0;
    }
    
    my $page = $c->model('Documentation')->fetch_page($page_id);
    $c->stash->{page} = $page;

    # Fix up the page id to for use as a page title
    $page_id =~ s/_/ /g;
    $c->stash->{title} = $page_id;
    $c->stash->{wiki_server} = &DBDefs::WIKITRANS_SERVER;

    if ($bare)
    {
        $c->stash->{template} = $page->{success} ? 'doc/bare.tt'
                              : 'doc/bare_error.tt';
    }
    else
    {
        $c->stash->{template} = $page->{success} ? 'doc/page.tt'
                              : 'doc/error.tt';
    }
}

1;
