package provide indexwizard 0.1
if {$::debugging} {
    puts "flow: entering indexwizard.tcl"
}
class Indexwizard {
    inherit itk::Widget

    
    # Layout variables
    private variable grid_search 0
    private variable grid_counter 0
    private variable index_workflow "true"
    private variable mosaicity_workflow "true"
    private variable index_done 0
    private variable mosaicity_done 0
    public variable doIndexNow "no"

    private variable showbeamsearch 0
    private variable showmultilattice 0

    private variable margin 7
    private variable indent 20
    private variable panel 0

    # List of images to be indexed
    private variable images_list {}
    private variable image_objects_by_number ; # NB array - don't initialize
    private variable image_objects_by_item ; # NB array - don't initialize
    private variable image_items_by_number ; # NB array - don't initialize
    private variable image_items_by_object ; # NB array - don't initialize

    private variable choosing_images "0"
    private variable chosen_images_text ""
    private variable chosen_search_images ""

    # List of images being searched
    private variable images_being_searched {}
    # list of images being autoindexed
    public variable images_being_autoindexed {}

    # Temporary spotfile for indexing
    private variable spotfilename ""
    private variable l_first_image 0
    private variable haveNewSpotfilename 0

    # List of flags indicating whether spotlists should be used
    private variable use_spotlists {}
    
    # List of Lattice tab windows
    private variable path_to_tab ; # NB array - don't initialize
    private variable lattice_by_item ; # NB array - don't initialize
    private variable item_by_lattice ; # NB array - don't initialize

    # Processing options
    private variable result_update_checks {}
    private variable result_update_types {}

    private variable mosaicity ""

    private variable prior_cell ""
    
    private variable max_mosaicity_tested "0"
    private variable mosaicity_values {} ; # N.B. NOT array - do not NOTinitialize
    private variable mosaicity_intensities {} ; # N.B. NOT array - do not NOTinitialize
    private variable mosaicity_intensities_2nd_derivative {} ; # N.B. NOT array - do not NOT initialize


    # array holding result items
    #private variable result_items_by_name ; # N.B. array - do not initialize
    private variable spot_dev_pos ; # N.B. array - do not initialize
    private variable cell_volume ; # N.B. array - do not initialize

    # image tree rollover variables
    private variable prev_rollover_item ""
    private variable prev_rollover_element ""

    # Search types
    private variable searchtype "beam-centre"

    # Methods

    # Start and end
    public method launch
    public method hide
    public method clear
    private method clearLatticeTabs

    public method disable
    public method enable
    private method toggleAbility
    private method updateIndexButton
    public method updateMosaicityButton

    public method indexingRelay
    public method mosaicityRelay

    # Option methods
    private method fixMaxCellEdge
    private method toggleMultipleLattices
    private method addCell

    # Do job (spot finding, indexing and refinement)
    public method findSpots
    public method autoindex
    public method queueAutoindex

    private method pickFirstImage
    private method pickNinetyDegreeImages
    private method chooseImages

    # Process results
    public method readSpotsFile
    public method writeSpotsFile
    public method processSpotsFile
    public method processSpotfindingResults
    public method processIndexingResults
    public method processPrerefinementResult
    public method processRefinedResult
    public method processMosaicityEstimation
    public method processUpdatedAmatrices
    public method processSplitAngle

    # Show results
    # private method refreshSolutions 
    private method showRefinementResults

    # Spot finding methods
    public method addImage
    public method removeImage
    public method getIncludedImages
    private method buildImageTree
    private method imageTreeClick
    private method spotResultClick

    private variable ClickParent ""
    private variable ClickItem ""

    private method imageTreeDoubleClick
    private method checkSpotlistInclusion
    private method uncheckSpotlistInclusion
    private method toggleSpotlistInclusion
    private method toggleImageSelection
    public method updateSpotSummary
    private method updateTotal
    public method updateSpotlists
    public method updateSpotFindingResult
    public method updateSpotReportIsigi
    public method sortSpotFindingResults
    public method editSpots
    public method createImageCheck
    private method updateSpotlistSelection
    private method updateSpotlistInclusions
    private method updateImageNumbers

    public method imageTreeRollover

    # Indexing results method
    public method sortBeamSearchDevn
    public method sortBeamSearchCell
    private method toggleSpacegroup
    public method updateSpacegroupCombo
    public method updateLatticeSummary
    private method rightClickLattice
    private method unknownReasonForFailure
    # Mosaicity and summary methods
    public method estimateMosaicity
    private method createUpdateCheck


    private variable do_not_process_indexing 0
    private variable beam_list {}
    private variable preloop_beam_x
    private variable preloop_beam_y
    public method beamSearchLaunch
    private variable beamSearchTrigger "0"

    public method getNewSpotfilename
    public method getSpotfileFirstImage

    public method gridSearchRelay
    public method sigmaISearchRelay
    public method sigmaISearchAutoindex
    public method beamSearchAutoindex
    public method showBeamSearch
    public method hideBeamSearch
    public method abortBeamSearch
    public method toggleBeamSearchTable
    public method beamTreeDoubleClick

    private method raiseLatticetab
    public method showMultiLattice
    public method hideMultiLattice
    public method toggleMultiLatticeTable
    public method toggleLatticeSelection
    public method toggleLatticefromCombo
    public method getPathToLatticeTab
    public method getItemByLattice
    public method getLatticeByItem

    public method setPriorCell
    public method getPriorCell
    public method indexNow

    private variable selected_lattice "1"

    constructor {args} { }

}

