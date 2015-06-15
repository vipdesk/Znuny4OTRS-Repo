# --
# Kernel/System/ZnunyHelper.pm - provides some useful functions
# Copyright (C) 2012-2015 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
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
    'Kernel::System::GeneralCatalog',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Time',
    'Kernel::System::DB',
    'Kernel::System::XML',
    'Kernel::System::SysConfig',
    'Kernel::System::Group',
    'Kernel::System::Type',
    'Kernel::System::Service',
    'Kernel::System::SLA',
    'Kernel::System::State',
    'Kernel::System::User',
    'Kernel::System::Valid',
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::DynamicFieldValue',
    'Kernel::System::Package',
    'Kernel::System::GenericInterface::Webservice',
    'Kernel::System::YAML',
);

=head1 NAME

Kernel::System::ZnunyHelper

=head1 SYNOPSIS

All ZnunyHelper functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object. Do not use it directly, instead use:

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $ZnunyHelperObject = $Kernel::OM->Get('Kernel::System::ZnunyHelper');

=cut

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
    for my $Needed (qw(File)) {

        next NEEDED if defined $Param{$Needed};

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
        String => ${$ContentRef},
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
        )
    {
        $PackageObject->_Database(
            Database => $Structure{DatabaseInstall}->{pre},
        );
    }

    # install database (post)
    if (
        IsHashRefWithData( $Structure{DatabaseInstall} )
        && $Structure{DatabaseInstall}->{post}
        )
    {
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

sub _PackageUMain {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(File)) {

        next NEEDED if defined $Param{$Needed};

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
        String => ${$ContentRef},
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
        )
    {
        $PackageObject->_Database(
            Database => $Structure{DatabaseUninstall}->{pre},
        );
    }

    # uninstall database (post)
    if (
        IsHashRefWithData( $Structure{DatabaseUninstall} )
        && $Structure{DatabaseUninstall}->{post}
        )
    {
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

This function adds JavaScript files to the load of defined screens.

my $Result = $ZnunyHelperObject->_JSLoaderAdd(
    AgentTicketPhone => ['Core.Agent.WPTicketOEChange.js'],
);

DEPRECATED: -> use _LoaderAdd() instead

=cut

sub _JSLoaderAdd {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "_JSLoaderAdd function is deprecated, please use _LoaderAdd."
    );

    $Self->_LoaderAdd(%Param);

    return 1;
}

=item _JSLoaderRemove()

This function removes JavaScript files to the load of defined screens.

my $Result = $ZnunyHelperObject->_JSLoaderRemove(
    AgentTicketPhone => ['Core.Agent.WPTicketOEChange.js'],
);

DEPRECATED: -> use _LoaderRemove() instead

=cut

sub _JSLoaderRemove {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'notice',
        Message  => "_JSLoaderRemove function is deprecated, please use _LoaderRemove."
    );

    $Self->_LoaderRemove(%Param);

    return 1;
}

=item _LoaderAdd()

This function adds JavaScript and CSS files to the load of defined screens.

    my %LoaderConfig = (
        AgentTicketPhone => [
            'Core.Agent.WPTicketOEChange.css',
            'Core.Agent.WPTicketOEChange.js'
        ],
    );

    my $Success = $ZnunyHelperObject->_LoaderAdd(%LoaderConfig);

Returns:

    my $Success = 1;

=cut

sub _LoaderAdd {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    my %LoaderConfig = %Param;

    my $ExtensionRegExp = '\.(css|js)$';
    VIEW:
    for my $View ( sort keys %LoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $LoaderConfig{$View} );

        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

        # get existing config for each View
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( $CustomerInterfacePrefix . "Frontend::Module" )->{$View};

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
            Key   => $CustomerInterfacePrefix . "Frontend::Module###" . $View,
            Value => $Config,
        );
    }

    return 1;
}

=item _LoaderRemove()

This function removes JavaScript and CSS files to the load of defined screens.

    my %LoaderConfig = (
        AgentTicketPhone => [
            'Core.Agent.WPTicketOEChange.css',
            'Core.Agent.WPTicketOEChange.js'
        ],
    );

    my $Success = $ZnunyHelperObject->_LoaderRemove(%LoaderConfig);

Returns:

    my $Success = 1;

=cut

sub _LoaderRemove {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %LoaderConfig = %Param;

    VIEW:
    for my $View ( sort keys %LoaderConfig ) {

        next VIEW if !IsArrayRefWithData( $LoaderConfig{$View} );

        # check if we have to add the 'Customer' prefix for the SysConfig key
        my $CustomerInterfacePrefix = '';
        if ( $View =~ m{^Customer} ) {
            $CustomerInterfacePrefix = 'Customer';
        }

        # get existing config for each View
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( $CustomerInterfacePrefix . "Frontend::Module" )->{$View};

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
            )
        {
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
            Key   => $CustomerInterfacePrefix . 'Frontend::Module###' . $View,
            Value => $Config,
        );
    }

    return 1;
}

