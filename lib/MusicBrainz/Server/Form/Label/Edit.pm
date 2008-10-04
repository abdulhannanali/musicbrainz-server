package MusicBrainz::Server::Form::Label::Edit;

use strict;
use warnings;

use base 'MusicBrainz::Server::Form';

sub profile
{
    return {
        required => {
            name       => 'Text',
            sort_name  => 'Text',
            type       => 'Select',
        },
        optional => {
            begin_date => '+MusicBrainz::Server::Form::Field::Date',
            end_date   => '+MusicBrainz::Server::Form::Field::Date',
            label_code => '+MusicBrainz::Server::Form::Field::LabelCode',
            edit_note  => 'TextArea',
            country    => 'Select',

            # We make this required if duplicates are found,
            # or if a resolution is present when we edit the artist.
            resolution => {
                type             => 'Text',
                required_message => 'A label with this name already exists. '.
                                    'Please enter a comment about this label for disambiguation',
            },
        }
    };
}

sub options_country
{
    my $self = shift;

    my $mb = new MusicBrainz;
    $mb->Login;

    my $c = MusicBrainz::Server::Country->new($mb->{DBH});

    return map { $_->id => $_->name } $c->All;
}

sub options_type
{
    my $types = MusicBrainz::Server::Label::GetLabelTypes;

    return map {
        $_->[0] => sprintf("%s%s", $_->[3] ? '&nbsp;&nbsp;' : '', $_->[1]),
    } @$types;
}

=head2 model_validate

If the new label name already exists, make sure that the resolution field
is required

=cut

sub model_validate
{
    my $self = shift;

    my $label  = MusicBrainz::Server::Label->new($self->context->mb->{DBH});
    my $labels = $label->GetLabelsFromName($self->value('name'));

    my @dupes = grep { $_->id != $self->item_id } @$labels;

    if (scalar @dupes)
    {
        $self->field('resolution')->required(1);
        $self->field('resolution')->validate_field;
    }
}

sub init_value
{
    my $self = shift;
    my ($field, $item) = @_;

    $item ||= $self->item;

    return unless defined $item;

    if ($field->name eq 'resolution' && $item->resolution)
    {
        $field->required(1);
    }

    $self->SUPER::init_value(@_);
}

1;
