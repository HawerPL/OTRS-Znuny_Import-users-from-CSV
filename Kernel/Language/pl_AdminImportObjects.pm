package Kernel::Language::pl_AdminImport;

use strict;
use warnings;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'Import objects'} = 'Importuj obiekty';
    $Self->{Translation}->{'Select which type of object you want to import.'} = 'Wybierz jaki typ obiektów chcesz importować.';
    $Self->{Translation}->{'Objects'} = 'Obiekty';

    $Self->{Translation}->{'Import Agents'} = 'Importuj Agentów';
    $Self->{Translation}->{'Import Agents from CSV'} = 'Importuj Agentów z plik CSV';
    $Self->{Translation}->{'Not imported agents'} = 'Zaimportowani agenci';
    $Self->{Translation}->{'Imported agents'} = 'Niezaimportowani agenci';
    $Self->{Translation}->{'CSV file accepts headers: Name, Surname, Login, Email, Mobile, Validity, Password, Title (or Salution).'} = 'Plik CSV akceptuje nagłówki: Name, Surname, Login, Email, Mobile, Validity, Password, Title (or Salution)';

    $Self->{Translation}->{'Import Queues'} = 'Importuj Kolejki';
    $Self->{Translation}->{'Import Queues from CSV'} = 'Importuj Kolejki z plik CSV';
    $Self->{Translation}->{'Not imported Queues'} = 'Zaimportowane kolejki';
    $Self->{Translation}->{'Imported Queues'} = 'Niezaimportowane kolejki';
    $Self->{Translation}->{'CSV accepts headers Name, GroupID, UnlockTimeout, FollowUpLock, SystemAddressID, SalutationID, SignatureID, FirstResponseTime, FirstResponseNotify, UpdateTime, UpdateNotify, FollowUpID, SolutionTime, UpdateNotify, Comment, Validity. Do not fill in columns that you do not want to import (for example, SalutionId)'} = 'Plik CSV akceptuje nagłówki: Name, GroupID, UnlockTimeout, FollowUpLock, SystemAddressID, SalutationID, SignatureID, FirstResponseTime, FirstResponseNotify, UpdateTime, UpdateNotify, FollowUpID, SolutionTime, UpdateNotify, Comment, Validity. Nie wypełniaj kolumn, których nie chcesz zaimportować (na przykład SalutionId)';

    $Self->{Translation}->{'Import Groups'} = 'Importuj Grupy';
    $Self->{Translation}->{'Import Groups from CSV'} = 'Importuj Grupy z plik CSV';
    $Self->{Translation}->{'Not imported Groups'} = 'Zaimportowane grupy';
    $Self->{Translation}->{'Imported Groups'} = 'Niezaimportowane grupy';
    $Self->{Translation}->{'CSV accepts headers Name, Validity, Comment.'} = 'Plik CSV akceptuje nagłówki: Name, Validity, Comment.';


    return 1;
}
1;
           