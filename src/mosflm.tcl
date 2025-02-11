package provide mosflm 3.0
if {$::debugging} {
    puts "flow: entering mosflm.tcl"
}

class Mosflm {

    # Common variables #########################################

    # array to store variables used to check for mosflm readiness
    public common ready  
    
    # Procedures ###############################################

    public proc startMosflm
    public proc closeMosflm
    public proc restartMosflm

    # Member variables #########################################
    # server socket for mosflm core to connect to
    private variable server
    # socket for mosflm to communicate through
    private variable socket
    # port number for communications with mosflm
    private variable port
    # pid number of mosflm process
    private variable pid
    # log file
    private variable logging 0
    private variable logfile
    private variable datestamp ""
    # variable to keep track of who wants to know about mosaicity
    private variable mosaicity_requestor ""
    # variable to keep track of who is expecting processing feedback
    private variable processor ""
    # variables to keep track of when performing integration task
    private variable processing_flag "0"
    # variable to keep trackof when mosflm is "busy"
    private variable job_queue {}
    private variable job_descriptions {}
    private variable prediction_queued "0"
	
    private variable l_spotodfile ""
    private variable l_coordsfile ""
    private variable l_matfile ""
    private variable l_genfile ""
    private variable smooth_level "1"
    private variable bad_xml_from_mosflm ""
    private variable save_sum_n_images "1"

    # Methods ##################################################

    # method to shutdown current mosflm process
    public method shutdown
    # method to handle Mosflm's connection to the socket
    public method acceptSocketConnection

    # public method to send individual commands to the core
    public method sendCommand
    # only used for debugging - sends a sendCommand and a puts of the
    # same string
    public method mirrorCommand
    # method to handle messages from Mosflm
    public method processMessage

    # job queue methods
    private method addJob
    public method removeJob
    public method getFirstJob
    public method busy

    public method getSmoothLevel
    public method setSmoothLevel
    # method to fetch an image from the core
    public method getImage
    # method to fetch an image during processing
    public method getCurrentImage
    # method to get prediction during processing
    public method getCurrentPredictions
    # method to fetch experiment-invariant information pertaining to an image
    public method getExperimentData
    # method to read image's phi values
    public method getPhi
    # method to send masks
    private method sendMasks
    # method to send a findspots command to the core
    public method findspots
    # method to send an autoindex command to the core
    public method index
    public method index2
    public method index3
    # method for estimating mosaicity
    public method estimateMosaicity
    # method to get spot predictions from Mosflm
    public method getPredictions
    private method reallyGetPredictions
    public method getImageParameterValue
    # pick
    public method pick
    # strategy method
    public method calcStrategy
    # method to prompt processing to continue or abort
    public method promptProcessing
    # method to get suggested segments for cell refinement
    public method getCellRefinementSegments
    #method to calculate processing run start and ends from an image list
    public method makeProcessingPairLists
    public method getProcessingRuns
    # method to send an cell refinement command to the core
    public method refineCell
    # method to send a pattern matching cell refinement command to the core
    public method pm_refineCell
    # method to send an integrate command to the core
    public method integrate
    # method to send a pattern matching integrate command to the core
    public method pm_integrate
    # method to fit circle
    public method fitCircle
    # method called if mosflm cannot communicate with imosflm socket
    # when launched
    public method socketNotReachable

    public method fileErrorLog

    public method runningTestgen
    public method finishedTestgen

    public method getDateStamp
    public method getNewTimeStamp

    public method updateSessionForNewChunk

    public method hack { } {  }

    constructor { args } { }

}

proc mos { args } {
    $::mosflm sendCommand "$args"
}

# Contructor ########################################################
#####################################################################

body Mosflm::constructor { args } {

    # create server socket for mosflm to connect to, with:
    #  method acceptSocketConnection to handle connections, and
    #  dynamically assigned port (as directed by using 0 as port)
    # record the dynamically allocated port number
    # added by luke 4 December 2007: Inserted the if catch statement when opening a 
    # server socket in case the lo interface is down
    if {[catch {set server [socket -server [code $this acceptSocketConnection] -myaddr 127.0.0.1  0]} socketerrormsg ]} {
	puts $socketerrormsg
	exit
    }

    set port [lindex [fconfigure $server -sockname] 2]
    # launch mosflm
    set t_debug 0
    if {[info exists ::DEBUG_MOSFLM]} {
	if {$::DEBUG_MOSFLM == 1} {
	    set t_debug 1
	}
    }
    if {$t_debug} {
	set pid [exec xterm -eb gdb $::mosflm_executable &]
    } else {
	set canonicalpathname [file join $::mosflm_executable]
	set $::mosflm_executable $canonicalpathname

	set datestamp "[clock format [clock seconds] -format "%Y%m%d_%H%M%S"]"
	set l_sumfile [file join [pwd] "mosflm_${datestamp}.sum"]
    
	#Generate a name for the SPOTOD file
	set l_spotodfile [file join $::mosflm_directory "mosflm_${datestamp}.spotod"]
	    
	#Generate a name for the COORDS file
	set l_coordsfile [file join [pwd] "mosflm_${datestamp}.coords"]
    
	if { ![regexp -nocase windows $::tcl_platform(os)] } {
	    # not Windows
	    cd $::env(MOSDIR)
	    set ::mosflm_pipe [open "|\"$::mosflm_executable\" SUMMARY $l_sumfile SPOTOD $l_spotodfile COORDS $l_coordsfile  MOSFLMSOCKET $port"]
	} else {
	    # Windows
	    cd $::env(MOSDIR)
	    if {[file exists mosflm.lp]} {   
		#puts "LP file exists and is being renamed"
		if {[catch {file rename mosflm.lp mosflm_${datestamp}.lp} catchmessage]} {}
#		$::session addCCP4i2file "mosflm_logfile" "mosflm_${datestamp}.lp"
	    }
	    if { [file exists SUMMARY]} {
		#puts "SUMMARY exists and is being renamed"
		if {[catch {file rename SUMMARY mosflm_${datestamp}.sum} catchmessage]} {}
	    }
	
	    set ::mosflm_pipe [open "|\"$::mosflm_executable\" MOSFLMSOCKET $port"]
	}
	fconfigure $::mosflm_pipe -buffering line -blocking 0
	fileevent $::mosflm_pipe readable "[.c component history] monitor"
	after 1000 [code $this socketNotReachable]
	#puts  "$::mosflm_executable MOSFLMSOCKET $port"
    }

    if {[info exists ::env(MOSFLM_LOGGING)]} {
	if {$::env(MOSFLM_LOGGING) == 1} {
	    set logging 1
	    set logfile "logfile${datestamp}.debug"
	    set logfile_handle [open $logfile w]
	    puts $logfile_handle "Tcl platform is $::tcl_platform(platform) $::tcl_platform(machine) $::tcl_platform(os) \
		$::tcl_platform(osVersion)"
	    puts $logfile_handle "TclTk version from info patchlevel is [info patchlevel]"
	    close $logfile_handle
	    puts "full debugging turned on - a log of your session will be stored in a"
	    puts "datestamped file logfile$datestamp.debug"
	}
    }
}

# Socket acceptance method ##########################################
#####################################################################

body Mosflm::acceptSocketConnection { a_sock an_addr a_port } {
    # close the server socket
    close $server
    set server ""
    # record the name of the sock created
    set socket $a_sock
    # configure the newly created socket
    fconfigure $socket -buffering line -translation lf -blocking 0 -buffersize 72000
#   fconfigure $socket -buffering none -blocking true 
 
   # appoint method to handle incoming methods
    fileevent $socket "readable" [code $this processMessage]

    # set 'ready' variable, to trigger 'tkwait's waiting on that variable
    set ready 1

    set l_genfile "mosflm_${datestamp}.gen"
    sendCommand "GENFILE $l_genfile"
    set l_matfile "mosflm_${datestamp}.mat"
    sendCommand "NEWMAT $l_matfile"

}

# Shutdown method ###################################################
#####################################################################

body Mosflm::shutdown { } {

    # Unbind fileevent on socket
    fileevent $socket "readable" {}
    
    # Unbind fileevent on pipe
    fileevent $::mosflm_pipe "readable" {}

    # send a shutdown command to mosflm
    sendCommand "exit"

    # close the socket
    close $socket

    if { ![regexp -nocase windows $::tcl_platform(os)] } {
	if {[file exists $l_coordsfile]} {
	    file delete $l_coordsfile
	    #puts "deleted $l_coordsfile"
	}
	if {[file exists $l_matfile]} {
# hrp 13072015 why delete this? I use it a lot!	    file delete $l_matfile
	    foreach n { 1 2 3 4 5 6 7 8 9 * } {
		catch { file delete ${l_matfile}_lattice_${n}_raw.mat }
		# Delete any previous spotlists and matrices from multiple lattice indexing
		catch {file delete good_list_$n.spt}
		catch {file delete bad_list_$n.spt}
	    }
	    #puts "Was trying to delete ${::mosflm_directory}/$l_matfile"
	}
	if {[file exists $l_genfile]} {
	    file delete $l_genfile
	    #puts "Was trying to delete ${::mosflm_directory}/$l_genfile"
	}
    }

}

# Send command method ###############################################
#####################################################################

body Mosflm::sendCommand { a_command } {
    if {$logging} {
	# open the logfile

	set logfile_handle [open $logfile a]
	# log the command being sent to Mosflm
	puts $logfile_handle $a_command
	# close the logfile
	close $logfile_handle
    }
    # send the command to mosflm
    if {[catch {puts $socket $a_command}]} {
	error "Error sending command \"${a_command}\" to mosflm"
    } else {
	#puts "iMosflm successfully sent command $a_command"
	# Test busy state if command was Abort
	if { $a_command == "abort" } {
	    if {[busy]} {}
	}	
    }
}

body Mosflm::mirrorCommand { a_command } {
# mirrors command to launch window and to Mosflm - remember you may need
# to put the command in a Mosflm-type comment so it doesn't raise an error
    puts "$a_command"
    sendCommand "$a_command"
}

# job queue methods #################################################

body Mosflm::addJob { a_job { a_description "" } } {
    if {$::debugging} {
        puts "flow: enter addJob for $a_job $a_description"
    } 
    # If not already busy...
    if {![busy]} {
	# ...disable controls that require mosflm calls
	#.c disable
    }
    # Add job and description to lists
    lappend job_queue $a_job
    #puts [llength job_queue]
    lappend job_descriptions $a_description
    if {$::debugging} {
        puts "flow:   addJob: got $a_job, queue: $job_queue"
        puts "flow: status will be set to: [lindex $job_descriptions 0]"
    }
    # update status indicator to head of job queue
    .c busy [lindex $job_descriptions 0]
}

body Mosflm::getFirstJob { } {
    if { $job_queue == "" } { return "" }
    return [lindex $job_queue 0]
}

body Mosflm::removeJob { a_job } {
    if {$::debugging} {
        puts "flow: entering Mosflm::removeJob for $a_job, prediction_queued is $prediction_queued"
    }
    set l_head [lindex $job_queue 0]
    set l_tail [lrange $job_queue 1 end]
    if {$l_head != $a_job} {
	#puts "UNmoveJob: got $a_job, queue: $job_queue"
    } else {
	set job_queue $l_tail
	set job_descriptions [lrange $job_descriptions 1 end]
	#puts "rJb: removing: $l_head, queue is now: $job_queue"
	# update status indicator to head of job queue
	if {[busy]} {
	    .c busy [lindex $job_descriptions 0]
	} elseif {$prediction_queued && [$::session predictionPossible]} {
	    # Dont request predictions if processing the prediction job itself
	    #puts "rJb: not busy, predictions queued+possible, headofqueue $l_head"
	    set prediction_queued 0
	    reallyGetPredictions
	} else {
	    # Re-enable controls requiring mosflm calls
	    #.c enable
	    .c idle
	}
    }	
}

body Mosflm::busy { args } {
    #puts "Searching mosflm job queue for: $args ($job_queue)"
    if {[llength $args] == 0} {
	set lqueue [llength $job_queue]
	set job [lindex $job_queue 0]
	set result [expr [llength $job_queue] > 0]
	if { $result > 0 } {
            if {$::debugging} {
	        puts "flow: Busy - job queue: $job_queue"
            }
	}
    } else {
	set result 0
	foreach i_job_type $args {
	    if {[lsearch $job_queue $i_job_type] > -1} {
		set result 1
		break
	    }
	}
    }
    return $result
}

body Mosflm::getSmoothLevel { } {
    return $smooth_level
}

