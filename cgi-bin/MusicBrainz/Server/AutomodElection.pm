#!/home/httpd/musicbrainz/mb_server/cgi-bin/perl -w
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

package MusicBrainz::Server::AutomodElection;

use constant PROPOSAL_TIMEOUT => "1 week";
use constant VOTING_TIMEOUT => "1 week";

use base qw( TableBase );
use Carp;
use ModDefs ':vote';

# GetId - see TableBase
sub GetCandidate	{ $_[0]{candidate} }
sub GetProposer		{ $_[0]{proposer} }
sub GetSeconder1	{ $_[0]{seconder_1} }
sub GetSeconder2	{ $_[0]{seconder_2} }
sub GetStatus		{ $_[0]{status} }
sub GetYesVotes		{ $_[0]{yesvotes} }
sub GetNoVotes		{ $_[0]{novotes} }
sub GetProposeTime	{ $_[0]{proposetime} }
sub GetOpenTime		{ $_[0]{opentime} }
sub GetCloseTime	{ $_[0]{closetime} }

sub GetElections
{
	my $self = shift;
	my $sql = Sql->new($self->{DBH});

	my $rows = $sql->SelectListOfHashes(
		"SELECT * FROM automod_election ORDER BY proposetime DESC",
	);

	for (@$rows)
	{
		$_->{DBH} = $self->{DBH};
		bless $_, ref($self);
	}

	$rows;
}

sub newFromId
{
	my ($self, $id) = @_;
	my $sql = Sql->new($self->{DBH});

	my $row = $sql->SelectSingleRowHash(
		"SELECT * FROM automod_election WHERE id = ?",
		$id,
	) or return undef;

	$row->{DBH} = $self->{DBH};
	bless $row, ref($self);
}

sub _Refresh
{
	my $self = shift;
	my $sql = Sql->new($self->{DBH});
	my $newself = $self->newFromId($self->GetId)
		or return;
	%$self = %$newself;
	$self;
}

my %descstatus = (
	1 => "awaiting 1st seconder",
	2 => "awaiting 2nd seconder",
	3 => "voting open",
	4 => "accepted",
	5 => "rejected",
	6 => "cancelled",
);

sub GetStatusName
{
	my ($self, $status) = @_;
	$status = $self->GetStatus unless defined $status;
	$descstatus{$status};
}

sub GetVotes
{
	MusicBrainz::Server::AutomodElection::Vote->_newFromElection($_[0]);
}

################################################################################
# Automatically close or timeout elections.  Currently this is called from the
# elections web pages, but maybe it should be called from hourly.sh as well /
# instead.
################################################################################

sub DoCloseElections
{
	my $self = shift;
	my $sql = Sql->new($self->{DBH});

	$sql->AutoTransaction(
		sub {
			$sql->Do("LOCK TABLE automod_election IN EXCLUSIVE MODE");
			
			my $to_timeout = $sql->SelectListOfHashes(
				"SELECT * FROM automod_election WHERE status IN (1,2)
					AND NOW() - proposetime > INTERVAL ?",
				PROPOSAL_TIMEOUT,
			);

			for my $election (@$to_timeout)
			{
				$election->{DBH} = $self->{DBH};
				bless $election, ref($self);
				$election->_Timeout;
			}

			my $to_close = $sql->SelectListOfHashes(
				"SELECT * FROM automod_election WHERE status = 3
					AND NOW() - opentime > INTERVAL ?",
				VOTING_TIMEOUT,
			);

			for my $election (@$to_close)
			{
				$election->{DBH} = $self->{DBH};
				bless $election, ref($self);
				$election->_Close;
			}
		},
	);
}

sub _Timeout
{
	my $self = shift;
	my $sql = Sql->new($self->{DBH});

	$sql->Do(
		"UPDATE automod_election SET status = 5, closetime = NOW() WHERE id = ?",
		$self->GetId,
	);

	$self->{status} = 5;
	# NOTE closetime not set

	$self->SendTimeoutEmail;
}

