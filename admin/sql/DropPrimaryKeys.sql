\unset ON_ERROR_STOP

-- Alphabetical order

ALTER TABLE album DROP CONSTRAINT album_pkey;
ALTER TABLE albumjoin DROP CONSTRAINT albumjoin_pkey;
ALTER TABLE albummeta DROP CONSTRAINT albummeta_pkey;
ALTER TABLE album_amazon_asin DROP CONSTRAINT album_amazon_asin_pkey;
ALTER TABLE album_cdtoc DROP CONSTRAINT album_cdtoc_pkey;
ALTER TABLE albumwords DROP CONSTRAINT albumwords_pkey;
ALTER TABLE annotation DROP CONSTRAINT annotation_pkey;
ALTER TABLE artist DROP CONSTRAINT artist_pkey;
ALTER TABLE artistalias DROP CONSTRAINT artistalias_pkey;
ALTER TABLE artist_relation DROP CONSTRAINT artist_relation_pkey;
ALTER TABLE artistwords DROP CONSTRAINT artistwords_pkey;
ALTER TABLE automod_election DROP CONSTRAINT automod_election_pkey;
ALTER TABLE automod_election_vote DROP CONSTRAINT automod_election_vote_pkey;
ALTER TABLE cdtoc DROP CONSTRAINT cdtoc_pkey;
ALTER TABLE clientversion DROP CONSTRAINT clientversion_pkey;
ALTER TABLE country DROP CONSTRAINT country_pkey;
ALTER TABLE currentstat DROP CONSTRAINT currentstat_pkey;
ALTER TABLE historicalstat DROP CONSTRAINT historicalstat_pkey;
ALTER TABLE l_album_album DROP CONSTRAINT l_album_album_pkey;
ALTER TABLE l_album_artist DROP CONSTRAINT l_album_artist_pkey;
ALTER TABLE l_album_track DROP CONSTRAINT l_album_track_pkey;
ALTER TABLE l_album_url DROP CONSTRAINT l_album_url_pkey;
ALTER TABLE l_artist_artist DROP CONSTRAINT l_artist_artist_pkey;
ALTER TABLE l_artist_track DROP CONSTRAINT l_artist_track_pkey;
ALTER TABLE l_artist_url DROP CONSTRAINT l_artist_url_pkey;
ALTER TABLE l_track_track DROP CONSTRAINT l_track_track_pkey;
ALTER TABLE l_track_url DROP CONSTRAINT l_track_url_pkey;
ALTER TABLE l_url_url DROP CONSTRAINT l_url_url_pkey;
ALTER TABLE link_attribute DROP CONSTRAINT link_attribute_pkey;
ALTER TABLE link_attribute_type DROP CONSTRAINT link_attribute_type_pkey;
ALTER TABLE lt_album_album DROP CONSTRAINT lt_album_album_pkey;
ALTER TABLE lt_album_artist DROP CONSTRAINT lt_album_artist_pkey;
ALTER TABLE lt_album_track DROP CONSTRAINT lt_album_track_pkey;
ALTER TABLE lt_album_url DROP CONSTRAINT lt_album_url_pkey;
ALTER TABLE lt_artist_artist DROP CONSTRAINT lt_artist_artist_pkey;
ALTER TABLE lt_artist_track DROP CONSTRAINT lt_artist_track_pkey;
ALTER TABLE lt_artist_url DROP CONSTRAINT lt_artist_url_pkey;
ALTER TABLE lt_track_track DROP CONSTRAINT lt_track_track_pkey;
ALTER TABLE lt_track_url DROP CONSTRAINT lt_track_url_pkey;
ALTER TABLE lt_url_url DROP CONSTRAINT lt_url_url_pkey;
ALTER TABLE moderation_closed DROP CONSTRAINT moderation_closed_pkey;
ALTER TABLE moderation_note_closed DROP CONSTRAINT moderation_note_closed_pkey;
ALTER TABLE moderation_note_open DROP CONSTRAINT moderation_note_open_pkey;
ALTER TABLE moderation_open DROP CONSTRAINT moderation_open_pkey;
ALTER TABLE moderator DROP CONSTRAINT moderator_pkey;
ALTER TABLE moderator_preference DROP CONSTRAINT moderator_preference_pkey;
ALTER TABLE moderator_subscribe_artist DROP CONSTRAINT moderator_subscribe_artist_pkey;
ALTER TABLE "Pending" DROP CONSTRAINT "Pending_pkey";
ALTER TABLE "PendingData" DROP CONSTRAINT "PendingData_pkey";
ALTER TABLE release DROP CONSTRAINT release_pkey;
ALTER TABLE replication_control DROP CONSTRAINT replication_control_pkey;
ALTER TABLE stats DROP CONSTRAINT stats_pkey;
ALTER TABLE track DROP CONSTRAINT track_pkey;
ALTER TABLE trackwords DROP CONSTRAINT trackwords_pkey;
ALTER TABLE trm DROP CONSTRAINT trm_pkey;
ALTER TABLE trm_stat DROP CONSTRAINT trm_stat_pkey;
ALTER TABLE trmjoin DROP CONSTRAINT trmjoin_pkey;
ALTER TABLE trmjoin_stat DROP CONSTRAINT trmjoin_stat_pkey;
ALTER TABLE url DROP CONSTRAINT url_pkey;
ALTER TABLE vote_closed DROP CONSTRAINT vote_closed_pkey;
ALTER TABLE vote_open DROP CONSTRAINT vote_open_pkey;
ALTER TABLE wordlist DROP CONSTRAINT wordlist_pkey;

-- vi: set ts=4 sw=4 et :
