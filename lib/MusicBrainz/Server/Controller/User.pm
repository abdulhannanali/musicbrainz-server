package MusicBrainz::Server::Controller::User;

use strict;
use warnings;

use base 'MusicBrainz::Server::Controller';

use MusicBrainz;
use MusicBrainz::Server::Editor;
use UserPreference;

=head1 NAME

MusicBrainz::Server::Controller::User - Catalyst Controller to handle
user authentication and profile management

=head1 DESCRIPTION

The user controller handles users logging in and logging out, the
registration or administration of accounts, and the viewing/updating of
profile pages.

=head1 METHODS

=head2 index

If the user is currently logged in redirect them to their profile page,
otherwise redirect the user to the login page.

=cut

sub index : Private
{
    my ($self, $c) = @_;

    $c->forward('login');
    $c->detach('profile', [ $c->user->name ]);
}

=head2 login

Display a form allowing users to login. If a POST request is received,
we validate this login data, and attempt to log the user in.

=cut

sub login : Private
{
    my ($self, $c) = @_;

    return 1
        if MusicBrainz::Server::Editor->TryAutoLogin($c);

    return 1
        if $c->user_exists;

    use MusicBrainz::Server::Form::User::Login;
    my $form = $self->form(MusicBrainz::Server::Form::User::Login->new());
    $c->stash->{template} = 'user/login.tt';
    $c->stash->{form} = $self->form;

    $c->detach unless $self->submit_and_validate($c);

    my ($username, $password) = ( $form->value("username"),
                                  $form->value("password") );

    if( !$c->authenticate({ username => $username,
                            password => $password }) )
    {
        $c->stash->{errors} = ['Username/password combination invalid'];
        $c->detach;
    }
    else
    {
        if ($form->value('remember_me'))
        {
            $c->user->SetPermanentCookie($c,
                only_this_ip => $form->value('single_ip'));
        }
    }
}

sub login_form : Local Path('login')
{
    my ($self, $c) = @_;

    my $referer = $c->req->referer;
    if (!defined $c->session->{__login_dest})
    {
        $c->session->{__login_dest} = $referer;
    }

    $c->forward('/user/login');

    $referer = $c->session->{__login_dest};
    $c->session->{__login_dest} = undef;
    $c->response->redirect($referer);
}

=head2 register

Display a form allowing new users to register on the site. When a POST
request is received, we validate the data and attempt to create the
new user.

=cut

sub register : Local
{
    my ($self, $c) = @_;

    $c->detach('profile', [ $c->user->name ])
        if $c->user_exists;

    my $form = $c->form(undef, 'User::Register');
    $c->stash->{form} = $form;

    return unless $c->form_posted && $form->validate($c->request->parameters);

    my $new_user = $c->model('User')->create($form->value('username'),
                                             $form->value('password'));

    my $email            = $form->value('email');
    my $could_send_email = $new_user->SendVerificationEmail($email);

    $c->authenticate({ username => $new_user->username,
                       password => $new_user->password });

    $c->detach('registered', $could_send_email, $email);
}

=head2 registered

Called when a user has completed registration. We use this to notify
the user that everything went ok.

=cut

sub registered : Private
{
    my ($self, $c, $couldSend, $email) = @_;

    $c->stash->{emailed} = $couldSend;
    $c->stash->{email}   = $email;

    $c->stash->{template} = 'user/registered.tt';
}

=head2 forgotPassword

Allow users to retrieve their password if they have forgotten it.

This displays a form allowing the user to enter either their username
or email address in. With this data we then attempt to email the user
their password.

=cut

sub forgot_password : Local
{
    my ($self, $c) = @_;

    my $form = $c->form(undef, 'User::ForgotPassword');
    $form->context($c);

    return unless $c->form_posted && $form->validate($c->req->params);

    my ($email, $username) = ( $form->value('email'),
                               $form->value('username') );

    if ($email)
    {
        my $usernames = $c->model('User')->find_by_email($email);
        if(scalar @$usernames)
        {
            foreach $username (@$usernames)
            {
                my $user = $c->model('User')->load({ username => $username });
                if ($user)
                {
                    $user->SendPasswordReminder
                        or die "Could not send password reminder";
                }
            }

            $c->flash->{ok} = "A password reminder has been sent to you."
                            . "Please check your inbox for more details";
        }
        else
        {
            $c->field('email')->add_error('We could not find any users registered with this email address');
        }
    }
    elsif ($username)
    {
        my $user = $c->model('User')->load({ username => $username });
        if ($user)
        {
            $user->SendPasswordReminder
                or die "Could not send password reminder";

            $c->flash->{ok} = "A password reminder has been sent to you. Please check your inbox for more details";
        }
    }
}

