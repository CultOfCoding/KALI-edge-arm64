#!/usr/bin/perl -w
# $Header: /home/sjs/bin/RCS/adb_proxy,v 1.7 2018/05/28 22:59:14 sjs Exp $
use strict;
use warnings;
use Cwd 'abs_path';
use FileHandle;
$|++;

my ($Exec, $Func) = (abs_path($0) =~ m{^(.*)/(.*)});

my %CmdTable = (
    'install' => {exec => \&InstallAPK
        , help => "install package: Install t the apk files passed in.\n"
            . "        If the first arg is '-s', start the apk.  NOTE! if more\n"
            . "        than one apk file is passed in, only the last is started.\n"},
    'start' => {exec => \&StartAPK
        , help => "Start the app associated with the apk file passed in.\n"
            . "        If the first arg is '-s', start the apk.\n"},
    'ls' =>       {exec => \&DoLs
        , help => "Execute the ls command on the target.\n"},
    'memory' => {exec => \&GetMemory
        , help => "cat /proc/meminfo on the device.\n"},
    'packages' => {exec => \&GetPackages
        , help => "packages <regex>  List packages found on the device.\n"
            . "        Filter using <regex> if one is given.\n"},
    'permissions' => {exec => \&permissions
        , help => "grantedPermissions <regex> [revoke|grant a]\n"
            . "        if neither grant or revoke are given, list granted\n"
            . "        permissions. if grant or revoke is requested and 'a'\n"
            . "        is requested, grant/revoke all privelages.  if 'a' is not\n"
            . "        set, allow user to select privalage to grant/revoke.\n"
            . "        The regex allows the user to select the package to operate\n"
            . "        on.\n"},
    'pull'      => {exec => \&DoPull
        , help => "device_file host_file\n"
            . "        Read device_file from the device to host_file.\n"},
    'push'      => {exec => \&DoPush
        , help =>  "host_file device_file\n"
            . "        host_file device_file    Copy the host_file to the device_file.\n"},
    'reset'    => {exec => \&DoReset
        , help => "<-s>   Reset ADB abd display detected devices.  If <-s> is set,\n"
            . "        reset is executed as root.  'Reset' means adb kill-server;\n"
            . "        adb start-server; adb devices." },
    'restart'  => {exec => \&DoRestart
        , help =>  "regex_for_package\n"
            . "        Stop and then restart the app based on the package selected\n"
            . "        by the regex.\n"
    },
    'stop'  => {exec => \&DoStop
        , help =>  "regex_for_package\n"
            . "        Stop and the app based on the package selected\n"
            . "        by the regex.\n"
    },
    'shell'      => {exec => \&DoShell
        , help => "Execute an interactive shell command on host.\n"
    },
    'uninstall' => {exec => \&UninstallPackage
        , help => "unistall package: remove the apk indicated\n"
            . "        by the package regex passed in." },
);
my $USAGE = "USAGE of $Func:
    To run a function on one or more devices, run
        \"$Func device_0 ... device_n command ...\"
    To run a function on all devices, run
        \"$Func all command...\"
    '-f'   Many options require user confirmation.  To bypass this
    and \"force\" the operation, first argument should be '-f'.
    Possible commands are:\n"
    . join('', map {
        sprintf("    %-10s: %s\n", $_, $CmdTable{$_}{help});
    } sort keys %CmdTable)
    . "\n";

chomp(my $ADB=`/usr/bin/which adb`);
die $USAGE, "Failed to find adb\n" unless $ADB;
chomp (my $AAPT = `/usr/bin/which aapt`);
die $USAGE, "Failed to locate aapt.\n" unless ($AAPT);

