#!/usr/bin/perl -w
use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use IPC::Open3;
exit main();

my $dbg = 0;

sub main {
   print STDERR <<BLOCKOUT
       ____              _ ____          _            _    
      / ___|_ __ ___  __| / ___|_      _(_)___ ___   / \\   _ __ _ __ ___  _   _   
     | |   | '__/ _ \\/ _` \\___ \\ \\ /\\ / / / __/ __| / _ \\ | '__| '_ ` _ \\| | | | 
     | |___| | |  __/ (_| |___) \\ V  V /| \\__ \\__ \\/ ___ \\| |  | | | | | | |_| |
      \\____|_|  \\___|\\__,_|____/ \\_/\\_/ |_|___/___/_/   \\_\\_|  |_| |_| |_|\\__, |
                                                                          |___/ 

                                    By Chris King




BLOCKOUT
;


   my ($inputValid, $inputInvalid, $inputSkipIfError, $inputHash);
   $inputValid = $inputInvalid = $inputSkipIfError = $inputHash = 0;
   my ($inputAccounts, $inputServers, $inputOutput, $inputHelp, $inputMan);
   $inputAccounts = $inputServers = $inputOutput = $inputHelp = $inputMan = '';
   # Todo: Make these following variables switches eventually
   my $credsSeparator = ':';
   my $outputSeparator = ",";
   my $printToScreenFormat = "%-35s %-35s %-35s %-35s";
   GetOptions('accounts=s', \$inputAccounts,
           'servers=s', \$inputServers,
           'valid', \$inputValid,
           'invalid', \$inputInvalid,
           'output=s', \$inputOutput,
           'debug', \$dbg,
         'ntlm', \$inputHash,
         'passdelimiter=s', \$credsSeparator,
         'delimiter=s', \$outputSeparator,
         'formatoutput=s', \$printToScreenFormat,
         'help', \$inputHelp,
         'man', \$inputMan) or pod2usage(-verbose => 1) and exit;
   pod2usage(-verbose => 1) and exit if ($inputHelp);
   pod2usage(-verbose => 2) and exit if ($inputMan);
   pod2usage(-verbose => 1, -message => "Error: You must supply at least one account and server (either in word or file format)!\n") and exit if ($inputServers eq '' or $inputAccounts eq '');
   $inputValid = $inputInvalid = 1 if ($inputValid == 0 and $inputInvalid == 0);
   $printToScreenFormat = "$printToScreenFormat\n";
   my @accounts = ();
   my @servers = ();
   if (-e $inputAccounts) {
      debugMsg("Reading '$inputAccounts' for account information!\n");
      open(my $fh, '<', $inputAccounts) or pod2usage(-verbose => 1, -message => "Error: $0 - open '$inputAccounts' - $!\n") and exit;
      @accounts = <$fh>;
      chomp @accounts;
      @accounts = grep { debugMsg("Credential error: Found '$_' that did not have the credential separator '$credsSeparator' in it. Omitting...\n") and 0 unless(index($_,$credsSeparator)>-1); 1;} @accounts;
      close($fh);
   }
   else {
      debugMsg("'$inputAccounts' is not a valid file, so its a single cred!\n");
      pod2usage(-verbose => 1, -message =>  "Error: '$inputAccounts', the account to be used, did not have '$credsSeparator' in it to separate username and password! Cannot continue.\n") and exit if (index($inputAccounts,$credsSeparator) == -1);
      push @accounts, $inputAccounts;
   }

   if (-e $inputServers) {
      debugMsg("Reading '$inputServers' for server information!\n");
      open(my $fh, '<', $inputServers) or pod2usage(-verbose => 1, -message => "Error: $0 - open '$inputServers' - $!\n") and exit;
      @servers = <$fh>;
      chomp @servers;
      close($fh);
   }
   else {
      debugMsg("'$inputServers' is not a valid file, so its a single cred!\n");
      push @servers, $inputServers;
   }

   debugMsg("Starting the discovery process!\n");
   my $smbclient_cmd = 'smbclient';
   if ($inputHash) {
      $smbclient_cmd = 'pth-smbclient';
   }
   my @smbclient_args = ('-U', '', '', '', '-c', 'dir');
   my $headerPw = 'Password';
   my $errMsg = 'Invalid Creds';
   if ($inputHash) {
      $headerPw = 'NTLM';
      $errMsg = 'Invalid Hash';
      push(@smbclient_args, '--pw-nt-hash');
   }
   printf $printToScreenFormat, 'Server', 'Username', $headerPw, 'Response';
   print STDERR "--------------------------------------------------------------------------------------------------------------------------------\n" if ($printToScreenFormat eq "%-35s %-35s %-35s %-35s\n");
   my $outFH;
   if ($inputOutput ne '') {
      open($outFH, '>', $inputOutput) or print "Can't open output file '$inputOutput' ($!), so not writing an output file!\n\n";
   }
   foreach my $server (@servers) {
      foreach my $account (@accounts) {
         my ($username, $password) = split(/$credsSeparator/, $account, 2);
         $smbclient_args[1] = $username;
         $smbclient_args[2] = "\\\\$server\\C\$";
         $smbclient_args[3] = $password;
         my ($inStream, $outStream, $errStream) = '';
         my $pid = open3($inStream, $outStream, $errStream, $smbclient_cmd, @smbclient_args);
         my @results = <$outStream>;
         if ($results[0] =~ /LOGON_FAILURE/) { # Failed!
            if ($inputInvalid) {
               printf $printToScreenFormat, $server, $username, $password, $errMsg;
               printf $outFH "%s$outputSeparator%s$outputSeparator%s$outputSeparator%s\n", $server,$username,$password,$errMsg if ($outFH);
            }
         }
         elsif (scalar(@results) > 1 and $results[1] =~ /ACCESS_DENIED/) {  # Successful creds
            if ($inputValid) {
               printf $printToScreenFormat, $server, $username, $password, 'Valid';
               printf $outFH "%s$outputSeparator%s$outputSeparator%s$outputSeparator%s\n", $server,$username,$password,'Valid' if ($outFH);
            }
         }
         elsif ($results[0] =~ /OS=/ and substr($results[1],0,1) eq ' ' ) {
            if ($inputValid) {
               printf $printToScreenFormat, $server, $username, $password, 'LOCAL ADMIN!  Valid';
               printf $outFH "%s$outputSeparator%s$outputSeparator%s$outputSeparator%s\n", $server,$username,$password,'LOCAL ADMIN! Valid' if ($outFH);
            }
         }
         else { # A different error happened!
            my $errorLine = $results[0];
            $errorLine = $results[1] if (scalar(@results) > 1);
            my $errMsg = "Unknown Error: $errorLine";
            if ($errorLine =~ /NT_([a-zA-Z_]*)/) {
               $errMsg = "$1";
            }
            printf $printToScreenFormat, $server, $username, $password, $errMsg;
            printf $outFH "%s$outputSeparator%s$outputSeparator%s$outputSeparator%s\n", $server,$username,$password,$errMsg if ($outFH);
            printf "Response from system:   %s\n", join('',@results) if ($dbg);
         }
         waitpid($pid,0);
      }
   }

   return 0;
}

