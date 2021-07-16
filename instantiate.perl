#!/usr/bin/perl

# Author: Guy Morin


$CONN_BY_NAME = 1; # set to 1 to get : ".<name_of_port>(<net_name>?)"

#  Setting up some default values.
# $* = 0; # Single-line patterns.
$/ = "\n"; # Pattern-space delimiter is a newline character.

if ( $#ARGV == 1 )
 {
  $FILE = $ARGV[0];
  $MODULE = $ARGV[1];
  $module = $MODULE;
  if ( $module =~ /[A-Z]/ ) { $module =~ tr/A-Z/a-z/; }
  else { $module =~ tr/a-z/A-Z/; }
  }
elsif ( $#ARGV == 0 )
 {
  $FILE = $ARGV[0];
  $MODULE = $FILE;
  $MODULE =~ s/(.*\/)?(\w+)(\..*)*/$2/g;
  $module = $MODULE;
  if ( $module =~ /[A-Z]/ ) { $module =~ tr/A-Z/a-z/; }
  else { $module =~ tr/a-z/A-Z/; }
  }
else
 {
  die "Supply a filename <blockname>\n";
  }

$STRING1 = "$MODULE $module (";
$QBLANKS = length($STRING1);
$BLANKS = ' ' x $QBLANKS;


# ****************************************
# OUTPUT FILE NAME GENERATOR
# ****************************************
$TMPOUT = "/tmp/instantiate.tmp";
$RANDOM_NUMBER = 0;
$FOUND1 = 0;
while ( $FOUND1 == 0 )
{ 
 if ( -e "${TMPOUT}${RANDOM_NUMBER}" ) { $RANDOM_NUMBER = $RANDOM_NUMBER + 1; }
 else { $FOUND1 = 1; }
 }
$TMPOUTFILE1 = "${TMPOUT}${RANDOM_NUMBER}";
# ****************************************
 
  
#  ********************************************************
#  This next Block removes comments of the form: //...
#  ********************************************************
# $* = 0; # Single-line patterns.
$/ = "\n"; # Pattern-space delimiter is an end of line.
open (INFILE1,"$FILE") || die "Cannot open $FILE\n";
open (OUTFILE1,">$TMPOUTFILE1") || die "Error in trying to open output file\n";
while (<INFILE1>)  
{
 s/(\/\/).*//g; # remove comments "//..."
 s/^\s*$//g; # Remove empty lines.
 s/\s\s+/ /g; # Normalise whitespace between words.
 s/^\s+//g; # Remove whitespace at the beginning of the line.
 s/\s+$/\n/g; # Remove whitespace at the end of the line.
 print OUTFILE1"$_";
 } 
close(OUTFILE1);
close(INFILE1);
 
 
# ****************************************
# OUTPUT FILE NAME GENERATOR
# ****************************************
$RANDOM_NUMBER = 0;
$FOUND1 = 0;
while ( $FOUND1 == 0 )
{
 if ( -e "${TMPOUT}${RANDOM_NUMBER}" ) { $RANDOM_NUMBER = $RANDOM_NUMBER + 1; }
 else { $FOUND1 = 1; }
 }
$TMPOUTFILE2 = "${TMPOUT}${RANDOM_NUMBER}";
# **************************************** 
 
#  ********************************************************
#  This next Block removes comments of the form: /*...*/
#  ********************************************************
# $* = 1; # Multi-line patterns.
$/ = "*/"; # Pattern-space delimiter is an end of comment character.
open (INFILE2,"$TMPOUTFILE1") || die "Cannot open $FILE\n";
open (OUTFILE2,">$TMPOUTFILE2") || die "Error in trying to open output file\n";
while (<INFILE2>)
{  
 if ( /\/\*/ )
  {
   # s/(\/\*)(.|\n)*(\*\/)//g; # remove comments "/*...*/"
   s/(\/\*).*(\*\/)//msg; # remove comments "/*...*/"
   }
 elsif ( /\*\// )
  {
   } # if nested comments get all nested comments.
  print OUTFILE2"$_";
 }
close(OUTFILE2);
close(INFILE2);    
# $* = 0; # Single-line patterns.
$/ = "\n"; # Pattern-space delimiter is an end of line.
 
 
`rm -f $TMPOUTFILE1`;
 
 
# ****************************************
# OUTPUT FILE NAME GENERATOR
# ****************************************
$RANDOM_NUMBER = 0;
$FOUND1 = 0;
while ( $FOUND1 == 0 )
{ 
 if ( -e "${TMPOUT}${RANDOM_NUMBER}" ) { $RANDOM_NUMBER = $RANDOM_NUMBER + 1; }
 else { $FOUND1 = 1; }
 }
$TMPOUTFILE3 = "${TMPOUT}${RANDOM_NUMBER}";
# ****************************************
 
# $* = 0; # Single-line patterns.
$/ = "\n"; # Pattern-space delimiter is an end of line.
open (INFILE3,"$TMPOUTFILE2") || die "Cannot open\n";
open (OUTFILE3,">$TMPOUTFILE3") || die "Error in trying to open output file\n";
while (<INFILE3>)
{
 s/^[\s\n]*$//;
 print OUTFILE3"$_";
 }
close(OUTFILE3);
close(INFILE3);
# $* = 0; # Single-line patterns.
$/ = "\n"; # Pattern-space delimiter is an end of line.
 
`rm -f $TMPOUTFILE2`;


#  ********************************************************
#  The following program block finds the verilog file
#  Block header, collects the port-names, and calls the
#  output subroutine.
#  ********************************************************

# $* = 1; # Allows multi-line buffers.
$/ = ");"; # Sets the input record separator to be ");"
open (FILE,"$TMPOUTFILE3") || die "Cannot open $TMPOUTFILE3\n";
$FOUND_MODULE = 0;
while (<FILE>)
{
 next unless ( /\bmodule[\n\s]+$MODULE\b/ );
 if ( /\bmodule[\n\s]+$MODULE\b/ )
  {
   if (/\bparameter\b/)
    {
     $PARAMS = 1;
     $STRING1 = "$MODULE #(";
     $QBLANKS = length($STRING1);
     $BLANKS = ' ' x $QBLANKS;
     }
   else
    {
     $PARAMS = 0;
     $STRING1 = "$MODULE ii_$MODULE (";
     $QBLANKS = length($STRING1);
     $BLANKS = ' ' x $QBLANKS;
     }
   print "\n";
   print "$STRING1"; # Prints the module name and instance name followed by "("
   $FOUND_MODULE = 1;
   }
 # s/(.|\n)*module[^\)\(]*\(//g; # Remove everything before "module"
 s/.*?module[^\)\(]*\(//msg; # Remove everything before "module"

 s/\n//msg; # Remove newlines 

 $PORTS_DECLARED = 1;
 unless ( /\binput\b|\boutput\b|\binout\b/ )
  {
   $PORTS_DECLARED = 0;
   s/\s//msg; # Remove whitespace
   }

 if ( $CONN_BY_NAME == 1 )
  {
   $SIG_NAME = $_;
   #$SIG_NAME =~ s/([^,\)\(;\s]+)(,|\);)/$1 $2 /g;
   $SIG_NAME =~ s/([^,\)\(;\s]+)(,|\);)/$1 $2 /msg;

# print "$SIG_NAME\n";

   if ($PORTS_DECLARED == 0)
    {
     &OUTPUT;
     }
   else
    {
     &OUTPUT_2;
     }
#   s/([^,\)\(;\s]+)/\.$1\($1\)/g;
   }
 else
  {
   #s/,/,\n$BLANKS/g; # Add consistent newlines i.e. ",\n"
   s/,/,\n$BLANKS/msg; # Add consistent newlines i.e. ",\n"
   print "$_\n";
   }

}
print "\n";
close (FILE);

if ( $FOUND_MODULE == 0 )
 {
  print "Could not find module: $MODULE\n";
  print "\n";
  }


`rm -f $TMPOUTFILE3`;


#  ********************************************************
#  This subroutine prints out the various results.
#  ********************************************************
sub OUTPUT
  {
   $SIGNAL = $SIG_NAME;
   @PORT_NAME = split(/ /,$SIGNAL);
   # $* = 1; # Multi-line patterns.
   $/ = ";"; # Pattern-space delimiter is a semicolon
#   open (OUT1,">$module.wire") || "Cannot open output file.\n";
#   open (OUT2,">$module.assign") || "Cannot open output file.\n";
#   open (OUT3,">$module.max") || "Cannot open output file.\n";
#   open (OUT4,">$module.all_in_wires") || "Cannot open output file.\n";
#   open (OUT5,">$module.all_wires") || "Cannot open output file.\n";
   for ( $i = 0; $i <= $#PORT_NAME; $i += 2 )
     {
      open (FILE2,"$TMPOUTFILE3") || die "Cannot open $TMPOUTFILE3\n";
      while (<FILE2>)
          {
           next unless ( /\b(input|output|inout)\b/ );
           $PTYPE = '';
           # ( $PTYPE, $WIDTH, $BIT1, $BIT2, $J1, $J2, $J3 ) = /(input|output|inout)\s*(\[\s*(\d+)\s*:\s*(\d+)\s*\])?(.|\n)*(\W|\n)+$PORT_NAME[$i](\W|\n)+/;
           #( $PTYPE, $WIDTH, $BIT1, $BIT2, $J1, $J2, $J3 ) = /(input|output|inout)\s*(\[\s*(\d+|[^:]+)\s*:\s*(\d+)\s*\])?.*(\W|\n)+$PORT_NAME[$i](\W|\n)+/ms;
           ( $PTYPE, $signed, $WIDTH, $BIT1, $BIT2, $J1, $J2, $J3 ) = /\b(input|output|inout)\s*(signed\s*)?(\[\s*(\d+|[^:]+)\s*:\s*(\d+)\s*\])?.*(\W|\n)+$PORT_NAME[$i](\W|\n)+/ms;
           #  ( $PTYPE, $J1, $J2, $J3 ) = /(input|output|inout)(.|\n)*(\W|\n)+$PORT_NAME[$i](\W|\n)+/;
           # last if ( /(input|output|inout)(.|\n)*(\W|\n)+$PORT_NAME[$i](\W|\n)+/ );
# print "*******************************************************\n";
# print "$_\n";
# print "*******************************************************\n";
           last if ( $PTYPE =~ /(input|output|inout)/ );
           }
      print ".$PORT_NAME[$i]($PORT_NAME[$i]$WIDTH)$PORT_NAME[$i+1]\n$BLANKS";
      $QBITS = 1;
      $QBITS += $BIT1 - $BIT2;
#      if ( $PTYPE =~ /input/ )
#       {
##        print OUT2 "assign $PORT_NAME[$i]$WIDTH = ${QBITS}'d0;\n";
#        print OUT2 "assign $PORT_NAME[$i]$WIDTH = ;\n";
#        print OUT3 "|$PORT_NAME[$i]$WIDTH : INPUT_PIN = ;\n";
#        if ($QBITS > 1 ){print OUT1 "wire $WIDTH $PORT_NAME[$i];\n";}
#        print OUT4 "wire $WIDTH $PORT_NAME[$i];\n";
#        }
#      elsif ( $PTYPE =~ /inout/ )
#       {
#        print OUT3 "|$PORT_NAME[$i]$WIDTH : BIDIR_PIN = ;\n";
#        }
#      elsif ( $PTYPE =~ /output/ )
#       {
#        print OUT3 "|$PORT_NAME[$i]$WIDTH : OUTPUT_PIN = ;\n";
#        }
#      print OUT5 "wire $WIDTH $PORT_NAME[$i];\n";
      close (FILE2);
      }
#   close (OUT1);
#   close (OUT2);
#   close (OUT3);
#   close (OUT4);
#   close (OUT5);
   # $* = 1; # Allows multi-line buffers.
   $/ = ");"; # Sets the input record separator to be ");"
   }


#  ********************************************************
#  This subroutine prints out the various results.
#  ********************************************************
sub OUTPUT_2
  {
   $SIGNAL = $SIG_NAME;
   @PORT_NAME = split(/,/,$SIGNAL);
   foreach $PARAM_I (@PORT_NAME)
    {
     if ($PARAM_I =~ /(parameter)\s*(\bint)?\s*(\w+)\b/ms)
      {
       ($PTYPE,$INTYPE,$LAST_PARAMETER) = $PARAM_I =~ /(parameter)\s*(\bint)?\s*(\w+)\b/ms;
       }
     }
   #for ( $i = 0; $i <= $#PORT_NAME; $i += 2 )
   #for ( $i = 0; $i <= $#PORT_NAME; $i++ )
   for ( $i = 0; $i < $#PORT_NAME; $i++ )
     {
      if ($PORT_NAME[$i] =~  /(input|output|inout)\s*(\bwire|reg|logic)?\s*(\[\s*(\d+|[^:]+)\s*:\s*(\d+)\s*\])?\s*(\w+)/ms)
       {
         if ($PORT_NAME[$i] =~ /(parameter)\s*(\bint)?\s*(\w+)\b/ms)
          {
           ($PTYPE,$INTYPE,$ACTUAL_PORT_NAME) = $PORT_NAME[$i] =~ /(parameter)\s*(\bint)?\s*(\w+)\b/ms;
           if ($ACTUAL_PORT_NAME eq $LAST_PARAMETER)
            {
             print ".$ACTUAL_PORT_NAME($ACTUAL_PORT_NAME)\n$BLANKS) ii_$MODULE (\n$BLANKS";
             }
           else
            {
             print ".$ACTUAL_PORT_NAME($ACTUAL_PORT_NAME),\n$BLANKS";
             }
           }
         ($PTYPE,$INTYPE,$SIGNED,$WIDTH,$BIT1,$BIT2,$ACTUAL_PORT_NAME) = $PORT_NAME[$i] =~  /(input|output|inout)\s*(\bwire|reg|logic)?\s*(signed\s*)?(\[\s*(\d+|[^:]+)\s*:\s*(\d+)\s*\])?\s*(\w+)/ms;
         print ".$ACTUAL_PORT_NAME($ACTUAL_PORT_NAME$WIDTH),\n$BLANKS";
         }
      elsif ($PORT_NAME[$i] =~ /(parameter)\s*(\bint)?\s*(\w+)\b/ms)
       {
        ($PTYPE,$INTYPE,$ACTUAL_PORT_NAME)) = $PORT_NAME[$i] =~ /(parameter)\s*(\bint)?\s*(\w+)\b/ms;
        if ($ACTUAL_PORT_NAME eq $LAST_PARAMETER)
         {
          print ".$ACTUAL_PORT_NAME($ACTUAL_PORT_NAME)\n$BLANKS) ii_$MODULE (\n$BLANKS";
          }
        else
         {
          print ".$ACTUAL_PORT_NAME($ACTUAL_PORT_NAME),\n$BLANKS";
          }
        }
      else
       {
        print "$PORT_NAME[$i],\n$BLANKS";
        }

      #print ".$PORT_NAME[$i]($PORT_NAME[$i]$WIDTH)$PORT_NAME[$i+1]\n$BLANKS";
      #print ".$PORT_NAME[$i]\n$BLANKS";
      }
    ($PTYPE,$INTYPE,$SIGNED,$WIDTH,$BIT1,$BIT2,$ACTUAL_PORT_NAME) = $PORT_NAME[$#PORT_NAME] =~  /(input|output|inout)\s*(\bwire|reg|logic)?\s*(signed\s*)?(\[\s*(\d+|[^:]+)\s*:\s*(\d+)\s*\])?\s*(\w+)/ms;
    print ".$ACTUAL_PORT_NAME($ACTUAL_PORT_NAME$WIDTH)\);\n\n";


   }
