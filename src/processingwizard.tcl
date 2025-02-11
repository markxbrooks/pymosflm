# $Id: processingwizard.tcl,v 1.215 2021/08/26 09:13:04 andrew Exp $
package provide processingwizard 1.0

# qtRView released in ccp4-6.4.0

package require qtrv

class Processingwizard {
    inherit itk::Widget

    # Layout sizes
    protected variable margin "7"
    protected variable row_height "182"

    # common to keep track of instances
    common instance_count "0"

    protected variable processing_stage

    # pointer to results object
    protected variable results ""

    # Control variables
    protected variable processing_order "continue"
    protected variable continuation_command ""

    public variable image_numbers {}

    # processing variables
    #protected variable images_being_processed {}
    protected variable block_size ""
    protected variable pass1vars ; # N.B. Array - do initialize!
    protected variable pass2vars ; # N.B. Array - do initialize!

    # arrays associating tree items with parameters
    protected variable items_by_parameter ; # N.B. Array - do not initialize!
    protected variable parameters_by_item ; # N.B. Array - do not initialize!

    # fixing setting variable names
    protected variable fixes_by_parameter ; # Array

    # Images used to display profile
    protected variable profile_small ""
    protected variable profile_large ""

    protected variable current_profile ""

    # canvases for graphs
    protected variable canvases_by_content ; # array
    protected variable zoomed "0"

    # location for saving detector and crystal parameters
    common savedDXparam ; # N.B. Array - do not initialize!

    # treectrl tooltip queue's item
    protected variable last_tooltip_item ""

    protected variable l_numbers {}
    protected variable l_image_numbers {}
    public variable l_image_list {}
    protected variable pointless_only "1"

    # Text passed back from Mosflm to add cell refinement
    # cycle number to interface status messages
    protected variable cycle_message ""

    # Current lattice setting in Lattice combo
    protected variable curr_latt

    # flag for parallel batch run
    protected variable thisIsAParallelBatchRun "0"
    protected variable images_per_block "999999"

    # date stamp each time pointless/aimless/scala/(c)truncate run
    private variable datestamp ""

    # flag to ignore crystal & detector parameter warning popup
    private variable alwaysignore "0"

    # store the image number for last parameter plots and refresh interval
    protected variable plotnum "0"
    private variable refresh "1"
    # checks if distance is to be updated on image by image basis
    private variable updatedist "1"
    # wizard navigation methods
    public method launch
    public method hide
    public method resetControls
    public method clear
    public method clearParamsCentralProfile
    public method updateImages

    public method disable
    public method enable
    protected method toggleAbility

    public method process
    public method saveScript
    public method submitBatch
    public method splitaBatch
    public method submitParallelBatch
    public method processBatch
    protected method getScript
    protected method parallelizeScript
    private method writeScript
    private method validateMatrices
    private method saveDetectorCrystalParams
    private method testDetectorCrystalParams
    private method resetDetectorCrystalParams
    public method loadResults
    public method copyResults
    public method complete

    # uniqueify methods - to replace CCP4 uniqueify which is a Bourne shell script
    private method uniqueify
    private method uniqueMTZ
    private method runUnique
    private method runCad
    private method runFreeRFlagFirst
    private method runFreeRFlagSecond

    # Control methods
    protected method updateProcessButton
    protected method abort
    protected method pause
    protected method continueProcessing
    protected method makeLatticeCombo
    protected method selectLattice

    # Auxiliary processing methods
    public method getImageList
    protected method newResults
    protected method defaultImageSelection
    protected method clearImageSelection
    protected method disableAutoMTZGeneration


    # Feedback processing methods
    public method extractBlockSize
    public method updateProcessingStatus
    public method updatePatternMissets
    public method updateProcessingData
    public method updateProfileData
    public method finishedProcessing

    # Result display methods
    protected method initializeTreesAndGraphs
    protected method updateParameterTreesAndGraphs
    protected method updateParameterTrees
    protected method refreshProfileTree
    protected method updateProfileTree

    protected method paramTreeClick
    protected method plotProcessingGraph
    protected method processCellRefinementSummary
    protected method fixDefaultParameters { } { } ; # virtual

    public method updateProfileSelection
    public method displayProfile

    # zooming methods
    protected method toggleZoom
    protected method restoreGrid
    protected method zoom

    # Tooltips for treectrls
    public method treectrlMotion
    public method treectrlLeave

    public method extractIsolatedImages
    public method runPointless
    public method runScaling
    public method getRefinementTree
    public method getPostrefinementTree
    public method getItemsByParameter
    #public method getImageParameterValue

    constructor { args } { }
}