=item _DynamicFieldsScreenEnable()

This function enables the defined dynamic fields in the needed screens.

    my %Screens = (
        AgentTicketFreeText => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        }
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsScreenEnable(%Screens);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsScreenEnable {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    VIEW:
    for my $View ( sort keys %ScreenDynamicFieldConfig ) {

        next VIEW if !IsHashRefWithData( $ScreenDynamicFieldConfig{$View} );

        # get existing config for each screen
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( "Ticket::Frontend::" . $View );

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

    my %Screens = (
        AgentTicketFreeText => {
            TestDynamicField1 => 1,
            TestDynamicField2 => 1,
            TestDynamicField3 => 1,
            TestDynamicField4 => 1,
            TestDynamicField5 => 1,
        }
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsScreenDisable(%Screens);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsScreenDisable {
    my ( $Self, %Param ) = @_;

    # define the enabled dynamic fields for each screen
    # (taken from sysconfig)
    my %ScreenDynamicFieldConfig = %Param;

    VIEW:
    for my $View ( sort keys %ScreenDynamicFieldConfig ) {

        next VIEW if !IsHashRefWithData( $ScreenDynamicFieldConfig{$View} );

        # get existing config for each screen
        my $Config = $Kernel::OM->Get('Kernel::Config')->Get( "Ticket::Frontend::" . $View );

        # get existing dynamic field config
        my %ExistingSetting;
        if ( IsHashRefWithData( $Config->{DynamicField} ) ) {
            %ExistingSetting = %{ $Config->{DynamicField} };
        }

        my %NewDynamicFieldConfig;
        SETTING:
        for my $ExistingSettingKey ( sort keys %ExistingSetting ) {

            next SETTING if $ScreenDynamicFieldConfig{$View}->{$ExistingSettingKey};

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

    my @DynamicFields = (
        'TestDynamicField1',
        'TestDynamicField2',
        'TestDynamicField3',
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsDelete(@DynamicFields);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsDelete {
    my ( $Self, @DynamicFields ) = @_;

    return 1 if !@DynamicFields;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    return 1 if !IsArrayRefWithData($DynamicFieldList);

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # delete the dynamic fields
    DYNAMICFIELD:
    for my $DynamicFieldName (@DynamicFields) {

        next DYNAMICFIELD if !IsHashRefWithData( $DynamicFieldLookup{$DynamicFieldName} );

        my $ValuesDeleteSuccess = $Kernel::OM->Get('Kernel::System::DynamicField::Backend')->AllValuesDelete(
            DynamicFieldConfig => $DynamicFieldLookup{$DynamicFieldName},
            UserID             => 1,
        );

        my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldDelete(
            %{ $DynamicFieldLookup{$DynamicFieldName} },
            Reorder => 0,
            UserID  => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsDisable()

This function disables the defined dynamic fields

    my @DynamicFields = (
        'TestDynamicField1',
        'TestDynamicField2',
        'TestDynamicField3',
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsDisable(@DynamicFields);

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsDisable {
    my ( $Self, @DynamicFields ) = @_;

    return 1 if !@DynamicFields;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    return 1 if !IsArrayRefWithData($DynamicFieldList);

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    my $InvalidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'invalid',
    );

    # disable the dynamic fields
    DYNAMICFIELD:
    for my $DynamicFieldName (@DynamicFields) {

        next DYNAMICFIELD if !$DynamicFieldLookup{$DynamicFieldName};

        my $Success = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldUpdate(
            %{ $DynamicFieldLookup{$DynamicFieldName} },
            ValidID => $InvalidID,
            Reorder => 0,
            UserID  => 1,
        );
    }

    return 1;
}

=item _DynamicFieldsCreateIfNotExists()

creates all dynamic fields that are necessary

Usable Snippets (SublimeTextAdjustments):
    otrs.dynamicfield.config.text
    otrs.dynamicfield.config.checkbox
    otrs.dynamicfield.config.datetime
    otrs.dynamicfield.config.dropdown
    otrs.dynamicfield.config.textarea
    otrs.dynamicfield.config.multiselect

    my @DynamicFields = (
        {
            Name       => 'TestDynamicField1',
            Label      => "TestDynamicField1",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
        {
            Name       => 'TestDynamicField2',
            Label      => "TestDynamicField2",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
    );

    my $Result = $ZnunyHelperObject->_DynamicFieldsCreateIfNotExists( @DynamicFields );

Returns:

    my $Success = 1;

=cut

sub _DynamicFieldsCreateIfNotExists {
    my ( $Self, @Definition ) = @_;

    # get all current dynamic fields
    my $DynamicFieldList = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 0,
    );

    if ( !IsArrayRefWithData($DynamicFieldList) ) {
        $DynamicFieldList = [];
    }

    my @DynamicFieldExistsNot;
    DYNAMICFIELD:
    for my $NewDynamicField (@Definition) {

        next DYNAMICFIELD if !IsHashRefWithData($NewDynamicField);

        next DYNAMICFIELD if grep { $NewDynamicField->{Name} eq $_->{Name} } @{$DynamicFieldList};

        push @DynamicFieldExistsNot, $NewDynamicField;
    }

    return 1 if !@DynamicFieldExistsNot;

    return $Self->_DynamicFieldsCreate(@DynamicFieldExistsNot);
}

=item _DynamicFieldsCreate()

creates all dynamic fields that are necessary

Usable Snippets (SublimeTextAdjustments):
    otrs.dynamicfield.config.text
    otrs.dynamicfield.config.checkbox
    otrs.dynamicfield.config.datetime
    otrs.dynamicfield.config.dropdown
    otrs.dynamicfield.config.textarea
    otrs.dynamicfield.config.multiselect

    my @DynamicFields = (
        {
            Name       => 'TestDynamicField1',
            Label      => "TestDynamicField1",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
        {
            Name       => 'TestDynamicField2',
            Label      => "TestDynamicField2",
            ObjectType => 'Ticket',
            FieldType  => 'Text',
            Config     => {
                DefaultValue => "",
            },
        },
    );

    my $Success = $ZnunyHelperObject->_DynamicFieldsCreate( @DynamicFields );

Returns:

    my $Success = 1;

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

    if ( !IsArrayRefWithData($DynamicFieldList) ) {
        $DynamicFieldList = [];
    }

    # get the last element from the order list and add 1
    my $NextOrderNumber = 1;
    if (
        IsArrayRefWithData($DynamicFieldList)
        && IsHashRefWithData( $DynamicFieldList->[-1] )
        && $DynamicFieldList->[-1]->{FieldOrder}
        )
    {
        $NextOrderNumber = $DynamicFieldList->[-1]->{FieldOrder} + 1;
    }

    # create a dynamic fields lookup table
    my %DynamicFieldLookup;

    DYNAMICFIELD:
    for my $DynamicField ( @{$DynamicFieldList} ) {

        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);

        $DynamicFieldLookup{ $DynamicField->{Name} } = $DynamicField;
    }

    # create or update dynamic fields
    DYNAMICFIELD:
    for my $NewDynamicField (@DynamicFields) {

        my $CreateDynamicField;

        # check if the dynamic field already exists
        if ( !IsHashRefWithData( $DynamicFieldLookup{ $NewDynamicField->{Name} } ) ) {
            $CreateDynamicField = 1;
        }

        # if the field exists check if the type match with the needed type
        elsif (
            $DynamicFieldLookup{ $NewDynamicField->{Name} }->{FieldType}
            ne $NewDynamicField->{FieldType}
            )
        {
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

creates group if not exists

    my $Success = $ZnunyHelperObject->_GroupCreateIfNotExists(
        Name => 'Some Group Name',
    );

Returns:

    my $Success = 1;

=cut

sub _GroupCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

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

=item _RoleCreateIfNotExists()

creates role if not exists

    my $Success = $ZnunyHelperObject->_RoleCreateIfNotExists(
        Name => 'Some Role Name',
    );

Returns:

    my $Success = 1;

=cut

sub _RoleCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %RolesReversed = $Kernel::OM->Get('Kernel::System::Group')->RoleList(
        Valid => 0,
    );

    %RolesReversed = reverse %RolesReversed;

    return 1 if $RolesReversed{ $Param{Name} };

    return $Kernel::OM->Get('Kernel::System::Group')->RoleAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _TypeCreateIfNotExists()

creates Type if not exists

    my $Success = $ZnunyHelperObject->_TypeCreateIfNotExists(
        Name => 'Some Type Name',
    );

Returns:

    my $Success = 1;

=cut

sub _TypeCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %TypesReversed = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
        Valid => 0,
    );

    %TypesReversed = reverse %TypesReversed;

    return 1 if $TypesReversed{ $Param{Name} };

    return $Kernel::OM->Get('Kernel::System::Type')->TypeAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _StateCreateIfNotExists()

creates State if not exists

    my $Success = $ZnunyHelperObject->_StateCreateIfNotExists(
        Name => 'Some State Name',
        # e.g. new|open|closed|pending reminder|pending auto|removed|merged
        Type => $StateObject->StateTypeLookup( StateType => 'pending auto' ),
    );

Returns:

    my $Success = 1;

=cut

sub _StateCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %StatesReversed = $Kernel::OM->Get('Kernel::System::State')->StateList(
        Valid  => 0,
        UserID => 1
    );

    %StatesReversed = reverse %StatesReversed;

    return 1 if $StatesReversed{ $Param{Name} };

    return $Kernel::OM->Get('Kernel::System::State')->StateAdd(
        %Param,
        ValidID => 1,
        UserID  => 1,
    );
}

=item _StateDisable()

disables a given state

    my @States = (
        'State1',
        'State2',
    );

    my $Success = $ZnunyHelperObject->_StateDisable(@States);

Returns:

    my $Success = 1;

=cut

sub _StateDisable {
    my ( $Self, @States ) = @_;

    return 1 if !@States;

    #get current invalid id
    my $InvalidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'invalid',
    );

    my $Success = 1;

    # disable the states
    STATE:
    for my $StateName (@States) {

        my %State = $Kernel::OM->Get('Kernel::System::State')->StateGet(
            Name => $StateName,
        );
        next STATE if !%State;

        my $UpdateSuccess = $Kernel::OM->Get('Kernel::System::State')->StateUpdate(
            %State,
            ValidID => $InvalidID,
            UserID  => 1,
        );

        if ( !$UpdateSuccess ) {
            $Success = 0;
        }
    }

    return $Success;
}

=item _ServiceCreateIfNotExists()

creates Service if not exists

    my $Success = $ZnunyHelperObject->_ServiceCreateIfNotExists(
        Name => 'Some ServiceName',
        %ITSMParams,                        # optional params for Criticality or TypeID if ITSM is installed
    );

Returns:

    my $Success = 1;

=cut

sub _ServiceCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %ServiceReversed = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
        Valid  => 0,
        UserID => 1
    );

    %ServiceReversed = reverse %ServiceReversed;

    return 1 if $ServiceReversed{ $Param{Name} };

    # split string to check for possible sub services
    my @ServiceArray = split( '::', $Param{Name} );

    # create service with parent
    my $CompleteServiceName = '';
    SERVICE:
    for my $ServiceName (@ServiceArray) {

        my $ParentID;
        if ($CompleteServiceName) {

            $ParentID = $Kernel::OM->Get('Kernel::System::Service')->ServiceLookup(
                Name   => $CompleteServiceName,
                UserID => 1,
            );

            if ( !$ParentID ) {

                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Error while getting ServiceID for parent service "
                        . "'$CompleteServiceName' for new service '" . $Param{Name} . "'.",
                );
                return;
            }

            $CompleteServiceName .= '::';
        }

        $CompleteServiceName .= $ServiceName;

        next SERVICE if $ServiceReversed{$ServiceName};

        my $ServiceID = $Kernel::OM->Get('Kernel::System::Service')->ServiceAdd(
            %Param,
            Name     => $ServiceName,
            ParentID => $ParentID,
            ValidID  => 1,
            UserID   => 1,
        );

        if ( !$ServiceID ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while adding new service '$ServiceName'.",
            );
            return;
        }
    }

    return 1;
}

=item _SLACreateIfNotExists()

creates SLA if not exists

    my $Success = $ZnunyHelperObject->_SLACreateIfNotExists(
        Name => 'Some ServiceName',
        ServiceIDs          => [ 1, 5, 7 ],  # (optional)
        FirstResponseTime   => 120,          # (optional)
        FirstResponseNotify => 60,           # (optional) notify agent if first response escalation is 60% reached
        UpdateTime          => 180,          # (optional)
        UpdateNotify        => 80,           # (optional) notify agent if update escalation is 80% reached
        SolutionTime        => 580,          # (optional)
        SolutionNotify      => 80,           # (optional) notify agent if solution escalation is 80% reached
    );

Returns:

    my $Success = 1;

=cut

sub _SLACreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %SLAReversed = reverse $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
        UserID => 1
    );

    return 1 if $SLAReversed{ $Param{Name} };

    my $ValidID = $Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(
        Valid => 'valid',
    );
    my $SLAID = $Kernel::OM->Get('Kernel::System::SLA')->SLAAdd(
        Name                => $Param{Name},
        ValidID             => $ValidID,
        UserID              => 1,
        ServiceIDs          => $Param{ServiceIDs},
        FirstResponseTime   => $Param{FirstResponseTime},
        FirstResponseNotify => $Param{FirstResponseNotify},
        UpdateTime          => $Param{UpdateTime},
        UpdateNotify        => $Param{UpdateNotify},
        SolutionTime        => $Param{SolutionTime},
        SolutionNotify      => $Param{SolutionNotify},
    );

    return 1;
}

=item _QueueCreateIfNotExists()

creates Queue if not exists

    my $Success = $ZnunyHelperObject->_QueueCreateIfNotExists(
        Name => 'Some Queue Name',
    );

Returns:

    my $Success = 1;

=cut

sub _QueueCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my %QueuesReversed = $Kernel::OM->Get('Kernel::System::Queue')->QueueList();

    %QueuesReversed = reverse %QueuesReversed;

    return 1 if $QueuesReversed{ $Param{Name} };

    return $Kernel::OM->Get('Kernel::System::Queue')->QueueAdd(
        ValidID => 1,
        UserID  => 1,
        %Param,
    );
}

=item _NotificationCreateIfNotExists()

creates notification if not texts

    my $Success = $ZnunyHelperObject->_NotificationCreateIfNotExists(
        'Agent::PvD::NewTicket',   # Notification type
        'de',                      # Notification language
        'sub',                     # Notification subject
        'body',                    # Notification body
    );

Returns:

    my $Success = 1;

=cut

sub _NotificationCreateIfNotExists {
    my ( $Self, $Type, $Lang, $Subject, $Body ) = @_;

    # check if exists
    $Kernel::OM->Get('Kernel::System::DB')->Prepare(
        SQL  => 'SELECT notification_type FROM notifications WHERE notification_type = ? AND notification_language = ?',
        Bind => [ \$Type, \$Lang ],
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

=item _GeneralCatalogItemCreateIfNotExists()

adds a general catalog item if it does not exist

    my $ItemID = $ZnunyHelperObject->_GeneralCatalogItemCreateIfNotExists(
        Name    => 'Test Item',
        Class   => 'ITSM::ConfigItem::Test',
        Comment => 'Class for test item.',
    );

Returns:

    my $ItemID = 1234;

=cut

sub _GeneralCatalogItemCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(Name Class)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    my $MainObject  = $Kernel::OM->Get('Kernel::System::Main');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $MainObject->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    my $ValidID = $ValidObject->ValidLookup(
        Valid => 'valid',
    );

    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # check if item already exists
    my $ItemListRef = $GeneralCatalogObject->ItemList(
        Class => $Param{Class},
        Valid => $ValidID,
    );

    my %ItemList = reverse %{ $ItemListRef || {} };

    if ( $DBObject->{Backend}->{'DB::CaseSensitive'} ) {
        return $ItemList{ $Param{Name} } if $ItemList{ $Param{Name} };
    }
    else {
        my %ItemListLowerCase = map { lc $_ => $ItemList{$_} } sort keys %ItemList;
        return $ItemListLowerCase{ lc $Param{Name} } if $ItemListLowerCase{ lc $Param{Name} };
    }

    # add item if it does not exist
    my $ItemID = $GeneralCatalogObject->ItemAdd(
        Class   => $Param{Class},
        Name    => $Param{Name},
        ValidID => $ValidID,
        Comment => $Param{Comment},
        UserID  => 1,
    );

    return $ItemID;
}

=item _ITSMVersionAdd()

adds or updates a config item version.

    my $VersionID = $ZnunyHelperObject->_ITSMVersionAdd(
        ConfigItemID  => 12345,
        Name          => 'example name',

        ClassID       => 1234,
        ClassName     => 'example class',
        DefinitionID  => 1234,

        DeplStateID   => 1234,
        DeplStateName => 'Production',

        InciStateID   => 1234,
        InciStateName => 'Operational',

        XMLData => {
            'Priority'    => 'high',
            'Product'     => 'test',
            'Description' => 'test'
        },
    );

Returns:

    my $VersionID = 1234;

=cut

sub _ITSMVersionAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    NEEDED:
    for my $Needed (qw(ConfigItemID Name)) {

        next NEEDED if defined $Param{$Needed};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter '$Needed' is needed!",
        );
        return;
    }

    if ( !$Param{DeplStateID} && !$Param{DeplStateName} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter 'DeplStateID' or 'DeplStateName' needed!",
        );
        return;
    }
    if ( !$Param{InciStateID} && !$Param{InciStateName} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter 'DeplStateID' or 'DeplStateName' needed!",
        );
        return;
    }
    if ( $Param{XMLData} && !IsHashRefWithData( $Param{XMLData} ) ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Parameter 'XMLData' as hash ref needed!",
        );
        return;
    }

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    # check if general catalog module is installed
    my $ITSMConfigItemLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::ITSMConfigItem',
        Silent => 1,
    );

    return if !$ITSMConfigItemLoaded;

    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');

    my $ConfigItemID = $Param{ConfigItemID};
    my %ConfigItem = %{ $Param{XMLData} || {} };

    my %Version = $Self->_ITSMVersionGet(
        ConfigItemID => $ConfigItemID,
    );

    # get deployment state list
    my %DeplStateList = %{
        $GeneralCatalogObject->ItemList(
            Class => 'ITSM::ConfigItem::DeploymentState',
            )
            || {}
    };
    my %DeplStateListReverse = reverse %DeplStateList;

    my %InciStateList = %{
        $GeneralCatalogObject->ItemList(
            Class => 'ITSM::Core::IncidentState',
            )
            || {}
    };
    my %InciStateListReverse = reverse %InciStateList;

    # get definition
    my $DefinitionID = $Param{DefinitionID};
    if ( !$DefinitionID ) {

        # get class id or name
        my $ClassID = $Param{ClassID};
        if ( $Param{ClassName} ) {

            # get valid id
            my $ValidID = $ValidObject->ValidLookup(
                Valid => 'valid',
            );

            my $ItemListRef = $GeneralCatalogObject->ItemList(
                Class => 'ITSM::ConfigItem::Class',
                Valid => $ValidID,
            );

            my %ItemList = reverse %{ $ItemListRef || {} };

            $ClassID = $ItemList{ $Param{ClassName} };
        }

        my $XMLDefinition = $ConfigItemObject->DefinitionGet(
            ClassID => $ClassID,
        );

        $DefinitionID = $XMLDefinition->{DefinitionID};
    }

    if ( $Param{Name} ) {
        $Version{Name} = $Param{Name};
    }
    if ( $Param{DefinitionID} || $Param{ClassID} || $Param{ClassName} ) {
        $Version{DefinitionID} = $DefinitionID;
    }
    if ( $Param{DeplStateID} ) {
        $Version{DeplStateID} = $Param{DeplStateID};
    }
    if ( $Param{InciStateID} ) {
        $Version{InciStateID} = $Param{InciStateID};
    }
    if ( $Param{DeplStateName} ) {
        $Version{DeplStateID} = $DeplStateListReverse{ $Param{DeplStateName} };
    }
    if ( $Param{InciStateName} ) {
        $Version{InciStateID} = $InciStateListReverse{ $Param{InciStateName} };
    }

    %ConfigItem = ( %{ $Version{XMLData} || {} }, %ConfigItem );

    my $XMLData = [
        undef,
        {
            'Version' => [
                undef,
                {
                    map {
                        $_ => [
                            undef,
                            { 'Content' => $ConfigItem{$_} }
                            ]
                        } sort keys %ConfigItem
                },
            ],
        },
    ];

    my $VersionID = $ConfigItemObject->VersionAdd(
        ConfigItemID => $ConfigItemID,
        Name         => $Version{Name},
        DefinitionID => $Version{DefinitionID},
        DeplStateID  => $Version{DeplStateID},
        InciStateID  => $Version{InciStateID},
        XMLData      => $XMLData,
        UserID       => 1,
    );

    return $VersionID;
}