body Mosflm::setSmoothLevel { } {
    set smooth_level 1
    set model [$::session getParameterValue detector_model]
    set manufacturer [$::session getParameterValue detector_manufacturer]
    set modl [string toupper [string range $model 0 0]]
    set manu [string toupper [string range $manufacturer 0 3]]
    if { $manu == "PILA" && ![.image isZoomed] } {
	if { $modl == "6" } {
	    set smooth_level 5
	} elseif { $modl == "2" } {
	    set smooth_level 3
	} elseif { $modl == "3" } {
	    set smooth_level 1
	} else {
	    set smooth_level 1
	}
    }
# hrp only smooth for Eiger 4M at the moment - 05.05.2015
    if { $manu == "EIGE" && ![.image isZoomed] } {
	if { $modl == "4" } {
	    set smooth_level 5
	} else {
	    set smooth_level 1
	}
    }
# hrp only one ADSC PAD at the moment - 05.05.2015
    if { $manu == "APAD" } {
	if { ![.image isZoomed] } {
	    set smooth_level 5
	} else {
	    set smooth_level 1
	}
    }
    #puts "$manufacturer $model smooth_level $smooth_level"
    return $smooth_level
}

# Public methods for sending messages to Mosflm ####################
####################################################################

# getImage #########################################################

body Mosflm::getImage { an_image { a_min_contrast 0 } { a_max_contrast 0 } { nimagesum 0 } { summation "Addition" } { forceread 0 } } {
    addJob "image" "Opening image [$an_image getShortName]"

    #puts "debug: ***** Called Mosflm::getImage ****** "
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }

    sendCommand "directory [$an_image getDirectory]"
    sendCommand "template [$an_image getTemplateForMosflm]"

# this is a fudge
    if { [$an_image getNumber] == "0" || [$an_image getNumber] == "" } {
       $an_image setNumber 1
    }
    updateSessionForNewChunk
    sendCommand "image [$an_image getNumber]"
    if { $forceread } {
    sendCommand "forceread"
    }
    sendCommand "xgui on"
    sendCommand "go"

    # Only permit image summation for Pilatus, Eiger, Rigaku Pilatus and Eiger, ADSC PAD images and TIMEpix
    set manu [string toupper [string range [$::session getParameterValue detector_manufacturer] 0 3]]
    set modl [string toupper [string range [$::session getParameterValue detector_model] 0 0]]
    if { ($manu == "PILA" || $manu == "APAD" || $manu == "EIGE"  || $manu == "HDF5" || $manu == "RIPI" || $manu == "RIEI" || $manu == "TIME" ) && ($nimagesum > 1) } {
	# We are summing images from the current one up to nimagesum images in total
	sendCommand "create_grey_image type jpg $a_min_contrast $a_max_contrast smooth [setSmoothLevel] sum $nimagesum [string tolower [string range $summation 0 2]] reverse_video [.image isReverseVideo]"

    } else {

	sendCommand "create_grey_image type jpg $a_min_contrast $a_max_contrast smooth [setSmoothLevel] reverse_video [.image isReverseVideo]"
    }
    sendCommand "return"
    set ::timer001 [clock clicks -milli]
}

body Mosflm::getCurrentImage { { a_min_contrast 0 } { a_max_contrast 0 } } {
    sendCommand "create_grey_image type jpg $a_min_contrast $a_max_contrast smooth [setSmoothLevel] reverse_video [.image isReverseVideo]"
    set ::timer001 [clock clicks -milli]
}

body Mosflm::getCurrentPredictions { } {
    #puts "In getCurrentPredictions sending predict_spots"
    sendCommand "predict_spots"
}
# getExperimentData ###############################################

body Mosflm::getExperimentData { an_image } {
    $::session getParameterValue sum_n_images_changed
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$an_image getDirectory]"
    sendCommand "template [$an_image getTemplateForMosflm]"
     if { [$an_image getNumber] == "0"  || [$an_image getNumber] == "" } {
       $an_image setNumber 1
     }
    updateSessionForNewChunk
    sendCommand "image [$an_image getNumber]"
    # Add a pixel command here in case it is not in image header and has been
    # read from the site file. Need to send this to ipmosflm so that 
    # LIMIT = <central_size_region> is correctly calculated
    if { [$::session getParameterValue "pixel_size"] != "" } {
       sendCommand "pixel [$::session getParameterValue "pixel_size"]"
    }
    sendCommand "head"
    sendCommand "go"
    eval set ::timeri[$an_image getNumber] [clock clicks -milliseconds]
    set ::timer08 [clock clicks -milliseconds]
    $::session getParameterValue sum_n_images_changed
}

# getExperimentData ###############################################

body Mosflm::getPhi { an_image } {
#    puts " crucial: in Mosflm::getPhi, an_image is $an_image"
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$an_image getDirectory]"
#    puts "crucial: in Mosflm::getPhi, template is [$an_image getTemplateForMosflm]"
    sendCommand "template [$an_image getTemplateForMosflm]"
    updateSessionForNewChunk
#    puts "crucial: in Mosflm::getPhi, image number is [$an_image getNumber]"
    sendCommand "image [$an_image getNumber]"
    sendCommand "head brief"
    sendCommand "go"
    #eval set ::timeri[$an_image getNumber] [clock clicks -milliseconds]
}

# sendMasks ########################################################

body Mosflm::sendMasks { } {
    sendCommand "limits remove all"
    foreach i_mask [Mask::getMasks] {
	set l_coords [$i_mask getMmCoords]
	if {[llength $l_coords] == 8} {
	    sendCommand "limits quadrilateral $l_coords"
	}
    }
}

# findspots ########################################################

body Mosflm::findspots { an_image } {
    if {$::debugging} {
        puts "flow: Enter Mosflm::findspots" 
    }
    addJob "spot_finding" "Finding spots on image [$an_image getShortName]"
    
    # File details
    
    set l_detector [$::session getFullDetectorInformation]

    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$an_image getDirectory]"
    sendCommand "template [$an_image getTemplateForMosflm]"
    updateSessionForNewChunk

    # Masking
    sendMasks

    # Beam details
    if {![$::session getTwoTheta]} {
	sendCommand "beam [$::session getBeamPosition]"
    } else {
	sendCommand "beam swungout [$::session getBeamPosition]"
    }    

    # Detector parameters
    sendCommand "pixel [$::session getParameterValue "pixel_size"]"
    # Gain
    sendCommand "gain [$::session getParameterValue "gain"]"
    # ADCOFFSET
    if {[$::session getParameterValue "adcoffset"] != ""} {
	    sendCommand "ADCOFFSET [$::session getParameterValue "adcoffset"]"
    }
    # Distance
    sendCommand "distance [$::session getDistance]"

    # Nullpix
    sendCommand "nullpix [$::session getParameterValue nullpix]"

    # Apply separation limits
    if {[$::session separationCommandRequired]} {
	sendCommand "[$::session getSeparationCommand]"
    }

    # Spot finding settings
    sendCommand "findspots [$::session getFindspotsParameters]"
    
    # Spot finding command
    sendCommand "findspots find [$an_image getNumber] phi [$an_image getPhi] file \"[$an_image makeAuxiliaryFileName "spt" $::mosflm_directory]\""
    sendCommand "go"
 
}

# index ############################################################

body Mosflm::index { token_image spotfilename {solution "0"} } {

    if { $token_image == 0 } { return }
    if {$::debugging} {
        puts "flow: Entering Mosflm::index to send indexing commands to mosflm"
    }
# Set all stored image parameters (those resulting from images that have been
# integrated or used in cell refinement) to null as they are no longer
# relevent if a new indexing is carried out.
# AGWL 18/9/18
    set l_images [[$::session getCurrentSector] getImages]
    if {[llength $l_images] > 0} {
      # if there are any images to use...
      foreach i_image $l_images {
        $i_image setValue beam_x ""
        $i_image setValue beam_y ""
        $i_image setValue distance ""
        $i_image setValue yscale ""
        $i_image setValue tilt ""
        $i_image setValue twist ""
        $i_image updateMissets 0 0 0   0  1  0 
      }
    }
    addJob "indexing" "Autoindexing"

    # File details
    
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$token_image getDirectory]"
    sendCommand "template [$token_image getTemplateForMosflm]"
    updateSessionForNewChunk

    # Masking
    sendMasks

    # Beam details
    if {![$::session getTwoTheta]} {
	sendCommand "beam [$::session getBeamPosition]"
        # puts "debug: from Mosflm::index beam coords [$::session getBeamPosition]"
    } else {
	sendCommand "beam swungout [$::session getBeamPosition]"
    }

    # radial & tangential offsets
    if {([$::session getRadialOffset] != 0) || ([$::session getTangentialOffset] != 0)} {
	sendCommand "DISTORTION ROFF [$::session getRadialOffset] TOFF [$::session getTangentialOffset]"
    }

    # distance
    #puts "setting distance from $::session getDistance"
    sendCommand "distance [$::session getDistance]"

    # wavelength
    sendCommand "wavelength [$::session getWavelength]"

    # two theta
    sendCommand "twotheta [$::session getTwoTheta]"
    
    # pixel size
    sendCommand "pixel [$::session getParameterValue "pixel_size"]"

    # send target cell and spacegroup if required:
    if {[[$::session getSpacegroup] reportSpacegroup] != "Unknown"} {
	sendCommand "symmetry [[$::session getSpacegroup] reportSpacegroup]"
    }
    if {[[$::session getCell] reportCell] != "Unknown"} {
	if {[$::session getParameterValue "fix_cell_indexing"]} {
	    sendCommand "cell keep [[$::session getCell] listCell]"
	} else {
	    sendCommand "cell [[$::session getCell] listCell]"
	}
    }	

    set prior_cell [string trim [[.c component indexing] getPriorCell]]

    # Autoindexing
    if { $prior_cell == ""} {
	sendCommand "autoindex [$::session getIndexSubcommands] solution $solution image [$token_image getNumber] file \"$spotfilename\""
    } else {
	sendCommand "cell $prior_cell"
	sendCommand "autoindex [$::session getIndexSubcommands] solution $solution image [$token_image getNumber] file \"$spotfilename\" takanori"
    }

    set responses [sendCommand "go"]
    if { $responses != "" } {
	#puts "responses index: $responses"
    }
    return $responses
}

body Mosflm::index2 { a_solution a_sigma_cutoff {lattice 1} } {
    if {$::debugging} {
        puts "flow: Entering Mosflm::index2"
    }

    addJob "index_refinement" "Refining solution number $a_solution lattice $lattice"

    set unfixdist ""
    # Check if crystal to detector distance has been unfixed
    if {![$::session getFixedDistance]} {
	set unfixdist "unfixdist"
    }
    sendCommand "autoindex dps solution $a_solution sdcutoff $a_sigma_cutoff $unfixdist lattice $lattice"
    set responses [sendCommand "go"]
    if { $responses != "" } {
	#puts "responses index2: $responses"
    }
    return $responses
}

body Mosflm::index3  { a_beam_x a_beam_y token_image spotfilename {solution "0"} } {
    addJob "indexing" "Autoindexing"
    if {$::debugging} {
        puts "flow: Entering Mosflm::index3"
    }
    # File details
    
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$token_image getDirectory]"
    sendCommand "template [$token_image getTemplateForMosflm]"
    updateSessionForNewChunk

    # Masking
    sendMasks

    # Beam details
    # used for beam-centre search, so don't use stored beam centre from Mosflm     
    if {![$::session getTwoTheta]} {
	sendCommand "beam $a_beam_x $a_beam_y"
    } else {
	sendCommand "beam swungout $a_beam_x $a_beam_y"
    }
    
    # radial & tangential offsets
    if {([$::session getRadialOffset] != 0) || ([$::session getTangentialOffset] != 0)} {
	sendCommand "DISTORTION ROFF [$::session getRadialOffset] TOFF [$::session getTangentialOffset]"
    }

    # distance
    sendCommand "distance [$::session getDistance]"

    # wavelength
    sendCommand "wavelength [$::session getWavelength]"

    # two theta
    sendCommand "twotheta [$::session getTwoTheta]"
    
    # pixel size
    sendCommand "pixel [$::session getParameterValue "pixel_size"]"

    # send target cell and spacegroup if required:
    if {[[$::session getSpacegroup] reportSpacegroup] != "Unknown"} {
	sendCommand "symmetry [[$::session getSpacegroup] reportSpacegroup]"
    }
    if {[[$::session getCell] reportCell] != "Unknown"} {
	if {[$::session getParameterValue "fix_cell_indexing"]} {
	    sendCommand "cell keep [[$::session getCell] listCell]"
	} else {
	    sendCommand "cell [[$::session getCell] listCell]"
	}
    }	

    # Autoindexing
    sendCommand "autoindex [$::session getIndexSubcommands] solution $solution image [$token_image getNumber] file \"$spotfilename\""
	
    sendCommand "go"

}

# estimateMosaicity ################################################