body Indexwizard::constructor { args } {

    itk_option add hull.width hull.height
    
    # Toolbars ###############################################

    itk_component add spotfinding_toolbar {
	frame [.c component toolbar_frame].spotfinding
    }

    # Divider

    itk_component add spotfinding_divider1 {
	frame $itk_component(spotfinding_toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add beam_x_e {
        SettingEntry $itk_component(spotfinding_toolbar).bxe beam_x \
	    -image ::img::beam_x16x16 \
	    -balloonhelp "Beam x position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add beam_y_e {
        SettingEntry $itk_component(spotfinding_toolbar).bye beam_y \
	    -image ::img::beam_y16x16 \
	    -balloonhelp "Beam y position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add distance_e {
        SettingEntry $itk_component(spotfinding_toolbar).de distance \
	    -image ::img::distance16x16 \
	    -balloonhelp "Crystal to detector distance" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add spotfinding_divider2 {
	frame $itk_component(spotfinding_toolbar).div2 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add threshold_e {
        SettingEntry $itk_component(spotfinding_toolbar).te threshold \
	    -image ::img::spot_threshold16x16 \
	    -balloonhelp "Spot finding threshold" \
	    -type "real" \
	    -precision "2" \
	    -minimum "1.00" \
	    -width 4 \
	    -justify right \
	    -state normal 
    }

    itk_component add spot_size_e {
        MultiSettingEntry $itk_component(spotfinding_toolbar).size_e \
	    {spot_size_max_x spot_size_max_y} {} \
	    -image ::img::spot_size16x16 \
	    -balloonhelp "Spot size limit (\u221d median size)" \
	    -type "real" \
	    -precision "2" \
	    -allowblank "0" \
	    -minimum "1.00" \
	    -maximum 10.00 \
	    -defaultvalue "10.00" \
	    -width 4 \
	    -justify right \
	    -state normal
    }

    itk_component add peak_sep_x_e {
        SettingEntry $itk_component(spotfinding_toolbar).psxe spot_separation_x \
	    -image ::img::spot_sep_x16x16 \
	    -balloonhelp "Min spot separation in x" \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -justify right 
    }

    itk_component add peak_sep_y_e {
        SettingEntry $itk_component(spotfinding_toolbar).psye spot_separation_y \
	    -image ::img::spot_sep_y16x16 \
	    -balloonhelp "Min spot separation in y" \
	    -type real \
	    -precision 2 \
	    -maximum 10.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -justify right 
    }
    
    itk_component add splitting_e {
	MultiSettingEntry $itk_component(spotfinding_toolbar).split_e \
	    {spot_splitting_x spot_splitting_y} {} \
	    -image ::img::splitting16x16 \
	    -balloonhelp "Max within-spot peak separation (splitting)" \
	    -type real \
	    -precision 2 \
	    -allowblank 0 \
	    -defaultvalue "0.00" \
	    -maximum 1.00 \
	    -minimum 0.00 \
	    -width 4 \
	    -justify right \
	    -state normal
    }

    itk_component add indexing_toolbar {
	frame [.c component toolbar_frame].indexing
    }

    # Divider

    itk_component add indexing_divider1 {
	frame $itk_component(indexing_toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    # Toolbuttons
    
    itk_component add i_sig_i_e {
        SettingEntry $itk_component(indexing_toolbar).isie i_sig_i \
	    -image ::img::res_cutoff16x16 \
	    -balloonhelp "I/sig(i) threshold for including spots in indexing" \
	    -type "real" \
	    -width "4" \
	    -minimum "0" \
	    -justify right \
	    -state normal \
		-editcommand [code .c uncheckAutothreshCheckbutton]
    }

    itk_component add exclude_ice_tb {
	SettingToolbutton $itk_component(indexing_toolbar).eitb "exclude_ice" \
	    -image ::img::exclude_ice16x16 \
	    -activeimage ::img::exclude_ice_on16x16 \
	    -balloonhelp "Exclude ice rings during spot finding"
    }

    itk_component add exclude_auto_tb {
	SettingToolbutton $itk_component(indexing_toolbar).eatb "exclude_auto" \
	    -image ::img::exclude_auto16x16 \
	    -activeimage ::img::exclude_auto_on16x16 \
	    -balloonhelp "Exclude any spot rings during indexing"
    }

    itk_component add fix_distance_tb {
	SettingToolbutton $itk_component(indexing_toolbar).fdtb "fix_distance_indexing" \
	    -image ::img::fix_distance16x16 \
	    -activeimage ::img::fix_distance_on16x16 \
	    -balloonhelp "Fix distance during indexing"
    }

    itk_component add fix_cell_tb {
	SettingToolbutton $itk_component(indexing_toolbar).fctb "fix_cell_indexing" \
	    -image ::img::fix_cell16x16 \
	    -activeimage ::img::fix_cell_on16x16 \
	    -balloonhelp "Fix cell during indexing"
    }

    itk_component add fix_max_cell_edge_tb {
	SettingToolbutton $itk_component(indexing_toolbar).fmcetb "fix_max_cell_edge" \
	    -image ::img::fix_max_cell_edge16x16 \
	    -activeimage ::img::fix_max_cell_edge_on16x16 \
	    -balloonhelp "Fix the maximum cell edge"
    }

    itk_component add cell_edge_e {
        SettingEntry $itk_component(indexing_toolbar).mce max_cell_edge \
	    -image ::img::max_cell_edge16x16 \
	    -balloonhelp "Max cell edge" \
	    -type "int" \
	    -width 4 \
	    -minimum "0" \
	    -maximum "9999" \
	    -justify right \
	    -state normal \
	    -linkcommand [code $this fixMaxCellEdge]
    }

    itk_component add sigma_cutoff_e {
        SettingEntry $itk_component(indexing_toolbar).sce sigma_cutoff \
	    -image ::img::sigma16x16 \
	    -balloonhelp "Sigma cutoff during refinement" \
	    -type "real" \
	    -precision "2" \
	    -allowblank 0 \
	    -defaultvalue "2.50" \
	    -minimum "0.00" \
	    -maximum "100.00" \
	    -width 4 \
	    -justify right \
	    -state normal 
    }

    # Heading

    itk_component add heading_f {
	frame $itk_interior.hf \
	    -bd 1 \
	    -relief solid
    }

    itk_component add heading_l {
	label $itk_interior.hf.fl \
	    -text "Autoindexing" \
	    -font title_font
    } {
	usual
	ignore -font
    }

    # Spot finding panel
    ##########################################################
    
    itk_component add spotfindingpanel {
	frame $itk_interior.sfp \
	    -borderwidth 0 \
	    -relief raised
    }

    itk_component add image_selection_f {
	frame $itk_interior.sfp.isf
    }

    itk_component add index_controls_f {
	frame $itk_interior.sfp.idxc
    }

    itk_component add spotfindinglabel {
	label $itk_interior.sfp.isf.sfl
    }

    itk_component add image_numbers {
	Imagenumbers $itk_interior.sfp.isf.in \
	    -command [code $this chooseImages]
    }

    itk_component add single_image_button {
	Toolbutton $itk_interior.sfp.isf.sib \
	    -type "amodal" \
	    -image ::img::single_image24x24 \
	    -disabledimage ::img::single_image_disabled24x24 \
	    -command [code $this pickFirstImage] \
	    -balloonhelp " Pick first image in the current sector"
    }
    
    itk_component add ninety_degrees_button {
	Toolbutton $itk_interior.sfp.isf.ndb \
	    -type "amodal" \
	    -image ::img::two_images24x24 \
	    -disabledimage ::img::two_images_disabled24x24 \
	    -command [code $this pickNinetyDegreeImages] \
	    -balloonhelp " Pick two images ~90\u00b0 apart in the current sector"
    }
    
    itk_component add spotfinding_palette_tb {
	Toolbutton $itk_interior.sfp.isf.sptb \
	    -image ::img::many_images24x24 \
	    -disabledimage ::img::many_images_disabled24x24 \
	    -type "modal" \
	    -state "normal" \
	    -balloonhelp " Select images... "
    }

    itk_component add add_spots_tb {
	Toolbutton $itk_interior.sfp.isf.aspf \
	    -image ::img::openfile24x24trans \
	    -balloonhelp "Read spots file..." \
	    -command [code .c addSpots]
    }

    itk_component add save_spots_tb {
	Toolbutton $itk_interior.sfp.isf.sspf \
	    -image ::img::savefile24x24 \
	    -balloonhelp "Save spots file..." \
	    -command [code .c saveSpots]
    }

    itk_component add spotfinding_palette {
	SpotfindingPalette .sfp \
	    -alignwidget $itk_component(spotfindinglabel)
    } { }

     $itk_component(spotfinding_palette_tb) configure \
 	-command [list $itk_component(spotfinding_palette) launch $itk_component(spotfinding_palette_tb)]

    itk_component add tree_frame {
	frame $itk_interior.sfp.tf
    }

    itk_component add image_tree {
	treectrl $itk_interior.sfp.tf.itree \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width 430 \
	    -height 72 \
	    -itemheight 18
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(image_tree) column create -text "Image" -justify left -minwidth 80 -expand 1
    $itk_component(image_tree) column create -text "\u03c6 range" -justify left -minwidth 120 -expand 1
    $itk_component(image_tree) column create -text "Auto" -justify center -minwidth 60 -expand 1 
    $itk_component(image_tree) column create -text "Man" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "Del" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "> I/\u03c3(I)" -justify center -minwidth 80 -expand 1
    $itk_component(image_tree) column create -text "Find"  -justify center -minwidth 60 -tag search
    $itk_component(image_tree) column create -text "Use"  -justify center -minwidth 30 -tag use

    $itk_component(image_tree) state define CHECKED
    $itk_component(image_tree) state define AVAILABLE

    $itk_component(image_tree) element create e_icon image -image ::img::image
    $itk_component(image_tree) element create e_text text -fill {white selected}
    $itk_component(image_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(image_tree) element create e_auto_search image -image { ::img::spot_search_auto {} }
    $itk_component(image_tree) element create e_check image -image { ::img::embed_check_on {CHECKED AVAILABLE} ::img::embed_check_off {AVAILABLE !CHECKED} ::img::embed_check_off_disabled {!AVAILABLE} }
	
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
    $itk_component(image_tree) style elements s3 {e_highlight e_auto_search }
    $itk_component(image_tree) style layout s3 e_highlight -union [list e_auto_search] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s3 e_auto_search -expand ns -padx {2 2}

    $itk_component(image_tree) style create s4
    $itk_component(image_tree) style elements s4 {e_highlight e_check}
    $itk_component(image_tree) style layout s4 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s4 e_check -expand ns -padx {2 2}

    itk_component add detailmenu {
	menu $itk_component(image_tree).context -tearoff 0
    }
    
    $itk_component(detailmenu) add command -label "details" -command [code $this spotResultClick]

    bind $itk_component(image_tree) <3> [code tk_popup $itk_component(detailmenu) %X %Y]

    bind $itk_component(image_tree) <ButtonPress-1> [code $this imageTreeClick %W %x %y]
    bind $itk_component(image_tree) <Double-ButtonPress-1> [code $this imageTreeDoubleClick %W %x %y]
    bind $itk_component(image_tree) <ButtonRelease-1> { break }
    bind $itk_component(image_tree) <Motion> [code $this imageTreeRollover %W %x %y]

    itk_component add image_scroll {
	scrollbar $itk_interior.sfp.tf.iscroll \
	    -command [code $this component image_tree yview] \
	    -orient vertical
    }
    
    $itk_component(image_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(image_scroll)]

    # Set up selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> [code $this toggleImageSelection %S %D] 

    itk_component add total_tree {
	treectrl $itk_interior.sfp.tf.ttree \
	    -showheader 0 \
	    -showroot 1 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width 430 \
	    -height 22 \
	    -itemheight 18
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(total_tree) column create -text "Image" -justify left -minwidth 80 -expand 1 ;#-itembackground {"\#ffffff" "\#e8e8e8"}
    $itk_component(total_tree) column create -text "\u03c6 range" -justify left -minwidth 120 -expand 1
    $itk_component(total_tree) column create -text "Auto" -justify center -minwidth 60 -expand 1 
    $itk_component(total_tree) column create -text "Man" -justify center -minwidth 60 -expand 1
    $itk_component(total_tree) column create -text "Del" -justify center -minwidth 60 -expand 1
    $itk_component(total_tree) column create -text "> I/\u03c3(I)" -justify center -minwidth 80 -expand 1
    $itk_component(total_tree) column create -text "Find"  -justify center -minwidth 60 -tag search
    $itk_component(total_tree) column create -text "Use"  -justify center -minwidth 30 -tag use

    $itk_component(total_tree) element create e_icon image -image ::img::spotlist
    $itk_component(total_tree) element create e_text text -fill {white selected}
    $itk_component(total_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(total_tree) style create s1
    $itk_component(total_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(total_tree) style layout s1 e_icon -expand ns -padx {0 6}
    $itk_component(total_tree) style layout s1 e_text -expand ns
    $itk_component(total_tree) style layout s1 e_highlight -union [list e_icon e_text] -iexpand nse -ipadx 2
    
    $itk_component(total_tree) style create s2
    $itk_component(total_tree) style elements s2 {e_highlight e_text}
    $itk_component(total_tree) style layout s2 e_text -expand ns
    $itk_component(total_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    $itk_component(total_tree) item style set root 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2
    $itk_component(total_tree) item text root 0 "Total" 1 "" 2 0 3 0 4 0 5 0

    itk_component add spotselectionlabel {
	label $itk_interior.sfp.ssl \
	    -text "Spots:"
    }

    itk_component add spotselectionframe {
	frame $itk_interior.sfp.ssf \
	    -bd 2 \
	    -relief sunken
    } {
	usual
	rename -background -textbackground textBackground Background
    }

    itk_component add spotcanvas {
	canvas $itk_interior.sfp.ssf.spotcanvas \
	    -width 200 \
	    -height 200 \
	    -borderwidth 0 \
	    -relief solid \
	    -highlightthickness 0
    } {
	usual
	rename -background -textbackground textBackground Background
    }

    itk_component add index_button {
	#ExpandButton $itk_interior.sfp.ib
	button $itk_interior.sfp.idxc.ib \
	    -text "Index" \
	    -pady 2 \
	    -width 15 \
	    -command [code $this queueAutoindex]
    }

    #$itk_component(index_button) add "Index multiple lattices" [code $this queueAutoindex 1]

    itk_component add index_mx {
	Toolbutton $itk_interior.sfp.idxc.indml \
	    -image ::img::boxesall16x16 \
	    -activeimage ::img::boxesall16x16 \
	    -disabledimage ::img::boxes_disabled16x16 \
	    -command [ code $this toggleMultipleLattices ] \
	    -balloonhelp "Index multiple lattices"
    }

    itk_component add index_cell {
	Toolbutton $itk_interior.sfp.idxc.prior \
    	    -type "amodal" \
	    -image ::img::cell \
	    -command [ code $this addCell ] \
	    -balloonhelp "Give known cell before indexing"
    }

    # Solutions panel
    ##########################################################
    
    itk_component add solutionspanel {
	frame $itk_interior.slp \
	    -borderwidth 0 \
	    -relief raised
    }

    itk_component add beamsearchlabel {
	button $itk_interior.slp.bsl \
	    -text "Start beam search" \
	    -command [code $this beamSearchLaunch]
    }

    itk_component add beamsearchexpander {
	button $itk_interior.slp.bse \
	    -text "Show" \
	    -command [code $this toggleBeamSearchTable]
    }

    itk_component add beamsearch_tree {
	treectrl $itk_interior.slp.bstree \
	    -showline 0 \
	    -showbutton 1 \
	    -selectmode single \
	    -height 120
	    #-width 670
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(beamsearch_tree) column create -text "Beam x" -tag start_beamx -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "Beam y" -tag start_beamy -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "Beam x ref" -tag ref_beamx -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "Beam y ref" -tag ref_beamy -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1

    $itk_component(beamsearch_tree) column create -text "a" -tag a -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "b" -tag b -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "c" -tag c -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b1" -tag alpha -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b2" -tag beta -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b3" -tag gamma -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03c3(x,y)" -tag sigma_xy -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03c3(\u03c6)" -tag sigma_phi -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(beamsearch_tree) column create -text "\u03b4 beam" -tag delta_beam -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1

    $itk_component(beamsearch_tree) configure -treecolumn 0

    $itk_component(beamsearch_tree) element create e_text text -fill {white selected}
    $itk_component(beamsearch_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }

    $itk_component(beamsearch_tree) style create s2
    $itk_component(beamsearch_tree) style elements s2 {e_highlight e_text}
    $itk_component(beamsearch_tree) style layout s2 e_text -expand ns
    $itk_component(beamsearch_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2

    bind $itk_component(beamsearch_tree) <Double-ButtonPress-1> [code $this beamTreeDoubleClick %W %x %y]

    itk_component add multilatticelabel {
	label $itk_interior.slp.mll \
	    -text "Lattices:"
    }

    itk_component add multilatticeexpander {
	button $itk_interior.slp.mle \
	    -text "Show" \
	    -command [code $this toggleMultiLatticeTable]
	#label $itk_interior.slp.mle
	#    -text "\[Show\]"
    }

    itk_component add multilattice_tree {
	treectrl $itk_interior.slp.mltree \
	    -showline 0 \
	    -showbutton 1 \
	    -selectmode single \
	    -height 95
	    #-width 670
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(multilattice_tree) column create -text "Lattice" -tag latt_number -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(multilattice_tree) column create -text "Symbol" -tag latt_symbol -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(multilattice_tree) column create -text "Penalty" -tag latt_penalty -justify center -minwidth 40 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(multilattice_tree) column create -text "a" -tag latt_a -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(multilattice_tree) column create -text "b" -tag latt_b -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(multilattice_tree) column create -text "c" -tag latt_c -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(multilattice_tree) column create -text "\u03b1" -tag latt_alpha -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(multilattice_tree) column create -text "\u03b2" -tag latt_beta -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(multilattice_tree) column create -text "\u03b3" -tag latt_gamma -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(multilattice_tree) column create -text "\u03c3(x,y)" -tag latt_sigma_xy -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -font font_s -expand 1
    $itk_component(multilattice_tree) column create -text "Nref" -tag latt_norefs -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1
    $itk_component(multilattice_tree) column create -text "Split" -tag latt_split -justify center -minwidth 50 -itembackground {"\#ffffff" "\#e8e8e8"} -expand 1

    $itk_component(multilattice_tree) configure -treecolumn 0

    $itk_component(multilattice_tree) element create e_text text -fill {white selected}
    $itk_component(multilattice_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }

    $itk_component(multilattice_tree) style create s2
    $itk_component(multilattice_tree) style elements s2 {e_highlight e_text}
    $itk_component(multilattice_tree) style layout s2 e_text -expand ns
    $itk_component(multilattice_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew

    $itk_component(multilattice_tree) notify bind $itk_component(multilattice_tree) <Selection> [code $this toggleLatticeSelection %S]

    itk_component add contextmenu {
	menu $itk_component(multilattice_tree).context -tearoff 0
    }
    
    $itk_component(contextmenu) add command -label "delete" -command [code $this rightClickLattice]

    bind $itk_component(multilattice_tree) <3> [code tk_popup $itk_component(contextmenu) %X %Y]

    # Rather than adding one solution tree, add a tabbed notebook containing a solution tree for each lattice found

    # Add canvas for the notebook
    itk_component add solution_canvas {
	canvas $itk_component(solutionspanel).canvas
    }
    pack $itk_component(solution_canvas) -side top -fill both -expand 1

    # Add tabbed notebook
    itk_component add tabs {
        iwidgets::tabnotebook $itk_component(solution_canvas).tabs \
	    -tabpos n \
	    -background "#dcdcdc" \
	    -tabbackground "#a9a9a9" \
	    -foreground "black" \
	    -tabforeground "black" \
	    -backdrop "#dcdcdc" \
	    -angle "0" \
	    -bevelamount "3" \
	    -margin "0" \
	    -start "0" \
	    -gap "2" \
	    -padx "5" \
	    -font font_l \
	    -raiseselect 1 \
	    -borderwidth 0 ;# 3 just to see how things pack
    } {
        keep -background
        keep -width
    }
    # Hack to fix bug since tcl 8.4 in iwidgets::tabnotebook
    [$itk_component(tabs) component tabset] component hull configure -padx 0 -pady 0
    pack $itk_component(tabs) -side top -fill both -expand 1;# -padx 7 -pady 7

    # Lattice 1 is no longer added here as a special case its tab is added as a result of indexing
    # Add all lattice tabs, pack & add column headings as lattice results arrive from indexing

    itk_component add beamsearchscrollbar {
	scrollbar $itk_interior.slp.beamsearchscrollbar \
	    -command [code $this component beamsearch_tree yview] \
	    -orient vertical
    }

    $itk_component(beamsearch_tree) configure \
	-yscrollcommand [code $this component beamsearchscrollbar set]

    itk_component add multilatticescrollbar {
	scrollbar $itk_interior.slp.multilatticescrollbar \
	    -command [code $this component multilattice_tree yview] \
	    -orient vertical
    }

    $itk_component(multilattice_tree) configure \
	-yscrollcommand [code $this component multilatticescrollbar set]

    itk_component add spacegroupslabel {
	label $itk_interior.slp.spacegroupslabel \
	    -text "Spacegroup: "
    }

    itk_component add priorcelllabel {
	label $itk_interior.slp.priorcelllabel \
	    -text " Prior cell: "
    }

    itk_component add spacegroupcombo {
	combobox::combobox $itk_interior.slp.spacegroupcombo \
	    -width 8 \
	    -editable 1 \
	    -highlightcolor black \
	    -command [code $this toggleSpacegroup]
    } {
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }

    itk_component add mosaicity_l {
	label $itk_interior.slp.ml \
	    -text "Mosaicity: "
    }

    itk_component add mosaicity_e {
	SettingEntry $itk_interior.slp.me mosaicity \
	    -image ::img::mosaicity \
	    -type real \
	    -precision 2 \
	    -width 8 \
	    -minimum 0 \
	    -maximum 10 \
	    -justify right
    }

    itk_component add mosaicity_estimate_b {
	button $itk_interior.slp.meb \
	    -text "Estimate" \
	    -width 7 \
	    -pady 2 \
	    -command [code $this estimateMosaicity] \
	    -state disabled
    }

    # Spotfinding Toolbar
    pack $itk_component(spotfinding_divider1) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(beam_x_e) $itk_component(beam_y_e) $itk_component(distance_e) -side left -padx 2

    pack $itk_component(spotfinding_divider2) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(threshold_e) $itk_component(spot_size_e) $itk_component(peak_sep_x_e) $itk_component(peak_sep_y_e) $itk_component(splitting_e) $itk_component(exclude_ice_tb) \
 	-side left \
	-padx 2

    # Indexing Toolbar
    pack $itk_component(indexing_divider1) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(i_sig_i_e) $itk_component(exclude_auto_tb) $itk_component(fix_distance_tb) $itk_component(fix_cell_tb) $itk_component(fix_max_cell_edge_tb) $itk_component(cell_edge_e) $itk_component(sigma_cutoff_e) \
 	-side left \
	-padx 2

    # Heading
    pack $itk_component(heading_f) -side top -fill x -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5

    # Panels
    # pack the button panel only, the other panels will be packed
    # and unpacked according to other events
    ###############################################################

    # Frames
    pack $itk_component(spotfindingpanel) -side top -fill both -pady [list $margin 0]
    pack $itk_component(solutionspanel) -side top -fill both -expand 1 -pady [list 0 $margin]

    # Spot finding panel
    ###############################################################
	
    grid x $itk_component(image_selection_f) - $itk_component(index_controls_f) x -sticky we
    grid x $itk_component(tree_frame) - $itk_component(spotselectionframe) x -sticky nswe
    grid columnconfigure $itk_component(spotfindingpanel) { 0 2 4 } -minsize $margin
    grid columnconfigure $itk_component(spotfindingpanel) { 1 } -weight 1
    grid rowconfigure $itk_component(spotfindingpanel) { 2 } -weight 1

    pack $itk_component(spotfindinglabel) -side left -anchor n -pady 10
    pack $itk_component(image_numbers) -side left -fill x -expand 1 -anchor n -pady 6
    pack $itk_component(save_spots_tb) $itk_component(add_spots_tb) $itk_component(spotfinding_palette_tb) $itk_component(ninety_degrees_button) \
	$itk_component(single_image_button) -side right; # -anchor n
    pack $itk_component(index_button) $itk_component(index_mx) $itk_component(index_cell) -side left -fill x -expand 1

    grid $itk_component(image_tree) $itk_component(image_scroll) -sticky nswe
    grid $itk_component(total_tree) ^ -sticky nswe
    grid columnconfigure $itk_component(tree_frame) { 0 } -weight 1
    grid rowconfigure $itk_component(tree_frame) { 0 } -weight 1

    grid $itk_component(spotcanvas) -sticky nswe
    grid columnconfigure $itk_component(spotselectionframe) { 0 } -weight 1
    grid rowconfigure $itk_component(spotselectionframe) { 0 }  -weight 1
    
    # Solutions panel
    ###############################################################

    # Changed to tab notebook for first & any subsequent lattices
    grid x $itk_component(solution_canvas) - - - - x -rowspan 2 -sticky nswe

    grid x $itk_component(beamsearch_tree) - - - $itk_component(beamsearchscrollbar) x -sticky nswe

    grid remove $itk_component(beamsearch_tree)
    grid remove $itk_component(beamsearchscrollbar)


    grid x $itk_component(multilattice_tree) - - - $itk_component(multilatticescrollbar) x -sticky nswe
    grid remove $itk_component(multilattice_tree)
    grid remove $itk_component(multilatticescrollbar)

    grid x $itk_component(multilatticelabel) $itk_component(multilatticeexpander) x -row 3 -sticky w
    grid x x x $itk_component(beamsearchlabel) $itk_component(beamsearchexpander) -row 3 -sticky e
    grid x $itk_component(spacegroupslabel) $itk_component(spacegroupcombo) $itk_component(priorcelllabel) -sticky we
    grid x $itk_component(mosaicity_l) $itk_component(mosaicity_e) $itk_component(mosaicity_estimate_b) -sticky w

    grid columnconfigure $itk_component(solutionspanel) {0 5} -minsize $margin
    grid columnconfigure $itk_component(solutionspanel) 3 -weight 1
    grid rowconfigure $itk_component(solutionspanel) 1 -weight 1

    eval itk_initialize $args

}

# Launch and completion methods #####################################

body Indexwizard::launch { } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::launch"
    }
    if {[.ats component indexing getAutoindexingRelayBool]} {
	trace add variable [scope index_workflow] write "indexingRelay"
	trace add variable [scope mosaicity_workflow] write "mosaicityRelay"
    } else {
	trace remove variable [scope index_workflow] write "indexingRelay"
	trace remove variable [scope mosaicity_workflow] write "mosaicityRelay"
    }
    # Show stage
    grid $itk_component(hull) -row 0 -column 1 -sticky nswe

    # show toolbars
    pack $itk_component(spotfinding_toolbar) -in [.c component toolbar_frame] -side left
    # following was to help debug how the indexing window is restored, to see if the full
    # results could be presented after reading a saved session file. In fact, they cannot
    # be displayed without extensive programming.
    # if {[$::session getIntegrationDone] != ""  } {
    #    if {[$::session getIntegrationDone] } {
    #        puts "flow: RETURNING*****"
    #        return
    #	}
    #}

    pack $itk_component(indexing_toolbar) -in [.c component toolbar_frame] -side left

    $itk_component(spot_size_e) update
    $itk_component(splitting_e) update
    # The following added in case mosaicity edited in Images pane
    $itk_component(mosaicity_e) update [$::session getMosaicity]
    
    # Show any prior cell to be used in autoindexing??
    if { $prior_cell != "" } {
        #$itk_component(priorcelllabel) configure -text " Prior cell: [$prior_cell listCell]"	
    }

    # Recover any images and spot lists if reading a saved session file
    if { [$::session hasHistoryEvents]} {
        set images_list [$::session getImagesLastIndexed]
        if {$::debugging} {
            puts "flow: recovered images from history: $images_list"
        }
    }
    if {$::debugging} {
        puts "flow: getSpotfindingRelayBool [.ats component spotfinding getSpotfindingRelayBool]"
        puts "flow: getAutoindexingRelayBool [.ats component indexing getAutoindexingRelayBool]"
        puts "flow: indexing list is: [$::session getIndexingList]"
        puts "flow: integration done flag is [$::session getIntegrationDone]"
    }
# Changed next line to test "indexing getAutoindexingRelayBool" in place of 
# "spotfinding getSpotfindingRelayBool"
# to stop unwanted indexing on entering Indexing pane after a different step. AGWL 11/6/18
    if { [$::session getIndexingList] != "" && [.ats component indexing getAutoindexingRelayBool] } {
	# Check if the 'fastload' list has two images
	if { [llength [$::session getIndexingList]] > 1 } {
            if {$::debugging} {
	        puts "flow: Reading indexing list from getglobbedImages: [$::session getIndexingList]"
            }
	    set images_list [$::session getIndexingList]
	}
    }
 
    # if images are selected...
    if { $images_list != "" } {
        #puts "Calling getCurrentSector in Indexwizard launch"
        if {$::debugging} {
            puts "flow: images are selected, images_list is $images_list"
            puts "flow: calling chooseImages"
        }
	chooseImages [[$::session getCurrentSector] getTemplate] $images_list
        if {$::debugging} {
            puts "flow: queueAutoindex from within launch" 
        }
	if {![ $::session getSessionFileRead ]  } {
            queueAutoindex
        }
    } else {
	# if no images are selected...
	# and no spot search is taking place...
        if {$::debugging} {
            puts "flow: No images selected"
        }
	if {![$::mosflm busy "spot_finding"]} {
	    if {[.ats component spotfinding getSpotfindingRelayBool]} {
		# Switch may be on but images may have been adjusted
		if {[$itk_component(image_numbers) getContent] == ""} {
		    # pick two 90 degrees apart
                    if {$::debugging} {
                        puts "flow: pick images 90 degrees apart"
                    }
		    $itk_component(ninety_degrees_button) invoke
		}
	    } else {
		if {[$itk_component(image_numbers) getContent] == ""} {
		    #no images in box, not busy spot finding & not searching for two reference images
                    if {$::debugging} {
                        puts "flow: *** Disabling Index button in Indexwizard::launch"
                    }
		    $itk_component(index_button) configure -state disabled
		    $itk_component(index_mx) configure -state disabled
                }
	    }
	}
    }	
    if { [$::session getIndexingList] != "" } {
	# If used re-enters Indexing pane the list would be read again if still present
        if {$::debugging} {
            puts "flow: call ::session setIndexingList"
        }
	$::session setIndexingList ""
    }
    if {$::debugging} {
        puts "flow: about to exit Indexwizard launch"
    }
}

body Indexwizard::indexingRelay {name1 name2 ops} {
    #puts "Called indexingRelay \"$name1\" \"$name2\" \"$ops\" IndexingRelayBool [$::session getIndexingRelayBool]"
    if {[$::session getIndexingRelayBool] == 0} {
        if {$::debugging} {
            puts "flow: call queueAutoindex from Indexwizard::indexingRelay"
        }
	queueAutoindex
	$::session setIndexingRelayBool "1"
	#puts "IndexingRelayBool [$::session getIndexingRelayBool]"
    }
}

body Indexwizard::mosaicityRelay {name1 name2 ops} {
    if {[$::session getMosaicityRelayBool] == 0} {
	# Wait a second before estimating mosaicity in case a saved session file was read and indexing rerun on entering Indexing pane
	after 1000 [code $this estimateMosaicity]
	$::session setMosaicityRelayBool "1"
    }
}

body Indexwizard::toggleMultipleLattices { } {
    # Relabel the Index button to emphasize the mode of Indexing
    set multiple_lattice [expr ![$::session getMultipleLattices]]
    $::session setMultipleLattices $multiple_lattice
    if { $multiple_lattice == "1" } {
	$itk_component(index_button) configure -text "Index Multiple"
	if { [tk windowingsystem] == "aqua" } {
	    $itk_component(index_mx) configure -background red
	}
    } else {
	$itk_component(index_button) configure -text "Index"
	if { [tk windowingsystem] == "aqua" } {
	    $itk_component(index_mx) configure -background "\#dcdcdc"
#	    clearLatticeTabs
	}
    }
    return
}

body Indexwizard::hide { } {

    grid forget $itk_component(hull)
    pack forget $itk_component(spotfinding_toolbar) 
    pack forget $itk_component(indexing_toolbar) 
}

body Indexwizard::clear { } {
    # clear image numbers
    $itk_component(image_numbers) clear
    # delete tree items
    $itk_component(image_tree) item delete all

    # Hide and delete lattice summary tree
    hideMultiLattice
    $itk_component(multilattice_tree) item delete all

    clearLatticeTabs

    $itk_component(total_tree) item text root 0 "Total" 1 0 2 0 3 0 4 0
    # clear associated arrays
    array unset images_list *
    array unset image_objects_by_number *
    array unset image_objects_by_item *
    array unset image_items_by_number *
    array unset image_items_by_object *

    # clear the sort list and beam centre search tree
    array unset spot_dev_pos *
    array unset cell_volume *
    $itk_component(beamsearch_tree) item delete all
    hideBeamSearch
    # clear the spot summary canvas
    $itk_component(spotcanvas) delete all
    # clear the spacegroup
    $itk_component(spacegroupcombo) delete 0 end
    # clear the spacegroup combobox's list and disable it
    $itk_component(spacegroupcombo) list delete 0 end
    $itk_component(spacegroupcombo) configure \
	-state disabled
}

body Indexwizard::clearLatticeTabs { } {

    array unset lattice_by_item *
    array unset item_by_lattice *

    #puts "clearLTs: [array names path_to_tab]"
    foreach lattice [array names path_to_tab] {
	#puts "Lattice $lattice clearing tab"
	if {[info exists path_to_tab($lattice)]} {
	    $path_to_tab($lattice) clear
	}
	# Tabs numbered from zero but now referenced by label text
	$itk_component(tabs) delete "Lattice $lattice"
	#puts "Unsetting $path_to_tab($lattice)"
	unset path_to_tab($lattice)

	$::session setCellBeenEdited $lattice 0
    }

    # Empty the session's lattice list
    catch {$::session unsetLatticeList}

    # Reset the Lattice combo to a list of one in Image display
    .image setLatticeComboValues [list 1]
    
}

body Indexwizard::disable { } {
    toggleAbility disabled
}

body Indexwizard::enable { } {
    if {$::debugging} {
        puts "flow: Indexwizard::enable calling toggleAbility normal then updateIndexButton"
    }
    toggleAbility normal
    updateIndexButton
    updateMosaicityButton
    $itk_component(beamsearchlabel) configure -fg \#000000
}

body Indexwizard::toggleAbility { a_state } {
    if {$::debugging} {
        puts "flow: *** Indexwizard::toggleAbility setting state to $a_state"
    }
    $itk_component(index_button) configure -state $a_state
    $itk_component(index_mx) configure -state $a_state
    $itk_component(image_numbers) configure -state $a_state
    $itk_component(single_image_button) configure -state $a_state
    $itk_component(ninety_degrees_button) configure -state $a_state
    $itk_component(spotfinding_palette_tb) configure -state $a_state
    $itk_component(spacegroupcombo) configure -state $a_state
    $itk_component(mosaicity_estimate_b) configure -state $a_state
}

# #########################

body Indexwizard::addImage { an_image } {
    if {$::debugging} {
        puts "flow: enter Indexwizard::addImage to add image: $an_image"
    }
    # Only add if it isn't already there!
    if {![info exists image_items_by_object($an_image)]} {
	#puts "addImage: item for image object $an_image does not exist"
	# Choose labelling method depending on number of templates
	if {[llength [$::session getSectors]] > 1} {
	    set l_labelMethod "getRootName"
	} else {
	    set l_labelMethod "getNumber"
	}

	# create a new item
	set t_item [$itk_component(image_tree) item create]
	# set the item's style
	$itk_component(image_tree) item style set $t_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s3 7 s4
	# get the label to be used
	set l_label [$an_image $l_labelMethod]
	# update the text summaries
	$itk_component(image_tree) item text $t_item 0 $l_label 
	$itk_component(image_tree) item text $t_item 1 [$an_image reportPhis -mode "range"]
	# Set state to indicate spots are available from this image (and checked)
	$itk_component(image_tree) item state set $t_item [list AVAILABLE CHECKED]
	# add the new item to the tree
	$itk_component(image_tree) item lastchild root $t_item
	# Store pointer to image objects and items by number, item or object
	set image_objects_by_number([$an_image getNumber]) $an_image
	set image_objects_by_item($t_item) $an_image
	set image_items_by_number([$an_image getNumber]) $t_item
	set image_items_by_object($an_image) $t_item
    } else {
	#puts "addImage: image_items_by_object($an_image) $image_items_by_object($an_image)"
    }

    # Update the spot finding results
    updateSpotFindingResult $an_image

    # check for inclusion in the palette
    $itk_component(spotfinding_palette) checkImage $an_image

    # update the spot summary
    updateSpotSummary

    # Update summary labels
    updateImageNumbers
    if {$::debugging} {
        puts "flow: exit Indexwizard::addImage"
    }

}

body Indexwizard::removeImage { an_image } {
    if {$::debugging} {
        puts "flow: enter Indexwizard::removeImage to remove: $an_image"
    }
    #puts "removeImage $an_image"
    # Delete item from tree
    $itk_component(image_tree) item delete $image_items_by_object($an_image)

    #puts "removeImage - unsetting the following:"
    #puts "image_objects_by_number([$an_image getNumber]) $image_objects_by_number([$an_image getNumber])"
    #puts "image_objects_by_item($image_items_by_object($an_image)) $image_objects_by_item($image_items_by_object($an_image))"
    #puts "image_items_by_number([$an_image getNumber]) $image_items_by_number([$an_image getNumber])"
    #puts "image_items_by_object($an_image) $image_items_by_object($an_image)"

    # clear array entries
    array unset image_objects_by_number [$an_image getNumber]
    array unset image_objects_by_item $image_items_by_object($an_image)
    array unset image_items_by_number [$an_image getNumber]
    array unset image_items_by_object $an_image

    #puts "array names image_items_by_number [array names image_items_by_number]"
    #puts "array names image_items_by_object [array names image_items_by_object]"

    # uncheck in palette
    $itk_component(spotfinding_palette) uncheckImage $an_image

    # Update the spot summary
    updateSpotSummary
    # Update summary labels
    updateImageNumbers
    if {$::debugging} {
        puts "flow: exit Indexwizard::removeImage"
    }

}

body Indexwizard::getIncludedImages { } {
    return [array names image_items_by_object]
}

body Indexwizard::updateTotal { } {
    set l_auto 0
    set l_manual 0
    set l_deleted 0
    set l_total 0
    foreach i_image [array names image_items_by_object] {
	set l_spotlist [$i_image getSpotlist]
	incr l_auto [format %3d [$l_spotlist getAuto]]
	incr l_manual [format %3d [$l_spotlist getManual]]
	incr l_deleted [format %3d [$l_spotlist getDeleted]]
	incr l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
    }
    $itk_component(total_tree) item text root 1 "" 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total 

    #if not spot finding...
    if {![$::mosflm busy "spot_finding"]} {
	# Update index button if enough spots are selected
	updateIndexButton
    }
}

body Indexwizard::checkSpotlistInclusion { an_item } {
    # if the spotlist is not available and unchecked don't bother!
    if {(![$itk_component(image_tree) item state get $an_item AVAILABLE]) } {
	#puts "Item $an_item is not available for inclusion"
	return
    }
    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	#puts "Item $an_item is already checked & included"
	return
    }
    # get the item's label
    set l_label [$itk_component(image_tree) item text $an_item 0]
    # make the item  checked...
    $itk_component(image_tree) item state set $an_item CHECKED
    # pick colour according to selectedness
    if {[$itk_component(image_tree) item state get $an_item selected]} {
	set l_colour_over "blue"
	set l_colour_under "green"
    } else {
	set l_colour_over "red"
	set l_colour_under "gold"
    } 
    # Show spots in canvas 
    $itk_component(spotcanvas) itemconfigure "auto_over$l_label" -image ::img::spot_${l_colour_over}_plus3x3
    $itk_component(spotcanvas) itemconfigure "manual_over$l_label" -image ::img::spot_${l_colour_under}_cross3x3
    $itk_component(spotcanvas) itemconfigure "auto_under$l_label" -image ::img::spot_${l_colour_over}_plus3x3
    $itk_component(spotcanvas) itemconfigure "manual_under$l_label" -image ::img::spot_${l_colour_under}_cross3x3
    $itk_component(spotcanvas) raise "all$l_label"
    # Update summary labels
    updateImageNumbers
    if {$::debugging} {
        puts "flow: exit Indexwizard::checkSpotlistInclusion"
    }
}

body Indexwizard::uncheckSpotlistInclusion { an_item } {
    # if the spotlist is not available and checked don't bother!
    if {(![$itk_component(image_tree) item state get $an_item AVAILABLE])} { return }
    if {(![$itk_component(image_tree) item state get $an_item CHECKED])} { return }
    # remove item from tree
    #puts "$this remove item $an_item from tree"
    removeImage $image_objects_by_item($an_item)
}

body Indexwizard::toggleSpotlistInclusion { an_item } {
    set choosing_images 0
    if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	uncheckSpotlistInclusion $an_item
    } else {
	checkSpotlistInclusion $an_item
    }
}

body Indexwizard::toggleImageSelection { a_selected { a_deselected "" } } {
    # if the selected item is checked...
    if {($a_selected != "") && [$itk_component(image_tree) item state get $a_selected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_selected 0]
	# colour its spots
	$itk_component(spotcanvas) itemconfigure "auto_over$l_label" -image ::img::spot_blue_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_over$l_label" -image ::img::spot_blue_cross3x3
	$itk_component(spotcanvas) itemconfigure "auto_under$l_label" -image ::img::spot_green_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_under$l_label" -image ::img::spot_green_cross3x3
	# raise them
	$itk_component(spotcanvas) raise "all$l_label"
    }
    # if the deselected item is checked...
    if {($a_deselected != "") && [$itk_component(image_tree) item state get $a_deselected CHECKED]} {
	# get its label
	set l_label [$itk_component(image_tree) item text $a_deselected 0]
	# colour its spots black
	$itk_component(spotcanvas) itemconfigure "auto_over$l_label" -image ::img::spot_red_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_over$l_label" -image ::img::spot_red_cross3x3
	$itk_component(spotcanvas) itemconfigure "auto_under$l_label" -image ::img::spot_gold_plus3x3
	$itk_component(spotcanvas) itemconfigure "manual_under$l_label" -image ::img::spot_gold_cross3x3
    }
}
    
body Indexwizard::imageTreeClick { w x y } {
    set id [$w identify $x $y]
    set ClickParent $w
    set ClickItem $id
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id break
	if {[lindex $id 5] == "e_check"} {
	    #puts "toggleSpotlistInclusion $item"
	    toggleSpotlistInclusion $item
	} elseif {[lindex $id 5] == "e_auto_search"} {
	    set choosing_images "0"
	    findSpots $image_objects_by_item($item)
	}
    }
}

body Indexwizard::imageTreeDoubleClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_auto_search"} {
	    set choosing_images "0"
	    findSpots $image_objects_by_item($item)
	} elseif {[lindex $id 5] == "e_check"} {
	    toggleSpotlistInclusion $item
	}
    }
}

body Indexwizard::spotResultClick { } {
    set id $ClickItem
    #puts "debug: spotresultclick ClickItem $id"
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	set l_image $image_objects_by_item($item)
	set l_spotlist [$l_image getSpotlist]
	.splw process $l_spotlist $l_image
    }
}

body Indexwizard::beamTreeDoubleClick { w x y } {
    if {![set grid_search]} {
	set id [$w identify $x $y]
	if {$id eq ""} {
	} elseif {[lindex $id 0] eq "header"} {
	} else {
	    set beam_x_search [$itk_component(beamsearch_tree) item text [lindex $id 1] 2]
	    set beam_y_search [$itk_component(beamsearch_tree) item text [lindex $id 1] 3]
            # puts "debug: double click beam_x_search $beam_x_search beam_y_search $beam_y_search"
	    if {[string is double $beam_x_search] && [string is double $beam_y_search]} {
                # puts "debug: resetting all detector parameters"
		$::session resetDetector
                # puts "debug: updating beam_x and beam_y in session, no prediction"
		$::session updateSetting beam_x $beam_x_search 1 1 "Indexing" 0
		$::session updateSetting beam_y $beam_y_search 1 1 "Indexing" 0
                # puts "debug: after updating, beam coords from getBeamPosition [$::session getBeamPosition]"
                # puts "debug: about to reset beam_x beam_y to null in image object"
# Need to reset detector parameters in Image object to null as otherwise these
# will be used in preference to the updated values in Mosflm::getImageParameterValue
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
                if {$::debugging} {
                    puts "flow: call queueAutoindex from Indexwizard::beamTreeDoubleClick"
                }
		queueAutoindex
	    }
	}
    }
}

body Indexwizard::buildImageTree { } {
    error "buildImageTree"
}

# Spot finding methods ##############################################

body Indexwizard::pickFirstImage { } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::pickFirstImage"
    }
    # Clear any currently checked items
    foreach i_image [array names image_items_by_object] {
	catch {removeImage $i_image}
    }
    # Get a list of images in the session and sort
    set imgnumlist {}
    #puts "In Indexwizard::pickFirstImage calling getCurrentSector"
    set l_images [[$::session getCurrentSector] getImages]
    if {[llength $l_images] > 0} {
    # if there are any images to use...
	set a_template [[lindex $l_images 0] getTemplate]
	foreach i_image $l_images {
	    lappend imgnumlist [$i_image getNumber]
	}
	set imgnumsort [ lsort -integer $imgnumlist]
	# select the first image
	set first_num [lindex $imgnumsort 0]
	set first_image [$::session getImageByTemplateAndNumber $a_template $first_num]
	# If it's got a spotlist, just add it
	if {[$first_image getSpotlist] != ""} {
	    addImage $first_image
	} else {
	    # search for spots on the image
	    findSpots $first_image
	}
    }
}

body Indexwizard::pickNinetyDegreeImages { } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::pickNinetyDegreeImages"
    }
    # Clear any currently checked items
    foreach i_image [array names image_items_by_object] {
	catch {removeImage $i_image}
	#puts "Checked image $i_image"
    }
    # Get a list of images in the session and sort

# new code to find images in all sectors
#
    foreach i_sector [$::session getSectors] {
        #puts ""
        #puts "in loop over sectors, i_sector is: $i_sector"
        $::session setCurrentSector $i_sector
        set imgnumlist {}
        #puts "In Indexwizard::pickNinetyDegreeImages calling getCurrentSector"
        set l_images [[$::session getCurrentSector] getImages]
        #puts "Images:\n$l_images"
        if {[llength $l_images] > 0} {
        # if there are any images to use...
	    set a_template [[lindex $l_images 0] getTemplate]
	    foreach i_image $l_images {
	        lappend imgnumlist [$i_image getNumber]
	    }    
    	    #puts "Numbrs:\n$imgnumlist"
	    set imgnumsort [ lsort -integer $imgnumlist]
	    #puts "Sorted:\n$imgnumsort"
	    # select the first image
	    set first_num [lindex $imgnumsort 0]
	    set first_image [$::session getImageByTemplateAndNumber $a_template $first_num]
	    #puts "Image $first_num $first_image"
	    # If it's got a spotlist, just add it
	    if {[$first_image getSpotlist] != ""} {
	        addImage $first_image
	    } else {
	        # search for spots on the image
	        findSpots $first_image
	    }
	    # Get phi start of first image
	    foreach { l_phi_start l_phi_end } [$first_image getPhi] break
	    set next_image ""
	    set wedge 0.0
	    if { $l_phi_end > $l_phi_start } {
	        set wedge [ expr $wedge + $l_phi_end - $l_phi_start]
	    }
	    # Store ending phi to check contiguity
	    set phi_end_last $l_phi_end
	    # Loop through remaining images until the wedge >= 90 or we run out of images
	    foreach num [lrange $imgnumsort 1 end] {
	        set next_image [$::session getImageByTemplateAndNumber $a_template $num]
	        foreach { l_phi_start l_phi_end } [$next_image getPhi] break
	        # Check for a break in phi contiguity
	        set jump [ expr {$l_phi_start - $phi_end_last} ]
	        if { $l_phi_end > $l_phi_start } {
		    # for simplicity skip counting if an image's phi values cross zero in phi
		    set wedge [ expr $wedge + $l_phi_end - $l_phi_start + $jump]
	        }
	        #puts "Image $num: Phi-start $l_phi_start - Phi-end $l_phi_end Wedge $wedge degrees"
	        if { [expr $wedge >= 90.0] } {
		    #puts "Break at image $num: Phi-start $l_phi_start - Phi-end $l_phi_end Wedge $wedge degrees"
		    break
	        }
	        # Update ending phi to check contiguity
	        set phi_end_last $l_phi_end
	    }
	    # if we found an image >= 90 deg or the last in the list
	    if {$next_image != ""} {
	        #puts "Image $num $next_image"
	        # If it's got a spotlist, just add it
	        if {[$next_image getSpotlist] != ""} {
		    addImage $next_image
	        } else {
		    # search for spots on the image
		    #puts "Finding spots on image [$next_image getNumber]"
		    findSpots $next_image
	        }
	    } else {
	        #puts "Cannot find a second image"
	    }
        } else {
        }
    }
    if {$::debugging} {
        puts "flow: Exit Indexwizard::pickNinetyDegreeImages"
    }
}

body Indexwizard::chooseImages { {a_template ""} {a_num_list ""} } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::chooseImages"
    }
    # HRP 02032018 using getTemplate here allows spot finding to proceed with HDF5
    # Does this cause multiple sector image selection to fail?? AGWL 5/7/21
    if { $::env(HDF5file) == 1 } {
      set a_template [[$::session getCurrentSector] getTemplate]
    }
    # Set flag to indicate image choosing is going on
    set choosing_images 1
    # Initialize list of images to search
    set l_chosen_image_numbers {}
    set chosen_search_images {}
    # get the relevant sector 
    set l_sector [$::session getSectorByTemplate $a_template]
    $::session setCurrentSector $l_sector
    #puts "In call Indexwizard::chooseImages setCurrentSector passing sector name: $l_sector"
    # Select numbers that match existing images
    foreach i_num $a_num_list {
	set l_image [$::session getImageByTemplateAndNumber $a_template $i_num]
	# image exists in session
	lappend l_chosen_image_numbers $i_num
    }
    # Update the image list entry
    if {$::debugging} {
        puts "flow: calling setIndexingList from within Indexwizard::chooseImages"
    }
    $::session setIndexingList $l_chosen_image_numbers
    $itk_component(image_numbers) updateSector $a_template [compressNumList $l_chosen_image_numbers]

    # Remove all previously included images from this sector
    foreach i_image [array names image_items_by_object] {
	if { [lsearch $l_chosen_image_numbers $i_image] < 0 } {
	    if { [$i_image getTemplate] == $a_template } {
		#puts "catch removal of image [$i_image getNumber]"
		catch { removeImage $i_image }
	    }
	}
    }

    # Should we trap too many images entered for spot finding ...
    set num_for_sptfdg [llength $l_chosen_image_numbers]
    #puts "$num_for_sptfdg images input for spot finding"

    # Loop through chosen image numbers
    foreach i_num $l_chosen_image_numbers {
	# get image
	set l_image [$::session getImageByTemplateAndNumber $a_template $i_num]
	# if image exists for this number - it could have been deleted in the Images pane
	if { $l_image != "" } {
	    #puts "$i_num. $l_image got by name and number from Session"
	    # if it has a spotlist already...
	    if {[$l_image getSpotlist] != ""} {
		# add the image
		#puts "calls addImage"
		addImage $l_image
	    } else {
		# otherwise, search the image
		#puts "calls findSpots"
		findSpots $l_image
	    }
	} else {
	    #puts "$i_num. l_image has no value"
	}
    }
    if {$::debugging} {
        puts "flow: Exit Indexwizard::chooseImages"
    }
 
}

body Indexwizard::findSpots { an_image } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::findSpots for $an_image"
    }
    # disable controls
    disable

    # Keep list of images being list
    set images_being_searched [concat $images_being_searched $an_image]

    # Update the status indicators
    .c busy "Finding spots on image [$an_image getNumber]"
    
    # Tell mosflm to find spots on the picked images
    $::mosflm findspots $an_image
    if {$::debugging} {
        puts "flow: Exit Indexwizard::findSpots for $an_image"
    }
}

