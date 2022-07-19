#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use feature qw/say/;

use IPC::Cmd qw/run/;
use JSON::PP qw/decode_json/;
use List::Util qw/sum/;

for my $target (@ARGV) {
    my $cpu_info      = get_cpu_info($target);
    my $mem_info      = get_mem_info($target);
    my $swap_info     = get_swap_info($target);
    my $storage_info  = get_storage_info($target);
    my $network_info  = get_network_info($target);

    say "============= $target ===============";
    say get_os($target);
    say render_cpu_info($cpu_info);
    say render_mem_info($mem_info, $swap_info);
    say render_storage_info($storage_info);
    say render_network_info($network_info);
}
exit;

sub get_os {
    my $target = shift;

    my ($stdout, $stderr) = run_cmd('ssh', '-n', $target, 'env', 'LC_ALL=C', 'lsb_release', '-s', '-d'); # Debian系前提
    if (@$stderr) {
        say STDERR "$target\[lsb_release\]: ", $_ for @$stderr;
    }

    my ($os_name) = @$stdout;
    chomp $os_name;
    return $os_name;
}

sub get_cpu_info {
    my $target = shift;

    my ($result, $stderr) = run_json_cmd('ssh', '-n', $target, 'env', 'LC_ALL=C', 'lscpu', '-J');
    if (@$stderr) {
        say STDERR "$target\[lscpu\]: ", $_ for @$stderr;
    }
    # {
    #    "lscpu": [
    #       {"field": "Architecture:", "data": "x86_64"},
    #       {"field": "CPU op-mode(s):", "data": "32-bit, 64-bit"},
    #       {"field": "Byte Order:", "data": "Little Endian"},
    #       {"field": "CPU(s):", "data": "1"},
    #       {"field": "On-line CPU(s) list:", "data": "0"},
    #       {"field": "Thread(s) per core:", "data": "1"},
    #       {"field": "Core(s) per socket:", "data": "1"},
    #       {"field": "Socket(s):", "data": "1"},
    #       {"field": "NUMA node(s):", "data": "1"},
    #       {"field": "Vendor ID:", "data": "AuthenticAMD"},
    #       {"field": "CPU family:", "data": "23"},
    #       {"field": "Model:", "data": "49"},
    #       {"field": "Model name:", "data": "AMD EPYC 7R32"},
    #       {"field": "Stepping:", "data": "0"},
    #       {"field": "CPU MHz:", "data": "3294.088"},
    #       {"field": "BogoMIPS:", "data": "5600.00"},
    #       {"field": "Hypervisor vendor:", "data": "KVM"},
    #       {"field": "Virtualization type:", "data": "full"},
    #       {"field": "L1d cache:", "data": "32K"},
    #       {"field": "L1i cache:", "data": "32K"},
    #       {"field": "L2 cache:", "data": "512K"},
    #       {"field": "L3 cache:", "data": "4096K"},
    #       {"field": "NUMA node0 CPU(s):", "data": "0"},
    #       {"field": "Flags:", "data": "fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf tsc_known_freq pni pclmulqdq ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand hypervisor lahf_lm cmp_legacy cr8_legacy abm sse4a misalignsse 3dnowprefetch topoext ssbd ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 clzero xsaveerptr wbnoinvd arat npt nrip_save rdpid"}
    #    ]
    # }

    my %keys_map = (
        'Architecture:' => 'arch',
        'Vendor ID:' => 'vendor',
        "Model name:" => 'model',
        "CPU(s):" => 'cores',
        'Thread(s) per core:' => 'threads',
        "CPU MHz:" => 'clock',
        'BogoMIPS:' => 'bogo_mips',
        'L1 cache:' => 'l1',
        'L1d cache:' => 'l1d',
        # 'L1i cache:' => 'l1i', # 命令キャッシュ: メモリアライメントの考慮の参考にならないので無視
        'L2 cache:' => 'l2',
        'L3 cache:' => 'l3',
        'Flags:' => 'flags',
    );

    # flagsは拡張命令形だけに限定
    my %cpu_info = map { $keys_map{$_->{field}} => $_->{data} } grep { exists $keys_map{$_->{field}} } @{ $result->{lscpu} };
    $cpu_info{flags} = [sort grep /(?:mmx|sse|avx|fma|sha|aes)/, split /\s+/, $cpu_info{flags}];
    if (! defined $cpu_info{clock}) {
        if ($cpu_info{model} =~ /([.0-9]+[mg])Hz$/i) {
            my $clock = $1;
            for ($clock) {
                $_ *= 1000 if s/g$//i;
                $_ *= 1    if s/m$//i;
            }
            $cpu_info{clock} = $clock;
        }
   }
    $cpu_info{clock} = $cpu_info{clock} / 1000;

    # {
    #     arch        "x86_64",
    #     bogo_mips   5600.00,
    #     clock       3293.998,
    #     cores       1,
    #     flags       [
    #         [0]  "aes",
    #         [1]  "avx",
    #         [2]  "avx2",
    #         [3]  "fma",
    #         [4]  "misalignsse",
    #         [5]  "mmx",
    #         [6]  "mmxext",
    #         [7]  "sha_ni",
    #         [8]  "sse",
    #         [9]  "sse2",
    #         [10] "sse4_1",
    #         [11] "sse4_2",
    #         [12] "sse4a",
    #         [13] "ssse3"
    #     ],
    #     l1d         "32K",
    #     l1i         "32K",
    #     l2          "512K",
    #     l3          "4096K",
    #     model       "AMD EPYC 7R32",
    #     threads     1,
    #     vendor      "AuthenticAMD"
    # }
    return \%cpu_info
}