=head2 edit

Display a form to allow users to edit their profile, or (if a POST
request is received), update the profile data in the database.

=cut

sub edit : Local Form('User::EditProfile')
{
    my ($self, $c) = @_;

    $c->forward('login');

    my $form = $self->form;
    $form->init($c->user);

    return unless $self->submit_and_validate($c);

    $form->update_model;

    $c->flash->{ok} = "Your profile has been sucessfully updated";
}

=head2 changePassword

Allow users to change their password. This displays a form prompting
for their old password and a new password (with confirmation), which
when use to update the database data when we receive a valid POST request.

=cut

sub change_password : Local
{
    my ($self, $c) = @_;

    $c->forward('login');

    my $form = $c->form(undef, 'User::ChangePassword');

    return unless $c->form_posted && $form->validate($c->req->params);
    if ($form->value('old_password') eq $c->user->password)
    {
        $c->user->ChangePassword( $form->value('old_password'),
                                  $form->value('new_password'),
                                  $form->value('confirm_new_password') );

        $c->flash->{ok} = "Your password has been successfully changed";
    }
    else
    {
        $form->field('old_password')->add_error("Old password is incorrect.");
    }
}

=head2 profile

Display a users profile page.

=cut

sub profile : Local Args(1)
{
    my ($self, $c, $user_name) = @_;

    my $user = $c->model('User')->load({ username => $user_name });

    if (!defined $user)
    {
        $c->response->status(404);
        $c->error("User with user name $user_name not found");
        $c->detach;
    }

    if ($c->user_exists && $c->user->id eq $user->id)
    {
        $c->stash->{viewing_own_profile} = 1;
    }

    $c->stash->{user    } = $user;
    $c->stash->{template} = 'user/profile.tt';
}

=head2 logout

Logout the current user. Has no effect if the user is already logged out.

=cut

sub logout : Local
{
    my ($self, $c) = @_;

    if ($c->user_exists)
    {
        $c->user->ClearPermanentCookie($c);
        $c->logout;

        delete $c->session->{orig_privs};
        delete $c->session->{session_privs};
    }

    $c->response->redirect($c->uri_for('/'));
}

=head2 preferences

Change the users preferences

=cut

sub preferences : Local
{
    my ($self, $c) = @_;

    $c->forward('login');

    my $user  = $c->user;

    use MusicBrainz::Server::Form::User::Preferences;

    my $form = MusicBrainz::Server::Form::User::Preferences->new($user->id);
    $c->stash->{form} = $form;

    $form->update_from_form ($c->req->params)
        if($c->form_posted);

    $c->stash->{template} = 'user/preferences.tt';
}

=head2 donate

Check the status of donations and ask for one.

=cut

sub donate : Local
{
    my ($self, $c) = @_;

    $c->forward('login');

    my $user = $c->user;
    my @donateinfo = MusicBrainz::Server::Editor::NagCheck($user);

    $c->stash->{nag} = $donateinfo[0];
    $c->stash->{days} = int($donateinfo[1]);
    $c->stash->{template} = 'user/donate.tt';
}

=head2 verify

Verify the email address (this is the URL handed out in "verify your email
address" emails)

=cut

sub verify : Local
{
    my ($self, $c) = @_;

    my $user_id = $c->request->query_params->{user};
    my $email   = $c->request->query_params->{email};
    my $time    = $c->request->query_params->{time};
    my $key     = $c->request->query_params->{chk};

    die "The user ID is missing or, is in an invalid format"
        unless MusicBrainz::Server::Validation::IsNonNegInteger($user_id) && $user_id;

    die "The email address is missing"
        unless $email;

    die "The time is missing, or is in an invalid format"
        unless MusicBrainz::Server::Validation::IsNonNegInteger($time) && $time;

    die "The key is missing"
        unless $key;

    my $ui = MusicBrainz::Server::Editor->new($c->mb->{DBH});
    die "The checksum is invalid, please double check your email"
        unless $ui->GetVerifyChecksum($email, $user_id, $time) eq $key;

    if (($time + DBDefs::EMAIL_VERIFICATION_TIMEOUT) < time)
    {
        die "Sorry, this email verification link has expired";
    }
    else
    {
        my $user = $c->model('User')->load({ id => $user_id });

        die "User with id $user_id could not be found"
            unless $user;

        $user->SetUserInfo(email => $email)
            or die "Could not update user information";

        $c->stash->{template} = 'user/verified.tt';
    }
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