body Mosflm::estimateMosaicity { a_image } {
    
    addJob "mosaicity" "Estimating mosaicity"

    # See if it has a valid matrix
    set l_sector [$a_image getSector]
    set l_matrix [$l_sector getMatrix]
    if {![$l_matrix isValid]} {
	.m configure \
	    -type "1button" \
	    -button1of1 "Ok" \
	    -title "Error estimating mosaicity" \
	    -text "Cannot estimate mosaicity using image [$a_image getShortName]\nas it does not have a valid matrix. Sorry."
	.m confirm
	removeJob "mosaicity"
	return
    } else {
    
	set l_detector [$::session getFullDetectorInformation]
	if { $l_detector != "" } {
	    sendCommand "$l_detector"
	}
	sendCommand "directory [$a_image getDirectory]"
	sendCommand "template [$a_image getTemplateForMosflm]"
	updateSessionForNewChunk

	# Masking
	sendMasks

	# Beam details
	if {![$::session getTwoTheta]} {
	    sendCommand "beam [$::session getBeamPosition]"
	} else {
	    sendCommand "beam swungout [$::session getBeamPosition]"
	}
	sendCommand "distance [$::session getDistance]"
	sendCommand "wavelength [$::session getWavelength]"
	sendCommand "dispersion [$::session getParameterValue dispersion]"
	sendCommand "twotheta [$::session getTwoTheta]"
 	sendCommand "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]"
	if {[$::session getParameterValue "xray_source"] == "lab"} {
	    sendCommand "polarisation pinhole"
	} else {
	    sendCommand "polarisation synchrotron [$::session getParameterValue "polarization"]"
	}
 	# Detector parameters
 	sendCommand "pixel [$::session getParameterValue "pixel_size"]"
 	sendCommand "gain [$::session getParameterValue "gain"]"
	if {[$::session getParameterValue "adcoffset"] != ""} {
		sendCommand "ADCOFFSET [$::session getParameterValue "adcoffset"]"
	}

	sendCommand "DISTORTION YSCALE [$::session getParameterValue yscale] TILT [expr [$::session getParameterValue tilt] * 100] TWIST [expr [$::session getParameterValue twist] * 100] XTOFRA 1.0"	

	if {[$::session getParameterValue "overload_cutoff"] != ""} {
		sendCommand "OVERLOAD CUTOFF [$::session getParameterValue "overload_cutoff"]"
	}

# 	sendCommand "bias [$::session getParameterValue "bias"]"

	# Apply separation limits
	if {[$::session separationCommandRequired]} {
	    sendCommand "[$::session getSeparationCommand]"
	}

	# Matrix
	sendCommand "matrix [$l_matrix listMatrix]"

	# Cell
	sendCommand "cell [$::session listCell]"

	# Missets
	sendCommand "misset [$a_image getMissets]"

	sendCommand "symmetry [[$::session getSpacegroup] reportSpacegroup]"

	# Apply resolution limits
	sendCommand "resolution exclude none"
	sendCommand [$::session getEstimatedResolutionCommand]
	
# 	# Raster
# 	if {[$::session rasterIsValid]} {
# 	    sendCommand "raster [$::session getRaster]"
# 	}

# 	# Nullpix
# 	sendCommand "nullpix [$::session getParameterValue nullpix]"

# 	# Reflection width limit
# 	sendCommand "maxwidth [$::session getParameterValue "max_refl_width"]"

	# Set backstop
	sendCommand [$::session getBackstopCommand]
	
	set l_image [.image getNextImage]
	foreach { l_phi_start l_phi_end } [$l_image getPhi] break
	if { [$::session getPhiCorrectInHeader] } {
	    sendCommand "mosaic estimate [$a_image getNumber]"
	} {
	    sendCommand "mosaic estimate [$a_image getNumber] phi $l_phi_start to $l_phi_end"
	}
	sendCommand "go"
	sendCommand [$::session getResolutionCommand]
    }
}

# getPredictions ###################################################

body Mosflm::getPredictions { } {
    set l_new_image [.image getNextImage]
    if { $l_new_image != "" } {
	#puts "l_new_image $l_new_image"
	if {[catch {set l_sector [$l_new_image getSector]} catchmsg]} {
	    puts "$catchmsg getting Sector $lsector"
	}
	if { $l_sector != "" } {
	    if { [$l_sector reportMatrix] != "Unknown" } {
		if {[busy]} {
                    if {$::debugging} {
                        puts "flow: in mosflm:getPredictions, mosflm busy so set queue"
		        puts "Mosflm is busy, setting prediction_queued 1"
                    }
		    set prediction_queued 1
		} else {
                    if {$::debugging} {
                        puts "flow: in mosflm:getPredictions, really get predictions"
		        puts "Mosflm not busy so really get predictions"
                    }
		    reallyGetPredictions
		}
	    }
	}
    }
}

body Mosflm::reallyGetPredictions { } {

    #puts "REALLY GETTING PREDICTIONS"
    
    addJob "prediction" "Calculating predicted reflections"
    
    set l_image [.image getNextImage]
    # puts "debug: In reallyGetPredictions l_image is $l_image"
    
    if {$l_image != ""} {

	# Test for multiple lattices and get correct one
	set n_latts [$::session getNumberLattices]
	set curr_latt [$::session getCurrentLattice]
	#puts "Lattice $curr_latt of $n_latts"

	# Image details
	
	set l_detector [$::session getFullDetectorInformation]
	if { $l_detector != "" } {
	    sendCommand "$l_detector"
	}
        # puts "flow: in mosflm:reallyGetPredictions, send command directory [$l_image getDirectory]"
	sendCommand "directory [$l_image getDirectory]"
        # puts "flow: in mosflm:reallyGetPredictions, send command template [$l_image getTemplateForMosflm]"
	sendCommand "template [$l_image getTemplateForMosflm]"

	updateSessionForNewChunk
	set image_no [$l_image getNumber]
	foreach { l_phi_start l_phi_end } [$l_image getPhi] break
	if { [$::session getPhiCorrectInHeader] } {
	    sendCommand "image $image_no"
	} {
	    sendCommand "image $image_no phi $l_phi_start to $l_phi_end"
	}
	# Masking
	sendMasks
    
	# Beam details
	set beam_x [getImageParameterValue $l_image beam_x]
	set beam_y [getImageParameterValue $l_image beam_y]
	# Update the interface in case beam_x/y values came from refined integration results
        # puts "debug: About to update beam_x to $beam_x from reallyGetPredictions"
        # puts "debug: About to update beam_y to $beam_y from reallyGetPredictions"
	$::session updateSetting beam_x $beam_x 0 1 "User" 0
	$::session updateSetting beam_y $beam_y 0 1 "User" 0
	if {![$::session getTwoTheta]} {
	    sendCommand "beam $beam_x $beam_y"
	} else {
	    sendCommand "beam swungout $beam_x $beam_y"
	}

	# Distance
        #puts "distance recovered for image $l_image is [getImageParameterValue $l_image distance]"
	sendCommand "distance [getImageParameterValue $l_image distance]"

	# Wavelength
	sendCommand "wavelength [$::session getWavelength]"

	# Two theta
	sendCommand "twotheta [$::session getTwoTheta]"

	# Beam divergence
	sendCommand "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]"

	sendCommand "pixel [$::session getParameterValue "pixel_size"]"
	sendCommand "dispersion [$::session getParameterValue dispersion]"

	if {[$::session getParameterValue "xray_source"] == "lab"} {
	    sendCommand "polarisation pinhole"
	} else {
	    sendCommand "polarisation synchrotron [$::session getParameterValue "polarization"]"
	}

	# Radial and Tangential offsets
	sendCommand "distortion roff [getImageParameterValue $l_image radial_offset] toff [getImageParameterValue $l_image tangential_offset]"

	# Spot separation
	if {[$::session separationCommandRequired]} {
	    sendCommand "[$::session getSeparationCommand]"
	}
	
	# Matrix
	set l_sector [$l_image getSector]
	set l_matrix [$l_sector getMatrix]
	sendCommand "matrix [$l_matrix listMatrix]"

	# Cell 
	set l_cell [$::session getCell]
	#puts "reallyGetPredictions: Cell object $l_cell"
	sendCommand "cell [$l_cell listCell]"

	# Missets
	sendCommand "misset [$l_image getMissets]"
	
	# Symmetry
	#puts "reallyGetPredictions: Symmetry"
	sendCommand "symmetry [[$::session getSpacegroup] reportSpacegroup]"

	# Mosaic spread
	sendCommand "mosaic [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]"

	# Apply resolution limits
	sendCommand "resolution exclude none"
	sendCommand [$::session getResolutionCommand]

	# Reflection width limit
	sendCommand "maxwidth [$::session getParameterValue "max_refl_width"]"

	# Set backstop
	sendCommand [$::session getBackstopCommand]
	sendCommand "DISTORTION YSCALE [getImageParameterValue $l_image yscale] TILT [expr [getImageParameterValue $l_image tilt] * 100] TWIST [expr [getImageParameterValue $l_image twist] * 100] XTOFRA 1.0"

	# Reset camera constants
	sendCommand "CAMCON CCX 0.0 CCY 0.0 CCOM 0.0"

	# Add lattice keyword for current lattice and overlap subkeyword for the other lattices
	set other_latts ""
	#if { $n_latts > 1 } { Andrew wants the lattice command sent even if only one lattice is left e.g. after deletion
	    foreach latt [$::session getLatticeList] {
		if { $latt != $curr_latt } {
		    set other_latts [concat $other_latts $latt " " ]
		}
	    }
	    sendCommand "lattice [$::session getCurrentLattice] overlap $other_latts"
	#}

	# Tell Mosflm to use the new command parsing routine
	sendCommand "xgui on"
	sendCommand "go"
	set responses [sendCommand "predict_spots"]
	#puts ">>> reallyGetPredictions sent predict_spots <<<"
	sendCommand "return"
	return $responses
    }
}

body Mosflm::getImageParameterValue { image_object parameter } {
    
    set image_number [$image_object getNumber]
    set value ""

    # Get value of this parameter from the image object if possible or from the session - not the results
    set value [$image_object getValue "$parameter"]
    #puts "flow: value for $parameter from $image_object is $value"
    set from "image"
    if { $value == "" } {
        # Get value of this parameter from the session
	set value [$::session getParameterValue $parameter]
	set from "session"
        #puts "debug: value for $parameter from session is $value"
    }

    if { $parameter == "beam_x" || $parameter == "beam_y" } {
	# If beam been edited for this image use session value not value from results
	if { [$::session getBeamEditedImage] == $image_number } {
	    set value [$::session getParameterValue $parameter]
            # puts "debug: value for $parameter edited from session is $value"
	    set from session	    
	}
    }
     #puts "debug: $parameter $value for image $image_number from $from"

    return $value
}

# Pick ###########################################################

body Mosflm::pick { an_image a_x a_y a_width a_height } {
    #puts "mydebug: entering Mosflm::pick"
    #addJob "pick" - removed as it causes Image display to hang before prediction box redrawn if on max. zoom
    # Image details
    
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$an_image getDirectory]"
    sendCommand "template [$an_image getTemplateForMosflm]"
    updateSessionForNewChunk
    sendCommand "pick [$an_image getNumber] $a_x $a_y $a_width $a_height"
    sendCommand "go"
}


# Strategy #######################################################

body Mosflm::runningTestgen { } {
    addJob "strategy" "Calculating Test Strategy"
}

body Mosflm::finishedTestgen {} {
    removeJob "strategy"
}


