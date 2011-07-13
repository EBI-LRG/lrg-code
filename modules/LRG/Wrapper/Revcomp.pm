#! perl -w

###
# A wrapper for the S. Eddy revcomp utility
# 

use strict;
use warnings;
use LRG::Wrapper::Executable;

package Revcomp;

our @ISA = "LRG::Wrapper::Executable";

# Some default parameters
sub defaults {
    return {
        'executable' => 'revcomp'
    }; 
}

sub permitted {
    my $self = shift;
    return [
        @{$self->SUPER::permitted()},
        'inputfile'
    ];
}

sub parameters {
    my $self = shift;
 
    return [$self->inputfile()];
}

1;
