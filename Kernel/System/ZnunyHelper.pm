# --
# Kernel/ZnunyHelper.pm - provides some useful functions
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

package Kernel::System::ZnunyHelper;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Cache',
    'Kernel::System::Loader',
    'Kernel::System::Log',
    'Kernel::System::Main',
    'Kernel::System::Encode',
    'Kernel::System::Time',
    'Kernel::System::DB',
    'Kernel::System::XML',
    'Kernel::System::SysConfig',
    'Kernel::System::Group',
    'Kernel::System::User',
    'Kernel::System::Valid',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::DynamicFieldValue',
    'Kernel::System::Package',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = \%Param;
    bless( $Self, $Type );

    # rebuild ZZZ* files
    $Kernel::OM->Get('Kernel::System::SysConfig')->WriteDefault();

    # define the ZZZ files
    my @ZZZFiles = (
        'ZZZAAuto.pm',
        'ZZZAuto.pm',
    );

    # disable redefine warnings in this scope
    {
        no warnings 'redefine';

        # reload the ZZZ files (mod_perl workaround)
        for my $ZZZFile (@ZZZFiles) {

            PREFIX:
            for my $Prefix (@INC) {
                my $File = $Prefix . '/Kernel/Config/Files/' . $ZZZFile;
                next PREFIX if !-f $File;
                do $File;
                last PREFIX;
            }
        }
    # reset all warnings
    }

    return $Self;
}

# File => '/path/to/file'

sub _PackageInstall {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed ( qw(File) ) {

        next NEEDED if defined $Param{ $Needed };

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # read
    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $Param{File},
        Mode     => 'utf8',
        Result   => 'SCALAR',
    );
    return if !$ContentRef;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # parse
    my %Structure = $PackageObject->PackageParse(
        String => ${ $ContentRef },
    );

    # execute actions
    # install code (pre)
    if ( $Structure{CodeInstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeInstall},
            Type      => 'pre',
            Structure => \%Structure,
        );
    }

    # install database (pre)
    if (
        IsHashRefWithData( $Structure{DatabaseInstall} )
        && $Structure{DatabaseInstall}->{pre}
    ) {
        $PackageObject->_Database(
            Database => $Structure{DatabaseInstall}->{pre},
        );
    }

    # install database (post)
    if (
        IsHashRefWithData( $Structure{DatabaseInstall} )
        && $Structure{DatabaseInstall}->{post}
    ) {
        $PackageObject->_Database(
            Database => $Structure{DatabaseInstall}->{post},
        );
    }

    # install code (post)
    if ( $Structure{CodeInstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeInstall},
            Type      => 'post',
            Structure => \%Structure,
        );
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();
    $Kernel::OM->Get('Kernel::System::Loader')->CacheDelete();

    return 1;
}

# File => '/path/to/file'

sub _PackageUMain{
    my ( $Self, %Param ) = @_;


    # check needed stuff
    NEEDED:
    for my $Needed ( qw(File) ) {

        next NEEDED if defined $Param{ $Needed };

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    # read
    my $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
        Location => $Param{File},
        Mode     => 'utf8',
        Result   => 'SCALAR',
    );
    return if !$ContentRef;

    my $PackageObject = $Kernel::OM->Get('Kernel::System::Package');

    # parse
    my %Structure = $PackageObject->PackageParse(
        String => ${ $ContentRef },
    );

    # uninstall code (pre)
    if ( $Structure{CodeUninstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeUninstall},
            Type      => 'pre',
            Structure => \%Structure,
        );
    }

    # uninstall database (pre)
    if (
        IsHashRefWithData( $Structure{DatabaseUninstall} )
        && $Structure{DatabaseUninstall}->{pre}
    ) {
        $PackageObject->_Database(
            Database => $Structure{DatabaseUninstall}->{pre},
        );
    }

    # uninstall database (post)
    if (
        IsHashRefWithData( $Structure{DatabaseUninstall} )
        && $Structure{DatabaseUninstall}->{post}
    ) {
        $PackageObject->_Database(
            Database => $Structure{DatabaseUninstall}->{post},
        );
    }

    # uninstall code (post)
    if ( $Structure{CodeUninstall} ) {
        $PackageObject->_Code(
            Code      => $Structure{CodeUninstall},
            Type      => 'post',
            Structure => \%Structure,
        );
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp();
    $Kernel::OM->Get('Kernel::System::Loader')->CacheDelete();

    return 1;
}