body Mosflm::calcStrategy { a_mode a_sectors {a_matrix ""} {a_rotation ""} {a_segments ""} {a_anomalous "0"} {a_spacegroup ""} } {

    if {$a_mode == "complete"} {
	addJob "strategy" "Calculating strategy for maximum completeness"
    } else {
	addJob "strategy" "Calculating completeness of existing data"
    }

    # prepare anomalous subkeyword
    if {$a_anomalous} {
	set l_anomalous "anomalous"
    } else {
	set l_anomalous "notanom"
    }

    # prepare symmetry if set in Strategy pane
    if {$a_spacegroup == ""} {
	set l_spacegroup [$::session reportSpacegroup]
    } else {
	set l_spacegroup $a_spacegroup
    }

    # keep record of where to sending processing feedback
    set processor "strategy"
    set l_commands {}
    # If there are existing sectors
    if {[llength $a_sectors] > 0} {
	# Work out how many parts
	set l_parts [llength $a_sectors]
	if {$a_mode == "complete"} {
	    incr l_parts
	}
	# Send the strategy command for the first existing sector
	#  including a parts subkeyword
	set l_sector [lindex $a_sectors 0]
	foreach { l_phi_start l_phi_end } [$l_sector getPhiLimits] break
	lappend l_commands "matrix [$l_sector listMatrix]"
	lappend l_commands "strategy start $l_phi_start end $l_phi_end parts $l_parts $l_anomalous"
	#puts "strategy start $l_phi_start end $l_phi_end parts $l_parts $l_anomalous"
	lappend l_commands "go"
	# Send strategy commands for rest of existing sectors
	foreach i_sector [lrange $a_sectors 1 end] {
	    foreach { l_phi_start l_phi_end } [$i_sector getPhiLimits] break
	    lappend l_commands "matrix [$i_sector listMatrix]"
	    lappend l_commands "strategy start $l_phi_start end $l_phi_end"
	    #puts "strategy start $l_phi_start end $l_phi_end"
	    lappend l_commands "go"
	}
	# Remove anomalous subkeyword, as it has been sent already
	set l_anomalous ""
    }
    if {$a_mode == "complete"} {
	# Send strategy command for final part
	lappend l_commands "matrix [$a_matrix listMatrix]"
	if {$a_rotation == "Auto"} {
	    lappend l_commands "strategy auto $l_anomalous"
	    #puts "strategy auto $l_anomalous"
	} else {
	    lappend l_commands "strategy rotation $a_rotation segments $a_segments $l_anomalous"
	    #puts "strategy rotation $a_rotation segments $a_segments $l_anomalous"
	}
	lappend l_commands "go"
    } else {
	set i_run 0
 	foreach i_sector $a_sectors {
 	    lappend l_commands "run [incr i_run]"
 	}
	lappend l_commands "go"
    }
    set l_sector ""
    if {$a_matrix != ""} {
	set l_sector [$::session getSectorByMatrix $a_matrix]
    }
    if {$l_sector == ""} {
	foreach i_sector $a_sectors {
	    set l_sector [$::session getSectorByMatrix [$i_sector getMatrix]]
	    if {$l_sector != ""} {
		break
	    }
	}
    }
    if {$l_sector == ""} {
	set l_sector [lindex [$::session getSectors] 0]
    }
    set l_image [lindex [$l_sector getImages] 0]

    # Image details
    # Beam details
    if {![$::session getTwoTheta]} {
	sendCommand "beam [$::session getBeamPosition]"
    } else {
	sendCommand "beam swungout [$::session getBeamPosition]"
    }

    # Masking
    sendMasks

    # Distance
    sendCommand "distance [$::session getDistance]"
    # Wavelength
    sendCommand "wavelength [$::session getWavelength]"
    # Two theta
    sendCommand "twotheta [$::session getTwoTheta]"
    # Provide spacegroup
    sendCommand "symmetry $l_spacegroup"
    # Provide cell in case spacegroup and matrix are not consistent
    if {[[$::session getCell] reportCell] != "Unknown"} {
	sendCommand "cell [[$::session getCell] listCell]"
    }
   
    # Tell mosflm where to write output (hklout and genfile)
    sendCommand "hklout \"${::mosflm_directory}/hklout.mtz\""
    sendCommand "genfile \"${::mosflm_directory}/$l_genfile\""

    # Load token image
    
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$l_image getDirectory]"
    sendCommand "template [$l_image getTemplateForMosflm]"
    updateSessionForNewChunk
    sendCommand "image [$l_image getNumber]"
    sendCommand "load"
    sendCommand "go"

    foreach i_command $l_commands {
    if {$::debugging} {
        puts "flow: send command $i_command"
    }
	sendCommand $i_command
    }
    sendCommand "stats"
    sendCommand "exit"
    if {$::debugging} {
        puts "flow: send commands stats and exit"
    }
    #puts "Start: [clock format [clock seconds] -format "%H:%M:%S"] $processor"
}

# get suggested segments for cell refinement ######################

body Mosflm::getCellRefinementSegments { {requested_sector ""} } {
    addJob "segments" "Calculating optimal segment(s) for cell refinement"
    #puts "Calculating optimal segment(s) for cell refinement - requested sector $requested_sector"
    # hrp 11.10.2006 there must be a neater way to do the following
    set l_first_sector ""
    if { $requested_sector == "" } {
#        puts "crucial: In Mosflm::getCellRefinementSegments, requested_sector is null"
	# get first sector with valid matrix as sector not requested
	#puts "gCRS Number of sectors in session: [llength [$::session getSectors]]"
	#puts "Look for first sector"
	foreach i_sector [$::session getSectors] {
	    set l_matrix [$i_sector getMatrix]
	    if {[$l_matrix isValid]} {
		set l_first_sector $i_sector
		#puts "gCRS First sector: [$i_sector getTemplate] matrix [$l_matrix getName]"
		break
	    }
	}
	# get last sector with valid matrix as sector not requested
	set l_last_sector ""
	#puts "Look for last sector"
	foreach i_sector [$::session getSectors] {
	    set l_matrix [$i_sector getMatrix]
	}
	if {[$l_matrix isValid]} {
	    set l_last_sector $i_sector
	    #puts "gCRS Last sector: [$i_sector getTemplate] matrix [$l_matrix getName]"
	}
    } else {
	# A particular sector has been requested as an argument
#        puts "crucial: In Mosflm::getCellRefinementSegments, requested_sector is $requested_sector"
	set l_matrix [$requested_sector getMatrix]
	if {[$l_matrix isValid]} {
	    set l_first_sector $requested_sector
	    set l_last_sector $l_first_sector
	}
    }

    if {$l_first_sector != "" && $l_last_sector != "" } {
    
	# get first and last images
#        puts "crucial: l_first_sector is $l_first_sector, l_last_sector is $l_last_sector "
	set l_first_sector_first [lindex [$l_first_sector getImages] 0]
	set l_first_sector_last [lindex [$l_first_sector getImages] end]
#        puts "Mosflm::getCellRefinementSegments $l_first_sector Images [$l_first_sector_first getNumber] - [$l_first_sector_last getNumber]"

	# Beam details
	if {![$::session getTwoTheta]} {
	    sendCommand "beam [$::session getBeamPosition]"
	} else {
	    sendCommand "beam swungout [$::session getBeamPosition]"
	}
	# Distance
	sendCommand "distance [$::session getDistance]"
	# Wavelength
	sendCommand "wavelength [$::session getWavelength]"
	# High resolution
	sendCommand "resolution [$::session getHighResolution]"
	# Two theta
	sendCommand "twotheta [$::session getTwoTheta]"
	# Provide spacegroup
	sendCommand "symmetry [$::session reportSpacegroup]"
	
	# Tell mosflm where to write output (hklout and genfile)
	#sendCommand "hklout \"${::mosflm_directory}/hklout.mtz\""
	sendCommand "genfile \"${::mosflm_directory}/$l_genfile\""

	# Load token image for first sector
	
	set l_detector [$::session getFullDetectorInformation]
	if { $l_detector != "" } {
	    sendCommand "$l_detector"
	}
	sendCommand "directory [$l_first_sector_first getDirectory]"
	sendCommand "template [$l_first_sector_first getTemplateForMosflm]"
#        puts "crucial: l_first_sector_first before calling updateSessionForNewChunk is $l_first_sector_first"
	updateSessionForNewChunk
#        puts "crucial: In Mosflm::getCellRefinementSegments l_first_sector_first is $l_first_sector_first"
	foreach { l_phi_start l_phi_end } [$l_first_sector_first getPhi] break
#        puts "crucial: l_phi_start $l_phi_start l_phi_end $l_phi_end"
	if { [$::session getPhiCorrectInHeader] } {
	    sendCommand "image [$l_first_sector_first getNumber]"
	} else {
	    sendCommand "image [$l_first_sector_first getNumber] phi $l_phi_start to $l_phi_end"
	}
	sendCommand "load"
	sendCommand "go"
	sendCommand "matrix [$l_matrix listMatrix]"
	sendCommand "mosaic [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]"
	sendCommand "segment [$l_first_sector_first getNumber] [$l_first_sector_last getNumber]"
# only do this if there is more than one physical sector of data which exists. We are not 
# considering whether we ought to have two sectors of images for post-refinement - that is done 
# in the cellrefinementwizard.
	if {$l_first_sector != $l_last_sector} {
	    set l_last_sector_first [lindex [$l_last_sector getImages] 0]
	    set l_last_sector_last [lindex [$l_last_sector getImages] end]
#	    puts "Mosflm::getCellRefinementSegments $l_last_sector Images [$l_last_sector_first getNumber] - [$l_last_sector_last getNumber]"
	    set l_detector [$::session getFullDetectorInformation]
	    if { $l_detector != "" } {
		sendCommand "$l_detector"
	    }
	    sendCommand "directory [$l_last_sector_first getDirectory]"
	    sendCommand "template [$l_last_sector_first getTemplateForMosflm]"
	    updateSessionForNewChunk
	    foreach { l_phi_start l_phi_end } [$l_last_sector_first getPhi] break
	    if { [$::session getPhiCorrectInHeader] } {
		sendCommand "image [$l_last_sector_first getNumber]"
	    } else {
		sendCommand "image [$l_last_sector_first getNumber] phi $l_phi_start to $l_phi_end"
	    }
	    sendCommand "load"
	    sendCommand "go"

	    sendCommand "matrix [$l_matrix listMatrix]"
	    sendCommand "segment [$l_last_sector_first getNumber] [$l_last_sector_last getNumber]"
	}

    } else {
	# warn user!
    }
}

# prompt processing ##############################################

body Mosflm::promptProcessing { a_command } {
    #puts "$this sent command: $a_command"
    sendCommand $a_command
}

# refine cell ####################################################

body Mosflm::refineCell { lattice l_nums } {

    addJob "cell_refinement" "Refining cell"

    #puts "cell_refinement for lattice $lattice"
    set l_image [lindex $l_nums 0]
    if {$::debugging} {
        puts "flow: Entering Mosflm::refineCell first image is $l_image"
    }
    # keep record of where to sending processing feedback
    set processor "[.c component cell_refinement]"

    # Get the first valid matrix
    set l_first_valid_matrix ""
    foreach i_sector [$::session getSectors] {
	set l_matrix [$i_sector getMatrix]
	if {[$l_matrix isValid]} {
	    set l_first_valid_matrix $l_matrix
	    break
	}
    }

    # Provide experiment settings
    
    # Masking
    sendMasks
    # Beam details
    if {![$::session getTwoTheta]} {
#	sendCommand "beam [$::session getBeamPosition]"
	sendCommand "beam [getImageParameterValue $l_image beam_x] [getImageParameterValue $l_image beam_y]"
    } else {
#	sendCommand "beam swungout [$::session getBeamPosition]"
	sendCommand "beam swungout [getImageParameterValue $l_image beam_x] [getImageParameterValue $l_image beam_y]"
    }
    # puts "flow: sent command beam [getImageParameterValue $l_image beam_x] [getImageParameterValue $l_image beam_y]"

    # Distance
#    sendCommand "distance [$::session getDistance]"
    sendCommand "distance [getImageParameterValue $l_image distance]"
    # puts "flow: sent command distance [getImageParameterValue $l_image distance]"
    # Wavelength
    sendCommand "wavelength [$::session getWavelength]"
    # Two theta
    sendCommand "twotheta [$::session getTwoTheta]"
    # Gain
    sendCommand "gain [$::session getParameterValue "gain"]"
    # Beam divergence
    sendCommand "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]"

    sendCommand "pixel [$::session getParameterValue "pixel_size"]"

    if {[$::session getParameterValue "adcoffset"] != ""} {
	    sendCommand "ADCOFFSET [$::session getParameterValue "adcoffset"]"
    }

#    sendCommand "DISTORTION YSCALE [$::session getParameterValue yscale] TILT [expr [$::session getParameterValue tilt] * 100] TWIST [expr [$::session getParameterValue twist] * 100] XTOFRA 1.0"

    sendCommand "DISTORTION YSCALE [getImageParameterValue $l_image yscale] TILT [expr [getImageParameterValue $l_image tilt] * 100] TWIST [expr [getImageParameterValue $l_image twist] * 100] XTOFRA 1.0"
	
    # puts "flow: sent command DISTORTION YSCALE [getImageParameterValue $l_image yscale] TILT [expr [getImageParameterValue $l_image tilt] * 100] TWIST [expr [getImageParameterValue $l_image twist] * 100] XTOFRA 1.0"

    if {[$::session getParameterValue "overload_cutoff"] != ""} {
	    sendCommand "OVERLOAD CUTOFF [$::session getParameterValue "overload_cutoff"]"
    }

#    sendCommand "bias [$::session getParameterValue "bias"]"
    sendCommand "dispersion [$::session getParameterValue dispersion]"
    if {[$::session getParameterValue "xray_source"] == "lab"} {
	sendCommand "polarisation pinhole"
    } else {
	sendCommand "polarisation synchrotron [$::session getParameterValue "polarization"]"
    }
    
    # Provide matrix and spacegroup (indexing results)

    # Matrix + spacegroup - need to be provided for when user loads a session
    #  that they've previously indexed 
    #sendCommand "matrix [$::session getMatrix]"
    sendCommand "symmetry [$::session reportSpacegroup]"
    sendCommand "mosaicity [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]"

    # Tell mosflm where to write output (hklout and genfile)
#    sendCommand "hklout \"${::mosflm_directory}/hklout.mtz\""
    sendCommand "genfile \"${::mosflm_directory}/$l_genfile\""

    # Integration settings

    # Apply resolution limits
    sendCommand "resolution exclude none"
    sendCommand [$::session getResolutionCommand]

    # Profile
    sendCommand [$::session getProfileCommand]

    # Set backstop
    sendCommand [$::session getBackstopCommand]
    
    # Apply separation limits
    if {[$::session separationCommandRequired]} {
	sendCommand "[$::session getSeparationCommand]"
    }
    # Apply refinement fixes

    if {[$::session getParameterValue "donot_refine_detector"]} {
	    sendCommand "NOREFINE"
    } else {
	    sendCommand "NOREFINE OFF"
    }

    sendCommand [$::session getRefinementCommand cell_refinement]
    # Apply postrefinement fixes
    sendCommand [$::session getPostrefinementCommand cell_refinement]

    # Raster
    if {[$::session rasterIsValid]} {
	sendCommand "raster [$::session getRaster]"
    }

    # Nullpix
    sendCommand "nullpix [$::session getParameterValue nullpix]"

    # Reflection width limit
    sendCommand "maxwidth [$::session getParameterValue "max_refl_width"]"

    # Postrefinement command
    set l_image_image_pair_list_list [makeProcessingPairLists $l_nums]
    set l_num_segments 0
    foreach i_image_image_pair_list $l_image_image_pair_list_list {
	foreach { l_image l_image_pair_list } $i_image_image_pair_list break
	foreach i_image_pair $l_image_pair_list {
	    incr l_num_segments
	}
    }

    # Add lattice number to command
    sendCommand "POSTREF SEGMENT $l_num_segments lattice $lattice"

    set smllr_partls_fract [$::session getParameterValue smaller_partials_fraction]
    sendCommand "POSTREF PARTITION $smllr_partls_fract"

    set l_sent_matrix 0
    foreach i_image_image_pair_list $l_image_image_pair_list_list {
	foreach { l_image l_image_pair_list } $i_image_image_pair_list break
	if {!$l_sent_matrix} {
	    
	    # Test for multiple lattices and get correct matrix
	    set n_latts [$::session getNumberLattices]
	    set curr_latt [$::session getCurrentLattice]
	    if { $n_latts > 1 } {
		set solution [[.c component indexing getPathToLatticeTab $curr_latt] getChosenSolution]
		set l_matrix [$solution getMatrix]
	    } else {
		set l_matrix [[$l_image getSector] getMatrix]
	    }

	    if {[$l_matrix isValid]} {
		sendCommand "matrix [$l_matrix listMatrix]"
	    } else {
		sendCommand "matrix [$l_first_valid_matrix listMatrix]"
	    }
	    set l_sent_matrix 1
	}

	set l_detector [$::session getFullDetectorInformation]
	if { $l_detector != "" } {
	    sendCommand "$l_detector"
	}	
    
	# Cell 
	set l_cell [$::session getCell]
	sendCommand "cell [$l_cell listCell]"

	# Add submat lines for the other lattices and build string
	set other_latts ""
	set n_latts [$::session getNumberLattices]
	#if { $n_latts > 1 } { Andrew wants the lattice command sent even if only one lattice is left e.g. after deletion
	    foreach latt [$::session getLatticeList] {
		if { $latt != [$::session getCurrentLattice] } {
		    set solution [[.c component indexing getPathToLatticeTab $latt] getChosenSolution]
		    sendCommand "submat $latt [$solution getNumber] [[$solution getMatrix] listMatrix]"
		    set other_latts [concat $other_latts $latt " " ]
		}
	    }
	    # Add lattice & overlap command
	    sendCommand "lattice [$::session getCurrentLattice] overlap $other_latts"
	#}

	sendCommand "directory [$l_image getDirectory]"
	sendCommand "template [$l_image getTemplateForMosflm]"
	updateSessionForNewChunk
	foreach i_image_pair $l_image_pair_list {
	    foreach {l_start l_end} $i_image_pair {
		set t_image [$::session getImageByTemplateAndNumber [$l_image getTemplate] $l_start]
		sendCommand "misset [$t_image getMissets]"
#
# hrp 04.05.2018 for chunking
		foreach { l_phi_start l_phi_end } [$t_image getPhi] break
		set sum_n_images [$::session getParameterValue sum_n_images]
		sendCommand "process $l_start $l_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start]"
		sendCommand "run"
	    }
	}
    }
}

