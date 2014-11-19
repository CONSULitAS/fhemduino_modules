##############################################
# $Id: 14_FHEMduino_DCF77.pm 0001 2014-11-19 15:50:00Z jowiemann $

package main;

use strict;
use warnings;

#####################################
sub
FHEMduino_DCF77_Initialize($)
{
  my ($hash) = @_;

  # output format is "D163100-16062014"
  #                   DHHMMSS-TTMMJJJJ
  #                   0123456789ABCDEF
                         
  $hash->{Match}     = "^D...............";
  $hash->{DefFn}     = "FHEMduino_DCF77_Define";
  $hash->{UndefFn}   = "FHEMduino_DCF77_Undef";
  $hash->{AttrFn}    = "FHEMduino_DCF77_Attr";
  $hash->{ParseFn}   = "FHEMduino_DCF77_Parse";
  $hash->{AttrList}  = "IODev do_not_notify:0,1 showtime:0,1 ignore:0,1 ".$readingFnAttributes;
}


#####################################
sub
FHEMduino_DCF77_Define($$)
{
  my ($hash, $def) = @_;
  my @a = split("[ \t][ \t]*", $def);

  return "wrong syntax: define <name> FHEMduino_DCF77 DCF77".int(@a)
		if(int(@a) < 2 || int(@a) > 3);

  $hash->{CODE}    = $a[2];
  $modules{FHEMduino_DCF77}{defptr}{$a[2]} = $hash;
  $hash->{STATE} = "Defined";

  AssignIoPort($hash);
  return undef;
}

#####################################
sub
FHEMduino_DCF77_Undef($$)
{
  my ($hash, $name) = @_;
  delete($modules{FHEMduino_DCF77}{defptr}{$hash->{CODE}}) if($hash && $hash->{CODE});
  return undef;
}

#####################################
sub
FHEMduino_DCF77_Parse($$)
{
  my ($hash,$msg) = @_;
  my @a = split("", $msg);

  # output format is "D163100-16062014"
  #                   DHHMMSS-TTMMJJJJ
  #                   0123456789ABCDEF

  my $deviceCode = "DCF77";
  
  my $def = $modules{FHEMduino_DCF77}{defptr}{$hash->{NAME} . "." . $deviceCode};
  $def = $modules{FHEMduino_DCF77}{defptr}{$deviceCode} if(!$def);
  if(!$def) {
    Log3 $hash, 1, "FHEMduino_DCF77 UNDEFINED sensor detected, code $deviceCode";
    return "UNDEFINED FHEMduino_DCF77 FHEMduino_DCF77 $deviceCode";
  }
  
  $hash = $def;
  my $name = $hash->{NAME};
  return "" if(IsIgnored($name));
  
  Log3 $name, 4, "FHEMduino_DCF77 $name ($msg)";  
  
  my ($hour, $min, $sec);
  my ($day, $mon, $year);

  $hour = $a[1].$a[2];
  $min  = $a[3].$a[4];
  $sec  = $a[5].$a[6];
  
  $day  = $a[8].$a[9];
  $mon  = $a[10].$a[11];
  $year = $a[12].$a[13].$a[14].$a[15];
  
  my $time = $hour.":".$min.":".$sec;
  my $date = $day.".".$mon.".".$year;
  my $val  = $time." ".$date;
  
  $hash->{lastReceive} = time();
  $hash->{lastValues}{Time} = $time;
  $hash->{lastValues}{Date} = $date;

  Log3 $name, 4, "FHEMduino_DCF77 $name: $time: $date";

  readingsBeginUpdate($hash);
  readingsBulkUpdate($hash, "state", $val);
  readingsBulkUpdate($hash, "time", $time);
  readingsBulkUpdate($hash, "date", $date);
  readingsEndUpdate($hash, 1); # Notify is done by Dispatch

  return $name;
}

sub
FHEMduino_DCF77_Attr(@)
{
  my @a = @_;

  # Make possible to use the same code for different logical devices when they
  # are received through different physical devices.
  return if($a[0] ne "set" || $a[2] ne "IODev");
  my $hash = $defs{$a[1]};
  my $iohash = $defs{$a[3]};
  my $cde = $hash->{CODE};
  delete($modules{FHEMduino_DCF77}{defptr}{$cde});
  $modules{FHEMduino_DCF77}{defptr}{$iohash->{NAME} . "." . $cde} = $hash;
  return undef;
}

1;

=pod
=begin html

<a name="FHEMduino_DCF77"></a>
<h3>FHEMduino_DCF77</h3>
<ul>
  The FHEMduino_DCF77 module interprets LogiLink DCF77 type of messages received by the FHEMduino.
  <br><br>

  <a name="FHEMduino_DCF77define"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FHEMduino_DCF77 &lt;DCF77&gt;<br>
  </ul>
  <br>
</ul>

=end html

=begin html_DE

<a name="FHEMduino_DCF77"></a>
<h3>FHEMduino_DCF77</h3>
<ul>
  Das FHEMduino_DCF77 module dekodiert vom FHEMduino empfangene Nachrichten des LogiLink DCF77.
  <br><br>

  <a name="FHEMduino_DCF77define"></a>
  <b>Define</b>
  <ul>
    <code>define &lt;name&gt; FHEMduino_DCF77 &lt;DCF77&gt;<br>
  <br>
</ul>

=end html_DE
=cut
