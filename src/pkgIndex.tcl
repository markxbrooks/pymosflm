# This file is sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded imagedisplay 3.0 [list source [file join $dir imagedisplay.tcl]]
package ifneeded activity 1.0 [list source [file join $dir activity.tcl]]
package ifneeded advancedrefinementsettings 1.0 [list source [file join $dir advancedrefinementsettings.tcl]]
package ifneeded advancedintegrationsettings 1.0 [list source [file join $dir advancedintegrationsettings.tcl]]
package ifneeded sortscalemergesettings 1.0 [list source [file join $dir sortscalemergesettings.tcl]]
# This is the example of how to add a new tab to Processing options
#package ifneeded newonesettings 1.0 [list source [file join $dir newonesettings.tcl]]
package ifneeded advancedsessionsettings 1.0 [list source [file join $dir advancedsessionsettings.tcl]]
package ifneeded environmentvariables 1.0 [list source [file join $dir environmentvariables.tcl]]
package ifneeded bespokedetectorsettings 1.0 [list source [file join $dir bespokedetectorsettings.tcl]]
package ifneeded amodaldialog 1.0 [list source [file join $dir amodaldialog.tcl]]
package ifneeded pickwindow 1.0 [list source [file join $dir pickwindow.tcl]]
package ifneeded spotlistwindow 1.0 [list source [file join $dir spotlistwindow.tcl]]
package ifneeded balloon_help 0.1 [list source [file join $dir balloonhelp.tcl]]
package ifneeded balloonwidget 1.0 [list source [file join $dir balloonwidget.tcl]]
package ifneeded batch 1.0 [list source [file join $dir batch.tcl]]
package ifneeded cellrefinementwizard 1.0 [list source [file join $dir cellrefinementwizard.tcl]]
package ifneeded circlefitting 1.0 [list source [file join $dir circlefitting.tcl]]
package ifneeded combo 0.2 [list source [file join $dir combo.tcl]]
package ifneeded contrast 1.0 [list source [file join $dir contrast.tcl]]
package ifneeded pointlesswizard 1.0 [list source [file join $dir pointlesswizard.tcl]]
package ifneeded controller 3.0 [list source [file join $dir controller.tcl]]
package ifneeded dialog 0.1 [list source [file join $dir dialog.tcl]]
package ifneeded expandbutton 1.0 [list source [file join $dir expandbutton.tcl]]
package ifneeded experimentparameters 1.0 [list source [file join $dir experimentparameters.tcl]]
package ifneeded fileentry 0.1 [list source [file join $dir fileentry.tcl]]
package ifneeded fileopen 2.0 [list source [file join $dir fileopen2.tcl]]
package ifneeded giflibrary 1.0 [list source [file join $dir giflibrary.tcl]]
package ifneeded grab 1.0 [list source [file join $dir grab.tcl]]
package ifneeded gwidgets 1.0 [list source [file join $dir gwidgets.tcl]]
package ifneeded history 1.0 [list source [file join $dir history.tcl]]
package ifneeded iconlibrary 1.0 [list source [file join $dir iconlibrary.tcl]]
package ifneeded imagenumbers 1.0 [list source [file join $dir imagenumbers.tcl]]
package ifneeded indexing 2.0 [list source [file join $dir indexing.tcl]]
package ifneeded indexsettings 1.0 [list source [file join $dir indexsettings.tcl]]
package ifneeded indexwizard 0.1 [list source [file join $dir indexwizard.tcl]]
package ifneeded chunking 0.1 [list source [file join $dir chunking.tcl]]
package ifneeded integrationwizard 1.0 [list source [file join $dir integrationwizard.tcl]]
package ifneeded linker 1.0 [list source [file join $dir linker.tcl]]
package ifneeded masking 1.0 [list source [file join $dir masking.tcl]]
package ifneeded message 0.1 [list source [file join $dir message.tcl]]
package ifneeded mosaicity 1.0 [list source [file join $dir mosaicity.tcl]]
package ifneeded mosflm 3.0 [list source [file join $dir mosflm.tcl]]
package ifneeded mosflm_utilities 2.0 [list source [file join $dir utilities.tcl]]
package ifneeded mosflmGraph 1.0 [list source [file join $dir graph.tcl]]
package ifneeded overlays 1.0 [list source [file join $dir overlays.tcl]]
package ifneeded palette 1.0 [list source [file join $dir palette.tcl]]
package ifneeded phiprofile 1.0 [list source [file join $dir phiprofile.tcl]]
package ifneeded pnglibrary 1.0 [list source [file join $dir pnglibrary.tcl]]
package ifneeded processingdialog 1.0 [list source [file join $dir processingdialog.tcl]]
package ifneeded processingwizard 1.0 [list source [file join $dir processingwizard.tcl]]
package ifneeded processingresults 1.0 [list source [file join $dir processingresults.tcl]]
package ifneeded processingsettings 1.0 [list source [file join $dir processingsettings.tcl]]
package ifneeded progressbar 1.0 [list source [file join $dir progressbar.tcl]]
package ifneeded promptsavedialog 1.0 [list source [file join $dir promptsavedialog.tcl]]
package ifneeded qtrv 0.0 [list source [file join $dir qtrv.tcl]]
package ifneeded radio 1.0 [list source [file join $dir radio.tcl]]
package ifneeded session 1.0 [list source [file join $dir session.tcl]]
package ifneeded sessionsettings 1.0 [list source [file join $dir sessionsettings.tcl]]
package ifneeded sessionrecoverydialog 1.0 [list source [file join $dir sessionrecoverydialog.tcl]]
package ifneeded sessiontreedrag 1.0 [list source [file join $dir sessiontreedrag.tcl]]
package ifneeded settings2 1.0 [list source [file join $dir settings2.tcl]]
package ifneeded settingwidgets 1.0 [list source [file join $dir settingwidgets.tcl]]
package ifneeded spots 1.0 [list source [file join $dir spots.tcl]]
package ifneeded spotfindingsettings 2.0 [list source [file join $dir spotfindingsettings2.tcl]]
package ifneeded strategy 1.0 [list source [file join $dir strategy.tcl]]
package ifneeded tree 1.0 [list source [file join $dir tree.tcl]]
package ifneeded toolbutton 4.0 [list source [file join $dir toolbutton.tcl]]
package ifneeded gtooltip 1.0 [list source [file join $dir tooltip.tcl]]
package ifneeded userprofile 1.0 [list source [file join $dir userprofile.tcl]]
package ifneeded warnings 1.0 [list source [file join $dir warnings.tcl]]
package ifneeded latticetab 1.0 [list source [file join $dir latticetab.tcl]]