=item _ITSMVersionExists()

checks if a version already exists without returning a error.


    my $Found = $ZnunyHelperObject->_ITSMVersionExists(
        VersionID  => 123,
    );

    or

    my $Found = $ZnunyHelperObject->_ITSMVersionExists(
        ConfigItemID => 123,
    );


Returns:

    my $Found = 1;

=cut

sub _ITSMVersionExists {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{VersionID} && !$Param{ConfigItemID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need VersionID or ConfigItemID!',
        );
        return;
    }

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    # check if general catalog module is installed
    my $ITSMConfigItemLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::ITSMConfigItem',
        Silent => 1,
    );

    return if !$ITSMConfigItemLoaded;

    if ( $Param{VersionID} ) {

        # get version
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => 'SELECT 1 FROM configitem_version WHERE id = ?',
            Bind  => [ \$Param{VersionID} ],
            Limit => 1,
        );
    }
    else {

        # get version
        $Kernel::OM->Get('Kernel::System::DB')->Prepare(
            SQL   => 'SELECT 1 FROM configitem_version WHERE configitem_id = ? ORDER BY id DESC',
            Bind  => [ \$Param{ConfigItemID} ],
            Limit => 1,
        );
    }

    # fetch the result
    my $Found;
    while ( my @Row = $Kernel::OM->Get('Kernel::System::DB')->FetchrowArray() ) {
        $Found = 1;
    }

    return $Found;
}