sub _Close
{
	my $self = shift;
	my $sql = Sql->new($self->{DBH});

	$self->{status} = (($self->GetYesVotes > $self->GetNoVotes) ? 4 : 5);
	# NOTE closetime not set

	$sql->Do(
		"UPDATE automod_election SET status = ?, closetime = NOW() WHERE id = ?",
		$self->{status},
		$self->GetId,
	);

	if ($self->{status} == 4)
	{
		$self->SendAcceptedEmail;
	} else {
		$self->SendRejectedEmail;
	}
}

################################################################################
# The guts of the system: propose, second, cast vote, cancel
################################################################################

sub Propose
{
	my ($self, $proposer, $candidate) = @_;
	my $sql = Sql->new($self->{DBH});

	$@ = "ALREADY_AN_AUTOMOD", return
		if $candidate->IsAutoMod($candidate->GetPrivs);

	$sql->Do("LOCK TABLE automod_election IN EXCLUSIVE MODE");

	my $id = $sql->SelectSingleValue(
		"SELECT id FROM automod_election WHERE candidate = ?
			AND status IN (1,2,3)",
		$candidate->GetId,
	);
	$@ = "EXISTING_ELECTION $id", return
		if $id;

	$sql->Do(
		"INSERT INTO automod_election (candidate, proposer) VALUES (?, ?)",
		$candidate->GetId,
		$proposer,
	);
	$id = $sql->GetLastInsertId("automod_election");

	$self = $self->newFromId($id);
	$self->SendProposalEmail;
	$self;
}

sub Second
{
	my ($self, $seconder) = @_;
	my $sql = Sql->new($self->{DBH});

	$sql->Do("LOCK TABLE automod_election IN EXCLUSIVE MODE");
	$self->_Refresh
		or $@ = "NO_SUCH_ELECTION", return;

	$@ = "ELECTION_CLOSED", return
		if $self->{status} =~ /[456]/;

	$@ = "ALREADY_SECONDED", return
		if $self->{status} eq "3";

	my $propsec = grep { ($self->{$_}||0) == $seconder }
		qw( proposer seconder_1 seconder_2 );
	$@ = "INELIGIBLE", return
		if $propsec;

	$sql->Do(
		"UPDATE automod_election
			SET seconder_1 = ?, status = '2'
			WHERE id = ? AND status = '1'",
		$seconder,
		$self->GetId,
	) and do {
		$self->{seconder_1} = $seconder;
		$self->{status} = 2;
		return $self;
	};

	$sql->Do(
		"UPDATE automod_election
			SET seconder_2 = ?, status = '3', opentime = NOW()
			WHERE id = ? AND status = '2'",
		$seconder,
		$self->GetId,
	) and do {
		$self->{seconder_2} = $seconder;
		$self->{status} = 3;
		$self->SendVotingOpenEmail;
		return $self;
	};

	die;
}

sub CastVote
{
	my ($self, $voter, $new_vote) = @_;
	my $sql = Sql->new($self->{DBH});

	$sql->Do("LOCK TABLE automod_election, automod_election_vote IN EXCLUSIVE MODE");
	$self->_Refresh
		or $@ = "NO_SUCH_ELECTION", return;

	$@ = "VOTING_CLOSED", return
		if $self->{status} =~ /[456]/;
	$@ = "VOTING_NOT_YET_OPEN", return
		if $self->{status} =~ /[12]/;

	my $propsec = grep { ($self->{$_}||0) == $voter }
		qw( proposer seconder_1 seconder_2 );
	$@ = "INELIGIBLE", return
		if $propsec;

	my $old_vote = $sql->SelectSingleRowHash(
		"SELECT * FROM automod_election_vote
			WHERE automod_election = ? AND voter = ?",
		$self->GetId,
		$voter,
	);

	$@ = "NO_CHANGE", return 1
		if $old_vote
		and $old_vote->{vote} == $new_vote;

	if ($old_vote) {
		$sql->Do(
			"UPDATE automod_election_vote SET vote = ?, votetime = NOW() WHERE id = ?",
			$new_vote,
			$old_vote->{id},
		);
	} else {
		$sql->Do(
			"INSERT INTO automod_election_vote (automod_election, voter, vote) VALUES (?, ?, ?)",
			$self->GetId,
			$voter,
			$new_vote,
		);
	}

	my $yesdelta = my $nodelta = 0;
	--$yesdelta if $old_vote and $old_vote->{vote} == &ModDefs::VOTE_YES;
	--$nodelta if $old_vote and $old_vote->{vote} == &ModDefs::VOTE_NO;
	++$yesdelta if $new_vote == &ModDefs::VOTE_YES;
	++$nodelta if $new_vote == &ModDefs::VOTE_NO;

	$sql->Do(
		"UPDATE automod_election SET yesvotes = yesvotes + ?,
		novotes = novotes + ? WHERE id = ?",
		$yesdelta,
		$nodelta,
		$self->GetId,
	);

	$@ = ($old_vote ? "VOTE_CHANGED" : "VOTE_CAST");
	1;
}