body Processingwizard::constructor { args } {
    # Build megawidget

    # Toolbars ###############################################

    itk_component add toolbar {
	frame [.c component toolbar_frame].processing[incr instance_count]
    }

    # Divider

    itk_component add divider1 {
	frame $itk_component(toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add view_predictions_tb {
	SettingToolbutton $itk_component(toolbar).vptb "view_predictions_during_processing" \
	    -image ::img::view_predictions16x16 \
	    -activeimage ::img::view_predictions_on16x16 \
	    -balloonhelp "Show predictions on images during processing"
    }

    # Normal frame
    itk_component add normal_f {
	frame $itk_interior.normal
    }

    # Heading

    itk_component add heading_f {
	frame $itk_interior.normal.hf \
	    -bd 1 \
	    -relief solid
    }

    itk_component add heading_l {
	label $itk_interior.normal.hf.fl \
	    -text "" \
	    -font title_font
    } {
	usual
	ignore -font
    }

    # Image selection frame
    itk_component add image_selection_f {
	frame $itk_interior.normal.isf \
	    -bd 2 \
	    -relief raised
    } {
	usual
	keep -borderwidth
    }

    # images entry
    itk_component add images_label {
	label $itk_interior.normal.isf.il
    }

    itk_component add image_numbers_frame {
	frame $itk_interior.normal.isf.inf
    }

    itk_component add lattice_label {
	label $itk_interior.normal.isf.ll \
	-text "Lattice"
    }

    itk_component add lattice_combo {
	combobox::combobox $itk_interior.normal.isf.lc \
	    -width 1 \
	    -editable 0 \
	    -highlightcolor black \
	    -command [code $this selectLattice]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }


    itk_component add default_selection_tb {
	Toolbutton $itk_interior.normal.isf.dstb \
	    -image ::img::auto_image_selection24x24 \
	    -disabledimage ::img::auto_image_selection_disabled24x24 \
	    -type "amodal" \
	    -state "normal" \
	    -balloonhelp " Automatically select images " \
	    -command [code $this defaultImageSelection]
    }

    itk_component add clear_selection_tb {
	Toolbutton $itk_interior.normal.isf.cstb \
	    -image ::img::clear_image_selection24x24 \
	    -disabledimage ::img::clear_image_selection_disabled24x24 \
	    -type "amodal" \
	    -state "normal" \
	    -balloonhelp " Clear image selection " \
	    -command [code $this clearImageSelection]
    }

    itk_component add image_palette_tb {
	Toolbutton $itk_interior.normal.isf.iptb \
	    -image ::img::many_images24x24 \
	    -disabledimage ::img::many_images_disabled24x24 \
	    -type "modal" \
	    -state "normal" \
	    -balloonhelp " Select images... "
    }

    itk_component add image_palette {
	ImagePalette .ip\#auto $itk_component(hull) \
	    -alignwidget $itk_component(images_label)
    } { }

    $itk_component(image_palette_tb) configure \
 	-command [list $itk_component(image_palette) launch $itk_component(image_palette_tb)]

    itk_component add cancel {
	button $itk_interior.normal.isf.cancel \
	    -text "Abort" \
	    -width 7 \
	    -pady 2 \
	    -state "disabled" \
	    -command [code $this abort]
    }
     # puts "flow: add Abort button"
#    if { ![regexp -nocase windows $::tcl_platform(os)] } {
#	# Lunix
#
#	itk_component add process {
#	    ExpandButton $itk_interior.normal.isf.process \
#		-text "Process" \
#		-width 7 \
#		-pady 2 \
#		-command {} ; # To be configured on demand
#	}
#	$itk_component(process) add "Batch" [code $this submitBatch]
#	$itk_component(process) add "Parallel" [code $this submitParallelBatch]
#    } else {
#	# Windows - no Batch processing option
#    	itk_component add process {
#	    button $itk_interior.normal.isf.process \
#		-text "Process" \
#		-width 7 \
#		-pady 2 \
#		-command {} ; # To be configured on demand
#	}
#    }

    # Results frame
    itk_component add results_f {
	frame $itk_interior.normal.rf \
	    -bd 2 \
	    -relief raised
    } {
	usual
	keep -borderwidth
    }

    foreach i_param_class { refinement postrefinement } {
	# Variables trees
	itk_component add ${i_param_class}_tree {
	    treectrl $itk_interior.normal.rf.${i_param_class}_tree \
		-showroot 0 \
		-showline 0 \
		-showbutton 0 \
		-selectmode multiple \
		-width 284 \
		-height $row_height \
		-itemheight 15 \
		-highlightthickness 0 \
		-font font_s
	} {
	    rename -background -textbackground textBackground Background
	    #rename -font -entryfont entryFont Font
	}
	$itk_component(${i_param_class}_tree) column create -text "Parameter" -justify left -minwidth 180 -expand 1
	$itk_component(${i_param_class}_tree) column create -text "Value" -justify right -minwidth 60 -expand 1 -tag value
	$itk_component(${i_param_class}_tree) column create -text "Fix" -justify center -minwidth 30 -expand 1 -tag plot
	$itk_component(${i_param_class}_tree) state define ENABLED
	$itk_component(${i_param_class}_tree) state define CHECKED
	$itk_component(${i_param_class}_tree) element create e_text text -fill {white selected}
	$itk_component(${i_param_class}_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	$itk_component(${i_param_class}_tree) element create e_check image -image { ::img::embed_check_on {ENABLED CHECKED} ::img::embed_check_off {ENABLED !CHECKED} ::img::embed_check_on_disabled {!ENABLED CHECKED} ::img::embed_check_off_disabled {!ENABLED !CHECKED} }
	$itk_component(${i_param_class}_tree) style create s1
	$itk_component(${i_param_class}_tree) style elements s1 { e_highlight e_text }
	$itk_component(${i_param_class}_tree) style layout s1 e_text -expand ns
	$itk_component(${i_param_class}_tree) style layout s1 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
	$itk_component(${i_param_class}_tree) style create s2
	$itk_component(${i_param_class}_tree) style elements s2 {e_highlight e_check}
	$itk_component(${i_param_class}_tree) style layout s2 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
	$itk_component(${i_param_class}_tree) style layout s2 e_check -expand ns -padx {2 2}
	$itk_component(${i_param_class}_tree) style create s3
	$itk_component(${i_param_class}_tree) style elements s3 {e_highlight}
	$itk_component(${i_param_class}_tree) style layout s3 e_highlight -iexpand nsew -ipadx 2

	bind $itk_component(${i_param_class}_tree) <ButtonPress-1> [code $this paramTreeClick $i_param_class %W %x %y]
	bind $itk_component(${i_param_class}_tree) <Motion> [code $this treectrlMotion $i_param_class %W %x %y]
	bind $itk_component(${i_param_class}_tree) <Leave> [code $this treectrlLeave]
	bind $itk_component(${i_param_class}_tree) <ButtonPress-1> [code $this paramTreeClick $i_param_class %W %x %y]
	$itk_component(${i_param_class}_tree) notify bind $itk_component(${i_param_class}_tree) <Selection> [code $this plotProcessingGraph $i_param_class]

	# Canvas
	itk_component add ${i_param_class}_canvas {
	    canvas $itk_interior.normal.rf.${i_param_class}_canvas \
		-relief sunken \
		-borderwidth 2 \
		-width 284 \
		-height $row_height \
		-highlightthickness 0
	} {
	    rename -background -textbackground textBackground Background
	}

	# store canvas in param class's graph canvas list
	set canvases_by_content($i_param_class) $itk_component(${i_param_class}_canvas)
	bind $itk_component(${i_param_class}_canvas) <4> [code $this zoom %W]
	bind $itk_component(${i_param_class}_canvas) <5> [code $this restoreGrid]
	if {[tk windowingsystem] == "aqua"} {
	    bind $itk_component(${i_param_class}_canvas) <Command-ButtonPress-1> [code $this toggleZoom %W]
	} else {
	    bind $itk_component(${i_param_class}_canvas) <Control-ButtonPress-1> [code $this toggleZoom %W]
	}
	bind $itk_component(${i_param_class}_canvas) <Shift-ButtonPress-1> [code $this toggleZoom %W]

	bind $itk_component(${i_param_class}_canvas) <Configure> [code $this plotProcessingGraph $i_param_class]
    }

    itk_component add profile_f {
	frame $itk_interior.normal.rf.pf
    }

    itk_component add profile_tree {
	treectrl $itk_interior.normal.rf.pf.lb \
	    -showbuttons 0 \
	    -showlines 0\
	    -showroot 0 \
	    -width 50 \
	    -height $row_height \
	    -highlightthickness 0 \
	    -font font_s
    } {
	rename -background -textbackground textBackground Background
	#rename -font -entryfont entryFont Font
    }

    $itk_component(profile_tree) column create -text Image -justify right -expand 1
    $itk_component(profile_tree) state define AVAILABLE
    $itk_component(profile_tree) element create e_text text -fill {white {selected AVAILABLE} lightgrey {!AVAILABLE}}
    $itk_component(profile_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(profile_tree) style create s1
    $itk_component(profile_tree) style elements s1 {e_highlight e_text}
    $itk_component(profile_tree) style layout s1 e_text -expand ns
    $itk_component(profile_tree) style layout s1 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(profile_tree) notify bind $itk_component(profile_tree) <Selection> [code $this updateProfileSelection %S]

    itk_component add profile_sb {
	scrollbar $itk_interior.normal.rf.pf.sb \
	    -command [code $this component profile_tree yview] \
	    -orient vertical
    }

    $itk_component(profile_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(profile_sb)]

    itk_component add profile_c {
	canvas $itk_interior.normal.rf.pf.c \
	    -background white \
	    -relief sunken \
	    -borderwidth 2 \
	    -height $row_height \
	    -highlightthickness 0
    }
    # store canvas in param class's graph canvas list
    set canvases_by_content(profile) $itk_component(profile_c)
    # Setup bindings to refresh profile when canvas changes
    bind $itk_component(profile_c) <Configure> [code $this displayProfile]
    bind $itk_component(profile_c) <4> [code $this zoom $itk_component(profile_f)]
    bind $itk_component(profile_c) <5> [code $this restoreGrid]
    if {[tk windowingsystem] == "aqua"} {
	bind $itk_component(profile_c) <Command-1> [code $this toggleZoom $itk_component(profile_f)]
    } else {
	bind $itk_component(profile_c) <Control-1> [code $this toggleZoom $itk_component(profile_f)]
    }
    bind $itk_component(profile_c) <Shift-1> [code $this toggleZoom $itk_component(profile_f)]

    # Add alternative frame
    itk_component add alt_f {
	frame $itk_interior.alt
    }

    # Add alt canvas
    itk_component add alt_c {
	canvas $itk_interior.alt.c \
	    -bg white \
	    -relief sunken \
	    -borderwidth 2 \
	    -highlightthickness 0
    }
    bind $itk_component(alt_c) <1> [code $this dropCanvas]

    # Toolbar
    pack $itk_component(divider1) \
	-side left \
	-fill y \
	-padx 5 \
	-pady 1
    pack $itk_component(view_predictions_tb) \
	-side left \
	-padx 2

    # Layout

    # Normal frame
    pack $itk_component(normal_f) -side top -fill both -expand 1

    # Heading
    pack $itk_component(heading_f) -side top -fill x -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5

    # Image selection
    pack $itk_component(image_selection_f) -side top -fill x -pady 1 -padx $margin
    pack $itk_component(lattice_label) -side left -pady 6
    pack $itk_component(lattice_combo) -side left -pady 6
    pack $itk_component(images_label) -side left -anchor n -pady 10
    pack $itk_component(image_numbers_frame) -side left -fill x -expand 1 -anchor n -pady 6
    pack $itk_component(default_selection_tb) -side left
    pack $itk_component(clear_selection_tb) -side left
    pack $itk_component(image_palette_tb) -side left
#    pack $itk_component(process) -side right -pady $margin -padx $margin
    pack $itk_component(cancel) -side left -pady $margin -padx [list $margin 0]

    # Results frame
    pack $itk_component(results_f) -side top -fill both -expand 1

    grid x $itk_component(refinement_tree) x  $itk_component(refinement_canvas) x $itk_component(profile_f) x -sticky nsew -pady [list $margin 0]
    grid x $itk_component(postrefinement_tree) x $itk_component(postrefinement_canvas) x -sticky nsew -pady $margin
    grid columnconfigure $itk_component(results_f) { 0 2 4 6 } -minsize $margin
    grid columnconfigure $itk_component(results_f) { 3 5 } -weight 1
    grid rowconfigure $itk_component(results_f) { 0 1 } -weight 1

    # Profile frame
    grid $itk_component(profile_tree) $itk_component(profile_sb) $itk_component(profile_c) -sticky nswe
    grid columnconfigure $itk_component(profile_f) 2 -weight 1
    grid rowconfigure $itk_component(profile_f) 0 -weight 1



    # Alternative frame contents
    pack $itk_component(alt_c) -side top -fill both -expand 1 -padx $margin -pady $margin

    # Setup information for tables and graphs

    # Create temporary results object to create tree items from
    set t_results [newResults]

    foreach i_param_class { refinement postrefinement } {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    # create a new item
	    set t_param_item [$itk_component(${i_param_class}_tree) item create]
	    # set the items state as enabled
	    $itk_component(${i_param_class}_tree) item state set $t_param_item ENABLED
	    # set the item's style
	    $itk_component(${i_param_class}_tree) item style set $t_param_item 0 s1 1 s1
	    if {[Processingresults::parameterIsFixable $i_param]} {
		$itk_component(${i_param_class}_tree) item style set $t_param_item 2 s2
		set fixable_parameters_by_item($i_param_class,$t_param_item) $i_param
	    } else {
		$itk_component(${i_param_class}_tree) item style set $t_param_item 2 s1
	    }

	    # update the item's text
	    if { $i_param == "beam_y_corrected" } {
		$itk_component(${i_param_class}_tree) item text $t_param_item 0 "" 1 ""
	    } {
		$itk_component(${i_param_class}_tree) item text $t_param_item 0 [$t_results getParameterName $i_param] 1 ""
	    }
	    # add the new item to the tree
	    $itk_component(${i_param_class}_tree) item lastchild root $t_param_item

	    # Store pointer to image objects and items by bumber, item or object
	    set items_by_parameter($i_param) $t_param_item
	    set parameters_by_item($i_param_class,$t_param_item) $i_param
	    #puts $i_param
	}
    }
    # delete temporary results object
    delete object $t_results

    # Make default graphing selection
    $itk_component(refinement_tree) selection add $items_by_parameter(tilt) $items_by_parameter(twist)

    $itk_component(postrefinement_tree) selection add $items_by_parameter(phi_x) $items_by_parameter(phi_z)
    $itk_component(postrefinement_tree) selection add $items_by_parameter(mosaicity)

    # Fix default parameters
    fixDefaultParameters

    eval itk_initialize $args
}

# Image tree interaction methods

body Processingwizard::updateProcessButton { } {
    set l_check_count 0
    foreach i_sector [$itk_component(image_tree) item children root] {
	foreach i_image [$itk_component(image_tree) item children $i_sector] {
	    if {[$itk_component(image_tree) item state get $i_image CHECKED]} {
		incr l_check_count
	    }
	}
    }
    if {$l_check_count > 0} {
	$itk_component(process) configure -state "normal"
        # puts "flow: configure state normal"
    } else {
	$itk_component(process) configure -state "disabled"
        # puts "flow: configure state disabled"
    }
}


# Wizard navigation methods ######################################

body Processingwizard::launch { } {
    if {$::debugging} {
        puts "flow: Entering Processingwizard::launch"
    }
    #puts "PWlaunch: cell [[$::session getCell] listCell]"
    # Make default image selection whatever in case numbers left in field are not appropriate?
    if {[$itk_component(image_numbers) getContent] == {}} {
	defaultImageSelection
    }

    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    # show toolbars
    pack $itk_component(toolbar) -in [.c component toolbar_frame] -side left

    # Trap for no Mosaicity set
    if { [$::session forceMosaicityEstimation] } {
	# It has worked - user sees .me launched
    } else {
	# It has failed
	.m confirm \
	    -title "Mosaicity not set" \
	    -type "1button" \
	    -button1of1 "Ok" \
	    -text "The mosaicity cannot be estimated.\nPlease return to an earlier stage of processing."
    }

    # Reset unzoomed view
    restoreGrid

    # Make lattice selector if not processing
    if {![$::session getRunningProcessing]} {
	makeLatticeCombo
    }

}

body Processingwizard::makeLatticeCombo { } {
    # Get the list of lattice numbers
    set latt_list [$::session getLatticeList]
    set curr_latt [$::session getCurrentLattice]
    #puts "makeLatticeCombo: $latt_list current $curr_latt"
    $itk_component(lattice_combo) list delete 0 end
    # Get the number of lattices
    set n_lattices [$::session getNumberLattices]
    if { $n_lattices == 1 } {
	$itk_component(lattice_label) configure -state disabled
	$itk_component(lattice_combo) configure -state disabled
    } else {
	eval $itk_component(lattice_combo) list insert 0 $latt_list
	eval $itk_component(lattice_combo) select [lsearch $latt_list $curr_latt]
	$itk_component(lattice_label) configure -state normal
	$itk_component(lattice_combo) configure -state normal
    }
}

body Processingwizard::selectLattice { a_combo lattice } {

    # Update via Indexwizard and thereby update Image display lattice combo and lattice predictions
    set item [.c component indexing getItemByLattice $lattice]
    if {$item != "" } {
	# Is lattice required different from the current lattice - if so update Image display
	set current_lattice [$::session getCurrentLattice]
	if { $lattice != $current_lattice} {
	    #puts "PWselectLattice: lattice $lattice current_lattice $current_lattice toggling Indexwizard ..."
	    [.c component indexing] toggleLatticeSelection $item
	}
    }

    # Adjust the MTZ file name for this lattice if we have multiple lattices
    set l_mtz_file [$::session getParameterValue mtz_file]
    if { ( $l_mtz_file ne "" ) && ( [$::session getNumberLattices] > 1 ) } {
	#puts "old: $l_mtz_file"
	set prefix [file root $l_mtz_file]
	# If 'lattice' does not exist in the prefix append it
	if { ![regexp lattice $prefix] } {
	    set prefix ${prefix}_lattice${lattice}
	}
	# Set the correct lattice in the name as the character following the first occurrence of 'lattice'
	regsub "lattice\[1-9\]" $prefix "lattice${lattice}" new_name
	set new_mtz $new_name.mtz
	#puts "new: $new_mtz"
	$::session updateSetting "mtz_file" $new_mtz 1 1
    }
    # Recall the last results for this lattice or clear the processing pane
    set results [$::session getLatticeResultsObject $processing_stage $lattice]
    if { $results != ""} {
	#puts "selectLattice: lattice $lattice loading $processing_stage results: $results"
	[.c component $processing_stage] loadResults $results
    } else {
	#puts "no results yet, need to clear the $processing_stage pane here ..."
	[.c component $processing_stage] emptyplots
    }
}

body Processingwizard::hide { } {
    # Hide the wizard
    grid forget $itk_component(hull)
    # Hide the toolbar
    pack forget $itk_component(toolbar)
}

body Processingwizard::resetControls { } {
    # Reset processing button
    $itk_component(process) configure \
	-text "Process" \
	-command [code $this process]
    # puts "flow: Processingwizard::resetControls"
    # Reset cancel button
    $itk_component(cancel) configure -state "disabled"
}

body Processingwizard::clear { } {
    # Clear image number widget
    $itk_component(image_numbers) clear

    # General clear of parameters and central profile tree and plot
    clearParamsCentralProfile
}

body Processingwizard::clearParamsCentralProfile { } {

    foreach i_param_class { refinement postrefinement } {
	# Clear parameter values
	foreach i_item [$itk_component(${i_param_class}_tree) item children root] {
	    $itk_component(${i_param_class}_tree) item text $i_item 1 ""
	}
	# Clear graphs
	$itk_component(${i_param_class}_canvas) delete all
	bind $itk_component(${i_param_class}_canvas) <Configure> {}
    }
    # Clear profile trees
    $itk_component(profile_tree) item delete all
    $itk_component(profile_c) delete all
    bind $itk_component(profile_c) <Configure> {}
}

body Processingwizard::updateImages { an_image_list args } {

    # Build an array of lists of image numbers by template
   #puts ""
   #puts "Entering updateImages version740 with processing_stage: $processing_stage"
    #puts "an_image_list is: $an_image_list"

    foreach i_sector [$::session getSectors] {
       #puts "setting l_image_numbers_by_template null for i_sector:  $i_sector"  
	set l_image_numbers_by_template([$i_sector getTemplate]) {}
    }
    foreach i_image $an_image_list {
	if { ![catch "$i_image getTemplate" message ]} {
	   #puts "for image $i_image template is: $message"
	    lappend l_image_numbers_by_template([$i_image getTemplate]) [$i_image getNumber]
	}
	#puts "scope is: [scope $i_image] [$i_image getNumber]"
    }
    # update the image numbers widget
    # this needs to be done this way because of the way arrays are stored.
   #puts "About to call session getCurrentSector from updateImages"
    set current_sector [$::session getCurrentSector]
   #puts "111 current sector is $current_sector"
    foreach i_sector [$::session getSectors] {
       #puts ""
       #puts "in loop over sectors, i_sector is: $i_sector"
	set i_template [$i_sector getTemplate]
	#puts "template for this sector is: $i_template"
	set l_image_numbers [compressNumList $l_image_numbers_by_template($i_template)]
	#puts "image numbers for this sector are:  $l_image_numbers"
	if { $l_image_numbers != {} } {
           #puts "Update image numbers in GUI"
	    $itk_component(image_numbers) updateSector $i_template $l_image_numbers
	}
    }

    # then set current working sector if integrating, not if refinement
   #puts ""
   #puts "About to get template for current_sector: $current_sector"
    set i_template [$current_sector getTemplate]
   #puts ""
   #puts "Current working sector template: $i_template"

    set l_input_numbers {}
    set l_input_numbers $l_numbers
   #puts "l_input_numbers after setting to l_numbers: $l_input_numbers"
    set l_image_numbers {}
    set l_input_numbers [compressNumList $l_input_numbers]
   #puts "about to set l_image_numbers from l_image_numbers_by_template using template: $i_template"
    set l_image_numbers [compressNumList $l_image_numbers_by_template($i_template)]
   #puts "Updated l_image_numbers is: $l_image_numbers"

    if {$l_input_numbers != {} && [$::session getParameterValue "wait_activation"]} {
	#puts "WAIT IS ACTIVE"
	if {$l_image_numbers != {}} {
	    set l_image_numbers $l_input_numbers
	}
       #puts "l_image_numbers has been updated using l_input_numbers to give: $l_image_numbers"
    }
    if { $processing_stage != "cell_refinement" } { 
       #puts "About to update GUI image numbers for template $i_template with l_image_numbers: $l_image_numbers"
        $itk_component(image_numbers) updateSector $i_template $l_image_numbers
    }
   #puts "222 current_sector is: $current_sector"
    if { $current_sector != "" && $l_image_numbers == {} } {
       #puts "l_image_numbers is null for current sector: $current_sector"
	set l_image_numbers {}
	foreach i_image [$current_sector getImages] {
	    lappend l_image_numbers [$i_image getNumber]
	}
	if { $l_image_numbers != {} } {
	    $itk_component(process) configure -state normal
            set l_image_numbers [compressNumList $l_image_numbers]
           #puts "flow: in Processingwizard::updateImages 222 current_sector is: $current_sector"
	}
        if { $processing_stage != "cell_refinement" } { 
           #puts "About to update GUI image numbers for template $i_template with l_image_numbers: $l_image_numbers"
	    $itk_component(image_numbers) updateSector $i_template $l_image_numbers
        }
    }

    # Enable / disable controls appropriately
    if {$an_image_list != {} || $l_image_numbers != {}} {
	# Take account of the incoming image list or, if empty, that constructed from the sector above
	if {![regexp "pause" "[$itk_component(process) cget -command]"] && ![regexp "continue" "[$itk_component(process) cget -command]"] } {
	    #puts "I DID IT"
	    # Enable processing button
	    $itk_component(process) configure \
	    	-state normal \
	    	-command [code $this process]
            #puts "flow: in Processingwizard::updateImages Enable / disable controls"
	}
    } else {
	$itk_component(process) configure -state disabled
    }

    #puts [$itk_component(process) cget -command]

   #puts "mydebug: at end of processingwizard:update images, l_image_numbers is  $l_image_numbers"
}

body Processingwizard::clearImageSelection { } {
    set current_sector [$::session getCurrentSector]
    #puts "In clearImageSelection, current_sector set to $current_sector" 
    # clear all the rest first
    foreach i_sector [$::session getSectors] {
	if { $i_sector != [$::session getCurrentSector] } {
	    set i_template [$i_sector getTemplate]
	    $itk_component(image_numbers) updateSector $i_template {}
	}
    }
    # then set current working sector specifically
    $::session setCurrentSector $current_sector
    set i_template [$current_sector getTemplate]
    $itk_component(image_numbers) updateSector $i_template {}
    $itk_component(process) configure -state "disabled"
}

body Processingwizard::disable { } {
    toggleAbility "disabled"
}

body Processingwizard::disableAutoMTZGeneration { } {

    #puts [$itk_component(mtz_file_e) getValue]
    $itk_component(auto_update_mtz_tb) cancel
}

body Processingwizard::enable { } {
    toggleAbility "normal"
}

body Processingwizard::toggleAbility { a_state } {
    $itk_component(image_numbers) configure -state $a_state
    $itk_component(default_selection_tb) configure -state $a_state
    $itk_component(clear_selection_tb) configure -state $a_state
    $itk_component(image_palette_tb) configure -state $a_state
    $itk_component(process) configure -state $a_state
}

body Processingwizard::saveDetectorCrystalParams { } {

    # Lists for saving & resetting if refined to physically unreasonable values

    #Beam X,Y, Detector distance, twist & tilt, Yscale
    #Detector two-theta (not currently refined, but may be in future)
    #Separation parameters (this can also be corrupted)
    #Raster (measurement box) parameters (ditto)
    #Mosaic spread
    set param_list { beam_x beam_y beam_y_corrected distance yscale tilt twist tangential_offset radial_offset two_theta spot_separation_x spot_separation_y raster_nxs raster_nys raster_nc raster_nrx raster_nry mosaicity }
    foreach i_param $param_list {
	# Try to get the parameter value from the session
	if {![catch {set param [$::session getParameterValue $i_param]}]} {
	    #puts "save: $i_param $param"
	    set savedDXparam($i_param) $param
	} else {
	    #puts "save: no value for $i_param"
	}
    }

    #Unit cell parameters (in case this was a cell refinement run)
    set i 0
    set cell_list [$::session listCell]
    foreach i_param { cell_a cell_b cell_c cell_alpha cell_beta cell_gamma } {
	set param [lindex $cell_list $i]
	if { $param != "" } {
	    #puts "save: $i_param $param"
	    set savedDXparam($i_param) $param
	} else {
	    #puts "save: no value for $i_param"
	}
	incr i
    }

    #Missets (just the current PHIX, PHIY, PHIZ)
    # Find the first image
    set l_image_field_contents [lindex [.c component $processing_stage component image_numbers getContent] 0]
    #puts "l_image_field_contents $l_image_field_contents"
    if { $l_image_field_contents != "" } {
	set local_template [lindex $l_image_field_contents 0]
	set l_local_image_numbers [lindex $l_image_field_contents 1]
	set local_first_image_number [lindex $l_local_image_numbers 0]
	set local_first_image [$::session getImageByTemplateAndNumber $local_template $local_first_image_number]
	set i 0
	set misset_list [$local_first_image getMissets]
	foreach i_param { phi_x phi_y phi_z } {
	    set param [lindex $misset_list $i]
	    if { $param != "" } {
		#puts "save: $i_param $param"
		set savedDXparam($i_param) $param
	    } else {
		#puts "save: no value for $i_param"
	    }
	}
    }
    #puts "saveDetectorCrystalParams\n[array names savedDXparam]"
}

body Processingwizard::testDetectorCrystalParams { } {

    #puts "testDetectorCrystalParams\n[array names savedDXparam]"

    # 1. Detector tilt and twist. Absolute magnitude greater than 0.5 degrees gives
    # initial warning, absolute magnitude greater than 0.8 gives serious warning.

    set caution_limit 0.5
    set serious_limit 0.8
    set units degrees

    set param_list { tilt twist }
    foreach i_param $param_list {
	set response_[set i_param] ""
	# Try to get the parameter value from the session
	if {![catch {set param [$::session getParameterValue $i_param]}]} {
	    #puts "test: $i_param now $param was $savedDXparam($i_param)"
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
		set response caution
		if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		    set response serious
		}
		set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
	    }
	} else {
	    #puts "test: no value for $i_param in session"
	}
    }

    #1a. Radial_offset & tangential_offset. Cautionary should be absolute value greater than 0.3, critical
    # absolute value greater than 0.6.

    set caution_limit 0.3
    set serious_limit 0.6
    set units mm

    set param_list { tangential_offset radial_offset }
    foreach i_param $param_list {
	set response_[set i_param] ""
	# Try to get the parameter value from the session
	if {![catch {set param [$::session getParameterValue $i_param]}]} {
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
		set response caution
		if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		    set response serious
		}
		set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
		#puts "test: $i_param now $param was $savedDXparam($i_param)"
	    }
	} else {
	    #puts "test: no value for $i_param in session"
	}
    }

    #2. Yscale. Deviation great than 1.0 by more 0.005 gives initial warning, by
    #more than 0.01 gives serious warning.

    set caution_limit 0.005
    set serious_limit 0.01
    set units ""

    # Try to get the parameter value from the session
    set i_param yscale
    set response_[set i_param] ""
    if {![catch {set param [$::session getParameterValue $i_param]}]} {
	if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
	    set response caution
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		set response serious
	    }
	    set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
	}
	#puts "test: $i_param now $param was $savedDXparam($i_param)"
    } else {
	#puts "test: no value for $i_param in session"
    }

    # 3. Distance. Deviation from initial value greater than 2mm gives initial
    # warning, greater than 5mm gives serious warning.

    set caution_limit 2
    set serious_limit 5
    set units mm

    # Try to get the parameter value from the session
    set i_param distance
    set response_[set i_param] ""
    if {![catch {set param [$::session getParameterValue $i_param]}]} {
	if { [expr {abs($param - $savedDXparam($i_param))}] > $caution_limit } {
	    set response caution
	    if { [expr {abs($param - $savedDXparam($i_param))}] > $serious_limit } {
		set response serious
	    }
	    set response_[set i_param] "$i_param now $param was $savedDXparam($i_param) and exceeds $response limit of [set [set response]_limit] $units\n"
	}
	#puts "test: $i_param now $param was $savedDXparam($i_param)"
    } else {
	#puts "test: no value for $i_param in session"
    }

    # All three parameters should be checked and the warning level set to the highest of the three.
    return [list $response_tilt $response_twist $response_yscale $response_distance]
}