sub get_mem_info {
    my $target = shift;

    my ($result, $stderr) = run_json_cmd('ssh', '-n', $target, 'sudo', 'env', 'LC_ALL=C', 'lsmem', '-J', '-b');
    if (@$stderr) {
        say STDERR "$target\[lsmem\]: ", $_ for @$stderr;
    }
    # {
    #    "memory": [
    #       {"range":"0x0000000000000000-0x000000007fffffff", "size":2147483648, "state":"online", "removable":true, "block":"0-15"}
    #    ]
    # }

    my $size = sum map { $_->{size} } @{ $result->{memory} };
    my $unit = 'b';

    # normalize size
    if ($unit eq 'b' && $size > 1024) {
        $size /= 1024;
        $unit = 'kb';
    }
    if ($unit eq 'kb' && $size > 1024) {
        $size /= 1024;
        $unit = 'mb';
    }
    if ($unit eq 'mb' && $size > 1024) {
        $size /= 1024;
        $unit = 'gb';
    }
    if ($unit eq 'gb' && $size > 1024) {
        $size /= 1024;
        $unit = 'tb';
    }

    return {
        size => $size,
        unit => $unit,
    };
}

sub get_swap_info {
    my $target = shift;

    my ($stdout, $stderr) = run_cmd('ssh', '-n', $target, 'sudo', 'env', 'LC_ALL=C', 'swapon', '--show=SIZE', '--noheadings', '--bytes');
    if (@$stderr) {
        say STDERR "$target\[swapon\]: ", $_ for @$stderr;
    }
    return { size => 0, unit => 'b' } unless @$stdout;

    my ($size) = @$stdout;
    my $unit = 'b';

    # normalize size
    if ($unit eq 'b' && $size > 1024) {
        $size /= 1024;
        $unit = 'kb';
    }
    if ($unit eq 'kb' && $size > 1024) {
        $size /= 1024;
        $unit = 'mb';
    }
    if ($unit eq 'mb' && $size > 1024) {
        $size /= 1024;
        $unit = 'gb';
    }
    if ($unit eq 'gb' && $size > 1024) {
        $size /= 1024;
        $unit = 'tb';
    }

    return {
        size => $size,
        unit => $unit,
    };
}

