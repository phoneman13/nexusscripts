#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper qw/Dumper/;
use Getopt::Long qw/GetOptions/;

=head1 NAME

printblocks.pl - Dump JSON and related info about blocks to stdout - recursively scan previous blocks.

=head1 USAGE

You must be running nexus - this script should be run from the folder where your nexus binary is located.

 $ ./printblocks.pl -b current -n 100 -m 2 -x $HOME/code/Nexus/nexus

=head1 DESCRIPTION

The example shown in usage will print blocks starting with current block, going back 100 blocks, print out only blocks with two or more transactions

=head1 INTERFACE

Command line arguments.

=over 4

=item B<-x or --nexusbinary> Full path and name of your nexus binary. This is ./nexus if you are running the script in your Nexus folder.

=item B<-b or --starblock> Starting block id or hash. Use current or leave out to start with most recent block. 
 
=item B<-n or --numblock> Number of blocks to print. Starting with the block given by -b, this many blocks will be looked at, going backwards in time.
 
=item B<-m or --mintx> Minimum number of transactions required to print the JSON info for a block out. Use 2 to ignore blocks with only a coinbase transaction.

=back

=cut

=head1 NOTES

If you want prettier output to view e.g. one block, try this.
Install the 'jq' program with 
$ sudo apt-get install jq
Then, run something like this. jq should colorize and pretty print the output.
$ ./printblocks.pl -b current -n 1 -m 0 | tail -n1 | jq ''

One way to use this script would be to run it and pipe the output to a .txt file which you can later search with standard unix tools like grep. For example
$ ./printblocks.pl -b current -n 1000 -m 0 > last-1000-blocks-json.txt
$ grep <something> last-1000-blocks-json.txt

This script has no external dependencies and should run on any modern *nix system. Thank you for riding mag lev.

I added a txcount field to the block JSON because it is non-trivial to determine how many transactions are in the flat transaction array.

I also added a txdetails field to the block JSON so it's easier to see the transaciton details.

=cut

my $startblockx = 'current';
my $numblocks = 0;
my $minimumtx = 1;
my $nexusfull = -e './nexus' ? './nexus' : 
                -e "$ENV{HOME}/code/Nexus/nexus"  ? "$ENV{HOME}/code/Nexus/nexus" : 
                -e '../nexus'  ? '../nexus' : '';
my $result = GetOptions (
	"mintx|m=i"      => \$minimumtx,
	"numblocks|n=i"  => \$numblocks,
	"startblock|b=s"  => \$startblockx,
  "nexusfull|x=s"  => \$nexusfull,
) or die("Error in command line arguments\n");
die 'please provide a nexus binary name or run from your Nexus folder' unless $nexusfull;
if (!-f $nexusfull) {
  die "Nexus binary does not appear to exist at ($nexusfull). Please supply the path to your nexus binary.";
}

if ($startblockx =~ /current/) {
	$startblockx = runcmd("$nexusfull getblockcount");
	chomp $startblockx;
}

my $block;
if ($startblockx && $startblockx =~ /^\d+$/) {
	$block = getblock(number => $startblockx);
}
else {
	$block = getblock(hash => $startblockx);
}

if ($block->{txcount} >= $minimumtx) {
	print JSON::Tiny::encode_json($block)."\n";
}

my $prevblock = $block->{previousblockhash};

if ($numblocks > 1) {
	for (my $bi = 1; $bi < $numblocks; ++$bi) {
		print STDERR "Getting previous block (previous count = $bi)\n";
		$block = getblock(hash => $prevblock);
		if ($block->{txcount} >= $minimumtx) {
			print JSON::Tiny::encode_json($block)."\n";
		}
		print STDERR "Got block at height $block->{height}\n";
		$prevblock = $block->{previousblockhash};
	}
}

