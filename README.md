CredSwissArmy
======
		
This script is designed to identify if credentials are valid, invalid, or local 
admin valid credentials within a domain network and will also check for local admin.
It works by attempting to mount C$ on each server using different credentials.

This script also accepts NTLM hashes and uses pass-the-hash to confirm them.

**WARNING**:
	Careful running a domain account against multiple servers.  If the 
	Active Directory environment is setup to lockout accounts, you can
	easily accidentally lock a domain account by having too many invalid
	login attempts.  Always test a domain account with one server to see 
	if it is a valid password before attempting across multiple servers 
	to check for local admin

## Requirements:
   * Kali
   * Perl
   * smbclient (should be default in kali)
   * pth-smbclient (should be default in kali)

## Basic Usage:
   * ./CredSwissArmy.pl -a &lt;account or file&gt; -s &lt;server or file&gt; -o &lt;output_file&gt;
   * ./CredSwissArmy.pl -a &lt;account or file&gt; -s &lt;server or file&gt; -o &lt;output_file&gt; --ntlm

## Examples:
   * ./CredSwissArmy.pl -a 'testdomain\raikia:hunter2' -s 10.10.10.10 -o results.txt
   * ./CredSwissArmy.pl -a accounts.txt -s 10.10.10.10. -o results.txt
   * ./CredSwissArmy.pl -a 'testdomain\raikia:hunter2' -s servers.txt -o results.txt
   * ./CredSwissArmy.pl -a accounts.txt -s servers.txt -o results.txt
   * ./CredSwissArmy.pl -a 'testdomain\raikia:6608e4bc7b2b7a5f77ce3573570775af' -s 10.10.10.10 -o results.txt --ntlm
   * ./CredSwissArmy.pl -a accounts.txt -s servers.txt -o results.txt --ntlm

## Example output file:
   ```
      10.10.10.10,testdomain\admin,password,LOCAL ADMIN! Valid
      10.10.10.10,testdomain\randomuser,password,Valid
      10.10.10.10,testdomain\randomuser2,password,Invalid Creds
   ```

## Help to show all available options:
   * ./CredSwissArmy.pl -h


## ARGUMENTS
   * -a, --accounts &lt;word/file&gt;  
   	>	A word or file of user credentials to test.  Usernames are accepted in the form of 'DOMAIN\USERNAME:PASSWORD' ('DOMAIN\' is optional) (Username:Password delimiter is configurable)

   * -s, --servers &lt;word/file&gt;  
	>	A word or file of servers to test against.  Each credential will be tested against each of these servers by mounting attempting to mount "C$"

## Other Options
   * -v, --valid  
	>	Only print valid credentials (those with valid usernames/passwords).  Will print both local admins and those with valid users.
	
   * -i. --invalid  
	>	Only print invalid credentials (those with invalid username/password pairs).
	
   * -o, --output &lt;file&gt;  
	>	Print results to a file

   * --delimiter  
   	>	Change the delimiter of the output file.  Default is ","
   	
   * -d, --debug
   	>	Print out debugging messages
   	
   * -p, --passdelimiter  
	>	Change the delimiter between the account username and password.  Default is ":"
	
   * --formatoutput &lt;string&gt;
	>	Change the output format to the screen in PRINTF format (default: "%-35s %-35s %-35s %-35s\n")

	You can supply either a single account/server via commandline, or
	give a filename with multiple values separated by a new line

   * --ntlm
        >       Treat the passwords as NTLM hashes and attempt to pass-the-hash with them



## Contact Information

Feel free to contact me with any changes or feature requests!
* https://twitter.com/raikiasec
* raikiasec@gmail.com
