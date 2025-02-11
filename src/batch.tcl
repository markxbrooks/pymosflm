# $Id: batch.tcl,v 1.30 2021/01/07 16:13:31 andrew Exp $
package provide batch 1.0

#package require Expect

class BatchSubmissionDialog {
    inherit Amodaldialog

    private variable destinations {}
#
# parallel batch variables
#
    private variable cores {}
    private variable batches 0
    private variable thisBatchSize 0
    private variable batchJobList ""
    private variable jobHasStarted 0
    private variable jobIsRunning 0
    private variable totalImages 0
    private variable totalCores 0
    private variable showRefineEachBatch 0
    private variable refineEachBatch 1
    private variable useLastBatch 1
    private variable resolution 999
    private variable respost 999
    private variable Automatch 0
    private variable current_destination ""
    private variable SessionIsRunning 0
    private variable workingDirectory ""
    private variable imageDirectory ""
    private variable destinationFields {}
    private variable lsubDir {}
    private variable localListOfSubDirs {}
    private variable localListOfXMLFiles {}
    private variable listOfXMLFiles {}
    private variable localListOfMTZFiles {}
    private variable listOfMTZFiles {}
    public variable  timeStamp "00000000_000000"

    private variable detector_manufacturer
    private variable l_script
#
# parallel batch methods
#
    public method launch
    public method ok
    public method okparallel
    public method splitThisBatch
    public method retrieveXML
    public method getBatchJobList
    public method deleteFromBatchJobList
    private method process
    private method processParallel
    private method processExpect

    public method configureDestinations
    public method updateDestinations
    public method getWorkingDirectory
    public method updateWorkingDirectory
    public method getImageDirectory
    public method updateImageDirectory
    public method getTimeStamp
    public method updateTimeStamp

    private method getNumberOfCores
    private method updateCores
    private method updateCoresByName
    private method updateBatches
    private method toggleRefineEachBatch
    private method toggleRefineEachBatchTable 
    private method hideRefineEachBatchTable 
    private method hideWindow
    private method showRefineEachBatchTable 
    private method toggleUseLastBatch
    private method toggleAutomatch
    private method toggleShowGraphs
#methods for testing whether fields have been set for batch jobs
    public method initializeDestinationFields
    public method setDestinationFields

    constructor { args } { }
}

body BatchSubmissionDialog::constructor { args } {

#     wm title $itk_component(hull) "Batch submission - Mosflm"
#     wm iconbitmap $itk_component(hull) @$::env(MOSFLM_GUI)/images/mosflm_inverse.xbm
#     #wm iconmask $itk_component(hull) @$::env(MOSFLM_GUI)/images/mosflm.xbm
	
    
    itk_component add script_f {
	frame $itk_interior.sf \
	    -borderwidth 1 -relief sunken
    }

    itk_component add script_l {
	label $itk_interior.sf.sl \
	    -text "Script:" \
	    -anchor w
    }


    itk_component add script_t {
	text $itk_interior.sf.st
    } {
	usual
	rename -background -textbackground textBackground Background
    }

    itk_component add script_sb {
	scrollbar $itk_interior.sf.sb \
	    -orient vertical \
	    -command [list $itk_component(script_t) yview]
    }

    $itk_component(script_t) configure \
	-yscrollcommand [list autoscroll $itk_component(script_sb)]

# script for refinement before each batch in parallel mode
    itk_component add rscript_f {
	frame $itk_interior.rsf \
	    -borderwidth 1 -relief sunken
    }

    itk_component add rscript_l {
	label $itk_interior.rsf.sl \
	    -text "Refinement Script:" \
	    -anchor w
    }


    itk_component add rscript_t {
	text $itk_interior.rsf.st -height 12
    } {
	usual
	rename -background -textbackground textBackground Background
    }
    itk_component add rscript_sb {
	scrollbar $itk_interior.rsf.sb \
	    -orient vertical \
	    -command [list $itk_component(rscript_t) yview]
    }

    $itk_component(rscript_t) configure \
	-yscrollcommand [list autoscroll $itk_component(rscript_sb)]


# script for refinement before each batch in parallel mode
    itk_component add destination_f {
	frame $itk_interior.df
    }
    itk_component add destination_l {
	label $itk_interior.df.dl \
	    -text "Send to: " \
	    -anchor w
    }

    itk_component add destination_c {
	combobox::combobox $itk_interior.df.dc \
	    -editable 0 \
	    -command [code $this updateCoresByName] \
	    -listvar [scope destinations]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }
    
    itk_component add config_b {
	button $itk_interior.df.cb \
	    -text "Configure..." \
	    -command [code $this configureDestinations]
    }
    
# multiple core submission stuff
    itk_component add cores_f {
	frame $itk_interior.cf
    }
    itk_component add cores_l {
	label $itk_interior.cf.al \
	    -text "Number of cores: " \
	    -anchor w
    }
    
    itk_component add cores_c {
	combobox::combobox $itk_interior.cf.ac \
	    -editable 1 \
	    -width 4 \
	    -command [code $this updateCores] \
	    -listvar [scope cores]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }
    
    itk_component add bestbatchsize_l {
	label $itk_interior.cf.bbs \
	    -text "Batch size (images):" \
	    -anchor w
    }
    itk_component add bestbatchsize_e {
	SettingEntry $itk_interior.cf.bbe thisBatchSize \
	    -type int \
	    -justify right \
	    -state readonly \
	    -width 4
    }
#-----------
    itk_component add showrefine_f {
	frame $itk_interior.sr
    }
    
    itk_component add showrefine_l {
	label $itk_interior.sr.l  \
	    -text "Show refinement script" \
	    -anchor w
    }

    itk_component add showrefine_yn {
	SettingCheckbutton $itk_interior.sr.sryn showrefine_yesno \
	    -text "" \
	    -command [code $this toggleRefineEachBatchTable]
    }
#-----------
    itk_component add blockrefine_brl {
	label $itk_interior.sr.brl  \
	    -text "Refine before each batch\n(recommended)" \
	    -anchor w
    }
    itk_component add blockrefine_yn {
	SettingCheckbutton $itk_interior.sr.bryn blockrefine_yesno \
	    -text "" \
	    -command [code $this toggleRefineEachBatch]
    }
#-----------
    itk_component add uselastbatch_brl {
	label $itk_interior.sr.ulbl  \
	    -text "Use previous batch's refined values\n(recommended)" \
	    -anchor w
    }
    itk_component add uselastbatch_yn {
	SettingCheckbutton $itk_interior.sr.ulbyn uselastbatch_yesno \
	    -text "" \
	    -command [code $this toggleUseLastBatch]
    }
#-----------
    itk_component add showgraphs_l {
	label $itk_interior.sr.sgl  \
	    -text "show graphs from integration" \
	    -anchor w
    }
    itk_component add showgraphs_yn {
	SettingCheckbutton $itk_interior.sr.sgyn showgraphs_yesno \
	    -text "" \
	    -command [code $this toggleShowGraphs]
    }
#-----------
 


    itk_component add automatch_l {
	label $itk_interior.sr.aml  \
	    -text "Use convolution refinement\n(not recommended)" \
	    -anchor w
    }
    itk_component add automatch_yn {
	SettingCheckbutton $itk_interior.sr.amyn automatch_yesno \
	    -text "" \
	    -command [code $this toggleAutomatch]
    }
    # end of multiple core submission stuff 
    itk_component add button_f {
	frame $itk_interior.bf
    }

    itk_component add ok {
	button $itk_interior.bf.ok \
	    -text "Submit" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this ok]
    }
	    
    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this hideWindow]
    }
    #
    # hull
    # grid columnconfigure $itk_interior 1 -weight 1
    grid rowconfigure $itk_interior 99 -weight 1
    #
    # Script frame 
    grid configure $itk_component(script_f) -row 0
    grid columnconfigure $itk_component(script_f) 0 -weight 1
    grid $itk_component(script_f) - -sticky nwe -padx {6} -pady {6}
    #
    # Configure destination & submit frames
    grid configure $itk_component(destination_f) $itk_component(button_f) -row 20
    grid $itk_component(destination_f) -sticky nw -padx 6 -pady {6}
    grid $itk_component(button_f)      -sticky ne -padx 6 -pady {6}
    #
    # Cores frame
    grid configure $itk_component(cores_f) -row 21 -columnspan 2
    grid $itk_component(cores_f) -sticky nw -padx {6} -pady {6}
    #
    # Refinement Script frame
    grid configure  $itk_component(showrefine_f)  -row 22  -columnspan 2
    grid columnconfigure $itk_component(showrefine_f) 0 -weight 1
    grid rowconfigure $itk_interior 99 -weight 1
    grid $itk_component(showrefine_f)  -sticky nw -padx 6 -pady 6

    grid configure  $itk_component(rscript_f) -row 23
    grid columnconfigure $itk_component(rscript_f) 0 -weight 1
    grid rowconfigure $itk_interior 99 -weight 1
    grid $itk_component(rscript_f) -  -sticky swe -padx 6 -pady 6
    grid remove $itk_component(rscript_f)
    #-------------------------------------------------------------------
    # Script frame components
    grid $itk_component(script_l) - -sticky we 
    grid $itk_component(script_t) $itk_component(script_sb) -sticky nswe
    #
    # Button frame components
    grid $itk_component(ok) $itk_component(cancel) -sticky nw -ipadx 4
    #
    # Configure destination frame components
    grid $itk_component(destination_l) $itk_component(destination_c) $itk_component(config_b) -sticky nw 
    #
    # Cores & batch size frame components
    grid $itk_component(cores_l) $itk_component(cores_c) $itk_component(bestbatchsize_l) $itk_component(bestbatchsize_e) -sticky nw

    # Refinement Script frame  components - for parallel processing
    grid $itk_component(blockrefine_brl) $itk_component(blockrefine_yn) $itk_component(uselastbatch_brl) $itk_component(uselastbatch_yn) $itk_component(showrefine_l) $itk_component(showrefine_yn)  $itk_component(showgraphs_l) $itk_component(showgraphs_yn) -sticky nw -ipadx 2
    grid $itk_component(automatch_l) $itk_component(automatch_yn) 
    grid $itk_component(rscript_l) - -sticky we 
    grid $itk_component(rscript_t) $itk_component(rscript_sb) -sticky nswe

    # Build destinations list
    #updateDestinations
    bind $itk_component(blockrefine_yn) <ButtonPress-1> [code $this toggleRefineEachBatch]
    bind $itk_component(uselastbatch_yn) <ButtonPress-1> [code $this toggleUseLastBatch]
    bind $itk_component(showrefine_yn) <ButtonPress-1> [code $this toggleRefineEachBatchTable]
    bind $itk_component(showgraphs_yn) <ButtonPress-1> [code $this toggleShowGraphs]
    bind $itk_component(automatch_yn) <ButtonPress-1> [code $this toggleAutomatch]
    eval itk_initialize $args
}

