package Kernel::Modules::AdminImportUsers;

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

    my %Errors;

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

            my $RefUserArray = $CSVObject->CSV2Array(
                String      => $StringWithoutBOM,
                Separator   => ';',
                Quote       => '"'
            );


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
                # $Kernel::OM->Get('Kernel::System::Log')->Log(
                #     Priority => 'notice',
                #     Message  => $index
                # );

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

        }
    }

    #show file upload
    if ( $ConfigObject->Get('Package::FileUpload') ) {
        $LayoutObject->Block(
            Name => 'OverviewFileUpload',
            Data => {
                FormID => $Kernel::OM->Get('Kernel::System::Web::UploadCache')->FormIDCreate(),
                %Errors,
            },
        );
    }


    # Tu tworzy "HTML", najpier nagłowek, późnej dołączamy menu, szablon .tt, a na koniec stopkę
    my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminImportUsers',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

}

1;
