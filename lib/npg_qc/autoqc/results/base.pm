package npg_qc::autoqc::results::base;

use Moose;
use namespace::autoclean;
use Carp;

use npg_tracking::glossary::composition;
use npg_tracking::glossary::composition::component::illumina;

with 'npg_tracking::glossary::composition::factory::attributes' =>
  {component_class => 'npg_tracking::glossary::composition::component::illumina'};
with 'npg_qc::autoqc::role::result';

our $VERSION = '0';

sub BUILD {
  my $self = shift;
  $self->composition();
  return;
}

has 'composition' => (
    is         => 'ro',
    isa        => 'npg_tracking::glossary::composition',
    required   => 0,
    lazy_build => 1,
    handles   => {
      'composition_digest' => 'digest',
      'num_components'     => 'num_components',
    },
    predicate  => 'has_composition',
);
sub _build_composition {
  my $self = shift;
  if ($self->is_old_style_result) {
    return $self->create_composition();
  }
  croak 'Can only build old style results';
}

around 'pack' => sub {
  my ($old, $self) = @_;
  my $packed = $self->$old();
  foreach my $key (keys $packed->{'composition'}) {
    if ($key =~ /\A_[[:lower:]]/smx) {
      delete $packed->{'composition'}->{$key};
    }
  }
  return $packed;
};

around 'freeze' => sub {
  my ($old, $self) = @_;
  $self->composition->freeze(); # Integrity check
  return $self->$old()
};

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

npg_qc::autoqc::results::base

=head1 SYNOPSIS

=head1 DESCRIPTION

A composition-based parent object for autoqc result objects.

=head1 SUBROUTINES/METHODS

=head2 BUILD

Default object constructor extension that is called after the object is created,
but before it is returned to the caller. Builds the composition accessor.

=head2 composition

A npg_tracking::glossary::composition object. If the derived
class inplements id_run and position methods/attributes, a one-component
composition is created automatically.

=head2 pack

This method that is inherited from MooseX::Storage via npg_qc::autoqc::role::result. It
creates a hash representation of the object is extended to disregard private attributes
of the composition object.

=head2 freeze

This method that is inherited from MooseX::Storage via npg_qc::autoqc::role::result. It
returns JSON string serialization of the object. Error if the object lost integrity, ie
its composition changed.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item namespace::autoclean

=item Carp

=item npg_tracking::glossary::composition

=item npg_tracking::glossary::composition::factory::attributes

=item npg_tracking::glossary::composition::component::illumina

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 GRL

This file is part of NPG.

NPG is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
