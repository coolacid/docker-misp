	Configuration of System V init under Debian GNU/Linux

Most Unix versions have a file here that describes how the scripts
in this directory work, and how the links in the /etc/rc?.d/ directories
influence system startup/shutdown.

For Debian, this information is contained in the policy manual, chapter 
"System run levels and init.d scripts".  The Debian Policy Manual is 
available at:

    http://www.debian.org/doc/debian-policy/#contents

The Debian Policy Manual is also available in the Debian package
"debian-policy".  When this package is installed, the policy manual can be
found in directory /usr/share/doc/debian-policy. If you have a browser
installed you can probably read it at

    file://localhost/usr/share/doc/debian-policy/

Some more detailed information can also be found in the files in the
/usr/share/doc/sysv-rc directory.

Debian Policy dictates that /etc/init.d/*.sh scripts must work properly
when sourced.  The following additional rules apply:

* /etc/init.d/*.sh scripts must not rely for their correct functioning
  on their being sourced rather than executed.  That is, they must work
  properly when executed too. They must include "#!/bin/sh" at the top.
  This is useful when running scripts in parallel.

* /etc/init.d/*.sh scripts must conform to the rules for sh scripts as
  spelled out in the Debian policy section entitled "Scripts" (§10.4).

Use the update-rc.d command to create symbolic links in the /etc/rc?.d
as appropriate. See that man page for more details.

All init.d scripts are expected to have a LSB style header documenting
dependencies and default runlevel settings.  The header look like this
(not all fields are required):

### BEGIN INIT INFO
# Provides:          skeleton
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Should-Start:      $portmap
# Should-Stop:       $portmap
# X-Start-Before:    nis
# X-Stop-After:      nis
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# X-Interactive:     true
# Short-Description: Example initscript
# Description:       This file should be used to construct scripts to be
#                    placed in /etc/init.d.
### END INIT INFO

More information on the format is available from insserv(8).  This
information is used to dynamicaly assign sequence numbers to the
boot scripts and to run the scripts in parallel during the boot.
See also /usr/share/doc/insserv/README.Debian.
