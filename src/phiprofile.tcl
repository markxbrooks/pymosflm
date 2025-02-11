# $Id: phiprofile.tcl,v 1.2 2021/01/11 18:25:59 andrew Exp $
package provide phiprofile 1.0
if {$::debugging} {
    puts "flow: entering phiprofile.tcl"
}

class PhiProfile {
    inherit Amodaldialog

    # Member variables

    private variable image_used ""
    private variable max_mosaictiy_tested "0"
    private variable image_numbers {}
    private variable intensities {}
    private variable fractions {}

    # methods

    public method launch
    public method setupPhiProfile
    public method processPhiProfile
    public method finalPhiProfile
    public method getPhiProfile

    public method disable
    public method enable

    constructor { args } { }
}

body PhiProfile::constructor { args } {
    if {$::debugging} {
      puts "flow: PhiProfile::constructor"
    }
    # Main frame
    itk_component add main_f {
	frame $itk_interior.mf \
	    -bd 2 \
	    -relief raised
    }

    # Header frame
    itk_component add heading_f {
	frame $itk_interior.mf.hf \
	    -bd 1 \
	    -relief solid
    }

    # Header label

    itk_component add heading_l {
	label $itk_interior.mf.hf.fl \
	    -text "Reflection profile vs image number" \
	    -font title_font
    } {
	usual
	ignore -font
    }

    # Activity indicator
    itk_component add activity_l {
	Activity $itk_interior.mf.hf.al
    }
    $itk_component(activity_l) idle


    # image frame
    itk_component add image_f {
	frame $itk_interior.mf.if
    }

    itk_component add image_l {
	label $itk_interior.mf.if.il \
	    -text "?"
    }


    itk_component add phiprofile_graph {
	canvas $itk_interior.mf.mg \
	    -relief sunken \
	    -borderwidth 2 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
    }

    itk_component add mosaicity_l {
	label $itk_interior.mf.ml \
	    -text "Mosaicity:                                          "
    }

    itk_component add mosaicity_e {
	SettingEntry $itk_interior.mf.me mosaicity \
	    -image ::img::mosaicity \
	    -type real \
	    -precision 2 \
	    -width 7 \
	    -minimum 0 \
	    -maximum 10 \
	    -justify right \
	    -textbackground white \
            -balloonhelp "Current mosaicity. This can be changed and the 'Repeat phi profile'\n button used to re-evaluate the phi profile"
    }
    
    itk_component add repeat_b {
	button $itk_interior.mf.meb \
	    -text "Repeat phi profile" \
	    -width 18 \
	    -pady 2 \
	    -command [code $this getPhiProfile]
    }


    itk_component add mosaicity_l2 {
	label $itk_interior.mf.ml2 \
	    -text "Mosaicity2: "
    }

    itk_component add restrict_resolution_l {
   	label $itk_interior.mf.rrl -text "Restrict resolution for integration:          "
    }

    itk_component add restrict_resolution_check {
        SettingCheckbutton $itk_interior.mf.rrc restrict_resolution \
	    -text ""
#            -balloonhelp "If selected, only reflections in a narrow resolution shell\n will be integrated. This may be faster\n but the integration will be repeated for every profile."
    }

    itk_component add pad_l {
	label $itk_interior.mf.pl \
	    -text "Extend integration (number of images):"
    }

    itk_component add pad_e {
	SettingEntry $itk_interior.mf.pe imgpad \
	    -type integer \
	    -width 7 \
	    -minimum 0 \
	    -justify right \
	    -textbackground white \
            -balloonhelp "Integration will start and end before the predicted start and end of\n the selected reflection. This will take longer but allow the phi profile\n of other reflections to be determined without repeating integration."
    }

    ## Close button

    itk_component add close_b {
        button $itk_interior.button \
	    -highlightthickness 0 \
	    -takefocus 0 \
	    -text "Close" \
	    -command [code $this hide]
    }

    # Arrange widgets

    set margin 7
    
    pack $itk_component(main_f) -fill both -expand 1
    pack $itk_component(close_b) -side bottom -pady 4
    
    grid x $itk_component(heading_f) - - x -sticky we -pady 7
    pack $itk_component(heading_l) -side left -padx 5 -pady 5
    pack $itk_component(activity_l) -side right -padx 5 -pady 5
    
    grid x $itk_component(image_f) - - x -sticky w
    pack $itk_component(image_l) -side left
    grid x $itk_component(phiprofile_graph) - - x -sticky news -pady 7

#    grid x $itk_component(mosaicity_l)  x  $itk_component(mosaicity_e) -pady [list 0 7] -sticky e

    grid x $itk_component(mosaicity_l) x   $itk_component(mosaicity_e)  -sticky e
    grid x $itk_component(repeat_b)   -sticky we
    grid x $itk_component(restrict_resolution_l)   - $itk_component(restrict_resolution_check)  x x  -sticky e
    grid x $itk_component(pad_l) x   $itk_component(pad_e)  -sticky e



    grid columnconfigure $itk_component(main_f) { 0 4 } -minsize 7
    grid columnconfigure $itk_component(main_f) { 3 } -weight 1
    grid rowconfigure $itk_component(main_f) { 2 } -weight 1
    
    eval itk_initialize $args
}

