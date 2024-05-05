package Kernel::Modules::AdminImportObjects;

use strict;
use warnings;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject     = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $CSVObject       = $Kernel::OM->Get('Kernel::System::CSV');
    my $EncodeObject    = $Kernel::OM->Get('Kernel::System::Encode');
    my $ConfigObject    = $Kernel::OM->Get('Kernel::Config');
    my $UserObject      = $Kernel::OM->Get('Kernel::System::User');
    my $LogObject       = $Kernel::OM->Get('Kernel::System::Log');

    my %Errors;
    my $RefCsvArray;

    my $GroupSelected  = $ParamObject->GetParam( Param => 'Group' ) || '';

    # Show file upload
    if ( $ConfigObject->Get('Package::FileUpload') ) {
        $LayoutObject->Block(
            Name => 'OverviewFileUpload',
            Data => {
                FormID => $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate(),
                %Errors,
            },
        );
    }

    if ( $Self->{Subaction} eq 'Import' ){

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => "Zaimportowano plik"
        );

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $FormID      = $ParamObject->GetParam( Param => 'FormID') || '';
        my %UploadStuff = $ParamObject->GetUploadAll(
            Param => 'FileUpload',
        );

        my $UploadCacheObject = $Kernel::OM->Get('Kernel::System::Web::UploadCache');

        # save file in upload cache
        if (%UploadStuff) {
            my $Added = $UploadCacheObject->FormIDAddFile(
                FormID => $FormID,
                %UploadStuff,
            );

                
            # if file got not added to storage
            # (e. g. because of 1 MB max_allowed_packet MySQL problem)
            if ( !$Added ) {
                $LayoutObject->FatalError();
            }
        }        
        # get file from upload cache
        else {
            my @AttachmentData = $UploadCacheObject->FormIDGetAllFilesData(
                FormID => $FormID,
            );

            if ( !@AttachmentData || ( $AttachmentData[0] && !%{ $AttachmentData[0] } ) ) {
                $Errors{FileUploadInvalid} = 'ServerError';
            }
            else {
                %UploadStuff = %{ $AttachmentData[0] };
            }
        }

        if ( !%Errors ){

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'notice',
                Message  => 'Nie wystapily bledy z wgraniem pliku'
            );

            my $StringWithoutBOM = $EncodeObject->RemoveUTF8BOM( String => $UploadStuff{Content} );

            my $RefCsvArray = $CSVObject->CSV2Array(
                String      => $StringWithoutBOM,
                Separator   => ';',
                Quote       => '"'
            );

            if ( $GroupSelected eq 'ImportAgents'){
                my $ImportResultOutput = $Self->_ImportAgents(
                    %Param,
                    RefCsvArray     => $RefCsvArray,
                );
            }
            elsif ( $GroupSelected eq 'ImportGroups'){
                my $ImportResultOutput = $Self->_ImportGroups(
                    %Param,
                    RefCsvArray     => $RefCsvArray,
                );
            }
            elsif ( $GroupSelected eq 'ImportQueues'){
                my $ImportResultOutput = $Self->_ImportQueues(
                    %Param,
                    RefCsvArray     => $RefCsvArray,
                );
            }
            
        }
    }

    if ( $GroupSelected eq 'ImportAgents'){

         my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AdminImportAgents',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();
        return $Output;

    }
    elsif ( $GroupSelected eq 'ImportGroups'){

         my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AdminImportGroups',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();
        return $Output;

    }
    elsif ( $GroupSelected eq 'ImportQueues'){

         my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AdminImportQueues',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();
        return $Output;

    }
    else{
        # Tu tworzy "HTML", najpier nagłowek, późnej dołączamy menu, szablon .tt, a na koniec stopkę
        my $Output = $LayoutObject->Header();
            $Output .= $LayoutObject->NavigationBar();
            $Output .= $LayoutObject->Output(
                TemplateFile => 'AdminImportObjects',
                Data         => \%Param,
            );
            $Output .= $LayoutObject->Footer();
        return $Output;
        
    }
}

