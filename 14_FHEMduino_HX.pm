##############################################
# $Id: 14_FHEMduino_HX.pm 0001 2014-11-19 15:50:00Z jowiemann $

package main;

use strict;
use warnings;

  # 0011 => 1. 2xDing-Dong
  # 0101 => 2. Telefonklingeln
  # 1001 => 3. Zirkusmusik
  # 1101 => 4. Banjo on my knee
  # 1110 => 5. Morgen kommt der Weihnachtsmann
  # 0110 => 6. It’s a small world
  # 0010 => 7. Hundebellen
  # 0001 => 8. Westminster

#  "0011" => "2xDing-Dong",
#  "0001" => "Westminster",

my %codes = (
  "0011" => "hx_2xDing-Dong",
  "0001" => "hx_Westminster",
  "0101" => "hx_Telefonklingeln",
  "1001" => "hx_Zirkusmusik",
  "1101" => "hx_Banjo-on-my-knee",
  "1110" => "hx_Morgen-kommt-der-Weihnachtsmann",
  "0110" => "hx_It-is-a-small-world",
  "0010" => "hx_Hundebellen",
  );

my %hx_c2b;

my $hx_defrepetition = 14;   ## Default number of HX Repetitions

my $hx_simple ="off on";
my %models = (
  Heidemann   => 'HX Series',
  );

#####################################
sub
FHEMduino_HX_Initialize($)
{
  my ($hash) = @_;
 
  foreach my $k (keys %codes) {
    $hx_c2b{$codes{$k}} = $k;
  }
  
  $hash->{Match}     = "H...\$";
  $hash->{SetFn}     = "FHEMduino_HX_Set";
  $hash->{StateFn}   = "FHEMduino_HX_SetState";
  $hash->{DefFn}     = "FHEMduino_HX_Define";
  $hash->{UndefFn}   = "FHEMduino_HX_Undef";
  $hash->{AttrFn}    = "FHEMduino_HX_Attr";
  $hash->{ParseFn}   = "FHEMduino_HX_Parse";
  $hash->{AttrList}  = "IODev HXrepetition".
  $readingFnAttributes;
}

sub FHEMduino_HX_SetState($$$$){ ###################################################
  my ($hash, $tim, $vt, $val) = @_;
  $val = $1 if($val =~ m/^(.*) \d+$/);
  return "Undefined value $val" if(!defined($hx_c2b{$val}));
  return undef;
}

sub
FHEMduino_HX_Do_On_Till($@)
{
  my ($hash, @a) = @_;
  return "Timespec (HH:MM[:SS]) needed for the on-till command" if(@a != 3);

  my ($err, $hr, $min, $sec, $fn) = GetTimeSpec($a[2]);
  return $err if($err);

  my @lt = localtime;
  my $hms_till = sprintf("%02d:%02d:%02d", $hr, $min, $sec);
  my $hms_now = sprintf("%02d:%02d:%02d", $lt[2], $lt[1], $lt[0]);
  if($hms_now ge $hms_till) {
    Log3 $hash, 3, "on-till: won't switch as now ($hms_now) is later than $hms_till";
    return "";
  }

  my @b = ($a[0], "on");
  FHEMduino_HX_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

sub
FHEMduino_HX_On_For_Timer($@)
{
  my ($hash, @a) = @_;
  return "Seconds are needed for the on-for-timer command" if(@a != 3);

  # my ($err, $hr, $min, $sec, $fn) = GetTimeSpec($a[2]);
  # return $err if($err);
  
  my @lt = localtime;
  my @tt = localtime(time + $a[2]);
  my $hms_till = sprintf("%02d:%02d:%02d", $tt[2], $tt[1], $tt[0]);
  my $hms_now = sprintf("%02d:%02d:%02d", $lt[2], $lt[1], $lt[0]);
  
  if($hms_now ge $hms_till) {
    Log3 $hash, 4, "on-for-timer: won't switch as now ($hms_now) is later than $hms_till";
    return "";
  }

  my @b = ($a[0], "on");
  FHEMduino_HX_Set($hash, @b);
  my $tname = $hash->{NAME} . "_till";
  CommandDelete(undef, $tname) if($defs{$tname});
  CommandDefine(undef, "$tname at $hms_till set $a[0] off");

}

#####################################
sub
FHEMduino_HX_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> FHEMduino_HX HX".int(@a)
		if(int(@a) < 2 || int(@a) > 3);

  my $name = $a[0];
  my $code = $a[2];
  my $bitcode = hex2bin($code);

  Log3 $hash, 4, "FHEMduino_HX_DEF: $name $code $bitcode";

  if(int(@a) == 3) {
  }
  else {
    return "wrong syntax: define <name> FHEMduino_HX <code>";
  }

  Log3 undef, 5, "Arraylenght:  int(@a)";

  $hash->{CODE} = $code;
  $hash->{DEF} = $code;
  $hash->{XMIT} = $bitcode;

  Log3 $hash, 3, "Define hascode: {$code} {$name}";
  $modules{FHEMduino_HX}{defptr}{$code} = $hash;
#  $hash->{$hx_c2b{"hx_2xDing-Dong"}} = "0011";
#  $hash->{$hx_c2b{"hx_Westminster"}} = "0001";
#  $hash->{$hx_c2b{"hx_Telefonklingeln"}} = "0101";
#  $hash->{$hx_c2b{"hx_Zirkusmusik"}} = "1001";
#  $hash->{$hx_c2b{"hx_Banjo-on-my-knee"}} = "1101";
#  $hash->{$hx_c2b{"hx_Morgen-kommt-der-Weihnachtsmann"}} = "1110";
#  $hash->{$hx_c2b{"hx_It-is-a-small-world"}} = "0110";
#  $hash->{$hx_c2b{"hx_Hundebellen"}} = "0010";
  $modules{FHEMduino_HX}{defptr}{$bitcode}{$name} = $hash;

  if(!defined $hash->{IODev} ||!defined $hash->{IODev}{NAME}){
   AssignIoPort($hash);
  };  
  return undef;
}