body Processingwizard::resetDetectorCrystalParams { } {
    #puts "processing stage is $processing_stage"

    # Lists for saving & resetting if refined to physically unreasonable values

    #Beam X,Y, Detector distance, twist & tilt, Yscale
    # ** NOTE WELL ** Distance not reset until confirmed below for cell refinement
    #Detector two-theta (not currently refined, but may be in future)
    #Separation parameters (this can also be corrupted)
    #Raster (measurement box) parameters (ditto)
    #Mosaic spread
    if { $processing_stage == "cell_refinement" } {
       set param_list { beam_x beam_y beam_y_corrected yscale tilt twist tangential_offset radial_offset two_theta spot_separation_x spot_separation_y raster_nxs raster_nys raster_nc raster_nrx raster_nry mosaicity }
    } else {
       set param_list { beam_x beam_y beam_y_corrected distance yscale tilt twist tangential_offset radial_offset two_theta spot_separation_x spot_separation_y raster_nxs raster_nys raster_nc raster_nrx raster_nry mosaicity }
    }
    foreach i_param $param_list {
	# Reset the parameter value for the session
	if {[info exists savedDXparam($i_param)]} {
	   #puts "reset: $i_param reset from [$::session getParameterValue $i_param] to $savedDXparam($i_param)"
	    $::session updateSetting $i_param $savedDXparam($i_param) 1 1 "User"
	} else {
	   #puts "reset: no value stored for $i_param"
	}
    }

    if { $processing_stage == "cell_refinement" } {
                .m configure \
                    -title "Reset cell parameters" \
                    -type "2button" \
                    -text "Do you want to revert to the original cell parameters? \nIf only the distance has changed significantly the refined cell may be correct.\nSelecting Yes will reset the cell and the distance.\nSelecting No will keep the refined cell and the refined distance." \
                    -button1of2 "Yes" \
                    -button2of2 "No"
                set updatedist 0        
                if {[.m confirm]} {
                    # Revert to original cell and distance
                    #Unit cell parameters (in case this was a cell refinement run)
                    set i 0
                    set reset 0
                    set updatedist 1        
                    set cell_list {}
                    foreach i_param { cell_a cell_b cell_c cell_alpha cell_beta cell_gamma } {
	               if {[info exists savedDXparam($i_param)]} {
	                    lappend cell_list $savedDXparam($i_param)
	                    incr reset
	                   } else {
	                   #puts "reset: no value stored for $i_param"
  	                   }
	               incr i
                    }
                    # Check all cell parameters could be reset to stored values
                    if { $reset == 6 } {
	                set cell [$::session getCell]
	                #puts "reset: Old cell [$::session listCell]\nNew cell $cell_list"
	                eval $cell setCell $cell_list
                        $::session updateCell "Cell_refinement" $cell
                    }
                    set param_list {  distance }
                    foreach i_param $param_list {
	               # Reset the distance for the session
	               if {[info exists savedDXparam($i_param)]} {
	               #puts "reset: $i_param reset from [$::session getParameterValue $i_param] to $savedDXparam($i_param)"
	               $::session updateSetting $i_param $savedDXparam($i_param) 1 1 "User"
	               } else {
	                   #puts "reset: no value stored for $i_param"
	               }
                    }
                }
    }

    #Missets (just the current PHIX, PHIY, PHIZ)
    # Find the first image
    set l_image_field_contents [lindex [.c component $processing_stage component image_numbers getContent] 0]
    #puts "l_image_field_contents $l_image_field_contents"
    set local_template [lindex $l_image_field_contents 0]
    set l_local_image_numbers [lindex $l_image_field_contents 1]

    foreach i_param { phi_x phi_y phi_z } {
	set [set i_param] 0
	if {[info exists savedDXparam($i_param)]} {
	    set [set i_param] $savedDXparam($i_param)
        } else {
	   #puts "reset: no value stored for $i_param"
        }
    }

    foreach imageno $l_local_image_numbers {
	set l_image [$::session getImageByTemplateAndNumber $local_template $imageno]
	if {[$l_image hasMissets]} {
	    #puts "Image $imageno has missets [$l_image getMissets]"
	    $l_image updateMissets $phi_x $phi_y $phi_z 1 1 "Processing" [$::session getCurrentLattice]
	    #puts "      now reset to missets [$l_image getMissets]"
	}
    }

    # Finally, some Mosflm keywords reset behind the scenes
    $::mosflm sendCommand "DISTORTION XTOFRA 1.0"
    $::mosflm sendCommand "CAMCON CCX 0.0 CCY 0.0 CCOM 0.0"

    #puts "resetDetectorCrystalParams\n[array names savedDXparam]"
    #puts "resetting params for images, updatedist is $updatedist"
    if { $updatedist == 1 } {
	set param_list { beam_x beam_y beam_y_corrected distance yscale tilt twist tangential_offset radial_offset }
    } else {
#    *** remove distance from the list ***
	set param_list { beam_x beam_y beam_y_corrected yscale tilt twist tangential_offset radial_offset }
    }
    foreach i_param $param_list {
        foreach image $l_image_list {
	    # Reset the value stored in each image to its saved value
            #puts "$i_param for image [$image getNumber] stored as [$image getValue $i_param] resetting to $savedDXparam($i_param)"
            eval $image setValue $i_param $savedDXparam($i_param)
        }
    }
}

# Processing methods #############################################

body Processingwizard::process { args } {
    if {$::debugging} {
        puts "flow: Entering Processingwizard::process"
    }
    #puts "Start: [clock format [clock seconds] -format "%H:%M:%S"] $processing_stage"
    # If no matrix for this sector disable processing stages
    if { ![[[$::session getCurrentSector] getMatrix] isValid] } {
	.m confirm \
	    -title "No valid matrix exists" \
	    -type "1button" \
	    -button1of1 "Ok" \
	    -text "No matrix for sector [[$::session getCurrentSector] getTemplate]\nCannot perform $processing_stage operation."
	#puts "No valid matrix for sector [[$::session getCurrentSector] getTemplate] - aborting $processing_stage"
	return
    }
    if { $thisIsAParallelBatchRun != 0 } {
#    puts " thisIsAParallelBatchRun is $thisIsAParallelBatchRun"
	Integrationwizard::initializeTreesAndGraphs
    }
   
    set thisIsAParallelBatchRun "0"
#    puts " thisIsAParallelBatchRun is $thisIsAParallelBatchRun"

    # Check list of images to be processed
#    puts "***** l_image_list at start of Process [getImageList]"

    # Save copies of initial detector & crystal parameters once only
    #puts "savedXDparams: [$::session getXDparamsSaved]"
    if { [$::session getXDparamsSaved] == 0 } {
        if {$::debugging} {
            puts "flow: in ::process saveDetectorCrystalParams"
        }
	saveDetectorCrystalParams
	#$::session setXDparamsSaved 1 - weird has not existed lately
    }

    if {$processing_stage == "integration"} {
        if {$::debugging} {
            puts "flow: processing stage is integration"
        }
	$::session setIntegrationRun "0"
	$::session initialisePMon
	set plotnum 0
	if {[$::session getParameterValue "wait_activation"]} {
	    set l_image_field_contents [lindex [.c component integration component image_numbers getContent] 0]
	    set local_template [lindex $l_image_field_contents 0]
	    set l_local_image_numbers [lindex $l_image_field_contents 1]

	    set local_first_image_number [lindex $l_local_image_numbers 0]
	    set local_first_image [$::session getImageByTemplateAndNumber $local_template $local_first_image_number]
	    set local_image_directory [$local_first_image getDirectory]
	    set local_gain [$::session getParameterValue gain]

	    #puts "THE DIRECTORY is $local_image_directory"

	    foreach i_local_image_number $l_local_image_numbers {
		set i_local_image [$::session getImageByTemplateAndNumber $local_template $i_local_image_number]
		if {$i_local_image != ""} {
		    set i_local_phis [$i_local_image getPhi]
		    set i_local_phi_start [lindex $i_local_phis 0]
		    set i_local_phi_end [lindex $i_local_phis 1]
		    #puts [$::session getImageByTemplateAndNumber $local_template $i_local_image_number]
		    #puts "image $i_local_image_number exists"
		} else {
		    set i_local_phi_slice [expr {$i_local_phi_end - $i_local_phi_start}]
		    set i_local_phi_start $i_local_phi_end
		    set i_local_phi_end [expr {$i_local_phi_start + $i_local_phi_slice}]
		    set i_local_filename [::filenameFromTemplate $local_template $i_local_image_number]
		    set i_local_full_path [file join $local_image_directory $i_local_filename]
		    set wait_xml "<?xml version='1.0'?><!DOCTYPE brief_header_response><brief_header_response><status><code>ok</code></status><image_filename>$i_local_full_path</image_filename><phi_start>      [format %.2f $i_local_phi_start]</phi_start><phi_end>      [format %.2f $i_local_phi_end]</phi_end><gain>   $local_gain</gain></brief_header_response>"
		    set wait_dom [dom parse $wait_xml]
		    $::session processWaitBriefHeaderData $wait_dom
		}
	    }
	}
	$itk_component(mtz_file_e) publicUploadToSessionIfChanged

	# Check against overwriting previous MTZ file
	set l_mtz_file [$::session getParameterValue mtz_file]
	if { ![$::session getParameterValue mtz_overwrite] && [file exists [file join [$::session getParameterValue mtz_directory] "$l_mtz_file"]] } {
	    .m configure \
		-type "2button" \
		-title "File already exists" \
		-text "File $l_mtz_file exists.\nDo you want to overwrite it?" \
		-button1of2 "Yes" \
		-button2of2 "No"

	    if {![.m confirm]} {
		# Get new file name from user
		if {![winfo exists .chooseAuxFile]} {
		    Fileopen .chooseAuxFile \
			-type save \
			-title "Save MTZ file as" \
			-initialdir [pwd] \
			-filtertypes {{"MTZ files" {.mtz}}}
		}
		set l_mtz_file [.chooseAuxFile get]
		if { $l_mtz_file != "" } {
		    disableAutoMTZGeneration
		    $itk_component(mtz_file_e) update [file tail $l_mtz_file]
		    $::session updateSetting "mtz_file" [file tail $l_mtz_file] 1 1
		} else {
		    # Empty MTZ filename got
		    return
		}
	    } else {
		$::session updateSetting mtz_overwrite 1 0 0 "Processing options"
	    }
	}
	$::session addCCP4i2file "mosflm_mtzfile" "[file tail [$::session getParameterValue mtz_file]]"
    }

    # Get list of images to be processed
    set l_image_list [getImageList]

    if {$l_image_list != {}} {

	if {$processing_stage == "cell_refinement"} {
            if {$::debugging} {
                puts "flow: processing stage is cell_refinement"
                puts "flow: and image list is $l_image_list"
            }
	    # Attempt to spot any isolated images given and remove them from use in cell refinement
	    set l_new {}
	    set l_good {}
	    set l_isolated {}
	    # Build array of templates used and the images from each
	    array unset images_by_template
	    foreach image $l_image_list {
		set template [$image getTemplate]
		lappend images_by_template($template) $image
	    }
	    foreach template [array names images_by_template] {
		# Get the number & list of any isolated images followed by the list of non-isolated images
		set fullresult [extractIsolatedImages $images_by_template($template) $template]
		# fullresult contains n_isol l_isolated l_image_list
		set number_isolated [lindex $fullresult 0]
		set l_isolated [lrange $fullresult 1 $number_isolated]
		set l_good [lrange $fullresult [expr $number_isolated + 1] end]
		if { $number_isolated > 0 } {
		    .m confirm \
			-title "Isolated images detected" \
			-type "1button" \
			-button1of1 "Ok" \
			-text "Images $l_isolated\nwill not be used in cell refinement.\nIf these numbers were not entered by you\nplease inform the iMosflm developers."
		    #puts "$number_isolated isolated images found: $l_isolated"
		}
		foreach image $l_good {
		    lappend l_new $image
		}
		#puts "new list: $l_new"
	    }
	    if { [llength $l_new] == 0 } {
		# dont have any images left after removal of isolated images
		return
	    } else {
		set l_image_list $l_new
	    }
	} else {
	    # Set plot updating after each 5% of total which is then
	    # adjusted in updateProcessingData if block_size is less
	    set refresh [expr int([expr ([llength $l_image_list] * 0.05)])]
	    # Catch a divide by zero in cases of < 20 images to be processed
	    #puts "Pw:process refresh calculated as $refresh"
	    if { $refresh == 0 } { set refresh 1 }
	}

	# Make sure matrices are present, or if not use first matrix
	validateMatrices $l_image_list

	# Disable fixing checkbuttons
	foreach i_param_class { refinement postrefinement } {
	    foreach i_param [Processingresults::getParameters $i_param_class] {
		if {[Processingresults::parameterIsFixable $i_param]} {
		    $itk_component(${i_param_class}_tree) item state set $items_by_parameter($i_param) !ENABLED
		}
	    }
	}

	# Reset the processing command to continue by default
	set processing_order "continue"

	# create results object (auto initialized)
	if {$results != ""} {
#	    puts "Is $results an object? >>>[itcl::is object $results]<<<"
#            puts "Processingwizard::process deleting object $results"
	    delete object $results
	    set results ""
	}
	set results [eval newResults $l_image_list]
	#puts "Processingwizard::process results object created $results"

	# initialize trees and graphs
	initializeTreesAndGraphs

	# Disable ALL controls
	.c disable

	# disable controls button
	#disable

	# Reconfigure process button as pause button
	if { "$processing_stage" == "integration" } {
	    if { ![regexp -nocase windows $::tcl_platform(os)] } {
		# Lunix - Expandbutton can have a semi state
		$itk_component(process) configure \
		    -state "semi" \
		    -text "Pause" \
		    -command [code $this pause]
	    } else {
		# Windows - normal button not an Expandbutton
		$itk_component(process) configure \
		    -state "normal" \
		    -text "Pause" \
		    -command [code $this pause]
	    }
	}

	# Enable cancel button
	$itk_component(cancel) configure -state "normal"

	# send mosflm command
	set curr_latt [$::session getCurrentLattice]

	# Now branch according to the state of the Pattern matching orientation refinement checkbox
	if { [.ats component advanced_refinement getPatternMatchingBool] == 0 } {
	    if {$processing_stage == "integration"} {
	    # Update status
		.c busy "Integrating"
                # puts "debug: about to call mosflm::integrate from processingwizard"
		eval $::mosflm integrate $curr_latt [list $l_image_list] $l_image_numbers
                # puts "debug: have now called mosflm::integrate from processingwizard"
	    } else {
	    # Update status
                if {$::debugging} {
                    puts "flow: About to call ::mosflm refineCell"
                }
		.c busy "Refining cell"
		eval $::mosflm refineCell $curr_latt [list $l_image_list]
                if {$::debugging} {
                    puts "flow: Returned from calling ::mosflm refineCell"
                }
	    }
	} else {
	    debug "Pattern matching orientation refinement set to [.ats component advanced_refinement getPatternMatchingBool]"
	    if {$processing_stage == "integration"} {
	    # Update status
		.c busy "Pattern matching for integration"
		eval $::mosflm pm_integrate $curr_latt [list $l_image_list] $l_image_numbers
	    } else {
	    # Update status
		.c busy "Pattern matching for refining cell"
		eval $::mosflm pm_refineCell $curr_latt [list $l_image_list]
	    }
	}
	# Update the progress bar
         if {$::debugging} {
             puts "flow: about to exit method process in processingwizard"
         }
	.c progress 0
    }
}

body Processingwizard::extractIsolatedImages { in_list template } {

    set isolist {}
    set num_ok {}
    set numlist {}
    set out_list {}
    # loop through list of images, build list of numbers
    foreach image $in_list {
	lappend numlist [$image getNumber]
    }
    # loop through list of numbers looking for neighbours
    foreach num $numlist {
	set oneless [expr $num - 1]
	set onemore [expr $num + 1]
	if { ([lsearch $numlist $onemore] >= 0) || ([lsearch $numlist $oneless] >= 0) } {
	    lappend num_ok $num
	} else {
	    lappend isolist $num
	}
    }
    # get image names from the numbers
    foreach num $num_ok {
	lappend out_list [$::session getImageByTemplateAndNumber $template $num]
    }
    return [concat [llength $isolist] $isolist $out_list]
}