=item _JSLoaderAdd()

!!! DEPRECATED !!! -> use _LoaderAdd() instead

This function adds JavaScript files to the load of defined screens.

my $Result = $CodeObject->_JSLoaderAdd(
    AgentTicketPhone => ['Core.Agent.WPTicketOEChange.js'],
);

=cut

sub _JSLoaderAdd {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "_JSLoaderAdd function is deprecated, please use _LoaderAdd."
    );

    $Self->_LoaderAdd( %Param );

    return 1;
}

=item _JSLoaderRemove()

!!! DEPRECATED !!! -> use _LoaderRemove() instead

This function removes JavaScript files to the load of defined screens.

my $Result = $CodeObject->_JSLoaderRemove(
    AgentTicketPhone => ['Core.Agent.WPTicketOEChange.js'],
);

=cut

sub _JSLoaderRemove {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "_JSLoaderRemove function is deprecated, please use _LoaderRemove."
    );

    $Self->_LoaderRemove( %Param );

    return 1;
}

=item _LoaderAdd()

This function adds JavaScript and CSS files to the load of defined screens.

my $Result = $CodeObject->_LoaderAdd(
    AgentTicketPhone => [
        'Core.Agent.WPTicketOEChange.css',
        'Core.Agent.WPTicketOEChange.js'
    ],
);

=cut

sub _LoaderAdd {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    my %LoaderConfig = %Param;

    my $ExtensionRegExp = '\.(css|js)$';
    VIEW:
    for my $View ( keys %LoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $LoaderConfig{$View} );

        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

       # get existing config for each View
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get($CustomerInterfacePrefix ."Frontend::Module")->{$View};

        if ( !IsHashRefWithData($Config) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while getting '${CustomerInterfacePrefix}Frontend::Module' for view '$View'.",
            );
            next VIEW;
        }

        my @JSLoaderFiles;
        my @CSSLoaderFiles;
        if ( IsHashRefWithData( $Config->{Loader} ) ) {

            if ( IsArrayRefWithData( $Config->{Loader}->{JavaScript} ) ) {
                @JSLoaderFiles = @{ $Config->{Loader}->{JavaScript} };
            }
            if ( IsArrayRefWithData( $Config->{Loader}->{CSS} ) ) {
                @CSSLoaderFiles = @{ $Config->{Loader}->{CSS} };
            }
        }

        LOADERFILE:
        for my $NewLoaderFile ( sort @{ $LoaderConfig{$View} } ) {

            next LOADERFILE if $NewLoaderFile !~ m{$ExtensionRegExp}i;

            if ( lc $1 eq 'css' ) {

                next LOADERFILE if grep { $NewLoaderFile eq $_ } @CSSLoaderFiles;

                push @CSSLoaderFiles, $NewLoaderFile;
            }
            elsif ( lc $1 eq 'js' ) {

                next LOADERFILE if grep { $NewLoaderFile eq $_ } @JSLoaderFiles;

                push @JSLoaderFiles, $NewLoaderFile;
            }
        }

        $Config->{Loader}->{JavaScript} = \@JSLoaderFiles;
        $Config->{Loader}->{CSS}        = \@CSSLoaderFiles;

        # update the sysconfig
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => $CustomerInterfacePrefix ."Frontend::Module###" . $View,
            Value => $Config,
        );
    }

    return 1;
}

=item _LoaderRemove()

This function removes JavaScript and CSS files to the load of defined screens.

my $Result = $CodeObject->_LoaderRemove(
    AgentTicketPhone => [
        'Core.Agent.WPTicketOEChange.css',
        'Core.Agent.WPTicketOEChange.js',
    ],
);

=cut