sub _ImportAgents(){
    my ( $Self, %Param ) = @_;

    my $UserObject      = $Kernel::OM->Get('Kernel::System::User');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RefUserArray = $Param{RefCsvArray};

    my $NameColumn = 999;
    my $SurnameColumn = 999;
    my $EmailColumn = 999;
    my $LoginColumn = 999;
    my $MobileColumn = 999;
    my $ValidityColumn = 999;
    my $PasswordColumn = 999;
    my $TitleOrSalutionColumn = 999;
    my $index = 0;

    foreach my $i ( @{ $RefUserArray->[0] } ){
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => $index
        );

        if ( $i eq 'Name'){
            $NameColumn = $index;
        }
        elsif ( $i eq 'Surname'){
            $SurnameColumn = $index;
        }
        elsif ( $i eq 'Email'){
            $EmailColumn = $index;
        } 
        elsif ( $i eq 'Login'){
            $LoginColumn = $index;
        } 
        elsif ( $i eq 'Mobile'){
            $MobileColumn = $index;
        } 
        elsif ( $i eq 'Validity'){
            $ValidityColumn = $index;
        } 
        elsif ( $i eq 'Password'){
            $PasswordColumn = $index;
        } 
        elsif ( (index($i, 'Title') != -1) or (index($i, 'Salution') != -1) ){
            $TitleOrSalutionColumn = $index;
        } 
        $index = $index + 1;
    }

    my @UserArray = @{ $RefUserArray };
    my $Password = '';

    for my $User ( @UserArray[1 .. $#UserArray] ) {
        if ( ($User->[int($PasswordColumn)] eq '') or ( $PasswordColumn == 999 )){
            $Password = $UserObject->GenerateRandomPassword(
                Size => 128,
            );
        }
        else {
            $Password = $User->[int($PasswordColumn)];
        }
                
        my $UserID = $UserObject->UserAdd(
            UserFirstname => $User->[int($NameColumn)],
            UserLastname  => $User->[int($SurnameColumn)],
            UserLogin     => $User->[int($LoginColumn)],
            UserPw        => $Password,
            UserEmail     => $User->[int($EmailColumn)],
            UserMobile    => $User->[int($MobileColumn)],
            ValidID       => $User->[int($ValidityColumn)],
            ChangeUserID  => $Self->{UserID}
        );

        if ( $UserID ){
            $LayoutObject->Block(
                Name => 'ImportedAgentsRow',
                Data => {
                    Name            => $User->[int($NameColumn)],
                    Surname         => $User->[int($SurnameColumn)],
                    Login           => $User->[int($LoginColumn)],
                    Email           => $User->[int($EmailColumn)],
                    Mobile          => $User->[int($MobileColumn)],
                    Password        => '******',
                    Validity        => $User->[int($ValidityColumn)],
                    TitleOrSalution => $User->[int($TitleOrSalutionColumn)]
                },
            );
        } else {
            $LayoutObject->Block(
                Name => 'NotImportedAgentsRow',
                Data => {
                    Name            => $User->[int($NameColumn)],
                    Surname         => $User->[int($SurnameColumn)],
                    Login           => $User->[int($LoginColumn)],
                    Email           => $User->[int($EmailColumn)],
                    Mobile          => $User->[int($MobileColumn)],
                    Password        => '******',
                    Validity        => $User->[int($ValidityColumn)],
                    TitleOrSalution => $User->[int($TitleOrSalutionColumn)]
                },
            );
        }

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => 'Zakonczono import uzytkownikow'
        );
    }
    return 1;
}

sub _ImportGroups(){
    my ( $Self, %Param ) = @_;

    my $GroupObject      = $Kernel::OM->Get('Kernel::System::Group');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RefGroupArray = $Param{RefCsvArray};

    my $NameColumn = 999;
    my $ValidityColumn = 999;
    my $CommentColumn = 999;
    my $index = 0;

    foreach my $i ( @{ $RefGroupArray->[0] } ){
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'debug',
            Message  => $index
        );

        if ( $i eq 'Name'){
            $NameColumn = $index;
        }
        elsif ( $i eq 'Validity'){
            $ValidityColumn = $index;
        } 
        elsif ( $i eq 'Comment'){
            $CommentColumn = $index;
        } 
        $index = $index + 1;
    }

    my @GroupArray = @{ $RefGroupArray };

    for my $Group ( @GroupArray[1 .. $#GroupArray] ) {
                        
        my $GroupID = $GroupObject->GroupAdd(
            Name            => $Group->[int($NameColumn)],
            ValidID         => $Group->[int($ValidityColumn)],
            Comment         => $Group->[int($CommentColumn)],
            UserID    => $Self->{UserID}
        );

        if ( $GroupID ){
            $LayoutObject->Block(
                Name => 'ImportedGroupsRow',
                Data => {
                    Name            => $Group->[int($NameColumn)],
                    Validity        => $Group->[int($ValidityColumn)],
                    Comment         => $Group->[int($CommentColumn)]
                },
            );
        } else {
            $LayoutObject->Block(
                Name => 'NotImportedGroupsRow',
                Data => {
                    Name            => $Group->[int($NameColumn)],
                    Validity        => $Group->[int($ValidityColumn)],
                    Comment         => $Group->[int($CommentColumn)]
                },
            );
        }

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => 'Zakonczono import grup'
        );
    }
    return 1;
}

