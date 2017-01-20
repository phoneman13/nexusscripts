# NAME

paperwallet.pl - Back up private keys into a PDF format which can be printed to paper.

# USAGE

You must be running nexus - you can include the full path to the nexus binary on the command line.

    $ ./paperwallet.pl $HOME/code/Nexus/nexus

# DESCRIPTION

In the example shown, a paper wallet will be printed to ~/NexusPaperWallets/

# INTERFACE

Command line arguments.

- **-x or --nexusfull** Full path and name of your nexus binary. This is ./nexus if you are running the script in your Nexus folder.
- **-d or --debug** Print debug info - may contain private keys.
- **-v or --debugcmd** Print all shell commands run from script. May contain private keys.
- **-j or --savejson** Save a JSON version of the public and private key information as well.
- **-p or --noview** Do not attempt to open the PDF viewer when complete (good for security or if you are running on a server with no GUI)

# NOTES

The .tex file, included in the same directory, also contains your private key info.
This is a specially crafted text file which is used to generate the pdf.
If you want to back this up as well, you can. It could be helpful in the event that the PDF were corrupted.
Also, be careful with it since it does contain private keys.
Note that the other latex related build files (.log) may contain info on your private keys.
You are responsible for cleaning these up if you desire to do so.

# WARNINGS

If you have encrypted your wallet, be aware that running this script will produce an unencrypted plain text version of your wallet on the hard drive. If you are not OK with that then do not use this script.

Do not run this script while others are watching or while you are screen casting. Private keys may be dumped out to the screen at any time.

You should only use this script on a secure system where you are using fill disk encryption.
The qrcode latex library caches some information about qrcodes.
This means that information on your private key may be saved on the computer in locations you are not aware of.

The latex libraries can take up a lot of space on your hard drive.

# LICENSE

https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

# WARRANTY

Selected setions from the GPL v2:

11\. BECAUSE THE PROGRAM IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM IS WITH YOU. SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

12\. IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES. 
