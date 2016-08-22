package PatientData;
use strict;
use warnings FATAL => 'all';

sub GetPatientData;
sub GetPatient;
sub GetDiseasedChildren;
sub GetAllChildren;

# read in patient table
my $patients = 'rsave/patients.csv';
open(my $fh, '<:encoding(UTF-8)', $patients)
  or die "Could not open file '$patients' $!";
chomp(my @lines = <$fh>);
close $fh;
shift @lines;


# load patient csv into hash
my %patients;
foreach my $line (@lines) {
  my ($familyId, $childId, $paternalId, $maternalId, $gender, $md) = split(/,/, $line);
  $patients{$childId}{id} = $childId;
  $patients{$childId}{familyId} = $familyId;
  $patients{$childId}{paternalId} = $paternalId;
  $patients{$childId}{maternalId} = $maternalId;
  $patients{$childId}{gender} = $gender;
  $patients{$childId}{md} = $md;
}

sub GetPatientData() {
  return %patients;
}

sub GetPatient($) {
  my $id = $_[0];
  if (!exists($patients{$id})) {
    return undef;
  }
  return $patients{$id};
}

my @allchildren;
my @diseasedchildren;
foreach my $patientId (keys %{patients}) {
  my %patient = %{$patients{$patientId}};
  my $paternalId = $patient{paternalId};
  my $maternalId = $patient{maternalId};
  if ($paternalId ne 'NA' && $maternalId ne 'NA') {
    my %father = %{$patients{$paternalId}};
    my %mother = %{$patients{$maternalId}};
    # choose only parents who do not have muscle disease
    if ($father{md} != 1 && $mother{md} != 1) {
      push @allchildren, $patientId;
      if ($patient{md} == 1) {
        push @diseasedchildren, $patientId;
      }
    }
  }
}

sub GetDiseasedChildren() {
  return @diseasedchildren;
}

sub GetAllChildren() {
  return @allchildren;
}

1;