\unset ON_ERROR_STOP

-- Alphabetical order
DROP TABLE album;
DROP TABLE album_amazon_asin;
DROP TABLE album_cdtoc;
DROP TABLE albumjoin;
DROP TABLE albummeta;
DROP TABLE albumwords;
DROP TABLE annotation;
DROP TABLE artist;
DROP TABLE artistalias;
DROP TABLE artistwords;
DROP TABLE artist_relation;
DROP TABLE automod_election;
DROP TABLE automod_election_vote;
DROP TABLE cdtoc;
DROP TABLE clientversion;
DROP TABLE country;
DROP TABLE currentstat;
DROP TABLE historicalstat;
DROP TABLE l_album_album;
DROP TABLE l_album_artist;
DROP TABLE l_album_track;
DROP TABLE l_album_url;
DROP TABLE l_artist_artist;
DROP TABLE l_artist_track;
DROP TABLE l_artist_url;
DROP TABLE l_track_track;
DROP TABLE l_track_url;
DROP TABLE l_url_url;
DROP TABLE link_attribute;
DROP TABLE link_attribute_type;
DROP TABLE lt_album_album;
DROP TABLE lt_album_artist;
DROP TABLE lt_album_track;
DROP TABLE lt_album_url;
DROP TABLE lt_artist_artist;
DROP TABLE lt_artist_track;
DROP TABLE lt_artist_url;
DROP TABLE lt_track_track;
DROP TABLE lt_track_url;
DROP TABLE lt_url_url;
DROP TABLE moderation_closed;
DROP TABLE moderation_note_closed;
DROP TABLE moderation_note_open;
DROP TABLE moderation_open;
DROP TABLE moderator;
DROP TABLE moderator_preference;
DROP TABLE moderator_subscribe_artist;
DROP TABLE "Pending";
DROP TABLE "PendingData";
DROP TABLE release;
DROP TABLE replication_control;
DROP TABLE stats;
DROP TABLE track;
DROP TABLE trackwords;
DROP TABLE trm;
DROP TABLE trm_stat;
DROP TABLE trmjoin;
DROP TABLE trmjoin_stat;
DROP TABLE url;
DROP TABLE vote_closed;
DROP TABLE vote_open;
DROP TABLE wordlist;

-- Alphabetical order
DROP SEQUENCE album_id_seq;
DROP SEQUENCE albumjoin_id_seq;
DROP SEQUENCE artist_id_seq;
DROP SEQUENCE artist_relation_id_seq;
DROP SEQUENCE artistalias_id_seq;
DROP SEQUENCE automod_election_id_seq;
DROP SEQUENCE automod_election_vote_id_seq;
DROP SEQUENCE clientversion_id_seq;
DROP SEQUENCE country_id_seq;
DROP SEQUENCE discid_id_seq;
DROP SEQUENCE l_album_album_id_seq;
DROP SEQUENCE l_album_artist_id_seq;
DROP SEQUENCE l_album_track_id_seq;
DROP SEQUENCE l_album_url_id_seq;
DROP SEQUENCE l_artist_artist_id_seq;
DROP SEQUENCE l_artist_track_id_seq;
DROP SEQUENCE l_artist_url_id_seq;
DROP SEQUENCE l_track_track_id_seq;
DROP SEQUENCE l_track_url_id_seq;
DROP SEQUENCE l_url_url_id_seq;
DROP SEQUENCE link_attribute_id_seq;
DROP SEQUENCE link_attribute_type_id_seq;
DROP SEQUENCE lt_album_album_id_seq;
DROP SEQUENCE lt_album_artist_id_seq;
DROP SEQUENCE lt_album_track_id_seq;
DROP SEQUENCE lt_album_url_id_seq;
DROP SEQUENCE lt_artist_artist_id_seq;
DROP SEQUENCE lt_artist_track_id_seq;
DROP SEQUENCE lt_artist_url_id_seq;
DROP SEQUENCE lt_track_track_id_seq;
DROP SEQUENCE lt_track_url_id_seq;
DROP SEQUENCE lt_url_url_id_seq;
DROP SEQUENCE moderation_note_open_id_seq;
DROP SEQUENCE moderation_open_id_seq;
DROP SEQUENCE moderator_id_seq;
DROP SEQUENCE moderator_preference_id_seq;
DROP SEQUENCE moderator_subscribe_artist_id_seq;
DROP SEQUENCE "Pending_SeqId_seq";
DROP SEQUENCE release_id_seq;
DROP SEQUENCE replication_control_id_seq;
DROP SEQUENCE stats_id_seq;
DROP SEQUENCE toc_id_seq;
DROP SEQUENCE track_id_seq;
DROP SEQUENCE trm_id_seq;
DROP SEQUENCE trm_stat_id_seq;
DROP SEQUENCE trmjoin_id_seq;
DROP SEQUENCE trmjoin_stat_id_seq;
DROP SEQUENCE url_id_seq;
DROP SEQUENCE vote_open_id_seq;
DROP SEQUENCE wordlist_id_seq;

-- vi: set ts=4 sw=4 et :