# pattern matching for refine cell ###############################

body Mosflm::pm_refineCell { lattice l_nums } {

    addJob "cell_refinement" "Refining cell"

    #puts "cell_refinement for lattice $lattice"

    # keep record of where to sending processing feedback
    set processor "[.c component cell_refinement]"

    # Get the first valid matrix
    set l_first_valid_matrix ""
    foreach i_sector [$::session getSectors] {
	set l_matrix [$i_sector getMatrix]
	if {[$l_matrix isValid]} {
	    set l_first_valid_matrix $l_matrix
	    break
	}
    }

    # Provide experiment settings
    
    # Masking
    sendMasks
    # Beam details
    if {![$::session getTwoTheta]} {
	sendCommand "beam [$::session getBeamPosition]"
    } else {
	sendCommand "beam swungout [$::session getBeamPosition]"
    }
    # Distance
    sendCommand "distance [$::session getDistance]"
    # Wavelength
    sendCommand "wavelength [$::session getWavelength]"
    # Two theta
    sendCommand "twotheta [$::session getTwoTheta]"
    # Gain
    sendCommand "gain [$::session getParameterValue "gain"]"
    # Beam divergence
    sendCommand "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]"

    sendCommand "pixel [$::session getParameterValue "pixel_size"]"

    if {[$::session getParameterValue "adcoffset"] != ""} {
	    sendCommand "ADCOFFSET [$::session getParameterValue "adcoffset"]"
    }

    sendCommand "DISTORTION YSCALE [$::session getParameterValue yscale] TILT [expr [$::session getParameterValue tilt] * 100] TWIST [expr [$::session getParameterValue twist] * 100] XTOFRA 1.0"	
    

    if {[$::session getParameterValue "overload_cutoff"] != ""} {
	    sendCommand "OVERLOAD CUTOFF [$::session getParameterValue "overload_cutoff"]"
    }

#    sendCommand "bias [$::session getParameterValue "bias"]"
    sendCommand "dispersion [$::session getParameterValue dispersion]"
    if {[$::session getParameterValue "xray_source"] == "lab"} {
	sendCommand "polarisation pinhole"
    } else {
	sendCommand "polarisation synchrotron [$::session getParameterValue "polarization"]"
    }
    
    # Provide matrix and spacegroup (indexing results)

    # Matrix + spacegroup - need to be provided for when user loads a session
    #  that they've previously indexed 
    #sendCommand "matrix [$::session getMatrix]"
    sendCommand "symmetry [$::session reportSpacegroup]"
    sendCommand "mosaicity [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]"

    # Integration settings

    # Set backstop
    sendCommand [$::session getBackstopCommand]
    
    # Apply separation limits
    if {[$::session separationCommandRequired]} {
	sendCommand "[$::session getSeparationCommand]"
    }
    # Apply refinement fixes

    if {[$::session getParameterValue "donot_refine_detector"]} {
	    sendCommand "NOREFINE"
    } else {
	    sendCommand "NOREFINE OFF"
    }

    sendCommand [$::session getRefinementCommand cell_refinement]

    # Raster
    if {[$::session rasterIsValid]} {
	sendCommand "raster [$::session getRaster]"
    }

    # Nullpix
    sendCommand "nullpix [$::session getParameterValue nullpix]"

    # Reflection width limit
    sendCommand "maxwidth [$::session getParameterValue "max_refl_width"]"

    # Postrefinement command
    set l_image_image_pair_list_list [makeProcessingPairLists $l_nums]
    set l_num_segments 0
    foreach i_image_image_pair_list $l_image_image_pair_list_list {
	foreach { l_image l_image_pair_list } $i_image_image_pair_list break
	foreach i_image_pair $l_image_pair_list {
	    incr l_num_segments
	}
    }

    # Add lattice number to command
    sendCommand "POSTREF SEGMENT $l_num_segments lattice $lattice"

    set smllr_partls_fract [$::session getParameterValue smaller_partials_fraction]
    sendCommand "POSTREF PARTITION $smllr_partls_fract"
    
    set l_sent_matrix 0
    foreach i_image_image_pair_list $l_image_image_pair_list_list {
	foreach { l_image l_image_pair_list } $i_image_image_pair_list break
	if {!$l_sent_matrix} {
	    
	    # Test for multiple lattices and get correct matrix
	    set n_latts [$::session getNumberLattices]
	    set curr_latt [$::session getCurrentLattice]
	    if { $n_latts > 1 } {
		set solution [[.c component indexing getPathToLatticeTab $curr_latt] getChosenSolution]
		set l_matrix [$solution getMatrix]
	    } else {
		set l_matrix [[$l_image getSector] getMatrix]
	    }

	    if {[$l_matrix isValid]} {
		sendCommand "matrix [$l_matrix listMatrix]"
	    } else {
		sendCommand "matrix [$l_first_valid_matrix listMatrix]"
	    }
	    set l_sent_matrix 1
	}

	set l_detector [$::session getFullDetectorInformation]
	if { $l_detector != "" } {
	    sendCommand "$l_detector"
	}	
    
	# Cell 
	set l_cell [$::session getCell]
	sendCommand "cell [$l_cell listCell]"

	# Add submat lines for the other lattices and build string
	set other_latts ""
	set n_latts [$::session getNumberLattices]
	#if { $n_latts > 1 } { Andrew wants the lattice command sent even if only one lattice is left e.g. after deletion
	    foreach latt [$::session getLatticeList] {
		if { $latt != [$::session getCurrentLattice] } {
		    set solution [[.c component indexing getPathToLatticeTab $latt] getChosenSolution]
		    sendCommand "submat $latt [$solution getNumber] [[$solution getMatrix] listMatrix]"
		    set other_latts [concat $other_latts $latt " " ]
		}
	    }
	    # Add lattice & overlap command
	    sendCommand "lattice [$::session getCurrentLattice] overlap $other_latts"
	#}

	set init_resol [$::session getParameterValue pm_resinit]
	set init_final [$::session getParameterValue pm_resfinl]
	set rads_convg [$::session getParameterValue pm_radconv]
	set num_refs [$::session getParameterValue pm_refl_count_thresh]

	# If second pattern matching checkbox "Integrate all images specified after refining orientation of first image"
	# is not checked - treat as if it were and always add subkeyword 'MEAS' in this case of cell refinement.
	set nomeas "MEAS"
	#puts "Integrate all images specified after refining orientation of first image set to [.ats component advanced_refinement getPatternRefineBool]"

	sendCommand "directory [$l_image getDirectory]"
	sendCommand "template [$l_image getTemplateForMosflm]"
	updateSessionForNewChunk
	sendCommand [$::session getPostrefinementCommand cell_refinement]
	foreach i_image_pair $l_image_pair_list {
	    foreach {l_start l_end} $i_image_pair {
		set t_image [$::session getImageByTemplateAndNumber [$l_image getTemplate] $l_start]
		sendCommand "misset [$t_image getMissets]"
		foreach { l_phi_start l_phi_end } [$t_image getPhi] break
		sendCommand "AUTOMATCH RESOL $init_resol $init_final RCONV $rads_convg NREF $num_refs $nomeas"
		sendCommand "process $l_start $l_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start]"
		sendCommand "run"
	    }
	}
    }
}

# integrate #######################################################

