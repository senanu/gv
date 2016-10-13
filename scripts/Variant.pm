#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use JSON;
use Data::Dumper;
use Region;



package Variant;

sub new{
    my $class = shift;
    my $self  = shift;
    bless $self, $class;
    while ( scalar(@{$self->{data}}) > 0) {
        push @{$self->{regions}}, new Region(pop($self->{data}));
    }
    if ( scalar(@{$self->{data}}) == 0) {
        delete $self->{data};
    }
    $self->_calculateBasesMapped();
    $self->_countNumRegions();
    $self->_calculateEnds();
    $self->_countInversions();
    $self->_calcMappedChromosome();
    
    return $self;
}

sub _triggerCalculationsWithExternalData{
    my $self = shift;
    if ( defined $self->{original_end_attempted} &&
             defined $self->{original_start_attempted}) {
        if ( ! defined $self->{basesUnmapped}) {
            $self->_calcBasesUnmapped();
        }
    }
}


sub _calculateBasesMapped{
    my $self = shift;
    my $length = 0;
    foreach my $region (@{$self->{regions}}) {
        $length += $region->getMappedBases();
    }
    $self->{mapped_bases} = $length;
    return;
}

sub getBasesMapped{
    my $self = shift;
    return $self->{mapped_bases};
}

sub _countNumRegions{
    my $self = shift;
    $self->{num_regions} = scalar(@{$self->{regions}});
    return;
}

sub getNumRegions{
    my $self = shift;
    return $self->{num_regions};
}

sub _countInversions{
    my $self = shift;
    my $inversions = 0;
    foreach my $region (@{$self->{regions}}){
        $inversions += $region->isInversion();
    }
    $self->{inversions} = $inversions;
    return;
}

sub getInversions{
    my $self = shift;
    return $self->{inversions};
}

sub _calculateEnds{
    ## Calculate mapped and original ends. Necessary if broken into regions
    my $self = shift;
    my $start;
    my $end  ;
    my $original_start;
    my $original_end;
    foreach my $region (@{$self->{regions}}) {
        if ( defined($start)) {
            $start = $region->getStart() < $start ? $region->getStart() : $start;
        } else {
            $start = $region->getStart();
        }
        if ( defined($end)) {
            $end   = $region->getEnd() > $end ? $region->getEnd() : $end;
        } else {
            $end = $region->getEnd();
        }
        if ( defined($original_start)) {
            $original_start =
                $region->getOriginalStart() < $original_start ?
                $region->getOriginalStart() : $original_start;
        } else {
            $original_start = $region->getOriginalStart();
        }
        if ( defined($original_end)) {
            $original_end   =
                $region->getOriginalEnd() > $original_end ?
                $region->getOriginalEnd() : $original_end;
        } else {
            $original_end = $region->getOriginalEnd();
        }
    }
    $self->{original_start} = $original_start;
    $self->{original_end}   = $original_end;
    $self->{start} = $start;
    $self->{end}   = $end;
    return;
}

sub setOriginalStartAttempted{
    ## Set the start that was attempted to be mapped. This comes
    ## from an external source and may not be what was
    ## successfully mapped
    my $self = shift;
    my $start = shift;
    $start =~ s/^\s+//;
    $start =~ s/\s+$//;
    $self->{original_start_attempted} = $start;
    return;
}

sub setOriginalEndAttempted{
    ## Set the end that was attempted to be mapped. This comes
    ## from an external source and may not be what was
    ## successfully mapped
    my $self = shift;
    my $end  = shift;
    $end =~ s/^\s+//;
    $end =~ s/\s+$//;
    $self->{original_end_attempted} = $end;
    return;
}

sub _isStartMapped{
    my $self = shift;
    if (( defined $self->{original_start_attempted} ) &&
            ($self->{original_start} == $self->{original_start_attempted})){
        return 1;
    } else {
        return 0;
    }
}

sub _isEndMapped{
    my $self = shift;
    if (( defined $self->{original_end_attempted} ) &&
            ($self->{original_end} == $self->{original_end_attempted})){
        return 1;
    } else {
        return 0;
    }
}

sub isStartEndMapped{
    my $self = shift;
    if ($self->_isStartMapped() && $self->_isEndMapped()) {
        return "Both";
    } elsif ( $self->_isStartMapped()) {
        return "Start";
    } elsif ( $self->_isEndMapped()) {
        return "End";
    } else {
        return "Neither";
    }
}



sub getStart{
    my $self = shift;
    return $self->{start};
}

sub getEnd{
    my $self = shift;
    return $self->{end};
}

sub _calcMappedChromosome{
    my $self = shift;
    my $chr;
    foreach my $region (@{$self->{regions}}) {
        if ( ! defined $chr) {
            $chr = $region->getChromosome();
        } else {
            if ($chr ne $region->getChromosome()) {
                $self->{chromosome} = "multiple";
                return;
            } else {
                # chr matches so do nothing
            }
        }
    }
    $self->{chromosome} = $chr;
    return;
}

sub getMappedChromosome{
    my $self = shift;
    return $self->{chromosome};
}

sub _calcBasesUnmapped{
    my $self = shift;
    if ( defined $self->{original_start_attempted} &&
             defined $self->{original_end_attempted}) {
        $self->{original_length_attempted} =
            $self->{original_end_attempted} -
            $self->{original_start_attempted} + 1;
        $self->{bases_unmapped} =
            $self->{original_length_attempted} -
            $self->{mapped_bases};
    }
}

sub getBasesUnmapped{
    my $self = shift;
    $self->_triggerCalculationsWithExternalData();
    return $self->{bases_unmapped};
}

sub isPerfectMapping{
    my $self = shift;
    $self->_triggerCalculationsWithExternalData();
    if ( ($self->getMappedChromosome()  ne "multiple") &&
             ($self->getNumRegions()    == 1)          &&
             ($self->getBasesUnmapped() == 0)          &&
             ($self->getInversions()    == 0)          &&
             ($self->isStartEndMapped() eq 'Both')) {
        $self->{perfect_mapping} = 1;
        return 1;
    } else {
        $self->{perfect_mapping} = 0;
        return 0;
    }
}



1;