sub gettxcount {
	# Given a block, count the transactions (hacky)
	my %args = @_;
	my $block = $args{block};
	die 'you must pass in a block data structure' unless $block and UNIVERSAL::isa($block,'HASH');
	my $txcount = 0;
	foreach my $entry (@{$block->{tx}}) {
		if ($entry =~ / UTC$/) {
			$txcount++;
		}
	}
	return $txcount;
}

sub gettxdetails {
	# Given a block, get the transaction details
	my %args = @_;
	my $block = $args{block};
	die 'you must pass in a block data structure' unless $block and UNIVERSAL::isa($block,'HASH');
	my @txdetails;
	foreach my $entry (@{$block->{tx}}) {
		#print "Looking at ($entry)\n";
		if ($entry =~ /^(\w{128}\w*) [^s]/ ) {
			my $txhash = $1;
			my $txdstr = runcmd("$nexusfull getglobaltransaction $txhash");
			my $txd  = JSON::Tiny::decode_json($txdstr);
			push @txdetails,  $txd;
		}
	}
	return \@txdetails;
}

sub getblock {
	# Get a block - also count transactions and adds txcount to data structure
	my %args = @_;
	die 'current or number or hash argument is required'  unless $args{current} or $args{number} or $args{hash};
	if ($args{current}) {
		$args{number} = runcmd("$nexusfull getblockcount");
		chomp $args{number};
		print STDERR "Current block number is $args{number}\n";
	}
	my ($blocknum,$blockhash) = ($args{number},$args{hash});
	if ($blocknum) {
		print STDERR "block num is ($blocknum)\n";
		$blockhash = runcmd("$nexusfull getblockhash $blocknum");
		chomp $blockhash;
	}
	print STDERR "Block hash is: $blockhash\n";
	# the true here means include transaction info
	my $blockstr = runcmd("$nexusfull getblock $blockhash true");
	my $block  = JSON::Tiny::decode_json($blockstr);
	$block->{txcount} = gettxcount(block => $block);
	$block->{txdetails} = gettxdetails(block => $block);
	return $block;
#print Dumper $block;
#{
#          'size' => 643,
#          'nextblockhash' => '0000000000455621133fb959e3f7720acab2e8c7d1a8b1554f2ef42f93b1e9d2be0777f8e4f8e46009f810b4470989645cca39d0b74c2648ebc65633f484dbc9e37b407eb8a80bbc1373fc994eb553a343da815a2bb9d0dbf0324027bee5476f648f96cc1a6ea9598cfafe932c5199190a1ac517ad3b593cd1747e4a2fdc5ef9',
#          'previousblockhash' => '000000000003c6fa0222eac863a4dd2f735004e14bed6860629f9556923da3eff1e51300fb1d32b38170190ec40a6c7f709e5d4e96215a611e0a78950909923463b739aa58a9af34da2a917be20531514bc742d684c4b251332ae6c7e9e08fcc98176d949d3519a5fcb80188c4f542601c4fd408133d17fe55c97459eb640da7',
#          'bits' => '7b58c5bb',
#          'version' => 4,
#          'mint' => '65.705158',
#          'hash' => '000000000042d20ea17cce8f92c326b48f0c04997cc1c865f1142e63fec68278c4fec5a18794c9c0e7c02e0bc1ad99eda39f497a2d62df1578f7c58a4af55051ae1143b9569ae0e88df606b6b1b5cb7bfbe105af9a12b4eee4edaf17f1a12d665ec199942bd9ceba29f85b162757fcd35844896ec1deca876e4382678dd4a2d0',
#          'merkleroot' => '933ce63ef24a52a4ea2b19acd16813df5d92f2503241c12162cde0a9805faac9872b9c75cfad61d23ad6c4733a7a84d24eb43b588d6f0dc42823d0afad379e4e',
#          'time' => '2016-12-22 22:38:21 UTC',
#          'tx' => [
#                  '933ce63ef24a52a4ea2b19acd16813df5d92f2503241c12162cde0a9805faac9872b9c75cfad61d23ad6c4733a7a84d24eb43b588d6f0dc42823d0afad379e4e base',
#                  '2016-12-22 22:38:08 UTC',
#                  ' 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 -1',
#                  ' out 50.798256 0305545702 OP_CHECKSIG',
#                  ' out 13.661198 OP_DUP OP_HASH256 4ca48e7981 OP_EQUALVERIFY OP_CHECKSIG',
#                  ' out 1.245704 OP_DUP OP_HASH256 ffd7117008 OP_EQUALVERIFY OP_CHECKSIG'
#                ],
#          'height' => 1112211,
#          'difficulty' => '184.55908406',
#          'nonce' => 1071828750
#        };
}