=item _ITSMVersionGet()

get a config item version.

    my %Version = $ZnunyHelperObject->_ITSMVersionGet(
        ConfigItemID  => 12345,
    );

Returns:

    my %Version = (
        ConfigItemID  => 12345,

        DefinitionID  => 1234,
        DeplStateID   => 1234,
        DeplStateName => 'Production',
        InciStateID   => 1234,
        InciStateName => 'Operational',
        Name          => 'example name',
        XMLData => {
            'Priority'    => 'high',
            'Product'     => 'test',
            'Description' => 'test'
        },
    );

=cut

sub _ITSMVersionGet {
    my ( $Self, %Param ) = @_;

    # check if general catalog module is installed
    my $GeneralCatalogLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::GeneralCatalog',
        Silent => 1,
    );

    return if !$GeneralCatalogLoaded;

    # check if general catalog module is installed
    my $ITSMConfigItemLoaded = $Kernel::OM->Get('Kernel::System::Main')->Require(
        'Kernel::System::ITSMConfigItem',
        Silent => 1,
    );

    return if !$ITSMConfigItemLoaded;

    my $ConfigItemObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    return if !$Self->_ITSMVersionExists(%Param);

    my $VersionRef = $ConfigItemObject->VersionGet(
        %Param,
        XMLDataGet => 1,
    );

    return if !IsHashRefWithData($VersionRef);

    my %VersionConfigItem;
    $VersionConfigItem{XMLData} ||= {};
    if ( IsHashRefWithData( $VersionRef->{XMLData}->[1]->{Version}->[1] ) ) {

        FIELD:
        for my $Field ( sort keys %{ $VersionRef->{XMLData}->[1]->{Version}->[1] } ) {
            next FIELD if !IsArrayRefWithData( $VersionRef->{XMLData}->[1]->{Version}->[1]->{$Field} );

            my $Value = $VersionRef->{XMLData}->[1]->{Version}->[1]->{$Field}->[1]->{Content};

            next FIELD if !defined $Value;

            $VersionConfigItem{XMLData}->{$Field} = $Value;
        }
    }

    for my $Field (qw(ConfigItemID Name DefinitionID DeplStateID DeplState InciStateID InciState)) {
        $VersionConfigItem{$Field} = $VersionRef->{$Field};
    }

    return %VersionConfigItem;
}

