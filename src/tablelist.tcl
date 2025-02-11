# $Id: tablelist.tcl,v 1.3 2010/11/18 15:13:46 ojohnson Exp $
#==============================================================================
# Main Tablelist package module.
#
# Copyright (c) 2000-2004  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

package require Tcl 8
package require Tk  8

namespace eval tablelist {
    #
    # Public variables:
    #
    variable version	3.7
    if {[string compare $::tcl_platform(os) "Darwin"] != 0} {
	#
	# On the Macintosh, the tablelist::library variable is
	# set in the file pkgIndex.tcl, because of a bug in
	# [info script] in some Tcl releases for that platform.
	#
	variable library	[file dirname [info script]]
    }

    #
    # Creates a new tablelist widget:
    #
    namespace export	tablelist

    #
    # Sorts the items of a tablelist widget based on one of its columns:
    #
    namespace export	sortByColumn

    #
    # Helper procedures used in binding scripts:
    #
    namespace export	getTablelistPath convEventFields

    #
    # Register various widgets for interactive cell editing:
    #
    namespace export	addBWidgetEntry addBWidgetSpinBox addBWidgetComboBox
    namespace export    addIncrEntryfield addIncrDateTimeWidget \
			addIncrSpinner addIncrSpinint addIncrCombobox
    namespace export	addOakleyCombobox
    namespace export	addDateMentry addTimeMentry addFixedPointMentry \
    			addIPAddrMentry
}

package provide Tablelist $tablelist::version
package provide tablelist $tablelist::version

lappend auto_path [file join $tablelist::library scripts]
