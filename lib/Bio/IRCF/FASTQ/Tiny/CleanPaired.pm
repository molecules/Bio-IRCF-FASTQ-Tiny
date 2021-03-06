#!/bin/env perl
package Bio::IRCF::FASTQ::Tiny::CleanPaired;

# ABSTRACT: remove singletons from paired FASTQ files (assumes both pairs have a record for each sequence, but some may be empty or "too-short")
use strict;
use warnings;
use v5.10;

#NOTE: Be sure to compare FastQC from original and trimmed

use Bio::IRCF::FASTQ::Tiny qw( iterator coderef_print_entry open_output);

my $filename_R1 = shift;
my $filename_R2 = shift;

my $MIN_LENGTH = shift // 50;

my $R1_it = iterator($filename_R1);
my $R2_it = iterator($filename_R2);

my $print_R1            = __print_fh_out_for($filename_R1);
my $print_R2            = __print_fh_out_for($filename_R2);
my $print_R1_singlteons = __print_singleton_fh_out_for($filename_R1);
my $print_R2_singlteons = __print_singleton_fh_out_for($filename_R2);

while ( (my $R1_seq_obj = $R1_it->()) && (my $R2_seq_obj = $R2_it->()) ) {

    my $R1_seq = $R1_seq_obj->{seq};
    my $R2_seq = $R2_seq_obj->{seq};

    # Remove R1 sequence if it is under the minimum length
    if (length($R1_seq) < $MIN_LENGTH || $R1_seq =~ m{ \A N+ \z}xms ) { $R1_seq = $R1_seq_obj->{seq} = '' }

    # Remove R2 sequence if it is under the minimum length
    if (length($R2_seq) < $MIN_LENGTH || $R2_seq =~ m{ \A N+ \z}xms ) { $R2_seq = $R2_seq_obj->{seq} = '' }

    # skip writing if both reads are empty
    # # TODO count this occurrence
    next if ! ($R1_seq_obj->{seq} || $R2_seq_obj->{seq} );
    
    if ($R1_seq_obj->{seq} && $R2_seq_obj->{seq} ) {
        $print_R1->($R1_seq_obj);
        $print_R2->($R2_seq_obj);
    }
    elsif($R1_seq_obj->{seq}) {
        $print_R1_singlteons->($R1_seq_obj);
    }elsif($R2_seq_obj->{seq}) {
        $print_R2_singlteons->($R2_seq_obj);
    }
}

# Both iterators should have exhausted at the same time
if ( $R1_it->() || $R2_it->() ) {
    die "FASTQ files do not have the same number of records!!!!!!!!";
}

# pause to let IO catch up?
system("sleep 1");

#finished
exit;

sub __print_singleton_fh_out_for {
    my $basename = shift;
    $basename =~ s/ \.gz \z//xms;
    $basename =~ s/ \.fastq \z//xms;
    $basename =~ s/ \.fq \z//xms;
    my $fh_out = open_output("$basename.orphans.fastq.gz");
    return coderef_print_entry($fh_out);
}

sub __print_fh_out_for {
    my $basename = shift;
    $basename =~ s/ \.gz \z//xms;
    $basename =~ s/ \.fastq \z//xms;
    $basename =~ s/ \.fq \z//xms;
    my $fh_out = open_output("$basename.good_paired.fastq.gz");
    return coderef_print_entry($fh_out);
}