sub debugMsg {
   print "   -- Debug: $_[0]" if ($dbg);
   return 1;
}


__END__

=head1 Name

CredSwissArmy.pl

=head1 SYNOPSIS

Quickly check the validity of multiple user credentials across multiple servers
and be notified if that user has local administrator rights on each server.

=head1 DESCRIPTION

TBD

=head1 ARGUMENTS

   -a, --accounts <word/file>       A word or file of user credentials to test.
                                    Usernames are accepted in the form of 
                                    "DOMAIN\USERNAME:PASSWORD"
                        
                                    ("DOMAIN\" is optional)
                                    (Username:Password delimiter is configurable)

   -s, --servers <word/file>        A word or file of servers to test against.
                                    Each credential will be tested against each
                                    of these servers by mounting attempting to 
                                    mount "C$"

=head1 OPTIONS

   -v, --valid                      Only print valid credentials (those with valid
                                    usernames/passwords).  Will print both local 
                                    admins and those with valid users. 

   -i, --invalid                    Only print invalid credentials (those with
                                    invalid username/password pairs).

   -o, --output <file>              Print results to a file 

   --delimiter                      Change the delimiter of the output file.
                                    Default is ","

   --debug                          Print out debugging messages

   -p, --passdelimiter              Change the delimiter between the account username 
                                    and password.  Default is ":"
   
   --formatoutput <string>          Change the output format to the screen in PRINTF 
                                    format (default: "%-35s %-35s %-35s %-35s\n")

   --ntlm                           Treat the passwords as NTLM hashes and attempt
                                    to pass-the-hash!

=head1 AUTHOR

Chris King
