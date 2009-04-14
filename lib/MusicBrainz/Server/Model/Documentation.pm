package MusicBrainz::Server::Model::Documentation;

use strict;
use warnings;

use base 'MusicBrainz::Server::Model';

use Carp;
use DBDefs;
use MusicBrainz::Server::Cache;
use MusicBrainz::Server::WikiTransclusion;

sub fetch_page
{
    my ($self, $id) = @_;

    my $wt = MusicBrainz::Server::WikiTransclusion->new($self->dbh);
    my $index = $wt->GetPageIndex();

    if (!defined $index)
    {
        return {
            success => 0,
            status  => "Index not available",
            id      => $id,
        };
    }

    my $is_wiki_page = exists($index->{$id}) ? 1 : 0;
    my $cache_key = "wikidocs-$id";
    my $page = MusicBrainz::Server::Cache->get($cache_key);

    if (defined $page)
    {
        return {
            success => 1,
            body    => $page,
            id      => $id,
            version => $is_wiki_page ? $index->{$id} : ''
        };
    }

    my $doc_url = "http://" . &DBDefs::WIKITRANS_SERVER . "/"
                            . $id . "?action=render"
                            . ($is_wiki_page ? ("&oldid=".$index->{$id}) : "");

    require LWP::UserAgent;
    my $ua = LWP::UserAgent->new(max_redirect => 0);
    $ua->env_proxy;
    my $response = $ua->get($doc_url);

    if (!$response->is_success)
    {
        if ($response->is_redirect &&
            $response->header("Location") =~ /http:\/\/(.*?)\/(.*)$/)
        {
            return $self->fetch_page($1);
        }
        else
        {
            return {
                success => 0,
                status  => $response->status_line,
                id      => $id,
            };
        }
    }
    else
    {
        $page = $response->content;
        if ($page =~ /<div class="noarticletext">/s)
        {
            return {
                success => 0,
                status  => 404,
                id      => $id,
            };
        }
        elsif ($page =~ /<span class="redirectText"><a href="http:\/\/.*?\/(.*?)"/)
        {
            return $self->fetch_page($1);
        }
        else
        {
            my $server      = DBDefs::WEB_SERVER;
            my $wiki_server = DBDefs::WIKITRANS_SERVER;

            # remove [edit] links
            $page =~ s/\[.*?>edit<\/a>]//g;

            my $temp = "";
            while(1)
            {
                    if ($page =~ s=(.*?)<a(.*?)href\="http://$wiki_server/(.*?)"(.*?)>(.*?)</a>==s)
                    {
                            my ($text, $pre, $url, $post, $linktext) = ($1, $2, $3, $4, $5);

                            # Is this a non-existant link?
                            if ($url =~ /^\?title=(.*?)&amp;action=edit/)
                            {
                                    $temp .= "$text $linktext ";
                                    next;
                            }

                            my $isWD = exists($index->{$url});
                            my $css = $isWD ? "official" : "unofficial";
                            my $title = $isWD ? "WikiDocs" : "Wiki";

                            my $newpost = "";
                            for(;;)
                            {
                                    if ($post =~ s/(\w+?)="(.*?)"//s)
                                    {
                                            my ($attr, $value) = ($1, $2);
                                            if ($attr eq 'title')
                                            {
                                                    $newpost .= " title=\"$title: $2\"";
                                            }
                                    }
                                    else
                                    {
                                            last;
                                    }
                            }
                            $newpost .= " class=\"$css\""; 
                            $temp .= "$text<a".$pre."href=\"http://$server/doc/$url\"$newpost>$linktext</a>";
                    }
                    else
                    {
                            last;
                    }
            }
            $temp .= $page;
            $page = $temp;

            # this fixes image links to point to the wiki
            $page =~ s[src="/-/images][src="http://$wiki_server/-/images]g;


            # remove ugly ass border=1 from tables
            $page =~ s/table border="1"/table/g;

            # Obfuscate e-mail addresses
            $page =~ s/(\w+)\@(\w+)/$1&#x0040;$2/g;
            $page =~ s/mailto:/mailto&#x3a;/g;

            # expand placeholders which point to the current webserver [@WEB_SERVER@/someurl title]
            $page =~ s/\[\@WEB_SERVER\@([^ ]*) ([^\]]*)\]/<img src="\/images\/edit.gif" alt="" \/><a href="$1">$2<\/a>/g;

            # Now store page in cache
            MusicBrainz::Server::Cache->set($cache_key, $page, MusicBrainz::Server::WikiTransclusion::CACHE_INTERVAL);

            return {
                success => 1,
                body    => $page,
                id      => $id,
                version => $is_wiki_page ? $index->{$id} : ''
            };
        }
    }
}

1;
