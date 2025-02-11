# package name
package provide latticetab 1.0

# Class
class Latticetab {
    inherit itk::Widget Settings2

    # variables
    ###########
    private variable lattice_number
    private variable beam_x
    private variable beam_y

    # Solution list variables
    private variable solution_objects_by_number ; # N.B. array - do not initialize
    private variable solution_items_by_number ; # N.B. array - do not initialize
    private variable solution_numbers_by_item ; # N.B. array - do not initialize
    private variable solution_objects_by_item ; # N.B. array - do not initialize
    private variable solution_item_types ; # N.B. array - do not initialize
    private variable cell_volume_by_solution_number ; # N.B. array - do not initialize
    # suggested solution number from preselection may be updated after refinement
    private variable suggested_solution_number ""
    public variable solutions_cell_view "0"

    # refined cell object
    private variable refined_cell ""
    # chosen solution object
    private variable chosen_solution ""
    # chosen solution type (raw, reg, ref)
    private variable chosen_solution_type ""
    # list of images being autoindexed
    private variable images_being_autoindexed {}

    # methods
    #########
    public method addTreeHeadings
    public method loadPreselectionSolutions
    public method loadRefinedSolution
    public method updateRefinedSolutionAmatrices
    public method getChosenSolution
    public method getRefinedCell
    public method setRefinedCell
    public method getBeamXY
    public method setBeamXY
    public method redisplayPredictions
    public method clear
    private method refineAll
    private method refine
    private method toggleSolution
    private method doubleClickSolution

    # widget callbacks

    constructor { args } {
    }
}

# Bodies