sub Cancel
{
	my ($self, $canceller) = @_;
	my $sql = Sql->new($self->{DBH});

	$sql->Do("LOCK TABLE automod_election IN EXCLUSIVE MODE");
	$self->_Refresh
		or $@ = "NO_SUCH_ELECTION", return;

	$@ = "NOT_PROPOSED_BY_YOU", return
		unless $self->GetProposer == $canceller;

	$@ = "VOTING_CLOSED", return
		if $self->GetStatus =~ /[456]/;

	$sql->Do(
		"UPDATE automod_election
			SET status = 6, closetime = NOW()
			WHERE id = ? AND status IN (1,2,3)",
		$self->GetId,
	) or die;

	$self->{status} = 6;
	# NOTE closetime is not set
	$self->SendCancelEmail;

	1;
}

################################################################################
# E-mail sending section.  Here we post to the mb-automods mailing list to
# notify all automods when something relevant has happened.
################################################################################

sub _PrepareMail
{
	my $self = shift;

	(my $nums = $self->{proposetime}) =~ tr/0-9//cd;
	my $id = $self->GetId;
	$self->{message_id} = "<automod-election-$id-$nums\@musicbrainz.org>";

	my $us = UserStuff->new($self->{DBH});
	for my $key (qw( candidate proposer seconder_1 seconder_2 ))
	{
		my $id = $self->{$key}
			or next;
		my $them = $us->newFromId($id)
			or next;
		$self->{$key."_user"} = $them;
		$self->{$key."_name"} = $them->GetName;
		$self->{$key."_link"} = sprintf "http://%s/user/view.html?uid=%d",
			&DBDefs::WEB_SERVER, $them->GetId;
	}

	$self->{subject} = "Automod Election: $self->{candidate_name}";
	$self->{election_link} = sprintf "http://%s/user/election/show.html?id=%d",
		&DBDefs::WEB_SERVER, $self->GetId;
}

sub SendProposalEmail
{
	my $self = shift;
	$self->_PrepareMail;

	my $timeout = PROPOSAL_TIMEOUT;

	$self->_SendMail(
		is_reply	=> 0,
		Data		=> <<EOF,
A new candidate has been put forward for automoderator status:

Candidate: $self->{candidate_name}
           $self->{candidate_link}
Proposer:  $self->{proposer_name}
           $self->{proposer_link}

* If two seconders are found within $timeout, voting will begin
* Otherwise, the proposal will automatically be rejected
* Alternatively, the $self->{proposer_name} may withdraw the proposal

Please participate:
$self->{election_link}

EOF
	);
}

sub SendVotingOpenEmail
{
	my $self = shift;
	$self->_PrepareMail;

	my $timeout = VOTING_TIMEOUT;

	$self->_SendMail(
		is_reply	=> 1,
		Data		=> <<EOF,
Voting in this election is now open:

Candidate: $self->{candidate_name}
           $self->{candidate_link}
Proposer:  $self->{proposer_name}
           $self->{proposer_link}
Seconder:  $self->{seconder_1_name}
           $self->{seconder_1_link}
Seconder:  $self->{seconder_2_name}
           $self->{seconder_2_link}

* Voting will now remain open for the next $timeout
* Alternatively, the $self->{proposer_name} may withdraw the proposal

Please participate:
$self->{election_link}

EOF
	);
}