sub _ImportQueues(){
    my ( $Self, %Param ) = @_;

    my $QueueObject     = $Kernel::OM->Get('Kernel::System::Queue');
    my $LayoutObject    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $RefQueueArray   = $Param{RefCsvArray};

    my $NameColumn = 999;
    my $GroupIdColumn = 999;
    my $UnlockTimeoutColumn = 999;
    my $SystemAddressIdColumn = 999;
    my $SalutionIdColumn = 999;
    my $SignatureIdColumn = 999;
    my $FirstResponseTimeColumn = 999;
    my $FirstResponseNotifyColumn = 999;
    my $UpdateTimeColumn = 999;
    my $UpdateNotifyColumn = 999;
    my $FollowUpIdColumn = 999;
    my $FollowUpLockColumn = 999;
    my $SolutionTimeColumn = 999;
    my $SolutionNotifyColumn = 999;
    my $CommentColumn = 999;
    my $CalendarColumn = 999;
    my $ValidityColumn = 999;
    my $index = 0;

    $Self->{QueueDefaults} = {
        Calendar            => '',
        UnlockTimeout       => 0,
        FirstResponseTime   => 0,
        FirstResponseNotify => 0,
        UpdateTime          => 0,
        UpdateNotify        => 0,
        SolutionTime        => 0,
        SolutionNotify      => 0,
        SystemAddressID     => 1,
        SalutationID        => 1,
        SignatureID         => 1,
        FollowUpID          => 1,
        FollowUpLock        => 0,
    };

    foreach my $i ( @{ $RefQueueArray->[0] } ){
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'debug',
            Message  => $index
        );

        if ( $i eq 'Name'){
            $NameColumn = $index;
        }
        elsif ( $i eq 'GroupId'){
            $GroupIdColumn = $index;
        }
        elsif ( $i eq 'UnlockTimeout'){
            $UnlockTimeoutColumn = $index;
        } 
        elsif ( $i eq 'SystemAddressId'){
            $SystemAddressIdColumn = $index;
        } 
        elsif ( $i eq 'SalutionId'){
            $SalutionIdColumn = $index;
        }
        elsif ( $i eq 'SignatureId'){
            $SignatureIdColumn = $index;
        }  
        elsif ( $i eq 'FirstResponseTime'){
            $FirstResponseTimeColumn = $index;
        }  
        elsif ( $i eq 'FirstResponseNotify'){
            $FirstResponseNotifyColumn = $index;
        }  
        elsif ( $i eq 'UpdateTime'){
            $UpdateTimeColumn = $index;
        }  
        elsif ( $i eq 'UpdateNotify'){
            $UpdateNotifyColumn = $index;
        }  
        elsif ( $i eq 'FollowUpId'){
            $FollowUpIdColumn = $index;
        }  
        elsif ( $i eq 'FollowUpLock'){
            $FollowUpLockColumn = $index;
        }  
        elsif ( $i eq 'SolutionTime'){
            $SolutionTimeColumn = $index;
        }  
        elsif ( $i eq 'SolutionNotify'){
            $SolutionNotifyColumn = $index;
        }  
        elsif ( $i eq 'Comment'){
            $CommentColumn = $index;
        }  
        elsif ( $i eq 'Calendar'){
            $CalendarColumn = $index;
        }  
        elsif ( $i eq 'Validity'){
            $ValidityColumn = $index;
        } 
        $index = $index + 1;
    }

    my @QueueArray = @{ $RefQueueArray };

    for my $Queue ( @QueueArray[1 .. $#QueueArray] ) {
                       
        my $QueueID = $QueueObject->QueueAdd(
            Name                => $Queue->[int($NameColumn)],
            GroupID             => $Queue->[int($GroupIdColumn)],
            UnlockTimeout       => $Queue->[int($UnlockTimeoutColumn)],
            FirstResponseTime   => $Queue->[int($FirstResponseTimeColumn)],
            FirstResponseNotify => $Queue->[int($FirstResponseNotifyColumn)],
            UpdateTime          => $Queue->[int($UpdateTimeColumn)],
            UpdateNotify        => $Queue->[int($UpdateNotifyColumn)],
            SolutionTime        => $Queue->[int($SolutionTimeColumn)],
            SolutionNotify      => $Queue->[int($SolutionNotifyColumn)],
            SystemAddressID     => $Queue->[int($SystemAddressIdColumn)],
            SalutationID        => $Queue->[int($SalutionIdColumn)],
            SignatureID         => $Queue->[int($SignatureIdColumn)],
            FollowUpID          => $Queue->[int($FollowUpIdColumn)],
            FollowUpLock        => $Queue->[int($FollowUpLockColumn)],
            Calendar            => $Queue->[int($CalendarColumn)],
            Comment             => $Queue->[int($CommentColumn)],
            ValidID             => $Queue->[int($ValidityColumn)],
            UserID              => $Self->{UserID}
        );

        if ( $QueueID ){
            $LayoutObject->Block(
                Name => 'ImportedQueueRow',
                Data => {
                    Name                => $Queue->[int($NameColumn)],
                    GroupID             => $Queue->[int($GroupIdColumn)],
                    UnlockTimeout       => $Queue->[int($UnlockTimeoutColumn)],
                    FirstResponseTime   => $Queue->[int($FirstResponseTimeColumn)],
                    FirstResponseNotify => $Queue->[int($FirstResponseNotifyColumn)],
                    UpdateTime          => $Queue->[int($UpdateTimeColumn)],
                    UpdateNotify        => $Queue->[int($UpdateNotifyColumn)],
                    SolutionTime        => $Queue->[int($SolutionTimeColumn)],
                    SolutionNotify      => $Queue->[int($SolutionNotifyColumn)],
                    SystemAddressID     => $Queue->[int($SystemAddressIdColumn)],
                    SalutationID        => $Queue->[int($SalutionIdColumn)],
                    SignatureID         => $Queue->[int($SignatureIdColumn)],
                    FollowUpID          => $Queue->[int($FollowUpIdColumn)],
                    FollowUpLock        => $Queue->[int($FollowUpLockColumn)],
                    Calendar            => $Queue->[int($CalendarColumn)],
                    Comment             => $Queue->[int($CommentColumn)],
                    ValidID             => $Queue->[int($ValidityColumn)],
                },
            );
        } else {
            $LayoutObject->Block(
                Name => 'NotImportedQueueRow',
                Data => {
                    Name                => $Queue->[int($NameColumn)],
                    GroupID             => $Queue->[int($GroupIdColumn)],
                    UnlockTimeout       => $Queue->[int($UnlockTimeoutColumn)],
                    FirstResponseTime   => $Queue->[int($FirstResponseTimeColumn)],
                    FirstResponseNotify => $Queue->[int($FirstResponseNotifyColumn)],
                    UpdateTime          => $Queue->[int($UpdateTimeColumn)],
                    UpdateNotify        => $Queue->[int($UpdateNotifyColumn)],
                    SolutionTime        => $Queue->[int($SolutionTimeColumn)],
                    SolutionNotify      => $Queue->[int($SolutionNotifyColumn)],
                    SystemAddressID     => $Queue->[int($SystemAddressIdColumn)],
                    SalutationID        => $Queue->[int($SalutionIdColumn)],
                    SignatureID         => $Queue->[int($SignatureIdColumn)],
                    FollowUpID          => $Queue->[int($FollowUpIdColumn)],
                    FollowUpLock        => $Queue->[int($FollowUpLockColumn)],
                    Calendar            => $Queue->[int($CalendarColumn)],
                    Comment             => $Queue->[int($CommentColumn)],
                    ValidID             => $Queue->[int($ValidityColumn)],
                },
            );
        }

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'notice',
            Message  => 'Zakonczono import kolejek'
        );
    }
    return 1;
}

1;
