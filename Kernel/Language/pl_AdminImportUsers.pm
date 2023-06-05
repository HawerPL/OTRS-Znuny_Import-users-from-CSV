package Kernel::Language::pl_AdminImportUsers;

use strict;
use warnings;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Import Agents'} = 'Importuj Agentów';
    $Self->{Translation}->{'Import Agents from CSV'} = 'Importuj Agentów z plik CSV';
    $Self->{Translation}->{'Not imported agents'} = 'Zaimportowani agenci';
    $Self->{Translation}->{'Imported agents'} = 'Niezaimportowani agenci';
    $Self->{Translation}->{'CSV file accepts headers: Name, Surname, Login, Email, Mobile, Validity, Password, Title (or Salution).'} = 'Plik CSV akceptuje nagłówki: Name, Surname, Login, Email, Mobile, Validity, Password, Title (or Salution)';

    return 1;
}
1;
           