sub _LoaderRemove {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %LoaderConfig = %Param;

    VIEW:
    for my $View ( keys %LoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $LoaderConfig{$View} );

        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

       # get existing config for each View
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get($CustomerInterfacePrefix ."Frontend::Module")->{$View};

        if ( !IsHashRefWithData($Config) ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while getting '${CustomerInterfacePrefix}Frontend::Module' for view '$View'.",
            );
            next VIEW;
        }

        my @JSLoaderFiles;
        my @CSSLoaderFiles;
        if ( IsHashRefWithData( $Config->{Loader} ) ) {

            if ( IsArrayRefWithData( $Config->{Loader}->{JavaScript} ) ) {
                @JSLoaderFiles = @{ $Config->{Loader}->{JavaScript} };
            }
            if ( IsArrayRefWithData( $Config->{Loader}->{CSS} ) ) {
                @CSSLoaderFiles = @{ $Config->{Loader}->{CSS} };
            }
        }

        if (
            !scalar @JSLoaderFiles
            && !scalar @CSSLoaderFiles
        ) {
            next VIEW;
        }

        if ( scalar @JSLoaderFiles ) {

            my @NewJSLoaderFiles;
            LOADERFILE:
            for my $JSLoaderFile ( sort @JSLoaderFiles ) {

                next LOADERFILE if grep { $JSLoaderFile eq $_ } @{ $LoaderConfig{$View} };

                push @NewJSLoaderFiles, $JSLoaderFile;
            }

            $Config->{Loader}->{JavaScript} = \@NewJSLoaderFiles;
        }

        if ( scalar @CSSLoaderFiles ) {

            my @NewCSSLoaderFiles;
            LOADERFILE:
            for my $CSSLoaderFile ( sort @CSSLoaderFiles ) {

                next LOADERFILE if grep { $CSSLoaderFile eq $_ } @{ $LoaderConfig{$View} };

                push @NewCSSLoaderFiles, $CSSLoaderFile;
            }

            $Config->{Loader}->{CSS} = \@NewCSSLoaderFiles;
        }


        # update the sysconfig
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => $CustomerInterfacePrefix .'Frontend::Module###' . $View,
            Value => $Config,
        );
    }

    return 1;
}

=item _DynamicFieldsScreenEnable()

This function enables the defined dynamic fields in the needed screens.

my $Result = $CodeObject->_DynamicFieldsScreenEnable();

=cut

sub _DynamicFieldsScreenEnable {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    VIEW:
    for my $View ( keys %ScreenDynamicFieldConfig ) {

        next VIEW if !IsHashRefWithData( $ScreenDynamicFieldConfig{$View} );

        # get existing config for each screen
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::". $View);

        # get existing dynamic field config
        my %ExistingSetting;
        if ( IsHashRefWithData( $Config->{DynamicField} ) ) {
            %ExistingSetting = %{ $Config->{DynamicField} };
        }

        # add the new settings
        my %NewDynamicFieldConfig = ( %ExistingSetting, %{ $ScreenDynamicFieldConfig{$View} } );

        # update the sysconfig
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Frontend::' . $View . '###DynamicField',
            Value => \%NewDynamicFieldConfig,
        );
    }

    return 1;
}

=item _DynamicFieldsScreenDisable()

This function disables the defined dynamic fields in the needed screens.

my $Result = $CodeObject->_DynamicFieldsScreenDisable($Definition);

=cut

sub _DynamicFieldsScreenDisable {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    VIEW:
    for my $View ( keys %ScreenDynamicFieldConfig ) {

        next VIEW if !IsHashRefWithData( $ScreenDynamicFieldConfig{$View} );

        # get existing config for each screen
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get("Ticket::Frontend::". $View);

        # get existing dynamic field config
        my %ExistingSetting;
        if ( IsHashRefWithData( $Config->{DynamicField} ) ) {
            %ExistingSetting = %{ $Config->{DynamicField} };
        }

        my %NewDynamicFieldConfig;
        SETTING:
        for my $ExistingSettingKey ( sort keys %ExistingSetting ) {

            next SETTING if $ScreenDynamicFieldConfig{ $View }->{$ExistingSettingKey};

            $NewDynamicFieldConfig{$ExistingSettingKey} = $ExistingSetting{$ExistingSettingKey};
        }

        # update the sysconfig
        my $Success = $Kernel::OM->Get('Kernel::System::SysConfig')->ConfigItemUpdate(
            Valid => 1,
            Key   => 'Ticket::Frontend::' . $View . '###DynamicField',
            Value => \%NewDynamicFieldConfig,
        );
    }

    return 1;
}