body Latticetab::addTreeHeadings { args } {

    itk_component add solution_tree {
	treectrl $itk_interior.tree \
	    -showline 0 \
	    -showbutton 1 \
	    -selectmode single
	    #-width 670 \
	    #-height 200
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(solution_tree) notify bind $itk_component(solution_tree) <Selection> [code $this toggleSolution %c %S]

    $itk_component(solution_tree) column create -text Solution -tag solution -justify left -minwidth 100 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text Lat. -tag lattice -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text Pen. -tag penalty -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "a" -tag a -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "b" -tag b -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "c" -tag c -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "\u03b1" -tag alpha -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03b2" -tag beta -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03b3" -tag gamma -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "\u03c3(x,y)" -tag sigma_xy -justify center -minwidth 55 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(solution_tree) column create -text "Nref" -tag norefs -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(solution_tree) column create -text "\u03b4 beam" -tag delta_beam -justify center -minwidth 90 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1

    $itk_component(solution_tree) configure -treecolumn 0

    $itk_component(solution_tree) element create e_icon image -image ::img::raw_solution
    $itk_component(solution_tree) element create e_text text -fill {white selected}
    $itk_component(solution_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(solution_tree) style create s1
    $itk_component(solution_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(solution_tree) style layout s1 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(solution_tree) style layout s1 e_text -expand ns
    $itk_component(solution_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
    $itk_component(solution_tree) style create s2
    $itk_component(solution_tree) style elements s2 {e_highlight e_text}
    $itk_component(solution_tree) style layout s2 e_text -expand ns
    $itk_component(solution_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
    
    bind $itk_component(solution_tree) <Double-ButtonPress-1> [ code $this doubleClickSolution %W %x %y ]

    itk_component add solution_scroll {
	scrollbar $itk_interior.scroll \
	    -command [code $this component solution_tree yview] \
	    -orient vertical
    }

    $itk_component(solution_tree) configure \
	-yscrollcommand [code $this component solution_scroll set]

    pack $itk_component(solution_scroll) -side right -fill y
    pack $itk_component(solution_tree) -side top -fill both -expand 1

    eval itk_initialize $args

}

########################################################################
# Usual config options                                                 #
########################################################################

usual Latticetab { 
   #keep -background
   #keep -foreground
   #keep -selectbackground
   #keep -selectforeground
   #keep -textbackground
   #keep -font
   #keep -entryfont
}

body Latticetab::toggleSolution { a_selection_count a_selected } {
  # puts "debug: enter Latticetab::toggleSolution"
  # puts "debug: toggleSolution: a_selection_count a_selected $a_selection_count $a_selected"
  # flush stdout
    if {$a_selection_count > 0} {
	set l_solution $solution_objects_by_item($a_selected)
	set l_solution_number [$l_solution getNumber]
      # puts "debug: l_solution $l_solution l_solution_number $l_solution_number solution_item_types(a_selected) $solution_item_types($a_selected)"
      # flush stdout
	if {$solution_item_types($a_selected) == "raw"} {
	    #$itk_component(solution_tree) selection modify $solution_items_by_number(reg,$l_solution_number) all
	    if {[info exists solution_items_by_number(ref,$l_solution_number)]} {
		#puts "Selected solution is type raw, ref item $solution_items_by_number(ref,$l_solution_number)"
		$itk_component(solution_tree) selection modify $solution_items_by_number(ref,$l_solution_number) all
	    } else {
		#puts "Selected solution is type raw, reg item $solution_items_by_number(reg,$l_solution_number)"
		$itk_component(solution_tree) selection modify $solution_items_by_number(reg,$l_solution_number) all
	    }
	} else {
	    # Get the selected solution object and type
	    set t_item $a_selected
	    set chosen_solution $solution_objects_by_item($t_item)
	    set chosen_solution_type $solution_item_types($t_item)
	    #puts "toggleSolution: chosen_solution_type $solution_item_types($t_item) updating cell"

	    # update the cell before the spacegroup to avoid validateCellAndSpacegroup error
          # puts "debug: call session updateCell"
          # flush stdout
	    $::session updateCell "Indexing" [$chosen_solution getCell] 1 1 0

	    # Check solution number
	    #puts "Lattice $lattice_number solution [$chosen_solution getNumber]"
	    
	    # Get lattice type
	    set l_lattice_type [$chosen_solution getLattice]
          # puts "debug: about to updateSpacegroupCombo l_lattice_type $l_lattice_type"
          # flush stdout
	    [.c component indexing] updateSpacegroupCombo $l_lattice_type

	    # Update client-side variables to reflect results

	    # Get a list of sectors used
	    set l_sectors_to_update {}
	  # puts "debug: images_being_autoindexed: $images_being_autoindexed"
          # flush stdout
	    foreach i_image $images_being_autoindexed {
		if {[lsearch $l_sectors_to_update [$i_image getSector]] < 0} {
		    lappend l_sectors_to_update [$i_image getSector]
		}
	    }
	    #puts "l_sectors_to_update $l_sectors_to_update"

	    # update all used sectors with new matrix
	    #puts "toggleSolution: update all used sectors with new matrix [$chosen_solution getMatrix]"
	    foreach i_sector $l_sectors_to_update {
		#puts "Sector: $i_sector Template: [$i_sector getTemplate] Current sector: [$::session getCurrentSector]"
		#puts "Sect,soln,cell: [$i_sector getTemplate] [$chosen_solution getNumber] [[$chosen_solution getCell] listCell]"
		eval $i_sector updateMatrix "Indexing" [$chosen_solution getMatrix] 1 1 0
	    }
	    
	    # update the spacegroup
	    set l_spacegroup [namespace current]::[Spacegroup \#auto "initialize" "unnamed" [lindex $::spacegroup($l_lattice_type) 0]]
	  # puts "debug: Lattice: $lattice_number type: $l_lattice_type space group: [$l_spacegroup reportSpacegroup]"
          # puts "debug: about to call session updateSpacegroup with l_spacegroup $l_spacegroup"
          # flush stdout
	    $::session updateSpacegroup "Indexing" $l_spacegroup 1 1 0
	    delete object $l_spacegroup
	    
	    # if the solution was refined (so the beam was changed)...
	    if {$chosen_solution_type == "ref"} {
		# update the beam position
              # puts "debug: about to update beam position"
              # flush stdout
		foreach { l_beam_x l_beam_y } [$chosen_solution getBeam] break
		$::session updateSetting beam_x $l_beam_x 1 1 "Indexing" 0
		set beam_x $l_beam_x
		$::session updateSetting beam_y $l_beam_y 1 1 "Indexing" 0
		set beam_y $l_beam_y
		# Update the lattice line
              # puts "debug: about to update lattice line"
              # flush stdout
		[.c component indexing] updateLatticeSummary $lattice_number $chosen_solution $chosen_solution_type
		# If multilattice indexing also update matrices for all solutions
		if { [$::session getMultipleLattices] } {
		    # If no more refinement results are expected...
		    if {![$::mosflm busy "indexing" "index_refinement"]} {
			# try sending the target command
                      # puts "debug: about to try sending the target command"
                      # flush stdout
			$::mosflm sendCommand "target lattice $lattice_number solution [$chosen_solution getNumber] matrix [[$chosen_solution getMatrix] listMatrix]"
		    }
		}
		# Get new predictions
		#puts "toggled Latt: $lattice_number soln:[$chosen_solution getNumber] calling session::updatePredictions"
              # puts "debug: about to update predictions"
              # flush stdout
		$::session updatePredictions
	    } else {
		# update the beam position
              # puts "debug: Not a ref solution, about to update beam"
              # flush stdout
		set beam_x [$::session getParameterValue beam_x]
		set beam_y [$::session getParameterValue beam_y]
		# Update the lattice line
              # puts "debug: Not a ref solution, about to Update the lattice line"
              # flush stdout
		[.c component indexing] updateLatticeSummary $lattice_number $chosen_solution $chosen_solution_type
		# If selected solution is not a refined solution, and refined solution is not present, refine it.
		# This is to enable the function of doubleClickSolution, which seems to have been lost in moving to lattice tabs.
		if {![info exists solution_items_by_number(ref,$l_solution_number)]} {
		    # Refine the reg solution
                  # puts "debug: Not a ref solution, about to call refine"
                  # flush stdout
		    refine $a_selected $lattice_number
		}
	    }
	}

    } else {
	#puts "tS: a_selection_count $a_selection_count"
    }
}

body Latticetab::redisplayPredictions { chosen_solution } {
   # puts "debug: enter Latticetab::redisplayPredictions"
   # flush stdout

    # update the cell before the spacegroup to avoid validateCellAndSpacegroup error
    #puts "redisplayPredictions updating cell"
    $::session updateCell "Indexing" [$chosen_solution getCell] 1 1 0

    # Get lattice type
    set l_lattice_type [$chosen_solution getLattice]
    [.c component indexing] updateSpacegroupCombo $l_lattice_type

    # Update client-side variables to reflect results

    # Get a list of sectors used
    set l_sectors_to_update {}
    #puts "images_being_autoindexed: $images_being_autoindexed"
    foreach i_image $images_being_autoindexed {
	if {[lsearch $l_sectors_to_update [$i_image getSector]] < 0} {
	    lappend l_sectors_to_update [$i_image getSector]
	}
    }
    #puts "l_sectors_to_update $l_sectors_to_update"

    # update all used sectors with new matrix
    #puts "redisplayPredictions: update all used sectors with new matrix [$chosen_solution getMatrix]"
    foreach i_sector $l_sectors_to_update {
	#puts "Sector: $i_sector Template: [$i_sector getTemplate] Current sector: [$::session getCurrentSector]"
	#puts "Sect,soln,cell,matr: $i_sector $chosen_solution [$chosen_solution getCell] [$chosen_solution getMatrix]"
	eval $i_sector updateMatrix "Indexing" [$chosen_solution getMatrix] 1 1 0
    }
    
    # update the spacegroup
    set l_spacegroup [namespace current]::[Spacegroup \#auto "initialize" "unnamed" [lindex $::spacegroup($l_lattice_type) 0]]
    #puts "Lattice: $lattice_number type: $l_lattice_type space group: [$l_spacegroup reportSpacegroup]"
    $::session updateSpacegroup "Indexing" $l_spacegroup 1 1 0
    delete object $l_spacegroup

    # Get new predictions - necessary or not?
    #puts "redoPredns: latt/soln: $lattice_number/[$chosen_solution getNumber]"
    $::session updatePredictions

}

body Latticetab::loadPreselectionSolutions { a_dom images_indexed } {
   # puts "debug: enter Latticetab::loadPreselectionSolutions"
   # flush stdout
    # Clear any previous solutions
    foreach i_solution [array names solution_items_by_object] {
	delete object $i_solution
    }
    array unset solution_objects_by_number *
    array unset solution_objects_by_item *
    array unset solution_items_by_number *
    array unset solution_item_types *

    # Store images being autoindexed
    set images_being_autoindexed $images_indexed

    # Get the lattice_characters element
    set lattice_character_nodes [$a_dom selectNodes //lattice_character]

    # Get the suggest solution number
    set suggested_solution_number [$a_dom selectNodes {normalize-space(/preselection_index_response/suggested_solution/number)}]

    foreach i_lattice_character_node $lattice_character_nodes {
	# create solution objects
	set l_raw_solution [namespace current]::[Solution \#auto "build" "raw" $images_being_autoindexed $i_lattice_character_node]
	set l_reg_solution [namespace current]::[Solution \#auto "build" "reg" $images_being_autoindexed $i_lattice_character_node]
	set l_reg_cell [$l_reg_solution getCell]
	set l_raw_cell [$l_raw_solution getCell]
	
	# Add solution event to history
	$::session addHistoryEventQuickly "SolutionEvent" "Indexing" $l_reg_solution

	# add an item to the solutions tree for the regularized solution
	set l_reg_item [$this.tree item create -button 1]
	$this.tree item style set $l_reg_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2
	foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$l_reg_cell listCell] break 
	$this.tree item complex $l_reg_item \
	    [list [list e_icon -image ::img::reg_solution] [list e_text -text "[$l_reg_solution getNumber] (reg)"]] \
	    [list [list e_text -text "[$l_reg_solution getLattice]"]] \
	    [list [list e_text -text "[format %3d [$l_reg_solution getPenalty]]"]] \
	    [list [list e_text -text "[format %5.1f $l_a]"]] \
	    [list [list e_text -text "[format %5.1f $l_b]"]] \
	    [list [list e_text -text "[format %5.1f $l_c]"]] \
	    [list [list e_text -text "[format %5.1f $l_alpha]"]] \
	    [list [list e_text -text "[format %5.1f $l_beta]"]] \
	    [list [list e_text -text "[format %5.1f $l_gamma]"]] \
	    [list [list e_text -text "-"]] \
	    [list [list e_text -text "-"]] \
	    [list [list e_text -text "-"]]

	$this.tree item firstchild root $l_reg_item

	# Store pointers to solutions and solution items
	set solution_objects_by_number(reg,[$l_reg_solution getNumber]) $l_reg_solution
	set solution_items_by_number(reg,[$l_reg_solution getNumber]) $l_reg_item
	set solution_numbers_by_item($l_reg_item) [$l_reg_solution getNumber]
	set solution_objects_by_item($l_reg_item) $l_reg_solution
	set solution_item_types($l_reg_item) reg

	# add an item to the solutions tree for the raw solution
	set l_raw_item [$this.tree item create]
	$this.tree item style set $l_raw_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2
	foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$l_raw_cell listCell] break 
	$this.tree item complex $l_raw_item \
	    [list [list e_icon -image ::img::raw_solution] [list e_text -text "(raw)"]] \
	    [list [list e_text -text "[$l_raw_solution getLattice]"]] \
	    [list [list e_text -text "[format %3d [$l_raw_solution getPenalty]]"]] \
	    [list [list e_text -text "[format %5.1f $l_a]"]] \
	    [list [list e_text -text "[format %5.1f $l_b]"]] \
	    [list [list e_text -text "[format %5.1f $l_c]"]] \
	    [list [list e_text -text "[format %5.1f $l_alpha]"]] \
	    [list [list e_text -text "[format %5.1f $l_beta]"]] \
	    [list [list e_text -text "[format %5.1f $l_gamma]"]] \
	    [list [list e_text -text "-"]] \
	    [list [list e_text -text "-"]] \
	    [list [list e_text -text "-"]]
	# Add raw item to reg item in tree
	$this.tree item lastchild $l_reg_item $l_raw_item
	# Collapse regularized solution item
	$this.tree item collapse $l_reg_item
	# Store pointer to item in an array indexed by solution number
	set solution_objects_by_number(raw,[$l_raw_solution getNumber]) $l_reg_solution
	set solution_items_by_number(raw,[$l_raw_solution getNumber]) $l_raw_item
	set solution_numbers_by_item($l_raw_item) [$l_raw_solution getNumber]
	set solution_objects_by_item($l_raw_item) $l_raw_solution
	set solution_item_types($l_raw_item) raw
    }

    # Save the session (as history events have been added quickly)
    $::session writeToFile

    # Get the lattice number
    set lattice_number [$a_dom selectNodes normalize-space(//lattice_number)]

    # Get the suggest solution number
    set suggested_solution_number [$a_dom selectNodes {normalize-space(/preselection_index_response/suggested_solution/number)}]
    #puts "Preselection suggested solution: $suggested_solution_number"

    # scroll back to the early solutions
    $itk_component(solution_tree) yview moveto 0

    # Refine all solutions <=50
    # HRP 31.08.2006 was < 200
    $this refineAll
    
}

body Latticetab::refineAll { } {
   # puts "debug: enter Latticetab::refineAll"
   # flush stdout
    foreach i_item [$itk_component(solution_tree) item children root] {
	set l_penalty [$itk_component(solution_tree) item text $i_item penalty]
	# HRP 31.08.2006 was < 200
	if {$l_penalty <= 50} {
	    refine $i_item $lattice_number
	}
    }
}

body Latticetab::refine { { an_item "" } lattice } {
   # puts "debug: enter Latticetab::refine"
   # flush stdout
    
    #if no item is provided use the selected item
    if {$an_item != ""} {
	set l_item $an_item
    } else {
	# Get the selected item
	set l_item [$itk_component(solution_tree) selection get]
    }
    set l_solution_number $solution_numbers_by_item($l_item)

    # Send a refinement request
    $::mosflm index2 $l_solution_number [$::session getSigmaCutoff] $lattice
}

body Latticetab::updateRefinedSolutionAmatrices { a_dom } {
   # puts "debug: enter Latticetab::updateRefinedSolutionAmatrices"
   # flush stdout

    # Get the solution element which contains an A matrix for each refined solution
    set solution_nodes [$a_dom selectNodes //solution]

    foreach i_solution $solution_nodes {
	set num [$i_solution selectNodes {normalize-space(number)}]
	set a11 [$i_solution selectNodes {normalize-space(a_matrix/a11)}]
	set a12 [$i_solution selectNodes {normalize-space(a_matrix/a12)}]
	set a13 [$i_solution selectNodes {normalize-space(a_matrix/a13)}]
	set a21 [$i_solution selectNodes {normalize-space(a_matrix/a21)}]
	set a22 [$i_solution selectNodes {normalize-space(a_matrix/a22)}]
	set a23 [$i_solution selectNodes {normalize-space(a_matrix/a23)}]
	set a31 [$i_solution selectNodes {normalize-space(a_matrix/a31)}]
	set a32 [$i_solution selectNodes {normalize-space(a_matrix/a32)}]
	set a33 [$i_solution selectNodes {normalize-space(a_matrix/a33)}]

	if {[info exists solution_objects_by_number($num)]} {
	    # Get the solution object from the number
	    set l_soln_object $solution_objects_by_number($num)
    
	    # Get the matrix from the solution object
	    set l_matrix [$l_soln_object getMatrix]
    
	    # Update this solution's matrix with returned values
	    $l_matrix setMatrix $a11 $a12 $a13 $a21 $a22 $a23 $a31 $a32 $a33
    
	    #puts "$num: $a11 $a12 $a13 $a21 $a22 $a23 $a31 $a32 $a33"
	}
    }
}

body Latticetab::loadRefinedSolution { a_dom } {
  # puts "debug: Enter Latticetab::loadRefinedSolution"
  # flush stdout
    # Find out which solution it belongs to
    set l_sol_num [$a_dom selectNodes normalize-space(/refined_index_response/solution_number)]
    # See if regular solution item already exists
    if {[info exists solution_items_by_number(reg,$l_sol_num)]} {
	# Get the reg solution object for this result
	set l_reg_solution $solution_objects_by_number(reg,$l_sol_num)
	# Create refined solution object
	set l_ref_solution [namespace current]::[RefinedSolution \#auto "build" $l_reg_solution $a_dom]
    } else {
	# Coming from beam search with no preselection solutions stored
	set l_ref_solution [namespace current]::[RefinedSolution \#auto "build" $l_sol_num $a_dom]
    }
    set l_ref_cell [$l_ref_solution getCell]
    set l_ref_volume [$l_ref_solution getVolume]

    # Add solution event to history
    $::session addHistoryEventQuickly "SolutionEvent" "Indexing" $l_ref_solution
    #puts "add History ref.soln. $l_sol_num cell [$l_ref_cell listCell]"
       
    # See if refined solution item already exists
    if {![info exists solution_items_by_number(ref,$l_sol_num)]} {
      # puts "debug: refined solution item already exists $l_sol_num"
      # flush stdout
	# add an item to the solutions tree for the regularized solution
	set l_ref_item [$itk_component(solution_tree) item create -button 1]
	# Add this new solution to the tree
	$itk_component(solution_tree) item lastchild root $l_ref_item
	# Move reg item for this solution to subtree
	$itk_component(solution_tree) item lastchild $l_ref_item $solution_items_by_number(reg,$l_sol_num)
	# Remove button from raw solution
	$itk_component(solution_tree) item configure  $solution_items_by_number(raw,$l_sol_num) -button 0
	# Remove solution number from reg solution
	$itk_component(solution_tree) item element configure $solution_items_by_number(reg,$l_sol_num) 0 e_text -text "(reg)"
	# Collapse refined solution item
	$itk_component(solution_tree) item collapse $l_ref_item
    } else {
      # puts "debug: refined solution item does not already exists $l_sol_num"
      # flush stdout
	set l_ref_item $solution_items_by_number(ref,$l_sol_num)
	# Delete previous solution object
	delete object $solution_objects_by_item($l_ref_item)
    }

    # Update item's details
  # puts "debug: update item's details"
  # flush stdout
    $itk_component(solution_tree) item style set $l_ref_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2
    foreach { l_a l_b l_c l_alpha l_beta l_gamma } [$l_ref_cell listCell] break 

    $itk_component(solution_tree) item complex $l_ref_item \
	[list [list e_icon -image ::img::ref_solution] [list e_text -text "[$l_ref_solution getNumber] (ref)"]] \
	[list [list e_text -text "[$l_ref_solution getLattice]"]] \
	[list [list e_text -text "[format %3d [$l_ref_solution getPenalty]]"]] \
	[list [list e_text -text "[format %5.1f $l_a]"]] \
	[list [list e_text -text "[format %5.1f $l_b]"]] \
	[list [list e_text -text "[format %5.1f $l_c]"]] \
	[list [list e_text -text "[format %5.1f $l_alpha]"]] \
	[list [list e_text -text "[format %5.1f $l_beta]"]] \
	[list [list e_text -text "[format %5.1f $l_gamma]"]] \
	[list [list e_text -text "[format %4.2f [$l_ref_solution getSpotDevPos]]"]] \
	[list [list e_text -text "[format %4d [$l_ref_solution getReflectionsUsed]]"]] \
	[list [list e_text -text "[format %4.2f [$l_ref_solution getBeamShiftAbs]] ([format %4.1f [$l_ref_solution getBeamShiftRel]])"]]

    # Store pointer to item in an array indexed by solution number
    set solution_items_by_number(ref,$l_sol_num) $l_ref_item
    set solution_numbers_by_item($l_ref_item) $l_sol_num
    # Store pointer to solution in an array indexed by item tag
    set solution_objects_by_item($l_ref_item) $l_ref_solution
    set solution_objects_by_number($l_sol_num) $l_ref_solution
    # Store item type info
    set solution_item_types($l_ref_item) ref

    # Store volume for this solution
    set cell_volume_by_solution_number($l_sol_num) $l_ref_volume

    # Resort the solutions
    $itk_component(solution_tree) item sort root -dictionary

    # Get any new suggested solution number which has been added to this response
    set new_suggested_solution_number [$a_dom selectNodes {normalize-space(/refined_index_response/suggested_solution/number)}]
    if { ($new_suggested_solution_number != "") && ($new_suggested_solution_number != 0) } {
	if { $new_suggested_solution_number != $suggested_solution_number } {
	    # Reset solution suggested
	  # puts "debug: Suggested solution: $suggested_solution_number reset to: $new_suggested_solution_number"
          # flush stdout
	    set suggested_solution_number $new_suggested_solution_number
	} else {
	  # puts "debug: Suggested solution: $suggested_solution_number same as stored"
          # flush stdout
	}
    } else {
      # puts "debug: Suggested solution not sent"
      # flush stdout
    }

    # get the suggested solution item (refined or regularized)
    if {[info exists solution_items_by_number(ref,$suggested_solution_number)]} {
	set l_suggested_solution_item $solution_items_by_number(ref,$suggested_solution_number)
    } else {
	set l_suggested_solution_item $solution_items_by_number(reg,$suggested_solution_number)
    }

    # Re-hilight the suggested solution item regardless to ensure the
    # cell is updated to the refined cell rather than regularized
  # puts "debug: Suggested solution $suggested_solution_number, item $l_suggested_solution_item - updating selection"
  # flush stdout
    # Clear the current selection
    $itk_component(solution_tree) selection clear all
  # puts "debug: cleared current selection"
  # puts "debug: l_suggested_solution_item is $l_suggested_solution_item"
  # flush stdout
    # Select the chosen solution
    $itk_component(solution_tree) selection add $l_suggested_solution_item $l_suggested_solution_item
  # puts "debug: Select the chosen solution"
  # flush stdout

    if { [tk windowingsystem] != "aqua" } {
	# Gave Tcl error on MacOS
	focus $itk_component(solution_tree)
    }
#puts "debug: Exit Latticetab::loadRefinedSolution"
#flush stdout
}

body Latticetab::getRefinedCell { } {
  # puts "debug: enter Latticetab::getRefinedCell"
  # flush stdout
    return $refined_cell
}

body Latticetab::setRefinedCell { cell } {
  # puts "debug: enter Latticetab::setRefinedCell"
  # flush stdout
    set refined_cell $cell
}

body Latticetab::getChosenSolution { } {
  # puts "debug: enter Latticetab::getChosenSolution"
  # flush stdout
    return $chosen_solution
}

body Latticetab::getBeamXY { } {
  # puts "debug: enter Latticetab::getBeamXY"
  # flush stdout
    return [list $beam_x $beam_y]
}

body Latticetab::setBeamXY { l_beamx l_beamy } {
  # puts "debug: enter Latticetab::setBeamXY"
  # flush stdout
    set beam_x $l_beamx
    set beam_y $l_beamy
}

body Latticetab::clear { } {
  # puts "debug: enter Latticetab::clear"
  # flush stdout
    # Clear any previous solutions
    foreach i_solution [array names solution_items_by_object] {
	delete object $i_solution
    }
    array unset solution_objects_by_number *
    array unset solution_items_by_number *
    array unset solution_numbers_by_item *
    array unset solution_objects_by_item *
    array unset solution_item_types *
    $itk_component(solution_tree) item delete all
    array unset cell_volume_by_solution_number *
}

body Latticetab::doubleClickSolution { w x y } {
  # puts "debug: enter Latticetab::doubleClickSolution"
  # flush stdout
    puts "$this w $w x,y $x,$y "
    set id [$w identify $x $y]
    if {$id eq ""} {
	return
    }
    if {[lindex $id 0] eq "item"} {
	foreach {what item where arg1 arg2 arg3} $id break
	if {$arg1 != "button"} {
	    set suggested_solution_number $solution_numbers_by_item($item)
	    refine $lattice_number
	}
    }
}