#####################################
sub
FHEMduino_HX_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{FHEMduino_HX}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

sub FHEMduino_HX_Set($@){ ##########################################################
  my ($hash, @a) = @_;
  my $ret = undef;
  my $na = int(@a);
  my $message;
  my $msg;
  my $hname = $hash->{NAME};
  my $name = $a[0];

  return "no set value specified" if($na < 2 || $na > 3);
  
  my $list = "";
  $list .= "hx_2xDing-Dong hx_Westminster hx_Telefonklingeln hx_Zirkusmusik hx_Banjo-on-my-knee hx_Morgen-kommt-der-Weihnachtsmann hx_It-is-a-small-world hx_Hundebellen";

  return SetExtensions($hash, $list, $hname, @a) if( $a[1] eq "?" );
  return SetExtensions($hash, $list, $hname, @a) if( !grep( $_ =~ /^$a[1]($|:)/, split( ' ', $list ) ) );

  my $c = $hx_c2b{$a[1]};
  Log3 $name, 3, "$name: command $c";

  return FHEMduino_HX_Do_On_Till($hash, @a) if($a[1] eq "on-till");
  return "Bad time spec" if($na == 3 && $a[2] !~ m/^\d*\.?\d+$/);

  return FHEMduino_HX_On_For_Timer($hash, @a) if($a[1] eq "on-for-timer");
  # return "Bad time spec" if($na == 1 && $a[2] !~ m/^\d*\.?\d+$/);

  if(!defined($c)) {
   return "Unknown argument $a[1], choose one of " . join(" ", sort keys %hx_c2b);
  }
  my $io = $hash->{IODev};

  ## Do we need to change HXrepetition ??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"HXrepetition"})) {
  	$message = "hr".$attr{$a[0]}{"HXrepetition"};
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
         Log3 $hash, 5, "$name: Set HXrepetition: $message for $io->{NAME}";
    } else {
         Log3 $hash, 5, "$name: Error Set HXrepetition: $message for $io->{NAME}";
    }
  }

  my $v = join(" ", @a);
  Log3 $name, 3, "$name: set1 $v";

  $message = "hs".$hash->{XMIT}.$c;

  ## Log that we are going to switch InterTechno
  Log3 $name, 3, "$name: set $v IO_Name:$io->{NAME} CMD:$a[1] CODE:$c";

  (undef, $v) = split(" ", $v, 2);	# Not interested in the name...
  Log3 $name, 3, "$name: set2 $v";

  ## Send Message to IODev and wait for correct answer
  Log3 $hash, 4, "Messsage an IO senden Message raw: $message";
  $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
  if ($msg =~ m/raw => $message/) {
    Log3 $hash, 5, "$name: Answer from $io->{NAME}: $msg";
  } else {
    Log3 $hash, 5, "$name: IODev device didn't answer is command correctly: $msg";
  }

  ## Do we need to change HXrepetition back??	
  if(defined($attr{$a[0]}) && defined($attr{$a[0]}{"HXrepetition"})) {
  	$message = "hr".$hx_defrepetition;
    $msg = CallFn($io->{NAME}, "GetFn", $io, (" ", "raw", $message));
    if ($msg =~ m/raw => $message/) {
         Log3 $hash, 5, "$name: Set HXrepetition back: $message for $io->{NAME}";
    } else {
         Log3 $hash, 5, "$name: Error HXrepetition back: $message for $io->{NAME}";
    }
  }

  ##########################
  # Look for all devices with the same code, and set state, timestamp
  my $code = $hash->{XMIT};
  my $tn = TimeNow();

  $name = "$hash->{NAME}";
  Log3 $hash, 5, "$name: RSU: $code";

  my $defptr = $modules{FHEMduino_HX}{defptr}{$code};

  foreach my $n (keys %{ $defptr }) {
    Log3 $hash, 5, "$name: RSU->: $n";
    readingsSingleUpdate($defptr->{$n}, "state", $v, 1);
  }

  return $ret;
}