sub runcmd {
	my $cmd     = shift;
	my $out = `$cmd 2>&1`;
	if ($? != 0) {
		print $out;
		die "There was an error ($?) running ($cmd):\n $!";
	}
	return $out;
}

#addmultisigaddress <nrequired> <'["key","key"]'> [account]
#backupwallet <destination>
#checkwallet
#dumpprivkey <NexusAddress>
#dumprichlist <count>
#exportkeys
#getaccount <Nexusaddress>
#getaccountaddress <account>
#getaddressbalance <address>
#getaddressesbyaccount <account>
#getbalance [account] [minconf=1]
#getblock <hash> [txinfo]
#getblockcount
#getblockhash <index>
#getconnectioncount
#getdifficulty
#gettransaction <txid>
#getinfo
#getmininginfo
#getnewaddress [account]
#getpeerinfo
#getreceivedbyaccount <account> [minconf=1]
#getreceivedbyaddress <Nexusaddress> [minconf=1]
#getsupplyrate
#gettransaction <txid>
#help [command]
#importkeys
#importprivkey <PrivateKey> [label]
#keypoolrefill
#listaccounts [minconf=1]
#listreceivedbyaccount [minconf=1] [includeempty=false]
#listreceivedbyaddress [minconf=1] [includeempty=false]
#listsinceblock [blockhash] [target-confirmations]
#listtransactions [account] [count=10] [from=0]
#listunspent [minconf=1] [maxconf=9999999]  ["address",...]
#makekeypair [prefix]
#move <fromaccount> <toaccount> <amount> [minconf=1] [comment]
#repairwallet
#rescan
#reservebalance [<reserve> [amount]]
#sendfrom <fromaccount> <toNexusaddress> <amount> [minconf=1] [comment] [comment-to]
#sendmany <fromaccount> {address:amount,...} [minconf=1] [comment]
#sendtoaddress <Nexusaddress> <amount> [comment] [comment-to]
#setaccount <Nexusaddress> <account>
#settxfee <amount>
#signmessage <Nexusaddress> <message>
#stop
#validateaddress <Nexusaddress>
#verifymessage <Nexusaddress> <signature> <message>
#walletlock
#walletpassphrase <passphrase> <timeout> [mintonly]
#walletpassphrasechange <oldpassphrase> <newpassphrase>

package JSON::Tiny;

# Minimalistic JSON. Adapted from Mojo::JSON. (c)2012-2015 David Oswald
# License: Artistic 2.0 license.
# http://www.perlfoundation.org/artistic_license_2_0

use strict;
use warnings;
use Carp 'croak';
use Exporter 'import';
use Scalar::Util 'blessed';
use Encode ();

our $VERSION = '0.56';
our @EXPORT_OK = qw(decode_json encode_json false from_json j to_json true);

# Literal names
# Users may override Booleans with literal 0 or 1 if desired.
our($FALSE, $TRUE) = map { bless \(my $dummy = $_), 'JSON::Tiny::_Bool' } 0, 1;

