package t::autoqc_util;

use strict;
use warnings;
use Carp;
use English qw(-no_match_vars);
use Exporter;
use File::Temp qw(tempdir);
use File::Path qw/make_path/;

use npg_tracking::glossary::composition::factory;
use npg_tracking::glossary::composition::component::illumina;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
                      write_bwa_script
                      write_samtools_script
                   );

sub find_or_save_composition {
  my ($schema, $h) = @_;

  my $component_rs   = $schema->resultset('SeqComponent');
  my $composition_rs = $schema->resultset('SeqComposition');
  my $com_com_rs     = $schema->resultset('SeqComponentComposition');

  my @temp = %{$h};
  my %temp_hash = @temp;
  my $component_h = \%temp_hash;

  my $component =
    npg_tracking::glossary::composition::component::illumina->new($component_h);
  my $f = npg_tracking::glossary::composition::factory->new();
  $f->add_component($component);
  my $composition = $f->create_composition();
  my $composition_digest = $composition->digest;
  my $composition_row = $composition_rs->find({digest => $composition_digest});
  if (!$composition_row) {
    $component_h->{'digest'} = $component->digest;
    my $component_row = $component_rs->create($component_h);
    $composition_row = $composition_rs->create(
      {size => 1, digest => $composition_digest});
    $com_com_rs->create({size               => 1,
                         id_seq_component   => $component_row->id_seq_component,
                         id_seq_composition => $composition_row->id_seq_composition
                       });
  }
  return $composition_row->id_seq_composition;
}

sub write_samtools_script {
  my ($script_path, $b1) = @_;
  
  open my $fh, '>', $script_path or croak "Cannot open $script_path for writing";

  print $fh '#!/usr/local/bin/bash';
  print $fh "\n";
  print $fh '# Script to fake samtools in testing. Automatically generated by npg at ' . time;
  print $fh "\n";

  if (defined $b1) {
    print $fh "cat $b1\n";
  }else{
    print $fh "echo 'Version: 0.5.5 (r1273)'\n";
  }

  close $fh or carp "Cannot close $script_path";
    
  chmod 0775, $script_path;
  return 1;
}

sub write_fastx_script {

  my ($script_path, $b1) = @_;
  
  my $fh;
  open($fh, '>', $script_path) or croak "Cannot open $script_path for writing";

  print $fh '#!/usr/local/bin/bash';
  print $fh "\n";
  print $fh '# Script to fake fastx in testing. Automatically generated by npg at ' . time;
  print $fh "\n";

  # echo the first argument $1;
  # echo number of arguments: $#;
  if (!defined $b1) {
    my $out = q[usage: fastx_reverse_complement [-h] [-r] [-z] [-v] [-i INFILE] [-o OUTFILE]
Part of FASTX Toolkit 0.0.12 by A. Gordon (gordon@cshl.edu)

   [-h]         = This helpful help screen.
   [-z]         = Compress output with GZIP.
   [-i INFILE]  = FASTA/Q input file. default is STDIN.
   [-o OUTFILE] = FASTA/Q output file. default is STDOUT.

];

    print $fh "echo '$out'";
  }

  close $fh;

  chmod 0775, $script_path;
  return 1;
}

sub write_bwa_script {

  my ($script_path, $s1, $bwa_version) = @_;
  
  my $fh;
  open($fh, '>', $script_path) or croak "Cannot open $script_path for writing";

  print $fh '#!/usr/local/bin/bash';
  print $fh "\n";
  print $fh '# Script to fake BWA tool in testing. Automatically generated by npg at ' . time;
  print $fh "\n";

  # echo the first argument $1;
  # echo number of arguments: $#;
  if (defined $s1) {
    print $fh 'if [ $# != 0 ]; then';
    print $fh "\n";
    print $fh 'if [ $1 == sampe ]; then';
    print $fh "\n";
    print $fh "cat $s1\n";
    print $fh "fi\n";
    print $fh "else\n";
    print $fh "echo 'Version: 0.5.5 (r1273)'\n";
    print $fh "fi\n";
  }else{
    print $fh "echo 'Version: 0.5.5 (r1273)'\n";
  }

  close $fh;
    
  chmod 0775, $script_path;
  return 1;
}

sub create_runfolder {
  my ($dir, $names) = @_;
  $dir   ||= tempdir(CLEANUP => 1);
  $names ||= {};
  my $rf_name = $names->{'runfolder_name'} || q[180524_A00510_0008_BH3W7VDSXX];
  my $apath = $names->{'analysis_path'}    || q[BAM_basecalls_20180714-103457];
  my $paths = {};
  $paths->{'runfolder_path'} = join q[/], $dir, $rf_name;
  $paths->{'intensity_path'} = join q[/], $paths->{'runfolder_path'}, q[Data/Intensities];
  $paths->{'basecall_path'}  = join q[/], $paths->{'intensity_path'}, q[BaseCalls];
  $paths->{'analysis_path'}  = join q[/], $paths->{'intensity_path'}, $apath;
  $paths->{'nocal_path'}     = join q[/], $paths->{'analysis_path'}, q[no_cal];
  $paths->{'archive_path'}   = join q[/], $paths->{'nocal_path'}, q[archive];

  make_path(values %{$paths});
  return $paths;
}

1;