=item _WebserviceCreateIfNotExists()

creates webservices that not exist yet

    # installs all .yml files in $OTRS/scripts/webservices/
    # name of the file will be the name of the webservice
    my $Result = $CodeObject->_WebserviceCreateIfNotExists(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

OR:

    my $Result = $CodeObject->_WebserviceCreateIfNotExists(
        Webservices => {
            'New Webservice 1234' => '/path/to/Webservice.yml',
            ...
        }
    );

=cut

sub _WebserviceCreateIfNotExists {
    my ( $Self, %Param ) = @_;

    my $Webservices = $Param{Webservices};
    if ( !IsHashRefWithData($Webservices) ) {
        $Webservices = $Self->_WebservicesGet(
            SubDir => $Param{SubDir},
        );
    }

    return 1 if !IsHashRefWithData($Webservices);

    my $WebserviceList = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList();
    if ( ref $WebserviceList ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Error while getting list of Webservices!"
        );
        return;
    }

    WEBSERVICE:
    for my $WebserviceName ( sort keys %{$Webservices} ) {

        # stop if already added
        next WEBSERVICE if grep { $WebserviceName eq $_ } sort values %{$WebserviceList};

        my $WebserviceYAMLPath = $Webservices->{$WebserviceName};

        # read config
        my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $WebserviceYAMLPath,
        );

        if ( !$Content ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't read $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        my $Config = $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => ${$Content} );

        if ( !$Config ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while loading $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        # add webservice to the system
        my $WebserviceID = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceAdd(
            Name    => $WebserviceName,
            Config  => $Config,
            ValidID => 1,
            UserID  => 1,
        );

        if ( !$WebserviceID ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while adding Webservice '$WebserviceName' from $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }
    }

    return 1;
}

=item _WebserviceCreate()

creates or updates webservices

    # installs all .yml files in $OTRS/scripts/webservices/
    # name of the file will be the name of the webservice
    my $Result = $CodeObject->_WebserviceCreate(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

OR:

    my $Result = $CodeObject->_WebserviceCreate(
        Webservices => {
            'New Webservice 1234' => '/path/to/Webservice.yml',
            ...
        }
    );

=cut

sub _WebserviceCreate {
    my ( $Self, %Param ) = @_;

    my $Webservices = $Param{Webservices};
    if ( !IsHashRefWithData($Webservices) ) {
        $Webservices = $Self->_WebservicesGet(
            SubDir => $Param{SubDir},
        );
    }

    return 1 if !IsHashRefWithData($Webservices);

    my $WebserviceList = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList();
    if ( ref $WebserviceList ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Error while getting list of Webservices!"
        );
        return;
    }
    my %WebserviceListReversed = reverse %{$WebserviceList};

    WEBSERVICE:
    for my $WebserviceName ( sort keys %{$Webservices} ) {

        my $WebserviceID           = $WebserviceListReversed{$WebserviceName};
        my $UpdateOrCreateFunction = 'WebserviceAdd';

        if ($WebserviceID) {
            $UpdateOrCreateFunction = 'WebserviceUpdate';
        }

        # stop if already added
        next WEBSERVICE if grep { $WebserviceName eq $_ } sort values %{$WebserviceList};

        my $WebserviceYAMLPath = $Webservices->{$WebserviceName};

        # read config
        my $Content = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $WebserviceYAMLPath,
        );

        if ( !$Content ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Can't read $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        my $Config = $Kernel::OM->Get('Kernel::System::YAML')->Load( Data => ${$Content} );

        if ( !$Config ) {

            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while loading $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }

        # add or update webservice
        my $Success = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->$UpdateOrCreateFunction(
            ID      => $WebserviceID,
            Name    => $WebserviceName,
            Config  => $Config,
            ValidID => 1,
            UserID  => 1,
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while updating/adding Webservice '$WebserviceName' from $WebserviceYAMLPath!"
            );
            next WEBSERVICE;
        }
    }

    return 1;
}