sub get_network_info {
    my $target = shift;

    my ($result, $stderr) = run_json_cmd('ssh', '-n', $target, 'sudo', 'env', 'LC_ALL=C', 'ip', '-f', 'inet', '-json', 'addr', 'show', 'up');
    if (@$stderr) {
        say STDERR "$target\[ip\]: ", $_ for @$stderr;
    }

    (my $stdout, $stderr) = run_cmd('ssh', '-n', $target, 'curl', '-sf', 'ifconfig.me');
    if (@$stderr) {
        say STDERR "$target\[ip\]: ", $_ for @$stderr;
    }

    my ($public_ip) = @$stdout;
    my @networks = grep { $_->{operstate} ne 'DOWN' }
        grep { !grep /^(?:LOOPBACK|NO-CARRIER)$/, @{ $_->{flags} } } @$result;

    return {
        map {
            $_->{ifname} => $_,
        } map {
            +{
                %$_{qw/ifname mtu/},
                public_ip  => $public_ip,
                private_ip => $_->{addr_info}->[0]->{local},
            }
        } @networks
    };
}

sub get_storage_info {
    my $target = shift;

    my %disks;
    {
        my ($stdout, $stderr) = run_cmd('ssh', '-n', $target, 'df', '-P', '-l', '-T');
        if (@$stderr) {
            say STDERR "$target\[df\]: ", $_ for @$stderr;
        }
        # Filesystem     Type     1024-blocks     Used Available Capacity Mounted on
        # udev           devtmpfs      988668        0    988668       0% /dev
        # tmpfs          tmpfs         203508      716    202792       1% /run
        # /dev/vda3      ext4       202228644 45191388 146747544      24% /
        # tmpfs          tmpfs        1017528       16   1017512       1% /dev/shm
        # tmpfs          tmpfs           5120        0      5120       0% /run/lock
        # tmpfs          tmpfs        1017528        0   1017528       0% /sys/fs/cgroup
        # tmpfs          tmpfs         203504        0    203504       0% /run/user/1001

        # normalize to lines
        my @lines = split /\n/, join '', @$stdout;
        my $header = shift @lines;

        my $columns = 7;
        my @headers = split /\s+/, $header, $columns;
        %disks = map { $_->{Filesystem} => $_ } map {
            my %h;
            @h{@headers} = split /\s+/, $_, $columns;
            \%h;
        } grep m!^/!, @lines;
    };
    # {
    #     /dev/vda3   {
    #         1024-blocks    202228644,
    #         Available      146747428,
    #         Capacity       "24%",
    #         Filesystem     "/dev/vda3",
    #         'Mounted on'   "/",
    #         Type           "ext4",
    #         Used           45191504
    #     }
    # }

    my %inodes;
    {
        my ($stdout, $stderr) = run_cmd('ssh', '-n', $target, 'df', '-P', '-l', '-i');
        if (@$stderr) {
            say STDERR "$target\[df\]: ", $_ for @$stderr;
        }
        # Filesystem     Type       Inodes  IUsed    IFree IUse% Mounted on
        # udev           devtmpfs   247167    436   246731    1% /dev
        # tmpfs          tmpfs      254382    649   253733    1% /run
        # /dev/vda3      ext4     12845056 549898 12295158    5% /
        # tmpfs          tmpfs      254382      2   254380    1% /dev/shm
        # tmpfs          tmpfs      254382      3   254379    1% /run/lock
        # tmpfs          tmpfs      254382     18   254364    1% /sys/fs/cgroup
        # tmpfs          tmpfs      254382     19   254363    1% /run/user/1001

        # normalize to lines
        my @lines = split /\n/, join '', @$stdout;
        my $header = shift @lines;

        my $columns = 7;
        my @headers = split /\s+/, $header, $columns;
        %inodes = map { $_->{Filesystem} => $_ } map {
            my %h;
            @h{@headers} = split /\s+/, $_, $columns;
            \%h;
        } grep m!^/!, @lines;
    };
    # {
    #     /dev/vda3   {
    #         Filesystem     "/dev/vda3",
    #         IFree          12295158,
    #         Inodes         12845056,
    #         IUse%          "5%",
    #         IUsed          549898,
    #         'Mounted on'   "/",
    #         Type           "ext4"
    #     }
    # }

    my @storages;
    for my $dev (sort keys %disks) {
        my $disk = $disks{$dev};
        my $inode = $inodes{$dev};

        # ignore tmpfs/squashfs
        next if $disk->{Type} =~ /tmpfs/i;
        next if $disk->{Type} =~ /squashfs/i;

        push @storages => {
            dev       => $dev,
            format    => $disk->{Type},
            mount     => $disk->{'Mounted on'},
            size      => _humalize_bytes($disk->{Used} * 1024),
            capacity  => _humalize_bytes(($disk->{'1024-blocks'}) * 1024),
            util      => $disk->{Capacity},
            isize     => _humalize_bytes($inode->{IUsed}) =~ s/B$//r,
            icapacity => _humalize_bytes($inode->{Inodes}) =~ s/B$//r,
            iutil     => $inode->{'IUse%'},
        };
    }

    return {
        storages => \@storages,
    };
}