body Processingwizard::runPointless {pointless_only_bool anomalous_bool} {
     if {$::debugging} {
         # When debugging on Windows, cannot redirect stdout, so send puts output to a file
         # This debug to recognise that env(CBIN) can exist but is actually null .. see below
         set l_filename "debug2.log"
         set l_file [open $l_filename w]
         puts $l_file "In Processingwizard, from getParameterValue, ccp4_bin is: [$::session getParameterValue ccp4_bin]"
         puts $l_file "test for env(CBIN) existing has value: [info exists ::env(CBIN)]"
         puts $l_file "The name for env(CBIN) is: [ array names env CBIN ] "
         flush $l_file
         close $l_file
     }
    # set CBIN to match Environment variable window
    if {[$::session getParameterValue ccp4_bin] != ""} {
        #puts $l_file "In runPointless, about to set env(CBIN) to: [file normalize [$::session getParameterValue ccp4_bin]]"
	set ::env(CBIN) [file normalize [$::session getParameterValue ccp4_bin]]
        #puts $l_file "info exists env(CBIN) is: [info exists ::env(CBIN)]"
    } {
	if { [info exists ::env(CBIN)] } {
            # Under Windows, env(CBIN) can exist, but is null so trying to
            # access it gives a Tcl error, so check that it is not null.
            if { [ array names env CBIN ] != "" } {
	        $::session updateSetting ccp4_bin $::env(CBIN) 0 0 "Processing_options"
    	    }
	}
    }

    #puts "CBIN set to $::env(CBIN)"
    set proglist {}

    set feckprog ""
    set pointprog pointless
    set scaling_prog aimless
    set truncate_prog ctruncate
    
    if {[.ats component sort_scale_merge getUseScalaBool] == 1} { set scaling_prog scala }
    if {[.ats component sort_scale_merge getUseTrnctBool] == 1} { set truncate_prog truncate }

    if {[$::session getMultipleLattices] && [$::session getParameterValue use_feckless_prep] == 1} {
	# If required prepare multi-lattice MTZ files with feckless before running pointless
	set nlatts [$::session getNumberLattices]
	if { (  $nlatts > 1 ) } {
	    # feckless requires pointless 1.8.0 linked locally in ~/bin to pointmore
 	    set pointprog pointless
	    # feckless linked locally in ~/bin
	    set feckprog feckless
	}
    }
# 
# only for checking that the programs exist and are runnable
# 
    if { $pointless_only_bool == 1} {
	if { $feckprog == "" } {
	    lappend proglist $pointprog
	} else {
	    set proglist [list $feckprog $pointprog]
	}
    } else {
	if { $feckprog == "" } {
	    set proglist [list $pointprog $scaling_prog $truncate_prog]
	} else {
	    set proglist [list $feckprog $pointprog $scaling_prog $truncate_prog]
	}
    }

    foreach prog $proglist {
	#puts "Checking $prog will start"
	if { [catch {exec $prog <<""} message ]} {
	    if { [regexp "couldn't execute" $message] } {
		.m confirm \
		    -type "1button" \
		    -title "Cannot execute" \
		    -button1of1 "Dismiss" \
		    -text "Could not execute the program [subst $prog]\nMake sure that the [subst $prog] binary is in your path"
		if { $prog == "aimless"} {
		    set scaling_prog scala
		    .ats component sort_scale_merge setUseScalaBool 1
		} else {
		    return
		}
	    }
	}
    }

    if { [regexp -nocase windows $::tcl_platform(os)] } {
	set baubles_windows_path [file join $::env(CCP4) share smartie baubles.py]
	if {![file exists $baubles_windows_path]} {
	    .m confirm \
		-title "Error" \
		-type "1button" \
		-button1of1 "Dismiss" \
		-text "Couldn't find baubles.py \nMake sure it is in the '$CCP4/share/smartie' directory"
	    return
	}
    } else {
	if { [catch "exec baubles" message ]} {
	    if { [regexp "couldn't execute" $message]} {
		.m confirm \
		    -title "Error" \
		    -type "1button" \
		    -button1of1 "Dismiss" \
		    -text "Couldn't execute baubles \nMake sure that baubles is in your path"
		return
	    }
	}
    }

    # Check for any multiple MTZ files selected
    if {[.ats component sort_scale_merge getPointlessMTZfiles] ne ""} {
	set default_mtz_file "multiple.mtz"
	set current_mtz_file [.ats component sort_scale_merge getPointlessMTZfiles]
	set current_mtz_dir [.ats component sort_scale_merge getPointlessMTZdirectory]
    } else {
	# Get the MTZ file name and directory
	set current_mtz_dir [$::session getMTZDirectory]
	set current_mtz_file [$::session getMTZFilename]
        #puts "debug: current_mtz_file from session getMTZFilename is: $current_mtz_file"
	set ssm_mtz_file [$::session getParameterValue ssm_mtz_file]
        #puts "debug: ssm_mtz_file from getParameterValue is: $ssm_mtz_file"

	# Check for file identifier for Sort, Scale & Merge MTZ files
	set default_mtz_file $ssm_mtz_file
	if { $default_mtz_file == ""} {
	    set default_mtz_file $current_mtz_file
	}
	# Default not empty but may refer to the wrong lattice
	#puts "debug: default_mtz_file $default_mtz_file current_mtz_file $current_mtz_file"
	if { $default_mtz_file != $current_mtz_file && $default_mtz_file != $ssm_mtz_file } {
	    set default_mtz_file $current_mtz_file
	}
	# Check template contains .mtz/.MTZ just for ctruncate it would appear
	if { ![regexp -nocase "\.mtz" $default_mtz_file] } {
	    set default_mtz_file ${default_mtz_file}.mtz
	}
	if {[$::session getParameterValue ssm_mtz_file] == ""} {
        # Do not update ssm_mtz_file otherwise the same output filenames will be used for
        # Pointless etc, even if mosflm MTZ flename is changed
            #puts "debug: Now NOT Setting ssm_mtz_file to $default_mtz_file"
	#    $::session updateSetting "ssm_mtz_file" $default_mtz_file 1 1 "User"
	}
    }
#
# start of code for joining MTZ files from the parallel sub-directories
#
    set datestamp [$::mosflm getNewTimeStamp]
    set pointlesslog "pointandscale_$datestamp.log"
    $::session addCCP4i2file "pointscale_logfile" "$pointlesslog"
    if { $::ccp4i2 == 1 } {
	set PointXML  "XMLOUT pointless_$datestamp.xml"
    } {
	set PointXML ""
    }
    set baubleshtml [ file join $current_mtz_dir "pointandscale_$datestamp.html" ]
    update


    set nlatts [$::session getNumberLattices]
    set current_mtz_file [file join $current_mtz_dir $current_mtz_file ]
    if {[.ats component sort_scale_merge getPointlessMTZfiles] eq ""} {
	if { ![ file exists $current_mtz_file ]} {
	    if {[$::session getParameterValue multiple_mtz_files]} {
		# Try the wild card option
		if {[regsub "\.mtz" $current_mtz_file "_\*\.mtz" wildcard]} {
		    set current_mtz_file [glob $wildcard]
		}
	    } else {
		.m confirm \
		    -title "Error" \
		    -type "1button" \
		    -button1of1 "Dismiss" \
		    -text "The file $current_mtz_file does not exist. QuickSymm or QuickScale will not proceed "
		return
	    }
	}
    }

    # Check for any HKLREF MTZ file specified
    set pnt_hklref_dir [$::session getHKLREFdirectory]
    set pnt_hklref_file [$::session getHKLREFfile]
    if { $pnt_hklref_dir ne "" } {
	set hklreffile "HKLREF [file join $pnt_hklref_dir $pnt_hklref_file]"
	#puts $hklreffile
    } else {
	set hklreffile ""
    }
    if {[$::session getMultipleLattices] && [$::session getParameterValue use_feckless_prep] == 1} {
	debug "checking on Feckless"
	# If required prepare multi-lattice MTZ files with feckless before running pointless
	set l_mtz_file [$::session getParameterValue mtz_file]
	set nlatts [$::session getNumberLattices]
	
	if { ( $l_mtz_file ne "" ) && (  $nlatts > 1 ) } {
	    if {[catch {set l_file [open feckless.input w]}]} {
		puts "Could not create input file: feckless.input"
	    } else {
#		set feckproglog "feckless_$datestamp.log"
#		debug "feckproglog is $feckproglog"
		puts $l_file feckless.mtz
		regsub "_lattice\[1-9\]\.mtz" $l_mtz_file "_lattice" mtz_root
		set nlattfiles 0
		debug "lattice list is [$::session getLatticeList]"
		foreach latt [$::session getLatticeList] {
		    set latt_mtz "${mtz_root}${latt}.mtz"
		    if {[file exists $latt_mtz]} {
			puts $l_file $latt_mtz
			# Count the number of lattice mtz files
			incr nlattfiles 1
		    }
		}
		close $l_file
	    }
	    debug "before running feckless, nlattfiles = $nlattfiles"
	    if { $nlattfiles > 1 } {
		debug "trying to run FECKLESS"
		# Must have at least 2 files for feckless
		if { [catch "exec $feckprog <feckless.input >> $pointlesslog" message ]} {
		    debug "FECKLESS failed somehow, going straight to Pointless"
		} else {
		    debug "FECKLESS ran okay"
		    debug "running pointless with:"
		    debug "set pointlesspipe \[open \"| $pointprog HKLIN feckless.mtz $hklreffile HKLOUT pointless_$default_mtz_file $PointXML\" \"r+\"\]"
		    set pointlesspipe [open "| $pointprog HKLIN feckless.mtz $hklreffile HKLOUT pointless_$default_mtz_file $PointXML" "r+"]
		}
	    } else {
		if { $pointless_only_bool == 1 } {
		    set warning_string "QuickSymm"
		} else {
		    set warning_string "QuickScale"
		}
		.m configure \
		    -title "Only one MTZ file?" \
		    -type "TwoButton" \
		    -buttonAofB "Proceed" \
		    -buttonBofB "Integrate another?" \
		    -text "You are running $warning_string on a single lattice in a\nmulti-lattice run.\n\nDo you want to proceed, or do you want to integrate\n another lattice first?"
		
		if { [.m confirm] } {
		} else {
		    return
		}
	    }
	}
    } else {
	debug "not using Feckless"
	if { [$::session getParameterValue use_feckless_prep] != 1 } {
	    debug "Parallel job on single lattice - not running pointless again"
	    set pointlesspipe [open "| echo" "r+"]
	} {
	    debug "single thread job"
            #puts "debug: about to run pointless, input file $current_mtz_file output file pointless_$default_mtz_file"
	    set pointlesspipe [open "| $pointprog HKLIN $current_mtz_file $hklreffile HKLOUT pointless_$default_mtz_file $PointXML" "r+"]
	}
    }
    debug "gone past running Feckless"
    #
    # end of test for multiple lattices
    #

    if { ![info exists pointlesspipe] } {
	debug "warning - Feckless has not been run on a multilattice job"
	    debug "running $pointprog on file $current_mtz_file with reference file $hklreffile"
	debug "$pointprog HKLIN $current_mtz_file $hklreffile HKLOUT pointless_$default_mtz_file"
            #puts "debug: about to run pointless for multiple lattice, input file $current_mtz_file output file pointless_$default_mtz_file"
	    set pointlesspipe [open "| $pointprog HKLIN $current_mtz_file $hklreffile HKLOUT pointless_$default_mtz_file $PointXML" "r+"]
    }
    catch {fconfigure $pointlesspipe -buffering line} catchmsg
    if { $catchmsg != "" } {
	.m confirm \
	    -title "Error" \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -text "There was a problem running Pointless.\nIf running Feckless to prepare multiple lattices,\nyour Pointless version must be 1.8.0 or above."
	return
    }
    # if running QuickScale and requested to - use iMosflm symmetry
    if {[$::session getParameterValue use_mosflm_symmetry] == 1 && $pointless_only_bool != 1 } {
	if {[$::session getSpacegroup] != ""} {
	    puts $pointlesspipe "choose spacegroup [[$::session getSpacegroup] reportSpacegroup]"
	    if {[[$::session getSpacegroup]  reportSpacegroup] == "C2"} {
		puts $pointlesspipe "setting C2"
	    }
	}
    }
    # If in CCP4i2 mode add datestamped XML output - should no longer be needed 10/11/2015
#    if { $::ccp4i2 == 1 } {
#	eval puts \$pointlesspipe \"$PointXML"
#    }

    # if passing multiple MTZ files to Pointless allow out of sequence files
    if { $default_mtz_file eq "multiple.mtz" } {
	puts $pointlesspipe "ALLOW OUTOFSEQUENCEFILES"
    }
	puts $pointlesspipe "end"
    fileevent $pointlesspipe "readable" [runScaling $pointlesspipe $default_mtz_file $pointlesslog $baubleshtml $pointless_only_bool $scaling_prog $truncate_prog]
#

}

