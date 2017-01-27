#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper qw/Dumper/;
use Getopt::Long qw/GetOptions/;

=head1 NAME

paperwallet.pl - Back up private keys into a PDF format which can be printed to paper.

=head1 USAGE

You must be running nexus - you can include the full path to the nexus binary on the command line.

 $ ./paperwallet.pl $HOME/code/Nexus/nexus

=head1 DESCRIPTION

In the example shown, a paper wallet will be printed to ~/NexusPaperWallets/

The wallet will contain public addresses and private keys in plain text and QR code formats.

Note, you can use this script in addition to a temporary wallet, e.g. on an Ubuntu live usb, to make Nexus paper wallets suitable for giving out to friends, etc. Just make sure not to give out private keys to any addresses you plan on filling with your own NXS!

=head1 INTERFACE

Command line arguments.

=over 4

=item B<-x or --nexusfull> Full path and name of your nexus binary. This is ./nexus if you are running the script in your Nexus folder.
 
=item B<-d or --debug> Print debug info - may contain private keys.

=item B<-v or --debugcmd> Print all shell commands run from script. May contain private keys.

=item B<-j or --savejson> (Default true) Save a JSON version of the public and private key information as well.

=item B<-n or --nosavejson> Do not save a JSON version of the public and private key information as well.

=item B<-p or --noview> Do not attempt to open the PDF viewer when complete (good for security or if you are running on a server with no GUI)

=back

=cut

=head1 NOTES

The .tex file, included in the same directory, also contains your private key info.
This is a specially crafted text file which is used to generate the pdf.
If you want to back this up as well, you can. It could be helpful in the event that the PDF were corrupted.
Also, be careful with it since it does contain private keys.
Note that the other latex related build files (.log) may contain info on your private keys.
You are responsible for cleaning these up if you desire to do so.

=head1 WARNINGS

If you have encrypted your wallet, be aware that running this script will produce an unencrypted plain text version of your wallet on the hard drive. If you are not OK with that then do not use this script.

Do not run this script while others are watching or while you are screen casting. Private keys may be dumped out to the screen at any time.

You should only use this script on a secure system where you are using fill disk encryption.
The qrcode latex library caches some information about qrcodes.
This means that information on your private key may be saved on the computer in locations you are not aware of.

The latex libraries can take up a lot of space on your hard drive.

=head1 LICENSE

https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

=head1 WARRANTY

Selected setions from the GPL v2:

11. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

12. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. 

=head1 TODO

Add mode to read in a saved json and produce the pdf (skip building the acct/addr/priv key info, use that saved in json).

Add ability to restore addresses to the wallet from a json file.

=cut

# How to generate the readme: perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' paperwallet.pl > README-PAPERWALLET.md

my $debug = 0;
my $debugcmd = 0;
my $savejson = 1;
my $nosavejson = 0;
my $noview = 0;
my $paperwalletdir = "$ENV{HOME}/NexusPaperWallets";
my $time = time();
my $paperwalletlatexfile = "$ENV{HOME}/NexusPaperWallets/NexusPaperWallet$time.tex";
my $nexusfull = -e './nexus' ? './nexus' : 
                -e "$ENV{HOME}/code/Nexus/nexus"  ? "$ENV{HOME}/code/Nexus/nexus" : 
                -e '../nexus'  ? '../nexus' : '';

my $result = GetOptions (
  "nexusfull|x=s"  => \$nexusfull,
  "debug|d"  => \$debug,
  "debugcmd|v"  => \$debugcmd,
  "savejson|j"  => \$savejson,
  "nosavejson|n"  => \$savejson,
  "noview|p"  => \$noview,
) or die("Error in command line arguments\n");
die 'please provide a nexus binary name or run from your Nexus folder' unless $nexusfull;
if (!-f $nexusfull) {
  die "Nexus binary does not appear to exist at ($nexusfull). Please supply the path to your nexus binary.";
}
$savejson = 0 if $nosavejson;

ensurepdflatex();
ensureqrcode();

my $walletfh;
createlatexwallet($walletfh);

my $allkeyinfo = {};

my $accounts = listaccounts();

my $addresses;

while (my ($acct,$bal) = each %{$accounts}) {
	debug("Attempting to fetch addresses for account $acct.\n");
	$allkeyinfo->{$acct} = getaddressesbyaccount(account => $acct);
}

# Fetch private keys
while (my ($acct,$acinfo) = each %{$allkeyinfo}) {
	while (my ($addr,$adinfo) = each %{$acinfo}) {
		my $privkeymap = dumpprivkey(address => $addr);
		$allkeyinfo->{$acct}{$addr}{privkey} = $privkeymap->{privkey};
	}	
}

#print Dumper($allkeyinfo) if $debug;

my $jsonfile = $paperwalletlatexfile;
if ($savejson) {
	$jsonfile =~ s/\.tex/.json/;
	print "savejson mode enabled. Also saving account/address/private keys to json file at $jsonfile\n";
	open my $jsonfh, '>', $jsonfile or die "Couldn't open $jsonfile: $!";
	print $jsonfh JSON::Tiny::encode_json($allkeyinfo);
	close $jsonfh;
}