body PhiProfile::launch { { an_image "" } } {
    if {$::debugging} {
      puts "flow: PhiProfile::launch"
    }
    $itk_component(mosaicity_e) update [$::session getMosaicity]
    # show the dialog
    show
}

body  PhiProfile::getPhiProfile { args } {
    if {$::debugging} {
      puts "flow: PhiProfile::getPhiProfile"
    }
    # Tell mosflm to get a phi profile
    set l_command "phiprofile repeat "
    if {[$::session getParameterValue restrict_resolution]} {
	append l_command " RESTRICT \n"
    } else {
	append l_command " UNRESTRICT \n"
    }
    $::mosflm sendCommand $l_command
    $::mosflm sendCommand "go \n"
}

body PhiProfile::setupPhiProfile { a_dom } {
    if {$::debugging} {
      puts "flow: PhiProfile::setupPhiProfile"
    }
    launch
    # Wipe existing data
    set image_numbers {}
    set intensities {}
    set fractions {}
    # Check on status of task
    set status_code [$a_dom selectNodes string(//status/code)]

    if {$status_code == "error"} {
	# Report error if it occured
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Cannot calculate phi profile" \
	    -text " [$a_dom selectNodes string(//status/message)]"
	#wm withdraw .pp
    } else {
	# Get the indices, phi, phiwidth and resolutiomn from XML
	set l_h [$a_dom selectNodes normalize-space(//index_h)]
	set l_k [$a_dom selectNodes normalize-space(//index_k)]
	set l_l [$a_dom selectNodes normalize-space(//index_l)]
        # Tried to replot the cross in exact position, but this does not work
        # as cannot access the image display canvas.
        #ImageDisplay::findHKL $l_h $l_k $l_l 
        #ImageDisplay::plotHKL
 
	set l_phi [$a_dom selectNodes normalize-space(//phi)]
	set l_phi_width [$a_dom selectNodes normalize-space(//phi_width)]
	set l_resol [$a_dom selectNodes normalize-space(//resolution)]
        $itk_component(image_l) configure \
	-text "Indices: $l_h $l_k $l_l Phi [format %.2f $l_phi]  width [format %.2f $l_phi_width] resolution [format %.2f $l_resol]"
    
        # Update the status indicators
        $itk_component(activity_l) busy "Getting reflection profile"
        # Clear any previous plot
        $itk_component(phiprofile_graph) delete all
        # Disable controls
        disable
    }
}

body PhiProfile::processPhiProfile { a_dom } {
    if {$::debugging} {
      puts "flow: PhiProfile::processPhiProfile"
    }
    # Check on status of task
    set status_code [$a_dom selectNodes string(//status/code)]

    if {$status_code == "error"} {

	error "[$a_dom selectNodes string(//status/message)]"

    } else {

	# Get the image number and intensity from the xml
	set l_image_number [$a_dom selectNodes normalize-space(//image_number)]
	set l_intensity [$a_dom selectNodes normalize-space(//intensity)]
	set l_fraction [$a_dom selectNodes normalize-space(//fraction_recorded)]


	# Add the new data to the array
       #puts "mydebug: l_image_number in phiprofile is $l_image_number"
	lappend image_numbers $l_image_number
       #puts "mydebug: image_numbers in phiprofile is $image_numbers"
	lappend intensities $l_intensity
	lappend fractions $l_fraction

	# Calculate desired x-axis size
	set max_image_number [lindex $image_numbers end]
       #puts "mydebug: image $l_image_number max_image_number $max_image_number"

	# Calculate graph window
	set x0 10
	set x1 [expr [winfo width $itk_component(phiprofile_graph)] - 10]
	set y0 10
	set y1 [expr [winfo height $itk_component(phiprofile_graph)] - 10]
	set window [list $x0 $y0 $x1 $y1]

	# Calculate the max x value for the graph
        set l_x_max $max_image_number

	# Build datasets
	set l_x_dataset [namespace current]::[Dataset \#auto $image_numbers [Unit::getUnit ""] "Image number" "Image"]
	set l_y_dataset [namespace current]::[Dataset \#auto $intensities [Unit::getUnit ""] "Intensity" "Intensity"]
	set l_y_dataset2 [namespace current]::[Dataset \#auto $fractions [Unit::getUnit ""] "Predicted" "Predicted"]
        if {$::debugging} {
          puts "flow: l_x_dataset is $l_x_dataset"
          puts "flow: l_y_dataset is $l_y_dataset"
        }
        set l_y_datasets [concat $l_y_dataset $l_y_dataset2]
	# Create graph
	#puts "mydebug: PhiProfile calling ScatterGraph l_x_dataset is $l_x_dataset"
	#ScatterGraph \#auto $itk_component(phiprofile_graph) $window phiprofid $l_x_dataset $l_y_datasets -x_axis_limit $l_x_max
	ScatterGraph \#auto $itk_component(phiprofile_graph) $window phiprofid $l_x_dataset $l_y_datasets 
    }
}

body PhiProfile::finalPhiProfile { a_dom } {
    #puts "mydebug: PhiProfile::finalPhiProfile"
    
    # Check on status of task
    set status_code [$a_dom selectNodes string(//status/code)]
# Note, no status_code of "warning" is sent currently from mosflm
    if {$status_code == "warning"} {
	# Report error if it occured
	.m confirm \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Error from phi profile" \
	    -text "The phi profile has not worked for some reason.\nMessage from Mosflm is - [$a_dom selectNodes string(//status/message)].\n"
	wm withdraw .pp
    } else {
	# Get the mosaicity
	set l_mosaicity [$a_dom selectNodes normalize-space(//mosaicity)]
        set l_warning [$a_dom selectNodes normalize-space(//warning)]
        if {$l_warning != ""} {
            #puts "first 4 characters are [string range $l_warning 0 3]"
            if { [string range $l_warning 0 4] == "trunc"} {
              set title "Phi profile truncated"
	    } elseif { [string range $l_warning 0 4] == "not_f"} {
              set title "Reflection not found"
	    } elseif { [string range $l_warning 0 4] == "rejec"} {
              set title "Reflection rejected"
	    }
            if {$l_warning == "truncated_start_too_wide"} {
               set l_message "The phi profile has been truncated at the start and end\nas the reflection extends over more than 50 images and\nalso starts before the first image.\n"
            } elseif {$l_warning == "truncated_end_too_wide"} {
               set l_message "The phi profile has been truncated at the start and end\nas the reflection extends over more than 50 images and\nalso ends after the last image.\n"
            } elseif {$l_warning == "truncated_start"} {
               set l_message "The phi profile has been truncated at the start\nas the reflection starts before the first image.\n"
            } elseif {$l_warning == "truncated_end"} {
               set l_message "The phi profile has been truncated at the end\nas the reflection extends beyond the last image.\n"
            } elseif {$l_warning == "truncated_both"} {
               set l_message "The phi profile has been truncated at both the start and the end\nas the reflection extends beyond the first and the last images.\n"
            } elseif {$l_warning == "too_wide"} {
               set l_message "The phi profile has been truncated at both the start and the end\nas the reflection extends over more than 50 images.\n"
            } elseif {$l_warning == "not_found"} {
               set l_message "Reflection not found for calculation of a phi profile.\nBe sure to click on a predicted reflection.\n"
            } elseif {$l_warning == "rejected"} {
               set l_message "Reflection has been rejected during integration.\nProfile could not be calculated.\n"
            }
	    # Report error if it occured
	    .m confirm \
	        -type "1button" \
	       -button1of1 "Dismiss" \
	        -title $title \
	        -text $l_message
        }	
        # Enable dialog
	enable
    }    
    # Update status
    $itk_component(activity_l) idle
}

body PhiProfile::disable { } {
    #puts "mydebug: PhiProfile::disable"
    $itk_component(mosaicity_e) configure -state disabled
    $itk_component(repeat_b) configure -state disabled
}

body PhiProfile::enable { } {
    #puts "mydebug: PhiProfile::enable"
    $itk_component(mosaicity_e) configure -state normal
    $itk_component(repeat_b) configure -state normal
}

# #############################################################