body BatchSubmissionDialog::launch { a_script } {



    set l_fullinformation ""
    set l_fulldetectorinformation ""
    set detector_manufacturer [$::session getParameterValue detector_manufacturer]
    if { $detector_manufacturer != "" } {
	if { $detector_manufacturer == "RAXI" || $detector_manufacturer == "DIP2" } {
	    lappend l_fullinformation $detector_model
	} else {
	    lappend l_fullinformation $detector_manufacturer
	}
	# can be set in non-expert mode for I24
	if {  [$::session getDetectorOmega] != "" } {
	    lappend l_fullinformation "omega"
	    lappend l_fullinformation "[$::session getDetectorOmega]"
	}
	if { [$::session getReversePhi] } {
	    lappend l_fullinformation "reversephi"
	}
	
	if { $l_fullinformation != ""  } {
	    set l_fulldetectorinformation [concat "detector" $l_fullinformation]
	}
    }

    set l_script ""
    append l_script "$l_fulldetectorinformation\n"
    append l_script  $a_script

    set a_script $l_script

    # need to find number of images from "process" line
    set data [split $a_script "\n"]
    set l_directory {}
    foreach line $data {
	if {[regexp "process" $line]} {
	    set totalImages [expr [lindex ${line} 2] - [lindex ${line} 1] + 1]
	}
	if {[regexp "directory" $line] && ! [regexp "mtzdirectory" $line]} {
	    lappend l_directory [lindex $line end end]
	    set imageDirectory [::UserProfile::batchLocal0 setImageDirectory [lindex $l_directory 0 0]]
	    .bsd updateImageDirectory $imageDirectory
	}
    }
    # Select first machine for processing on if none selected
    if {[$itk_component(destination_c) get] == ""} {
	$itk_component(destination_c) select 0
    }
    set current_destination [BatchDestination::getDestinationByName [$itk_component(destination_c) get]]
    updateWorkingDirectory [$current_destination getWorkingDirectory]
    updateImageDirectory [$current_destination getImageDirectory]
    if {[$current_destination isa BatchLocal]} {
	if {[$current_destination getWorkingDirectory] == "" } {
	    updateWorkingDirectory [pwd]
	    $current_destination setWorkingDirectory [pwd]
#	    puts "setting working directory to [pwd] because it hasn't been set yet"
	}
    }
    # then work out how many cores to use or the maximum available
    if {[$itk_component(cores_c) get] == ""} {
	set batches [.bsd getNumberOfCores]
	$::session setNumberOfCores $batches
	$itk_component(cores_c) select $batches
	
    }
# initialize batches and thisBatchSize
    if {[$current_destination isa BatchRemote]} {
	set host [$itk_component(destination_c) get]
	set username [$current_destination getUsername]
	set executable [$current_destination getExecutable]
	set totalCores [$current_destination getTotalCores]
	if { $totalCores == "" } {
	    set totalCores [.bcd getRemoteCores]
	} {
	    $::session updateMaxNumberOfCores $totalCores
	}
    }
    if {[$current_destination isa BatchLocal]} {
	set totalCores [.bcd getLocalCores]
    }
    $current_destination setTotalCores $totalCores
    updateCores $itk_component(cores_c) $totalCores
    # set optimum minimum batch size
    $itk_component(bestbatchsize_e) setValue [$::session getBatchSizeFromCores]
    if {[$itk_component(bestbatchsize_e) getValue] == "0"} {
	$itk_component(bestbatchsize_e) setValue [$::session getBatchSizeFromCores]
    }
    set thisBatchSize [$itk_component(bestbatchsize_e) getValue]
    
    # Load script
    $itk_component(script_t) delete 0.0 end
    $itk_component(script_t) insert 0.0 $a_script
    #create & load a prototype refinement script
    set refineScript ""    
    append refineScript "BEAM <new x> <new y>\n"
    append refineScript "DISTANCE <new distance>\n"
    append refineScript "DISTORTION <new values>\n"
    append refineScript "MOSAIC <newvalue>\n"
    append refineScript "RASTER <nxs> <nys> <nc> <nrx> <nry>\n"
    append refineScript "SEPARATION <new values>\n"
    append refineScript "postref segment 1\n"
    append refineScript "\# automatch\n"
    append refineScript "resolution <low resolution run>\n"
    append refineScript "process <first> to <last> start <phi angle> angle <phi range per image>\n"
    append refineScript "run\n"
    append refineScript "save refined.pars\n"
    append refineScript "resolution <integration run>\n"
    append refineScript "postref nosegment\n"
    $itk_component(rscript_t) delete 0.0 end
    $itk_component(rscript_t) insert 0.0 $refineScript
# make non-editable
    $itk_component(rscript_t) configure -state disabled
    
    # show the dialog
    show
    return 1
}


body BatchSubmissionDialog::getWorkingDirectory { } {
    return $workingDirectory
}

body BatchSubmissionDialog::updateWorkingDirectory { a_directory } {
    set workingDirectory $a_directory
    return $workingDirectory
}

body BatchSubmissionDialog::getImageDirectory { } {
    return $imageDirectory
}

body BatchSubmissionDialog::updateImageDirectory { a_directory } {
    set imageDirectory $a_directory
    return $imageDirectory
}

body BatchSubmissionDialog::getTimeStamp { } {
    return $timeStamp
}

body BatchSubmissionDialog::updateTimeStamp { } {
    set timeStamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
    return $timeStamp
}

body BatchSubmissionDialog::ok { } {
    # Hide the dialog
    hide
    # need to test that the destination has had all its parameters set
    setDestinationFields [.bcd updateColourEntries]
    set okayToSubmit 1
    set forceField {}
    for {set destination 0} { $destination < [llength $destinationFields] } { incr destination } {
	set thisDestination [lsearch [lindex $destinationFields $destination] $current_destination]
	if { $thisDestination != -1 } {
	    if {[$current_destination isa BatchRemote]} {
		set listOfFields { executable host username working image } 
	    } {
		set listOfFields { executable } 
	    } 
	    set checkDestination [lindex $destinationFields $destination]
	    set field 1
	    set forceField {}
	    foreach entryField $listOfFields {
		if {[lindex $checkDestination $field] == "orange"} {
		    set okayToSubmit 0
		    lappend forceField $entryField
		}
		incr field
	    }
	}
    }
    if { [llength $forceField] > 0 } {
	.bcd addMissingEntries $current_destination $forceField
    } {
    # Process the batch job
	process
    }
}