my %FoundDevices = ();
my %FoundDeviceIndexes = ();
my @SelectedDevices = ();
my (%IndexedDevices, %DeviceIds);
sub PrintDevices {
    my $rv = "";
    for my $id (@SelectedDevices) {
        $rv .= sprintf("%2d) %s\n"
            , $FoundDevices{$id}{index} + 1, $FoundDevices{$id}{desc});
    }
    return $rv;
}
my $Verbose;
if (grep $_ eq '-v', @ARGV) {
    $Verbose++;
    @ARGV = grep $_ ne '-v', @ARGV;
}
my $Force;
if (grep $_ eq '-f', @ARGV) {
    if (YesNo("Really, force operation?", 'y')) {
        $Force++;
        @ARGV = grep $_ ne '-f', @ARGV;
    }
    else {
        die "Aborting...";
    }
}

# executables needed.
my @PropertyKeys = qw(
    ro.build.version.release
    ro.build.version.sdk
    ro.product.brand
    ro.product.manufacturer
    ro.product.model
    ro.product.name
);

# Return a list of hash references to device properties.
sub GetDevices {
    my %device_properties;
    chomp(my @devices = `$ADB devices -l`);
    if(my @unauthorized = grep /\bunauthorized\b/, @devices) {
        die "Unauthorized devices found:\n"
        , join("\n", @unauthorized, '');
    }
    my $index = 0;
    for my $device (sort @devices) {
        if ($device =~ m{^(\S+)\s+device\s+(.*)}) {
            my $id = $1;
            $FoundDeviceIndexes{$index+1} = $id;
            chomp(my @properties = `$ADB -s $id shell getprop`);
            my %dev_info = (id => $id);
            $dev_info{index} = $index++;
            map {s/\cM//; s/[\[\]]//g;}@properties;
            for my $key (@PropertyKeys) {
                my $k = $key;
                $k =~ s/^ro\.[^\.]+\.//;
                if ((grep(/$key/, @properties))[0] =~ m{:\s+(.*)}) {
                    $dev_info{$k} = $1;
                }
            }
            $dev_info{desc} = sprintf('%-19s %-20s Android %-6s API=%-3s',
                $id, "$dev_info{brand} $dev_info{model}",
                $dev_info{'version.release'}, $dev_info{'version.sdk'});
            $device_properties{$id} = \%dev_info;
        }
    }
    return %device_properties;
}
sub GetInstalledAPK {
    my $device = shift @_;
    my @cmd = ($ADB, '-s', $device,
        qw(shell pm list packages -f));
    my @p = `@cmd`;
    map {s/[\n\r]*$//} @p; # for some reason, chomp wasn't working.
    my %packages = map {reverse m{^[^:]+:([^=]+).*=([^=]+)$}} @p;
    return %packages;
}
sub GetInstalledAPK_by_regex {
    my ($device, $regex) = @_;
    my %packages = ();
    my %installed = GetInstalledAPK($device);
    while (my($key, $val) = each %installed) {
        if ("$key\n$val" =~ m{$regex}im) {
            $packages{$key} = $val;
        } 
    }
    return %packages;
}
sub DoShell {
    for my $id (@SelectedDevices) {
        my $cmd = join(' ', $ADB, '-s', $id, 'shell');
        print "Executing \"$cmd\"\n";
        exec $cmd
#        open(my $fh, $cmd) || die "open \"$cmd\" FAILED\n";
#        my @lines = <$fh>;
#        $fh->close();
#        map { s/[\r|\n].*//s; } @lines;
#        print join("\n", @lines, "\n");
    }
}
sub DoLs {
    for my $id (@SelectedDevices) {
        print "======== $FoundDevices{$id}{desc}\n";
        print"> @_\n";
        my $cmd = join(' ', $ADB, '-s', $id, 'shell', @_, '2>&1', '|');
        open(my $fh, $cmd) || die "open \"$cmd\" FAILED\n";
        my @lines = <$fh>;
        $fh->close();
        map { s/[\r|\n].*//s; } @lines;
        print join("\n", @lines, "\n");
    }
}
sub DoPush {
    my $subName = shift @_;
    die $USAGE, "$subName: wrong number of arguments.\n" unless @_ == 2;
    unless (-f $_[0]) {
        die $USAGE, "push: device_file doesn't exist or isn't readable.\n";
    }
    for my $id (@SelectedDevices) {
        my @cmd = ($ADB, '-s', $id, $subName, @_, '2>&1');
        my $response = `@cmd`;
        print $response, "\n";
    }
}
sub DoPull {
    die $USAGE, "pull: wrong number of arguments.\n" unless @_ == 2;
    for my $id (@SelectedDevices) {
        my $cmd = join(' ',$ADB, '-s', $id, @_, '2>&1', '|');
        open(my $fh, $cmd) || die "open \"$cmd\" FAILED\n";
        while (defined(my $line = <$fh>)) {
            print $line;
        }
        $fh->close();
    }
}
sub PrintPackages {
    my ($prompt, $packageInfoRef) = @_;
    my $max = 0;
    foreach (keys %$packageInfoRef) {
        $max = length $_ if length $_ > $max;
    }
    print $prompt, "\n";
    my $i = 1;
    while (my ($key, $val) = each %{$packageInfoRef}) {
        printf("%3d) %-${max}s %s\n", $i++, $key, $val)
    }
}
sub GetMemory {
    my ($cmd) = @_;
    foreach my $device (@SelectedDevices) {
        print "======== $FoundDevices{$device}{desc}\n";
        my @cmd = ($ADB, '-s', $device,
            qw(shell cat /proc/meminfo));
        my @p = `@cmd`;
        print "@p";
    }
}
sub GetPackages {
    for my $id (@SelectedDevices) {
        print "======== $FoundDevices{$id}{desc}\n";
        my ($cmd, $regex) = @_;
        my %byPackage = (defined $regex)
            ? GetInstalledAPK_by_regex ($id, $regex)
            : GetInstalledAPK($id);
        my $max;
        if (defined $regex) {
            if (%byPackage) {
                PrintPackages("Regex \"$regex\":", \%byPackage);
            }
            else {
                print "No packages found to match regex \"$regex\"\n";
            }
        }
        else {
            PrintPackages(
                join(' ', "Found ", scalar keys %byPackage, " packages."),
                \%byPackage);
        }
    }
}
sub StartAPK {
    my ($cmd, $apk) = @_;
    die $CmdTable{$cmd}{help}, "\"@_\", Wrong arg count\n" unless @_ == 2;
    unless ($apk =~ /\.apk/
            && (`/usr/bin/file $apk` =~ /\b(?:Jar|Zip)\b/)) {
        die $USAGE, $CmdTable{$cmd}{help}
            , "$apk doesn't look like an apk file.\n";
    }
    my $apk_name = ($apk =~ m{([^/]*.apk)$})[0];
    my $apk_base = ($apk =~ m{^.*/(.*)$})[0];
    my $badging = `$AAPT dump badging $apk`;
    my ($package, $activity) = ($badging =~ m{
            ^package:\s+name='([^']+)'
            .*
            ^launchable-activity:\s+name='([^']+)'
        }msx
    );
    for my $id (@SelectedDevices) {
        printf("========== %d) %s\n",
            $FoundDevices{$id}{index} + 1,
            $FoundDevices{$id}{desc});
        my %byPackage = GetInstalledAPK($id);
        my $apk_base = ($apk =~ m{^.*/(.*)$})[0];
        print "Starting $apk_base\n";
        my @start_cmd = ("$ADB", '-s', $id, qw(shell am start -n)
            , "$package/$activity", '2>&1');
        my $result = `@start_cmd`;
        if ($result =~ m{\bSuccess\b}) {
            print "Success...\n";
        }
        elsif ($result =~ /task has been brought to the front/) {
            print "Current task was running and brought to front.\n";
        }
        else {
            die "\"@start_cmd\" FAILED\n";
        }
    }
}
sub InstallAPK {
    my ($cmd) = shift @_;
    my $startAPK = (@_ && $_[0] eq '-s') ? shift @_ : "";
    my @apk_files = @_;

    die $CmdTable{$cmd}{help}, "Wrong arg count\n" unless @apk_files;
    if (my @bad = grep !-f, @apk_files) {
        die $USAGE, $CmdTable{$cmd}{help}
            , "APK files not found:\n\t",
            join("\n\t", @bad), "\n";
    }
    for my $id (@SelectedDevices) {
        printf("========== %d) %s\n",
            $FoundDevices{$id}{index} + 1,
            $FoundDevices{$id}{desc});
        foreach my $apk (@apk_files) {
            unless ($apk =~ /\.apk/
                    && (`/usr/bin/file $apk` =~ /\b(?:Jar|Zip)\b/i)) {
                die $USAGE, $CmdTable{$cmd}{help}
                    , "$apk doesn't look like an apk file.\n";
            }
            my $apk_name = ($apk =~ m{([^/]*.apk)$})[0];
            my $badging = `$AAPT dump badging $apk`;
            my ($package, $activity) = ($badging =~ m{
                    ^package:\s+name='([^']+)'
                    .*
                    ^launchable-activity:\s+name='([^']+)'
                }msx
            );
            my %byPackage = GetInstalledAPK($id);
            my $apk_base = ($apk =~ m{^.*/(.*)$})[0];
            if (exists $byPackage{$package}) {
                print "Uninstalling $apk_base\n"; 
                $cmd = "$ADB -s $id uninstall $package 2>&1";
                my $result = `$cmd`;
                print "Uninstalling $apk_base: \"$cmd\"\n:Result:\"$result\"\n";
                unless($result =~ /Success/) {
                    die "Uninstall FAILED: $result\n";
                }
            }
            print "Installing $apk_base\n";
            my @install_cmd = ("$ADB", '-s', $id, 'install', '-t', $apk, '2>&1');
            my $result = `@install_cmd`;
            print "Installing; \"@install_cmd\"\nResuilt:\"$result\n";
            if($result =~ /Success/) {
                print "Install succeeded.\n";
            }
            else {
                die "Install FAILED: $result\n";
            }
            if ($apk eq $apk_files[$#apk_files] && $startAPK) {
                StartAPK('start', $apk);
            }
        }
    }
}
sub YesNo {
    my $prompt = shift @_;
    my $positive = (@_ > 0) ? shift @_ : "y";
    my $in = "";
    my $rv = "";
    $positive = uc($positive);
    if ($positive !~ /^[YN]$/) {
        die "YesNo: positive response must be \"y\" or \"n\"\n";
    }
    my $p = ($positive eq "Y") ? "Y/n" : "y/N";
    do {
        print "$prompt ($p) > ";
        if ($Force) {
            print "user selected '-f'\n";
            $in = $positive;
        }
        else {
            chomp($in = uc(<STDIN>));
        }
        if ($in =~ /^\s*([YN])\s*$/) {
            $in = $1;
            $rv = $in eq $positive;
        }
        else {
            print "Please enter y or n.\n";
            $in = "";
        }
    } until ($in);
    return $rv;
}
sub UninstallPackage {
    my ($cmd, @packages) = @_;
    die $USAGE, $CmdTable{$cmd}{help}
        , "Wrong arg count\n" unless @packages >= 1;
    foreach my $package (@packages) {
        print "Removing package $package\n";
        for my $id (@SelectedDevices) {
            my %byPackage = GetInstalledAPK($id);
            printf("========== %d) %s\n",
                $FoundDevices{$id}{index} + 1,
                $FoundDevices{$id}{desc});
            my @rm_pkg = grep $_ =~ /$package/i, keys %byPackage;
            if (@rm_pkg == 0) {
                print STDERR $CmdTable{$cmd}{help}
                    , "\nNo package matching \"$package\" not found.\n";
                next;
            }
            foreach my $pkg (@rm_pkg) {
                if (YesNo("remove package \"$pkg\"")) {
                    print `$ADB -s $id uninstall $pkg 2>&1`;
                }
                else {
                    print "skipping $package...\n"
                }
            }
        }
    }
}
sub DoReset {
    unless (@_ == 1 || (@_ == 2 && $_[1] eq '-s')) {
        die $USAGE, "Reset: wrong arguments.\n";
    }
    # unless (getpwuid($<) eq 'root') {
    #    my @exec = ('/usr/bin/sudo', $0, "ADB=$ADB", @ARGV);
    #    exec @exec;
    #}
    # Reset the hub.  In this case: bus 004 device 002
    # system('/usr/bin/sudo', '/root/usbreset', '/dev/bus/usb/004/002');
    my @cmd0 = ((@_ == 2) ? ('/usr/bin/sudo', $ADB) : ($ADB));
    system(@cmd0, 'kill-server');
    system(@cmd0, 'start-server');
    print "Looking for devices after reset.\n";
    system($ADB, 'devices');
}
# use dumpsys to catch permissions on a device/package basis.
sub pmDumpSys {
    my  ($id, $package) = @_;
    my @cmd = ($ADB, '-s' , $id , 'shell'
        , '/system/bin/dumpsys', 'package', $package);
    open(my $pm, '-|', @cmd) || die "open \"@cmd\" FAILED: $!\n";
    my @result = map {s{\cM.*\n}{}; s{^\s+}{}; $_;} <$pm>;
    close $pm;
    # lines starting a permission end with [Pp]ermissions:.
    # All lines from the first stating a permission until the 
    # last line of dumpsys output contain permission info.
    my %permissions = ();
    my $currentPermission;
    foreach (@result) {
        if (/(\w+\s*[Pp]ermissions):$/ || $currentPermission) {
            if (!defined $currentPermission || $currentPermission ne $1) {
                $currentPermission = $1;
                $permissions{$currentPermission} = [];
            }
            else {
                push @{$permissions{$currentPermission}}, $_;
            }
        }
    }
    return %permissions;
}
sub permissions {
    my $cmd     = shift @_;
    my $regex   = shift @_;
    my $operation = (defined $_[0])
                        ? ($_[0] =~ /^grant|revoke$/)
                            ? shift @_
                            : die "$cmd: unrecognized arg: $_[0]\n"
                        : 'list';
    my $range = (defined $_[0])
                        ? ($_[0] eq 'a')
                            ? 'all'
                            : die "$cmd: unrecognized arg: $_[0]\n"
                        : '';
    die "$cmd: No package given.\n" unless defined $regex;
    # Can't revoke/grant these.
    my %exclude = qw (
        com.android.launcher.permission.INSTALL_SHORTCUT    1
        android.permission-group.STORAGE                    1
    );
    for my $id (@SelectedDevices) {
        printf("========== %d) %s\n",
            $FoundDevices{$id}{index} + 1,
            $FoundDevices{$id}{desc});
        my $sdkVersion = $FoundDevices{$id}{'version.sdk'};
        if (($operation eq 'revoke' || $operation eq 'grant') && $sdkVersion < 23) {
            print "        Can't revoke/deny permission on "
                . "pre Android M/sdk version < 23.\n";
            next;
        }
        my @packages = do {
            my %x = GetInstalledAPK_by_regex($id, $regex);
            keys %x;
        };
        if (!@packages) {
            die "$cmd: No packages match regex $regex\n";
        }
        foreach my $package (@packages) {
            print "    Package: $package\n";
            # permissions are returned as a hash => array ref.
            # keys are the permission name and the ref contains
            # the permissions granted.  Note that a permission
            # may actually have no instances granted.
            my %permissions = pmDumpSys($id, $package);
            my %granted = (exists $permissions{'requested permissions'})
                ? map{$_, 1} grep(/:\s+granted=true/ && !$exclude{$_}
                    , @{$permissions{'runtime permissions'}})
                : ();
            my %requested = (exists $permissions{'requested permissions'})
                ? map {$_, 1}
                    grep(!$exclude{$_},@{$permissions{'requested permissions'}})
                : ();
            if ($operation eq 'list') {
                if (%permissions) {
                    for my $key (sort keys %permissions) {
                        my @perms = @{$permissions{$key}};
                        print "        $key\n";
                        if (@perms) {
                            print map {"            $_\n"} @perms;
                        }
                        else {
                            print "            NONE\n";
                        }
                    }
                }
                else {
                    print "        NONE\n";
                }
            }
            elsif ($operation eq 'revoke') {
                if (%granted) {
                    foreach my $perm (keys %granted) {
                        $perm =~ s/:.*//;
                        print "    Revoke $perm...\n";
                        if ($range eq 'all' || YesNo("Revoke $perm")) {
                            my @cmd = ($ADB, '-s', $id, 'shell',
                                '/system/bin/pm', 'revoke', $package, $perm,
                                '2>&1');
                            open (my $op, '-|', @cmd)
                                || die ("$cmd: @cmd FAILED:$!\n");
                            my @result = <$op>;
                            if ($?) {
                                die "@cmd FAILED:$!\n@result\n";
                            }
                            close $op;
                        }
                    }
                }
                else {
                    print "Revoke permissions for $package: NONE\n";
                }
            }
            elsif ($operation eq 'grant') {
                if (%requested) {
                    foreach my $perm (keys %requested) {
                        if (defined $granted{$perm}) {
                            print "    $perm already granted.\n";
                        }
                        elsif ($range eq 'all' || YesNo("grant $perm")) {
                            print "    Grant $perm...\n";
                            my @cmd = ($ADB, '-s', $id, 'shell',
                                '/system/bin/pm', 'grant', $package, $perm,
                                '2>&1');
                            open (my $op, '-|', @cmd)
                                || die ("$cmd: @cmd FAILED:$!\n");
                            my @result = map {s/\cM\cJ$//; $_} <$op>;
                            close $op;
                            if (@result) {
                                print STDERR "Possible error:\n$result[0]\n\n";
                            }
                        }
                    }
                }
                else {
                    print "Requested permissions for $package: NONE\n";
                }
            }
            else {
                die "$cmd: unrecognized operation: $operation\n";
            }
        }
    }
}
sub getPackageAndIntent {
    my ($id, $regex) = @_;
    my %byPackage = GetInstalledAPK($id);
    my @packages = grep /$regex/, keys %byPackage;
    if (@packages == 0) {
        die "No packages found to match \"$regex\"\n";
    }
    elsif (@packages > 1) {
        die "Found too many packages:\n"
            , map {"\t$_\n"} @packages;
    }
    my $package = $packages[0];
    my $APK = $byPackage{$package};
    # DUMP OF SERVICE package:
    #   Activity Resolver Table:
    #     Non-Data Actions:
    #         android.intent.action.MAIN:
    #           4214f528 com.kana_tutor.kanjidic/.MainActivity filter 42c63c68
    #     Action: "android.intent.action.MAIN"
    #     Category: "android.intent.category.LAUNCHER"
    my @sh = ($ADB, '-s', $id, 'shell');
    my @cmd = (@sh, 'pm', 'dump', $package);
    chomp(my @in = `@cmd 2>&1`);
    map {s/\cM$//} @in;
    my $state = 0;
    my $intent;
    foreach (@in) {
        if ($state == 0 && /action\.MAIN:/) {
            $state++;
            next;
        }
        if ($state == 1 && /^\s+[\d+a-f]+\s+($package\S+)/i) {
            $intent = $1;
            last;
        }
    }

    unless ($intent) {
        die "Failed to find launcher activity.\n";
    }
    return($package, $intent);
}
sub DoRestart {
    my ($cmd, $package_regex) = @_;
    unless(@_ == 2) {
        die $USAGE
            , "$cmd: wrong arg count.  Expected one got "
            , scalar(@_) - 1;
    }
    for my $id (@SelectedDevices) {
        print "======== "
            , ($FoundDevices{$id}{index} + 1)
            , " $FoundDevices{$id}{desc}\n";
        my($package, $intent) =  getPackageAndIntent($id, $package_regex);
        # stop the activity.
        my @sh = ($ADB, '-s', $id, 'shell');
        my @to_do = (@sh, 'am', 'force-stop', $package);
        print "Stopping...\n    <@to_do>\n";
        system(@to_do);
        @to_do = (@sh, 'am', 'start', '-n', "$intent");
        print "Starting...\n    <@to_do>\n";
        system(@to_do) && die "\"@to_do\" FAILED\n";
    }
}
sub DoStop {
    my ($cmd, $package_regex) = @_;
    unless(@_ == 2) {
        die $USAGE
            , "$cmd: wrong arg count.  Expected one got "
            , scalar(@_) - 1;
    }
    for my $id (@SelectedDevices) {
        print "======== "
            , ($FoundDevices{$id}{index} + 1)
            , " $FoundDevices{$id}{desc}\n";
        my($package, $intent) =  getPackageAndIntent($id, $package_regex);
        # stop the activity.
        my @sh = ($ADB, '-s', $id, 'shell');
        my @to_do = (@sh, 'am', 'force-stop', $package);
        print "Stopping...\n    <@to_do>\n";
        system(@to_do);
        @to_do = (@sh, 'am', 'start', '-n', "$intent");
    }
}
%FoundDevices = GetDevices();
my @argv = @ARGV;
# No input, print found devices.
unless (@argv) {
    unless (keys %FoundDevices) {
        die $USAGE, "No devices found.\n";
    }
    @SelectedDevices = map {$FoundDeviceIndexes{$_}}
        sort {$a <=> $b} keys %FoundDeviceIndexes;
    die "Found devices are:\n"
        , PrintDevices()
        , "\n";
}
if (@argv && $argv[0] eq 'all') {
    my @args = 1..(scalar keys %FoundDevices);
    @argv = (@args, @argv[1..$#argv]);
}
map {$_ = $FoundDeviceIndexes{$_}} grep exists $FoundDeviceIndexes{$_}, @argv;
# Strip off devices until we find a non-device.
{
    my %x;
    while (@argv && exists $FoundDevices{$argv[0]}) {
        $x{$argv[0]}++;
        shift @argv;
    }
    # sort id's by their index to make output pretty.
    @SelectedDevices
        = sort{$FoundDevices{$a}{index} <=> $FoundDevices{$b}{index}}
            keys %x;
}
unless (exists $CmdTable{$argv[0]}) {
    die $USAGE, "Failed to find command \"$argv[0]\" in CmdTable\n";
}
unless (@SelectedDevices) {
    @SelectedDevices = map {$FoundDeviceIndexes{$_}}
        sort {$a <=> $b} keys %FoundDeviceIndexes;
    die $USAGE
        , "No devices selected.  Found devices are:\n"
        , PrintDevices()
        , "\n";
}
if ($Verbose) {
    my $rules = "/etc/udev/rules.d/51-android.rules";
    # SUBSYSTEM=="usb", ATTR{idVendor}=="0502", MODE="0666", GROUP="plugdev" #Acer
    open F, $rules;
    my %from_rules = map {m{^.*=="([a-f0-9]{4})"[^#]+#\s*(.*)$}}
        grep /^SUB/, <F>;
    close F;
    open F, "/etc/udev/rules.d/51-android.rules";
    # Bus 003 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    my %usb = map {m{^.* ([a-f0-9]{4}):}, 1} `/usr/bin/lsusb`;
    # print "From lsub + $rules\n";
    # for my $u (sort keys %usb) {
    #     if (exists $from_rules{$u}) {
    #         print "\t$u -> $from_rules{$u}\n";
    #     }
    # }
    print "From adb devices:\n", map {"\t$_"} `$ADB devices`;
}

&{$CmdTable{$argv[0]}{exec}}(@argv);
__END__
