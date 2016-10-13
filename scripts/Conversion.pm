#!/usr/bin/env perl

=pod

=head1 NAME

Conversion.pm - a module for holding conversion objects and
statistics about them

=head1 SYNOPSIS

=cut
use strict;
use warnings;
use Carp;
use JSON;
use Data::Dumper;
use Variant;

package Conversion;

=pod

Initialization:
     my $convert = new Conversion('a.json', 'b.json', 'c.json');
     my $convert = new Conversion(@files);

=cut

sub new{
    my $class = shift;
    my $self  =  {files => [@_]} ;
    bless $self, $class;
    foreach my $file (@{$self->{files}}) {
        Conversion::_read_file($self, $file);
    }
    return $self;
}

sub getVariant{
    my $self = shift;
    my $variant_name = shift;
    return $self->{variants}->{$variant_name};
}


=pod

B<_read_file> Read in a single file into the object

=cut

sub _read_file{
    my ($self, $file) = @_;
    
    my $dat = $self->_slurp($file);
    my $count = 0;
    
    foreach my $variant (keys %$dat) {
        if ( defined $dat->{$variant}) {
            $self->{variants}->{$variant} = Variant->new({name => $variant,
                                                          data => $dat->{$variant}});
        } 
    }
    
    
    return;
}

sub _slurp{
    my ($self, $file) = @_;
    open (my $in, "<", $file) or die "File $file not found\n";
    local $/=undef;
    my $raw = <$in>;
    my $map = JSON::from_json($raw);
    return $map;
}








1;





__END__


=item B<new>

Initialize an object using 

=back

=head1 DESCRIPTION



=head1 SEE ALSO

=head1 AUTHOR

Senanu Spring-Pearson Senanu.Pearson --at-- gmail.com

=cut