body BatchSubmissionDialog::splitThisBatch { } {
# initialise variables & lists for splitting up script
    [.c component integration] initializeTreesAndGraphs
    $::session clearListOfXMLFiles
    set batches [$itk_component(cores_c) get]
    $::session setNumberOfCores $batches
    set batchJobList ""
    set thiswd [pwd]
    set processLineCount 0
    set processLine {}
    set lfirst_in_block {}
    set llast_in_block {}
    set lthis_start_angle {}
    set lthis_add_block {}
    set lsubDir {}
    set localListOfSubDirs {}
    set localListOfXMLFiles {}
    set listOfXMLFiles {}
    set localListOfMTZFiles {}
    set listOfMTZFiles {}
    set XMLFile "integrate_1.xml"
    set MTZFile "integrate_1.mtz"
    set testXMLFile ""
    set a_script [$itk_component(script_t) get 0.0 end]
    set data [split $a_script "\n"]
    set startLine 0
    set endLine 0
    foreach line $data {
	# do some line processing here
	# puts "line: $line"
	
	if {[regexp "mosaicity" $line]} {
	    set mosaicity [lindex ${line} 1 ]
	    
	} elseif {[regexp "resolution" $line]} {
	    set resolution [lindex ${line} 1 ]
	    if { $resolution >= 4.0 } {
		set respost  $resolution
	    } {
		set respost  [expr $resolution + 0.25]
		if { [expr 4.0 < $respost] } {
		    set respost 4.0
		}
#		set respost  $resolution
	    }
	    
	} elseif {[regexp "process" $line]} {
	    incr processLineCount
	    set first_image [lindex ${line} 1]
	    set last_image  [lindex ${line} 2]
	    set start_angle [lindex ${line} 4]
	    set range_angle [lindex ${line} 6]
	    set add_block   [lindex ${line} 8]
	    set totalImages [expr $last_image - $first_image + 1]
	    #
	    # work out how to divide up the images into batches
	    #
	    set thisBatchSize [expr $totalImages/$batches]
	    set thisProcessLine [concat $first_image $last_image $start_angle $range_angle $add_block $totalImages $thisBatchSize $batches]
	    lappend processLine $thisProcessLine
	} {
	}
    }
    for {set iCount 0} {$iCount < $processLineCount} { incr iCount} {
	set start_time [clock seconds]
	set thisProcessLine [lindex $processLine $iCount]
	set first_image        [lindex $thisProcessLine 0]
	set last_image         [lindex $thisProcessLine 1]
	set start_angle        [lindex $thisProcessLine 2]
	set range_angle        [lindex $thisProcessLine 3]
	set add_block          [lindex $thisProcessLine 4]
	set totalImages [expr $last_image - $first_image + 1]
	set thisBatchSize   [lindex $thisProcessLine 6]
	set batches             [lindex $thisProcessLine 7]
	#
	# postrefine images is actually one less than the number we want, but Mosflm 
	# lists the first and last in each segment, e.g. image N and image (N+4)
	#
	set postrefine_images [expr int(5.0*$mosaicity/$range_angle)]
	if {$postrefine_images >= 20  } {
	    set postrefine_images [expr $postrefine_images/2]
	}
	set thisBlock  ${iCount}_1
	set delayCount 0
	set totalJobsInList 0
    }
    #initialise all that we can here
    for {set Block 0} {$Block < $batches} {incr Block} {
	set pBlock [expr $Block + 1]
	$::session appendToListOfXMLFiles integrate_${pBlock}.xml
	lappend listOfXMLFiles integrate_${pBlock}.xml
	lappend listOfMTZFiles integrate_${pBlock}.mtz
	lappend lfirst_in_block [expr $Block * $thisBatchSize + $first_image]
	set last_in_block  [expr ($pBlock) * $thisBatchSize + $first_image - 1 ]
	if { $last_in_block > $last_image || $pBlock == $batches } {
	    set last_in_block $last_image
	}
	lappend llast_in_block $last_in_block
	lappend lthis_start_angle [expr $start_angle + ($range_angle * $thisBatchSize * $Block)]
	lappend lthis_add_block [expr $add_block + ($thisBatchSize * $Block)]
	[.c component integration] setReadMoreLines $Block "yes"
    }
    set workingDirectory [$current_destination getWorkingDirectory]
    set imageDirectory [getImageDirectory]
    set timeStamp [updateTimeStamp]
    for {set Block 0} {$Block < $batches} {incr Block} {
	set pBlock [expr $Block + 1]
	lappend lsubDir ${iCount}_${pBlock}
	updateWorkingDirectory [$current_destination getWorkingDirectory]
	updateImageDirectory [$current_destination getImageDirectory]
	if {[$current_destination isa BatchLocal]} {
	    
	    # check if workingDirectory subdirectories (e.g. 1_1) exists, if it does, move it
	    # out of the way to a datestamped subdirectory
	    if { $pBlock == 1 } {
		if { [file exists $workingDirectory/${iCount}_${pBlock}] } {
		    file mkdir $workingDirectory/$timeStamp
		    foreach subDir [glob $workingDirectory/${iCount}_*] {
			file rename $subDir $workingDirectory/$timeStamp/.
		    }
		}
	    }
	    file mkdir $workingDirectory/${iCount}_${pBlock}
	    set l_result [catch {set remoteShell [exec ssh localhost echo \$SHELL]} l_error]
	} { 
	    set username [$current_destination getUsername]
	    set host [$current_destination getHost]
	    updateWorkingDirectory [$current_destination getWorkingDirectory]
	    updateImageDirectory [$current_destination getImageDirectory]
	    if { $pBlock == 1 } {
		# local directories
		if { [file exists ${iCount}_${pBlock}] } {
		    file mkdir $timeStamp
		    foreach subDir [glob ${iCount}_*] {
			file rename $subDir $timeStamp/.
		    }
		}
		file mkdir ${iCount}_${pBlock}
		# remote directories
		set fo [open doesDirectoryExist "w"]
		puts $fo "#!/bin/sh\ntest -e $workingDirectory/${iCount}_${pBlock}\na=\$?\necho \$a\n"
		close $fo
		exec scp doesDirectoryExist $username@$host:
		set retCode [exec ssh -l ${username} ${host} "chmod +x doesDirectoryExist; ./doesDirectoryExist"]
		if { $retCode == 0 && ! [file exists $workingDirectory/$timeStamp]} {
		    exec ssh -l ${username} ${host} "mkdir $workingDirectory/$timeStamp;mv $workingDirectory/${iCount}_* $workingDirectory/$timeStamp/."
		}
	    }
	    if { ! [file exists $workingDirectory/${iCount}_${pBlock}]} {
		exec ssh -l ${username} ${host} "mkdir $workingDirectory/${iCount}_${pBlock}"
	    }
	}
	if {[$current_destination isa BatchLocal]} {
	    cd ${iCount}_${pBlock}
	}
	if { ! [info exists remoteShell] } {
	    set l_result [catch {set remoteShell [exec ssh -l ${username} ${host} "echo \$SHELL"]} l_error] 
	}
	set fo [open integrate_${pBlock} "w"]
	puts $fo "#!$remoteShell"
	puts $fo "time [$current_destination getExecutable]  XMLFILE integrate_${pBlock}.xml << EOF > integrate_${pBlock}.lp &" 
	#  Process data file
	set data [split $a_script "\n"]
	set processCount 1
	foreach line $data {
	    if {[regexp "directory" $line]} {
		set line "directory $imageDirectory"
	    }
	    if {[regexp "process" $line]} {
		set totalImages [expr $last_image - $first_image + 1]
		if {$processCount == 1} {
		    incr processCount
		    set first_in_block [lindex $lfirst_in_block $Block]
		    set last_in_block  [lindex $llast_in_block $Block]
		    set this_start_angle [lindex $lthis_start_angle $Block]
		    set this_add_block [lindex $lthis_add_block $Block]
		    set line [lreplace ${line} 1 2 $first_in_block $last_in_block]
		    set line [lreplace ${line} 4 4 $this_start_angle]
#may want to reduce NSIG for low resolution data		    puts $fo "refine nsig 4"
		    if { $refineEachBatch == 1 } {
			puts $fo "postref segment 1"
			if { $Automatch == 1 } {
			    puts $fo "automatch"
			}
			puts $fo "$postref_line"
			puts $fo "resolution $respost"
			puts $fo "process $first_in_block to [expr $first_in_block + $postrefine_images] start $this_start_angle angle $range_angle"
			puts $fo "run"
			puts $fo "save refined.pars"
			puts $fo "resolution $resolution"
			puts $fo "postref nosegment"
			if  { $useLastBatch == 1 } {
			    #
			    # read updated parameters if not first block
			    #  
			    
			    if { $Block > 0 } {
				if {[$current_destination isa BatchLocal]} {
				    set lastRoundFileExists [catch {set lastRoundFile [open ../${thisBlock}/refined.pars "r"] } l_error]
				} {
				    set lastRoundFileExists [catch {set lastRoundFile [open ${thisBlock}/refined.pars "r"]} l_error]
				} 

				set delayCount 0
				
				while {$lastRoundFileExists && [gets ${lastRoundFile} refineline] >= 0} {
				    if {[regexp "BEAM" $refineline ]} {
					puts $fo  $refineline
				    } elseif {[regexp "DISTANCE" $refineline ]} {
					puts $fo  $refineline
				    } elseif {[regexp "DISTORTION" $refineline ]} {
					puts $fo  $refineline
				    } elseif {[regexp "MOSAIC" $refineline ]} {
					puts $fo  $refineline
				    } elseif {[regexp "RASTER" $refineline ]} {
					puts $fo  $refineline
				    } elseif {[regexp "SEPARATION" $refineline ]} {
					puts $fo  $refineline
				    }
				}
# hrp 25.06.2013 - what to do if the last batch failed and there is no NEWMAT?
				puts $fo  "matrix ../${thisBlock}/NEWMAT"
				if { $lastRoundFileExists } {
				    close ${lastRoundFile}
				}
			    }
			}
		    }
		}
		puts $fo $line		
	    } {
		if {[regexp "postref" $line]} {
		    set postref_line [linsert $line 1 segment 1]
		    append postref_line "fix mosaic"
		    
		} elseif {[regexp "mtzdirectory" $line]} {
		    set line [lreplace ${line} 1 1 "."]
		    
		} elseif {[regexp "hklout" $line]} {
		    set line [lreplace ${line} 1 1 "integrate_${pBlock}.mtz"]
		} {
		    # default, don't change anything
		}
		puts $fo $line
	    }
	    set lastBlock $Block
	}
	puts $fo "EOF"
	puts $fo "echo \$\! > thisPID"
	close $fo
	exec chmod u+x integrate_${pBlock}
	if {[$current_destination isa BatchLocal]} {
	    set pid [exec ./integrate_${pBlock} &]
	    # must be foregrounded both here and on "remote localhost"
	    set fo [open doesThisPIDExist "w"]
	    puts $fo "#!/bin/sh\nwhile \[ ! -f $workingDirectory/${iCount}_${pBlock}/thisPID \]; do sleep 1 ;done"
	    close $fo
	    exec ssh localhost "cd $workingDirectory/${iCount}_${pBlock}; chmod +x doesThisPIDExist; ./doesThisPIDExist"
	    set fo [open $workingDirectory/${iCount}_${pBlock}/thisPID "r"]
	    gets $fo thisPID
	    lappend batchJobList $thisPID
	    set totalJobsInList [expr $totalJobsInList + 1 ]
	    # must be foregrounded both here and on "remote localhost"
	    set fo [open $workingDirectory/${iCount}_${pBlock}/doesRefinedParsExist "w"]
	    puts $fo "#!/bin/sh\nwhile \[ ! -f $workingDirectory/${iCount}_${pBlock}/refined.pars \]; do sleep 1 ;done"
	    close $fo
	    exec ssh localhost "chmod +x $workingDirectory/${iCount}_${pBlock}/doesRefinedParsExist; $workingDirectory/${iCount}_${pBlock}/doesRefinedParsExist"
	    
	} {
	    #
	    # remote job
	    #
	    # make local directory for local copies when running remotely
	    if { ! [file exists ${iCount}_${pBlock}] } {
#		puts "making remote directory ${iCount}_${pBlock} at [clock format [clock seconds] -format %H:%M:%S]"
		file mkdir ${iCount}_${pBlock}
	    }
	    exec scp integrate_${pBlock} $username@$host:$workingDirectory/${iCount}_${pBlock}
#	    puts "copying  integrate_${pBlock} to remote directory ${iCount}_${pBlock} at [clock format [clock seconds] -format %H:%M:%S]"
	    set remoteLoginProtocol [.bcd getRemoteLoginProtocol]
	    #
	    # integrate this block - this must be backgrounded both here and on remote host
	    #
	    set commandLine "$remoteLoginProtocol >& /dev/null;cd $workingDirectory/${iCount}_${pBlock}; ./integrate_${pBlock} & "
	    puts "submitting remote job for ${username} on ${host} at [clock format [clock seconds] -format %H:%M:%S]"
	    exec ssh -l ${username} ${host} $commandLine &
	    set okayToStartNextBatch 0
	    #
	    # PID exists? might need to pause a little
	    #
	    set PIDNotStarted 1
	    while { $PIDNotStarted } {
		set PIDNotStarted [catch {exec scp $username@$host:$workingDirectory/${iCount}_${pBlock}/thisPID ${iCount}_${pBlock}/.} l_error]
		after 250
	    }
	    #
	    # job has started?
	    #
	    puts "Job integrate_${pBlock} started at [clock format [clock seconds] -format %H:%M:%S]"
	    set fo [open ${iCount}_${pBlock}/thisPID "r"]
	    set thisPID [gets $fo]
	    close $fo
	    set commandLine "kill -0 $thisPID >& /dev/null;echo $?"
	    set jobHasStarted [catch {exec ssh -l ${username} ${host} $commandLine} l_error]
	    incr totalJobsInList
	    if { ! $jobHasStarted } {
	    }
	    lappend batchJobList $thisPID
	    #
	    # refined.pars exists? also need to make sure the job is still running
	    #
	    
	    set refinedParsExist 1
	    while { $refinedParsExist && $pBlock < $batches } {
		set refinedParsExist [catch {exec scp $username@$host:$workingDirectory/${iCount}_${pBlock}/refined.pars ${iCount}_${pBlock}/.} l_error]
		if { ! $refinedParsExist } {
#		    puts "copied refined.pars for job ${iCount}_${pBlock} at [clock format [clock seconds] -format %H:%M:%S]"
		    set okayToStartNextBatch 1
		}
		set jobHasStarted [catch {exec ssh -l ${username} ${host} $commandLine} l_error]
		if { $jobHasStarted } {
		    break
		}
		after 100
	    }
	    #
	    # this must be foregrounded both here and on remote host
	    file rename -force integrate_${pBlock} ${iCount}_${pBlock}/.
#	    puts "release the hounds! (pBlock = $pBlock)"
	}
	set parallelMTZFilenames ${iCount}_\*/integrate_*.mtz
	$::session setMTZFilename $parallelMTZFilenames
	#
	# now set up jobs for parsing
	#
	set thisBlock  ${iCount}_${pBlock}
#	if  { $okayToStartNextBatch == 0 } {
#	if { [ llength $batchJobList] == 1 } {
		if {[$current_destination isa BatchLocal]} {
		    set username ""
		    set host "localhost"
		    cd ${thiswd}
		}
	if {! [info exists lastLine] } {
	    set lastLine 0
	    set endLine 0
	}
	if { $lastLine  <= $endLine } {
	    set thisXMLFileAndSubDir [retrieveXML $username $host]
	    set thisXMLFile [lindex $thisXMLFileAndSubDir 1]
	    set thisSubDir  [lindex $thisXMLFileAndSubDir 0]
	    set startLine 1
	    set endLine 0
	}
		if  { [$::session getShowGraphs] == 1 } {
#		    if { $thisXMLFile != "" & $thisXMLFile != [file tail $XMLFile] } {
#			set startLine 1
#			set endLine 0
#		    }
		    if { $jobIsRunning == 9999 } {
		    if { $thisXMLFile != "" } { 
			if { $thisSubDir != "" } {
			    set thisXMLFile $thisSubDir/[file tail $thisXMLFile]
			}
			set XMLFile $thisXMLFile
			set fo [open $thisXMLFile "r"]
			set endLine 0
			set delay 500 
			while { ! [eof $fo] } {
			    gets $fo line
			    incr endLine
			    set lastLine $endLine
			}
			if { $endLine > [expr $startLine + 100] } { 
			    set endLine [expr $startLine + 100]
			    set delay 100 
			} 
			close $fo
			if { $jobIsRunning == 0 } {
#			incr endLine -1
			    #		    puts "(1) decrementing endLine to $endLine"
			}
			puts "(1) reading and parsing a single XML file - $XMLFile, starting at line $startLine and finishing at $endLine at [clock format [clock seconds] -format %H:%M:%S]"
			after $delay
			set doctype [Integrationwizard::readAndParseSingleXMLFile $thisXMLFile $startLine $endLine]
		puts "( ) return code from Integrationwizard::readAndParseSingleXMLFile is $doctype"
			set startLine $endLine
			puts "(1) after reading the XML file, startLine is $startLine, endLine is $endLine but lastLine is $lastLine at [clock format [clock seconds] -format %H:%M:%S]"
		    }
		    }
		}
#	    }
#	}
    }
    set timer 0
    set doctype 0
    while { ([llength $batchJobList] > 0) || ([llength $localListOfXMLFiles] > 0) } {
	
	if {[$current_destination isa BatchLocal]} {
	    set username ""
	    set host "localhost"
	    cd ${thiswd}
	}	   
	set thisXMLFileAndSubDir [retrieveXML $username $host]
#	set thisXMLFile [lindex $thisXMLFileAndSubDir 1]
#	set thisSubDir  [lindex $thisXMLFileAndSubDir 0]
	set thisXMLFile [lindex $localListOfXMLFiles 0]
	set thisSubDir  [lindex $localListOfSubDirs 0]
	if  { [$::session getShowGraphs] == 1 } {	    
	    if { $thisXMLFile != "" } { 
		if { $thisSubDir != "" } {
		    set thisXMLFile $thisSubDir/$thisXMLFile
		    set localListOfXMLFiles [lreplace $localListOfXMLFiles 0 0]
		    set localListOfSubDirs [lreplace $localListOfSubDirs 0 0]
		}
#
# new XML file only if we have read to the end of the previous one
#
		if { $doctype == 1 } {
		    if { $thisXMLFile != "" && $thisXMLFile != $XMLFile } {
			#		    puts "starting a new XML file"
			set XMLFile $thisXMLFile
			set startLine 1
		    }
		    set endLine 0
		}
		set fo [open $thisXMLFile "r"]
		while { ![eof $fo] } {
		    gets $fo line
		    incr endLine
		}
		incr endLine -1
		close $fo
		after 500
		puts "$thisXMLFile $startLine $endLine"
		set doctype [Integrationwizard::readAndParseSingleXMLFile $thisXMLFile $startLine $endLine]
		set startLine $endLine
	    }
	    after 500
	    incr timer
	}
    }
    .c idle
}