sub _humalize_bytes {
    my $bytes = shift;

    my $unit = 'B';
    if ($bytes > 1024) {
        $bytes /= 1024;
        $unit = 'KB';
    }
    if ($bytes > 1024) {
        $bytes /= 1024;
        $unit = 'MB';
    }
    if ($bytes > 1024) {
        $bytes /= 1024;
        $unit = 'GB';
    }
    if ($bytes > 1024) {
        $bytes /= 1024;
        $unit = 'TB';
    }

    return sprintf '%.2f%s', $bytes, $unit;
}

sub render_cpu_info {
    my $cpu_info = shift;

    my @available_caches = grep { defined $cpu_info->{$_} } qw/l1 l1d l2 l3/;
    my $cache = join "/", @$cpu_info{@available_caches};
    my $flags = join ",", @{ $cpu_info->{flags} };
    my $name = $cpu_info->{vendor} eq 'AuthenticAMD' ? $cpu_info->{model}
             : $cpu_info->{vendor} eq 'GenuineIntel' ? $cpu_info->{model} =~ s/\s*@\s*\S+$//r
             : join ' ', @$cpu_info{qw/vendor model/} ;
    return sprintf '%s (%s/%.2fGHz/(BOGO)%dMIPS/%s/%dCPU/%dThreads) %s',
        $name, @$cpu_info{qw/arch clock bogo_mips/}, $cache, @$cpu_info{qw/cores threads/}, $flags;
}

sub render_mem_info {
    my ($mem_info, $swap_info) = @_;

    return sprintf 'MEMORY %.2f%s (SWAP: %.2f%s)',
        $mem_info->{size}, uc $mem_info->{unit},
        $swap_info->{size}, uc $swap_info->{unit};
}

sub render_storage_info {
    my $storage_info = shift;

    my @lines;
    for my $storage (@{ $storage_info->{storages} }) {
        push @lines => sprintf 'DISK %s %s (mount=%s) %s/%s(%s) INODE %s/%s(%s)',
            @$storage{qw/dev format mount size capacity util isize icapacity iutil/};
    }

    return join $/, @lines;
}

sub render_network_info {
    my $network_info = shift;

    my @lines;
    for my $ifname (sort keys %$network_info) {
        my $network = $network_info->{$ifname};
        push @lines => sprintf 'NETWORK %s (MTU=%d) PUBLIC=%s PRIVATE=%s',
            @$network{qw/ifname mtu public_ip private_ip/};
    }

    return join $/, @lines;
}

sub run_json_cmd {
    my ($stdout_buf, $stderr_buf) = run_cmd(@_);
    my $result = eval { decode_json(join '', @$stdout_buf) };
    if ($@) { require Carp; Carp::croak $@; }
    return ($result, $stderr_buf);
}

sub run_cmd {
    my @cmd = @_;
    # warn "run: @cmd";
    my ($ok, $err, $full_buf, $stdout_buf, $stderr_buf) = run(
        command => \@cmd,
        verbose => 0,
        timeout => 0, # no timeout
    );
    unless ($ok) {
        say STDERR "failed to execute command: @cmd";
        print STDERR $_ for @$full_buf;
        die $err;
    }

    return ($stdout_buf, $stderr_buf);
}

__END__