=item _DynamicFieldsDelete()

This function delete the defined dynamic fields

my $Result = $CodeObject->_DynamicFieldsDelete('Field1', 'Field2');

=cut

sub _DynamicFieldsDelete {
    my ( $Self, @DynamicFields ) = @_;

    return 1 if !@DynamicFields;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    return 1 if !IsArrayRefWithData( $DynamicFieldList );

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{ $DynamicFieldList } ) {

        next DYNAMICFIELD if !IsHashRefWithData( $DynamicField );

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # delete the dynamic fields
    DYNAMICFIELD:
    for my $DynamicFieldName (@DynamicFields) {

        next DYNAMICFIELD if !IsHashRefWithData( $DynamicFieldLookup{ $DynamicFieldName } );

        my $ValuesDeleteSuccess = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->AllValuesDelete(
            DynamicFieldConfig => $DynamicFieldLookup{ $DynamicField },
            UserID             => 1,
        );

        my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldDelete(
            %{ $DynamicFieldLookup{ $DynamicFieldName } },
            Reorder => 0,
            UserID  => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsDisable()

This function disables the defined dynamic fields

my $Result = $CodeObject->_DynamicFieldsDisable('Field1', 'Field2');

=cut

sub _DynamicFieldsDisable {
    my ( $Self, @DynamicFields ) = @_;

    return 1 if !@DynamicFields;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    return 1 if !IsArrayRefWithData( $DynamicFieldList );

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{ $DynamicFieldList } ) {

        next DYNAMICFIELD if !IsHashRefWithData( $DynamicField );

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    my $InvalidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'invalid',
    );

    # disable the dynamic fields
    DYNAMICFIELD:
    for my $DynamicFieldName (@DynamicFields) {

        next DYNAMICFIELD if !$DynamicFieldLookup{ $DynamicFieldName };

        my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldUpdate(
            %{ $DynamicFieldLookup{ $DynamicFieldName } },
            ValidID => $InvalidID,
            Reorder => 0,
            UserID  => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsCreateIfNotExists()

creates all dynamic fields that are necessary

    my $Result = $CodeObject->_DynamicFieldsCreateIfNotExists( $Definition );

=cut

sub _DynamicFieldsCreateIfNotExists {
    my ( $Self, @Definition ) = @_;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    if ( !IsArrayRefWithData( $DynamicFieldList ) ) {
        $DynamicFieldList = [];
    }

    my @DynamicFieldExistsNot;
    DYNAMICFIELD:
    for my $NewDynamicField ( @Definition ) {

        next DYNAMICFIELD if !IsHashRefWithData( $NewDynamicField );

        next DYNAMICFIELD if grep { $NewDynamicField->{Name} eq $_->{Name} } @{ $DynamicFieldList };

        push @DynamicFieldExistsNot, $NewDynamicField;
    }

    return 1 if !@DynamicFieldExistsNot;

    return $Self->_DynamicFieldsCreate(@DynamicFieldExistsNot);
}

=item _DynamicFieldsCreate()

creates all dynamic fields that are necessary

    my $Result = $CodeObject->_DynamicFieldsCreate( $Definition );

=cut

sub _DynamicFieldsCreate {
    my ( $Self, @DynamicFields ) = @_;

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );

    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    # get all current dynamic fields
    my $DynamicFieldList = $DynamicFieldObject->DynamicFieldListGet(
        Valid => 0,
    );

    if ( !IsArrayRefWithData( $DynamicFieldList ) ) {
        $DynamicFieldList = [];
    }

    # get the last element from the order list and add 1
    my $NextOrderNumber = 1;
    if (
        IsArrayRefWithData( $DynamicFieldList )
        && IsHashRefWithData( $DynamicFieldList->[-1] )
        && $DynamicFieldList->[-1]->{FieldOrder}
    ) {
        $NextOrderNumber = $DynamicFieldList->[-1]->{FieldOrder} + 1;
    }

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{ $DynamicFieldList } ) {

        next DYNAMICFIELD if !IsHashRefWithData( $DynamicField );

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # create or update dynamic fields
    DYNAMICFIELD:
    for my $NewDynamicField ( @DynamicFields ) {

        my $CreateDynamicField;

        # check if the dynamic field already exists
        if ( !IsHashRefWithData( $DynamicFieldLookup{ $NewDynamicField->{Name} } ) ) {
            $CreateDynamicField = 1;
        }

        # if the field exists check if the type match with the needed type
        elsif (
            $DynamicFieldLookup{ $NewDynamicField->{Name} }->{FieldType}
            ne $NewDynamicField->{FieldType}
        ) {
            my %OldDynamicFieldConfig = %{ $DynamicFieldLookup{ $NewDynamicField->{Name} } };

            # rename the field and create a new one
            my $Success = $DynamicFieldObject->DynamicFieldUpdate(
                %OldDynamicFieldConfig,
                Name   => $OldDynamicFieldConfig{Name} . 'Old',
                UserID => 1,
            );

            $CreateDynamicField = 1;
        }

        # otherwise if the field exists and the type matches, update it as defined
        else {
            my %OldDynamicFieldConfig = %{ $DynamicFieldLookup{ $NewDynamicField->{Name} } };

            my $Success = $DynamicFieldObject->DynamicFieldUpdate(
                %{$NewDynamicField},
                ID         => $OldDynamicFieldConfig{ID},
                FieldOrder => $OldDynamicFieldConfig{FieldOrder},
                ValidID    => $ValidID,
                Reorder    => 0,
                UserID     => 1,
            );
        }

        # check if new field has to be created
        next DYNAMICFIELD if !$CreateDynamicField;

        # create a new field
        my $FieldID = $DynamicFieldObject->DynamicFieldAdd(
            Name       => $NewDynamicField->{Name},
            Label      => $NewDynamicField->{Label},
            FieldOrder => $NextOrderNumber,
            FieldType  => $NewDynamicField->{FieldType},
            ObjectType => $NewDynamicField->{ObjectType},
            Config     => $NewDynamicField->{Config},
            ValidID    => $ValidID,
            UserID     => 1,
        );
        next DYNAMICFIELD if !$FieldID;

        # increase the order number
        $NextOrderNumber++;
    }

    return 1;
}

=item _GroupCreateIfNotExists()

creates group if not texts

    my $Result = $CodeObject->_GroupCreateIfNotExists( Name => 'Some Group Name' );

=cut

sub _GroupCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed ( qw(Name) ) {

        next NEEDED if defined $Param{ $Needed };

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %GroupsReversed = $Kernel::OM->Get('Kernel::System::Group')->GroupList(
        Valid => 0,
    );

    %GroupsReversed = reverse %GroupsReversed;

    return 1 if $GroupsReversed{ $Param{Name} };

    return $Kernel::OM->Get('Kernel::System::Group')->GroupAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _NotificationCreateIfNotExists()

creates notification if not texts

    my $Result = $CodeObject->_NotificationCreateIfNotExists(
        'Agent::PvD::NewTicket',
        'de',
        'sub',
        'body',
    );

=cut

sub _NotificationCreateIfNotExists {
    my ( $Self, $Type, $Lang, $Subject, $Body ) = @_;

    # check if exists
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL   => 'SELECT notification_type FROM notifications WHERE notification_type = ? AND notification_language = ?',
        Bind  => [ \$Type, \$Lang ],
        Limit => 1,
    );
    my $Exists;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Exists = 1;
    }
    return 1 if $Exists;

    # create new
    my $Charset = 'utf8';
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO notifications (notification_type, notification_language, '
            . 'subject, text, notification_charset, content_type, '
            . 'create_time, create_by, change_time, change_by) '
            . 'VALUES( ?, ?, ?, ?, ?, \'text/plain\', '
            . 'current_timestamp, 1, current_timestamp, 1 )',
        Bind => [ \$Type, \$Lang, \$Subject, \$Body, \$Charset ],
    );
}

1;
