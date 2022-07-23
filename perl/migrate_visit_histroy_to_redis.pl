use v5.36;
no warnings qw/portable/;
use utf8;
use experimental qw(builtin try isa defer);
use builtin qw(true false);

use DBIx::Sunny;

my $host     = $ENV{ISUCON_DB_HOST}       || '127.0.0.1';
my $port     = $ENV{ISUCON_DB_PORT}       || '3306';
my $user     = $ENV{ISUCON_DB_USER}       || 'isucon';
my $password = $ENV{ISUCON_DB_PASSWORD}   || 'isucon';
my $dbname   = $ENV{ISUCON_DB_NAME}       || 'isuports';

my $dsn = "dbi:mysql:database=$dbname;host=$host;port=$port";
my $db = DBIx::Sunny->connect($dsn, $user, $password, {
    mysql_enable_utf8mb4 => 1,
    mysql_auto_reconnect => 1,
});

my $sth = $db->prepare('SELECT competition_id, player_id, MIN(created_at) AS min_created_at FROM visit_history WHERE tenant_id = ? AND created_at < 1654041600 GROUP BY competition_id, player_id');
for my $tenant_id (1..100) {
    my $tenant_db = connect_to_tenant_db($tenant_id);
    my %finished_at_map = @{ $tenant_db->selectcol_arrayref('SELECT id, finished_at FROM competition WHERE finished_at IS NOT NULL', { Columns => [1, 2] }) };

    my @columns = qw/competition_id player_id min_created_at/;
    my %row;
    $sth->execute($tenant_id);
    $sth->bind_columns(undef, \(@row{@columns}));

    my $prev_key;
    while ($sth->fetch) {
        my $competition_id = hex($row{competition_id});
        next unless $finished_at_map{$competition_id};
	next unless $row{min_created_at} < $finished_at_map{$competition_id};

	my $key = sprintf 'visit_set_%d_%d', $tenant_id, $competition_id;
	if (!$prev_key) {
	    printf 'SADD %s %d', $key, hex($row{player_id});
	} elsif ($prev_key eq $key) {
	    printf ' %d', hex($row{player_id});
	} else {
            printf "\nSADD %s %d", $key, hex($row{player_id});
	}
	$prev_key = $key;
    }
    print "\n" if $prev_key;
}
$sth->finish();


# テナントDBに接続する
sub connect_to_tenant_db($id) {
    my $host_id  = 1 + ((1+$id) % 2);
    my $host     = $ENV{"ISUCON_TENANT${host_id}_DB_HOST"} || '127.0.0.1';
    my $port     = $ENV{ISUCON_DB_PORT}         || '3306';
    my $user     = $ENV{ISUCON_DB_USER}         || 'isucon';
    my $password = $ENV{ISUCON_DB_PASSWORD}     || 'isucon';
    my $dbname   = "isuports_tenant_$id";

    my $dsn = "dbi:mysql:database=$dbname;host=$host;port=$port";
    my $dbh = DBIx::Sunny->connect($dsn, $user, $password, {
        mysql_enable_utf8mb4 => 1,
        mysql_auto_reconnect => 1,
    });
    return $dbh;
}