#####################################
sub
FHEMduino_HX_Parse($$)
{
  my ($hash,$msg) = @_;
  my @a = split("", $msg);

  my $deviceCode = "";
  my $zahlCode1 = "";
  my $zahlCode2 = "";

  if (length($msg) < 4) {
    Log3 "FHEMduino", 4, "FHEMduino_Env: wrong message -> $msg";
    return "";
  }
  my $bitsequence = "";
  my $bin = "";
  my $sound = "";
  my $hextext = substr($msg,1);

  # Bit 8..12 => Sound of door bell
  # 0011 => 1. 2xDing-Dong
  # 0101 => 2. Telefonklingeln
  # 1001 => 3. Zirkusmusik
  # 1101 => 4. Banjo on my knee
  # 1110 => 5. Morgen kommt der Weihnachtsmann
  # 0110 => 6. It’s a small world
  # 0010 => 7. Hundebellen
  # 0001 => 8. Westminster
  # 1111 1111 11111
  # 0    4    8

  $bitsequence = hex2bin($hextext); # getting message string and converting in bit sequence
  $bin = substr($bitsequence,0,4);
  $zahlCode1 = sprintf("%X",oct("0b$bin"));
  $bin = substr($bitsequence,4,4);
  $zahlCode2 = sprintf("%X",oct("0b$bin"));
  $deviceCode = "$zahlCode1"."$zahlCode2";
  $sound = substr($bitsequence,8,4);

  Log3 $hash, 4, "FHEMduino_HX: $msg";
  Log3 $hash, 4, "FHEMduino_HX: $hextext";
  Log3 $hash, 4, "FHEMduino_HX: $bitsequence $deviceCode $sound";

  
  my $def = $modules{FHEMduino_HX}{defptr}{$hash->{NAME} . "." . $deviceCode};
  $def = $modules{FHEMduino_HX}{defptr}{$deviceCode} if(!$def);
  if(!$def) {
    Log3 $hash, 1, "FHEMduino_HX UNDEFINED sensor HX detected, code $deviceCode";
    return "UNDEFINED HX_$deviceCode FHEMduino_HX $deviceCode";
  }
  
  $hash = $def;
  my $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $name, 5, "FHEMduino_HX: actioncode: $deviceCode";  
  
  $hash->{lastReceive} = time();
  $hash->{lastValues}{FREQ} = $sound;

  Log3 $name, 4, "FHEMduino_HX: $name: $sound";
  $sound = $codes{$sound};
  Log3 $name, 4, "FHEMduino_HX: $name: $sound";

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $sound);
  readingsEndUpdate($hash, 1); # Notify is done by Dispatch

  return $name;
}

sub
FHEMduino_HX_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FHEMduino_HX}{defptr}{$cde});
  $modules{FHEMduino_HX}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

sub
hex2bin($)
{
  my $h = shift;
  my $hlen = length($h);
  my $blen = $hlen * 4;
  return unpack("B$blen", pack("H$hlen", $h));
}

sub
bin2dec($)
{
  my $h = shift;
  my $int = unpack("N", pack("B32",substr("0" x 32 . $h, -32))); 
  return sprintf("%d", $int); 
}

1;

=pod
=begin html

<a name="FHEMduino_HX"></a>
=end html

=begin html_DE

<a name="FHEMduino_HX"></a>
=end html_DE

=cut