body Mosflm::integrate { lattice an_image_list args } {

    addJob "integration" "Integrating"
    #puts $l_nums

    #puts "integration for lattice $lattice"

    if {[$::session getParameterValue "wait_activation"]} {
	    sendCommand "WAIT 180" 
    }

    set l_first [lindex $an_image_list 0]
    #puts $l_first
    #puts $an_image_list
    set l_numbers $args
    regsub {\-} $l_numbers { } l_numbers

    # keep record of where to sending processing feedback
    set processor "[.c component integration]"

    # Image details
    
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$l_first getDirectory]"
    sendCommand "template [$l_first getTemplateForMosflm]"

    updateSessionForNewChunk

    # Provide data harvesting labels
    if {[$::session getParameterValue project] != ""} {
	sendCommand "pname [$::session getParameterValue project]"
    }
    if {[$::session getParameterValue dataset] != ""} {
	sendCommand "dname [$::session getParameterValue dataset]"
    }
    if {[$::session getParameterValue crystal] != ""} {
	sendCommand "xname [$::session getParameterValue crystal]"
    }
    if {[$::session getParameterValue title] != ""} {
	sendCommand "title [$::session getParameterValue title]"
    }

    # Provide experiment settings

    # Masking
    sendMasks

    # Test for multiple lattices and get correct cell, matrix & space group
    set n_latts [$::session getNumberLattices]
    set curr_latt [$::session getCurrentLattice]

    # Beam details
    #Get this from the result stored in the image object, failing that, from the session
    set l_beam [list [$::mosflm getImageParameterValue $l_first beam_x] [$::mosflm getImageParameterValue $l_first beam_y]]
    if { $n_latts > 1 } {
	set l_beam [[.c component indexing getPathToLatticeTab $curr_latt] getBeamXY]
    }
    if {![$::session getTwoTheta]} {
	sendCommand "beam $l_beam"
    } else {
	sendCommand "beam swungout $l_beam"
    }

    # Distance
    sendCommand "distance [$::mosflm getImageParameterValue $l_first distance]"
    # Wavelength
    sendCommand "wavelength [$::session getWavelength]"
    # Two theta
    sendCommand "twotheta [$::session getTwoTheta]"
    # Beam divergence
    sendCommand "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]"
    # Gain
    sendCommand "gain [$::session getParameterValue "gain"]"

    sendCommand "DISTORTION YSCALE [$::mosflm getImageParameterValue $l_first yscale] TILT [expr [$::mosflm getImageParameterValue $l_first tilt] * 100] TWIST [expr [$::mosflm getImageParameterValue $l_first twist] * 100] XTOFRA 1.0"	
	
    set l_rejection_command "REJECTION"	
    append l_rejection_command " BGRATIO [$::session getParameterValue bgratio]"
    append l_rejection_command " PKRATIO [$::session getParameterValue pkratio]"
    append l_rejection_command " GRADIENT [$::session getParameterValue rejection_gradient_integration]"
    sendCommand "$l_rejection_command"

    sendCommand "pixel [$::session getParameterValue "pixel_size"]"

    if {[$::session getParameterValue "adcoffset"] != ""} {
	    sendCommand "ADCOFFSET [$::session getParameterValue "adcoffset"]"
    }

    if {[$::session getParameterValue "overload_cutoff"] != ""} {
	    sendCommand "OVERLOAD CUTOFF [$::session getParameterValue "overload_cutoff"]"
    }

    #sendCommand "bias [$::session getParameterValue "bias"]"
    sendCommand "dispersion [$::session getParameterValue dispersion]"
    if {[$::session getParameterValue "xray_source"] == "lab"} {
	sendCommand "polarisation pinhole"
    } else {
	sendCommand "polarisation synchrotron [$::session getParameterValue "polarization"]"
    }

    # Provide matrix and spacegroup (indexing results)

    # Matrix + spacegroup - need to be provided for when user loads a session
    # that they've previously indexed

    if { $n_latts > 1 } {
	$::session setCurrentCellMatrixSpaceGroup $curr_latt
    }
    sendCommand "matrix [[$l_first getSector] listMatrix]"
    sendCommand "cell [[$::session getCell] listCell]"
    sendCommand "symmetry [$::session reportSpacegroup]"
    sendCommand "mosaicity [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]"

    # Add submat lines for the other lattices and build string
    set other_latts ""
    #if { $n_latts > 1 } { Andrew wants the lattice command sent even if only one lattice is left e.g. after deletion
	foreach latt [$::session getLatticeList] {
	    if { $latt != $curr_latt } {
		set solution [[.c component indexing getPathToLatticeTab $latt] getChosenSolution]
		sendCommand "submat $latt [$solution getNumber] [[$solution getMatrix] listMatrix]"
		set other_latts [concat $other_latts $latt " " ]
	    }
	}
	# Add lattice & overlap command
	sendCommand "lattice [$::session getCurrentLattice] overlap $other_latts"
    #}

    # Integration settings

    # Tell mosflm where to write output (hklout and genfile)
    set l_mtz_file [$::session getParameterValue mtz_file]
    if {$l_mtz_file == ""} {
	set l_mtz_file [$l_first makeAuxiliaryFileName "mtz"]
	$::session updateSetting "mtz_file" $l_mtz_file 1 1
    }
    # Tell mosflm which directory in which to write output (hklout and genfile)
    set l_mtz_directory [$::session getParameterValue mtz_directory]
    if {$l_mtz_directory != ""} {
	$::session updateSetting "mtz_directory" $l_mtz_directory 1 1
	sendCommand "mtzdirectory \"$l_mtz_directory\""
    }

# hrp 28.02.2007    sendCommand "hklout \"[file join [pwd] $l_mtz_file]\""
    if {[$::session getParameterValue multiple_mtz_files]} {
	sendCommand "hklout $l_mtz_file multiple"
    } else {
	#sendCommand "CLOSE MTZFILE"
	sendCommand "hklout $l_mtz_file nomultiple"
    }
    sendCommand "genfile \"${::mosflm_directory}/$l_genfile\""
    
    # Apply resolution limits
    sendCommand "resolution exclude none"
    sendCommand [$::session getResolutionCommand]

    # Raster
    if {[$::session rasterIsValid]} {
	sendCommand "raster [$::session getRaster]"
    }

    # Nullpix
    sendCommand "nullpix [$::session getParameterValue nullpix]"

    # Reflection width limit
    sendCommand "maxwidth [$::session getParameterValue "max_refl_width"]"

    # Profile
    sendCommand [$::session getProfileCommand]

    # Set backstop
    sendCommand [$::session getBackstopCommand]
    
    # Apply separation limits
    if {[$::session separationCommandRequired]} {
	sendCommand "[$::session getSeparationCommand]"
    }
    # Apply refinement fixes
    if {[$::session getParameterValue "donot_refine_detector"]} {
	sendCommand "NOREFINE"
    } else {
	sendCommand "NOREFINE OFF"
    }
	
    sendCommand [$::session getRefinementCommand integration]
    # Apply postrefinement fixes
    sendCommand [$::session getPostrefinementCommand integration]

    # Get block size
    set l_block_size [$::session getParameterValue "block_size"]
    if {$l_block_size == ""} {
	set l_block_subcommand ""
    } else {
	set l_block_subcommand " block $l_block_size"
    }
    # Get batch number
    set l_batch_number [$::session getParameterValue "batch_number"]
    if {$l_batch_number == ""} {
	set l_batch_number 0
    }

    # Integration commands
#    set l_pair_list [getProcessingRuns $args]
#	puts $an_image_list
    set l_pair_list [getProcessingRuns $an_image_list]
#	puts $l_pair_list
#	if {[llength $l_pair_list] > 1 && [.c.body.integration getWaitState]} {
#		puts "you need to specify contiguous range of images"
#		return
#	}
    foreach i_pair $l_pair_list {
	foreach { i_start i_end } $i_pair {
	    if  {[$::session getParameterValue "wait_activation"]} {
		set i_end [lindex $l_numbers 1]
	    }
	    set t_image [$::session getImageByTemplateAndNumber [$l_first getTemplate] $i_start]
	    if {[$t_image hasMissets]} {
		sendCommand "misset [$t_image getMissets]"
	    }
	    foreach { l_phi_start l_phi_end } [$t_image getPhi] break
	    set sum_n_images [$::session getParameterValue sum_n_images]
	    sendCommand "process $i_start $i_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start] $l_block_subcommand add $l_batch_number"
	    #puts "process $i_start $i_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start] $l_block_subcommand add $l_batch_number"
	}
    }
    sendCommand "go"

#    puts "Integration job started at  [clock format [clock seconds] -format "%H:%M:%S"]"
    .c component integration resetCurrentBlock

}

# pattern match integrate #########################################

body Mosflm::pm_integrate { lattice an_image_list args } {

    addJob "integration" "Integrating"
    #puts $l_nums

    #puts "integration for lattice $lattice"

    if {[$::session getParameterValue "wait_activation"]} {
	sendCommand "WAIT 180" 
    }

    set l_first [lindex $an_image_list 0]
    #puts $l_first
    #puts $an_image_list
    set l_numbers $args
    regsub {\-} $l_numbers { } l_numbers

    # keep record of where to sending processing feedback
    set processor "[.c component integration]"

    # Image details
    
    set l_detector [$::session getFullDetectorInformation]
    if { $l_detector != "" } {
	sendCommand "$l_detector"
    }
    sendCommand "directory [$l_first getDirectory]"
    sendCommand "template [$l_first getTemplateForMosflm]"
    updateSessionForNewChunk

    # Provide data harvesting labels
    if {[$::session getParameterValue project] != ""} {
	sendCommand "pname [$::session getParameterValue project]"
    }
    if {[$::session getParameterValue dataset] != ""} {
	sendCommand "dname [$::session getParameterValue dataset]"
    }
    if {[$::session getParameterValue crystal] != ""} {
	sendCommand "xname [$::session getParameterValue crystal]"
    }
    if {[$::session getParameterValue title] != ""} {
	sendCommand "title [$::session getParameterValue title]"
    }

    # Provide experiment settings

    # Masking
    sendMasks

    # Test for multiple lattices and get correct cell, matrix & space group
    set n_latts [$::session getNumberLattices]
    set curr_latt [$::session getCurrentLattice]

    # Beam details
    #Get this from the result stored in the image object, failing that, from the session
    set l_beam [list [$::mosflm getImageParameterValue $l_first beam_x] [$::mosflm getImageParameterValue $l_first beam_y]]
    if { $n_latts > 1 } {
	set l_beam [[.c component indexing getPathToLatticeTab $curr_latt] getBeamXY]
    }
    if {![$::session getTwoTheta]} {
	sendCommand "beam $l_beam"
    } else {
	sendCommand "beam swungout $l_beam"
    }

    # Distance
    sendCommand "distance [$::mosflm getImageParameterValue $l_first distance]"
    # Wavelength
    sendCommand "wavelength [$::session getWavelength]"
    # Two theta
    sendCommand "twotheta [$::session getTwoTheta]"
    # Beam divergence
    sendCommand "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]"
    # Gain
    sendCommand "gain [$::session getParameterValue "gain"]"

    sendCommand "DISTORTION YSCALE [$::mosflm getImageParameterValue $l_first yscale] TILT [expr [$::mosflm getImageParameterValue $l_first tilt] * 100] TWIST [expr [$::mosflm getImageParameterValue $l_first twist] * 100] XTOFRA 1.0"	
	
    set l_rejection_command "REJECTION"	
    append l_rejection_command " BGRATIO [$::session getParameterValue bgratio]"
    append l_rejection_command " PKRATIO [$::session getParameterValue pkratio]"
    append l_rejection_command " GRADIENT [$::session getParameterValue rejection_gradient_integration]"
    sendCommand "$l_rejection_command"

    sendCommand "pixel [$::session getParameterValue "pixel_size"]"

    if {[$::session getParameterValue "adcoffset"] != ""} {
	    sendCommand "ADCOFFSET [$::session getParameterValue "adcoffset"]"
    }

    if {[$::session getParameterValue "overload_cutoff"] != ""} {
	    sendCommand "OVERLOAD CUTOFF [$::session getParameterValue "overload_cutoff"]"
    }

    #sendCommand "bias [$::session getParameterValue "bias"]"
    sendCommand "dispersion [$::session getParameterValue dispersion]"
    if {[$::session getParameterValue "xray_source"] == "lab"} {
	sendCommand "polarisation pinhole"
    } else {
	sendCommand "polarisation synchrotron [$::session getParameterValue "polarization"]"
    }

    # Provide matrix and spacegroup (indexing results)

    # Matrix + spacegroup - need to be provided for when user loads a session
    # that they've previously indexed

    if { $n_latts > 1 } {
	$::session setCurrentCellMatrixSpaceGroup $curr_latt
    }
    sendCommand "matrix [[$l_first getSector] listMatrix]"
    sendCommand "cell [[$::session getCell] listCell]"
    sendCommand "symmetry [$::session reportSpacegroup]"
    sendCommand "mosaicity [$::session getMosaicity] BLOCKSIZE [$::session getParameterValue mosaicblock]"

    # Add submat lines for the other lattices and build string
    set other_latts ""
    #if { $n_latts > 1 } { Andrew wants the lattice command sent even if only one lattice is left e.g. after deletion
	foreach latt [$::session getLatticeList] {
	    if { $latt != $curr_latt } {
		set solution [[.c component indexing getPathToLatticeTab $latt] getChosenSolution]
		sendCommand "submat $latt [$solution getNumber] [[$solution getMatrix] listMatrix]"
		set other_latts [concat $other_latts $latt " " ]
	    }
	}
	# Add lattice & overlap command
	sendCommand "lattice [$::session getCurrentLattice] overlap $other_latts"
    #}

    # Pattern matching for integration settings

    # Tell mosflm where to write output (hklout and genfile)
    set l_mtz_file [$::session getParameterValue mtz_file]
    if {$l_mtz_file == ""} {
	set l_mtz_file [$l_first makeAuxiliaryFileName "mtz"]
	$::session updateSetting "mtz_file" $l_mtz_file 1 1
    }
    # Tell mosflm which directory in which to write output (hklout and genfile)
    set l_mtz_directory [$::session getParameterValue mtz_directory]
    if {$l_mtz_directory != ""} {
	$::session updateSetting "mtz_directory" $l_mtz_directory 1 1
	sendCommand "mtzdirectory \"$l_mtz_directory\""
    }

# hrp 28.02.2007    sendCommand "hklout \"[file join [pwd] $l_mtz_file]\""
    if {[$::session getParameterValue multiple_mtz_files]} {
	sendCommand "hklout $l_mtz_file multiple"
    } else {
	#sendCommand "CLOSE MTZFILE"
	sendCommand "hklout $l_mtz_file nomultiple"
    }
    sendCommand "genfile \"${::mosflm_directory}/$l_genfile\""
    
    # Apply resolution limits
    sendCommand "resolution exclude none"
    sendCommand [$::session getResolutionCommand]

    # Raster
    if {[$::session rasterIsValid]} {
	sendCommand "raster [$::session getRaster]"
    }

    # Nullpix
    sendCommand "nullpix [$::session getParameterValue nullpix]"

    # Reflection width limit
    sendCommand "maxwidth [$::session getParameterValue "max_refl_width"]"

    # Profile
    sendCommand [$::session getProfileCommand]

    # Set backstop
    sendCommand [$::session getBackstopCommand]
    
    # Apply separation limits
    if {[$::session separationCommandRequired]} {
	sendCommand "[$::session getSeparationCommand]"
    }
    # Apply refinement fixes
    if {[$::session getParameterValue "donot_refine_detector"]} {
	sendCommand "NOREFINE"
    } else {
	sendCommand "NOREFINE OFF"
    }
	
    sendCommand [$::session getRefinementCommand integration]

    # Get block size
    set l_block_size [$::session getParameterValue "block_size"]
    if {$l_block_size == ""} {
	set l_block_subcommand ""
    } else {
	set l_block_subcommand " block $l_block_size"
    }
    # Get batch number
    set l_batch_number [$::session getParameterValue "batch_number"]
    if {$l_batch_number == ""} {
	set l_batch_number 0
    }

    set init_resol [$::session getParameterValue pm_resinit]
    set init_final [$::session getParameterValue pm_resfinl]
    set rads_convg [$::session getParameterValue pm_radconv]
    set num_refs [$::session getParameterValue pm_refl_count_thresh]

    set nomeas "NOMEAS"
    if { [.ats component advanced_refinement getPatternRefineBool] == 1 } {
	puts "Integrate all images specified after refining orientation of first image set to [.ats component advanced_refinement getPatternRefineBool]"
	set nomeas "MEAS"
    }

    sendCommand "AUTOMATCH RESOL $init_resol $init_final RCONV $rads_convg NREF $num_refs $nomeas"

    sendCommand [$::session getPostrefinementCommand integration]

    # Integration commands
#    set l_pair_list [getProcessingRuns $args]
#	puts $an_image_list
    set l_pair_list [getProcessingRuns $an_image_list]
#	puts $l_pair_list
#	if {[llength $l_pair_list] > 1 && [.c.body.integration getWaitState]} {
#		puts "you need to specify contiguous range of images"
#		return
#	}
    foreach i_pair $l_pair_list {
	foreach { i_start i_end } $i_pair {
	    if  {[$::session getParameterValue "wait_activation"]} {
		set i_end [lindex $l_numbers 1]
	    }
	    set t_image [$::session getImageByTemplateAndNumber [$l_first getTemplate] $i_start]
	    if {[$t_image hasMissets]} {
		sendCommand "misset [$t_image getMissets]"
	    }
	    foreach { l_phi_start l_phi_end } [$t_image getPhi] break
	    set sum_n_images [$::session getParameterValue sum_n_images]
	    sendCommand "process $i_start $i_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start] $l_block_subcommand add $l_batch_number"
	    #puts "process $i_start $i_end start $l_phi_start angle [expr $l_phi_end - $l_phi_start] $l_block_subcommand add $l_batch_number"
	}
    }

    sendCommand "go"

#    puts "Integration job started at  [clock format [clock seconds] -format "%H:%M:%S"]"
    .c component integration resetCurrentBlock

}