body BatchSubmissionDialog::retrieveXML { a_username a_host } {
# this checks to see if the jobs in the list are still running, and if not, 
# copies the appropriate XML file from the job to the local host.
    set joblist $batchJobList
    set username $a_username
    set host $a_host
    set thisXMLFile ""
    set thisSubDir ""
    foreach job $joblist {
	set commandLine "kill -0 $job >& /dev/null;echo $?"
	if {[$current_destination isa BatchLocal]} {
# I don't understand this - it shouldn't need to use "ssh localhost" to 
# run the command! 
	    set jobIsRunning [catch {exec ssh localhost $commandLine} l_error] 
	} {
	    set jobIsRunning [catch {exec ssh -l ${username} ${host} $commandLine} l_error] 
	} 
	set index [lsearch $batchJobList $job]
	set thisSubDir [lindex $lsubDir $index]
	set thisXMLFile [lindex $listOfXMLFiles $index]
	set thisMTZFile [lindex $listOfMTZFiles $index]
	if { $jobIsRunning == 0 } {
	    # job is not finished
	    if {[$current_destination isa BatchRemote]} {
		exec scp -p $username@$host:$workingDirectory/${thisSubDir}/$thisXMLFile ${thisSubDir}/.
		if { [lsearch $localListOfXMLFiles $thisXMLFile] < 0 } {
#		    puts "STILL RUNNING: updating localListOfXMLFiles with $index: [lindex $listOfXMLFiles $index]"
		    lappend localListOfXMLFiles $thisXMLFile
		    lappend localListOfSubDirs ${thisSubDir}
		} {
#		    puts "STILL RUNNING:          localListOfXMLFiles is $localListOfXMLFiles"
		}
	    }
# sometimes the XML file isn't available immediately the job ends
	    while { ![file exists ${thisSubDir}/$thisXMLFile] } {
		after 250
	    }
	    
	} {
	    # job must be finished
	    if {[$current_destination isa BatchRemote]} {
		exec scp -pr $username@$host:$workingDirectory/${thisSubDir} .
	    }
# sometimes the XML file isn't available immediately the job ends
	    while { ! [file exists ${thisSubDir}/$thisXMLFile] } {
		after 250
	    }
	    if { [lsearch $localListOfXMLFiles [lindex $listOfXMLFiles $index]] < 0 } {
		#		puts "*************************************************************"
		#	    puts "FINISHED: updating localListOfXMLFiles with $index: [lindex $listOfXMLFiles $index]"
		#		puts "*************************************************************"
		lappend localListOfXMLFiles [lindex $listOfXMLFiles $index]
		lappend localListOfMTZFiles [lindex $listOfMTZFiles $index]
		lappend localListOfSubDirs ${thisSubDir}
	    }
	    set batchJobList [lreplace $batchJobList $index $index]
	    set listOfXMLFiles [lreplace $listOfXMLFiles $index $index]
	    set listOfMTZFiles [lreplace $listOfMTZFiles $index $index]
	    set lsubDir [lreplace $lsubDir $index $index]
	}
	return [ list $thisSubDir $thisXMLFile ]
    }
}

body BatchSubmissionDialog::getBatchJobList { } {
    return $batchJobList
}

body BatchSubmissionDialog::deleteFromBatchJobList { a_pid } {
    set index [lsearch $batchJobList $a_pid]
    set batchJobList [lreplace $batchJobList $index $index]
    return $index
}

body BatchSubmissionDialog::process { } {
    set current_destination [BatchDestination::getDestinationByName [$itk_component(destination_c) get]]
    updateWorkingDirectory [$current_destination BatchDestination::getWorkingDirectory]
    splitThisBatch
    return 1
}

body BatchSubmissionDialog::processParallel { } {
    
}

body BatchSubmissionDialog::processExpect { } {
    exp_spawn -noecho ssh $host "\$MOSFLM_EXEC < [file join $::mosflm_directory batch.scr]"
    expect "password"
    exp_send "$password\r"
    expect -timeout -1 eof
}

body BatchSubmissionDialog::configureDestinations { } {
    .bcd show
}

body BatchSubmissionDialog::updateDestinations { } {
    set destinations {}
    foreach i_destination [BatchDestination::getDestinations] {
	lappend destinations [$i_destination getName]
    }
    if {([$itk_component(destination_c) get] == "") ||
	([lsearch $destinations [$itk_component(destination_c) get]] < 0)} {
	$itk_component(destination_c) select 0
    }
}

# cores for "parallel processing"

body BatchSubmissionDialog::updateCoresByName { a_widget a_value } {
    updateCores $a_widget "Auto"
}


body BatchSubmissionDialog::updateCores { a_widget a_value } {
#
# method to update the core list and the default number of cores to use based on the host
#
    set batches $a_value
    set host [$itk_component(destination_c) get]
    if { $current_destination != [BatchDestination::getDestinationByName $host] } {
	set current_destination [BatchDestination::getDestinationByName $host]
	set executable [$current_destination getExecutable]
	set totalCores [$current_destination getTotalCores]
	set batches "Auto"
    } {
	if { $totalCores == "" || $totalCores < 1 } {
	    if {[$current_destination isa BatchRemote]} {
		set totalCores [.bcd getRemoteCores]
	    }
	    if {[$current_destination isa BatchLocal]} {
		set totalCores [.bcd getLocalCores]
	    }
	    
	}
	if { $batches == "Auto" } {
	    if { $totalCores > 16 } { set maxBatches 16 } { set maxBatches $totalCores }
	    set thisBatchSize 999999
	    set batches 0
	    while { $thisBatchSize >= 30 && $batches < $maxBatches } {
		incr batches
		set thisBatchSize [expr $totalImages/$batches]
	    }
	    $itk_component(cores_c) select $batches
	} {
	    set thisBatchSize [expr $totalImages/$batches]
	}
    }
    if { $totalImages < 1 } {
	return
    }
    if { $batches == "Auto" } {
	if { $totalCores == "" || $totalCores < 1 } {
	    if {[$current_destination isa BatchRemote]} {
		set totalCores [.bcd getRemoteCores]
	    }
	    if {[$current_destination isa BatchLocal]} {
		set totalCores [.bcd getLocalCores]
	    }
	}
	set batches [getNumberOfCores]
	$itk_component(cores_c) select $batches
    }
    $itk_component(bestbatchsize_e) setValue $thisBatchSize
}
body BatchSubmissionDialog::updateBatches { } {
}
body BatchSubmissionDialog::getNumberOfCores { } {
#
# method to work out the batch size based on the number of cores available and the number of
# images in this dataset
#
    
    if { $totalImages < 1 } {
	puts "I don't know how many images there are, so I am returning now"
	return $batches
    }
    # determine number of cores available on this box, provide list
    if { $batches == 0 || $batches == "Auto" } {
	# 
	# cores is a list starting at "Auto"
	#
	set cores { "Auto" }
	for { set maxBatches 1 } { $maxBatches <= $totalCores } { incr maxBatches } {
	    lappend cores $maxBatches
	}
	if { $totalCores > 16 } { set maxBatches 16 } { set maxBatches $totalCores }
	if { $maxBatches < 1 } {
	    # this must never happen!
	    set maxBatches 1
	}
	set thisBatchSize 999999
	set batches 0
	while { $thisBatchSize >= 30 && $batches < $maxBatches } {
	    incr batches
	    set thisBatchSize [expr $totalImages/$batches]
	}
    } {
	# or don't over-ride value in widget
	set batches [$itk_component(cores_c) get]
	return $batches
    }
    return $batches
}