body Indexwizard::processSpotsFile { spots_file } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::processSpotsFile for $spots_file"
    }
    #puts "Session image height [$::session getImageHeight]"

    # Read the user's input file into a string
    set l_in_file [open $spots_file]
    set content [read $l_in_file]
    close $l_in_file
    
    # Split into records on newlines
    set records [split $content "\n"]

    # Make first spots list file name & handle
    set temp_spt [file join $::mosflm_directory "tmp[expr int(rand()*99999)].spt"]
    set l_out_file [open $temp_spt w]

    # Iterate over the records
    set penult 0
    foreach rec $records {
	#puts $rec
	puts $l_out_file $rec
	if { [string match *-99* $rec] > 0 } {
	    close $l_out_file
	    # then create the spot list object etc.
	    readSpotsFile $temp_spt
	    # Make a new file for the spots for the next phi_centre/image in the input file
	    set temp_spt [file join $::mosflm_directory "tmp[expr int(rand()*99999)].spt"]
	    set l_out_file [open $temp_spt w]
	}
    }
}

body Indexwizard::writeSpotsFile { spots_file } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::writeSpotsFile for $spots_file"
    }
    #puts "Session image height [$::session getImageHeight]"

    # Use the same method used to write the temporary spot file
    set l_first_image [getSpotfileFirstImage $spots_file]

}