=item _WebserviceDelete()

deletes webservices

    # deletes all .yml files webservices in $OTRS/scripts/webservices/
    # name of the file will be the name of the webservice
    my $Result = $CodeObject->_WebserviceDelete(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

OR:

    my $Result = $CodeObject->_WebserviceDelete(
        Webservices => {
            'Not needed Webservice 1234' => 1, # value is not used
            ...
        }
    );

=cut

sub _WebserviceDelete {
    my ( $Self, %Param ) = @_;

    my $Webservices = $Param{Webservices};
    if ( !IsHashRefWithData($Webservices) ) {
        $Webservices = $Self->_WebservicesGet(
            SubDir => $Param{SubDir},
        );
    }

    return 1 if !IsHashRefWithData($Webservices);

    my $WebserviceList = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceList();
    if ( ref $WebserviceList ne 'HASH' ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "Error while getting list of Webservices!"
        );
        return;
    }
    my %WebserviceListReversed = reverse %{$WebserviceList};

    WEBSERVICE:
    for my $WebserviceName ( sort keys %{$Webservices} ) {

        # stop if already deleted
        next WEBSERVICE if !$WebserviceListReversed{$WebserviceName};

        # delete webservice
        my $Success = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceDelete(
            ID     => $WebserviceListReversed{$WebserviceName},
            UserID => 1,
        );

        if ( !$Success ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Error while deleting Webservice '$WebserviceName'!"
            );
            return;
        }
    }

    return 1;
}