body Processingwizard::runScaling { a_pipe a_mtz_file a_logfile a_baubles_htmlfile a_bool scaling_prog truncate_prog } {
    $itk_component(quick_symm_tb) configure -state disabled
    $itk_component(quick_scale_tb) configure -state disabled
    debug "a_logfile is $a_logfile"
    set pointlesslogfileID [open $a_logfile a]
    set i "0"
    #puts "in runScaling with $scaling_prog"
    #puts [gets $a_pipe std_out]
    if {$a_bool == 1} {
	.c updateStatusMessage "checking symmetry with pointless ..."
    } else {
	.c updateStatusMessage "busy scaling ..."
    }
    while {[gets $a_pipe std_out] >= 0} {
	puts $pointlesslogfileID $std_out
	#puts $a_logfile $std_out
	incr i
	.c progress [expr $i%100]
	update
    }
    .c idle
    #puts "$pointprog has finished"

    # Set filename prefix according to scaling program name
    eval set prefix $scaling_prog

    if {$a_bool != 1} {
	set i "0"
	if { [file exists pointless_${a_mtz_file}] } {
	    debug "pointless_${a_mtz_file} exists, so okay to proceed"
	    $::session addCCP4i2file "pointless_mtzfile" "pointless_${a_mtz_file}"
	} {
	    debug "pointless_${a_mtz_file} doesn't exist, so we should NOT proceed now"
            .m configure -type "1button" \
                -text "pointless_${a_mtz_file} doesn't exist to run $scaling_prog. Sorry." \
                -button1of1 "Dismiss"
            if {[.m confirm]} {
                return
            }
	}
    if { $::ccp4i2 == 1 } {
	set ScaleXML  "XMLOUT aimless_$datestamp.xml"
	set TruncXML  "XMLOUT ctruncate_$datestamp.xml"
    } {
	set ScaleXML ""
	set TruncXML ""
    }
	set scalapipe [open "| $scaling_prog HKLIN pointless_${a_mtz_file} HKLOUT ${prefix}_${a_mtz_file} $ScaleXML" "r+"]
	fconfigure $scalapipe -buffering line
	set space_scales [$::session getParameterValue scale_factor_spacing]
	set space_Bs [$::session getParameterValue B_factor_spacing]
	puts $scalapipe "scales rotation spacing $space_scales secondary 4 bfactor on brotation spacing $space_Bs"

	# Add optional resolution limits for scaling
	set low ""
	set high ""
	set alowres [$::session getParameterValue aimls_low_res_lim]
	if { ($alowres ne "") && ($alowres ne "0.00") } {
	    set low "LOW $alowres"
	}
	set ahighres [$::session getParameterValue aimls_high_res_lim]
	if { ($ahighres ne "") && ($ahighres ne "0.00") } {
	    set high "HIGH $ahighres"
	}
	if { ($low ne "") || ($high ne "") } {
	    puts $scalapipe "RESOLUTION $low $high"
	}

	# Add optional batch exclusion list for scaling
	set batchexcl [$::session getParameterValue aimls_batch_excl]
	if { $batchexcl ne "" } {
	    # replace commas with spaces
	    regsub -all {,} $batchexcl { } batchexcl
	    # shrink spaces
	    regsub -all {"  "} $batchexcl { } batchexcl    
	    #puts "EXCLUDE BATCH $batchexcl"
	    puts $scalapipe "EXCLUDE BATCH $batchexcl"
	}

	# Will work for comma-separated list of batch ranges e.g. 2-4, 6-8,
	set rngexcl [$::session getParameterValue aimls_range_excl]
	if { $rngexcl ne "" } {
	    set l_ranges [$::session processExclResRngs $rngexcl]
	    foreach range $l_ranges {
		set num1 [lindex $range 0]
		set num2 [lindex $range 1]
		#puts "EXCLUDE $num1 to $num2"
		puts $scalapipe "EXCLUDE BATCH $num1 to $num2"
	    }
	}

	if {[$::session getParameterValue treat_anomalous_data] == 1} {
	    puts $scalapipe "anomalous on"
	} else {
	    puts $scalapipe "anomalous off"
	}

	if {[$::session getParameterValue keep_overloaded] == 1} {
	    if { $scaling_prog eq "scala" } {
		puts $scalapipe "ACCEPT OVERLOADS"
	    } elseif { $scaling_prog eq "aimless" } {
		puts $scalapipe "KEEP OVERLOADS"
	    } else {
		# do nothing
	    }
	}

	if {[$::session getParameterValue sameSDall] == 1} {
	    if { $scaling_prog eq "scala" } {
		puts $scalapipe "SDCORRECTION UNIFORM"
	    } elseif { $scaling_prog eq "aimless" } {
		puts $scalapipe "SDCORRECTION SAME"
	    } else {
		# do nothing
	    }
	}

	if {[$::session getParameterValue setSDBterm0] == 1} {
	    puts $scalapipe "SDCORRECTION FIXSDB"
	}

	puts $scalapipe "PARTIALS CHECK TEST [$::session getParameterValue part_frac_low] [$::session getParameterValue part_frac_high]"

	puts $scalapipe "REJECT [$::session getParameterValue outl_sig_cutoff]"

	if {[.ats component sort_scale_merge getOutputUnmergedBool] && ![.ats component sort_scale_merge getUseScalaBool]} {
	    # Harry requested .sca output files for SHELX - restricted to Aimless for the moment
	    puts $scalapipe "OUTPUT UNMERGED"
	}

	puts $scalapipe "end"
	while {[gets $scalapipe std_out2] >= 0} {
	    puts $pointlesslogfileID $std_out2
	    incr i
	    .c progress [expr $i%100]
	    update
	}
#	puts "Scala has finished"
 	#set datestamp [$::mosflm getDateStamp]
 	foreach file { SCALES ROGUES ROGUEPLOT PLOT NORMPLOT CORRELPLOT ANOMPLOT SCALEPACK } {
 	    if { [file exists $file]} {
 		#puts "$file exists and is being renamed ${file}_${datestamp}"
 		if {[catch {[file rename $file ${file}_${datestamp}]} catchmessage]} {}
		if { $file == "SCALES" || $file == "ROGUES" } {
		    $::session addCCP4i2file "${file}_file" "${file}_${datestamp}"
		}
 	    }
 	}

#	run (c)truncate also
	if { [file exists ${prefix}_${a_mtz_file}]} {
	    debug "${prefix}_${a_mtz_file} exists, so okay to proceed"
	    $::session addCCP4i2file "${scaling_prog}_mtzfile" "${prefix}_${a_mtz_file}"
	} {
	    debug "${prefix}_${a_mtz_file} doesn't exist, so we should NOT proceed now"
            .m configure -type "1button" \
                -text "${prefix}_${a_mtz_file} doesn't exist to run $truncate_prog. Sorry." \
                -button1of1 "Dismiss"
            if {[.m confirm]} {
                return
            }
	}
	if { $truncate_prog == "ctruncate" } {
	    # Future ctruncate XML output will be via -xmlout ${truncate_prog}_${datestamp} on the command line
	debug "Ctruncate!"
# hrp 10/11/2015 uncomment next line and remove subsequent line once ctruncate 
#                produces XML!
#	    set ctruncatepipe [open "| $truncate_prog -hklin ${prefix}_${a_mtz_file} -hklout ${truncate_prog}_${a_mtz_file} -colin \"/*/*/\[IMEAN,SIGIMEAN\]\" -colano \"/*/*/\[I(+),SIGI(+),I(-),SIGI(-)\]\" $TruncXML.xml" "r+"]
	    set ctruncatepipe [open "| $truncate_prog -hklin ${prefix}_${a_mtz_file} -hklout ${truncate_prog}_${a_mtz_file} -colin \"/*/*/\[IMEAN,SIGIMEAN\]\" -colano \"/*/*/\[I(+),SIGI(+),I(-),SIGI(-)\]\"" "r+"]
	} else {
	debug "Old truncate!"
	    # Ensure we do not pick up the UNIX truncate command
	    set ctruncatepipe [open "| $::env(CBIN)/$truncate_prog hklin ${prefix}_${a_mtz_file} hklout ${truncate_prog}_${a_mtz_file}" "r+"]
	}
	debug "ctruncatepipe is $ctruncatepipe"
	fconfigure $ctruncatepipe -buffering line
	puts $ctruncatepipe "end"
	while {[gets $ctruncatepipe std_out2] >= 0} {
	    puts $pointlesslogfileID $std_out2
	}
	$::session addCCP4i2file "${truncate_prog}_mtzfile" "${truncate_prog}_${a_mtz_file}"
    }

    close $pointlesslogfileID
    
    # qtRView released in ccp4-6.4.0
    if { [qtrv::isAvailable] == 1 } {
	qtrv::launchReportViewer $a_logfile $a_mtz_file [expr $a_bool == 1]
    } else {

	# Set the path to the baubles python script and to python
	if { [regexp -nocase windows $::tcl_platform(os)] } {
	    set python_windows_path [file join $::env(CCP4) bin ccp4-python]
	    set baubles_windows_path [file join $::env(CCP4) share smartie baubles.py]
	    if {[$::session getParameterValue web_browser] != ""} {
		# set via Environment variable settings window
		set ::env(CCP4_BROWSER) [$::session getParameterValue web_browser]
	    } {
		if { [info exists ::env(CCP4_BROWSER)] } {
		    $::session updateSetting web_browser $::env(CCP4_BROWSER) 0 0 "Processing_options"
		}
	    }
	}

	# Set the path to the baubles python script
	if { [regexp -nocase windows $::tcl_platform(os)] } {
	    set b [open "| $python_windows_path $baubles_windows_path $a_logfile" r]
	} else {
	    set b [open "| baubles $a_logfile" r]
	}
	set std_out [read -nonewline $b]
	if {[eof $b]} {
	    #puts "baubles has finished running"
	    catch {close $b} std_err
	    set baubleshmtlfileID [open $a_baubles_htmlfile w]
	    puts $baubleshmtlfileID $std_out
	    close $baubleshmtlfileID

	    # Added special case for windows as it seems to not work with open_url
	    # Added file:/// for Firefox 12 on Windows 7 which would not open c:\Users\etc.
	    if { [regexp -nocase windows $::tcl_platform(os)] } {
		exec [regsub -all \" $::env(CCP4_BROWSER) "" ] "file\:\/\/\/$a_baubles_htmlfile" &
	    } else {
		open_url $a_baubles_htmlfile
	    }
	    #[.c component activity_l] idle
	    .c idle
	    [.c component status_message] configure -text "Done"
	}
    }

    $itk_component(quick_symm_tb) configure -state normal
    $itk_component(quick_scale_tb) configure -state normal
    if {$a_bool != 1 && ([expr int([file size ${truncate_prog}_${a_mtz_file}])] > 0)} {


	if { [$::session getParameterValue uq_rfree_frac] > 0.0 } {
	uniqueify ${truncate_prog}_${a_mtz_file} $a_logfile
###	# We should have run (c)truncate and have a non-zero size output file
###	if { [catch "exec uniqueify -p [$::session getParameterValue uq_rfree_frac] ${truncate_prog}_${a_mtz_file}" u_message] } {
###	    if { [regexp "not found" $u_message] } {
###	    } else {
###		# BS uniqueify will not append to an existing file, so
###		set currentUniqueLogFile [lrange [lsort -dictionary [glob -nocomplain [file rootname ${truncate_prog}_${a_mtz_file}]-unique.log*]] end end]
###		if { [file exists $currentUniqueLogFile] } {
###		    set logfile1 [open $currentUniqueLogFile r]
###		    set logfile2 [open $a_logfile a]
###		    fcopy $logfile1 $logfile2
###		    close $logfile1
###		    close $logfile2
###		    file delete $currentUniqueLogFile
###		}
###		# Want to write the output MTZ to the list of files saved in CCP4i2 mode
###		set currentUniqueMTZFileRoot [file rootname ${truncate_prog}_${a_mtz_file}]
###		# The following raises an Application error pop-up if not within an 'if catch else' - which is just weird as it gives "no error caught"
		if { [catch { $::session addCCP4i2file uniqueify_mtzfile ${currentUniqueMTZFileRoot}-unique.mtz } ] } {
		    #puts "error caught"
		} else {
		    #puts "no error caught"
		}
###	    }
###	}
	}
    }
}

# 
# start of uniqueify methods to replace CCP4 Bourne shell script so it will run on Windows
# 
body Processingwizard::uniqueify { truncate_mtz_file logfile } {
    set uniqueOK 1
    # first test to see if executables are availableset uniqueOK 1
    foreach uniqueifyProgramme { mtzdump unique freerflag cad } {
	if { [catch {exec $uniqueifyProgramme <<""} executableError]} {
	    if { [regexp "couldn't execute" $executableError] } {
		set uniqueOK 0
	    }
	}
    }
    if { $uniqueOK == 0 } {
	return
    }
    set UniqueMTZFile "[file rootname $truncate_mtz_file]-unique.mtz"
    set temp1 "temp1.mtz"
    set temp2 "temp2.mtz"
    set temp3 "temp3.mtz"
    set a_logfile [open "$logfile" "a"]
    #
    # run mtzdmp to get values for CELL, SYMM, RESO to use in unique
    set uniqueifypipe [open "| mtzdump HKLIN $truncate_mtz_file" "r+"]
    catch {fconfigure $uniqueifypipe -buffering line} catchmsg
    fileevent $uniqueifypipe "readable" [uniqueMTZ $uniqueifypipe $a_logfile $temp1]
    #
    # first FreeRFlag
    set uniqueifypipe [open "| freerflag HKLIN $temp1 HKLOUT $temp2" "r+"]
    catch {fconfigure $uniqueifypipe -buffering line} catchmsg
    fileevent $uniqueifypipe "readable" [runFreeRFlagFirst $uniqueifypipe $a_logfile]
    #
    # cad
    set uniqueifypipe [open "| cad HKLIN2 $temp2 HKLIN1 $truncate_mtz_file HKLOUT $temp3" "r+"]
    catch {fconfigure $uniqueifypipe -buffering line} catchmsg
    fileevent $uniqueifypipe "readable" [runCad $uniqueifypipe $a_logfile]
    #
    # second FreeRFlag (to tidy up)
    set uniqueifypipe [open "| freerflag HKLIN $temp3 HKLOUT $UniqueMTZFile" "r+"]
    catch {fconfigure $uniqueifypipe -buffering line} catchmsg
    fileevent $uniqueifypipe "readable" [runFreeRFlagSecond $uniqueifypipe $a_logfile]
    #
    # tidy up, add ccp4i2 value - weird catch behaviour if not in an if...then...else
    if { [catch { $::session addCCP4i2file uniqueify_mtzfile $UniqueMTZFile } ] } {
	#puts "error caught"
    } else {
	#puts "no error caught"
    }

    close $a_logfile
    file delete $temp1
    file delete $temp2
    file delete $temp3
    
}

body Processingwizard::uniqueMTZ { a_pipe pointlesslogfileID temp1 } {
    puts $a_pipe "NREF 0"
    puts $a_pipe "END"
    while {[gets $a_pipe line] >= 0} {
	puts $pointlesslogfileID "$line"
	if { [regexp "Dataset ID" $line] } {
	    # read 5 lines, CELL on 5th
	    set line [gets $a_pipe]
	    set line [gets $a_pipe]
	    set line [gets $a_pipe]
	    set line [gets $a_pipe]
	    set cell [join [gets $a_pipe]]
	}
	if { [regexp "Resolution Range" $line] } {
	    # read 3 lines, RESO on 3rd
	    set line [gets $a_pipe]
	    set line [gets $a_pipe]
	    set line [join $line " "]
	    set icount 0
	    set lwords [split $line " "]
	    foreach word $lwords {
		if { $icount == 3 } {
		    set res_1 $word
		}
		if { $icount == 5 } {
		    set res_2 $word
		}
		incr icount
	    }
	    # pick high resolution limit
	    if { $res_1 < $res_2 } {
		set resolution $res_1
	    } {
		set resolution $res_2
	    }
	}
	
	# SYMM on this line  
	if { [regexp "Space group" $line] } {
	    set symm [string range $line [expr [string first ' $line]+1] [expr [string last ' $line]-1]]
	    break
	}
    }
    set uniqueifypipe [open "| unique HKLOUT $temp1" "r+"]
    catch {fconfigure $uniqueifypipe -buffering line} catchmsg
    fileevent $uniqueifypipe "readable" [runUnique $uniqueifypipe $pointlesslogfileID $cell $symm $resolution]
}

body Processingwizard::runUnique { a_pipe pointlesslogfileID cell symm resolution } {
    puts $a_pipe "CELL $cell"
    puts $a_pipe "SYMM \"$symm\""
    puts $a_pipe "RESOLUTION $resolution"
    puts $a_pipe "LABOUT F=FUNI SIGF=SIGFUNI"
    puts $a_pipe "END"
    while {[gets $a_pipe line] >= 0} {
	puts $pointlesslogfileID "$line"
    }
    return
}

body Processingwizard::runFreeRFlagFirst { a_pipe pointlesslogfileID } {
    puts $a_pipe "FREERFRAC [$::session getParameterValue uq_rfree_frac]"
    puts $a_pipe "END"
    while {[gets $a_pipe line] >= 0} {
	puts $pointlesslogfileID "$line"
    }
    return
}

body Processingwizard::runCad { a_pipe pointlesslogfileID } {
    puts $a_pipe "LABI FILE 1  ALLIN"
    puts $a_pipe "LABI FILE 2  E1=FreeR_flag"
    puts $a_pipe "END"
    while {[gets $a_pipe line] >= 0} {
	puts $pointlesslogfileID "$line"
    }
    return
}

body Processingwizard::runFreeRFlagSecond { a_pipe pointlesslogfileID } {
    puts $a_pipe "COMPLETE FREE=FreeR_flag"
    puts $a_pipe "END"
    while {[gets $a_pipe line] >= 0} {
	puts $pointlesslogfileID "$line"
    }
    return
}
# 
# end of uniqueify methods
# 
body Processingwizard::saveScript { } {

    # Get list of images to be processed
    set l_image_list [getImageList]

    # Validate matrices
    validateMatrices $l_image_list

    # Get the user to pick a new filename and location (as full path)
    if {![winfo exists .saveScript]} {
	Fileopen .saveScript  \
	    -title "Save script file" \
	    -type save \
	    -initialdir [pwd] \
	    -filtertypes {{"Mosflm script" {.msc}} {"All Files" {.*}}}
    }
    set l_script_file [.saveScript get]

    # If the user picked a file
    if {$l_script_file != ""} {
        # Write script file
	writeScript $l_script_file $l_image_list
    }
}

body Processingwizard::submitBatch { } {
    # Get list of images to be processed
    set l_image_list [getImageList]

    # Validate matrices
    validateMatrices $l_image_list

    set l_script [getScript $l_image_list]

    # Launch batch dialog

    if {$results != ""} {
	delete object $results
	set results ""
    }
    set results [eval newResults $l_image_list]
    .c enable
    .c busy "batch integration"
    set launchBatch [.bsd launch $l_script]
}

body Processingwizard::submitParallelBatch { } {

    set thisIsAParallelBatchRun "1"
    # Get list of images to be processed
    set l_image_list [getImageList]
    # Validate matrices
    validateMatrices $l_image_list

    # now modify for parallel batches
    set l_script [getScript $l_image_list]
#hrp - remove to stop empty object initialisation error    initializeTreesAndGraphs
    parallelizeScript $l_image_list
}


body Processingwizard::splitaBatch { } {

    set nbatch 0
    set ntosplit 20

    # Get list of images to be processed
    set l_image_list [getImageList]

    # Validate matrices
    validateMatrices $l_image_list

    set total [llength $l_image_list]
    if { $total > $ntosplit } {
	for { set offset 0} { $offset <= $total } { incr offset $ntosplit} {
	    incr nbatch
	    set l_script [getScript [lrange $l_image_list $offset [expr ($offset+$ntosplit-1)]]]
	    # Launch batch process
	    .bsd ok $l_script $nbatch
	}
    } else {
        set l_script [getScript $l_image_list]
    }
    #puts $l_image_list

    .m configure \
        -type "2button" \
        -title "Batch XML file" \
        -text "Try reading mosflm_batch.xml?" \
        -button1of2 "Yes" \
        -button2of2 "No"
    if { [.m confirm] } {
        #puts "Start: [clock format [clock seconds] -format "%H:%M:%S"] reading batch XML"
        # create results object (auto initialized)
        if {$results != ""} {
            #puts "Processingwizard::splitaBatch deleting object $results"
            delete object $results
            set results ""
        }
        set results [eval newResults $l_image_list]
	for { set batch 1 } { $batch <=2 } { incr batch } {
	    # Test reading the mosflm_batch.xml file
	    set in_file [::open [file join [$::session getParameterValue mtz_directory] "mosflm_batch_$batch.xml"] r]
	    while {[gets $in_file line] >= 0} {
		if {[string range $line 0 4] == "<?xml"} {
		    set dom [dom parse $line]
		    processBatch $dom
		} else {
                # ignore e.g. <Mosflm version ...> header
		}
	    }
	    #puts " Ends: [clock format [clock seconds] -format "%H:%M:%S"]"
	    ::close $in_file
	}
    } else {
	if { $nbatch == 0 } {
	    # Launch batch dialog
	    .bsd launch $l_script
	}
    }
}

body Processingwizard::processBatch { dom } {
    # keep record of where to send processing feedback
    set processor "[.c component integration]"

    # read the document type
    set doctype [[$dom documentElement] nodeName]
#    puts "processBatch: $doctype"
    # Pass to appropriate object to process...
    if {$doctype == "image_response"} {
        .image parseHistogram $dom
    } elseif {$doctype == "header_response"} {
        $::session processHeaderData $dom
    } elseif {$doctype == "brief_header_response"} {
        $::session processBriefHeaderData $dom
    } elseif {$doctype == "experiment_response"} {
        $::session processExperimentData $dom
    #} elseif {$doctype == "warnings"} {
    #    $::session parseWarnings $dom
# Started processing keyword errors sent by Mosflm but probably too disruptive
# as e.g. during Integration iMosflm sends a "continue" command after each image.
#       } elseif {$doctype == "keyword_error"} {
#          $::session parseErrors $dom
    } elseif {$doctype == "spot_search_response"} {
        [.c component indexing] processSpotfindingResults $dom
    } elseif {$doctype == "preselection_index_response"} {
        [.c component indexing] processIndexingResults $dom
    } elseif {$doctype == "prerefinement_index_response"} {
        [.c component indexing] processPrerefinementResult $dom
    } elseif {$doctype == "refined_index_response"} {
        [.c component indexing] processRefinedResult $dom
    } elseif {$doctype == "updated_amatrix_response"} {
	[.c component indexing] processUpdatedAmatrices $dom
    } elseif {$doctype == "mosaicity_response"} {
        .me processMosaicityEstimation $dom
    } elseif {$doctype == "mosaicity_estimation_response"} {
        .me processMosaicityFeedback $dom
    } elseif {$doctype == "prediction_response"} {
        .image processPredictions $dom
    } elseif {$doctype == "bad_spots_response"} {
        .image processBadSpots $dom
    } elseif {$doctype == "pick_region"} {
        .image processPick $dom
    } elseif {$doctype == "block_size_notification"} {
        if {$processor != "strategy"} {
            $processor extractBlockSize $dom
        }
    } elseif {$doctype == "image_process_begin"} {
        # set the processing flag, so next <done> is trapped as processing finish
        set processing_flag "1"
        $processor updateProcessingStatus "refinement" $dom
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
	#puts "pB: got block_integrate_begin"
	if {$processor eq [.c component integration]} {
		if {[$::session getParameterValue pointless_live] == 1} {
		    $::session callPointlessProcess
		}
	}
	$processor updateIntegrationStatus
    } elseif {$doctype == "processing_task_begin"} {
	#puts "pB: got processing_task_begin"
    } elseif {$doctype == "processing_task_end"} {
	#puts "pB: got processing_task_end $processor updateIntegrationGraphics"
        # puts "debug: in processingwizard, about to call updateIntegrationGraphics"
	$processor updateIntegrationGraphics
        # puts "debug: in processingwizard, called updateIntegrationGraphics"
    } elseif {$doctype == "block_integrate_end"} {
	#puts "pB: got block_integrate_end $processor updateIntegrationGraphics"
	$processor updateIntegrationGraphics
    } elseif {$doctype == "integration_response"} {
        $processor updateIntegrationData $dom
#hrp 29.09.2012    } elseif {$doctype == "cell_refine_response"} {
#hrp 29.09.2012        $processor_refine processCellRefinementSummary $dom
    } elseif {$doctype == "information_and_warnings"} {
        $::session parseInfoAndWarnings $processor $dom
    } elseif {$doctype == "strategy_response_alignment"} {
        [.c component strategy] processStrategyAlignmentResponse $dom
    } elseif {$doctype == "strategy_response"} {
        [.c component strategy] processStrategyResponse $dom
    } elseif {$doctype == "strategy_response_breakdown"} {
        [.c component strategy] processStrategyBreakdownResponse $dom
    } elseif {$doctype == "segment_setup_response"} {
        [.c component cell_refinement] processSegmentSetupResponse $dom
    } elseif {$doctype == "updated_raster_and_separation"} {
        $::session processRasterAndSeparation $dom $processor
    } elseif {$doctype == "circle_fitting_response"} {
        CircleFit::parseCircle $dom
    } elseif {$doctype == "backstop_response"} {
        ImageDisplay::parseBackstop $dom
    } elseif {$doctype == "fatal_condition_response"} {
        $::session processFatalError $dom
    } elseif {$doctype == "strategy_response_testgen"} {
        [.c component strategy] processTestgenResponse $dom
    } elseif {$doctype == "generate_response"} {
        $::session processGenerateResponse $dom
    } else {
        # Unrecognized message!!!
    }
    # Tidyup
    $dom delete
    return $doctype
}

body Processingwizard::writeScript {  a_filename an_image_list } {

    if {[catch {set l_file [open $a_filename w]}]} {
	puts "Could not create script file: $a_filename"
    } else {
	puts $l_file [getScript $an_image_list]
	close $l_file
    }

}

body Processingwizard::getScript { an_image_list } {
    error "This method should be overwritten!"
}

body Processingwizard::parallelizeScript { an_image_list } {
    error "This method should be overwritten!"
}

body Processingwizard::validateMatrices { a_image_list } {
    # Check matrices are all present
    #puts "vM: Image list $a_image_list"
    set l_sector_list {}
    foreach i_image $a_image_list {
	#puts "vM: image $i_image"
	set l_sector [$i_image getSector]
	#puts "vM: sector $l_sector template [$l_sector getTemplate]"
	if {[lsearch $l_sector_list $l_sector] < 0} {
	    lappend l_sector_list $l_sector
	}
    }
    # Get list of sectors with invalid matrices
    set l_sectors_with_invalid_matrices {}
    foreach i_sector $l_sector_list {
	set l_matrix [$i_sector getMatrix]
	if {![$l_matrix isValid]} {
	    lappend l_sectors_with_invalid_matrices $i_sector
	}
    }
    if {[llength $l_sectors_with_invalid_matrices] > 0} {
	set l_first_matrix ""
	# Get first valid matrix in session
	foreach i_sector [$::session getSectors] {
	    set l_matrix [$i_sector getMatrix]
	    if {[$l_matrix isValid]} {
		set l_first_matrix $l_matrix
		break
	    }
	}
	# If there is a valid matrix
	if {$l_first_matrix != ""} {
	    if {$processing_stage == "cell_refinement"} {
		set l_reason "Cell_refinement"
	    } else {
		set l_reason "Integration"
	    }
	    set l_reason
	    # updte the sectors requiring it
	    foreach i_sector $l_sectors_with_invalid_matrices {
		#puts "validateMatrices: [$i_sector getTemplate] $l_first_matrix $l_reason"
		$i_sector updateMatrix $l_reason $l_first_matrix 1 1 0
	    }
	} else {
	    # Shouldn't be possible!
	    # warn the user that mosflm couldn't proceed.
	    .m configure \
		-title "Error" \
		-type "1button" \
		-text "Cannot find a valid matrix. Sorry." \
		-button1of1 "Dismiss"
	    if {[.m confirm]} {
		return
	    }
	}
    }
}

body Processingwizard::loadResults { a_results } {

    # create results object (auto initialized)
    if { $a_results == "" } {
	puts "Pw::lR: NO passed \$a_results object"
    }
#    if {$results != ""} {          ; # code for parallel batches
#	delete object $results      ; # code for parallel batches
#	set results ""              ; # code for parallel batches
#    }                              ; # code for parallel batches
    if {$results == ""} {
        #puts "Pw::lR: \$results object copied from: $a_results"
	set results [copyResults $a_results]
    }

    #puts "copyResults: [$results serialize]"

    # update image numbers
    #puts "Images from $results [$results getImages]"
    updateImages [$results getImages]

    # initialize trees and graphs
    initializeTreesAndGraphs

}

body Processingwizard::getImageList { args } {
    # build image_list
    set l_image_list {}
    set l_numbers {}
    set l_nums {}
    foreach i_template_and_numbers [$itk_component(image_numbers) getContent] {
	foreach { l_template l_numbers } $i_template_and_numbers break
	# Sort this list unique to prevent overlapping ranges screwing-up the plots
# hrp 10/11/2015 - this line was commented out, I think it's the easy way to make 
# sure we don't have duplicate entries in the integration list.
	set l_numbers [lsort -integer -uniq $l_numbers]
	foreach i_num $l_numbers {
	    #puts "getImageList: image $i_num template $l_template"
	    set l_image [$::session getImageByTemplateAndNumber $l_template $i_num]
	    if {$l_image != ""} {
		lappend l_image_list $l_image
	    }
	}
    }

    updateImages $l_image_list
    return $l_image_list
}
body Processingwizard::newResults { args } {
    return [namespace current]::[eval Processingresults \#auto "new" $args]
}

body Processingwizard::copyResults { a_results } {
    error "Virtual method called!"
}

body Processingwizard::initializeTreesAndGraphs { } {

    #puts "here - Processingwizard::initializeTreesAndGraphs"
    # update parameter trees and graphs
    updateParameterTreesAndGraphs

    # refresh the profile tree
    refreshProfileTree

}

body Processingwizard::updateParameterTreesAndGraphs { args } {

    # This is used for updating all graphs in both refinement
    # and integration. Similarly-named functions in other files call this.

    # if no parameter class(es) is/are specified, update both - but do we plot twice or just once?
    if {[llength $args] == 0} {
	#puts "No args to updateParameterTreesAndGraphs - initializing?"
	set l_param_classes [list refinement postrefinement]
    } else {
	set l_param_classes $args
    }

    foreach i_param_class $l_param_classes {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    #puts $i_param
	    if { $i_param != "beam_y_corrected" } {
		$itk_component(${i_param_class}_tree) item text $items_by_parameter($i_param) 1 [$results getDatum $i_param]
	    }
	}
	#puts "Call plotProcessingGraph for $i_param_class with list set to $l_param_classes"

	# We do want to update if it is a parallel run in order to give interface more signs of life during processing
	plotProcessingGraph $i_param_class
    }
}

body Processingwizard::updateParameterTrees { item } {
    set l_param_classes [list refinement postrefinement]
    foreach i_param_class $l_param_classes {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    #puts $i_param
	    if { $i_param != "beam_y_corrected" } {
		$itk_component(${i_param_class}_tree) item text $items_by_parameter($i_param) 1 [$results getDatum $i_param $item]
	    }
	}
    }
}