printtolatexwallet(latexbeginning());

while (my ($acct,$acinfo) = each %{$allkeyinfo}) {
	printtolatexwallet('\subsection{'.$acct.'}');
	while (my ($addr,$adinfo) = each %{$acinfo}) {
		my $priv  = $allkeyinfo->{$acct}{$addr}{privkey};
		my $bal   = $allkeyinfo->{$acct}{$addr}{balance} || 0;
		my ($pt1,$pt2);
		if ($priv =~ /^(\w{50})(\w+)$/) {
			($pt1,$pt2) = ($1,$2);
		}
		else {
			die "Private key does not match pattern.";
		}
		printtolatexwallet('\paragraph{Address ('.$bal.' NXS)} '."\n$addr\n");
		printtolatexwallet('\qrset{height=4.5cm}\qrcode[level=H]{'.$addr.'}$\langle$-----------Public Address');
		printtolatexwallet('\vspace*{100px}');
		printtolatexwallet('\paragraph{Private Key------------keep this safe!---------------------$\rangle$}');
		printtolatexwallet('\qrcode[level=H]{'.$priv.'}');
		printtolatexwallet('\paragraph{PK Part 1}'."\n$pt1\n");
		printtolatexwallet('\paragraph{PK Part 2}'."\n$pt2\n");
		printtolatexwallet('\newpage{}'."\n");
	}
}

printtolatexwallet(latexending());

debug("Running pdflatex\n");

runcmd("cd $paperwalletdir && pdflatex $paperwalletlatexfile");

my $paperwalletpdffile = $paperwalletlatexfile;
$paperwalletpdffile =~ s/\.tex$/.pdf/;
print "Paper wallet written to $paperwalletpdffile.\n";

if ($savejson) {
	print "savejson mode enabled. Also saved account/address/private keys to json file at $jsonfile\n";
}

my $aux = $paperwalletlatexfile;
my $log = $paperwalletlatexfile;
$aux =~ s/tex$/aux/;
$log =~ s/tex$/log/;
unlink $aux;
unlink $log;

print "Please print your wallet.\n";

print "Opening PDF viewer.\n" unless $noview;

runcmd("xdg-open $paperwalletpdffile") unless $noview;

exit 0;




sub ensurewalletdir {
	if (!-e $paperwalletdir) {
		mkdir $paperwalletdir or die "Couldn't make paper wallet dir $paperwalletdir: $!";
	}
}

sub createlatexwallet {
	ensurewalletdir();
	open $_[0], '>', $paperwalletlatexfile or die "Couln't open latex file $paperwalletlatexfile: $!";
}

sub printtolatexwallet {
	print $walletfh $_[0];
}


sub listaccounts {
	#dev@ubuntu:~/code/Nexus$ ./nexus listaccounts
	#{
	#    "test1" : 0.00000000,
	#    "test2" : 0.00000000
	#}
	my $accountsjson = runcmd("$nexusfull listaccounts");
	my $accounts = JSON::Tiny::decode_json($accountsjson);
	if ($debug) {
		while (my ($k,$v) = each %{$accounts}) {
			debug("Account '$k', Value: '$v'\n");
		}
	}
	return $accounts;
}

sub getaddressesbyaccount {
	#dev@ubuntu:~/code/Nexus$ ./nexus getaddressesbyaccount test1
	#[
	#    "2Qh4XKya3zxQdBx6ZZu4QrZhsdq8TKYG9Ut4hHweVZ4531Z2pMJ"
	#]
	my %args = @_;
	my $account = $args{account};
	die 'you must pass in an account to get addresses for' unless $account eq "" || $account;
	
	my $ret = {};
	my $addressesjson = runcmd("$nexusfull getaddressesbyaccount \"$account\"");
	my $addresses = JSON::Tiny::decode_json($addressesjson);

	# Also get address balance while we are at it
	foreach my $address (@{$addresses}) {
		debug("About to get balance for address '$address'\n");
		my ($addr,$bal) = %{getaddressbalance(address => $address)};
		$ret->{$addr}{balance} = $bal;
	}
	
	return $ret;
}

sub getaddressbalance {
	#dev@ubuntu:~/code/Nexus$ ./nexus getaddressbalance 2Qh4XKya3zxQdBx6ZZu4QrZhsdq8TKYG9Ut4hHweVZ4531Z2pMJ
	#{
	#    "2Qh4XKya3zxQdBx6ZZu4QrZhsdq8TKYG9Ut4hHweVZ4531Z2pMJ" : 0.00000000
	#}
	my %args = @_;
	my $address = $args{address};
	die "you must pass in an address to get balance for (input: '$address')" unless $address =~ /^[A-Za-z0-9]+$/;
	my $ret = {};
	debug("Getting balance for address $address\n");
	my $addrandbaljson = runcmd("$nexusfull getaddressbalance $address\n");
	my $addrandbal = JSON::Tiny::decode_json($addrandbaljson);
	my ($addr,$bal) = %{$addrandbal};
	debug("Address: '$addr', Bal: '$bal'\n");
	$ret->{$addr} = $bal;
	return $ret;
}