body BatchSubmissionDialog::toggleRefineEachBatch { args } {
        if { [set refineEachBatch]} {
	    set refineEachBatch 0
	    set useLastBatch 0
	    $itk_component(uselastbatch_yn) setValue 0
	    set Automatch 0
	    $itk_component(automatch_yn) setValue 0
	} {
	    set refineEachBatch 1
	    set useLastBatch 1
	    $itk_component(uselastbatch_yn) setValue 1
	}
}

body BatchSubmissionDialog::toggleUseLastBatch { args } {
        if { [set useLastBatch]} {
	    set useLastBatch 0
	} {
	    set useLastBatch 1
	}
}

body BatchSubmissionDialog::toggleRefineEachBatchTable { args } {
        if { [set showRefineEachBatch]} {
	    hideRefineEachBatchTable
	    set showRefineEachBatch 0
	} {
	    showRefineEachBatchTable
	    set showRefineEachBatch 1
	}
}
body BatchSubmissionDialog::hideRefineEachBatchTable { } {
    grid remove $itk_component(rscript_f)
}
body BatchSubmissionDialog::showRefineEachBatchTable { } {
    grid $itk_component(rscript_f)
}


body BatchSubmissionDialog::hideWindow { } {
    .c idle
    hide
}

body BatchSubmissionDialog::toggleShowGraphs { args } {
        if { [$::session getShowGraphs] == 1 } {
#	    puts "I was showing the graphs, but now I won't!"
	    $::session setShowGraphs 0
	} {
#	    puts "I wasn't showing the graphs, but now I will!"
	    $::session setShowGraphs 1
	}
}

body BatchSubmissionDialog::toggleAutomatch { args } {
    if { [set Automatch]} {
	set Automatch 0
    } {
	set Automatch 1
    }
    if { ! $refineEachBatch } {
	set Automatch 0
	$itk_component(automatch_yn) setValue 0
    }
}

body BatchSubmissionDialog::initializeDestinationFields {} {
    set destinationFields {}
}

body BatchSubmissionDialog::setDestinationFields { emptyField } {

    for {set index [expr [llength $destinationFields] -1]} { $index >= 0 } { incr index -1} {
	if { "[lindex [lindex $destinationFields $index] 0]" == "[lindex $emptyField 0]"} {
	    set destinationFields [lreplace $destinationFields $index $index]
	}
    }
    lappend destinationFields $emptyField
}

#############################################################################

# Batch destination configuration

class BatchConfigDialog {
    inherit Amodaldialog

    protected variable destinations_by_item ; # array
    private variable items_by_destination ; # array
    private variable current_destination ""

    private variable executable ""
    private variable host ""
    private variable totalCores ""
    private variable username ""
    private variable remoteTempDirectory ""
    private variable workingDirectory ""
    private variable imageDirectory ""
    private variable command ""
    private variable remoteShell
    public variable destinationFields {}
    # methods

    private method addDestination
    private method deleteDestination
    private method newRemoteDestination
    private method newFarmDestination
    private method sortDestinations
    private method renameDestination
    private method updateSelection
    private method queueUpdateSelection
    public  method addMissingEntries
    public  method updateColourEntries
    public  method resetConfigDialogue
    public  method resetConfigDialogueAndCancel
    public  method resetConfigDialogueAndProceed

    private method updateExecutable
    private method updateHost
    public  method getHost
    public  method updateTotalCores
    public  method getCores
    public  method getLocalCores
    public  method getRemoteCores
    private method getTotalCores
    public  method getUsername
    private method updateUsername
    public  method getRemoteLoginProtocol
    private method updateRemoteTempDirectory
    public method updateWorkingDirectory
    public method updateImageDirectory
    public  method getRemoteTempDirectory
    public  method getImageDirectory
    public  method getWorkingDirectory
    private method updateCommand
    public method getRemoteShell
    public method updateRemoteShell

    public  method initialize

    constructor { args } { }

}