#body Processingwizard::getImageParameterValue { image_object parameter } {
#    set value ""
#    # Get the value of this parameter from the image object
#    set value [$image_object getValue "$parameter"]
#    if { $value == "" } {
#	set image_number [$image_object getNumber]
#	if { $results != "" } {
#	    # Get the value of this parameter for this image from the results
#	    set value [$results getDatum $parameter $image_number]
#	    puts "$parameter $value - image $image_number from results"
#	}
#    }
#    return $value
#}

body Processingwizard::getRefinementTree { } {
    return $itk_component(refinement_tree)
}

body Processingwizard::getPostrefinementTree { } {
    return $itk_component(postrefinement_tree)
}

body Processingwizard::getItemsByParameter {a_param } {
    return $items_by_parameter($a_param)
}

body Processingwizard::complete { } {
    $results updateSession
    hide
}

# Control methods

body Processingwizard::abort { } {
    # Set the process processing order to be "abort"
    set processing_order "abort"

    # Enable fixing checkbuttons
    foreach i_param_class { refinement postrefinement } {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    if {[Processingresults::parameterIsFixable $i_param]} {
		$itk_component(${i_param_class}_tree) item state set $items_by_parameter($i_param) ENABLED
	    }
	}
    }

}

body Processingwizard::pause { } {
    # Set the process processing order to be blank
    set processing_order ""

    # N.B. Mosflm will wait for a continue or an abort!

    # Update the control buttons
    $itk_component(process) configure \
	-text "Continue" \
	-command [code $this continueProcessing]

    # Disable the Abort button - it only works if Process-ing
    $itk_component(cancel) configure -state disabled

    # Update activity indicator
    .c pause
}

body Processingwizard::continueProcessing { } {
    # Send continue signal to mosflm
    update idletasks
    $::mosflm promptProcessing "continue"

    # set subsequent processing order to be continue too
    set processing_order "continue"

    # Update the control buttons
    $itk_component(process) configure \
	-text "Pause" \
	-command [code $this pause]

    # Enable the Abort button - so it works if Process-ing
    $itk_component(cancel) configure -state normal

    # Update activity indicator
    .c busy
}

# Feedback processing methods ######################################################################