body Indexwizard::readSpotsFile { spots_file } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::readSpotsFile for $spots_file"
    }
    #puts "File $spots_file used for spot list"
    set new_spotlist [namespace current]::[Spotlist \#auto "file" [$::session getImageHeight] $spots_file]
    #puts "New spotlist object $new_spotlist"
    set num_new_spots [llength [$new_spotlist getSpots]]
    #puts "New spotlist has $num_new_spots spots"
    if { $num_new_spots == 0 } {
	.m confirm \
	    -type "1button" \
	    -title "No Spots Found" \
	    -text "No spots could be read from file." \
	    -button1of1 "Dismiss"
	delete object $new_spotlist
	return
    }
    set l_spotlist_phi [$new_spotlist getPhi]
    set l_image [$::session getImageByPhi $l_spotlist_phi]
    if { $l_image == "" } {
	puts "Phi of $l_spotlist_phi does not correspond to any image in the session"
	return ; # do not permit spots for a phi value whose image is not in the session
    } else {
	#puts "Phi of $l_spotlist_phi found in spots list corresponds to Image [$l_image getNumber]"
    }

    #Add an event to the session history recording old and new spotlists
    set l_image_displayed [.image getImage]
    set old_spotlist [$l_image_displayed getSpotlist]
    #puts "old_spotlist: $old_spotlist"
    $::session addHistoryEvent "SpotSearchEvent" "Input" [$l_image getFullPathName] $old_spotlist $new_spotlist

    # Update the image's spotlist
    $l_image setSpotlist $new_spotlist
    # Add the searched image to the indexing list
    addImage $l_image
    # Update the image tree
    $itk_component(spotfinding_palette) updateSpotFindingResult $l_image

    # Update summary labels
    updateImageNumbers

    # Update image viewer with spots if they are for this image
    if { $l_image_displayed == $l_image } {
	.image plotSpots
    }
    if {$::debugging} {
        puts "flow: exit Indexwizard::readSpotsFile"
    }
}

