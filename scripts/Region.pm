#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use JSON;
use Data::Dumper;


package Region;

sub new{
    my $class = shift;
    my $self  = shift;

    bless $self, $class;
    $self->_calculateMappedBases();
    return $self;
}

sub _calculateMappedBases{
    my $self = shift;
    $self->{mapped_bases} = $self->{mapped}->{end} - $self->{mapped}->{start} + 1;
    return;
}

sub getMappedBases{
    my $self = shift;
    return $self->{mapped_bases};
}

sub getStart{
    my $self = shift;
    return $self->{mapped}->{start};
}

sub getEnd{
    my $self = shift;
    return $self->{mapped}->{end};
}

sub getOriginalStart{
    my $self = shift;
    return $self->{original}->{start};
}

sub getOriginalEnd{
    my $self = shift;
    return $self->{original}->{end};
}


sub isInversion{
    my $self = shift;
    return $self->{mapped}->{strand} == -1;
}

sub getChromosome{
    my $self = shift;
    return $self->{mapped}->{seq_region_name};
}



1;
