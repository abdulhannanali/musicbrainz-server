\set ON_ERROR_STOP 1

-- Alphabetical order by table

ALTER TABLE album ADD CONSTRAINT album_pkey PRIMARY KEY (id);
ALTER TABLE albumjoin ADD CONSTRAINT albumjoin_pkey PRIMARY KEY (id);
ALTER TABLE albummeta ADD CONSTRAINT albummeta_pkey PRIMARY KEY (id);
ALTER TABLE album_amazon_asin ADD CONSTRAINT album_amazon_asin_pkey PRIMARY KEY (album);
ALTER TABLE album_cdtoc ADD CONSTRAINT album_cdtoc_pkey PRIMARY KEY (id);
ALTER TABLE albumwords ADD CONSTRAINT albumwords_pkey PRIMARY KEY (wordid, albumid);
ALTER TABLE annotation ADD CONSTRAINT annotation_pkey PRIMARY KEY (id);
ALTER TABLE artist ADD CONSTRAINT artist_pkey PRIMARY KEY (id);
ALTER TABLE artistalias ADD CONSTRAINT artistalias_pkey PRIMARY KEY (id);
ALTER TABLE artist_relation ADD CONSTRAINT artist_relation_pkey PRIMARY KEY (id);
ALTER TABLE artistwords ADD CONSTRAINT artistwords_pkey PRIMARY KEY (wordid, artistid);
ALTER TABLE automod_election ADD CONSTRAINT automod_election_pkey PRIMARY KEY (id);
ALTER TABLE automod_election_vote ADD CONSTRAINT automod_election_vote_pkey PRIMARY KEY (id);
ALTER TABLE cdtoc ADD CONSTRAINT cdtoc_pkey PRIMARY KEY (id);
ALTER TABLE clientversion ADD CONSTRAINT clientversion_pkey PRIMARY KEY (id);
ALTER TABLE country ADD CONSTRAINT country_pkey PRIMARY KEY (id);
ALTER TABLE currentstat ADD CONSTRAINT currentstat_pkey PRIMARY KEY (id);
ALTER TABLE historicalstat ADD CONSTRAINT historicalstat_pkey PRIMARY KEY (id);
ALTER TABLE l_album_album ADD CONSTRAINT l_album_album_pkey PRIMARY KEY (id);
ALTER TABLE l_album_artist ADD CONSTRAINT l_album_artist_pkey PRIMARY KEY (id);
ALTER TABLE l_album_track ADD CONSTRAINT l_album_track_pkey PRIMARY KEY (id);
ALTER TABLE l_album_url ADD CONSTRAINT l_album_url_pkey PRIMARY KEY (id);
ALTER TABLE l_artist_artist ADD CONSTRAINT l_artist_artist_pkey PRIMARY KEY (id);
ALTER TABLE l_artist_track ADD CONSTRAINT l_artist_track_pkey PRIMARY KEY (id);
ALTER TABLE l_artist_url ADD CONSTRAINT l_artist_url_pkey PRIMARY KEY (id);
ALTER TABLE l_track_track ADD CONSTRAINT l_track_track_pkey PRIMARY KEY (id);
ALTER TABLE l_track_url ADD CONSTRAINT l_track_url_pkey PRIMARY KEY (id);
ALTER TABLE l_url_url ADD CONSTRAINT l_url_url_pkey PRIMARY KEY (id);
ALTER TABLE link_attribute ADD CONSTRAINT link_attribute_pkey PRIMARY KEY (id);
ALTER TABLE link_attribute_type ADD CONSTRAINT link_attribute_type_pkey PRIMARY KEY (id);
ALTER TABLE lt_album_album ADD CONSTRAINT lt_album_album_pkey PRIMARY KEY (id);
ALTER TABLE lt_album_artist ADD CONSTRAINT lt_album_artist_pkey PRIMARY KEY (id);
ALTER TABLE lt_album_track ADD CONSTRAINT lt_album_track_pkey PRIMARY KEY (id);
ALTER TABLE lt_album_url ADD CONSTRAINT lt_album_url_pkey PRIMARY KEY (id);
ALTER TABLE lt_artist_artist ADD CONSTRAINT lt_artist_artist_pkey PRIMARY KEY (id);
ALTER TABLE lt_artist_track ADD CONSTRAINT lt_artist_track_pkey PRIMARY KEY (id);
ALTER TABLE lt_artist_url ADD CONSTRAINT lt_artist_url_pkey PRIMARY KEY (id);
ALTER TABLE lt_track_track ADD CONSTRAINT lt_track_track_pkey PRIMARY KEY (id);
ALTER TABLE lt_track_url ADD CONSTRAINT lt_track_url_pkey PRIMARY KEY (id);
ALTER TABLE lt_url_url ADD CONSTRAINT lt_url_url_pkey PRIMARY KEY (id);
ALTER TABLE moderation_closed ADD CONSTRAINT moderation_closed_pkey PRIMARY KEY (id);
ALTER TABLE moderation_note_closed ADD CONSTRAINT moderation_note_closed_pkey PRIMARY KEY (id);
ALTER TABLE moderation_note_open ADD CONSTRAINT moderation_note_open_pkey PRIMARY KEY (id);
ALTER TABLE moderation_open ADD CONSTRAINT moderation_open_pkey PRIMARY KEY (id);
ALTER TABLE moderator ADD CONSTRAINT moderator_pkey PRIMARY KEY (id);
ALTER TABLE moderator_preference ADD CONSTRAINT moderator_preference_pkey PRIMARY KEY (id);
ALTER TABLE moderator_subscribe_artist ADD CONSTRAINT moderator_subscribe_artist_pkey PRIMARY KEY (id);
ALTER TABLE "Pending" ADD CONSTRAINT "Pending_pkey" PRIMARY KEY ("SeqId");
ALTER TABLE "PendingData" ADD CONSTRAINT "PendingData_pkey" PRIMARY KEY ("SeqId", "IsKey");
ALTER TABLE release ADD CONSTRAINT release_pkey PRIMARY KEY (id);
ALTER TABLE replication_control ADD CONSTRAINT replication_control_pkey PRIMARY KEY (id);
ALTER TABLE stats ADD CONSTRAINT stats_pkey PRIMARY KEY (id);
ALTER TABLE track ADD CONSTRAINT track_pkey PRIMARY KEY (id);
ALTER TABLE trackwords ADD CONSTRAINT trackwords_pkey PRIMARY KEY (wordid, trackid);
ALTER TABLE trm ADD CONSTRAINT trm_pkey PRIMARY KEY (id);
ALTER TABLE trm_stat ADD CONSTRAINT trm_stat_pkey PRIMARY KEY (id);
ALTER TABLE trmjoin ADD CONSTRAINT trmjoin_pkey PRIMARY KEY (id);
ALTER TABLE trmjoin_stat ADD CONSTRAINT trmjoin_stat_pkey PRIMARY KEY (id);
ALTER TABLE url ADD CONSTRAINT url_pkey PRIMARY KEY (id);
ALTER TABLE vote_closed ADD CONSTRAINT vote_closed_pkey PRIMARY KEY (id);
ALTER TABLE vote_open ADD CONSTRAINT vote_open_pkey PRIMARY KEY (id);
ALTER TABLE wordlist ADD CONSTRAINT wordlist_pkey PRIMARY KEY (id);

-- vi: set ts=4 sw=4 et :