body Mosflm::makeProcessingPairLists { an_image_list } {
    # split lists according to template
    foreach i_image $an_image_list {
	lappend l_lists_by_template([$i_image getTemplate]) $i_image
    }
    # index lists by first image
    foreach i_template [array names l_lists_by_template] {
	set l_list $l_lists_by_template($i_template)
	set l_first_image [lindex $l_list 0]
	set l_lists_by_image($l_first_image) $l_list
    }
    # get list of first-image/phi pairs
    set l_image_phi_pairs {}
    foreach i_image [array names l_lists_by_image] {
	foreach { l_phi_start l_phip_end } [$i_image getPhi] break
	lappend l_image_phi_pairs [list $i_image $l_phi_start]
    }
    # sort image-phi list by phi
    set l_image_phi_pairs [lsort -real -index 1 $l_image_phi_pairs]
    # make ordered list of image/image-list pairs
    set l_image_image_pair_list_list {}
    foreach i_image_phi_pair $l_image_phi_pairs {
	foreach { l_image l_phi } $i_image_phi_pair break
	lappend l_image_image_pair_list_list [list $l_image [getProcessingRuns $l_lists_by_image($l_image)]]
    }
    return $l_image_image_pair_list_list
}   

body Mosflm::getProcessingRuns { an_image_list } {
    set l_pair_list {}
    set l_first_image [lindex $an_image_list 0]
    set l_start_number [$l_first_image getNumber]
    set l_previous_number $l_start_number
    set l_image_number_list [list $l_start_number]
    # Loop through all images
    foreach i_image [lrange $an_image_list 1 end] {
	set l_current_number [$i_image getNumber]
	lappend l_image_number_list $l_current_number
	if {$l_current_number != ($l_previous_number + 1)} {
	    lappend l_pair_list [list $l_start_number $l_previous_number]
	    set l_start_number $l_current_number
	}
	set l_previous_number $l_current_number
    }
    lappend l_pair_list [list $l_start_number $l_previous_number]

    return $l_pair_list
}

body Mosflm::fitCircle { a_coords_list } {
    set l_num_points [expr [llength $a_coords_list] / 2]
    if { $l_num_points > 2 } {
	sendCommand "fitCircle $l_num_points $a_coords_list"
    }
}
# Mosflm is launched but cannot communicate with the iMosflm server socket
# and the pipe dies. This method detects the dead pipe and spawns a dialog box
body Mosflm::socketNotReachable { } {
    if {[eof $::mosflm_pipe]} {
	#puts "mosflm crashed"
	.m configure \
	    -type "1button" \
	    -title "Socket not reachable" \
	    -text " iMosflm was unable to communicate with Mosflm.\n\n Please check \
that localhost is defined in your /etc/hosts file\n\n and that the lo interface \
is up and running" \
	    -button1of1 "Exit" 		
	wm deiconify .m

	if {[.m confirm]} {
	    # User didn't want to configure, so quit
	    exit
	}
    } else {
    }
}
# Incoming message processing method ################################
#####################################################################
body Mosflm::processMessage { } {
    if {$::debugging} {
        # Comment out next line, produces too much output
        #puts "flow: enter Mosflm::processMessage"
    } 
    # Try and read from the socket
    if {[eof $socket] || [catch {gets $socket l_message} l_result]} {
	# if reading doesn't work
        if {$::debugging} {
            puts "flow: in  Mosflm::processMessage reading doesn't work"
        } 

	# NB need to unbind and close socket before re-entering event
	#  loop with dialog confirm
	# Unbind fileevent on socket
	fileevent $socket "readable" {}
	# close the socket
	close $socket

	# Update controller status
	.c errorMessage "Mosflm crash"

	# Create file name for crash log
	set l_error_filename [fileErrorLog "crash"]
	# Set the session flag
	$::session setCrashed

	# Inform user of crash
	.m configure \
	    -type "1button" \
	    -title "Error" \
	    -button1of1 "Dismiss" \
	    -text "Mosflm has crashed unexpectedly. An error log has been compiled in file:\n\n\t$l_error_filename\n\nYou should find clues regarding the cause of the problem if you read \nthe end of the log file (say, the last hundred lines or so). You may \nbe able to work out what went wrong, and you may be able to alter your \nprocessing to avoid the problem.\n\nIf, after examining the log file, you need any more help, please try \nto re-run the job in exactly the same way as before, but check the \n\"Debug output\" box in the \"Environment variables\" window (found \nunder \"Processing options\"), and send the report and the full \ndatestamped logfile produced (in the current working directory, \n\$MOSDIR), along with the associated mosflm.lp file to:\n\n\t$::env(MAINTAINER)\n\nand we will be happy to help.\n\nThank you."

	if {[.m confirm]} {
	    # reset processing controls
	    [.c component cell_refinement] resetControls
	    [.c component integration] resetControls
	    # (re)start mosflm
	    startMosflm
	    # update controller status
	    .c idle
	    .c enable
	}
    } elseif {$l_message != ""} {
	if {$logging} {
	    # Record the message in the log file
	    set logfile_handle [open $logfile a]
    #
    # /9j/4 is the header for a base64 encoded jpeg
    # UDUgI is the header for a base64 encoded pgm (grey scale)
    # UDYgI is the header for a base64 encoded ppm (colour scale)
	    if {[string range $l_message 0 4] == "UDUgI" || [string range $l_message 0 4] == "UDYgI" || [string range $l_message 0 4] == "/9j/4"} {
		#puts "header string for image received is [string range $l_message 0 4]"
		#puts "string length for image received is [string length $l_message]"
		puts $logfile_handle "<Image data: [string range $l_message 0 20]...>"
	    } elseif {[string range $l_message 31 49] == " * disabled * prediction_response"} {
		puts $logfile_handle "[string range $l_message 0 50]...[string range $l_message end-21 end]"
	    } elseif {[string range $l_message 31 44] == "image_response"} {
		puts $logfile_handle "[string range $l_message 0 45]...[string range $l_message end-16 end]"
	    } else {
		puts $logfile_handle $l_message
	    }
	    close $logfile_handle
	}
	# Get the start of the message to see which kind it is
	set test_segment [string range $l_message 0 4]
        if {$::debugging && $test_segment != "<done" } {
            puts "flow: In Mosflm::processMessage test_segment is $test_segment"
        } 
    
	if {$test_segment == "<done"} {
            # ipmosflm send <done> after reading every mosflm keyword
	    if {$processing_flag} {
		sendCommand "CLOSE MTZFILE"
		set processing_flag "0"
                if {$::debugging} {
                    puts "flow: about to call finishedProcessing from Mosflm::processMessage"
                }
		$processor finishedProcessing
	    }
	    # ignore
	} elseif {$test_segment == "UDUgI"|| $test_segment == "UDYgI"|| $test_segment == "/9j/4"} {
	    # jpeg or ppm
	    set ::timer002 [clock clicks -milli]
	    .image updateImage $l_message
	    removeJob "image"
	} elseif {$test_segment == "<?xml"} {
	    # xml - parse
	    if {[catch {set dom [dom parse $l_message]}]} {
		.c errorMessage "Mosflm crash"
		set bad_xml_from_mosflm "$l_message"
		set l_error_filename [fileErrorLog "comms"]

		# Set the session flag
		$::session setCrashed

		.m configure \
		    -type "1button" \
		    -title "Error" \
		    -button1of1 "Dismiss" \
		    -text "Mosflm has sent a badly formatted xml message to iMosflm. \n\nPlease e-mail these files \n\n\t$l_error_filename\nand\n\t[file join $::env(MOSDIR) "mosflm_$datestamp.lp"]\n\nto $::env(MAINTAINER) so that this can be investigated\n\nThis is almost certainly caused by a bug in Mosflm, so we will be extremely grateful to hear about it.\n\nThank you."
		if {[.m confirm]} {
		    [.c component cell_refinement] resetControls
		    [.c component integration] resetControls
		    .c idle
		    restartMosflm
		    .c enable
		}
	    } else {
		#check format overflow in returned XML data - non-fatal error
		set bad_val [string first **** $l_message]
		if { $bad_val > 0} {
		    set bad_xml_from_mosflm "$l_message"
		    set l_error_filename [fileErrorLog "badxml"]
		    # extract tag preceding ****
		    #set tagend [expr $bad_val - 2]
		    #set leadstr [string range $l_message 0 $tagend]
		    #set tagstart [expr [ string last < $leadstr ] + 1]
		    #set bad_tag [string range $l_message $tagstart $tagend]
		    #set bad_tag [regsub -all {\_\_nl\_\_} $bad_tag "\n"]
		    ## Add meaningful parameter names for a,b,c_slope
		    #if { $bad_tag == "a_slope" || $bad_tag == "b_slope"} { set bad_tag "background plane gradient" }
		    #if { $bad_tag == "c_slope" } { set bad_tag "background plane constant" }
		    set l_out_file [open $l_error_filename "w"]
		    puts $l_out_file "The XML message from Mosflm contained **** in the response for the message about [[$dom documentElement] nodeName] at character position $bad_val\nFull string:\n\n$l_message"
		    close $l_out_file
		    #puts "Format overflow in XML returning value for $bad_tag"
		    .m configure \
			-type "1button" \
			-title "Parameter value results in XML format error" \
			-button1of1 "Dismiss" \
			-text "The XML response from Mosflm has a value which causes a format error.\n\nWhile this will not affect processing, it indicates a problem that\nthe iMosflm developers should investigate. \n\nPlease e-mail these files \n\n\t$l_error_filename\nand\n\t[file join $::env(MOSDIR) "mosflm_$datestamp.lp"]\n\nto $::env(MAINTAINER) so that this can be investigated\n\n"
		    if {[.m confirm]} {
		    }
		}
    
		# read the document type
		set doctype [[$dom documentElement] nodeName]
                if {$::debugging} {
                  puts "Returning XML is a $doctype"
                }
		# Pass to appropriate object to process...
		if {$doctype == "image_response"} {
		    .image parseHistogram $dom
		} elseif {$doctype == "header_response"} {
		    $::session processHeaderData $dom
		} elseif {$doctype == "brief_header_response"} {
		    $::session processBriefHeaderData $dom
		} elseif {$doctype == "experiment_response"} {
		    $::session processExperimentData $dom
		} elseif {$doctype == "warnings"} {
		    $::session parseWarnings $dom
	 # Started processing keyword errors sent by Mosflm but probably too disruptive
	 # as e.g. during Integration iMosflm sends a "continue" command after each image.
	 #       } elseif {$doctype == "keyword_error"} {
	 #	   $::session parseErrors $dom
		} elseif {$doctype == "spot_search_response"} {
		    removeJob "spot_finding"
		    [.c component indexing] processSpotfindingResults $dom
		} elseif {$doctype == "preselection_index_response"} {
		    removeJob "indexing"
		    [.c component indexing] processIndexingResults $dom
		} elseif {$doctype == "prerefinement_index_response"} {
		    [.c component indexing] processPrerefinementResult $dom
		} elseif {$doctype == "refined_index_response"} {
		    removeJob "index_refinement"
                    if {$logging} {
                	set logfile_handle [open $logfile a]
                	puts $logfile_handle "debug: about to call processRefinedResult"
                	close $logfile_handle
                    }
		    [.c component indexing] processRefinedResult $dom
                    if {$logging} {
                	set logfile_handle [open $logfile a]
                	puts $logfile_handle "debug: returned from call to processRefinedResult"
                	close $logfile_handle
                    }
		} elseif {$doctype == "updated_amatrix_response"} {
		    [.c component indexing] processUpdatedAmatrices $dom
		} elseif {$doctype == "split_angle_response"} {
		    [.c component indexing] processSplitAngle $dom
		} elseif {$doctype == "multiple_lattice_index_response"} {
		    $::session parseNumberLattices $dom
		} elseif {$doctype == "mosaicity_response"} {
		    removeJob "mosaicity"
		    .me processMosaicityEstimation $dom
		} elseif {$doctype == "mosaicity_estimation_response"} {
		    .me processMosaicityFeedback $dom
		} elseif {$doctype == "image_pixel_response"} {
		    .image processPixelResponse $dom
		} elseif {$doctype == "prediction_response"} {
		    removeJob "prediction"
		    .image processPredictions $dom
		} elseif {$doctype == "bad_spots_response"} {
		    .image processBadSpots $dom
		} elseif {$doctype == "pick_region"} {
                    #puts "mydebug: from mosflm.tcl, calling .image processPick to parse XML"
		    .image processPick $dom
		    #addition removed in Mosflm::pick as it causes Image display to hang
		    #before prediction box redrawn if on max. zoom - so no need to remove!
		    #removeJob "pick"
		} elseif {$doctype == "block_size_notification"} {
		    if {$processor != "strategy"} {
			$processor extractBlockSize $dom
		    }
		} elseif {$doctype == "image_process_begin"} {
		    # set the processing flag, so next <done> is trapped as processing finish
		    set processing_flag "1"
		    $processor updateProcessingStatus "refinement" $dom
		} elseif {$doctype == "pattern_matching_response"} {
		    $processor updatePatternMissets "pattern_matching" $dom
		} elseif {$doctype == "integration_positional_refinement"} {
		    $processor updateProcessingData "refinement" $dom
		} elseif {$doctype == "spot_profile"} {
		    $processor updateProfileData $dom
		} elseif {$doctype == "integration_postrefinement_begin"} {
		    $processor updateProcessingStatus "postrefinement" $dom
		} elseif {$doctype == "integration_postrefinement"} {
		    $processor updateProcessingData "postrefinement" $dom
		} elseif {$doctype == "refinement_repeat"} {
		    $processor updateProcessingStatus "repeat refinement" $dom
		} elseif {$doctype == "regional_spot_profile_response"} {
		    $processor updateRegionalProfileData $dom
		} elseif {$doctype == "block_integrate_begin"} {
		     if {$processor eq [.c component integration]} {
			     if {[$::session getParameterValue pointless_live] == 1} {
				     $::session callPointlessProcess
			     }
		     }
		     $processor updateIntegrationStatus
		} elseif {$doctype == "block_integrate_end"} {
		    # hrp 08032018 sometimes gets triggered if refinement follows an integration run
		    if { $processor == ".c.body.integration" } {
			$processor updateIntegrationGraphics
		    }
		} elseif {$doctype == "integration_response"} {
                    if {$::debugging} {
                        puts "flow: In body Mosflm::processMessage removejob integration"
                    }
		    removeJob "integration" ; # causes icon to stop spinning after first block
		    $processor updateIntegrationData $dom
		} elseif {$doctype == "processing_task_begin"} {
		    $::session setRunningProcessing 1
		} elseif {$doctype == "processing_task_end"} {
		    $::session setRunningProcessing 0
                    if {$::debugging} {
                        puts "flow: at processing_task_end, job_queue is $job_queue"
                    }
                    # If all images are rejected (eg too high positional refinement residual)
                    # the job_queue is not empty because the integration_response XML
                    # will not have been set, so test for that now and set null if necessary.
                    if { [llength $job_queue] != 0 } {
			if {$job_queue == "integration"} {
                             removeJob "integration"
                        }
			if {$job_queue == "cell_refinement"} {
                             removeJob "cell_refinement"
                        }
                      if {$::debugging} {
                          puts "flow: set job_queue null, so it is now: $job_queue"
                      }
                    }
                    # puts "debug: in mosflm.tcl setRunningProcessing set to 0"
		} elseif {$doctype == "cell_refine_response"} {
		    #removeJob "cell_refinement" moved to processCellRefinementSummary
		    $processor processCellRefinementSummary $dom
		} elseif {$doctype == "information_and_warnings"} {
		    #puts "debug: from mosflm.tcl, processor is $processor"
		    $::session parseInfoAndWarnings $processor $dom
		} elseif {$doctype == "strategy_response_alignment"} {
		    [.c component strategy] processStrategyAlignmentResponse $dom
		} elseif {$doctype == "strategy_response"} {
		    [.c component strategy] processStrategyResponse $dom
		} elseif {$doctype == "strategy_response_breakdown"} {
		    removeJob "strategy"
		    #puts " Ends: [clock format [clock seconds] -format "%H:%M:%S"]"
		    [.c component strategy] processStrategyBreakdownResponse $dom
		} elseif {$doctype == "segment_setup_response"} {
		    removeJob "segments"
		    [.c component cell_refinement] processSegmentSetupResponse $dom
		} elseif {$doctype == "updated_raster_and_separation"} {
		    $::session processRasterAndSeparation $dom $processor
		} elseif {$doctype == "circle_fitting_response"} {
		    CircleFit::parseCircle $dom
		} elseif {$doctype == "backstop_response"} {
		    ImageDisplay::parseBackstop $dom
		} elseif {$doctype == "fatal_condition_response"} {
		    $::session processFatalError $dom
		} elseif {$doctype == "trapped_error_response"} {
		    $::session processTrappedError $dom
		} elseif {$doctype == "strategy_response_testgen"} {
		    [.c component strategy] processTestgenResponse $dom
		} elseif {$doctype == "generate_response"} {
		    $::session processGenerateResponse $dom
		} elseif {$doctype == "interface_input_response"} {
		    #puts "Interface input response from $processor"
		    $::session processInterfaceInputResponse $dom $processor
		} elseif {$doctype == "processor_information"} {
		    $::session setMaxNumberOfCores $dom
		} elseif {$doctype == "resolution_response"} {
		    $::session reportResolution $dom
		} elseif {$doctype == "phiprofile_setup"} {
		    .pp setupPhiProfile $dom
		} elseif {$doctype == "phiprofile_response"} {
		    .pp processPhiProfile $dom
		} elseif {$doctype == "phiprofile_final"} {
		    .pp finalPhiProfile $dom
		} else {
		    # Unrecognized message!!!
		}
		# Tidyup
		$dom delete
	    }
	} else {
	    # Wrong
	    # Non-xml message recieved
	    # puts "Mosflm said something strange: $l_message"
	}
     }
}