sub SendAcceptedEmail
{
	my $self = shift;
	$self->_PrepareMail;

	$self->_SendMail(
		is_reply	=> 1,
		Data		=> <<EOF,
Voting in this election is now closed: $self->{candidate_name} has been
accepted as an auto-moderator.  Congratulations!

Details:
$self->{election_link}

Thank you to everyone who took part.

EOF
	);
}

sub SendRejectedEmail
{
	my $self = shift;
	$self->_PrepareMail;

	$self->_SendMail(
		is_reply	=> 1,
		Data		=> <<EOF,
Voting in this election is now closed: the proposal to make
$self->{candidate_name} an auto-moderator was rejected.

Details:
$self->{election_link}

Thank you to everyone who took part.

EOF
	);
}

sub SendTimeoutEmail
{
	my $self = shift;
	$self->_PrepareMail;

	my $timeout = PROPOSAL_TIMEOUT;

	$self->_SendMail(
		is_reply	=> 1,
		Data		=> <<EOF,
This election has been cancelled, because two seconders could not be
found within the allowed time ($timeout).

Details:
$self->{election_link}

EOF
	);
}

sub SendCancelEmail
{
	my $self = shift;
	$self->_PrepareMail;

	$self->_SendMail(
		is_reply	=> 1,
		Data		=> <<EOF,
This election has been cancelled by the proposer ($self->{proposer_name}).

Details:
$self->{election_link}

EOF
	);
}

sub _SendMail
{
	my ($self, %opts) = @_;

	$opts{Subject} ||= $self->{subject};
	$opts{Sender} ||= 'Webserver <webserver@musicbrainz.org>';
	$opts{From} = 'The Returning Officer <noreply@musicbrainz.org>';
	$opts{To} = 'mb-automods Mailing List <musicbrainz-automods@lists.musicbrainz.org>';
	$opts{Type} ||= "text/plain";
	$opts{Encoding} ||= "quoted-printable";

	my $is_reply = delete $opts{is_reply};
	if ($is_reply) {
		$opts{"In-Reply-To"} ||= $self->{message_id};
		$opts{"References"} ||= $self->{message_id};
	} elsif (defined $is_reply) {
		$opts{"Message-ID"} ||= $self->{message_id};
	}

	require MusicBrainz::Server::Mail;
	my $entity = MusicBrainz::Server::Mail->new(%opts);
    $entity->attr("content-type.charset" => "utf-8");

	$entity->send(
		'webserver@musicbrainz.org',
		'musicbrainz-automods@lists.musicbrainz.org',
	);
}

################################################################################
# The Vote class
################################################################################

package MusicBrainz::Server::AutomodElection::Vote;

use base qw( TableBase );
use Carp;
use ModDefs ':vote', 'STATUS_OPEN';

# GetId / SetId - see TableBase
sub GetElection		{ $_[0]{automod_election} }
sub GetVoter		{ $_[0]{voter} }
sub GetVote			{ $_[0]{vote} }
sub GetVoteTime		{ $_[0]{votetime} }

sub _newFromElection
{
	my ($class, $election) = @_;
	my $sql = Sql->new($election->{DBH});

	my $votes = $sql->SelectListOfHashes(
		"SELECT * FROM automod_election_vote WHERE automod_election = ? ORDER BY votetime",
		$election->GetId,
	);

	for (@$votes)
	{
		$_->{DBH} = $election->{DBH};
		bless $_, $class;
	}

	$votes;
}

my %VoteText = (
    &ModDefs::VOTE_UNKNOWN	=> "Unknown",
    &ModDefs::VOTE_NOTVOTED	=> "Not voted",
    &ModDefs::VOTE_ABS		=> "Abstain",
    &ModDefs::VOTE_YES		=> "Yes",
    &ModDefs::VOTE_NO		=> "No"
);

sub GetVoteName
{
	my ($self, $vote) = @_;
	$vote = $self->GetVote unless defined $vote;
	$VoteText{$vote};
}

1;
# eof AutomodElection.pm