=item _WebservicesGet()

gets a list of .yml files from $OTRS/scripts/webservices

    my $Result = $CodeObject->_WebservicesGet(
        SubDir => 'Znuny4OTRSAssetDesk', # optional
    );

    $Result = {
        'Webservice'          => '$OTRS/scripts/webservices/Znuny4OTRSAssetDesk/Webservice.yml',
        'New Webservice 1234' => '$OTRS/scripts/webservices/Znuny4OTRSAssetDesk/New Webservice 1234.yml',
    }

=cut

sub _WebservicesGet {
    my ( $Self, %Param ) = @_;

    my $WebserviceDirectory = $Kernel::OM->Get('Kernel::Config')->Get('Home')
        . '/scripts/webservices';

    if ( IsStringWithData( $Param{SubDir} ) ) {
        $WebserviceDirectory .= '/' . $Param{SubDir};
    }

    my @FilesInDirectory = $Kernel::OM->Get('Kernel::System::Main')->DirectoryRead(
        Directory => $WebserviceDirectory,
        Filter    => '*.yml',
    );

    my %Webservices;
    for my $FileWithPath (@FilesInDirectory) {

        my $WebserviceName = $FileWithPath;
        $WebserviceName =~ s{\A .+? \/ ([^\/]+) \. yml \z}{$1}xms;

        $Webservices{$WebserviceName} = $FileWithPath;
    }

    return \%Webservices;
}

=item _PackageSetupInit()

set up initial steps for package setup

    my $Success = $ZnunyHelperObject->_PackageSetupInit();

Returns:

    my $Success = 1;

=cut

sub _PackageSetupInit {
    my ( $Self, %Param ) = @_;

    # rebuild ZZZ* files
    $Kernel::OM->Get('Kernel::System::SysConfig')->WriteDefault();

    # define the ZZZ files
    my @ZZZFiles = (
        'ZZZAAuto.pm',
        'ZZZAuto.pm',
    );

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

    # make sure to use a new config object
    $Kernel::OM->ObjectsDiscard(
        Objects => ['Kernel::Config'],
    );

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