body Mosflm::fileErrorLog { a_type } {
    set l_out_filename [file join $::mosflm_directory "${a_type}_[clock format [clock seconds] -format "%Y.%m.%d.%H%M"]"]
    set l_out_file [open $l_out_filename w]
    if { ![regexp -nocase windows $::tcl_platform(os)] } {
	set l_filename_list [list "mosflm_$datestamp.lp"]
    } else {
    #	set l_filename_list [list "mosflm.lp"]
	set l_filename_list [file join $::env(MOSDIR) "mosflm.lp"]
	set l_filename_list [list $l_filename_list]
    }
    if {$logging} {
	lappend l_filename_list $logfile
    }
    foreach i_filename $l_filename_list {
	set i_filename_length [expr 19 + [string length $i_filename]]
	puts $l_out_file "*[string repeat \* $i_filename_length]*"
	puts $l_out_file "*[string repeat \  $i_filename_length]*"
	puts $l_out_file "*[string repeat \  $i_filename_length]*"
	puts $l_out_file "* Contents of file: $i_filename *"
	puts $l_out_file "*[string repeat \  $i_filename_length]*"
	puts $l_out_file "*[string repeat \  $i_filename_length]*"
	puts $l_out_file "*[string repeat \* $i_filename_length]*"
	puts $l_out_file ""
	if {[file exists $i_filename]} {
	set l_in_file [open $i_filename r]
		while {![eof $l_in_file]} {
	   	 puts $l_out_file [gets $l_in_file]
		}
		close $l_in_file
    	}
    }
    if { [string length $bad_xml_from_mosflm] > 0 } {
	puts $l_out_file "The error was triggered by this XML string written by Mosflm:\n\n$bad_xml_from_mosflm\n\n"
    }
    close $l_out_file

    return $l_out_filename
}

body Mosflm::startMosflm { } {
    if {[info exists ::mosflm]} {
	if {[info commands $::mosflm] != ""} {
	    delete object $::mosflm
	}
    }
    debug "Mosflm: Creating mosflm object"
    set ::mosflm [namespace current]::[Mosflm m]
    debug "Mosflm: Waiting for mosflm to connect"
    tkwait variable [scope ready]
    debug "Mosflm: Mosflm connected"
    return 1
}

body Mosflm::closeMosflm { } {
    #global mosflm
    if {$::mosflm != ""} {
	$::mosflm shutdown
	delete object $::mosflm
	set ::mosflm ""
    }
}

body Mosflm::restartMosflm { } {
    closeMosflm
    return [startMosflm]
}

body Mosflm::getDateStamp { } {
    return $datestamp
}

body Mosflm::getNewTimeStamp { } {
    return "[clock format [clock seconds] -format "%Y%m%d_%H%M%S"]"
}

body Mosflm::updateSessionForNewChunk { } {
# method to delete current sector and images from session and replace 
# them with a session containing the chunked images, if the new chunk size
# is different from the old one
#
# print current and new values of chunk size
#
#    puts "crucial: In updateSessionForNewChunk, sum_n_images is [$::session getParameterValue sum_n_images] saved value is $save_sum_n_images"
    if {[ $::session getSessionFileRead ]  } {
       sendCommand "chunk [$::session getParameterValue sum_n_images]"
       set save_sum_n_images [$::session getParameterValue sum_n_images]
    }
#    puts "crucial: saved value is now $save_sum_n_images"
    if {[$::session getParameterValue sum_n_images] != $save_sum_n_images} {
	#puts "(1) Old chunk size is $save_sum_n_images, new chunk size is [$::session getParameterValue sum_n_images]"
	set save_sum_n_images [$::session getParameterValue sum_n_images]
	#
	# print list of current sectors
	#
	#puts "Current sectors are:\n              [$::session getSectors]"
	sendCommand "chunk [$::session getParameterValue sum_n_images]"

	$::session setParameterValue sum_n_images_changed "1"
	foreach i_sector [$::session getSectors] {
#
# get first image from current sector	    
#
	    set l_first [lindex [$i_sector getImages] 0]
	    set l_directory [$l_first getDirectory]
	    set l_template [$l_first getTemplate]
	    set l_template_for_mosflm [$l_first getTemplateForMosflm]
	    set an_image "$l_directory/$l_template_for_mosflm"
	    #puts "list of images is [$::session getImages]"
	    #puts "-------------------------------------------------------------"
	    #puts "l_first is $l_first"
	    #puts "directory [$l_first getDirectory]"
	    #puts "l_template for l_first is $l_template"
	    #puts "l_template_for_mosflm for l_first is $l_template_for_mosflm"
	    #puts "checking l_template: $l_template"
	    #puts "an_image is $an_image"
	    #puts "============================================================="
	    #puts "deleting sector $i_sector"
#
	    # clearing images and sector done cleanly in controller.tcl, use that method; unfortunately, 
	    # just clearing the images from the sectors is difficult because sending a "head" rather than 
	    # "head brief" to mosflm creates a new sector...
#	    .c deleteImagesFromSector
	    .c rightClickSession
	    $::session addImage $an_image
	}
    } else {
	$::session setParameterValue sum_n_images_changed "0"	
    }
#    puts "crucial: exiting updateSessionForNewChunk"
}