# Escaped special character map with u2028 and u2029
my %ESCAPE = (
  '"'     => '"',
  '\\'    => '\\',
  '/'     => '/',
  'b'     => "\x08",
  'f'     => "\x0c",
  'n'     => "\x0a",
  'r'     => "\x0d",
  't'     => "\x09",
  'u2028' => "\x{2028}",
  'u2029' => "\x{2029}"
);
my %REVERSE = map { $ESCAPE{$_} => "\\$_" } keys %ESCAPE;

for(0x00 .. 0x1f) {
  my $packed = pack 'C', $_;
  $REVERSE{$packed} = sprintf '\u%.4X', $_ unless defined $REVERSE{$packed};
}

sub decode_json {
  my $err = _decode(\my $value, shift);
  return defined $err ? croak $err : $value;
}

sub encode_json { Encode::encode 'UTF-8', _encode_value(shift) }

sub false () {$FALSE}  ## no critic (prototypes)

sub from_json {
  my $err = _decode(\my $value, shift, 1);
  return defined $err ? croak $err : $value;
}

sub j {
  return encode_json $_[0] if ref $_[0] eq 'ARRAY' || ref $_[0] eq 'HASH';
  return decode_json $_[0];
}

sub to_json { _encode_value(shift) }

sub true () {$TRUE} ## no critic (prototypes)

sub _decode {
  my $valueref = shift;

  eval {

    # Missing input
    die "Missing or empty input\n" unless length( local $_ = shift );

    # UTF-8
    $_ = eval { Encode::decode('UTF-8', $_, 1) } unless shift;
    die "Input is not UTF-8 encoded\n" unless defined $_;

    # Value
    $$valueref = _decode_value();

    # Leftover data
    return m/\G[\x20\x09\x0a\x0d]*\z/gc || _throw('Unexpected data');
  } ? return undef : chomp $@;

  return $@;
}

sub _decode_array {
  my @array;
  until (m/\G[\x20\x09\x0a\x0d]*\]/gc) {

    # Value
    push @array, _decode_value();

    # Separator
    redo if m/\G[\x20\x09\x0a\x0d]*,/gc;

    # End
    last if m/\G[\x20\x09\x0a\x0d]*\]/gc;

    # Invalid character
    _throw('Expected comma or right square bracket while parsing array');
  }

  return \@array;
}

sub _decode_object {
  my %hash;
  until (m/\G[\x20\x09\x0a\x0d]*\}/gc) {

    # Quote
    m/\G[\x20\x09\x0a\x0d]*"/gc
      or _throw('Expected string while parsing object');

    # Key
    my $key = _decode_string();

    # Colon
    m/\G[\x20\x09\x0a\x0d]*:/gc
      or _throw('Expected colon while parsing object');

    # Value
    $hash{$key} = _decode_value();

    # Separator
    redo if m/\G[\x20\x09\x0a\x0d]*,/gc;

    # End
    last if m/\G[\x20\x09\x0a\x0d]*\}/gc;

    # Invalid character
    _throw('Expected comma or right curly bracket while parsing object');
  }

  return \%hash;
}