body BatchConfigDialog::constructor { args } {

    itk_component add destination_frame {
	frame $itk_interior.df
    }

    itk_component add destination_tree {
	treectrl $itk_interior.df.dt \
	    -showroot 0 \
	    -showrootlines 0 \
	    -showheader 0 \
	    -selectmode single \
	    -width 400 \
	    -height 100
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    # Set up selection binding
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Selection> [code $this queueUpdateSelection %S %D]
    # Set up delete binding
    bind $itk_component(destination_tree) <KeyPress-Delete> [code $this deleteDestination]
if {[tk windowingsystem] == "aqua"} {
    bind $itk_component(destination_tree) <Command-ButtonPress-2> [code $this deleteDestination]
} else {
    bind $itk_component(destination_tree) <Control-ButtonPress-2> [code $this deleteDestination]
}
    #$itk_component(destination_tree) notify bind $itk_component(destination_tree) <Key-Delete> [code $this keyPressDelete %c]

    $itk_component(destination_tree) column create -text Destination -tag destination -justify left -expand 1 ;# -itembackground {"\#ffffff" "\#e8e8e8"} 

    $itk_component(destination_tree) element create e_icon image -image ::img::raw_solution
    $itk_component(destination_tree) element create e_text text -fill {white selected}
    $itk_component(destination_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(destination_tree) style create s1
    $itk_component(destination_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(destination_tree) style layout s1 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(destination_tree) style layout s1 e_text -expand ns
    $itk_component(destination_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
#     $itk_component(destination_tree) style create s2
#     $itk_component(destination_tree) style elements s2 {e_highlight e_text}
#     $itk_component(destination_tree) style layout s2 e_text -expand ns
#     $itk_component(destination_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
        
    #bind $itk_component(destination_tree) <Double-ButtonPress-1> [code $this doubleClickDestination %W %x %y]

    # Set up tags to support treectrl's "file list" bindings
    bindtags $itk_component(destination_tree) [list $itk_component(destination_tree) TreeCtrlFileList TreeCtrl [winfo toplevel $itk_component(destination_tree)] all]
    
    # Instal item editing events
    $itk_component(destination_tree) notify install <Edit-begin>
    $itk_component(destination_tree) notify install <Edit-end>
    $itk_component(destination_tree) notify install <Edit-accept>

    # List of lists: {column style element ...} specifying text elements
    # the user can edit
    TreeCtrl::SetEditable $itk_component(destination_tree) {
	{destination s1 e_text}
    }
    
    # List of lists: {column style element ...} specifying elements
    # the user can click on or select with the selection rectangle
    TreeCtrl::SetSensitive $itk_component(destination_tree) {
	{destination s1 e_icon e_text e_highlight}
    }
    
    # List of lists: {column style element ...} specifying elements
    # added to the drag image when dragging selected items
    TreeCtrl::SetDragImage $itk_component(destination_tree) {
	{destination s1 e_icon e_text}
    }
    
    # During editing, hide the text and (NOT!) selection-rectangle elements
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Edit-begin> {
	%T item element configure %I %C e_text -draw no;# + e_highlight -draw no
    }

    # On completion of editing, call rename method
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Edit-accept> [code $this renameDestination %I %t]


    # After editing, show the text and (STILL) selection-rectangle elements
    $itk_component(destination_tree) notify bind $itk_component(destination_tree) <Edit-end> {
	%T item element configure %I %C e_text -draw yes;# + e_highlight -draw yes
    }
    
    itk_component add destination_scroll {
	scrollbar $itk_interior.df.ds \
	    -command [code $this component destination_tree yview] \
	    -orient vertical
    }
    
    $itk_component(destination_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(destination_scroll)]


#     itk_component add list {
# 	tablelist::tablelist $itk_interior.l \
# 	    -background white \
# 	    -highlightthickness 0 \
# 	    -width 0 \
# 	    -height 5 \
# 	    -showlabels 0 \
# 	    -selectborderwidth 0 \
# 	    -exportselection 0 \
# 	    -stretch 0 \
# 	    -sortcommand [code $this sortDestinations] \
# 	    -editendcommand [code $this renameDestination] \
# 	    -columns {
# 		50 "Destination"
# 	    }
#     } {
# 	keep -labelfont
# 	rename -font -entryfont entryFont Font
# 	keep -selectforeground -selectbackground
#     }
#     $itk_component(list) columnconfigure 0 -align left
#     bind $itk_component(list) <<ListboxSelect>> [code $this updateSelection]

    itk_component add button_f {
	frame $itk_interior.bf
    }


    itk_component add new_remote_b {
	button $itk_interior.bf.nrb \
	    -image ::img::new_remote16x16 \
	    -command [code $this newRemoteDestination]
    }

    itk_component add new_farm_b {
	button $itk_interior.bf.nfb \
	    -image ::img::new_farm16x16 \
	    -command [code $this newFarmDestination]
    }

    itk_component add destination_l {
	label $itk_interior.dl \
	    -text "Destination: " \
	    -anchor w
    }

    itk_component add icon_l {
	label $itk_interior.icon \
	    -anchor w
    }

    itk_component add name_l {
	label $itk_interior.name \
	    -text "" \
	    -anchor w
    }

    itk_component add executable_l {
	label $itk_interior.el \
	    -text "Executable: " \
	    -anchor w
    }

    itk_component add executable_e {
	gEntry $itk_interior.ee \
	    -textvariable [scope executable] \
	    -command [code $this updateExecutable]
    }

    itk_component add host_l {
	label $itk_interior.hl \
	    -text "Host: " \
	    -anchor w
    }

    itk_component add host_e {
	gEntry $itk_interior.he \
	    -textvariable [scope host] \
	    -command [code $this updateHost]
    }
# cores available on remote machine
     itk_component add cores_l {
	label $itk_interior.totcl \
	    -text "Total Cores: " \
	    -anchor w
    }

    itk_component add cores_e {
	gEntry $itk_interior.totce \
	    -textvariable [scope totalCores] \
	    -command [code $this updateTotalCores]
    }

    itk_component add cores_update_b {
	button $itk_interior.totup \
	    -image ::img::update_cores16x16 \
	    -command [code $this getCores]
    }


   itk_component add username_l {
	label $itk_interior.ul \
	    -text "Username: " \
	    -anchor w
    }

    itk_component add username_e {
	gEntry $itk_interior.ue \
	    -textvariable [scope username] \
	    -command [code $this updateUsername]
    }

    itk_component add command_l {
	label $itk_interior.cl \
	    -text "Command: " \
	    -anchor w
    }

    itk_component add command_e {
	gEntry $itk_interior.ce \
	    -textvariable [scope command] \
	    -command [code $this updateCommand]
    }
    
# working directory on batch machine (may be local or remote)
    itk_component add working_l {
	label $itk_interior.wl \
	    -text "Remote working directory: " \
	    -anchor w
    }

    itk_component add working_e {
	gEntry $itk_interior.we \
	    -textvariable [scope workingDirectory] \
	    -command [code $this updateWorkingDirectory]
    }
    
# image directory on batch machine (may be local or remote)
    itk_component add image_l {
	label $itk_interior.il \
	    -text "Remote image directory: " \
	    -anchor w
    }

    itk_component add image_e {
	gEntry $itk_interior.ie \
	    -textvariable [scope imageDirectory] \
	    -command [code $this updateImageDirectory]
    }
    itk_component add ok {
	button $itk_interior.ok \
	    -text "Proceed" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this resetConfigDialogueAndProceed]
    }
	    
    itk_component add cancel {
	button $itk_interior.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this resetConfigDialogueAndCancel]
    }

#update background colours
    set emptyField $current_destination
    set listOfEntryFields { executable host username working image }
    foreach entryField $listOfEntryFields {
	if { [string length [$itk_component(${entryField}_e) query]] == 0 } {
	    set fieldColour orange
	} {
	    set fieldColour white
	} 
	lappend emptyField $fieldColour
	$itk_component(${entryField}_e) configure -textbackground $fieldColour
    }


    grid x $itk_component(destination_frame) - - $itk_component(button_f) -sticky nwe -pady {7 0}
    grid $itk_component(destination_tree) $itk_component(destination_scroll) -sticky nswe
    grid columnconfigure $itk_component(destination_frame) 0 -weight 1
    pack $itk_component(new_remote_b) $itk_component(new_farm_b) -padx 2 -pady {0 2}
    grid x $itk_component(destination_l) $itk_component(icon_l) $itk_component(name_l) -sticky we -pady {7 0}
    grid x $itk_component(executable_l) $itk_component(executable_e) - -sticky we -pady {7 0}
    grid x $itk_component(host_l) $itk_component(host_e) - -sticky we -pady {7 0}
    grid x $itk_component(cores_l) $itk_component(cores_e) - $itk_component(cores_update_b) -sticky we -pady {7 0}
    grid x $itk_component(username_l) $itk_component(username_e) - -sticky we -pady {7 0}
    grid x $itk_component(working_l) $itk_component(working_e) - -sticky we -pady {7 0}
    grid x $itk_component(image_l) $itk_component(image_e) - -sticky we -pady {7 0}
    grid x $itk_component(command_l) $itk_component(command_e) - -sticky we -pady {7 0}
    grid x $itk_component(ok) $itk_component(cancel) - -sticky we -pady {7 0}
    grid remove $itk_component(ok) 
    grid remove $itk_component(cancel)

    grid columnconfigure $itk_interior 0 -minsize 7
    grid columnconfigure $itk_interior 5 -minsize 7
    grid columnconfigure $itk_interior 3 -weight 1
    grid rowconfigure $itk_interior 99 -minsize 7 -weight 1

    eval itk_initialize $args
#update background colours
    set emptyField $current_destination
    set listOfEntryFields { executable host username working image }
    foreach entryField $listOfEntryFields {
	if { [string length [$itk_component(${entryField}_e) query]] == 0 } {
	    set fieldColour orange
	} {
	    set fieldColour white
	} 
	lappend emptyField $fieldColour
	$itk_component(${entryField}_e) configure -textbackground $fieldColour
	grid $itk_component(${entryField}_e)
    }


}

body BatchConfigDialog::addDestination { a_destination { a_edit 1 } } {

    # create new item 
    set l_item [$itk_component(destination_tree) item create]
    $itk_component(destination_tree) item style set $l_item 0 s1
    $itk_component(destination_tree) item text $l_item 0 [$a_destination getName]
    $itk_component(destination_tree) item element configure $l_item 0 e_icon -image [$a_destination getIcon]
    $itk_component(destination_tree) item lastchild root $l_item
    set destinations_by_item($l_item) $a_destination
    set items_by_destination($a_destination) $l_item

    # select new item
    $itk_component(destination_tree) selection modify $l_item all

    # sort tablist
    $itk_component(destination_tree) item sort root -command [code $this sortDestinations]

    # update batch submission dialog
    .bsd updateDestinations

    if { $a_edit } {
	# begin editing of destination name
	::TreeCtrl::FileListEdit $itk_component(destination_tree) $l_item destination e_text
    }
}

body BatchConfigDialog::deleteDestination { } {
    foreach i_item [$itk_component(destination_tree) selection get] {
	$itk_component(destination_tree) item delete $i_item
	delete object $destinations_by_item($i_item)
	array unset items_by_destination $destinations_by_item($i_item)
	array unset destinations_by_item $i_item
    }
    .bsd updateDestinations
    BatchDestination::saveProfile
}

body BatchConfigDialog::renameDestination { a_item a_name } {
    # Get the destination object
    set l_destination $destinations_by_item($a_item)
    # Try and rename it
    if {[$l_destination rename $a_name]} {
	# if succesful update tree label and destination label
	$itk_component(destination_tree) item text $a_item destination $a_name
	$itk_component(name_l) configure -text " $a_name" 
	# update batch submission dialog
	.bsd updateDestinations
    } else {
	# renaming failed (due to clash with existing name)...
	# (Do nothing)
    }
}   

body BatchConfigDialog::sortDestinations { a_item b_item } {
    # foreach item...
    foreach i {a b} {
	# get the corresponding destination
	set ${i}_destination $destinations_by_item([set ${i}_item])
	# get its class
	set ${i}_class [[set ${i}_destination] info class]
	# work out the order based on class
	if {[set ${i}_class] == "::BatchLocal"} {
	    set ${i}_class_order "a"
	} elseif {[set ${i}_class] == "::BatchRemote"} {
	    set ${i}_class_order "b"
	} else {
	    set ${i}_class_order "c"
	}
    }
    # compare by class order
    set l_comparison [string compare $a_class_order $b_class_order]
    # if the same..
    if {$l_comparison == 0} {
	# compare by name
	set l_comparison [string compare [$a_destination getName] [$b_destination getName]]
    }
    return $l_comparison
}

body BatchConfigDialog::newRemoteDestination { } {
    # generate an unused name
    set l_used_names [BatchDestination::getDestinationNames]
    set i_count 1
    while {1} {
	if {[lsearch $l_used_names "Remote$i_count"] < 0} {
	    set l_name "Remote$i_count"
	    break
	}
	incr i_count
    }
    # Create destination
    set l_destination [BatchRemote \#auto $l_name]
    addDestination $l_destination
}

body BatchConfigDialog::newFarmDestination { } {
    # generate an unsed name
    set l_used_names [BatchDestination::getDestinationNames]
    set i_count 1
    while {1} {
	if {[lsearch $l_used_names "Farm$i_count"] < 0} {
	    set l_name "Farm$i_count"
	    break
	}
	incr i_count
    }
    # Create destination
    set l_destination [BatchFarm \#auto $l_name]
    addDestination $l_destination
}

body BatchConfigDialog::queueUpdateSelection { a_selected a_deselected } {
    # NB updateSelection executed in event loop (using after) to
    # allow any <FocusOut> events for previous destination's parameters
    # to successful complete for "current_destination" before it is changed.
    after 0 [code $this updateSelection  $a_selected $a_deselected]
}

body BatchConfigDialog::updateSelection { a_selected a_deselected} {
    if {$a_selected != ""} {
	# get the selected destination
	set current_destination $destinations_by_item($a_selected)
	# update universally applicable settings (name, icon, executable)
	$itk_component(name_l) configure -text " [$current_destination getName]"
	$itk_component(icon_l) configure -image  [$current_destination getIcon]
	set executable [$current_destination getExecutable]
	set totalCores [$current_destination getTotalCores]
	# update class-specific widgets and settings
	if {[$current_destination isa BatchLocal]} {
	    grid remove $itk_component(host_l)
	    grid remove $itk_component(host_e)
	    grid remove $itk_component(username_l)
	    grid remove $itk_component(username_e)
# hrp 24.01.2014 - too many problems with working in different directory
# from current one with local host, so remove the option for the moment.
#	    $itk_component(working_l) configure -text "Local working directory: "
	    grid remove $itk_component(working_l)
	    grid remove $itk_component(working_e)
#	    $itk_component(image_l) configure -text "Local image directory: "
	    grid remove $itk_component(image_l)
	    grid remove $itk_component(image_e)
	    grid remove $itk_component(command_l)
	    grid remove $itk_component(command_e)
	} elseif {[$current_destination isa BatchRemote]} {
	    grid $itk_component(host_l)
	    grid $itk_component(host_e)
	    grid $itk_component(cores_l)
	    grid $itk_component(cores_e)
	    grid $itk_component(username_l)
	    grid $itk_component(username_e)
	    $itk_component(working_l) configure -text "Remote working directory: "
	    grid $itk_component(working_l)
	    grid $itk_component(working_e)
	    $itk_component(image_l) configure -text "Remote image directory: "
	    grid $itk_component(image_l)
	    grid $itk_component(image_e)
	    grid remove $itk_component(command_l)
	    grid remove $itk_component(command_e)

	    set host [$current_destination getHost]
	    set totalCores [$current_destination getTotalCores]
	    set username [$current_destination getUsername]
	    set remoteTempDirectory [$current_destination getRemoteTempDirectory]
	} elseif {[$current_destination isa BatchFarm]} {
	    grid remove $itk_component(host_l)
	    grid remove $itk_component(host_e)
	    grid remove $itk_component(cores_l)
	    grid remove $itk_component(cores_e)
	    grid remove $itk_component(username_l)
	    grid remove $itk_component(username_e)
	    grid remove $itk_component(working_l)
	    grid remove $itk_component(working_e)
	    grid remove $itk_component(image_l)
	    grid remove $itk_component(image_e)
	    grid $itk_component(command_l)
	    grid $itk_component(command_e)
	    set command [$current_destination getCommand]
	} else {
	    error "Unrecognized destination class"
	}
# common updates
	set workingDirectory [$current_destination getWorkingDirectory]
	set imageDirectory [$current_destination getImageDirectory]
	.bsd updateWorkingDirectory $workingDirectory
	.bsd updateImageDirectory $imageDirectory
    } else {
	set current_destination "" 
    }
    # colour empty fields orange
    set emptyField $current_destination
    if {[$current_destination isa BatchLocal]} {
	set listOfEntryFields { executable }
    } {
	set listOfEntryFields { executable host username working image }
    } 
    foreach entryField $listOfEntryFields {
	if { [string length [$itk_component(${entryField}_e) query]] == 0 } {
	    set fieldColour orange
	} {
	    set fieldColour white
	} 
	lappend emptyField $fieldColour
	$itk_component(${entryField}_e) configure -textbackground $fieldColour
	grid $itk_component(${entryField}_e)
    }
    .bsd setDestinationFields $emptyField
}

body BatchConfigDialog::addMissingEntries { a_current_destination a_missing } {
# only show those options that need to be updated    

    for { set count 1 } { $count <= [array size destinations_by_item] } { incr count} {
	if { "$a_current_destination" == "$destinations_by_item($count)" } {
	    set selected $count
	}
    }
    incr count -1
    set deselected [expr $count - $selected]
    if { $deselected == $selected } { incr deselected }
    if { $deselected >= $count } { set deselected "" }

    $this updateSelection $selected $deselected 
#update background colours
    set emptyField $current_destination
    set field {}
    if {[$current_destination isa BatchLocal]} {
	set listOfEntryFields { executable }
    } {
	set listOfEntryFields { executable host username working image }
    } 
    foreach entryField $listOfEntryFields {
	if { [string length [$itk_component(${entryField}_e) query]] == 0 } {
	    set fieldColour orange
	    lappend field $entryField
	} {
	    set fieldColour white
	} 
	lappend emptyField $fieldColour
	$itk_component(${entryField}_e) configure -textbackground $fieldColour
    }
# remove all choices of host etc
    grid remove $itk_component(destination_tree)
    grid remove $itk_component(destination_frame)
    grid remove $itk_component(button_f)
    grid remove $itk_component(destination_scroll)
    grid remove $itk_component(new_remote_b) 
    grid remove $itk_component(new_farm_b)
    foreach emptyField { executable host username working image } {
	grid remove $itk_component(${emptyField}_l)
	grid remove $itk_component(${emptyField}_e)
    }
    grid remove $itk_component(cores_update_b)
    foreach emptyField $field {
	grid $itk_component(${emptyField}_l)
	grid $itk_component(${emptyField}_e)
    }
    grid $itk_component(ok) 
    grid $itk_component(cancel)
    .bcd configure -title "Fill in the missing values"
    show
    return 1
}

body BatchConfigDialog::resetConfigDialogueAndCancel { } {
    resetConfigDialogue
}

body BatchConfigDialog::resetConfigDialogueAndProceed { } {
    resetConfigDialogue
    .bsd show
}

body BatchConfigDialog::resetConfigDialogue { } {
    grid $itk_component(destination_tree)
    grid $itk_component(destination_frame)
    grid $itk_component(button_f)
    grid $itk_component(destination_scroll)
    grid $itk_component(new_remote_b) 
    grid $itk_component(new_farm_b)
    grid $itk_component(executable_l) 
    grid $itk_component(executable_e)
    grid $itk_component(host_l)
    grid $itk_component(host_e)
    grid $itk_component(cores_l)
    grid $itk_component(cores_e)
    grid $itk_component(username_l)
    grid $itk_component(username_e)
    grid $itk_component(working_l)
    grid $itk_component(working_e)
    grid $itk_component(image_l)
    grid $itk_component(image_e)
    grid remove $itk_component(ok) 
    grid remove $itk_component(cancel)
    set emptyField $current_destination
    if {[$current_destination isa BatchLocal]} {
	set listOfEntryFields { executable }
    } {
	set listOfEntryFields { executable host username working image }
    } 
    foreach entryField $listOfEntryFields {
	if { [string length [$itk_component(${entryField}_e) query]] == 0 } {
	    set fieldColour orange
	} {
	    set fieldColour white
	} 
	lappend emptyField $fieldColour
	$itk_component(${entryField}_e) configure -textbackground $fieldColour
    }
    .bcd configure -title "Batch destinations"
    .c idle
    show
    hide

}

body BatchConfigDialog::updateColourEntries {} {
    set emptyField $current_destination
    if {[$current_destination isa BatchLocal]} {
	set listOfEntryFields { executable }
    } {
	set listOfEntryFields { executable host username working image }
    } 
    foreach entryField $listOfEntryFields {
	if { [string length [$itk_component(${entryField}_e) query]] == 0 } {
	    set fieldColour orange
	} {
	    set fieldColour white
	} 
	lappend emptyField $fieldColour
	$itk_component(${entryField}_e) configure -textbackground $fieldColour
    }
    return $emptyField
}

body BatchConfigDialog::updateExecutable { an_executable } {
    $current_destination setExecutable $an_executable
}

body BatchConfigDialog::updateHost { a_host } {
    $current_destination setHost $a_host
}

body BatchConfigDialog::getHost {} {
    return [$current_destination getHost]
}

body BatchConfigDialog::updateTotalCores { a_totalCores } {

	$current_destination setTotalCores $a_totalCores
}

body BatchConfigDialog::getRemoteLoginProtocol {} {
    set remoteShell "not set"
    set l_result [catch {set remoteShell [exec ssh -l ${username} ${host} "echo \$SHELL"]} l_error] 
# 
# remember that Tcl usually expects  1 = success, 0 = failure, 
#     but all UNIX shells expect     0 = success, 1 = failure
#
# some sshs/X11 give a hard error on finding the DISPLAY with anything but 
# "0" or "0.0", and kills this method - so force it to have 0.0.
    if {$::tcl_platform(os) == "Darwin"} {
	set ::env(DISPLAY) "[string trimright $::env(DISPLAY) 0123456789.]0.0"
    }
    if { [regexp "csh" $remoteShell] } {
#	puts "trying (t)csh"
	set remoteLoginProtocol "source .login"
	set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo `which $executable` >& /dev/null"} l_error]
	if { ! $l_result} {
#	    puts "Mosflm is OK from .login"
	} else {
#	    puts ".login failed, trying .cshrc"
	    set remoteLoginProtocol "source .cshrc"
	    set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo `which $executable` >& /dev/null"} l_error]
	    if {! $l_result} {
#		puts "Mosflm is OK from .cshrc"
	    } else {
		puts "Mosflm has not been set up on the remote machine from either .login or .cshrc.\n
Fix this problem before proceeding"
	    }
	}
    } elseif { [regexp "bash" $remoteShell] }  {
#	puts "trying bash"
	set remoteLoginProtocol ". .bash_profile"
	set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo `which $executable` >& /dev/null"} l_error]
	if { ! $l_result} {
#	    puts "Mosflm is OK from .bash_profile"
	} else {
#	    puts ".bash_profile failed, trying .profile"
	    set remoteLoginProtocol ". .profile"
	    set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo `which $executable` >& /dev/null"} l_error]
	    if { ! $l_result} {
#		puts "Mosflm is OK from .profile"
	    } else {
#		puts ".profile failed, trying .bashrc"
		set remoteLoginProtocol ". .bashrc"
		set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo `which $executable` >& /dev/null"} l_error]
		if { ! $l_result} {
#		    puts "Mosflm is OK from .bashrc"
		} else {
		    puts "Mosflm has not been set up on the remote machine from .bash_profile, \n.profile or .bashrc\n
Fix this problem before proceeding"
		}
	    }
	}
    } elseif { [regexp "zsh" $remoteShell] }  {
#	puts "trying zsh"
	set remoteLoginProtocol ". .zshrc"
	set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo `which $executable` >& /dev/null"} l_error]
	if { ! $l_result} {
#	    puts "Mosflm is OK from .zshrc"
	} else {
#	    puts ".zshrc failed, trying .profile"
	    set remoteLoginProtocol ". .profile"
	    set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo `which $executable` >& /dev/null"} l_error]
	    if { ! $l_result} {
#		puts "Mosflm is OK from .profile"
	    } else {
		    puts "Mosflm has not been set up on the remote machine from .zshrc, or .profile\n
Fix this problem before proceeding"
	    }
	}
    }
#    puts "remoteLoginProtocol is $remoteLoginProtocol"
    return $remoteLoginProtocol
}


body BatchConfigDialog::getCores  {} {
    if { [$current_destination isa BatchLocal] } {
	getLocalCores 
    } {
	getRemoteCores
    }
}

body BatchConfigDialog::getLocalCores  {} {
    exec echo exit | $::mosflm_executable XMLFILE junk.xml >& /dev/null
    set fp [open "junk.xml" r]
    set CoreCountXML [split [read $fp] "\n"]
    close $fp
    foreach line $CoreCountXML {
	set test_segment [string range $line 0 4]
	if {$test_segment == "<?xml"} {
	    set badLine [catch {dom parse $line} dom]
	    set doctype [[$dom documentElement] nodeName]
	}
    }
    file delete junk.xml
    if { $badLine == 0 } {
	$::session setMaxNumberOfCores $dom
    }
    set totalCores [string trimleft [$::session getMaxNumberOfCores]]
    $itk_component(cores_e) update $totalCores
    return $totalCores
}

body BatchConfigDialog::getRemoteCores  {} {
    set remoteLoginProtocol [getRemoteLoginProtocol]
    set ranOK [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol >& /dev/null; echo exit | $executable XMLFILE junk.xml >& /dev/null"} notOK]
    if { $notOK != "" } { puts $notOK }
    if { $ranOK == 1 } {
	set executable "Cannot run \"$executable\""
	$itk_component(executable_e) configure -textbackground red 
    } {
	$itk_component(executable_e) configure -textbackground white
    }
    catch [set CoreCountXML [split [exec ssh -l ${username} ${host} "cat junk.xml"] "\n"]]
    foreach line $CoreCountXML {
	set test_segment [string range $line 0 4]
	if {$test_segment == "<?xml"} {
	    set badLine [catch {dom parse $line} dom]
	    set doctype [[$dom documentElement] nodeName]
	}
    }
    file delete junk.xml
    if { $badLine == 0 } {
	$::session setMaxNumberOfCores $dom
    }
    set totalCores [string trimleft [$::session getMaxNumberOfCores]]
    $itk_component(cores_e) update $totalCores
    return $totalCores
}

body BatchConfigDialog::getRemoteShell  {} {
    return $remoteShell
}

body BatchConfigDialog::updateRemoteShell  { a_shell } {
    set remoteShell $a_shell
    return $remoteShell
}

body BatchConfigDialog::getTotalCores {} {
    return [$current_destination getTotalCores]
}

body BatchConfigDialog::getUsername {} {
    return [$current_destination getUsername]
}

body BatchConfigDialog::updateUsername { a_username } {
    $current_destination setUsername $a_username
}

body BatchConfigDialog::updateCommand { a_command } {
    $current_destination setCommand $a_command
}

body BatchConfigDialog::updateWorkingDirectory { a_directory } {
    $current_destination setWorkingDirectory $a_directory
}

body BatchConfigDialog::getWorkingDirectory { } {
    $current_destination getWorkingDirectory
}

body BatchConfigDialog::updateRemoteTempDirectory { a_directory } {
    $current_destination setRemoteTempDirectory $a_directory
}

body BatchConfigDialog::getRemoteTempDirectory { } {
    $current_destination getRemoteTempDirectory
}

body BatchConfigDialog::updateImageDirectory { a_directory } {
    $current_destination setImageDirectory $a_directory
}

body BatchConfigDialog::getImageDirectory { } {
    $current_destination getImageDirectory
}

body BatchConfigDialog::initialize { } {
    set l_local_found 0
    # Load existing destinations (created from profile)
    foreach i_destination [BatchDestination::getDestinations] {
	addDestination $i_destination 0
	# Keep watch for a local destination
	if {[$i_destination info class] == "::BatchLocal"} {
	    set l_local_found 1
	}

    }
    # If there was no local destination, create one
    if {!$l_local_found} {
	if {[catch {set l_host_name $::env(HOSTNAME)}]} {
	    set l_host_name "localhost"
	}
	set l_destination [namespace current]::[BatchLocal \#auto "$l_host_name"]
	addDestination $l_destination 0
    }
    # update batch submission dialog
    foreach i_destination [BatchDestination::getDestinations] {
	if { ! [catch {exec ping -c 1 -t 1 [$i_destination getName] } ] } {
	    .bsd updateDestinations
	} { 
	    BatchDestination::deleteDestination $i_destination
	}
    }
}
usual BatchConfigDialog { }

# Submission methods ################################

# Generic base class

class BatchDestination {

    # I forget get the collective name for these
    public variable l_xmlfile ""
    public variable r_xmlfile ""
    private common destinationsByName ; # array
    public proc getDestinations
    public proc deleteDestination
    public proc getDestinationNames
    public proc getDestinationByName
    public proc saveProfile

    # variables
    protected variable name ""
    protected variable icon
    protected variable totalCores ""
    protected variable executable "mosflm"
    protected variable workingDirectory ""
    protected variable imageDirectory ""
    private variable listOfXMLFiles {}
    private variable listOfMTZFiles {}

    # methods
    public method getName { } { return $name } 
    public method rename
    public method getIcon { } { return $icon }

    public method getTotalCores { } { return $totalCores }
    public method setTotalCores { a_totalCores } {
	if { $a_totalCores == "" } {
	    set totalCores 1
	} {
	    set totalCores $a_totalCores
	}
        saveProfile
    }
    public method getExecutable { } {
	if {$executable == ""} {
	    set executable $::env(MOSFLM_EXEC)
	}
	return $executable
    }
    public method setExecutable { a_executable } {
	if {![file exists $a_executable] && $a_executable != ""} {
	    puts "Executable path stored in profile file:\n$a_executable\ndoes not exist so resetting to:\n$::env(MOSFLM_EXEC)"
	    set executable $::env(MOSFLM_EXEC)
	} else {
	    set executable $a_executable   
	}
        saveProfile
    }
    public method getWorkingDirectory { } { 
	return $workingDirectory 
    }

    public method setWorkingDirectory { a_directory } {
	set workingDirectory $a_directory
        saveProfile
    }

    public method getImageDirectory { } { 
	return $imageDirectory 
    }

    public method setImageDirectory { a_directory } {
	set imageDirectory $a_directory
        saveProfile
    }

    public method getRemoteTempDirectory { } { return $remoteTempDirectory }
    public method setRemoteTempDirectory { a_directory } {
	set remoteTempDirectory $a_directory
        saveProfile
    }


    public method execute { args } { error "Virtual method called!" }

    protected method createScript { a_script a_host } { }

    constructor { a_name } { }

    destructor {
	array unset destinationsByName $name
    }
}

# procs

body BatchDestination::getDestinations { } {
    set l_destinations {}
    foreach { i_name i_destination } [array get destinationsByName] {
	lappend l_destinations $i_destination
    }
    return $l_destinations
}

body BatchDestination::deleteDestination { a_destination } {
    set index [lsearch [array get destinationsByName] $a_destination]
    array unset destinationsByName $a_destination
    array unset destinationsByName [$a_destination getName]
}

body BatchDestination::getDestinationNames { } {
    return [array names destinationsByName]
}

body BatchDestination::getDestinationByName { a_name } {
    if {[info exists destinationsByName($a_name)]} {
	return $destinationsByName($a_name)
    } else {
	return ""
    }
}

body BatchDestination::saveProfile { } {
    .c saveProfile
}

# methods

body BatchDestination::constructor { a_name } {
    set name $a_name
    set destinationsByName($name) $this
    saveProfile
}

body BatchDestination::rename { a_name } {
    set l_existing_destination [getDestinationByName $a_name]
    if {$l_existing_destination == ""} {
	array unset destinationsByName $name
	set name $a_name
	set destinationsByName($name) $this
	# success
	saveProfile
	return 1
    } else {
	# failure
	return 0
    }
}   

body BatchDestination::createScript { a_script a_host } {
    if { $a_host == "" } {
	set a_host "localhost"
    }
    set current_destination [getDestinationByName $a_host]
    return
    # Generate and open timestamped file in .mosflm directory
    set l_timestamp [.bsd updateTimeStamp]
    set l_filename "mosflm_batch_${l_timestamp}.bat"
    set l_file [open $l_filename w]

    # Generate a name for the log file
    set l_logfile [file join [getWorkingDirectory] "mosflm_batch_${l_timestamp}.log"]
    # Generate a name for the XML file
    set l_xmlfile "mosflm_batch_${l_timestamp}.xml"
    set r_xmlfile [file join [getWorkingDirectory] $l_xmlfile]
    set listOfXMLFiles $l_xmlfile
    $::session clearListOfXMLFiles
    $::session appendToListOfXMLFiles $l_xmlfile
    # Generate a name for the SUMMARY file
    set l_sumfile [file join [getWorkingDirectory] "mosflm_batch_${l_timestamp}.sum"]

	#Generate a name for the SPOTOD file
    set l_spotodfile [file join [getRemoteTempDirectory] "mosflm_batch_${l_timestamp}.spotod"]
	
	#Generate a name for the COORDS file
    set l_coordsfile [file join [getRemoteTempDirectory] "mosflm_batch_${l_timestamp}.coords"]

    set executable [$current_destination getExecutable]

    # Write sh script to launch mosflm
    puts $l_file "#!/bin/sh"
    puts $l_file "cd [getWorkingDirectory]"
    puts $l_file "$executable XMLFILE $r_xmlfile SUMMARY $l_sumfile SPOTOD $l_spotodfile COORDS $l_coordsfile <<EOF >& $l_logfile"
    puts $l_file "GENFILE [file join [getWorkingDirectory] "mosflm_batch_${l_timestamp}.gen"]"
    puts $l_file "NEWMAT [file join [getWorkingDirectory] "mosflm_batch_${l_timestamp}.mat"]"
    foreach i_line [split $a_script "\n"] {
    if {[regexp "directory" $i_line]} {
	    set i_line "directory [getImageDirectory]"
	}
	puts $l_file $i_line
    }
    puts $l_file "EOF"
    puts $l_file "date >> $l_logfile"
    puts $l_file "echo \"Batch complete\" >> $l_logfile"
#	puts $l_file "rm $l_coordsfile"
    close $l_file

    # Make batch file executable
    exec chmod u+x $l_filename
    return $l_filename
}

# Remote batch destination class

class BatchRemote {
    inherit BatchDestination

    private variable host ""
    private variable remoteTempDirectory ""
    protected variable username ""
    public method setHost { a_host } { set host $a_host ; saveProfile }

    public method setTotalCores { a_totalCores } {
	if { $a_totalCores == "" } {
	    set totalCores 1
	} {
	    set totalCores $a_totalCores
	}
        saveProfile
    }
    public method setUsername { a_username } { set username $a_username; saveProfile }
    public method setRemoteTempDirectory { a_directory } { set remoteTempDirectory $a_directory ; saveProfile }

    public method getHost { } { return  $host }
    public method getUsername { } { return $username }
    public method getRemoteTempDirectory { } { return $remoteTempDirectory }

    public method execute
    public method execute2

    public method serialize

    constructor { a_name } {
	BatchDestination::constructor $a_name 
    } {
	set icon ::img::remote16x16
    }
}

body BatchRemote::execute { a_script } {
# hrp 26.06.2013 - this method isn't used 
# what is remote shell?

    catch [set remoteShell [exec ssh -l ${username} ${host} "echo \$SHELL"]]
    BatchConfigDialog::updateRemoteShell $remoteShell
# where is remote .mosflm directory ($HOME/.mosflm)
    catch [set remoteTempDirectory [file join [exec ssh -l ${username} ${host} "echo \$HOME"] ".mosflm"]]
    setRemoteTempDirectory $remoteTempDirectory
# how many cores on remote machine?
    set remoteLoginProtocol [.bcd getRemoteLoginProtocol]
    
    set l_result [catch {exec ssh -l ${username} ${host} "$remoteLoginProtocol > /dev/null; echo exit | $executable XMLFILE junk.xml >& /dev/null; scp junk.xml ."} l_error]
    if { $l_result != "" } { puts $l_result }

    set in_file [ ::open "junk.xml" r ]
    while { [gets $in_file line]  >=0 } {
	set test_segment [string range $line 0 4]
	if {$test_segment == "<?xml"} {
	    set badLine [catch {dom parse $line} dom]
	    set doctype [[$dom documentElement] nodeName]
	}
    }
    file delete junk.xml
    if { $badLine == 0 } {
	$::session setMaxNumberOfCores $dom
    }

    set remoteScript [createScript $a_script $host]
    exec scp $remoteScript ${host}:[getWorkingDirectory]
    catch [exec ssh -l ${username} ${host} "source .login >& /dev/null; cd [getWorkingDirectory] ; chmod +x $remoteScript; $remoteScript"]

#    set l_result [catch {exec ssh -l ${username} ${host} $remoteScript &} l_error]
#    if {$l_result} {
#	.m confirm \
#	    -type "1button" \
#	    -button1of1 "Dismiss" \
#	    -title "Error" \
#	    -text "Could not run batch job on ${host}:\n\n$l_error\n\nSorry!"
#
#    } else {
#	puts "sending the script to ${host} failed"
#    }
    
    exec scp ${host}:$r_xmlfile $l_xmlfile
}

body BatchRemote::serialize { } {

    set xml "<batch_destination type=\"remote\" name=\"$name\" executable=\"$executable\" host=\"$host\" totalCores=\"[string trimleft $totalCores]\" username=\"$username\" workingDirectory=\"$workingDirectory\" imageDirectory=\"$imageDirectory\" protocol=\"\"/>"
}

# local batch destination class

class BatchLocal {
    inherit BatchDestination

    public method execute
    public method serialize

    constructor { a_name } {
	BatchDestination::constructor $a_name 
    } {
	set icon ::img::local16x16
	set executable $::mosflm_executable
    }
}

body BatchLocal::execute { a_script } {
    # Run batch script
    if {[catch {exec [createScript $a_script] &} l_error]} {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Error" \
	    -text "Could not run local batch job:\n\n$l_error\n\nSorry!"
    }
}

body BatchLocal::serialize { } {
    if { $totalCores == "" || $totalCores < 1 } {
	set totalCores [.bcd getLocalCores]
    }
    set xml "<batch_destination type=\"local\" name=\"$name\" executable=\"$executable\" totalCores=\"[string trimleft $totalCores]\" workingDirectory=\"$workingDirectory\" imageDirectory=\"$imageDirectory\"/>"
}

class BatchFarm {
    inherit BatchDestination

    private variable command ""

    public method getCommand { } { return $command }
    public method setCommand { a_command } { set command $a_command ; saveProfile }

    public method execute

    public method serialize

    constructor { a_name } {
	BatchDestination::constructor $a_name
    } {
	set icon ::img::farm16x16
    }
}

body BatchFarm::execute { a_script } {
    if {[catch {eval exec $command [createScript $a_script] &} l_error]} {
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Error" \
	    -text "Could not submit batch job to farm:\n\n$l_error\n\nSorry!"
    }
}

body BatchFarm::serialize { } {
    set xml "<batch_destination type=\"farm\" name=\"$name\" executable=\"$executable\" command=\"$command\" protocol=\"\"/>"
}
