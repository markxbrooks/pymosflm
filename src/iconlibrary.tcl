# $Id: iconlibrary.tcl,v 1.1.1.1 2006/08/21 11:19:52 harry Exp $
package provide iconlibrary 1.0

# Load png library, unless running under aqua, in which case 
# the gif library should be used.
#
# N.B. Once the png bug in Img under Aqua is fixed, pnglibrary
# should always be used.

if {[tk windowingsystem] != "aqua"} {
    package require pnglibrary
} else {
    package require giflibrary
}