sub _decode_string {
  my $pos = pos;
  
  # Extract string with escaped characters
  m!\G((?:(?:[^\x00-\x1f\\"]|\\(?:["\\/bfnrt]|u[0-9a-fA-F]{4})){0,32766})*)!gc; # segfault on 5.8.x in t/20-mojo-json.t
  my $str = $1;

  # Invalid character
  unless (m/\G"/gc) {
    _throw('Unexpected character or invalid escape while parsing string')
      if m/\G[\x00-\x1f\\]/;
    _throw('Unterminated string');
  }

  # Unescape popular characters
  if (index($str, '\\u') < 0) {
    $str =~ s!\\(["\\/bfnrt])!$ESCAPE{$1}!gs;
    return $str;
  }

  # Unescape everything else
  my $buffer = '';
  while ($str =~ m/\G([^\\]*)\\(?:([^u])|u(.{4}))/gc) {
    $buffer .= $1;

    # Popular character
    if ($2) { $buffer .= $ESCAPE{$2} }

    # Escaped
    else {
      my $ord = hex $3;

      # Surrogate pair
      if (($ord & 0xf800) == 0xd800) {

        # High surrogate
        ($ord & 0xfc00) == 0xd800
          or pos($_) = $pos + pos($str), _throw('Missing high-surrogate');

        # Low surrogate
        $str =~ m/\G\\u([Dd][C-Fc-f]..)/gc
          or pos($_) = $pos + pos($str), _throw('Missing low-surrogate');

        $ord = 0x10000 + ($ord - 0xd800) * 0x400 + (hex($1) - 0xdc00);
      }

      # Character
      $buffer .= pack 'U', $ord;
    }
  }

  # The rest
  return $buffer . substr $str, pos $str, length $str;
}

sub _decode_value {

  # Leading whitespace
  m/\G[\x20\x09\x0a\x0d]*/gc;

  # String
  return _decode_string() if m/\G"/gc;

  # Object
  return _decode_object() if m/\G\{/gc;

  # Array
  return _decode_array() if m/\G\[/gc;

  # Number
  my ($i) = /\G([-]?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)/gc;
  return 0 + $i if defined $i;

  # True
  return $TRUE if m/\Gtrue/gc;

  # False
  return $FALSE if m/\Gfalse/gc;

  # Null
  return undef if m/\Gnull/gc;  ## no critic (return)

  # Invalid character
  _throw('Expected string, array, object, number, boolean or null');
}

sub _encode_array {
  '[' . join(',', map { _encode_value($_) } @{$_[0]}) . ']';
}

sub _encode_object {
  my $object = shift;
  my @pairs = map { _encode_string($_) . ':' . _encode_value($object->{$_}) }
    sort keys %$object;
  return '{' . join(',', @pairs) . '}';
}

sub _encode_string {
  my $str = shift;
  $str =~ s!([\x00-\x1f\x{2028}\x{2029}\\"/])!$REVERSE{$1}!gs;
  return "\"$str\"";
}

sub _encode_value {
  my $value = shift;

  # Reference
  if (my $ref = ref $value) {

    # Object
    return _encode_object($value) if $ref eq 'HASH';

    # Array
    return _encode_array($value) if $ref eq 'ARRAY';

    # True or false
    return $$value ? 'true' : 'false' if $ref eq 'SCALAR';
    return $value  ? 'true' : 'false' if $ref eq 'JSON::Tiny::_Bool';

    # Blessed reference with TO_JSON method
    if (blessed $value && (my $sub = $value->can('TO_JSON'))) {
      return _encode_value($value->$sub);
    }
  }

  # Null
  return 'null' unless defined $value;


  # Number (bitwise operators change behavior based on the internal value type)

  # "0" & $x will modify the flags on the "0" on perl < 5.14, so use a copy
  my $zero = "0";
  # "0" & $num -> 0. "0" & "" -> "". "0" & $string -> a character.
  # this maintains the internal type but speeds up the xor below.
  my $check = $zero & $value;
  return $value
    if length $check
    # 0 ^ itself          -> 0    (false)
    # $character ^ itself -> "\0" (true)
    && !($check ^ $check)
    # filter out "upgraded" strings whose numeric form doesn't strictly match
    && 0 + $value eq $value
    # filter out inf and nan
    && $value * 0 == 0;

  # String
  return _encode_string($value);
}

sub _throw {

  # Leading whitespace
  m/\G[\x20\x09\x0a\x0d]*/gc;

  # Context
  my $context = 'Malformed JSON: ' . shift;
  if (m/\G\z/gc) { $context .= ' before end of data' }
  else {
    my @lines = split "\n", substr($_, 0, pos);
    $context .= ' at line ' . @lines . ', offset ' . length(pop @lines || '');
  }

  die "$context\n";
}

# Emulate boolean type
package JSON::Tiny::_Bool;
use overload '""' => sub { ${$_[0]} }, fallback => 1;
1;
