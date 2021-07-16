#!/usr/bin/perl

$SPACE_TAB = 2; # This variable indicates how many spaces for indent
$LINE_WIDTH = 80; # Stores the maximum number of characters per line

#$* = 0; # 0 single line edits; 1 multi-line edits
#$/ = "\n"; # input field delimiter is a newline
#
#$* = 1; # 0 single line edits; 1 multi-line edits
$/ = undef(); # input field delimiter

if ($#ARGV >= 0)
 {
  @DIR_CONTENT = @ARGV;
  }
else
 {
  #$DIR_OUTPUT = `dir .`; #Get directory contents
  $DIR_OUTPUT = `ls -1`; #Get directory contents
  @DIR_CONTENT = split(/\n/,$DIR_OUTPUT); #Insert each line into array
  }
foreach $DIR_CONTENT (@DIR_CONTENT)
{
 next unless ($DIR_CONTENT =~ /\d\s+(\w[\w\s]*\.vhdl?)\b/i); #Only deal with VHDL files
 # ($FILE) = $DIR_CONTENT =~ /\d\s+(\w[\w\s]*\.vhdl?)\b/i; #Obtain filename only
 ($T2,$FILE) = $DIR_CONTENT =~ /\s+(\d|,)+\s+(\w[\w\s]*\.vhdl?)\b/i; #Obtain filename only
 
 @SIGNALS = ();
 @CONSTANTS = ();
 @PORT_LIST = ();

# **************************************************************
#Start by collecting some key statistics on the VHDL file
#such as longest signal name, and longest constant name.
# **************************************************************
$SIGNAL_LENGTH = 0;
$SIGNAL_LENGTH_MAX = 0;
$SIG_WDTH_LENGTH = 0;
$CONSTANT_LENGTH = 0;
#$* = 0; # 0 single line edits; 1 multi-line edits
$/ = "\n"; # input field delimiter is a newline
open (INFILE1,"$FILE") || die "Cannot open $FILE";
while (<INFILE1>)  
{
 if(/^\s*signal\s+\w+\s*:/i)
  {
   ($SIGNAL_NAME) = /^\s*signal\s+(\w+)\s*:/i;
   $LENGTH = length($SIGNAL_NAME);
   unless($SIGNAL_NAME =~ /_s$/i)
     {
      $LENGTH = $LENGTH + 2;
      push(@SIGNALS,$SIGNAL_NAME);
#print"$SIGNAL_NAME\n";
      }
   if($LENGTH > $SIGNAL_LENGTH){$SIGNAL_LENGTH = $LENGTH;}
   if($LENGTH > $SIGNAL_LENGTH_MAX){$SIGNAL_LENGTH_MAX = $LENGTH;}

   if (/\((.*?)\s+downto\s+(.*?)\)/)
    {
     ($SIG_WDTH,$HI,$LO) = /(\((.*?)\s+downto\s+(.*?)\))/i;
     $LENGTH = length($HI) + length($LO) + 3;
     if ($LENGTH > $SIG_WDTH_LENGTH){$SIG_WDTH_LENGTH = $LENGTH}
     }
   }
 elsif(/^\s*constant\s+\w+\s*:/i)
  {
   ($CONSTANT_NAME) = /^\s*constant\s+(\w+)\s*:/i;
   $LENGTH = length($CONSTANT_NAME);
   unless($CONSTANT_NAME =~ /_c$/i)
     {
      $LENGTH = $LENGTH + 2;
      push(@CONSTANTS,$CONSTANT_NAME);
      }
   if($LENGTH > $CONSTANT_LENGTH){$CONSTANT_LENGTH = $LENGTH;}
   }
 }
close(INFILE1);


if($CONSTANT_LENGTH > $SIGNAL_LENGTH){$SIGNAL_LENGTH = $CONSTANT_LENGTH;}
# **************************************************************
# **************************************************************

#print "$CONSTANT_LENGTH\n";

# ****************************************
# OUTPUT FILE NAME GENERATOR
# ****************************************
#$OUTFILE = $FILE;
$TMPOUT = "$FILE";
$RANDOM_NUMBER = 0;
#$TMPOUT =~ s/([^.]+)\./$1$RANDOM_NUMBER\./;
$TMPOUT =~ s/([^.]+)\./$1\.out/;
$FOUND1 = 0;
#while ( $FOUND1 == 0 )
#{ 
##if ( -e "${TMPOUT}${RANDOM_NUMBER}" ) { $RANDOM_NUMBER = $RANDOM_NUMBER + 1; }
#if ( -e "${TMPOUT}" )
#{
#$NEXT_NUMBER = $RANDOM_NUMBER + 1;
#$TMPOUT =~ s/([^.]+)$RANDOM_NUMBER\./$1$NEXT_NUMBER\./;
#$RANDOM_NUMBER = $NEXT_NUMBER;
#}
#else { $FOUND1 = 1; }
#}
$TMPOUTFILE1 = "${TMPOUT}";
# ****************************************
$TMPOUTSV = "$FILE";
$TMPOUTSV =~ s/([^.]+)\.(\w+)/$1\.sv/;
$OUTFILESV = "${TMPOUTSV}";


#$* = 1; # 0 single line edits; 1 multi-line edits
$/ = undef(); # input field delimiter
$COUNT = 0;

# First pass aims to ensure various structures
# are properly defined for the beautification phase.
open (INFILE1,"$FILE") || die "Cannot open $FILE";
open (OUTFILE1,">$TMPOUTFILE1") || die "Error in trying to open output file";
open (OUTFILEX,">$OUTFILESV") || die "Error in trying to open output file";
while (<INFILE1>)  
{
 s/\t/ /msg; #Substitute all tab characters with single space.

 # Clean up "end" of process, if, case statements
 s/end(\s|\n)+process/end process/msig; #unifies end and process
 s/end process(\s|\n)+\b/end process /msig; #eliminates whitespace
 s/end(\s|\n)+if/end if/msig; #unifies end and if
 s/end(\s|\n)+case/end case/msig; # unifies end and case
 s/\b(\s|\n)*;/;/msg; #Cleans up all whitespace to semicolon


 #Adjust whitespace in the vicinity of the entity declaration
 s/entity(\s|\n)+(\w+)(\s|\n)+is(\s|\n)+Port(\s|\n)+\((\s|\n)+/entity $2 is\nport \(\n/msig;

 #Adjust architecture name suffix to _BEH
 ($TRASH,$ENTITY_NAME) = /entity(\s|\n)+(\w+)(\s|\n)+is/msi;
 ($TRASH,$OLD_ARCH_NAME) = /architecture(\s|\n)+(\w+)(\s|\n)+of/msi;
 #s/(architecture)(\s|\n)+\w+(\s|\n)+of(\s|\n)+$ENTITY_NAME(\s|\n)+is/architecture ${ENTITY_NAME}_BEH of $ENTITY_NAME is/msgi;
 #s/end(\s|\n)+$OLD_ARCH_NAME(\s|\n)*;/end ${ENTITY_NAME}_BEH;/msgi;
 
 # Collect port list, capitalize and substitute througout file
 # Also find length of longest port
 $PORT_LENGTH = 0;
 ($TRASH,$PORT_LIST) = /entity\s+$ENTITY_NAME\s+is(\s|\n)+port\s*\(((.|\n)+)$/msi;
 $PORT_LIST =~ s/end\s+$ENTITY_NAME\b(.|\n)+$//msi;
 
 #Obtain the length of the longest port name
 @PORT_LIST = split(/;/,$PORT_LIST); #Insert each line into array
 foreach $PORT_NAME (@PORT_LIST)
 {
  next unless ($PORT_NAME =~ /\b\w+\s*:\s*(in|out|inout)\s+/msi);
  ($PORT) = $PORT_NAME =~ /\b(\w+)\s*:\s*(in|out|inout)\s+/msi;
  $UC_PORT = $PORT;
  $LENGTH = length($PORT);
  if ($LENGTH > $PORT_LENGTH){$PORT_LENGTH = $LENGTH;}
  #$UC_PORT =~ tr/[a-z]/[A-Z]/; 
  #s/\b$PORT\b/$UC_PORT/msig;
  }


 #Add signal and constant substitutions for _c and _s here
 #foreach $SIGNAL (@SIGNALS)
 #{
 #s/\b$SIGNAL\b  /${SIGNAL}_s/msgi;
 #s/\b$SIGNAL\b/${SIGNAL}_s/msgi;
 #}
 
 #foreach $CONSTANT (@CONSTANTS)
 #{
 #s/\b$CONSTANT\b/${CONSTANT}_c/msgi;
 #}
 
 
 ($T1,$T2,$T3,$T4,$GENERIC_LIST,$T5,$T6,$PORT_LIST) = /\bentity(\s|\n)+$ENTITY_NAME\s+is(\s|\n)+generic(\s|\n)*\((\s|\n)?(.*?)\);(\s|\n)*port(\s|\n)*\((.*?)(\s|\n)+end(\s|\n)+$ENTITY_NAME(\s|\n)*;/msi;


 print OUTFILEX "`timescale 1 ns / 1 ps\n";
 print OUTFILEX "module $ENTITY_NAME # (\n";

 $PARAM_LMAX = 0;
 @GENERIC_LIST = split(/\n/,$GENERIC_LIST);
 #chop(@GENERIC_LIST);
  foreach $GENERIC_NAME(@GENERIC_LIST)
  {
   if ($GENERIC_NAME =~ /(\s*)\b(\w+)\s*:\s*([^;]+);?\s*[-\/]{2}\w*(.*)/i)
    {
     ($WSPACE,$PARAM,$TYPE,$COMMENT) = $GENERIC_NAME =~ /(\s*)\b(\w+)\s*:\s*([^;]+);?\s*[-\/]{2}\w*(.*)/i;
     $PARAM_L = length($PARAM);
     if ($PARAM_L > $PARAM_LMAX) {
       $PARAM_LMAX = $PARAM_L;
       }
      $LAST_PARAM = $PARAM; 
     }
   }
  for($iii=0;$iii<=$#GENERIC_LIST;$iii++)
  {
   $GENERIC_NAME = $GENERIC_LIST[$iii];
   if ($GENERIC_NAME =~ /(\s*)\b(\w+)\s*:\s*([^;]+);?\s*[-\/]{2}\w*(.*)/i) {
    $PARAM_L = length($PARAM);
    $PSPACES = " " x ($PARAM_LMAX - $PARAM_L);
    if($PARAM eq $LAST_PARAM) {
      print OUTFILEX "${WSPACE}parameter int $PARAM $PSPACES\/\/$COMMENT\n";
      }
    else {
      print OUTFILEX "${WSPACE}parameter int $PARAM,$PSPACES\/\/$COMMENT\n";
      }
    }
   elsif ($GENERIC_NAME =~ /\w+/) {
     ($COMMENT) = $GENERIC_NAME =~ /[-\/]{2}\w*(.*)/i;
     print OUTFILEX "$WSPACE//$COMMENT\n";
    }
   }

print OUTFILEX ") (\n";

@PORT_LIST = split(/\n/,$PORT_LIST);
$HI_LO_WIDTH = 0;
foreach $PORT_NAME (@PORT_LIST){
  next unless ($PORT_NAME =~ /^\s*\b\w+\s*:\s*(in|out|inout)\s+/msi);
  ($WSPACE,$PORT,$DIR,$TYPE,$TR1,$HI,$LO) = $PORT_NAME =~ /^(\s*)\b(\w+)\s*:\s*(in|out|inout)\s*([^(-]+)(\((.*?)\s+downto\s+(.*?)\))?/i;
  next unless ($TR1 =~ /downto/i)
  $HILENGTH = length($HI);
  $LOLENGTH = length($LO);
  $ADD = $HILENGTH + $LOLENGTH;
  if ($ADD > $HI_LO_WIDTH){$HI_LO_WIDTH = $ADD;}
  }
  $HI_LO_WIDTH += 4;


  @PORT_LIST = split(/\n/,$PORT_LIST);
  $PORT_LENGTH_MAX = 0;

  for $PORT_NAME (@PORT_LIST) {
    next unless ($PORT_NAME =~ /\b\w+\s*:\s*(in|out|inout)\s+/msi);
    ($WSPACE,$PORT,$DIR,$TYPE,$TR1,$HI,$LO) = $PORT_NAME =~ /(\s*)\b(\w+)\s*:\s*(in|out|inout)\s*([^(-]+)(\((.*?)\s+downto\s+(.*?)\))?/i;
    if (length($PORT)>$PORT_LENGTH_MAX) {
       $PORT_LENGTH_MAX = $PORT;
       }
    $LAST_PORT = $PORT;
    }



foreach $PORT_NAME (@PORT_LIST) {
$SIGN = 0;
next unless ($PORT_NAME =~ /^\s*\b\w+\s*:\s*(in|out|inout)\s+/msi);
($WSPACE,$PORT,$DIR,$TYPE,$TR1,$HI,$LO)=$PORT_NAME=~/^(\s*)\b(\w+)\s*:\s*(in|out|inout)\s*([^(-]+)(\((.*?)\s+downto\s+(.*?)\))?/i;
($COMMENT) = $PORT_NAME =~ /--(.*)/i;
print OUTFILEX "$WSPACE";
if ($DIR =~ /inout/i) {
  print OUTFILEX "$DIR  logic";
  }
elsif ($DIR =~ /in/i){
  print OUTFILEX "${DIR}put logic ";
  }
else{
  print OUTFILEX "${DIR}PUT logic ";
  }

if ($TYPE eq "signed") {
  $SIGN = 1;
  print OUTFILEX "$TYPE ";
  }

if ($TR1 =~ /downto/i){
  if ($SIGN == 0) {
    $SPACE = " " x ($HI_LO_WIDTH - length("[$HI:$LO] ") + 7);
    }
  else{
    $SPACE = " " x  x ($HI_LO_WIDTH - length("[$HI:$LO] "));
    }
  print OUTFILEX "[$HI:$LO]$SPACE ";
  }
else{
  if ($SIGN == 0) {
    $SPACE = " " x ($HI_LO_WIDTH + 7);
    }
  else{
    $SPACE = " " x  x ($HI_LO_WIDTH);
    }
  print OUTFILEX "$SPACE ";  
  }

$COM_PORT_SPACE = $PORT_LENGTH_MAX - length($PORT);
$CP_SPACE = " " x $COM_PORT_SPACE;

if ($PORT eq $LAST_PORT){
  print OUTFILEX "$PORT ${CP_SPACE}\/\/ ";
  }
else{
  print OUTFILEX "$PORT,${CP_SPACE}\/\/ ";
  }

unless($TYPE =~ == /logic/ ){
  print OUTFILEX "$TYPE";
  }

print OUTFILEX "$COMMENT\n";
}

print OUTFILEX ");\n";

 print OUTFILE1 "$_"; #Print improved statements.
 } # while infile
close(OUTFILE1);
close(INFILE1);



@COMPONENTS = '';
$/ = "\n";
open (INFILE1,"$FILE") || die "Cannot open $FILE";
while(INFILE1){
last if(/^\s*begin\b/);

if(/^\s*\b(signal|variable)\s+\b([^:]+)\s*:/i){
  ($TR0,$SIG_NAME,$TYPE,$WIDTH,$HI_INDEX,$LO_INDEX,$RANGE,$EQUALS,$OPERAND,$TR1,$COMMENT) = /^\s*(signal|variable)\s*([^:\n\(\)]+)\s*:\s*(signed|unsigned|std_ulogic|std_ulogic_vector|std_logic_vector|std_logic|integer|memshort_t)\s*(\((.*?)\s+downto\s+(.*?)\))?\s*(\brange\b.*?)?(:=\s*([^;]+))?;\s*(--(.*?))?$/i;

  $SIG_NAME =~ s/\s//msig;
  if($EQUALS =~ /:=/){
    $EQUALS =~ s/^(\s*):/ $1/;
    $EQUALS =~ s/\(\s*others\s*=>\s*'\s*0\s*'\s*\)/\'0/msig;
    $EQUALS =~ s/\(\s*others\s*=>\s*'\s*1\s*'\s*\)/\'1/msig;
    }
  if($WIDTH =~ /downto/){
    $MINUS = length($HI_INDEX) + length($LO_INDEX) + 3;
    $SPACE = " " x ($SIG_WDTH_LENGTH - $MINUS);
    $SPACE_PLUS = " " x ($SIG_WDTH_LENGTH - $MINUS + 7);

    $COM_SIG_SPACE = $SIGNAL_LENGTH_MAX - length($SIG_NAME);
    $CS_SPACE = " " x $COM_SIG_SPACE;
    $CS_SPACE_PLUS = " " x ($COM_SIG_SPACE + 7);
    if($TYPE =~ /\bsigned\b/i){
      print OUTFILEX "logic $TYPE [$HI_INDEX:$LO_INDEX]$SPACE $SIG_NAME;${CS_SPACE}\/\/ $RANGE $EQUALS $COMMENT\n";
      }else{
       print OUTFILEX "logic [$HI_INDEX:$LO_INDEX]$SPACE_PLUS $SIG_NAME;${CS_SPACE}\/\/ $TYPE $RANGE $EQUALS $COMMENT\n";
      }
    }else{
      $SPACE = " " x ($SIG_WDTH_LENGTH + 7);
      $COM_SIG_SPACE = $SIGNAL_LENGTH_MAX - length($SIG_NAME);
      $CS_SPACE = " " x $COM_SIG_SPACE;
      print OUTFILEX "logic $SPACE $SIG_NAME;${CS_SPACE}\/\/ $TYPE $RANGE $EQUALS $COMMENT\n";
      }
  }
elsif(/^\s*\bconstant\s+\b(\w+)\s*:/i){
  ($SIG_NAME,$TYPE,$WIDTH,$HI_INDEX,$LO_INDEX,$EQUALS,$RIGHT_SIDE,$COMMENT) = /^\s*constant\s+\b([^:]+)\s*:\s*(signed|unsigned|std_ulogic|integer|natural|positive|std_ulogic_vector|std_logic_vector|std_logic)\s*(\((.*?)\s+downto\s+(.*?)\))?\s*(:=\s*([^;]+))?\s*;\s*(--)?(.*?)\n/i;
  if($EQUALS =~ /:=/){
    $EQUALS =~ s/^(\s*):/ $1/;
    }
  if($WIDTH =~ /downto/){
    $MINUS = length($HI_INDEX) + length($LO_INDEX) + 3;
    $SPACE = " " x ($SIG_WDTH_LENGTH - $MINUS);
    $SPACE_PLUS = " " x ($SIG_WDTH_LENGTH - $MINUS + 7);

    $COM_SIG_SPACE = $SIGNAL_LENGTH_MAX - length($SIG_NAME);
    $CS_SPACE = " " x $COM_SIG_SPACE;
    $CS_SPACE_PLUS = " " x ($COM_SIG_SPACE + 7);
    if($TYPE =~ /\bsigned\b/i){
      print OUTFILEX "const logic $TYPE [$HI_INDEX:$LO_INDEX]$SPACE $SIG_NAME$EQUALS;${CS_SPACE}\/\/ $COMMENT\n";
      }else{
       print OUTFILEX "const logic [$HI_INDEX:$LO_INDEX]$SPACE_PLUS $SIG_NAME$EQUALS;${CS_SPACE}\/\/ $TYPE $COMMENT\n";
      }
    }else{
      $SPACE = " " x ($SIG_WDTH_LENGTH + 7);
      $COM_SIG_SPACE = $SIGNAL_LENGTH_MAX - length($SIG_NAME);
      $CS_SPACE = " " x $COM_SIG_SPACE;
      print OUTFILEX "const logic $SPACE $SIG_NAME$EQUALS;${CS_SPACE}\/\/ $TYPE $COMMENT\n";
      }
  }
elsif(/\bcomponent\s*\b(\w+)\b/i){
  ($COMPONENT) = /\bcomponent\s*\b(\w+)\b/i;
  $FOUND = 0;
  foreach $i (0 .. $#COMPONENTS){
    if ($COMPONENT eq $COMPONENTS[$i]){
      $FOUND = 1;
      last;
      }
    }
  if ($FOUND == 0){
    push(@COMPONENTS,$COMPONENT);
    }
  }
elsif(/^\s*\b(type|function)\s+\b(\w+)\b/i){
  print OUTFILEX "$_";
  }
}# while INFILE1
close(INFILE1);





$/ = undef();
$COUNT = 0;
open(INFILE1,"$FILE")||die"Cannot open $FILE";
while(<INFILE1>){
  ($CODE_BODY) = /\bbegin\b(.*)/msi;
  }
close(INFILE1);


$CODE_BODY =~ s/\bend\s+\w+(\s|\n)*;(\s|\n)*\Z/endmodule/msig; #NB \Z is EOF.
$CODE_BODY =~ s/([^-]|\n)--/$1\/\//msig; #VHDL to SV comments.
$CODE_BODY =~ s/\((\d{1,2})\)/\[$1\]/msig; #alter vector bit select from (#) to [#], this must preceed VHDL to SV instance ports!
$CODE_BODY =~ s/(\n\s*)\b(\w+\s*)=>\s*([^,;\/\n\s]+)(\s*(,))?(\s*\/\/[^\n]*)?/$1\.$2\($3\)$5$6/msig; # VHDL to SV instance ports dependency on above VHDL to SV comments.
$CODE_BODY =~ s/\b(\w+)\s*:\s*(\w+)[\n\s]+generic\s+map\s*\((.*?)\)[\s\n]*port\s+map\s*\((.*?)\);/$2 #\($3\) $1 \($4\);/msig;#VHDL to SV instances.
$CODE_BODY =~ s/\n([^-\/\w]+)\b(\w+)\s*:([^\n]+)\bgenerate\b[\s\n]*(\bbegin\b)?/\n${1}generate\n${1}${3}begin : $2\n/ig;#Disallow .*? from matching newline by avoiding /msig
$CODE_BODY =~ s/\n(\s*)(\w+)\s*:\s*process\s*\([^\n\)]*(\w*clk\w*)[^\n\)]*\)\s*(is)?(.*?)\bbegin\b[\s\n]+if\b[^\n]+clk[^\n]+\bthen\b(.*?)\bend\s+if\s*;[\s\n]+\bend\s+process\s+\w+\s*;/\n${1}always_ff @ \(posedge $3 \)$5 begin : $2$6${1}end/msig;#Synchronous reset process blocks

$CODE_BODY =~ s/\n(\s*)process\s*\([^\n\)]*(\w*clk\w*)[^\n\)]*\)\s*(is)?(.*?)\bbegin\b[\s\n]+if\b[^\n]+clk[^\n]+\bthen\b(.*?)\bend\s+if\s*;[\s\n]+\bend\s+process\s*;/\n${1}always_ff @ \(posedge $2 \)$4 begin $5\n${1}end/msig;#Synchronous reset process blocks no identifier

$CODE_BODY =~ s/\n(\s*)(\w+)\s*:\s*process\s*\([^\n\)]*(\w*clk\w*)[^\n\)]*\)\s*(is)?(.*?)\bbegin\b(.*?)\bend\s+process\s+\w+\s*;/\n${1}always_ff @ \(posedge $3 \)$5 begin : $2$6${1}end/msig;#Asynchronous reset process blocks


$CODE_BODY =~ s/(\n\s*)if(.*?)then/${1}if${2}begin/msig;
$CODE_BODY =~ s/\n(\s*)elsif\s+clk\s*'\s*event\s+and\s+clk\s*=\s*'1'\s*then/\n${1}end else begin/msig;
$CODE_BODY =~ s/(\n\s*)elsif(.*?)then/${1}end else if${2}begin/msig;#MUST FOLLOW elsif clk!!!
$CODE_BODY =~ s/(\n\s*)end\s+if\s*;/${1}end/msig;
$CODE_BODY =~ s/(\n\s*)else/${1}end else begin/msig;
$CODE_BODY =~ s/([^=:<>\/])=([^=:<>\/])/${1}==$2/msig;
$CODE_BODY =~ s/\/=/!=/msig;
$CODE_BODY =~ s/\band\b/&&/msig;
$CODE_BODY =~ s/\bor\b/||/msig;
$CODE_BODY =~ s/\bxor/^/msig;
$CODE_BODY =~ s/\bnot\b/!/msig;
$CODE_BODY =~ s/\bSIGNED/signed/msig;
$CODE_BODY =~ s/(\n\s*)signal\s+([^:\n]+)\s*:\s*(\bsigned\b)?(unsigned|std_ulogic|integer|natural|positive|std_ulogic_vector|std_logic_vector|std_logic)?\s*(\(([^\)\n]+)\s+downto\s+([^\)\n]+)\))/${1}logic $3 [$6:$7] $2/msig;
$CODE_BODY =~ s/(\n\s*)signal\s+([^:\n]+)\s*:\s*(\bstd_logic\b)?/${1}logic $2/msig;
$CODE_BODY =~ s/(\n\s*)constant\s+\b([^:\n]+)\s*:\s*(signed|unsigned|std_ulogic|integer|natural|positive|std_ulogic_vector|std_logic_vector|std_logic)\s*(\(([^\)\n]+)\s+downto\s+([^\)]+)\))?\s*:(=\s*[^;\n]+\s*;)?/${1}const int $2 $7/msig;
$CODE_BODY =~ s/\bto_integer\b//msig;
$CODE_BODY =~ s/\bunsigned\b//msig;
$CODE_BODY =~ s/\bsigned/$signed/msig;# narrower scope needed for signal declarations in the body
$CODE_BODY =~ s/\blogic\s+\$signed\b/logic signed/msig;
$CODE_BODY =~ s/\bresize\s*\(([^,]+),[^\)]+\)/$1/msig;
$CODE_BODY =~ s/\bshift_left\s*\(([^,]+),([^\)]+)\)/${1}<<<\($2\)/msig;
$CODE_BODY =~ s/\(\s*others\s*=>\s*'\s*0\s*'\s*\)/\'0/msig;
$CODE_BODY =~ s/\(\s*others\s*=>\s*'\s*1\s*'\s*\)/\'1/msig;
$CODE_BODY =~ s/\"([01]{2})\"/2\'b$1/msig;
$CODE_BODY =~ s/\"([01]{3})\"/3\'b$1/msig;
$CODE_BODY =~ s/\"([01]{4})\"/4\'b$1/msig;
$CODE_BODY =~ s/\"([01]{5})\"/5\'b$1/msig;
$CODE_BODY =~ s/\'0\'/1\'b0/msig;
$CODE_BODY =~ s/\'1\'/1\'b1/msig;
$CODE_BODY =~ s/\(([^\(]*)\s+downto\s+([^\)]*)\)/\[$1:$2\]/msig;#Vector specs to SV [###:0]
$CODE_BODY =~ s/\n(\s*)(\w+)\s*:\s*process\s*(\([^\)]*\))\s*(is)?(.*?)\bbegin\b(.*?)\bend\s+process\s+\w+\s*;/\n${1}always_comb begin : $2\n$6\n${1}end\n/msig;# Combinational blocks after clocked processes
$CODE_BODY =~ s/(\n\s*)case\b(\s*[^\n]+\s*)is([\s\n]+)when\b([^=]+)=>/${1}case${2}inside${3}$4:begin/msig;
$CODE_BODY =~ s/(\n\s*)when\b\s+others\s*=>/$1end$1default:begin/msig;#"when others" must preceed general when case, or risk confusion
$CODE_BODY =~ s/(\n\s*)when\b([^=]+)=>/$1end$1$2:begin/msig;
$CODE_BODY =~ s/(\n\s*)end[\s\n]+case\s*/$1end$1endcase/msig;
$CODE_BODY =~ s/(\n\s*)(\d{1,2}\s*:\s*begin)/${1}='d$2/msig;
$CODE_BODY =~ s/(\n\s*)(\d+)\s*to\s*(\d+)\s*(:\s*begin)/${1}\[\'d$2:\'d$3\]$4/msig;

print OUTFILEX "$CODE_BODY\n";
close(OUTFILEX);



# ****************************************
# OUTPUT FILE NAME GENERATOR
# ****************************************
#$OUTFILE = $FILE;
$TMPOUT = "$FILE";
$RANDOM_NUMBER = 0;
$TMPOUT =~ s/([^.]+)\./$1$RANDOM_NUMBER\./;
$FOUND1 = 0;
while ( $FOUND1 == 0 )
{ 
	#if ( -e "${TMPOUT}${RANDOM_NUMBER}" ) { $RANDOM_NUMBER = $RANDOM_NUMBER + 1; }
 if ( -e "${TMPOUT}" )
   {
    $NEXT_NUMBER = $RANDOM_NUMBER + 1;
    $TMPOUT =~ s/([^.]+)$RANDOM_NUMBER\./$1$NEXT_NUMBER\./;
    $RANDOM_NUMBER = $NEXT_NUMBER;
    }
 else { $FOUND1 = 1; }
 }
$TMPOUTFILE2 = "${TMPOUT}";
# ****************************************


#Execute a pass to align text according to port, signal and constant
#length, and regulate tab whitespace at start of every line.
# USE: $PORT_LENGTH, $SIGNAL_LENGTH, $ENTITY_NAME
$LEADING_SPACE = 0;
$STATE = 0;
#$* = 0; # 0 single line edits; 1 multi-line edits
$/ = "\n"; # input field delimiter is a newline
open (INFILE2,"$TMPOUTFILE1") || die "Cannot open $FILE";
open (OUTFILE2,">$TMPOUTFILE2") || die "Error in trying to open output file";
while (<INFILE2>)  
{
 if ( (/^\s*--/) && ($STATE != 4) )
  {
   print OUTFILE2 "$_";
   next;
   }
 elsif (/^\s+$/)
  {
   print OUTFILE2 "$_";
   next;
   }
 elsif (/^\s*\)/)
  {
   print OUTFILE2 "$_";
   next;
   }



 if(/^\s*entity\s+$ENTITY_NAME\s+is/i)
  {
   $STATE = 1;
   }
 elsif( (/^\s*port\s*\(/i) && ($STATE == 1) )
  {
   $STATE = 2;
   }
 elsif (/^\s*end\s+$ENTITY_NAME\s*;/i)
  {
   $STATE = 0;
   }
   #elsif( ($STATE == 2) && !(/^\s*port\s*\(/i) )
 elsif ($STATE == 2)
  {
   $LEADING_SPACE = $SPACE_TAB;
   $SPACE = " " x $LEADING_SPACE;
   ($PORT) = /^\s*(\w+)\s*:/i;
   $LENGTH = length($PORT);
   $PORT2COLON_LENGTH = $PORT_LENGTH + $LEADING_SPACE - $LENGTH;
   $PORT2COLON_SPACE = " " x $PORT2COLON_LENGTH;
   s/^\s*(\w+)\s*:/$SPACE$1$PORT2COLON_SPACE:/i;
   }


 if(/^\s*constant\s+\w+\s*:/i)
  {
   ($CONSTANT) = /^\s*constant\s+(\w+)\s*:/i;
   $LENGTH = length($CONSTANT);
   $PORT2COLON_LENGTH = $SIGNAL_LENGTH + $LEADING_SPACE - $LENGTH;
   $PORT2COLON_SPACE = " " x $PORT2COLON_LENGTH;
   s/^\s*constant\s+(\w+)\s*:/constant $1$PORT2COLON_SPACE:/i;
   }
 elsif(/^\s*signal\s+\w+\s*:/i)
  {
   ($CONSTANT) = /^\s*signal\s+(\w+)\s*:/i;
   $LENGTH = length($CONSTANT);
   $PORT2COLON_LENGTH = $SIGNAL_LENGTH + $LEADING_SPACE - $LENGTH;
   $PORT2COLON_SPACE = " " x $PORT2COLON_LENGTH;
   s/^\s*signal\s+(\w+)\s*:/signal   $1$PORT2COLON_SPACE:/i;
   }
 


 if(/^\s*(\w+\s*:\s*)?process\s*\(/i)
  {
   $STATE = 3;
   }
 elsif( (/^\s*begin\b/i) && ($STATE == 3) )
  {
   print OUTFILE2 "$_";
   $STATE = 4;
   $LEADING_SPACE = $SPACE_TAB;
   }
 elsif (/^\s*end\s+process(\s+\w+)?\s*;/i)
  {
   $STATE = 0;
   }
 elsif ($STATE == 4)
  {
   chop($_); # Remove the newline
   # Separate comment and statement to reduce miscues.
   ($COMMENT) = /(--.*)$/i;
   s/\s*--.*$//i;
   ($STATEMENT) = /^\s*(.+)$/i;
	  
   if ( /^\s*if\b/i && /\bthen\b/i )
    {
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     $LEADING_SPACE = $LEADING_SPACE + $SPACE_TAB;
     }
   elsif ( /^\s*if\b/i && !/\bthen\b/i )
    {
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     $LEADING_SPACE = $LEADING_SPACE + $SPACE_TAB;
     }
   elsif ( !/^\s*if\b/i && !/\belsif\b/i && /\bthen\b/i )
    {
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     # $LEADING_SPACE = $LEADING_SPACE - $SPACE_TAB;
     }
   elsif ( /^\s*elsif\b/i && /\bthen\b/i )
    {
     $LEADING_SPACE = $LEADING_SPACE - $SPACE_TAB;
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     $LEADING_SPACE = $LEADING_SPACE + $SPACE_TAB;
     }
   elsif ( /^\s*else/i )
    {
     $LEADING_SPACE = $LEADING_SPACE - $SPACE_TAB;
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     $LEADING_SPACE = $LEADING_SPACE + $SPACE_TAB;
     }
   elsif ( /^\s*elsif\b/i && !/\bthen\b/i )
    {
     $LEADING_SPACE = $LEADING_SPACE - $SPACE_TAB;
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     $LEADING_SPACE = $LEADING_SPACE + $SPACE_TAB;
     }
   elsif ( /^\s*end\b/i && /\bif\b/i )
    {
     $LEADING_SPACE = $LEADING_SPACE - $SPACE_TAB;
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     }
   elsif (/^\s*case\b/i)
    {
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     $LEADING_SPACE = $LEADING_SPACE + $SPACE_TAB + $SPACE_TAB;
     }
   elsif (/^\s*when\b/i)
    {
     $LEADING_SPACE = $LEADING_SPACE - $SPACE_TAB;
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     $LEADING_SPACE = $LEADING_SPACE + $SPACE_TAB;
     }
   elsif (/^\s*end\b/i && /\bcase\b/i)
    {
     $LEADING_SPACE = $LEADING_SPACE - $SPACE_TAB - $SPACE_TAB;
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     }
   else
    {
     $SPACE = " " x $LEADING_SPACE;
     print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     }
   
   } #elsif $STATE == 4






 unless ($STATE == 4)
   {
    print OUTFILE2 "$_"; #Print improved statements.
    }

 
 } # while infile2
close(OUTFILE2);
close(INFILE2);
`del $TMPOUTFILE1`;


#Create a separate while loop to process assignment statements within
#each process.
     #elsif (/<=/ && /;/)
     #{
     #($ASSIGN) = $STATEMENT =~ /^\s*(.+)\s*<=/i;
     #$LENGTH = length($ASSIGN);
     #$PORT2COLON_LENGTH = $SIGNALS_ONLY + $LEADING_SPACE - $LENGTH;
     #$PORT2COLON_SPACE = " " x $PORT2COLON_LENGTH;
     #$STATEMENT =~ s/\b($ASSIGN)\s*<=/$1$PORT2COLON_SPACE<=/i;

     #$SPACE = " " x $LEADING_SPACE;
     #print OUTFILE2 "$SPACE$STATEMENT$COMMENT\n";
     #}


} #foreach $FILE (@DIR_CONTENT)