sub dumpprivkey {
	#dev@ubuntu:~/code/Nexus$ ./nexus dumpprivkey 2Qh4XKya3zxQdBx6ZZu4QrZhsdq8TKYG9Ut4hHweVZ4531Z2pMJ
	#PRIVKEYSHOWNHERE
	my %args = @_;
	my $address = $args{address};
	die "you must pass in an address to get the private key for (input: '$address')" unless $address =~ /^[A-Za-z0-9]+$/;
	my $privkey = runcmd("$nexusfull dumpprivkey $address");
	debug("Address: '$address', priv key: '$privkey'\n");
	return { privkey => $privkey };
}

sub latexbeginning {
	my $ret = '\title{Nexus Paper Wallet}
\author{Nexus Core Devs}
\date{\today}

\documentclass{article}
\usepackage[nolinks]{qrcode}

\begin{document}
\maketitle

\paragraph{}
This paper wallet contains qr codes and text which can be imported into a Nexus wallet.
Public and private keys will be displayed starting on the next page of this document.

\newpage{}

\section{Accounts}
';
	return $ret;
}


sub latexending {
	my $ret = '\paragraph{}
This is the end of your paper wallet. Please ensure all of your addresses and private keys are present before printing this backup.

Please note that if you are unable to use QR codes to grab private keys from this document, you will have to combine the PK Part 1 text and the PK Part 2 text to reconstruct the full private key for an address.

Learn more about the script which generated this wallet here.

https://github.com/physicsdude/nexusscripts

\paragraph{}
THE TRUTH IS OUT THERE
\end{document}
';
	return $ret;
}

sub ensurepdflatex {
	eval {
		runcmd("which pdflatex");
	};
	if (my $e = $@){
		print STDERR "Thanks for trying the paper wallet creator.\n";
		print STDERR "First, you need to install some packages on your operating system.\n";
		print STDERR "Please copy and paste the command below onto your command line, then try running this program again.\n";
		print STDERR "\nsudo apt-get update && sudo apt-get -y --no-install-recommends install texlive-base texlive-extras\n";
	}
}

sub ensureqrcode {
	my $qrcodedir = "/usr/local/share/texmf/tex/latex/qrcode";
	eval {
		runcmd("ls $qrcodedir >/dev/null");
	};
	if (my $e = $@) {
		print STDERR "qrcode latex library is not installed. Will try to automatically install this for you.";
	}
	else {
		return 1;
	}

	my $script = "#!/bin/bash\n";
	$script .= "set -e\nset -v\nset -x\n";
	$script .= "cd $ENV{HOME}/Downloads\n";
	$script .= "which wget || sudo apt-get install wget\n";
	$script .= "ls qrcode.zip || wget http://mirrors.ctan.org/macros/latex/contrib/qrcode.zip\n";
	$script .= "which unzip || sudo apt-get install unzip\n";
	$script .= "unzip qrcode.zip\n";
	$script .= "cd qrcode\n";
	$script .= "latex qrcode.ins\n";
	$script .= "latex qrcode.dtx\n";
	$script .= "sudo mkdir -p $qrcodedir\n";
	$script .= "cd $qrcodedir\n";
	$script .= "sudo rsync -av $ENV{HOME}/Downloads/qrcode/* .\n";
	$script .= "cd /usr/local/share/texmf\n";
	$script .= "sudo mktexlsr\n";
	$script .= "exit 0\n";

	open my $out, '>', '/tmp/installqrcode.sh' or die "Couldn't open /tmp/installqrcode.sh: $!";
	print $out $script;
	close $out;

	`chmod 755 /tmp/installqrcode.sh`;

	print "One more thing ... you need to install the qrcode latex library.\n Copy and paste this onto your command line:\n /tmp/installqrcode.sh\n";

	# runcmd("/bin/bash /tmp/installqrcode.sh > /tmp/installqrcode.log 2>&1");
}

# Are not using exportkeys becasuse it does not back up keys which don't have nxs in them yet.
# Want to back these up so people can add funds to them later without having to back up again.
#dev@ubuntu:~/code/Nexus$ ./nexus exportkeys test1
#error: {"code":-1,"message":"exportkeys\nThis command dumps the private keys and account names of all unspent outputs.\nThis allows the easy dumping and importing of all private keys on the system\n"}

sub debug {
	return unless $debug;
	print STDERR shift;
}

sub runcmd {
	my $cmd     = shift;
	print STDERR "Running command ($cmd)\n" if $debugcmd;
	my $out = `$cmd 2>&1`;
	chomp $out;
	print STDERR "Command returned ($out)\n" if $debugcmd;
	if ($? != 0) {
		print $out;
		die "There was an error ($?) running ($cmd):\n $!";
	}
	return $out;
}

#backupwallet <destination> - backs up the wallet.dat
#exportkeys - backs up only keys with a balance

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
# THE TRUTH IS OUT THERE