body Indexwizard::processSpotfindingResults { a_dom } {
    if {$::debugging} {
        puts "flow: Enter Indexwizard::processSpotfindingResults"
    }
    
    # Check on status of task
    set status_code [$a_dom selectNodes string(/spot_search_response/status/code)]
    set image_number [$a_dom selectNodes string(/spot_search_response/image_number)]
    if {$status_code == "error"} {
	set message [$a_dom selectNodes string(/spot_search_response/status/message)]
	set image_number [$a_dom selectNodes string(/spot_search_response/image_number)]
	# Skip responses from the successive lowering of the threshold by Mosflm
	if { [string compare [string range $message 0 3] "Too "] == 0 } {
	    # skip pop-up 'Too 'many/few spots etc.
	} else {
	    # Add a warning to the box
	    $::session generateWarning "$message. Image [string trim $image_number]" -reason "Images"
	    # Flag image in Images pane
	    .c flagImage [string trim $image_number]
	    .m confirm -type "1button" \
		-title "Spot search failed" \
		-text "$message. Image [string trim $image_number]" \
		-button1of1 "Dismiss"
	    enable
	}
    } else {
	# Update spot finding parameters

	# Separation
	set l_separation [$a_dom selectNodes normalize-space(//separation)]
	if {$l_separation != ""} {
	    foreach { l_sep_x l_sep_y } $l_separation break
	    if {[$::session getParameterValue "spot_separation_x"] != $l_sep_x} {
		$::session updateSetting "spot_separation_x" $l_sep_x "1" "1" "Spotfinding"
	    }
	    if {[$::session getParameterValue "spot_separation_y"] != $l_sep_y} {
		$::session updateSetting "spot_separation_y" $l_sep_y "1" "1" "Spotfinding"
	    }
	} else {
	}

	# "Close"
	set l_close [$a_dom selectNodes normalize-space(//close)]
	if {$l_close != ""} {
	    if {[$::session getParameterValue "separation_close"] != $l_close} {
		$::session updateSetting "separation_close" $l_close "1" "1" "Spotfinding"
	    }
	} else {
	}

	# Raster
	set l_raster [$a_dom selectNodes normalize-space(//raster)]
	if {[llength $l_raster] == 5} {
	    foreach { l_raster_nxs l_raster_nys l_raster_nc l_raster_nrx l_raster_nry } $l_raster break
	    $::session updateSetting "raster_nxs" $l_raster_nxs "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nys" $l_raster_nys "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nc" $l_raster_nc "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nrx" $l_raster_nrx "1" "1" "Spotfinding"
	    $::session updateSetting "raster_nry" $l_raster_nry "1" "1" "Spotfinding"
	} else {
	}

	set l_resolution [$a_dom selectNodes normalize-space(//estimated_resolution)]
	if { $l_resolution != "" } {
	    if {[$::session getParameterValue "estimated_high_resolution_limit"] != "0"} {
		$::session updateSetting "estimated_high_resolution_limit" $l_resolution "1" "1" "Spotfinding"
	    }
	}

	# Get the name of the spot file returned
	set received_file [$a_dom selectNodes string(//spotfile)]
	#puts "spotfile $received_file"
	# Get the name of the image it belongs to
	set l_image_path [$a_dom selectNodes string(//imagefile)]
# HRP 01032018 for HDF5
	if { $::env(HDF5file) == 0 } {
	    set l_image [Image::getImageByPath $l_image_path]
	} {
	    set l_image [Image::getImageByPath [file dirname $l_image_path]/image.[format %07g $image_number]]
	}
        # puts "l_image from indexwizard $l_image"
	# Get the autothreshold value returned
	set local_auto_thresh [$a_dom selectNodes normalize-space(//indexing_threshold_value)]
	$::session updateSetting "i_sig_i" $local_auto_thresh "1" "1" "Spotfinding" "0"
	$::session updateSetting "auto_thresh_value" $local_auto_thresh "0" "0" "Spotfinding" "0"

	# Output some values to a file for the details popup listbox
	set spot_result [$l_image makeAuxiliaryFileName "ssr" $::mosflm_directory]
	file delete $spot_result
	set f [open $spot_result "w"]
	puts $f "Spot search parameters for image: [file tail $l_image_path]"
	puts $f "Spots found: [$a_dom selectNodes normalize-space(//found)]  Spots used: [$a_dom selectNodes normalize-space(//used)] \
	estimated resolution: [$a_dom selectNodes normalize-space(//estimated_resolution)]"
	puts $f "Median spot size in pixels in X: [$a_dom selectNodes normalize-space(//median_size_x)]    in Y: \
	[$a_dom selectNodes normalize-space(//median_size_y)]"
	puts $f "Derived measurement box parameters: NX: $l_raster_nxs NY: $l_raster_nys \
	NC: $l_raster_nc NRX: $l_raster_nrx NRY: $l_raster_nry"
	puts $f "I/sig(I) threshold for using spots: $local_auto_thresh\n"
	puts $f "Number rejected as possible ice spots: [$a_dom selectNodes normalize-space(//reject_ice_spots)]"
	puts $f "Number rejected as too small on X: [$a_dom selectNodes normalize-space(//reject_xmin)]"
	puts $f "Number rejected as too small on Y: [$a_dom selectNodes normalize-space(//reject_ymin)]"
	puts $f "Number rejected as too big on X: [$a_dom selectNodes normalize-space(//reject_xmax)]"
	puts $f "Number rejected as too big on Y: [$a_dom selectNodes normalize-space(//reject_ymax)]"
	puts $f "Number rejected as having too few pixels: [$a_dom selectNodes normalize-space(//reject_too_few_pixels)]"
	puts $f "Number rejected by resolution limit: [$a_dom selectNodes normalize-space(//reject_resolution_limit)]"
	puts $f "Number too close: [$a_dom selectNodes normalize-space(//reject_separation)]"
	puts $f "Minimum spot separation in X: $l_sep_x    in Y: $l_sep_y"
        #puts "warning string is:[$a_dom selectNodes normalize-space(//warning)]"
	if { [$a_dom selectNodes normalize-space(//warning)] == "Resolution limit" } {
           puts $f " "
           puts $f "** Warning, many spots rejected by the applied 4.5A resolution limit **"
           puts $f "Try unchecking the Automatic Resolution reduction checkbox"
           puts $f "in Processing options -> Spot finding"
           # Create pop-up window if resolution limit warning is set.
	   .m confirm -type "1button" \
	      -title "Many spots rejected by automatic resolution reduction" \
	      -text "Many spots have been rejected on image [file tail $l_image_path] because very few strong spots found\nbetween 6.5A and 4.5A.\nIf this is inappropriate in this case, uncheck the Automatic Resolution reduction checkbox\n in 'Processing options -> Spot finding' and then click the icon under 'Find' for this image\nNote: Details of spot finding results can be seen by highlighting an image, then\nright mouse click on the highlighted line and click on the resulting 'details' button"\
	      -button1of1 "Dismiss"
        }
	close $f

	# Create a spotlist from the file
	#puts "Image [$l_image getNumber] \($l_image\) used for spot list"
	#puts "Image image height [$l_image getImageHeight]"
	set new_spotlist [namespace current]::[Spotlist \#auto "file" [$l_image getImageHeight] [$l_image makeAuxiliaryFileName "spt" $::mosflm_directory]]

	#Add an event to the session history recording old and new spotlists
	set old_spotlist [$l_image getSpotlist]
	$::session addHistoryEvent "SpotSearchEvent" "Indexing" [$l_image getFullPathName] $old_spotlist $new_spotlist

	# Update the image's spotlist
	$l_image setSpotlist $new_spotlist

	# If there are no more results awaited
	if {![$::mosflm busy "spot_finding"]} {
	    # Turn off activity indicator
	    #.c idle
	    # enable controls
	    enable
	    set index_workflow "true"
	} else {
	}
	
	# Add the searched image to the indexing list
	addImage $l_image

	# Update the image tree
	$itk_component(spotfinding_palette) updateSpotFindingResult $l_image

	# Update summary labels
	updateImageNumbers
	
	# Update image viewer with spots if now available
	.image plotSpots

	# Was beam search trigger set?
	if { $beamSearchTrigger == 1 } {
	    set beamSearchTrigger 0
	    beamSearchLaunch
	}
    }
    if {$::debugging} {
        puts "flow: Exit Indexwizard::processSpotfindingResults"
    }
}

body Indexwizard::updateSpotlists { an_image } {
    # Don't bother if we can't find the image item
    if {[array get image_items_by_object $an_image] != ""} {
	# Get the label
	set l_label [$an_image getNumber]
	# get any existing spotlist
	set l_spotlist [$an_image getSpotlist]
	# depending on whether there's a spotlist or not...
	if {$l_spotlist != ""} {
	    # Manual spot editing implies we want to use these spots!
	    $itk_component(image_tree) item state set $image_items_by_object($an_image) [list AVAILABLE CHECKED]
	    # Get the text summary for display in the image tree
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotal]]
	    # plot the spots in the canvas (tagged by label)
	    $l_spotlist plotSummary $itk_component(spotcanvas) $l_label
	    # Move the spots to avoid the canvas border
	    $itk_component(spotcanvas) move "all$l_label" 1 1
	    # Scale the spot summary canvas
	    set l_scale_factor [expr 250.0 / [$an_image getImageHeight]]
	    $itk_component(spotcanvas) scale "all$l_label" 1 1 $l_scale_factor $l_scale_factor
	    # If the item is checked for inclusion...
	    if {[$itk_component(image_tree) item state get $image_items_by_object($an_image) CHECKED]} {
		# If the item is currently selected...
		if {[$itk_component(image_tree) item state get $image_items_by_object($an_image) selected]} {
		    # colour its spots blue
		    $itk_component(spotcanvas) itemconfigure "auto$l_label" -image ::img::summary_spot_blue_plus
		    $itk_component(spotcanvas) itemconfigure "manual$l_label" -image ::img::summary_spot_blue_cross    
		}
	    } else {
		$itk_component(spotcanvas) itemconfigure "manual$l_label" -image ""
	    }
	} else {
	    # Set state to indicate spots are NOT available from this image
	    $itk_component(image_tree) item state set $image_items_by_object($an_image) [list !AVAILABLE !CHECKED] 
	    # Make text summary indicating no spots searched for yet
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}
	# update the image icon
	$itk_component(image_tree) item element configure $image_items_by_object($an_image) 0 e_icon -image $l_icon
	# update the text summaries
	$itk_component(image_tree) item text $image_items_by_object($an_image) 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
    }
    # Update summary canvas
    updateSpotlistSelection

}
   
body Indexwizard::updateSpotFindingResult { a_image } {
    # Only bother if the image is in the wizard's list!
    #puts "updateSpotFindingResult: image_items_by_object($a_image) is $image_items_by_object($a_image)"
    if { [info exists image_items_by_object($a_image)] } {
	# get the image's item
	set l_item $image_items_by_object($a_image)
	# get the image's spotlist
	set l_spotlist [$a_image getSpotlist]
	# get the image's label in the image tree
	set l_label [$itk_component(image_tree) item text $l_item 0]
	if {$l_spotlist != ""} {
	    $itk_component(image_tree) item state set $l_item AVAILABLE
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotal]]
	} else {
	    $itk_component(image_tree) item state set $l_item !AVAILABLE
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}
	updateSpotSummary
	set l_total [format %3d [$l_spotlist getTotalAboveIsigi]] 
	$itk_component(image_tree) item element configure $l_item 0 e_icon -image $l_icon
	$itk_component(image_tree) item text $l_item 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
	# Sort the image tree
	$itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]
	# update the summary
	#updateSpotSummary
    }
}

body Indexwizard::updateSpotReportIsigi { a_image } {
    # Only bother if the image is in the wizard's list!
    if {[info exists image_items_by_object($a_image)]} {
	# get the image's item
	set l_item $image_items_by_object($a_image)
	#puts "updateSpotReportIsigi: object for item $l_item $image_objects_by_item($l_item)"
	# get the image's spotlist
	set l_spotlist [$a_image getSpotlist]
	# get the image's label in the image tree
	set l_label [$itk_component(image_tree) item text $l_item 0]
	if {$l_spotlist != ""} {
	    $itk_component(image_tree) item state set $l_item AVAILABLE
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotal]]
	} else {
	    $itk_component(image_tree) item state set $l_item !AVAILABLE
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}
	set l_total [format %3d [$l_spotlist getTotalAboveIsigi]] 
	$itk_component(image_tree) item element configure $l_item 0 e_icon -image $l_icon
	$itk_component(image_tree) item text $l_item 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total

	# Sort the image tree
	$itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]
    }
}

body Indexwizard::sortSpotFindingResults { a_item b_item } {
    #puts "IW:sort a_item $a_item b_item $b_item"
    set a_available [$itk_component(image_tree) item state get $a_item AVAILABLE]
    set b_available [$itk_component(image_tree) item state get $b_item AVAILABLE]
    if {$a_available && !$b_available} {
	return -1
    } elseif {!$a_available && $b_available} {
	return +1
    } else {
	eval set a_image_num [$image_objects_by_item($a_item) getNumber]
	eval set b_image_num [$image_objects_by_item($b_item) getNumber]
	if {$a_image_num < $b_image_num} {
	    return -1
	} elseif {$a_image_num > $b_image_num} {
	    return +1
	} else {
	    return 0
	}
    }
}

body Indexwizard::editSpots { } {
    .image openImage [lindex $images_list [$itk_component(imageslist) curselection]]
}

body Indexwizard::createImageCheck { tbl row col w } {
    error "Obsolete method Indexwizard::createImageCheck called"
}

body Indexwizard::updateSpotlistInclusions { a_row a_value } {
    # update the list of which spotlists to use
    set use_spotlists [lreplace $use_spotlists $a_row $a_row $a_value]
    # Update summary canvas
    updateSpotlistSelection
}

body Indexwizard::updateSpotSummary { } {
    # clear the spot summary canvas
    $itk_component(spotcanvas) delete all
    # initialize iterator to "", to allow later test for any iterations
    set i_image ""
    # Loop through chosen images
    foreach i_image [array names image_items_by_object] {
	#puts "updateSpotSummary: Image from array names of image_items_by_object: $i_image"
	#puts "updateSpotSummary - image is $i_image, item_by_object is $image_items_by_object($i_image)"
	# Choose labelling method depending on number of templates
	if {[llength [$::session getSectors]] > 1} {
	    set l_labelMethod "getRootName"
	} else {
	    set l_labelMethod "getNumber"
	}
	# get the label to be used
	set l_label [$i_image $l_labelMethod]
	# get the spotlist
	set l_spotlist [$i_image getSpotlist]
	# plot the spots in the canvas (tagged by label)
	$l_spotlist plotSummary $itk_component(spotcanvas) $l_label [$::session getParameterValue "i_sig_i"]
	set l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
	updateSpotReportIsigi $i_image
    }
    # if any summaries were plotted
    if {$i_image != ""} {
	set l_x_scale [expr double([winfo width $itk_component(spotcanvas)]) / [$::session getImageWidth]]
	set l_y_scale [expr double([winfo height $itk_component(spotcanvas)]) / [$::session getImageHeight]]
	# Scale the summaries to fit the canvas
	$itk_component(spotcanvas) scale all 0 0 $l_x_scale $l_y_scale
    }

    bind $itk_component(spotcanvas) <Configure> [code $this updateSpotSummary]

    # Update the total
    updateTotal
}

body Indexwizard::updateSpotlistSelection {  } {
    # initialize the index used to count through spot lists
    set i_index 0
    # loop through images 
    foreach i_image $images_list {
	# if the images's spotlist is to be used...
	if {[lindex $use_spotlists $i_index] == "1"} {
	    if {[$itk_component(imageslist) curselection] == $i_index} {
		# show the markers
		$itk_component(spotcanvas) itemconfigure "auto[$i_image getNumber]" -image ::img::summary_spot_blue_plus
		$itk_component(spotcanvas) itemconfigure "manual[$i_image getNumber]" -image ::img::summary_spot_blue_cross
		$itk_component(spotcanvas) raise "all[$i_image getNumber]"
	    } else {
		$itk_component(spotcanvas) itemconfigure "auto[$i_image getNumber]" -image ::img::summary_spot_black_plus
		$itk_component(spotcanvas) itemconfigure "manual[$i_image getNumber]" -image ::img::summary_spot_black_cross
	    }
	} else {
	    $itk_component(spotcanvas) itemconfigure "all[$i_image getNumber]" -image ::img::summary_spot_blank
	}
	incr i_index
    }
} 

body Indexwizard::updateImageNumbers { } {
    # Loop through images in tree, building:
    #  - count of images included, and
    #  - lists of image numbers per sector (template)
    set current_sector [$::session getCurrentSector]
    #puts "in Indexwizard::updateImageNumbers, current_sector set to $current_sector"
    foreach i_sector [$::session getSectors] {
	set l_image_numbers_by_template([$i_sector getTemplate]) {}
    }
    set l_image_count 0
    foreach i_item [$itk_component(image_tree) item children root] {
	incr l_image_count
	if {[$itk_component(image_tree) item state get $i_item CHECKED]} {
	    set l_image $image_objects_by_item($i_item)
	    lappend l_image_numbers_by_template([$l_image getTemplate]) [$l_image getNumber]
	}
    }
    foreach i_template [array names l_image_numbers_by_template] {
	$itk_component(image_numbers) updateSector $i_template [compressNumList $l_image_numbers_by_template($i_template)]
    }
    set i_template [$current_sector getTemplate] ;# reset to the current sector and reset image numbers
    if {$::debugging} {
        puts "flow: calling setIndexingList from within Indexwizard::updateImageNumbers"
    }
    $::session setIndexingList $l_image_numbers_by_template($i_template)
    $itk_component(image_numbers) updateSector $i_template [compressNumList $l_image_numbers_by_template($i_template)]
}

body Indexwizard::imageTreeRollover { a_w a_x a_y } {
    set l_new_item ""
    set l_new_element ""

    # get item and element rolled over
    set id [$a_w identify $a_x $a_y]
    if {$id != ""} {
	if {[lindex $id 0] eq "item"} {
	    set l_new_item [lindex $id 1]
	    if {[lindex $id 4] eq "elem"} {
		set l_new_element [lindex $id 5]
	    }
	}
    }
    
    # if changed, get rid of previous highlights / tooltips
    if {($prev_rollover_item != "") && ($prev_rollover_element != "")} {
	if {($prev_rollover_item != $l_new_item) || ($prev_rollover_element != $l_new_element)} {
	    if {$prev_rollover_element == "e_auto_search"} {
		$a_w item element configure $prev_rollover_item search e_auto_search -image ::img::spot_search_auto
		$a_w configure -cursor left_ptr
	    }
	}
    }
    
    # setup new highlights / tooltips
    if {$l_new_element == "e_auto_search"} {
	$a_w item element configure $l_new_item search e_auto_search -image  ::img::spot_search_auto_highlighted
	$a_w configure -cursor hand2
    }
    
    # update record of old item and element
    set prev_rollover_item $l_new_item
    set prev_rollover_element $l_new_element
}


# Autoindexing methods #############################################

body Indexwizard::queueAutoindex { } {
    if {$::debugging} {
        puts "flow: Entering Indexwizard::queueAutoindex"
    }
    set images [$itk_component(image_numbers) getContent]
    if { $images  == {} } {
	# No images entered, selected nor chosen. Cannot Index - do nothing
	return
    }
    # shift focus to index button to force setting updates
    focus $itk_component(index_button)

#    # Determine whether to Index multiple lattices
#    if { [$::session getMultipleLattices] } {
#	#showMultiLattice show it when lattice no.2 found
#	puts "indexwizard: setting MultipleLattices in queueAutoindex"
#	$::session setMultipleLattices 1
#    } else {
#	hideMultiLattice; # in case previous indexing was multi
#	puts "indexwizard: unsetting MultipleLattices in queueAutoindex"
#	$::session setMultipleLattices 0
#    }
    # trap zero crystal-to-detector distance
    $::session forceDistanceSetting
    if {[$::session distanceIsSet]} {
	# schedule autoindexing in event loop to allow updates to take place first
	after 0 [code $this autoindex]
    } else {
    }
}

body Indexwizard::autoindex { } {
    if {$::debugging} {
        puts "flow: enter Indexwizard::autoindex calls ::mosflm index"
    }
    set do_not_process_indexing 0

    # disable controls
    disable

    # Remove solution selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> {}

    # Delete the lattice summary tree
    $itk_component(multilattice_tree) item delete all

    clearLatticeTabs

    # Clear the displayed predictions
    .image clearPredictions

    # Get new spotfile in case choice of image changed
    set spotfilename [getNewSpotfilename]
    set l_first_image [getSpotfileFirstImage $spotfilename]
    #puts "autoindex: $l_first_image $spotfilename"
    # Trap if this image does not have a spotfile
    if { $l_first_image == 0 } { return }

    # Send command to Mosflm
    ########################
    $::mosflm index $l_first_image $spotfilename 0
}

body Indexwizard::sigmaISearchAutoindex { } {
    if {$::debugging} {
        puts "flow: enter Indexwizard::sigmaISearchAutoindex calls ::mosflm index"
    }
    set do_not_process_indexing 1
    #puts "$this set do_not_process_indexing 1"
    # disable controls
    disable

    # Remove solution selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> {}

    # Get new spotfile in case choice of image changed
    set spotfilename [getNewSpotfilename]
    set l_first_image [getSpotfileFirstImage $spotfilename]
    #puts "autoindex: $l_first_image $spotfilename"

    # Send command to Mosflm
    ########################
    $::mosflm index $l_first_image $spotfilename 0
}

body Indexwizard::beamSearchAutoindex { a_beam_x a_beam_y } {
    if {$::debugging} {
        puts "flow: enter Indexwizard::beamSearchAutoindex calls ::mosflm index3"
    }

    # disable controls
    disable

    # Remove solution selection binding
    $itk_component(image_tree) notify bind $itk_component(image_tree) <Selection> {}

    # Get new spotfile in case choice of image changed
    #set spotfilename [getNewSpotfilename]
    #set l_first_image [getSpotfileFirstImage $spotfilename]

    if { $l_first_image == "0" } {
	set l_first_image [$::session getImageByNumber [$itk_component(image_numbers) getContent]]
    }

    # puts "debug: autoindex: $l_first_image $spotfilename $a_beam_x $a_beam_y "

    # Send command to Mosflm
    ########################
    after 0 [code $::mosflm index3 $a_beam_x $a_beam_y $l_first_image $spotfilename 0]
}

body Indexwizard::getNewSpotfilename { } {

# Open randomly named temporary spot file
    expr srand([clock clicks])
    set file_creation_incomplete 1
    set file_creation_attempts 0
    while {$file_creation_incomplete} {
	if {$file_creation_attempts > 50} {
	    .m confirm \
		-type "1button" \
		-title "Error" \
		-text "Could not create spotfile:\n$out_file" \
		-button1of1 "Dismiss"
	    return 0
	}
	set spotfilename [file join $::mosflm_directory "msf[expr int(rand()*99999)].tmp"]
	set file_creation_incomplete [catch {open $spotfilename {WRONLY CREAT EXCL}} out_file]
	incr file_creation_attempts
    }
    # close file
    close $out_file
    set haveNewSpotfilename 1
    return $spotfilename
}

body Indexwizard::getSpotfileFirstImage { spotfilename } {

    # Open randomly named temporary spot file
    set file_creation_incomplete 1
    set file_creation_incomplete [catch {open $spotfilename {WRONLY CREAT}} out_file]

    # write header info
    #        3072        3072 0.10260000    1.000000    0.000000
    #           1           1
    #  157.32001  157.05000
    #
    #3072 = number of pixels in X, Y - <image_width> & <image_height> in <header_response>
    #0.1026 = pixel size in mm <pixel_size> in <header_response>
    #1.000 = YSCALE <yscale>
    #0.000 = OMEGA <omega> 
    set iw [$::session getParameterValue "image_width"]
    set ih [$::session getParameterValue "image_height"]
    set px [$::session getParameterValue "pixel_size"]
    set ys [$::session getParameterValue "yscale"]
    set do [$::session getParameterValue "detector_omega"]
    puts $out_file "[format %12d $iw][format %12d $ih][format %11.8f $px][format %12.6f $ys][format %12.6f $do]"
    #
    #1 = "invertx" flag <invertx>
    #1 = "swung out coordinates" - always 1 for iMosflm, not sent in XML
    set ix [string match T [$::session getInvertX]]
    set so 1
    puts $out_file "[format %12d $ix][format %12d $so]"
    #
    #157.32001  157.05000 = beam X & Y - <beam_x> <beam_y>
    set bx [$::session getParameterValue "beam_x"]
    set by [$::session getParameterValue "beam_y"]
    puts $out_file "[format %11.5f $bx][format %11.5f $by]"

    # loop through images, generating spot lists
    set first_image 1
    set i_index 0
    set images_being_autoindexed {}
    foreach i_item [$itk_component(image_tree) item children root] {
	if {[$itk_component(image_tree) item state get $i_item CHECKED]} {
	    set l_image $image_objects_by_item($i_item)
	    lappend images_being_autoindexed $l_image
	    if {$first_image} {
		set first_image 0
		set l_first_image $l_image
	    } else {
		puts $out_file "[format %11.2f -99.00][format %10.2f -99.00][format %9.3f -99.00][format %9.3f -99.00][format %12.1f -99.00][format %10.1f -99.00]"
	    }
	    foreach { start end } [$l_image getPhi] break
	    # Send start and end phi values to writeToFile
            # If images have been summed for spotfinding, need to send "end" phi for last image used
            # otherwise phi value in temporary spots file will be wrong.
	    set l_spotlist [$l_image getSpotlist]
            set end [expr $end + ([$::session getParameterValue nsum_pil_spf] -1) * ($end - $start)]
            #puts "number summed [$::session getParameterValue nsum_pil_spf]"
            #puts "dumping spots $l_spotlist $start $end"
	    $l_spotlist writeToFile $out_file $start $end
	}
	incr i_index
    }
    puts $out_file "[format %11.2f -999.00][format %10.2f -999.00][format %9.3f -999.00][format %9.3f -999.00][format %12.1f -999.00][format %10.1f -999.00]"
    puts $out_file "[format %7d $iw][format %6d $ih][format %10.4f $px][format %5d [expr int($ys)]]"
    
    # close file
    close $out_file
    return $l_first_image
}

body Indexwizard::processIndexingResults { a_dom } {
    if {$::debugging} {
        puts "flow: enter Indexwizard::processIndexingResults calls ::mosflm index2"
    }
    # Check on status of task
    set status_code [$a_dom selectNodes string(/preselection_index_response/status/code)]
    if {$status_code == "warning"} {
	set status_message [$a_dom selectNodes string(/preselection_index_response/status/message)]
	$::session generateWarning $status_message -type "Warning"
    } elseif {$status_code == "error"} {
	# get message
	set status_message [$a_dom selectNodes string(/preselection_index_response/status/message)]
	# Get latest returned value for new max cell edge
	catch {set l_max_cell_edge [$a_dom selectNodes normalize-space(//maximum_cell_edge)]}
	if { $l_max_cell_edge != "" } {
	    $::session updateSetting max_cell_edge [expr int(round($l_max_cell_edge))] "1" "1" "Indexing"
	}
	set simpleError 0
	if {$do_not_process_indexing != 1} {
	    if {[regexp {found in spot file} $status_message]} {
		set simpleError 1
		.m configure \
		    -title "Error" \
		    -type "1button" \
		    -text "Mosflm is not able to index with so few spots.\nPlease try again with more spots." \
		    -button1of1 "Dismiss"
	    } elseif {[regexp {Failed to index image} $status_message]} {
		set simpleError 1
		.m configure \
		    -title "Error" \
		    -type "1button" \
		    -text "Indexing failed.\nPlease check the beam position, distance, and max cell edge." \
		    -button1of1 "Dismiss"
	    } elseif {[regexp {Bravais failure} $status_message]} {
		set simpleError 1
		.m configure \
		    -title "Error" \
		    -type "1button" \
		    -text "Mosflm failed to index correctly, sorry.\nIncreasing the max cell edge and/or decreasing the threshold may help." \
		    -button1of1 "Dismiss"
	    } else {
		set simpleError 0
		unknownReasonForFailure
		# If no more refinement results are expected...
		if {![$::mosflm busy "indexing" "index_refinement"]} {
		    # enable the controls
		    enable
		}
#		.m configure \
#		    -title "Error" \
#		    -type "1button" \
#		    -text "The indexing process has failed. It might be worthwhile trying again with:\n1. A large or smaller longest cell edge\n2. Using more or fewer reflections (200 - 1000 is best)\n3. Using more and/or different images\n4. Checking your direct beam position carefully" \
#		    -button1of1 "Dismiss"
	    }
	    if { $simpleError == 1 && [.m confirm]} {
		# If no more refinement results are expected...
		if {![$::mosflm busy "indexing" "index_refinement"]} {
		    # enable the controls
		    enable
		}
	    }
        } else {
	    set start_beam_x [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 0]]]
	    set start_beam_y [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 1]]]
#	                puts "$start_beam_x $start_beam_y $bs_beam_x $bs_beam_y [format %4.2f $bs_beam_shift_rel] [format %4.2f $bs_spot_deviation_pos] [format %4.2f $bs_spot_deviation_phi]"

	    set bs_item [$itk_component(beamsearch_tree) item create]
	    $itk_component(beamsearch_tree) item style set $bs_item 0 s2 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2 12 s2
	    $itk_component(beamsearch_tree) item text $bs_item 0 $start_beam_x
	    $itk_component(beamsearch_tree) item text $bs_item 1 $start_beam_y
	    $itk_component(beamsearch_tree) item text $bs_item 2 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 3 "-"			
	    $itk_component(beamsearch_tree) item text $bs_item 4 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 5 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 6 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 7 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 8 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 9 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 10 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 11 "-"
	    $itk_component(beamsearch_tree) item text $bs_item 12 "-"
	    
	    $itk_component(beamsearch_tree) item lastchild root $bs_item

	    $itk_component(beamsearch_tree) yview moveto 1.0

 	    # record beam shift for each tree item for sorting
 	    set spot_dev_pos($bs_item) "999"
 	    set cell_volume($bs_item) "9999999999.9"

	    if {![$::mosflm busy "indexing" "index_refinement"]} {
		enable
	    }
	    gridSearchRelay
	}
    } else {
	# Get the lattice number
	set l_lattice [$a_dom selectNodes normalize-space(//lattice_number)]
	# Create the cell edited flag for the Images pane
	$::session setCellBeenEdited $l_lattice 0
	# Permit up to five lattices only - 10 is the limit in Mosflm
	#
	if { $l_lattice > 5 } { return }

	# Increase session's counter
	$::session setNumberLattices $l_lattice
	if {$do_not_process_indexing != 1} {
	    #puts "Processing prerefined results for lattice $l_lattice"
	    # Parse updated settings
	    set l_max_cell_edge [$a_dom selectNodes normalize-space(//maximum_cell_edge)]
	    if {[$::session getParameterValue "fix_max_cell_edge"] != "1"} {
		$::session updateSetting max_cell_edge [expr int(round($l_max_cell_edge))] "1" "1" "Indexing"
	    }

	    set tab_no [expr {$l_lattice - 1}]

	    # Add solutions tab for lattices after the first

	    if { $l_lattice > 1 } {
		# Display lattices summary area after first lattice
		showMultiLattice
	    } else {
		hideMultiLattice
	    }
	    if {![info exists path_to_tab($l_lattice)] } {

		$itk_component(tabs) add -label "Lattice $l_lattice" -command [ code $this raiseLatticetab $tab_no ]
		eval set lattice${l_lattice}_tab [$itk_component(tabs) childsite $tab_no]
		eval set tab \$lattice${l_lattice}_tab
    
		itk_component add lattice_tab${l_lattice} {
		    eval set ltab${l_lattice} [Latticetab $tab.lattice_tab]
		}
		#eval puts \"Tab no. \$tab_no is \$ltab${l_lattice}\"
    
		eval set path_to_tab(${l_lattice}) \$ltab${l_lattice}
		#puts "Latticetab is $path_to_tab(${l_lattice})"
    
		pack $itk_component(lattice_tab${l_lattice}) -fill both -expand 1
		$path_to_tab($l_lattice) addTreeHeadings
    
		# Select this tab and hide others
		$itk_component(tabs) select "Lattice $l_lattice";#$tab_no
    
		# Increment lattice combo
		.image setLatticeComboVal $l_lattice
    
		#puts "Lattice $l_lattice tab $tab_no widget $path_to_tab($l_lattice)"
    
		# Add this lattice to session's list
		$::session appendLatticeList $l_lattice
    
		# Set the list of lattice numbers
		.image setLatticeComboValues [$::session getLatticeList]

	    } else {

		# Delete the previous tab for this lattice
		$path_to_tab($l_lattice) clear

		$::session setCellBeenEdited $l_lattice 0
	    }

	    # Handle indexing solutions - clearing previous solutions as first act before loading
	    $path_to_tab($l_lattice) loadPreselectionSolutions $a_dom $images_being_autoindexed

	} else {
	    #puts "IN AUTOINDEXING AND NOT PROCESSING RESULTS"
	    set solution_number_nodes [$a_dom selectNodes //lattice_character]
	    $::mosflm index2 1 [$::session getSigmaCutoff] $l_lattice
	    if {![$::mosflm busy "indexing" "index_refinement"]} {
		# enable the controls
		enable
	    }
	}
    }
}

body Indexwizard::updateSpacegroupCombo { lattice_type } {
  # puts "debug: Entering Indexwizard::updateSpacegroupCombo"
  # flush stdout 
    # get the list of possible spacegroups for this lattice type
    $itk_component(spacegroupcombo) list delete 0 end
    eval $itk_component(spacegroupcombo) list insert 0 $::spacegroup($lattice_type)
    # select the minimal one as default
    $itk_component(spacegroupcombo) select 0
    # enable the spacegroup combobox
    $itk_component(spacegroupcombo) configure -state normal
  # puts "debug: Exiting Indexwizard::updateSpacegroupCombo"
  # flush stdout 
}

body Indexwizard::toggleSpacegroup { a_widget a_value } {
  # puts "debug: "
  # puts "debug: "
  # puts "debug: Entering Indexwizard::toggleSpacegroup a_widget $a_widget a_value $a_value"
    set l_prev_lattice [$::session getLattice]
    set l_current_spacegroup [[$::session getSpacegroup] reportSpacegroup]
    # Needs to be editable see bug 269
    regsub -all " " $a_value "" trim_value
  # puts "debug: in Indexwizard::toggleSpacegroup regsub, trim_value $trim_value current_spg $l_current_spacegroup"
    if { [string length $trim_value] == 0 } { return }
    if { [string index $trim_value 0] != "h" } {
	set trim_value [string toupper $trim_value]
      # puts "debug: trim_value set to upper $trim_value"
    }
    if { [string index $trim_value 0] == "H" } {
	set trim_value [string tolower $trim_value]
      # puts "debug: trim_value set to lower $trim_value"
    }
  # puts "debug: spacegroups $::spacegroups trim value $trim_value"
    if {[lsearch $::spacegroups $trim_value] > -1} {
	# Known to iMosflm
	# Previously did a test here against the current spacegroup.
	# This is not desirable, because if there was more than one
	# solution with the same spacegroup, and the second occurrence
	# had a lower rmsd, the indexing would choose that solution
	# but the session cell would not be updated!
	# Testing against a null string avoids this but does mean
	# a lot more calls to "validate" are issued, making the .lp
	# file messy, but more importantly the sesion cell is set to
	# the cell for the best indexing solution. 21/5/18
	if {$trim_value != "" } {
	    # & different
	    if {[[$::session getCell] reportCell] != "Unknown"} {
		# I think cell is Unknown when first space group value is inserted from chosen solution
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
		#puts "togSpgrp vCAS: $trim_value $l_a $l_b $l_c $l_alpha $l_beta $l_gamma"
              # puts "debug: Indexwizard::toggleSpacegroup  knowntomosflm validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value"
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value
	    }
	    set l_curr_lattice [$::session getLattice]
	    if { $l_curr_lattice != "" } {
		#puts "Space group $trim_value chosen in lattice $l_curr_lattice"
	    }
        }
    } else {
	# Not known to iMosflm
	if { ($l_prev_lattice != "") && ($l_current_spacegroup != "Unknown") } {
	    if {[[$::session getCell] reportCell] != "Unknown"} {
		# I think cell is Unknown when first space group value is inserted from chosen solution
		foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
		#puts "togSpgrp vCAS: $trim_value $l_a $l_b $l_c $l_alpha $l_beta $l_gamma"
              # puts "debug: Indexwizard::toggleSpacegroup NOTknowntomosflm validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value"
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $trim_value
	    }
	}
    }
  # puts "debug: leaving Indexwizard::toggleSpacegroup a_widget a_value $a_widget $a_value"
}

body Indexwizard::showMultiLattice { } {

    hideBeamSearch
    grid $itk_component(multilatticescrollbar)
    grid $itk_component(multilattice_tree)
    $itk_component(multilatticeexpander) configure -text "Hide"
    set showmultilattice 1
}

body Indexwizard::hideMultiLattice { } {

    grid remove $itk_component(multilatticescrollbar)
    grid remove $itk_component(multilattice_tree)
    $itk_component(multilatticeexpander) configure -text "Show"
    set showmultilattice 0
}

body Indexwizard::getLatticeByItem { item } {
    if {[info exists lattice_by_item($item)]} {
	return $lattice_by_item($item)
    } else {
	return ""
    }
}

body Indexwizard::getItemByLattice { lattice } {
    if {[info exists item_by_lattice($lattice)]} {
	return $item_by_lattice($lattice)
    } else {
	return ""
    }
}

body Indexwizard::raiseLatticetab { selected } {
    # Redisplay predictions for chosen solution
    set tabindex $selected
    #puts "raiseLT: selected is $selected"
    set lattice [expr { $tabindex + 1 }]
    if {[info exists item_by_lattice($lattice)]} {
	#puts "raiseLT: item_by_lattice($lattice) $item_by_lattice($lattice)"
	toggleLatticeSelection $item_by_lattice($lattice) 1
    }
}

body Indexwizard::toggleLatticefromCombo { lattice } {
    if {[info exists item_by_lattice($lattice)]} {
	set selected $item_by_lattice($lattice)
	#puts "IW:toggleLatticefromCombo lattice $lattice selected $selected"
	toggleLatticeSelection $selected 0
    } else {
	set tabindex [lsearch [$::session getLatticeList] $lattice]
	#puts "Tab to select is $tabindex"
	$itk_component(tabs) select $tabindex
    }
}

body Indexwizard::toggleLatticeSelection { a_selected {update_combo 1} } {
    if { $a_selected != "" } {
	# Raise the correct Lattice solutions tab
	if { $a_selected != 0 } {
	    set lattice $lattice_by_item($a_selected)
	    set selected_lattice $lattice

	    # Finally set the lattice for the session
	    #puts "IW:toggleLatticeSelection item $a_selected selected tab Lattice $lattice"
	    $::session setCurrentLattice $selected_lattice
	    $::session setCurrentCellMatrixSpaceGroup $selected_lattice

	    # Update the beam position for this lattice
	    foreach { l_beam_x l_beam_y } [$path_to_tab($lattice) getBeamXY] break
	    #puts "Lattice $lattice beam_x,y: $l_beam_x $l_beam_y"
	    $::session updateSetting beam_x $l_beam_x 1 1 "Indexing" 0
	    $::session updateSetting beam_y $l_beam_y 1 1 "Indexing" 0

	    # Select correct line in summary
	    $itk_component(multilattice_tree) selection modify $a_selected all
	    $itk_component(tabs) select "Lattice $lattice"

	    # Redisplay predictions for chosen solution
	    set chosen_solution [$path_to_tab($lattice) getChosenSolution]
	    if { ![.image getMergeOnState] } {
		# Get predictions afresh for this lattice only if not displaying all lattices
		$path_to_tab($lattice) redisplayPredictions $chosen_solution
	    }

	    # Plot bad spots
	    .image plotBadSpots

	    if { $update_combo } {
		# Update the combo in Image display
		.image setLatticeComboVal $selected_lattice
	    }
	}
    }
}

body Indexwizard::toggleMultiLatticeTable { } {
    if {[set showmultilattice]} {
	hideMultiLattice
    } else {
	showMultiLattice 
    }
}

body Indexwizard::getPathToLatticeTab { lattice } {
    # Catch if no indexing lattice tabs exists e.g. reading a saved .mos file
    if {[info exists path_to_tab($lattice)]} {
	return $path_to_tab($lattice)
    } else {
	return ""
    }
}

body Indexwizard::updateLatticeSummary { lattice solution { type ref } } {

    # Only delete a line if it exists
    if { [info exists item_by_lattice($lattice)] } {
	#puts "item_by_lattice($lattice) is $item_by_lattice($lattice)"
	catch { $itk_component(multilattice_tree) item delete $item_by_lattice($lattice) }
    }

    #puts "[[$solution getMatrix] listMatrix]"
    if { $type == "ref" } {
	set devpos [format %4.2f [$solution getSpotDevPos]]
	set norefs [format %4d [$solution getReflectionsUsed]]
    } else {
	set devpos "-"
	set norefs "-"
    }
    set item_line [$itk_component(multilattice_tree) item create]
    $itk_component(multilattice_tree) item style set $item_line 0 s2 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2
    foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$solution getCell] listCell] break 
    $itk_component(multilattice_tree) item text $item_line 0 "$lattice"
    $itk_component(multilattice_tree) item text $item_line 1 "[$solution getLattice]"
    $itk_component(multilattice_tree) item text $item_line 2 "[format %3d [$solution getPenalty]]"
    $itk_component(multilattice_tree) item text $item_line 3 "[format %5.1f $l_a]"
    $itk_component(multilattice_tree) item text $item_line 4 "[format %5.1f $l_b]"
    $itk_component(multilattice_tree) item text $item_line 5 "[format %5.1f $l_c]"
    $itk_component(multilattice_tree) item text $item_line 6 "[format %5.1f $l_alpha]"
    $itk_component(multilattice_tree) item text $item_line 7 "[format %5.1f $l_beta]"
    $itk_component(multilattice_tree) item text $item_line 8 "[format %5.1f $l_gamma]"
    $itk_component(multilattice_tree) item text $item_line 9 "$devpos"
    $itk_component(multilattice_tree) item text $item_line 10 "$norefs"
    $itk_component(multilattice_tree) item text $item_line 11 "-"
    $itk_component(multilattice_tree) item lastchild root $item_line

    #puts "Item $item_line Lattice: $lattice Solution: [$solution getNumber] Cell: [[$solution getCell] listCell] Symbol: [$solution getLattice] replace $replace"

    set lattice_by_item($item_line) $lattice
    set item_by_lattice($lattice) $item_line
    #puts "item_by_lattice($lattice) $item_by_lattice($lattice)"
    #puts "lattice_by_item($item_line) $lattice_by_item($item_line)"

    $itk_component(multilattice_tree) item sort root

    # Select this line in the summary
    $itk_component(multilattice_tree) selection modify $item_line all
}

body Indexwizard::rightClickLattice { } {

    if { $selected_lattice != "" && ([$::session getNumberLattices] > 0)} {
	# get the object belonging to the item right-clicked on
	set l_item $item_by_lattice($selected_lattice)
	$path_to_tab($selected_lattice) clear
	#puts "Item $l_item Lattice: $selected_lattice tab [expr {$selected_lattice - 1}] emptying solutions ..."
	$itk_component(multilattice_tree) item delete $l_item
	#puts "Now unsetting $path_to_tab($selected_lattice)"
	unset path_to_tab($selected_lattice)
	$itk_component(tabs) delete "Lattice $selected_lattice"
	unset lattice_by_item($l_item)
	unset item_by_lattice($selected_lattice)

	$::mosflm sendCommand "lattice delete $selected_lattice"
	$::session setNumberLattices [expr {[$::session getNumberLattices] - 1}]
	$::session removeLatticeList $selected_lattice
	# Select the new current lattice after removal
	set new_curr_latt [$::session getCurrentLattice]
	if { $new_curr_latt ne "" } {
	    # Protect against deletion of all lattices
	    #puts "new_curr_latt $new_curr_latt"
	    set new_item $item_by_lattice($new_curr_latt)
	    .c component indexing toggleLatticeSelection $new_item 0
	    # Set the lattice spinbox values to be the edited lattice list
	    .image setLatticeComboValues [$::session getLatticeList]
	} else {
	    .image clearPredictions
	    toggleMultiLatticeTable
	}
    }
}

body Indexwizard::showBeamSearch { } {

    hideMultiLattice
    grid $itk_component(beamsearch_tree)
    grid $itk_component(beamsearchscrollbar)
    $itk_component(beamsearchexpander) configure -text "Hide"
    set showbeamsearch 1
}

body Indexwizard::hideBeamSearch { } {

    grid remove $itk_component(beamsearch_tree)
    grid remove $itk_component(beamsearchscrollbar)
    $itk_component(beamsearchexpander) configure -text "Show"
    set showbeamsearch 0
}

body Indexwizard::abortBeamSearch { } {
    set grid_search 0
    if {[$::mosflm busy]} {
	$itk_component(beamsearchlabel) configure -fg grey	
	$itk_component(beamsearchlabel) configure -text "Start beam search"
    } else {
	$itk_component(beamsearchlabel) configure -text "Start beam search"
    }
}

body Indexwizard::toggleBeamSearchTable { } {
    if {[set showbeamsearch]} {
	hideBeamSearch
    } else {
	showBeamSearch 
    }
}

body Indexwizard::beamSearchLaunch { } {
    if {$::debugging} {
        puts "flow: enter  Indexwizard::beamSearchLaunch"   
    }
    # Protect if no images entered for spot finding
    set images [$itk_component(image_numbers) getContent]
    if { $images  == {} } {
	# No images entered, selected nor chosen. Choose the first one, find spots
	# and set a trigger to do beam search after processing spotfinding results.
	set beamSearchTrigger 1
	pickNinetyDegreeImages
    } else {
	$itk_component(beamsearchlabel) configure -text "Abort beam search"
	set grid_search 1
	set grid_counter 0
	set haveNewSpotfilename 0
	set do_not_process_indexing 1
    
	if {$searchtype == "beam-centre"} {
	    showBeamSearch
	    $itk_component(beamsearch_tree) item delete all
	    $itk_component(beamsearchexpander) configure -text "Hide"
	    # clear the sort list
	    array unset spot_dev_pos *
	    array unset cell_volume *
	    set beam_list {}
	    gridSearchRelay
	} elseif {$searchtype == "higher I/sigma(I)"} {
	    sigmaISearchRelay {up}
	} elseif {$searchtype == "lower I/sigma(I)"} {
	    sigmaISearchRelay {down}
	} else {
	}
    }
}

body Indexwizard::sigmaISearchRelay { dir } {

    set sig1 [$::session getISigmaI]
    set sigdel [$::session getISigmaIdelta]
    set delta [expr { int ( $sig1 * $sigdel / 100 ) }]
    if {$dir == "up"} {
	set sig3 [expr { $sig1 + $delta }]
    }
    if {$dir == "down"} {
	set sig3 [expr { $sig1 - $delta }]
    }

    $::session updateSetting i_sig_i $sig3 1 1 "Indexing" 0
    if {$::debugging} {
        puts "flow: call queueAutoindex from Indexwizard::sigmaISearchRelay"
    }
    queueAutoindex
    return
}

body Indexwizard::gridSearchRelay { } {

    set beam_centre [$::session getBeamPosition]
    set stepsize [$::session getParameterValue beamsearch_stepsize]
    set stepnumx [$::session getParameterValue beamsearch_stepnumx]
    set stepnumy [$::session getParameterValue beamsearch_stepnumy]

    set preloop_beam_x [expr [lindex $beam_centre 0] - [expr $stepnumx * $stepsize] ]
    set preloop_beam_y [expr [lindex $beam_centre 1] - [expr $stepnumy * $stepsize] ]

     # puts "debug: beam search at $beam_centre"
    #puts $beam_centre
    #puts $preloop_beam_x
    #puts $preloop_beam_y

    # Doing a grid search so one temporary spot file will suffice for each search
    if {$haveNewSpotfilename == 0} {
	set spotfilename [getNewSpotfilename]
	set l_first_image [getSpotfileFirstImage $spotfilename]

	if { $l_first_image == "0" } {
	    set l_first_image [$::session getImageByNumber [$itk_component(image_numbers) getContent]]
	}

	#puts "gridSearchRelay: $l_first_image $spotfilename"
    }
    

    if {$grid_counter == 0} {
	for {set local_beam_x $preloop_beam_x} {$local_beam_x <= [expr $preloop_beam_x + [expr 2*($stepnumx * $stepsize)]]} {set local_beam_x [expr $local_beam_x + $stepsize]} {
	    for {set local_beam_y $preloop_beam_y} {$local_beam_y <= [expr $preloop_beam_y + [expr 2*($stepnumy * $stepsize)]]} {set local_beam_y [expr $local_beam_y + $stepsize]} {
		lappend beam_list [list $local_beam_x $local_beam_y]
	    }
	}
    }

#	# puts "debug: beam_list $beam_list"
    set list_length [llength $beam_list]

    if {$grid_counter < $list_length} {
	#puts $grid_counter
	#puts [list [lindex $beam_list $grid_counter]]
	if {$grid_search != 0} {
	    beamSearchAutoindex [lindex [lindex $beam_list $grid_counter] 0] [lindex [lindex $beam_list $grid_counter] 1]
	    incr grid_counter
	}
    } else {
	# puts "debug: sort the list on sigma(x,y) ascending"
	# sort the list on sigma(x,y) ascending
	$itk_component(beamsearch_tree) item sort root -command [code $this sortBeamSearchDevn]
	# sort the list on cell volume ascending
	$itk_component(beamsearch_tree) item sort root -command [code $this sortBeamSearchCell]
	# scroll back to the smallest sigma(x,y)
	$itk_component(beamsearch_tree) yview moveto 0
	set do_not_process_indexing 0
	set grid_search 0
	$itk_component(beamsearchlabel) configure -text "Start beam search"
	return
    }
}

body Indexwizard::processPrerefinementResult { a_dom} {

    # Check on status of task
    set status_code [$a_dom selectNodes string(/prerefinement_index_response/status/code)]
    if {$status_code == "error"} {
	# Update activity indicator

	# get message
	set status_message [$a_dom selectNodes string(/prerefinement_index_response/status/message)]
	if {[regexp {found in spotfile} $status_message]} {
	    .m configure \
		-title "Error" \
		-type "1button" \
		-text "Mosflm is not able to index with so few spots.\nPlease try again with more spots." \
		-button1of1 "Dismiss"
	} elseif {[regexp {Failed to index image} $status_message]} {
	    .m configure \
		-title "Error" \
		-type "1button" \
		-text "Indexing failed.\nPlease check the beam position, distance, and max cell edge." \
		-button1of1 "Dismiss"
	} elseif {[regexp {Bravais failure} $status_message]} {
	    .m configure \
		-title "Error" \
		-type "1button" \
		-text "Mosflm failed to index correctly, sorry.\nIncreasing the max cell edge and/or decreasing the threshold may help." \
		-button1of1 "Dismiss"
	} else {
	    .m configure \
		-title "Error" \
		-type "1button" \
		-text "Mosflm failed in a new and unusual way.\nNoyce!" \
		-button1of1 "Dismiss"
	}
	if {[.m confirm]} {
	    # was showSpotSearchResults
	}
    } else {
	puts "Stray prerefinement_index_response issued by mosflm: [$a_dom asHTML]"
    }
}

body Indexwizard::processUpdatedAmatrices { a_dom } {
    # Check on status of task
    set status_code [$a_dom selectNodes string(/updated_amatrix_response/status/code)]
    if {$status_code == "error"} {
	.m confirm -type "1button" \
	    -text "Updating of A matrices for refined solutions failed, sorry.\n[$a_dom selectNodes string(/updated_amatrix_response/status/message)]" \
	    -button1of1 "Dismiss"
    } else {
	# Find out which lattice updated matrices belong to
	set l_lattice [$a_dom selectNodes normalize-space(/updated_amatrix_response/lattice_number)]

	#puts "Updating A matrices for lattice $l_lattice"
	# Parse results for all refined solutions for this lattice
	$path_to_tab($l_lattice) updateRefinedSolutionAmatrices $a_dom

	# Save the session (as history events have been added quickly)
	$::session writeToFile

	# enable controls
	enable
    }
}

body Indexwizard::processSplitAngle { a_dom } {

    #puts "processSplitAngle no.lattices: [$::session getNumberLattices]"
    if {[$::session getNumberLattices] < 2 } {
	# Should only get split angle response if more than one lattice
	toggleMultipleLattices
#hrp 21042015	$::session setMultipleLattices 0
	return
    }

    # Check on status of task
    set status_code [$a_dom selectNodes string(/split_angle_response/status/code)]
    if {$status_code == "error"} {
	.m confirm -type "1button" \
	    -text "Processing of the split angle failed, sorry.\n[$a_dom selectNodes string(/split_angle_response/status/message)]" \
	    -button1of1 "Dismiss"
    } else {
	# Find out which lattice split angle belongs to
	set l_lattice [$a_dom selectNodes normalize-space(/split_angle_response/lattice_number)]

	set l_split [$a_dom selectNodes normalize-space(/split_angle_response/split_angle)]
	#puts "Collected split angle $l_split for lattice $l_lattice"

	if {[info exists item_by_lattice($l_lattice)]} {
	    # Find the line for this lattice in the summary table
	    set item_line $item_by_lattice($l_lattice)
	    # Update the line
	    if { [string trimleft $l_split] == -999.00 } {
		$itk_component(multilattice_tree) item text $item_line 11 "-"
	    } else {
		$itk_component(multilattice_tree) item text $item_line 11 "[format %5.1f $l_split]"
	    }
	}
    }
}

body Indexwizard::processRefinedResult { a_dom } {
  # puts "debug: Enter Indexwizard::processRefinedResult  do_not_process_indexing $do_not_process_indexing"
  # flush stdout

    if {$do_not_process_indexing != 1} {
	# Check on status of task
	set status_code [$a_dom selectNodes string(/refined_index_response/status/code)]
	if {$status_code == "error"} {
	    .m confirm -type "1button" \
		-text "Refinement of indexing solution failed, sorry.\n[$a_dom selectNodes string(/refined_index_response/status/message)]" \
		-button1of1 "Dismiss"
	} else {
	    # Find out which lattice refined solution belongs to
	    set l_lattice [$a_dom selectNodes normalize-space(/refined_index_response/lattice_number)]
	    # Increase session's counter
	    $::session setNumberLattices $l_lattice
	    # Set the current lattice
	    $::session setCurrentLattice $l_lattice
	  # puts "debug: Refined results for lattice $l_lattice"
          # flush stdout

	    if {![info exists path_to_tab($l_lattice)]} {
		
		set tab_no [expr {$l_lattice - 1}]

		$itk_component(tabs) add -label "Lattice $l_lattice" -command [ code $this raiseLatticetab $tab_no ]
		eval set lattice${l_lattice}_tab [$itk_component(tabs) childsite $tab_no]
		eval set tab \$lattice${l_lattice}_tab
    
		itk_component add lattice_tab${l_lattice} {
		    eval set ltab${l_lattice} [Latticetab $tab.lattice_tab]
		}
		#eval puts \"Tab no. \$tab_no is \$ltab${l_lattice}\"
    
		eval set path_to_tab(${l_lattice}) \$ltab${l_lattice}
		#puts "Latticetab is $path_to_tab(${l_lattice})"
    
		pack $itk_component(lattice_tab${l_lattice}) -fill both -expand 1
		$path_to_tab($l_lattice) addTreeHeadings
    
		# Select this tab and hide others
		$itk_component(tabs) select "Lattice $l_lattice";#$tab_no
    
		# Increment lattice combo
		.image setLatticeComboVal $l_lattice
    
		#puts "Lattice $l_lattice tab $tab_no widget $path_to_tab($l_lattice)"
    
		# Add this lattice to session's list
		$::session appendLatticeList $l_lattice
    
		# Set the list of lattice numbers
		.image setLatticeComboValues [$::session getLatticeList]

	    }

	    # Parse refined solution
          # puts "debug: about to Parse refined solution"
          # flush stdout
	    $path_to_tab($l_lattice) loadRefinedSolution $a_dom
    
	    # If no more refinement results are expected
	    if {![$::mosflm busy "indexing" "index_refinement"]} {
		# Mosaicity estimation should follow if flag is set
		set mosaicity_workflow "true"
	    }
    
	    # Save the session (as history events have been added quickly)
          # puts "debug: about to save session"
          # flush stdout
	    $::session writeToFile
          # puts "debug: session saved"
          # flush stdout
    
	    # enable controls
	    enable
	}
    } else {
	# Check on status of task
	set status_code [$a_dom selectNodes string(/refined_index_response/status/code)]
	if {$status_code == "error"} {
	    #.m confirm -type "1button" \
	    #	-text "Refinement of indexing solution failed, sorry.\n[$a_dom selectNodes string(/refined_index_response/status/message)]" \
	    #	-button1of1 "Dismiss"
	    return
	} else {
	    #puts [$a_dom asXML]
	  # puts "debug: Storing results of indexing"
          # flush stdout
	    set bs_spot_deviation_pos [format %4.2f [$a_dom selectNodes normalize-space(//spot_deviation_pos)]]
	    set bs_spot_deviation_phi [format %4.2f [$a_dom selectNodes normalize-space(//spot_deviation_phi)]]
	    set bs_beam_x [$a_dom selectNodes normalize-space(//beam_x)]
	    set bs_beam_y [$a_dom selectNodes normalize-space(//beam_y)]
	    set bs_beam_shift_abs [format %4.2f [$a_dom selectNodes normalize-space(//beam_shift_abs)]]
	    set bs_beam_shift_rel [$a_dom selectNodes normalize-space(//beam_shift_rel)]
	    set bs_reflections_used [$a_dom selectNodes normalize-space(//reflections_used)]
    
	    set bs_a [format %5.1f [$a_dom selectNodes {normalize-space(//a)}]]
	    set bs_b [format %5.1f [$a_dom selectNodes {normalize-space(//b)}]]
	    set bs_c [format %5.1f [$a_dom selectNodes {normalize-space(//c)}]]
	    set bs_alpha [format %5.1f [$a_dom selectNodes {normalize-space(//alpha)}]]
	    set bs_beta [format %5.1f [$a_dom selectNodes {normalize-space(//beta)}]]
	    set bs_gamma [format %5.1f [$a_dom selectNodes {normalize-space(//gamma)}]]
    
	    set start_beam_x [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 0]]]
	    set start_beam_y [format %5.1f [lindex [lindex $beam_list [expr $grid_counter - 1] 1]]]
    
	    set volume [format %12.1f [$a_dom selectNodes {normalize-space(//volume)}]]
    
	    set bs_item [$itk_component(beamsearch_tree) item create]
	    $itk_component(beamsearch_tree) item style set $bs_item 0 s2 1 s2 2 s2 3 s2 4 s2 5 s2 6 s2 7 s2 8 s2 9 s2 10 s2 11 s2 12 s2
	    $itk_component(beamsearch_tree) item text $bs_item 0 $start_beam_x
	    $itk_component(beamsearch_tree) item text $bs_item 1 $start_beam_y
	    $itk_component(beamsearch_tree) item text $bs_item 2 $bs_beam_x
	    $itk_component(beamsearch_tree) item text $bs_item 3 $bs_beam_y			
	    $itk_component(beamsearch_tree) item text $bs_item 4 $bs_a
	    $itk_component(beamsearch_tree) item text $bs_item 5 $bs_b
	    $itk_component(beamsearch_tree) item text $bs_item 6 $bs_c
	    $itk_component(beamsearch_tree) item text $bs_item 7 $bs_alpha
	    $itk_component(beamsearch_tree) item text $bs_item 8 $bs_beta
	    $itk_component(beamsearch_tree) item text $bs_item 9 $bs_gamma
	    $itk_component(beamsearch_tree) item text $bs_item 10 $bs_spot_deviation_pos
	    $itk_component(beamsearch_tree) item text $bs_item 11 $bs_spot_deviation_phi
	    $itk_component(beamsearch_tree) item text $bs_item 12 $bs_beam_shift_abs
	    
	    $itk_component(beamsearch_tree) item lastchild root $bs_item
	    $itk_component(beamsearch_tree) yview moveto 1.0
	    
	    # record beam shift for each tree item for sorting
	    set spot_dev_pos($bs_item) $bs_spot_deviation_pos
	    set cell_volume($bs_item) $volume
	    # puts "debug: item $bs_item ; rmsd for sort $bs_spot_deviation_pos"
	
	    if {![$::mosflm busy "indexing" "index_refinement"]} {
		enable
	    }
	    gridSearchRelay
	}
    }
  # puts "debug: Exit Indexwizard::processRefinedResult"
  # flush stdout
}

body Indexwizard::sortBeamSearchCell { a_item b_item } {

    set a_value $cell_volume($a_item)
    set b_value $cell_volume($b_item)

    # First get rid of values flagged as maximum
    if { $a_value == 9999999999.9 } {
	if { $b_value < $a_value } {
	    return +1
	} else {
	    return 0
	}
    }
    if { $b_value == 9999999999.9 } {
	if { $a_value < $b_value } {
	    return -1
	} else {
	    return 0
	}
    }

    set a_plus [expr { $a_value * 1.25 }]
    set a_minus [expr { $a_value * 0.75 }]
    set b_plus [expr { $b_value * 1.25 }]
    set b_minus [expr { $b_value * 0.75 }]
    if {$a_plus < $b_minus} {
	#puts "a+5% $a_plus < b-5% $b_minus :-1"
	return -1
    } elseif {$a_minus > $b_plus} {
	#puts "a-5% $a_minus > b+5% $b_plus :+1"
	return +1
    } else {
	#puts "Small volume difference: $a_value and $b_value is [expr {$a_value - $b_value}]"
	return 0
    }
}

body Indexwizard::sortBeamSearchDevn { a_item b_item } {
    #puts "IW::BeamSearchResults a_item $a_item b_item $b_item"

    set a_value $spot_dev_pos($a_item)
    set b_value $spot_dev_pos($b_item)
    if {$a_value < $b_value} {
	return -1
    } elseif {$a_value > $b_value} {
	return +1
    } else {
	return 0
    }
}

# Mosaicity & completion methods ######################################################

body Indexwizard::estimateMosaicity { } {
    # Launch mosaicity estimation with first image used in indexing
    set l_image [lindex $images_being_autoindexed 0]
    if {$l_image == ""} {
	set l_image [.image getImage]
    }
    eval .me launch $l_image
}

body Indexwizard::updateIndexButton { } {
    # Count total spots
    set l_total 0
    foreach i_image [array names image_items_by_object] {
	set l_spotlist [$i_image getSpotlist]
	    incr l_total [format %3d [$l_spotlist getTotal]]
    }
    # Update button
    if {$l_total >= 12} {
        if {$::debugging} {
            puts "flow: *** Enabling Index button in Indexwizard::updateIndexButton"
        }
	$itk_component(index_button) configure -state normal
    } else {
        if {$::debugging} {
            puts "flow: *** Disabling Index button in Indexwizard::updateIndexButton"
        }
	$itk_component(index_button) configure -state disabled
    }
}

body Indexwizard::updateMosaicityButton { } {
    if {[$::session mosaicityEstimationPossible]} {
	$itk_component(mosaicity_estimate_b) configure -state normal
    } else {
	$itk_component(mosaicity_estimate_b) configure -state disabled
    }
}

body Indexwizard::fixMaxCellEdge { } {
    $itk_component(fix_max_cell_edge_tb) invoke
}

body Indexwizard::addCell { args } {
    if {![winfo exists .priorCell]} {
	PriorCellDialog .priorCell -title "Input known cell ..."
    }
    # Clear the dialog
    #.priorCell clear
    # Get cell from the user
    set prior_cell [.priorCell get]
    #puts "priorCell returned $prior_cell with parameters: [getPriorCell]"
}

body Indexwizard::setPriorCell { {a1 ""} {a2 ""} {a3 ""} {a4 ""} {a5 ""} {a6 ""} } {
    #puts "setPriorCell given $a1 $a2 $a3 $a4 $a5 $a6"
    $itk_component(priorcelllabel) configure -text " Prior cell: $a1 $a2 $a3 $a4 $a5 $a6"
    set new_label ""
    set label [$itk_component(index_button) cget -text]
    #puts "setPriorCell: label $label"
    # Relabel the Index button to emphasize the mode of Indexing
    if { $a1 != "" } {
        $itk_component(index_cell) configure -background red
	$itk_component(index_button) configure -text "$label Cell"
    } else {
	regsub -all " Cell" $label "" new_label
	$itk_component(index_cell) configure -background "\#dcdcdc"
	$itk_component(index_button) configure -text "$new_label"
    }
    #puts "Text now [$itk_component(priorcelllabel) cget -text]"
}

body Indexwizard::getPriorCell { } {
    regsub -all " Prior cell: " [$itk_component(priorcelllabel) cget -text] "" prior_cell
    set prior_cell [string trim $prior_cell]
    #puts "getPriorCell gets $prior_cell from [$itk_component(priorcelllabel) cget -text]"
    if { $prior_cell != "" } {
        return $prior_cell
    } else {
	return ""
    }
}

body Indexwizard::unknownReasonForFailure { } {
    if {![winfo exists .indexConfigDialog]} {
	IndexConfigDialog  .indexConfigDialog -title "Indexing has failed"
    }
    .indexConfigDialog get
    if { $::doIndexNow == "ok" } {
# update image list here, 
	
	set a_template [lindex [join [$itk_component(image_numbers) getContent]] 0]
        $itk_component(image_numbers) updateSector $a_template [compressNumList [$::session getIndexingList]]
    # if images are selected, find spots and index
	set images_list [$::session getIndexingList]
	if { $images_list != "" } {
	    chooseImages [[$::session getCurrentSector] getTemplate] $images_list
            if {$::debugging} {
                puts "flow: call queueAutoindex from Indexwizard::unknownReasonForFailure"
            }
	    queueAutoindex
	}
    }
    return
}

body Indexwizard::indexNow { a_value } {
    set ::doIndexNow $a_value
    return ::doIndexNow
}

usual Indexwizard { 
} 

# Index config dialog ############################################

class IndexConfigDialog {
    inherit Dialog

    #private variable name ""

    # six prior cell parameters
    private variable maxCell ""
    private variable threshold ""
    private variable images ""
    private variable beamX ""
    private variable beamY ""
    private variable distance ""
    private variable reversePhi ""
    private variable wavelength ""

    # and their labels
    private variable l_maxCell ""
    private variable l_threshold ""
    private variable l_images ""
    private variable l_beamX ""
    private variable l_beamY ""
    private variable l_reversePhi ""
    private variable l_wavelength ""

    public method get
    public method ok
    private method cancel
    private method autoindex

    constructor { args } { }
}

body IndexConfigDialog::constructor { args } {

   
    set l_auto 0
    set l_manual 0
    set l_deleted 0
    set l_total 0
    set n_images 0
    set image_numbers ""

    set maxCellEdge [$::session getParameterValue "max_cell_edge"]
    set threshold [$::session getParameterValue "i_sig_i"]
    set beam_x [$::session getParameterValue "beam_x"]
    set beam_y [$::session getParameterValue "beam_y"]
    set distance [$::session getParameterValue "distance"]
    set wavelength [$::session getParameterValue "wavelength"]
    
#
#
    #puts "In IndexConfigDialog::constructor, calling getCurrentSector"
    set l_images [[$::session getCurrentSector] getImages]
    set image_list {}
    if {[llength $l_images] > 0} {
    # if there are any images to use...
	set a_template [[lindex $l_images 0] getTemplate]
	foreach i_image [$::session getIndexingList] {

	    lappend image_list [$::session getImageByTemplateAndNumber $a_template $i_image]
	}
    }
#
#
    foreach i_sector [$::session getSectors] {	
	foreach i_image $image_list {
	    set l_spotlist [$i_image getSpotlist]
	    # depending on whether there's a spotlist or not...
# NONONO - this should be whether it's active in the spot list or not!
	    if {$l_spotlist != ""} {
		set a_template [$i_image getTemplate]
		incr n_images
		incr l_auto [format %3d [$l_spotlist getAuto]]
		incr l_manual [format %3d [$l_spotlist getManual]]
		incr l_deleted [format %3d [$l_spotlist getDeleted]]
		incr l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
	    }
	}
    }
    set list_image_numbers [$::session getIndexingList]

    itk_component add image_numbers {
	Imagenumbers $itk_interior.icdin
    }

# populate sector, template and image numbers
    set current_sector [$::session getCurrentSector]
    #puts "In IndexConfigDialog::constructor current_sector set to $current_sector"
    $itk_component(image_numbers) addSector $current_sector
    $itk_component(image_numbers) updateSector $a_template $list_image_numbers
#     $::session setIndexingList $list_image_numbers

#===============


    set l_maxCell "Longer or shorter maximum unit cell"
    set l_threshold "Change I/sig(I) threshold to increase or decrease the number of reflections \nused (200 - 1000 is best, you are using $l_total reflections out of $l_auto found)"
    set l_images "More or fewer images well-separated in phi (currently using $n_images images)"
    set l_beamX "Check direct beam position (see magenta cross on image display)"
    set l_beamY "Crystal to detector distance"
    set l_reversePhi "Reversed direction of rotation of crystal"
    set l_wavelength "Wavelength of X-rays; this is unlikely to be wrong if it has been read from \nthe image header"
# display magenta cross for direct beam 
    $::session forceBeamSetting
    ImageDisplay::toggleBeam 1

    itk_component add xmm {
	label $itk_interior.xmm -text "mm " -justify left
    }

    itk_component add ymm {
	label $itk_interior.ymm -text "mm " -justify left
    }

    itk_component add dmm {
	label $itk_interior.dmm -text "mm " -justify left
    }

    itk_component add angstrom {
	label $itk_interior.angstrom -text "Å " -justify left
    }

    itk_component add angstromL {
	label $itk_interior.angstromL -text "Å " -justify left
    }

    itk_component add maxCell_l {
	    label $itk_interior.icdmaxCell_l \
		-justify left \
		-text "[subst \$l_maxCell] "
	}

	itk_component add maxCell_e {
	    SettingEntry $itk_interior.icdmaxCell_e max_cell_edge \
		-type real \
		-precision 2 \
		-width 8 \
		-textvariable [scope maxCell] \
		-justify right \
		-balloonhelp "Maximum cell edge in Angstroms searched for in autoindexing" 
	}

	itk_component add threshold_l {
	    label $itk_interior.icdthreshold_l \
		-justify left \
		-text "[subst \$l_threshold] "
	}
	itk_component add threshold_e {
	    SettingEntry $itk_interior.icdthreshold_e i_sig_i \
		-type real \
		-precision 2 \
		-width 8 \
		-textvariable [scope threshold] \
		-justify right \
		-balloonhelp "I/sig(i) threshold for including spots in indexing,\nnot the threshold used in spot finding" 
	}

	itk_component add images_l {
	    label $itk_interior.icdimages_l \
		-justify left \
		-text "[subst \$l_images] "
	}

	itk_component add beamXY_l {
	    label $itk_interior.icdbeamXY_l \
		-justify left \
		-text "[subst \$l_beamX] "
	}
	itk_component add beamX_e {
	    SettingEntry $itk_interior.icdbeamX_e beam_x \
		-type real \
		-precision 2 \
		-width 8 \
		-textvariable [scope beamX] \
		-justify right \
		-balloonhelp "beam x (mm)"
	}
	itk_component add beamY_e {
	    SettingEntry $itk_interior.icdbeamY_e beam_y \
		-type real \
		-precision 2 \
		-width 8 \
		-textvariable [scope beamY] \
		-justify right \
		-balloonhelp "beam y (mm)" 
	}
	itk_component add distance_l {
	    label $itk_interior.icddistance_l \
		-text "[subst \$l_beamY] "
	}
	itk_component add distance_e {
	    SettingEntry $itk_interior.icddistance_e distance \
		-width 8 \
		-textvariable [scope distance] \
		-justify right \
		-balloonhelp "Crystal to detector distance in mm" 
	}
	itk_component add reversePhi_l {
	    label $itk_interior.icdreversePhi_l \
		-text "[subst \$l_reversePhi] "
	}
	itk_component add reversePhi_e {
	    SettingCheckbutton $itk_interior.icdreversePhi_e reverse_phi \
		-text " \"Reverse phi\""
	}
	itk_component add wavelength_l {
	    label $itk_interior.icdwavelength_l \
		-text "[subst \$l_wavelength]: "
	}
	itk_component add wavelength_e {
	    SettingEntry $itk_interior.icdwavelength_e wavelength \
		-width 8 \
		-textvariable [scope wavelength] \
		-justify right \
		-balloonhelp "Wavelength of radiation used (unlikely to be wrong)" 
	}


	$itk_component(maxCell_e) setValue $maxCellEdge
	$itk_component(threshold_e) setValue $threshold
	$itk_component(beamX_e) setValue $beam_x
	$itk_component(beamY_e) setValue $beam_y
	$itk_component(distance_e) setValue $distance
	$itk_component(reversePhi_e) setValue [$::session getReversePhi]
	$itk_component(wavelength_e) setValue $wavelength
    itk_component add button_frame {
	frame $itk_interior.icdbf
    }

    itk_component add cancel {
	button $itk_interior.icdbf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -command [code $this cancel]
    }

    itk_component add ok {
	button $itk_interior.icdbf.ok \
	    -text "Okay" \
	    -width 7 \
	    -command [code $this ok]
    }



    itk_component add preamble {
	label $itk_interior.icdpreamble \
	    -justify left \
	    -text "
Indexing has failed because one or more of the following is so wrong that iMosflm can't figure out what\nto do. You will need to think and to examine your images to try to work out which of the following hints\nis useful.\n\nIt's usually best to start at the top of the list and work down if indexing is still unsuccessful\n"

    }
    grid $itk_component(preamble) -columnspan 6 -pady 3 -sticky w
    grid $itk_component(beamXY_l) $itk_component(beamX_e) $itk_component(xmm) $itk_component(beamY_e)  $itk_component(ymm)  - -pady 3 -sticky w
    grid $itk_component(maxCell_l) $itk_component(maxCell_e) $itk_component(angstrom) - - - -pady 3 -sticky w
    grid $itk_component(threshold_l) $itk_component(threshold_e) - - - - -pady 3 -sticky w
    grid $itk_component(images_l) -columnspan 6 -pady 3 -sticky w
    grid $itk_component(image_numbers) - - - - -columnspan 5 -sticky w
    grid $itk_component(distance_l) $itk_component(distance_e) $itk_component(dmm) - - - - -pady 3 -sticky w
    grid $itk_component(reversePhi_l) $itk_component(reversePhi_e) - - - - -pady 3 -sticky w
    grid $itk_component(wavelength_l) $itk_component(wavelength_e) $itk_component(angstromL) - - - -pady 3 -sticky w
    grid $itk_component(button_frame) - - - -sticky we
    grid columnconfigure $itk_interior { 4 } -weight 1

    pack $itk_component(ok) $itk_component(cancel) -side right -pady 7 -padx { 0 7 }

    eval itk_initialize $args

}

body IndexConfigDialog::ok { } {
    Indexwizard::indexNow "ok"
    set ::doIndexNow "ok"
    dismiss ""
    if {$::debugging} {
        puts "flow: calling setIndexingList from within IndexConfigDialog::ok"
    }
    $::session setIndexingList [lindex [join [$itk_component(image_numbers) getContent]] 1]
    set n_images [llength [uncompressNumList [lindex [join [$itk_component(image_numbers) getContent]] 1]]]
    set l_images "More or fewer images well-separated in phi (currently using $n_images images): change this in the image selection bar"
    $itk_component(images_l) configure \
	-text "[subst \$l_images]"
    return "ok"
}

	
body IndexConfigDialog::get { } {
    Indexwizard::indexNow "get"
    set ::doIndexNow "get"
    return [confirm]
}

body IndexConfigDialog::cancel { } {
    Indexwizard::indexNow "cancel"
    dismiss ""
    set ::doIndexNow "cancel"
    return "cancel"
}



# Prior cell dialog ############################################

class PriorCellDialog {
    inherit Dialog

    #private variable name ""
    # six prior cell parameters
    private variable a1 ""
    private variable a2 ""
    private variable a3 ""
    private variable a4 ""
    private variable a5 ""
    private variable a6 ""

    # and their labels
    private variable l1 "a"
    private variable l2 "b"
    private variable l3 "c"
    private variable l4 "alpha"
    private variable l5 "beta"
    private variable l6 "gamma"

    public method get
    private method cancel
    private method ok
    public method clear
    private method validateCell

    constructor { args } { }
}

body PriorCellDialog::constructor { args } {

    foreach num { 1 2 3 4 5 6 } {
	itk_component add a${num}_l {
	    label $itk_interior.a${num}_l \
		-text "[subst \$l${num}]: "
	}
	itk_component add a${num}_e {
	    gEntry $itk_interior.a${num}_e \
		-type real \
		-precision 2 \
		-width 8 \
		-textvariable [scope a$num] \
		-justify right \
		-command [code $this validateCell]
	}
    }

    itk_component add button_frame {
	frame $itk_interior.bf
    }

    itk_component add clear {
	button $itk_interior.bf.clear \
	    -text "Clear" \
	    -width 7 \
	    -command [code $this clear]
    }

    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -width 7 \
	    -command [code $this cancel]
    }

    itk_component add ok {
	button $itk_interior.bf.ok \
	    -text "OK" \
	    -width 7 \
	    -command [code $this ok]
    }

    grid $itk_component(a1_l) $itk_component(a1_e) $itk_component(a2_l) $itk_component(a2_e) $itk_component(a3_l) $itk_component(a3_e) -padx 7 -pady 7
    grid $itk_component(a4_l) $itk_component(a4_e) $itk_component(a5_l) $itk_component(a5_e) $itk_component(a6_l) $itk_component(a6_e) -padx 7 -pady 7
    grid $itk_component(button_frame) - - - - - -sticky we
    grid columnconfigure $itk_interior { 5 } -weight 1

    pack $itk_component(ok) $itk_component(cancel) $itk_component(clear) -side right -pady 7 -padx { 0 7 }

    eval itk_initialize $args

    validateCell
    [.c component indexing] setPriorCell "" "" "" "" "" ""
}

body PriorCellDialog::cancel { } {
    dismiss ""
}
	
body PriorCellDialog::ok { } {
    set pcell [namespace current]::[Cell \#auto "initialize" "prior" $a1 $a2 $a3 $a4 $a5 $a6]
    [.c component indexing] setPriorCell $a1 $a2 $a3 $a4 $a5 $a6
    dismiss $pcell
    #$::session validateCellAndSpacegroup $a1 $a2 $a3 $a4 $a5 $a6 "P1"
}

body PriorCellDialog::get { } {
    return [confirm]
}

body PriorCellDialog::clear { } {
    foreach param { 1 2 3 4 5 6 } {
	set a${param} ""
    }
    [.c component indexing] setPriorCell "" "" "" "" "" ""
    $itk_component(ok) configure -state disabled
}

body PriorCellDialog::validateCell { args } {
    set l_valid_cell 1
    foreach num { 1 2 3 4 5 6 } {
	set l_element [set a${num}]
	if {$l_element == "" || (![string is double $l_element])} {
	    set l_valid_cell 0
	    break
	}
    }

    if {$l_valid_cell} {
	$itk_component(ok) configure -state normal
	return 1
    } else {
	$itk_component(ok) configure -state disabled
	return 0
    }
}

class SpotfindingPalette {
    inherit Palette

    private variable image_objects_by_number ; # NB array - don't initialize
    private variable image_objects_by_item ; # NB array - don't initialize
    private variable image_items_by_number ; # NB array - don't initialize
    private variable image_items_by_object ; # NB array - don't initialize

    public method launch
    public method buildImageList
    public method sortSpotFindingResults
    public method checkImage
    public method uncheckImage
    public method updateSpotFindingResult

    private method imageTreeClick
    private method imageTreeDoubleClick
    private method toggleSpotlistInclusion
    private method toggleImageSelection

    constructor { args } { }

}

body SpotfindingPalette::launch { a_button args } {
    buildImageList
    Palette::launch $a_button
}
    

body SpotfindingPalette::constructor { args } {

    itk_component add image_tree {
	treectrl .sfp.itree \
	    -showroot 0 \
	    -showline 0 \
	    -showbutton 0 \
	    -selectmode single \
	    -width 430 \
	    -height 356 \
	    -itemheight 18
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    $itk_component(image_tree) column create -text "Image" -justify left -minwidth 80 -expand 1 ;#-itembackground {"\#ffffff" "\#e8e8e8"}
    $itk_component(image_tree) column create -text "\u03c6 range" -justify left -minwidth 120 -expand 1
    $itk_component(image_tree) column create -text "Auto" -justify center -minwidth 60 -expand 1 
    $itk_component(image_tree) column create -text "Man" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "Del" -justify center -minwidth 60 -expand 1
    $itk_component(image_tree) column create -text "> I/\u03c3(I)" -justify center -minwidth 80 -expand 1
    $itk_component(image_tree) column create -text "Find"  -justify center -minwidth 60 -tag search
    $itk_component(image_tree) column create -text "Use"  -justify center -minwidth 30 -tag use

    $itk_component(image_tree) state define CHECKED
    $itk_component(image_tree) state define AVAILABLE

    $itk_component(image_tree) element create e_icon image -image ::img::image
    $itk_component(image_tree) element create e_text text -fill {white selected}
    $itk_component(image_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
    $itk_component(image_tree) element create e_auto_search image -image { ::img::spot_search_auto {} }
    $itk_component(image_tree) element create e_check image -image { ::img::embed_check_on {CHECKED AVAILABLE} ::img::embed_check_off {AVAILABLE !CHECKED} ::img::embed_check_off_disabled {!AVAILABLE} }
	
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
    $itk_component(image_tree) style elements s3 {e_highlight e_auto_search}
    $itk_component(image_tree) style layout s3 e_highlight -union [list e_auto_search] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s3 e_auto_search -expand ns -padx {2 2}

    $itk_component(image_tree) style create s4
    $itk_component(image_tree) style elements s4 {e_highlight e_check}
    $itk_component(image_tree) style layout s4 e_highlight -union [list e_check] -iexpand nsew -ipadx 2
    $itk_component(image_tree) style layout s4 e_check -expand ns -padx {2 2}

    bind $itk_component(image_tree) <ButtonPress-1> [code $this imageTreeClick %W %x %y]
    bind $itk_component(image_tree) <Double-ButtonPress-1> [code $this imageTreeDoubleClick %W %x %y]
    bind $itk_component(image_tree) <ButtonRelease-1> { break }

    itk_component add image_scroll {
	scrollbar .sfp.iscroll \
	    -command [code $this component image_tree yview] \
	    -orient vertical
    }
    
    $itk_component(image_tree) configure \
	-yscrollcommand [list autoscroll $itk_component(image_scroll)]
    
    if {[tk windowingsystem] == "aqua"} {
	# Add a closing X as there was a problem dismissing the pop-up on an earlier aqua
	itk_component add exit_button {
	    button .sfp.eb -text "x"  \
		-command [code $this dismiss]
	}
	grid $itk_component(exit_button) -sticky ne -columnspan 2
    }

    grid $itk_component(image_tree) $itk_component(image_scroll)  -sticky nswe
    grid columnconfigure $itk_component(hull) 0 -weight 1

    eval itk_initialize $args
}

body SpotfindingPalette::buildImageList { } {
    #puts "Entering SpotfindingPalette::buildImageList"
    # Configure the treectrl with apprpriate column width, and remove buttons/lines
    $itk_component(image_tree) configure -showlines 0 -showbuttons 0
    $itk_component(image_tree) column configure 0 -width {}

    # clear existing image arrays 
    array unset image_objects_by_number *
    array unset image_objects_by_item *
    array unset image_items_by_number *
    array unset image_items_by_object *

    # clear the image tree
    $itk_component(image_tree) item delete all


    ### Build list of images for tree

    # Choose labelling method depending on number of templates
    if {[llength [$::session getSectors]] > 1} {
	set l_labelMethod "getRootName"
    } else {
	set l_labelMethod "getNumber"
    }

    # loop through session's sectors and images...
    foreach i_sector [$::session getSectors] {
        #puts "Looping through sectors, sector is: $i_sector"
	foreach i_image [$i_sector getImages] {
	    # create a new item
	    set t_item [$itk_component(image_tree) item create]
	    # set the item's style
	    $itk_component(image_tree) item style set $t_item 0 s1 1 s2 2 s2 3 s2 4 s2 5 s2 6 s3 7 s4
	    # get the label to be used
	    set l_label [$i_image $l_labelMethod]
	    set l_phis [$i_image reportPhis -mode "range"]
    
	    # get any existing spotlist
	    set l_spotlist [$i_image getSpotlist]
	    # depending on whether there's a spotlist or not...
	    if {$l_spotlist != ""} {
		# Set state to indicate spots are available from this image (but none checked yet)
		$itk_component(image_tree) item state set $t_item [list AVAILABLE !CHECKED]
		# Get the text summary for display in the image tree
		set l_icon ::img::spotlist
		set l_auto [format %3d [$l_spotlist getAuto]]
		set l_manual [format %3d [$l_spotlist getManual]]
		set l_deleted [format %3d [$l_spotlist getDeleted]]
		set l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
	    } else {
		# Set state to indicate spots are NOT available from this image
		$itk_component(image_tree) item state set $t_item [list !AVAILABLE !CHECKED] 
		# Make text summary indicating no spots searched for yet
		set l_icon ::img::image
		set l_auto " - "
		set l_manual " - "
		set l_deleted " - "
		set l_total " - "
	    }
	    # update the image icon
	    $itk_component(image_tree) item element configure $t_item 0 e_icon -image $l_icon
	    # update the text summaries
	    $itk_component(image_tree) item text $t_item 0 $l_label 1 $l_phis 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
	    # add the new item to the tree
	    $itk_component(image_tree) item lastchild root $t_item
	    # Store pointer to image objects and items by number, item or object
	    set image_objects_by_number([$i_image getNumber]) $i_image
	    set image_objects_by_item($t_item) $i_image
	    set image_items_by_number([$i_image getNumber]) $t_item
	    set image_items_by_object($i_image) $t_item
	}
    }
    
    # Check all images listed in main window
    foreach i_image [[.c component indexing] getIncludedImages] {
	checkImage $i_image
    }

    # Sort the image tree
    $itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]

    # Scroll to top of tree
    $itk_component(image_tree) yview moveto 0
    
}

body SpotfindingPalette::sortSpotFindingResults { a_item b_item } {
    #puts "SP:sort a_item $a_item b_item $b_item"
    set a_available [$itk_component(image_tree) item state get $a_item AVAILABLE]
    set b_available [$itk_component(image_tree) item state get $b_item AVAILABLE]
    if {$a_available && !$b_available} {
	return -1
    } elseif {!$a_available && $b_available} {
	return +1
    } else {
	if {[info exists image_objects_by_item($a_item)]} {
	    set a_image $image_objects_by_item($a_item)
	    set a_image_num [$a_image getRootName]
	}
	if {[info exists image_objects_by_item($b_item)]} {
	    set b_image $image_objects_by_item($b_item)
	    set b_image_num [$b_image getRootName]
	}
	if {$a_image_num < $b_image_num} {
	    return -1
	} elseif {$a_image_num > $b_image_num} {
	    return +1
	} else {
	    return 0
	}
    }
}

body SpotfindingPalette::imageTreeClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	$w activate [$w index [list nearest $x $y]]
	foreach {what item where arg1 arg2 arg3} $id break
	if {[lindex $id 5] == "e_check"} {
	    toggleSpotlistInclusion $item
	}
    }
}

body SpotfindingPalette::imageTreeDoubleClick { w x y } {
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	if {[lindex $id 5] == "e_auto_search"} {
	    set choosing_images "0"
	    [.c component indexing] findSpots $image_objects_by_item($item)
	} elseif {[lindex $id 5] == "e_check"} {
	    toggleSpotlistInclusion $item
	}
    }
}

body SpotfindingPalette::toggleSpotlistInclusion { an_item } {
    set choosing_images 0
    # if the item is available...
    if {[$itk_component(image_tree) item state get $an_item AVAILABLE]} {
	if {[$itk_component(image_tree) item state get $an_item CHECKED]} {
	    uncheckImage $image_objects_by_item($an_item)
	    #puts "Item $an_item AVAILABLE now UNchecked"
	    [.c component indexing] removeImage $image_objects_by_item($an_item)
	} else {
	    checkImage $image_objects_by_item($an_item)
	    #puts "Item $an_item AVAILABLE  now  checked"
	    [.c component indexing] addImage $image_objects_by_item($an_item)
	}
    } else {
	#puts "Item $an_item not AVAILABLE"
    }
}

body SpotfindingPalette::checkImage { an_image } {
    catch {$itk_component(image_tree) item state set $image_items_by_object($an_image) CHECKED}
}

body SpotfindingPalette::uncheckImage { an_image } {
    catch {$itk_component(image_tree) item state set $image_items_by_object($an_image) !CHECKED}
}

body SpotfindingPalette::updateSpotFindingResult { a_image } {
    # Only bother if the image is in the wizard's list!
    if {[info exists image_items_by_object($a_image)]} {
	# get the image's item
	set l_item $image_items_by_object($a_image)
	# get the image's spotlist
	set l_spotlist [$a_image getSpotlist]
	# get the image's label in the image tree
	set l_label [$itk_component(image_tree) item text $l_item 0]
	if {$l_spotlist != ""} {
	    $itk_component(image_tree) item state set $l_item AVAILABLE
	    set l_icon ::img::spotlist
	    set l_auto [format %3d [$l_spotlist getAuto]]
	    set l_manual [format %3d [$l_spotlist getManual]]
	    set l_deleted [format %3d [$l_spotlist getDeleted]]
	    set l_total [format %3d [$l_spotlist getTotalAboveIsigi]]
	} else {
	    $itk_component(image_tree) item state set $l_item !AVAILABLE
	    set l_icon ::img::image
	    set l_auto " - "
	    set l_manual " - "
	    set l_deleted " - "
	    set l_total " - "
	}

	$itk_component(image_tree) item element configure $l_item 0 e_icon -image $l_icon
	$itk_component(image_tree) item text $l_item 2 $l_auto 3 $l_manual 4 $l_deleted 5 $l_total
	# Sort the image tree
	$itk_component(image_tree) item sort root -command [code $this sortSpotFindingResults]
    }
}