body Processingwizard::extractBlockSize { a_dom } {
    set block_size [$a_dom selectNodes normalize-space(//block_size)]
    #$::session updateSetting "block_size" $block_size 1 1 "User"
    # Uploading to session means this value will appear in the interface
    # and it will then override anything set in Mosflm see bug 246
}

body Processingwizard::updateProcessingStatus { a_reason a_dom } {

    # get the name of the image being processed
    set l_image_name [$a_dom selectNodes normalize-space(//image_name)]
    set l_image_number [$a_dom selectNodes normalize-space(//image_number)]
    set l_template_name [$a_dom selectNodes normalize-space(//image_template)]

    # Clear bad spot list from any previous integration done on this image
    #puts "updateProcessingStatus - clearing bad spots for $l_image_name reason $a_reason"
# HRP 02032018 for HDF5 - template = filename
    if { $l_image_name == $l_template_name } {
	set l_image_name "image.[format %07g $l_image_number]"
    }
    set i_image [$::session getImageByName $l_image_name]
    $i_image unsetBadSpotlist $curr_latt

    # hrp 13.05.2013 if results doesn't exist
    if {$results == ""} {                                   ; # code for parallel batches
	set results [eval newResults $l_image_list]         ; # code for parallel batches
    }                                                       ; # code for parallel batches
    # hrp 13.05.2013
    # Update the results (truncating/padding data and returning status message)
    foreach { l_message l_update_refinement_graph l_update_postrefinement_graph } [$results updateProcessingStatus $a_reason $l_image_name] break
    

    # Update the status message inserting the cycle number
    .c updateStatusMessage [concat $cycle_message $l_message]

    # Update the progress bar
    .c progress [$results getProgress]

    # Update graphs if necessary
    if {$l_update_refinement_graph} {
	#puts "$l_update_refinement_graph plotProcessingGraph refinement $l_image_name"
	plotProcessingGraph "refinement"
	if {$processing_stage == "cell_refinement"} {
	    #puts "update_refinement_graph - plotnum  still $plotnum"
	}
    }
    if {$l_update_postrefinement_graph} {
	#puts "$l_update_postrefinement_graph plotProcessingGraph postrefinement $l_image_name"
	plotProcessingGraph "postrefinement"
	if {$processing_stage == "cell_refinement"} {
	    #puts "update_postrefinement_graph - plotnum set as 0"
	    # To give processing plots more activity during subsequent cell refinement cycles
	    set plotnum 0
	}
    }

}

body Processingwizard::updatePatternMissets { a_reason a_dom } {

    # Check on status of task
    set status_code [$a_dom selectNodes string(/pattern_matching_response/status/code)]
    if {$status_code == "error"} {
	.m confirm \
	    -title "Error" \
	    -type "1button" \
	    -text "Pattern matching misset updating failed, sorry." \
	    -button1of1 "Dismiss"
    } elseif {$status_code == "ok"} {
	# Get the name of the image being processed. Changes to make this work for HDF5 1/5/19
	if { $::env(HDF5file) == 0 } {
	    set l_node [$a_dom selectNodes {/pattern_matching_response}]
            #puts "l_node is $l_node"
	    set l_image_name [$l_node selectNodes normalize-space(imagefile)]
            #puts "l_image_name is $l_image_name"
	    set l_image [Image::getImageByPath $l_image_name]
            #puts "l_image is $l_image"
        } {
	    set l_node [$a_dom selectNodes {/pattern_matching_response}]
            #puts "l_node is $l_node"
	    set l_image_path [$a_dom selectNodes string(//imagefile)]
            #puts "l_image_path is $l_image_path"
	    set image_number [$l_node selectNodes normalize-space(image_number)]
            #puts "image_number from XML $image_number"
	    set l_image [Image::getImageByPath [file dirname $l_image_path]/image.[format %07g $image_number]]
            #puts "l_image is $l_image"
        }
	set lattice [$::session getCurrentLattice]
	set l_phi_x [$l_node selectNodes normalize-space(phi_x)]
	set l_phi_y [$l_node selectNodes normalize-space(phi_y)]
	set l_phi_z [$l_node selectNodes normalize-space(phi_z)]
        #puts "limage $l_image phix $l_phi_x phiy $l_phi_y phiz $l_phi_z lattice $lattice"
	$l_image updateMissetsFromPatternMatching $l_phi_x $l_phi_y $l_phi_z 1 1 "Processing" $lattice
    } else {
	# what?
    }
}

body Processingwizard::updateProcessingData { a_param_class a_dom } {
    if {$::debugging} {
        puts "flow: Entering Processingwizard::updateProcessingData"
    }
    # Check on status of task
    set status_code [$a_dom selectNodes string(/integration_postrefinement/status/code)]
    if {$status_code == "error"} {
	.m confirm \
	    -title "Error" \
	    -type "1button" \
	    -text "Integration post-refinement failed, sorry.\n[$a_dom selectNodes string(/integration_postrefinement/status/message)]" \
	    -button1of1 "Dismiss"
    } else {
	# prompt mosflm to continue or abort if necessary (only during refinement)
	set l_image_name [$a_dom selectNodes normalize-space(//image_name)]
	set l_image_number [$a_dom selectNodes normalize-space(//image_number)]
	set l_template_name [$a_dom selectNodes normalize-space(//image_template)]

	# HRP 02032018 for HDF5 - template = filename
	if { $l_image_name == $l_template_name } {
	    set l_image_name "image.[format %07g $l_image_number]"
	}
	
	set i_image [$::session getImageByName $l_image_name]
	if {$a_param_class == "refinement"} {
	    # Update the image if the update images box is checked
	    if {[$::session getParameterValue "view_predictions_during_processing"]} {
		# Get the object for current image
		set l_image [$::session getImageByName $l_image_name]
		# Tell image viewer to open current image
		#puts "Viewing images during processing, displaying [$l_image getShortName]"
		.image openCurrentImage $l_image
		$::mosflm promptProcessing "head brief"
		$::mosflm promptProcessing "go"
	    } else {
		set l_image [.image getImageDisplayed]
		#puts "Not viewing images during processing, displaying [$l_image getShortName]"
	    }
	    # Continue, abort, or do nothing...
	    if {$processing_order == "continue"} {
		update idletasks
		$::mosflm promptProcessing "continue"
	    } elseif {$processing_order == "abort"} {
		#puts "Abort sent in $a_param_class"
		catch [$::mosflm removeJob "cell_refinement"]
		catch [$::mosflm removeJob "integration"]
		$::mosflm promptProcessing "abort"
	    } else {
		# Must be paused...
	    }
	}

	# Extract data and store in results object & extract sd data also if postrefining
	#puts "$l_image_name - $a_param_class"
	if {$a_param_class == "postrefinement"} {
	    foreach i_param [Processingresults::getParameters $a_param_class] {
		$results appendDatum $i_param [$a_dom selectNodes normalize-space(//$i_param)]
		$results updateStdDev ${i_param}_sd [$a_dom selectNodes normalize-space(//${i_param}_sd)]
		$i_image setValue $i_param [$a_dom selectNodes normalize-space(//$i_param)]
	    }
	} else {
	    foreach i_param [Processingresults::getParameters $a_param_class] {
		$results appendDatum $i_param [$a_dom selectNodes normalize-space(//$i_param)]
		$i_image setValue $i_param [$a_dom selectNodes normalize-space(//$i_param)]
	    }
	}

	#puts "$results image [$a_dom selectNodes normalize-space(//image_name)]"
	# Trap refresh unset for Batch/Parallel running
	if {$refresh == "" || $refresh == 0 } { set refresh 1 }
	
	# Block size may be too large an interval for just a few hundred images
	if { $refresh > $block_size } { set refresh $block_size }

	set numpostref [$results getNumPostrefined]

	if { $thisIsAParallelBatchRun == 1 } {
	    set refresh $block_size
	    if { $images_per_block < $block_size } { set refresh $images_per_block }
	    # Animate first batch more
	    if { $numpostref < $refresh } { set refresh 1 }
	}

	if { [expr $numpostref % $refresh ] == 0 } {
	    if { ( $numpostref > $plotnum ) || ( $plotnum == 0 ) } {

	    	#puts "numpostref $numpostref images, plotnum $plotnum, refresh $refresh, block_size $block_size, images_per_batch $images_per_block"

		# Select last central profile item added - if not cell refinement
		if { $processing_stage != "cell_refinement" } {
		    set last_item [$itk_component(profile_tree) item lastchild root]
		    if {$last_item != ""} {
			# Modifying the selection will display that profile
			$itk_component(profile_tree) selection modify $last_item all
		    }
		}

		# Update the parameter trees and graphs
		#puts "update central profile, param trees and graphs after $numpostref postrefined"
		updateParameterTreesAndGraphs ; # $a_param_class - but do both if every nth image

		set plotnum $numpostref
	    }
	}
    }
}

body Processingwizard::updateProfileData { a_dom } {

    # Extract image name
    set l_image_name [$a_dom selectNodes normalize-space(//image_name)]
    set l_image_number [$a_dom selectNodes normalize-space(//image_number)]
    set l_template_name [$a_dom selectNodes normalize-space(//image_template)]

# HRP 02032018 for HDF5 - template = filename
    if { $l_image_name == $l_template_name } {
	set l_image_name "image.[format %07g $l_image_number]"
    }
    # Extract and store spot profile info from xml
    $results storeProfile $l_image_name \
	[$a_dom selectNodes normalize-space(//width)] \
	[$a_dom selectNodes normalize-space(//height)] \
	[$a_dom selectNodes normalize-space(//profile)] \
	[$a_dom selectNodes normalize-space(//mask)]

    # update the profile listbox
    updateProfileTree $l_image_name

    # Calculate progress...
    .c progress [$results getProgress]
}

body Processingwizard::refreshProfileTree { } {
    # Clear previous profile tree entries
    $itk_component(profile_tree) item delete all
    array unset profile_items_by_name *
    array unset profile_names_by_item *
    set current_profile ""
    set t_item ""
    # Add entries for each image to the profile listbox
    foreach i_image_name [$results getProfileNames] {
        set l_image [$::session getImageByName $i_image_name]
        set t_item [$itk_component(profile_tree) item create]
        $itk_component(profile_tree) item style set $t_item 0 s1
        $itk_component(profile_tree) item text $t_item 0 [$l_image getNumber]
        $itk_component(profile_tree) item state set $t_item AVAILABLE
        $itk_component(profile_tree) item lastchild root $t_item
        set profile_items_by_name($i_image_name) $t_item
        set profile_names_by_item($t_item) $i_image_name
    }
    # Sort items
    $itk_component(profile_tree) item sort root -dictionary
    # Select last item if any were created
    set l_item [$itk_component(profile_tree) item lastchild root]
    if {$l_item != ""} {
        $itk_component(profile_tree) selection modify $l_item all
    }
    displayProfile
}

body Processingwizard::updateProfileTree { i_image_name } {

    # Add incoming image to the profile listbox - may be being processed again
    set t_item ""
    set last_item ""
    set curr_item ""
    set current_profile ""
    set l_image [$::session getImageByName $i_image_name]
    set last_item [$itk_component(profile_tree) item lastchild root]
    set curr_item [ expr [lsearch -exact [$results getProfileNames] $i_image_name] + 1 ]
    if { $curr_item <= $last_item } {
	#puts "Re-update of profile for $i_image_name last item still $last_item"
	# Select item being reprocessed
	$itk_component(profile_tree) selection modify $curr_item all
    } else {
	set t_item [$itk_component(profile_tree) item create]
	#puts "updateProfileTree: file $i_image_name l_image [$l_image getNumber] $l_image this_item $t_item"

	$itk_component(profile_tree) item style set $t_item 0 s1
	$itk_component(profile_tree) item text $t_item 0 [$l_image getNumber]
	$itk_component(profile_tree) item state set $t_item AVAILABLE
	$itk_component(profile_tree) item lastchild root $t_item

	# Select last item just added - try only selecting at the end of a block
	#$itk_component(profile_tree) selection modify $t_item all

	# Scroll down
	$itk_component(profile_tree) yview moveto 1.0
    }

    #Display the new profile - try only selecting at the end of a block
    #displayProfile $i_image_name
}

body Processingwizard::finishedProcessing { } {
    if {$::debugging} {
        puts "flow: Entering Processingwizard::finishedProcessing"
        puts "flow: about to set integration_done 1"
    }
    $::session setIntegrationDone
    # Turn off activity indicator and clear status message
    .c idle

    # Enable ALL controls
    .c enable

    # Unset the session's flag for running integration
    $::session setRunningProcessing 0

    # set BeamEditedImage to null after an integration run
    $::session setBeamEditedImage 0

    # Re-configure process button from pause button
    $itk_component(process) configure \
	-state "normal" \
	-text "Process" \
	-command [code $this process]

    # Disable cancel button
    $itk_component(cancel) configure -state "disabled"

    # Enable fixing checkbuttons
    foreach i_param_class { refinement postrefinement } {
	foreach i_param [Processingresults::getParameters $i_param_class] {
	    if {[Processingresults::parameterIsFixable $i_param]} {
		$itk_component(${i_param_class}_tree) item state set $items_by_parameter($i_param) ENABLED
	    }
	}
    }

    # update the session with the new parameter values 
    # puts "flow: about to call processingresults:updateSession from finishedProcessing in processingwizard"
   $results updateSession
    if {$::debugging} {
        puts "flow: returned from processingresults:updateSession"
    }
    # Test the detector and cell parameters vs. those in saveDetectorCrystalParams before Processing
    set warning_list [testDetectorCrystalParams]
    set messages ""
    foreach warning $warning_list {
	if { $warning != "" } {
	    # test for word serious in each warning?
	    append messages $warning
	}
    }
    set choice 0
    if { ($messages != "") && ($alwaysignore == 0) } {
	#puts $messages
	# Warn the user change
	.n configure \
	    -type "3button" \
	    -title "Doubtful refinement of Detector parameters" \
	    -text "The following detector parameters have refined to physically questionable values:\n\n$messages\nIt is possible that this is due to inaccurate initial cell parameters or\nincorrect choice of space group.\n\nIf you wish to continue, you are advised to reset the detector and crystal\nparameters to their initial values before attempting to correct the situation\n(e.g. re-indexing, choosing alternative indexing solution).\n" \
	    -button1of3 "Reset" \
	    -button2of3 "Always" \
	    -button3of3 "Once" \
	    -buttontext "Ignore (in this Session only)        "
	set choice [.n confirm]
	if {$choice == 2} {
	    resetDetectorCrystalParams
	} elseif {$choice == 1} {
	    set alwaysignore 0
	} else {
	    set alwaysignore 1
	}
    }

    updateParameterTreesAndGraphs
    set last_item [$itk_component(profile_tree) item lastchild root]
    if {$last_item != ""} {
	# Modifying the selection will display that profile
	$itk_component(profile_tree) selection modify $last_item all
    }

    #puts " Ends: [clock format [clock seconds] -format "%H:%M:%S"]"
    if {$::debugging} {
        puts "flow: exitingProcessingwizard::finishedProcessing"
        puts "l_image_list is $l_image_list"
    }
}

body Processingwizard::paramTreeClick { a_param_class w x y } {
    # bug 61 in this vicinity
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_check"} {
	    if {[$w item state get $item ENABLED]} {
		set l_params $parameters_by_item($a_param_class,$item)
		if {$l_params == "beam_x"} {
		    set l_setting "${processing_stage}_fix_beam"
		    lappend l_params beam_y
		} elseif {$l_params == "beam_y"} {
		    set l_setting "${processing_stage}_fix_beam"
		    lappend l_params beam_x
		} else {
		    set l_setting "${processing_stage}_fix_$l_params"
		}
		if {[$w item state get $item CHECKED]} {
		    $::session updateSetting $l_setting "0"
		    foreach i_param $l_params {
			$w item state set $items_by_parameter($i_param) !CHECKED
		    }
		} else {
		    $::session updateSetting $l_setting "1"
		    foreach i_param $l_params {
			$w item state set $items_by_parameter($i_param) CHECKED
		    }
		}
	    }
	}
    }
}

body Processingwizard::plotProcessingGraph { a_param_class } {

    if {$results != ""} {
	#puts "plotProcessingGraph: $a_param_class results is $results"
	# Build datasets
	set l_data_sets {}
	foreach i_param [Processingresults::getParameters $a_param_class] {
	    # Don't plot beam_y, plot beam_y_corrected instead
	    if { $i_param != "beam_y" && $i_param != "beam_y_corrected" } {
		if {[$itk_component(${a_param_class}_tree) selection includes $items_by_parameter($i_param)]} {
		    set l_data_set [$results getDataSet $i_param]
		    if {[llength $l_data_set] > 0} {
			lappend l_data_sets [$results getDataSet $i_param]
		    }
		}
	    } else {
		if {[$itk_component(${a_param_class}_tree) selection includes $items_by_parameter($i_param)]} {
		    set l_data_set [$results getDataSet beam_y_corrected]
		    if {[llength $l_data_set] > 0} {
			#puts "Got $i_param [$results getDataSet beam_y] beam_y_corrected [$results getDataSet beam_y_corrected]"
			lappend l_data_sets [$results getDataSet beam_y_corrected]
		    }
		}
	    }
	}
	# See if anything should be plotted
	if {([llength [$results getImages]] == 0) || ([llength $l_data_sets] == 0)} {
	    #puts "Zero length images or datasets"
	    # Loop through canvases to plot graph on
	    foreach i_canvas $canvases_by_content($a_param_class) {
		# Delete any previous graphs
		$i_canvas delete all
	    }
	} else {
	    # Loop through canvases to plot graph on
	    foreach i_canvas $canvases_by_content($a_param_class) {
		# Calculate window
		set window [list 10 10]
		lappend window [expr [winfo width $i_canvas] - 10]
		lappend window [expr [winfo height $i_canvas] - 10]
		#puts [winfo width $i_canvas]
		#puts [winfo height $i_canvas]
		#puts "$i_canvas window $window"
		if {([lindex $window 2] > 20) && ([lindex $window 3] > 20)} {
		    # Create graph if there's room
		    set image_data_set [$results getImageDataSet]
		    #puts "Linegraph for [llength $l_data_sets] datasets $l_data_sets after $a_param_class of [llength [$results getImages]] images"
		    LineGraph \#auto $i_canvas $window "id" $image_data_set $l_data_sets
 		    # Remove the dataset objects to ease memory overheads
 		    #puts "Deleting $image_data_set"
		    delete object $image_data_set
 		    foreach ds $l_data_sets {
 			delete object $ds
 			#puts "Deleting $ds"
 		    }
		} else {
		    #puts "No room for graph $i_canvas"
		}
		bind $i_canvas <Configure> [code $this plotProcessingGraph $a_param_class]
	    }
	}
    } else {
	#puts "plotProcessingGraph: $a_param_class results is unset"
    }
}

body Processingwizard::updateProfileSelection { a_item } {
    if {$a_item != ""} {
	# Updates the central profile plot for this image/item
	#puts "updateProfileSelection: item $a_item"
	if {[$itk_component(profile_tree) item state get $a_item AVAILABLE]} {
	    set current_profile [ lindex [$results getProfileNames] [expr $a_item - 1] ]
	    displayProfile $current_profile
	}
	# Update the parameter trees (not graphs) for this image/item once processing stopped
	if { ![$::session getRunningProcessing] } { updateParameterTrees $a_item }
    } else {
	$itk_component(profile_c) delete all
    }
}

body Processingwizard::displayProfile { { a_name ""} } {
    # Update current profile if one was passed
    if {$a_name != ""} {
	set current_profile $a_name
    }
    # if there is now a current profile
    if {$current_profile != ""} {
	# Display the profile
	$results displayProfile $current_profile $itk_component(profile_c)
    }
    bind $itk_component(profile_c) <Configure> [code $this displayProfile]

}

# Graph zooming #################################################

body Processingwizard::zoom { a_widget } {
    if {!$zoomed} {
	foreach i_widget [winfo children $itk_component(results_f)] {
	    grid forget $i_widget
	}
	grid $a_widget -sticky nswe -padx $margin -pady $margin
	grid columnconfigure $itk_component(results_f) { 0 2 4 6 } -minsize 0
	grid columnconfigure $itk_component(results_f) { 3 5 } -weight 0
	grid columnconfigure $itk_component(results_f) { 0 } -weight 1
	grid rowconfigure $itk_component(results_f) { 1 2 } -weight 0
	foreach i_widget [winfo children $a_widget] {
	    event generate $i_widget <Configure>
	}
	set zoomed 1
    }
}

body Processingwizard::toggleZoom { a_widget } {
    if {$zoomed} {
	restoreGrid
    } else {
	zoom $a_widget
    }
}

body Processingwizard::restoreGrid { } {
    if {$zoomed} {
	foreach i_widget [winfo children $itk_component(results_f)] {
	    grid forget $i_widget
	}
	grid x $itk_component(refinement_tree) x  $itk_component(refinement_canvas) x $itk_component(profile_f) x -sticky nsew -pady [list $margin 0]
	grid x $itk_component(postrefinement_tree) x $itk_component(postrefinement_canvas) x -sticky nsew -pady $margin
	grid columnconfigure $itk_component(results_f) { 0 2 4 6 } -minsize $margin
	grid columnconfigure $itk_component(results_f) { 3 5 } -weight 1
	grid rowconfigure $itk_component(results_f) { 0 1 } -weight 1
	set zoomed 0
    }
}

# Treectrl tooltips ###############################################

body Processingwizard::treectrlMotion { a_param_class a_w a_x a_y } {
    set l_item ""
    # get item rolled over
    set id [$a_w identify $a_x $a_y]
    if {$id != ""} {
	if {[lindex $id 0] eq "item"} {
	    set l_item [lindex $id 1]
	}
    }

    if {$l_item == ""} {
	# cancel tooltip
	.tooltip drop
	set last_tooltip_item ""
    } elseif {$l_item != $last_tooltip_item} {
	# Item changed so queue new tooltip...
	.tooltip queue \
	    -text [Integrationresults::getLongParameterName $parameters_by_item($a_param_class,$l_item)] \
	    -bg gold \
	    -fg black
	# record item tip was queued for
	set last_tooltip_item $l_item
    }
}

body Processingwizard::treectrlLeave { } {
    .tooltip drop
}

class ImagePalette {
    inherit Palette

    itk_option define -selectbackground selectBackground Foreground "\#3399ff"
    itk_option define -deselectbackground deselectBackground Foreground "\#dcdcdc"
    itk_option define -selectborder selectBorder Foreground "\#1c53eb"
    itk_option define -deselectborder deselectBorder Foreground "\#a9a9a9"

    # processing wizard
    private variable processing_wizard ""

    # arrays associating tree items and images
    protected variable images_by_item ; # N.B. Array - do not initialize!
    protected variable items_by_image ; # N.B. Array - do not initialize!

    # also index image_paths by item for quick sorting!!!
    protected variable image_paths_by_item ; # N.B. Array - do not initialize!

    # last cursor (for restoring cursor after button 2 & 3 use)
    protected variable last_cursor ""

    public method launch
    public method updateProcessWizard

    # Image tree interaction methods
    protected method imageTreeClick
    protected method imageTreeDoubleClick
    protected method toggleImageSelection
    protected method toggleImageInclusion
    protected method checkImageInclusion
    protected method uncheckImageInclusion

    # Segment canvas creation/positioning methods
    public method createSelectionSummary
    public method zoomIn
    public method zoomOut
    public method fitCanvas

    # Segment canvas toolbutton methods
    public method makeDefaultSelection
    public method uncheckAll
    public method checkAll
    public method toggleCheckSegmentsToolbutton
    public method toggleUncheckSegmentsToolbutton
    public method toggleGrabCanvasToolbutton

    # Segment canvas interaction methods
    public method turnSegmentPaintingOn
    public method turnSegmentPaintingOff
    public method turnSegmentWipingOn
    public method paintSegment
    public method wipeSegment
    public method grabCanvas
    public method releaseCanvas
    public method moveCanvasItems

    constructor { args } { }
}

body ImagePalette::constructor { a_processing_wizard args } {

    # Store processing wizard palette belongs to
    set processing_wizard $a_processing_wizard

    # Image list (tree)
    if {[tk windowingsystem] == "aqua"} {
	set file_chooser_width 380
    } else {
	set file_chooser_width 430
    }

    itk_component add image_tree {
	treectrl $itk_interior.itree \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width $file_chooser_width \
	    -itemheight 18 \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(image_tree) column create -text "Image" -justify left -minwidth 100 -expand 1 ;
    $itk_component(image_tree) column create -text "\u03c6-start" -justify center -minwidth 50 -tag phi_start
    $itk_component(image_tree) column create -text "\u03c6-end" -justify center -minwidth 50 -tag phi_end
    $itk_component(image_tree) column create -text "Use" -justify center -minwidth 30 -tag use

    $itk_component(image_tree) state define CHECKED

    $itk_component(image_tree) element create e_icon image -image ::img::image
    $itk_component(image_tree) element create e_text text -fill {white selected}
    $itk_component(image_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(image_tree) element create e_check image -image { ::img::embed_check_on {CHECKED} ::img::embed_check_off {!CHECKED} }

    $itk_component(image_tree) style create s1
    $itk_component(image_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(image_tree) style layout s1 e_icon -expand ns -padx {0 6}
    $itk_component(image_tree) style layout s1 e_text -expand ns
    $itk_component(image_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2

    $itk_component(image_tree) style create s2
    $itk_component(image_tree) style elements s2 {e_highlight e_text}
    $itk_component(image_tree) style layout s2 e_text -expand ns
    $itk_component(image_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(image_tree) style create s3
    $itk_component(image_tree) style elements s3 {e_highlight e_check}
    $itk_component(image_tree) style layout s3 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s3 e_check -expand ns -padx {2 2}

    bind $itk_component(image_tree) <ButtonPress-1> [code $this imageTreeClick %W %x %y]
    bind $itk_component(image_tree) <Double-ButtonPress-1> [code $this imageTreeDoubleClick %W %x %y]
    bind $itk_component(image_tree) <ButtonRelease-1> { break }

    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> [code $this toggleImageSelection %S %D]

    # Image list scrollbar
    itk_component add image_scroll {
	scrollbar $itk_interior.iscroll \
	    -command [code $this component image_tree yview] \
	    -orient vertical
    }

    $itk_component(image_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(image_scroll)]

    # Segment frame
    itk_component add segment_frame {
	frame $itk_interior.sf \
	    -relief sunken \
	    -bd 2
    } {
	usual
	rename -background -textbackground textBackground Background
    }

    # Segment toolbar
    itk_component add segment_toolbar {
	frame $itk_interior.sf.stb \
	    -relief raised \
	    -bd 2
    }
    # Toolbuttons

    itk_component add default_selection_tb {
	Toolbutton $itk_component(segment_toolbar).dstb \
	    -image ::img::cell_refinement_default_selection \
	    -disabledimage ::img::cell_refinement_default_selection_disabled \
	    -command [code $this makeDefaultSelection] \
	    -balloonhelp "Default image selection"
    }

    itk_component add uncheck_all_tb {
	Toolbutton $itk_component(segment_toolbar).uatb \
	    -image ::img::cell_refinement_clear_selection \
	    -disabledimage ::img::cell_refinement_clear_selection_disabled \
	    -command [code $this uncheckAll] \
	    -balloonhelp "Clear image selection"
    }

    itk_component add check_all_tb {
	Toolbutton $itk_component(segment_toolbar).catb \
	    -image ::img::cell_refinement_select_all \
	    -disabledimage ::img::cell_refinement_select_all_disabled \
	    -command [code $this checkAll] \
	    -balloonhelp "Select all images"
    }

    itk_component add divider_1_tb {
	frame $itk_component(segment_toolbar).div1 \
	    -width 2 \
	    -bd 1 \
	    -relief sunken
    }

    itk_component add check_segment_tb {
	Toolbutton $itk_component(segment_toolbar).cstb \
	    -type "radio" \
	    -image ::img::image_palette_check_segments_tool \
	    -group "select_processing_images" \
	    -command [code $this toggleCheckSegmentsToolbutton] \
	    -balloonhelp "Select images"
    }

    itk_component add uncheck_segment_tb {
       Toolbutton $itk_component(segment_toolbar).ustb \
	    -type "radio" \
	    -image ::img::image_palette_uncheck_segments_tool \
	    -group "select_processing_images" \
	    -command [code $this toggleUncheckSegmentsToolbutton] \
	    -balloonhelp "Deselect images"
    }

    itk_component add grab_canvas_tb {
	Toolbutton $itk_component(segment_toolbar).gctb \
	    -type "radio" \
	    -image ::img::fleur \
	    -disabledimage ::img::fleur_disabled \
	    -group "select_processing_images" \
	    -command [code $this toggleGrabCanvasToolbutton] \
	    -balloonhelp "Move view"
    }

    itk_component add divider_2_tb {
	frame $itk_component(segment_toolbar).div2 \
	    -width 2 \
	    -bd 1 \
	    -relief sunken
    }

    itk_component add zoom_in_tb {
	Toolbutton $itk_component(segment_toolbar).zitb \
	    -type "amodal" \
	    -image ::img::zoom_in \
	    -disabledimage ::img::zoom_in_disabled \
	    -command [code $this zoomIn] \
	    -balloonhelp "Zoom in"
    }

    itk_component add zoom_out_tb {
	Toolbutton $itk_component(segment_toolbar).zotb \
	    -type "amodal" \
	    -image ::img::zoom_out \
	    -disabledimage ::img::zoom_out_disabled \
	    -command [code $this zoomOut] \
	    -balloonhelp "Zoom out"
    }

    itk_component add fit_all_tb {
	Toolbutton $itk_component(segment_toolbar).fatb \
	    -type "radio" \
	    -image ::img::image_palette_fit_all \
	    -disabledimage ::img::cell_refinement_fit_all_disabled \
	    -group "select_processing_images" \
	    -command [code $this fitCanvas all] \
	    -balloonhelp "Fit all"
    }

    itk_component add fit_wedge_tb {
	Toolbutton $itk_component(segment_toolbar).fwtb \
	    -type "radio" \
	    -image ::img::image_palette_fit_sector \
	    -disabledimage ::img::cell_refinement_fit_wedge_disabled \
	    -group "select_processing_images" \
	    -command [code $this fitCanvas segment] \
	    -balloonhelp "Fit sector"
    }

    # Segment canvas
    itk_component add segment_canvas {
	canvas $itk_interior.sf.sc \
	    -borderwidth 0 \
	    -relief flat \
	    -highlightthickness 0
    } {
	rename -background -textbackground textBackground Background
    }

    # Arrange the widgets

    if {[tk windowingsystem] == "aqua"} {
	# Add a closing X as there was a problem dismissing the pop-up on an earlier aqua
	set margin 0
	itk_component add exit_button {
	    button $itk_interior.eb -text "x" \
		-command [code $this dismiss]
	}
	grid x x x x $itk_component(exit_button)  -sticky ne
    } else {
	set margin 7
    }

    # Image selection frame
    grid x $itk_component(image_tree) $itk_component(image_scroll) x $itk_component(segment_frame) x -sticky news -pady $margin
    pack $itk_component(segment_toolbar) -fill x
    pack $itk_component(segment_canvas) -fill both -expand 1
    grid columnconfigure $itk_component(hull) {0 3 5} -minsize $margin
    grid columnconfigure $itk_component(hull) {1 4} -weight 1
    grid rowconfigure $itk_component(hull) 0 -weight 1

    pack $itk_component(check_segment_tb) -side left
    pack $itk_component(uncheck_segment_tb) -side left
    pack $itk_component(grab_canvas_tb) -side left
    pack $itk_component(divider_2_tb) -side left -fill y -padx $margin
    pack $itk_component(zoom_in_tb) -side left
    pack $itk_component(zoom_out_tb) -side left
    pack $itk_component(fit_all_tb) -side left
    pack $itk_component(fit_wedge_tb) -side left

    eval itk_initialize $args
}


body ImagePalette::launch { a_button args } {
    # clear the image and tree
    $itk_component(image_tree) item delete all
    # clear arrays linking tree items and objects
    array unset images_by_item *
    array unset image_paths_by_item *
    array unset items_by_image *

    # Choose labelling method depending on number of templates
    if {[llength [$::session getSectors]] > 1} {
	set l_labelMethod "getRootName"
    } else {
	set l_labelMethod "getNumber"
    }

    # rebuild the image tree
    set i_sector [lindex [$::session getSectors] 0]
    foreach i_sector [$::session getSectors] {
	# Loop through sector's images
	foreach i_image [$i_sector getImages] {
	    # create a new item
	    set t_image_item [$itk_component(image_tree) item create]
	    # set the item's style
	    $itk_component(image_tree) item style set $t_image_item 0 s1 1 s2 2 s2 3 s3
	    # update the item's icon
	    $itk_component(image_tree) item element configure $t_image_item 0 e_icon -image ::img::image
	    # update the item's text
	    foreach {l_phi_start l_phi_end} [$i_image getPhi] break
	    set l_phi_start [format %6.2f $l_phi_start]
	    set l_phi_end [format %6.2f $l_phi_end]
	    $itk_component(image_tree) item text $t_image_item 0 [$i_image $l_labelMethod] 1 $l_phi_start 2 $l_phi_end
	    # add the new item to the tree
	    $itk_component(image_tree) item lastchild root $t_image_item
	    set i_last_item $t_image_item
	    # Store pointer to image objects and items by number, item or object
	    set images_by_item($t_image_item) $i_image
	    set image_paths_by_item($t_image_item) [$i_image getFullPathName]
	    set items_by_image($i_image) $t_image_item
	}
    }

    # Check images listed as included in the processing wizard
    foreach i_image [$processing_wizard getImageList] {
	checkImageInclusion $items_by_image($i_image)
    }

    # SCroll to top of list
    $itk_component(image_tree) yview moveto 0

    # Create the summary canvas illustration
    createSelectionSummary
    bind $itk_component(segment_canvas) <Configure> [code $this createSelectionSummary]

    Palette::launch $a_button
}

body ImagePalette::imageTreeClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_check"} {
	    toggleImageInclusion $item
	}
    }
}

body ImagePalette::imageTreeDoubleClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_icon"} {
	    # Open image
	    if {[info exists images_by_item($item)]} {
		.image openImage $images_by_item($item)
	    } else {
		$w item toggle $item
	    }
	} elseif {[lindex $id 5] == "e_check"} {
	    toggleImageInclusion $item
	}
    }
}

# Image selection

body ImagePalette::toggleImageSelection { a_selected { a_deselected "" } } {

    # if the selected item is checked...
    if {($a_selected != "") && [$itk_component(image_tree) item state get $a_selected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_selected 0]
	# Reflect selection in canvas???
    }
    # if the deselected item is checked...
    if {($a_deselected != "") && [$itk_component(image_tree) item state get $a_deselected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_deselected 0]
	# Reflect selection in canvas???
    }
}

# Image inclusion

body ImagePalette::toggleImageInclusion { an_item } {

    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	uncheckImageInclusion $an_item
    } else {
	checkImageInclusion $an_item
    }
}


body ImagePalette::checkImageInclusion { an_item } {

    # if the spotlist is not checked don't bother!
    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	return
    }
    # make the item  checked...
    $itk_component(image_tree) item state set $an_item CHECKED
    # get the item's label
    set l_label [$itk_component(image_tree) item text $an_item 0]
    # update the segment canvas
    $itk_component(segment_canvas) itemconfigure image($images_by_item($an_item)) \
	-fill $itk_option(-selectbackground) \
	-outline $itk_option(-selectborder) \
	-tags [list segment image($images_by_item($an_item)) checked]
    updateProcessWizard

}

body ImagePalette::uncheckImageInclusion { an_item } {

    # if the spotlist is not  checked don't bother!
    if {![$itk_component(image_tree) item state get $an_item CHECKED]} {
	return
    }
    # get the item's label
    set l_label [$itk_component(image_tree) item text $an_item 0]
    # make the item uncheked...
    $itk_component(image_tree) item state set $an_item !CHECKED
    # Update canvas...
    $itk_component(segment_canvas) itemconfigure image($images_by_item($an_item)) \
	-fill $itk_option(-deselectbackground) \
	-outline $itk_option(-deselectborder) \
	-tags [list segment image($images_by_item($an_item)) unchecked]
    updateProcessWizard
}

# Segment canvas creation/positioning methods #################################

body ImagePalette::createSelectionSummary { } {

    # clear canvas
    $itk_component(segment_canvas) delete all

    # Calculate circle position and size
    set x0 0
    set y0 0
    set x1 -500
    set x2 500
    set y1 -500
    set y2 500

    # Draw circle and labels
    $itk_component(segment_canvas) create oval $x1 $y1 $x2 $y2 -outline lightgrey -tags [list circle]
    $itk_component(segment_canvas) create text $x0 $y1 -text "0\u00b0" -fill lightgrey -anchor s
    $itk_component(segment_canvas) create text $x2 $y0 -text "90\u00b0" -fill lightgrey -anchor w
    $itk_component(segment_canvas) create text $x0 $y2 -text "180\u00b0" -fill lightgrey -anchor n
    $itk_component(segment_canvas) create text $x1 $y0 -text "270\u00b0" -fill lightgrey -anchor e

    # plot segments
    foreach i_im [$::session getImages] {
	# Get phi values
	foreach { l_phi_start l_phi_end } [$i_im getPhi] break
	# Get colours from checked
	if {[$itk_component(image_tree) item state get $items_by_image($i_im) CHECKED]} {
	    set l_fill $itk_option(-selectbackground)
	    set l_outline $itk_option(-selectborder)
	} else {
	    set l_fill $itk_option(-deselectbackground)
	    set l_outline $itk_option(-deselectborder)
	}
	# Create segment
	$itk_component(segment_canvas) create arc $x1 $y1 $x2 $y2 \
	    -start [expr 90 - $l_phi_start] \
	    -extent [expr $l_phi_start - $l_phi_end] \
	    -fill $l_fill \
	    -outline $l_outline \
	    -tags [list segment image($i_im) unchecked]
    }
    # Setup bindings
    $itk_component(uncheck_segment_tb) invoke
    $itk_component(grab_canvas_tb) invoke
    $itk_component(check_segment_tb) invoke
    bind $itk_component(segment_canvas) <ButtonPress-2> [code $this grabCanvas %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-2> [code $this releaseCanvas]
    bind $itk_component(segment_canvas) <ButtonPress-3> [code $this turnSegmentWipingOn %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-3> [code $this turnSegmentPaintingOff]
    bind $itk_component(segment_canvas) <ButtonPress-4> [code $this zoomIn]
    bind $itk_component(segment_canvas) <ButtonPress-5> [code $this zoomOut]

    $itk_component(fit_wedge_tb) invoke
}

body ImagePalette::zoomIn { args } {

    # Unbind canvas configure events
    bind $itk_component(segment_canvas) <Configure> {}
    # Cancel set-view toolbuttons
    $itk_component(fit_all_tb) cancel noexecute
    $itk_component(fit_wedge_tb) cancel noexecute
    # Zoom
    $itk_component(segment_canvas) scale all [expr [winfo width $itk_component(segment_canvas)] / 2] [expr [winfo height $itk_component(segment_canvas)] / 2] 1.1 1.1
}

body ImagePalette::zoomOut { args } {

    # Unbind canvas configure events
    bind $itk_component(segment_canvas) <Configure> {}
    # Cancel set-view toolbuttons
    $itk_component(fit_all_tb) cancel noexecute
    $itk_component(fit_wedge_tb) cancel noexecute
    # Zoom
    $itk_component(segment_canvas) scale all [expr [winfo width $itk_component(segment_canvas)] / 2] [expr [winfo height $itk_component(segment_canvas)] / 2] [expr 1.0/1.1] [expr 1.0/1.1]
}

body ImagePalette::fitCanvas { a_tag args } {

    if {$a_tag == "all"} {
	$itk_component(fit_wedge_tb) cancel noexecute
	bind $itk_component(segment_canvas) <Configure> [code $this fitCanvas all]
    } elseif {$a_tag == "segment"} {
	$itk_component(fit_all_tb) cancel noexecute
	bind $itk_component(segment_canvas) <Configure> [code $this fitCanvas segment]
    }

    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_scale_factor [expr double([winfo width $itk_component(segment_canvas)]) / ($x2 - $x1)]
    set y_scale_factor [expr double([winfo height $itk_component(segment_canvas)]) / ($y2 - $y1)]

    if {$x_scale_factor < $y_scale_factor} {
	set scale_factor $x_scale_factor
    } else {
	set scale_factor $y_scale_factor
    }

    $itk_component(segment_canvas) move all [expr - $x1] [expr - $y1]
    $itk_component(segment_canvas) scale all 0 0 $scale_factor $scale_factor
    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_shift [expr (([winfo width $itk_component(segment_canvas)] - $x2) - $x1) / 2]
    set y_shift [expr (([winfo height $itk_component(segment_canvas)] - $y2) - $y1) / 2]
    $itk_component(segment_canvas) move all $x_shift $y_shift
    # ... and repeat !!!
    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_scale_factor [expr double([winfo width $itk_component(segment_canvas)]) / ($x2 - $x1)]
    set y_scale_factor [expr double([winfo height $itk_component(segment_canvas)]) / ($y2 - $y1)]

    if {$x_scale_factor < $y_scale_factor} {
	set scale_factor $x_scale_factor
    } else {
	set scale_factor $y_scale_factor
    }
    $itk_component(segment_canvas) move all [expr - $x1] [expr - $y1]
    $itk_component(segment_canvas) scale all 0 0 $scale_factor $scale_factor
    foreach {x1 y1 x2 y2} [$itk_component(segment_canvas) bbox $a_tag] break
    set x_shift [expr (([winfo width $itk_component(segment_canvas)] - $x2) - $x1) / 2]
    set y_shift [expr (([winfo height $itk_component(segment_canvas)] - $y2) - $y1) / 2]
    $itk_component(segment_canvas) move all $x_shift $y_shift

}

# Segment canvas toolbutton methods ##########################################

body ImagePalette::makeDefaultSelection { } {
}

body ImagePalette::uncheckAll { } {
    foreach i_item [array names images_by_item] {
	uncheckImageInclusion $i_item
    }
}

body ImagePalette::checkAll { } {
    foreach i_item [array names images_by_item] {
	checkImageInclusion $i_item
    }
}

body ImagePalette::toggleCheckSegmentsToolbutton { args } {
    $itk_component(uncheck_segment_tb) cancel noexecute
    $itk_component(grab_canvas_tb) cancel noexecute
    foreach i_im [$::session getImages] {
	$itk_component(segment_canvas) bind $i_im <1> [code $this checkImageInclusion $items_by_image($i_im)]
    }
    bind $itk_component(segment_canvas) <ButtonPress-1> [code $this turnSegmentPaintingOn %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-1> [code $this turnSegmentPaintingOff]
    Cursor left_ptr_plus $itk_component(segment_canvas)
}

body ImagePalette::toggleUncheckSegmentsToolbutton { args } {
    $itk_component(check_segment_tb) cancel noexecute
    $itk_component(grab_canvas_tb) cancel noexecute
    foreach i_im [$::session getImages] {
       $itk_component(segment_canvas) bind $i_im <1> [code $this uncheckImageInclusion $items_by_image($i_im)]
    }
    bind $itk_component(segment_canvas) <ButtonPress-1> [code $this turnSegmentWipingOn %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-1> [code $this turnSegmentPaintingOff]
    Cursor left_ptr_minus $itk_component(segment_canvas)
}

body ImagePalette::toggleGrabCanvasToolbutton { args } {
    $itk_component(check_segment_tb) cancel noexecute
    $itk_component(uncheck_segment_tb) cancel noexecute

    bind $itk_component(segment_canvas) <ButtonPress-1> [code $this grabCanvas %x %y]
    bind $itk_component(segment_canvas) <ButtonRelease-1> [code $this releaseCanvas]
    $itk_component(segment_canvas) configure -cursor fleur
}

# Segment canvas interaction methods #####################################

body ImagePalette::turnSegmentPaintingOn { x y } {
    paintSegment $x $y
    bind $itk_component(segment_canvas) <Motion> [code $this paintSegment %x %y]
}

body ImagePalette::turnSegmentPaintingOff { } {
    bind $itk_component(segment_canvas) <Motion> {}
    Cursor left_ptr_plus $itk_component(segment_canvas)
}

body ImagePalette::turnSegmentWipingOn { x y } {
    set last_cursor [$itk_component(segment_canvas) cget -cursor]
    wipeSegment $x $y
    bind $itk_component(segment_canvas) <Motion> [code $this wipeSegment %x %y]
    Cursor left_ptr_minus $itk_component(segment_canvas)
}

body ImagePalette::paintSegment { x y } {
    set l_closest_item [$itk_component(segment_canvas) find closest $x $y]
    set l_tags [$itk_component(segment_canvas) gettags $l_closest_item]
    if {[regexp {image\((\S*)\)} $l_tags match l_image]} {
	checkImageInclusion $items_by_image($l_image)
    }
}

body ImagePalette::wipeSegment { x y } {
    set l_closest_item [$itk_component(segment_canvas) find closest $x $y]
    set l_tags [$itk_component(segment_canvas) gettags $l_closest_item]
    if {[regexp {image\((\S*)\)} $l_tags match l_image]} {
	uncheckImageInclusion $items_by_image($l_image)
    }
}

body ImagePalette::grabCanvas { x y } {
    # Cancel set-view toolbuttons
    $itk_component(fit_all_tb) cancel noexecute
    $itk_component(fit_wedge_tb) cancel noexecute
    # Unbind canvas configure events
    bind $itk_component(segment_canvas) <Configure> {}
    # Store cursor for resetting after release
    set last_cursor [$itk_component(segment_canvas) cget -cursor]
    # Create marker relative to which things should be moved
    $itk_component(segment_canvas) create text $x $y -tags click_position
    # Set up motion bindings to move items
    bind $itk_component(segment_canvas) <Motion> [code $this moveCanvasItems %x %y]
    # Set the canvas cursor to the 4-way arrow
    $itk_component(segment_canvas) configure -cursor fleur
}

body ImagePalette::releaseCanvas { } {
    $itk_component(segment_canvas) delete click_position
    bind $itk_component(segment_canvas) <Motion> {}
    $itk_component(segment_canvas) configure -cursor $last_cursor
}

body ImagePalette::moveCanvasItems { x y } {
    foreach {l_x0 l_y0} [$itk_component(segment_canvas) coords click_position] break
    $itk_component(segment_canvas) move all [expr $x - $l_x0] [expr $y - $l_y0]
}

body ImagePalette::updateProcessWizard { } {
    set l_chosen_images {}
    set l_chosen_image_paths {}
    set l_sorted_image_paths {}
    foreach i_item [array names images_by_item] {
	if {[$itk_component(image_tree) item state get $i_item CHECKED]} {
	    lappend l_chosen_image_paths $image_paths_by_item($i_item)
	}
    }
    if {[llength $l_chosen_image_paths] != 0} {
	set items_in_chosen_image_paths [llength $l_chosen_image_paths]
	if {$items_in_chosen_image_paths > 1 } {
	    set l_sorted_image_paths [lsort $l_chosen_image_paths]
	} elseif {$items_in_chosen_image_paths == 1} {
	    set l_sorted_image_paths $l_chosen_image_paths
	}
    }

    set l_sorted_images {}
    foreach i_path $l_sorted_image_paths {
	lappend l_sorted_images [Image::getImageByPath $i_path]
    }
    $processing_wizard updateImages $l_sorted_images
}

# #########################################################
