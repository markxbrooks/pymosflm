# package name
package provide controller 3.0
# $Id: controller.tcl,v 1.150 2022/11/08 11:40:54 andrew Exp $
# Class
class Controller {
    inherit itk::Widget

    # variables
    ###########

    # user profile
    private variable user_profile ""

    # launcher option variable
    private variable choice "1"
    
    # current stage
    private variable current_stage "hull"
    private variable previous_stage "hull"

    # status update queue
    private variable status_update_queue ""

    # main control first display flag
    private variable displayed_yet "0"

    # view menu options
    private variable showvariables "0"

    # name of session file
    private variable sessionfile ""

    # visual controls variables
    public variable image_files ""
    public variable selected_images ""
    public variable images_to_index ""

    # session tree variables
    private variable session_items_by_object ; # array
    private variable session_objects_by_item ; # array

    public variable temp_strategy_file ""
    public variable haveTempStrategyfile 0
    
    # methods
    #########

    # Initialization and shutdown

    public method initialize
    public method shutdown
    public method saveProfile

    # Interface configuration
    
    private method updateSessionMenu

    public method launch
    public method hide

    # activity and status methods
    public method busy
    public method errorMessage
    public method pause
    public method progress
    public method idle
    public method updateStatusMessage
    public method setColourCode
    private method showStatusHelp
    private method moveStatusHelp
    private method hideStatusHelp
    public method addWarning
    public method deleteWarning

    public method showAbout
    public method showWebpage

    public method disable
    public method enable
    private method toggleState

    public method showStage
    public method enableStage
    public method disableStage
    public method rollover
    public method rolloutof

    public method showIndexSettings
    public method showIntegrationSettings
    public method showExperimentSettings
    public method showHistory
    public method toggleIndexingSettings
    public method toggleExperimentSettings
    public method toggleIntegrationSettings
    public method toggleHistory

    public method enableIndexing
    public method disableIndexing
    public method enableProcessing
    public method disableProcessing

    # Session configuration

    public method getSiteFile
    public method readSiteFile
    public method parseSiteFile
    public method writeSiteFile
    public method addImages
    public method deleteImagesFromSector
    public method addSpots
    public method saveSpots
    private method promptSaving
    public method saveSession
    public method saveSessionAs
    public method closeSession
    public method newSession
    public method openSession
    public method foo
    private method openSessionFile
    private method openTempStrategyFile
    public method getTempStrFilename
    public method existsTempStrFilename
    public method wroteTempStrFile    

    # Session tree methods
    public method displaySession
    public method addSector
    public method addImage
    public method flagImage
    public method updateCell
    public method updateSpacegroup
    public method updateMosaicity
    public method updateMosaicblock
    public method updateSector
    public method updateMatrix
    public method updateImage

    public method getObjectByItem

    public method doubleClickSession
    public method editTree

    public method editMatrixProperties

    # for context-sensitive right-click
    public method rightClickSession
    public method singleClickSession
    private variable lukesingle ""
    private variable lukesingle2 ""

    ###########################
    # Button callbacks
    public method estimateMosaicity

    public method uncheckAutothreshCheckbutton


    # Private methods
    
    private method refreshDialogs
    
    constructor { args } { }
    
}

# Bodies

body Controller::constructor { args } {
    
    # Prevent killing of main window
    wm protocol [winfo toplevel $itk_component(hull)]  WM_DELETE_WINDOW [code $this shutdown]

    # Set up width and height
    itk_option add hull.width hull.height
    $itk_component(hull) configure -width 1050 -height 768	
    wm minsize [winfo toplevel $itk_component(hull)] 1024 600
    pack propagate $itk_interior 0

    ### Menu bar and menus ####################################

    itk_component add menu {
	menu $itk_interior.menu \
	    -tearoff 0 \
	    -borderwidth 1
    } 
    
    [winfo toplevel $itk_component(hull)] configure \
	 -menu $itk_component(menu)
    
    itk_component add sessionmenu {
	menu $itk_interior.menu.session \
	    -tearoff 0
    }
    
    $itk_component(menu) add cascade \
	-label "Session" \
	-menu $itk_component(sessionmenu)

        
    if {[tk windowingsystem] == "aqua"} {
	set newSessionAccelerator "Command-N"
	set openSessionAccelerator "Command-O"
	set saveSessionAccelerator "Command-S"
	set exitAccelerator "Command-F4"
    } {
	set newSessionAccelerator "Control-N"
	set openSessionAccelerator "Control-O"
	set saveSessionAccelerator "Control-S"
	set exitAccelerator "Alt-F4"
    }

    $itk_component(sessionmenu) add command \
	-label New \
	-underline 0 \
	-accelerator $newSessionAccelerator \
	-command [code $this newSession]
    
    $itk_component(sessionmenu) add command \
	-label "Open..." \
	-underline 0 \
	-accelerator $openSessionAccelerator \
	-command [code $this openSession]
    
    $itk_component(sessionmenu) add command \
	-label "Save" \
	-underline 0 \
	-accelerator $saveSessionAccelerator \
	-command [code $this saveSession]
    
    $itk_component(sessionmenu) add command \
	-label "Save as..." \
	-underline 5 \
	-command [code $this saveSessionAs]
    
    $itk_component(sessionmenu) add separator
    
    $itk_component(sessionmenu) add command \
	-label "Read site file..." \
	-command [code $this getSiteFile open]

    $itk_component(sessionmenu) add command \
	-label "Save site file..." \
	-command [code $this getSiteFile save]

    $itk_component(sessionmenu) add separator

    $itk_component(sessionmenu) add command \
	-label "Add images..." \
	-underline 4 \
	-command [code $this addImages]

    $itk_component(sessionmenu) add command \
	-label "Read spots file..." \
	-underline 6 \
	-command [code $this addSpots]

    $itk_component(sessionmenu) add command \
	-label "Save spots file..." \
	-command [code $this saveSpots]

    $itk_component(sessionmenu) add separator
    
    $itk_component(sessionmenu) add command \
	-label "Exit" \
	-underline 1 \
	-accelerator $exitAccelerator \
	-command [code $this shutdown]
    
    # Settings menu - was View #################################
    
    itk_component add viewmenu {
	menu $itk_interior.menu.view \
	    -tearoff false
    }
    
    $itk_component(menu) add cascade \
	-label "Settings" \
	-menu $itk_component(viewmenu)

    $itk_component(viewmenu) add command \
	-label "Experiment settings" \
	-underline 2 \
	-command {.ass show}

    $itk_component(viewmenu) add command \
	-label "Processing options" \
	-underline 2 \
	-command {.ats show}

    $itk_component(viewmenu) add command \
	-label "Environment variables" \
	-underline 2 \
	-command {.evs show}

    # Help menu ################################################
    
    itk_component add helpmenu {
            menu $itk_interior.menu.help \
		-tearoff false
    }
    
    $itk_component(menu) add cascade \
	-label "Help" \
	-menu $itk_component(helpmenu)

    # Nothing to separate from yet
    #$itk_component(helpmenu) add separator
    
    $itk_component(helpmenu) add command \
	-label "iMosflm tutorial" \
	-underline 0 \
	-command [code $this showWebpage "$::env(MOSFLM_GUI)/tutorial.html"]

    $itk_component(helpmenu) add command \
	-label "iMosflm web pages" \
	-underline 0 \
	-command [code $this showWebpage "$::env(MOSFLM_GUI)/meta.html"]

    $itk_component(helpmenu) add command \
	-label "About iMosflm" \
	-underline 0 \
	-command [code $this showAbout]

    # Add menu icons on linux

    if {($::tcl_platform(os) != "Darwin") &&
	($::tcl_platform(os) != "Windows NT")} {
	
	$itk_component(sessionmenu) entryconfigure 0 \
	    -compound left \
	    -image ::img::file16x16

	$itk_component(sessionmenu) entryconfigure 1 \
	    -compound left \
	    -image ::img::folder16x16

	$itk_component(sessionmenu) entryconfigure 2 \
	    -compound left \
	    -image ::img::disk16x16

	$itk_component(sessionmenu) entryconfigure 3 \
	    -compound left \
	    -image ::img::blank16x16

	# separator - item 4

	$itk_component(sessionmenu) entryconfigure 5 \
	    -compound left \
	    -image ::img::blank16x16

	$itk_component(sessionmenu) entryconfigure 6 \
	    -compound left \
	    -image ::img::blank16x16

	# separator - item 7

	$itk_component(sessionmenu) entryconfigure 8 \
	    -compound left \
	    -image ::img::add_image

	$itk_component(sessionmenu) entryconfigure 9 \
	    -compound left \
	    -image ::img::spot16x16

	$itk_component(sessionmenu) entryconfigure 10 \
	    -compound left \
	    -image ::img::blank16x16

	# separator - item 11

	$itk_component(sessionmenu) entryconfigure 12 \
	    -compound left \
	    -image ::img::blank16x16

	# separator - item 13

	$itk_component(sessionmenu) entryconfigure 14 \
	    -compound left \
	    -image ::img::blank16x16

	$itk_component(viewmenu) entryconfigure 0 \
	    -compound left \
	    -image ::img::experimentsettings

	$itk_component(viewmenu) entryconfigure 1 \
	    -compound left \
	    -image ::img::settings16x16

	$itk_component(viewmenu) entryconfigure 2 \
	    -compound left \
	    -image ::img::pinetree16x16
    }

    ### Tool bar and toolbuttons ##############################
    ###########################################################

    itk_component add toolbar_frame {
	frame $itk_interior.tbf \
	    -relief raised \
	    -borderwidth 1
    }

    itk_component add toolbar {
	frame $itk_interior.tbf.toolbar
    }
    
    itk_component add new_tb {
	Toolbutton $itk_interior.tbf.toolbar.ntb \
	    -image ::img::file16x16 \
	    -command [code $this newSession] \
	    -balloonhelp "New session"
    }
    
    itk_component add open_tb {
	Toolbutton $itk_interior.tbf.toolbar.otb \
	    -image ::img::folder16x16 \
	    -command [code $this openSession] \
	    -balloonhelp "Open saved session"
    }
    
    itk_component add save_tb {
	Toolbutton $itk_interior.tbf.toolbar.stb \
	    -image ::img::disk16x16 \
	    -command [code $this saveSession] \
	    -balloonhelp "Save session"
    }
            
    ### Activity indicator ####################################
    ###########################################################

    itk_component add activity_l {
	Activity $itk_interior.tbf.al \
    }
    $itk_component(activity_l) idle

    # Main area frame
    ###########################################################


    itk_component add body {
	frame $itk_interior.body \
	    -borderwidth 1 \
	    -relief raised
    }

    ### Stage Menu controls ###################################

    itk_component add stages {
	canvas $itk_interior.body.stages \
	    -relief sunken \
	    -bd 2 \
	    -bg white \
	    -width 100 \
	    -highlightthickness 0
    }

    set l_stage_name(hull) "Images"
    set l_stage_name(indexing) "Indexing"
    set l_stage_name(strategy) "Strategy"
    set l_stage_name(cell_refinement) "Cell Refinement"
    set l_stage_name(integration) "Integration"
    #set l_stage_name(pointless) "Pointless"
    set l_stage_name(history) "History"

    set i_y 10
    foreach i_stage { hull indexing strategy cell_refinement integration  history } {
	$itk_component(stages) create rectangle \
	    -5 $i_y 105 [expr $i_y + 5 + 32 + 14 + 5] \
	    -fill {} \
	    -outline {} \
	    -tags box($i_stage)
	$itk_component(stages) create image 50 [expr $i_y + 5] \
	    -image ::img::stage_${i_stage} \
	    -anchor n \
	    -tags icon($i_stage)
	$itk_component(stages) create text 50 [expr $i_y + 5 + 32] \
	    -text $l_stage_name($i_stage) \
	    -anchor n \
	    -tags label($i_stage)
	$itk_component(stages) create rectangle \
	    -5 $i_y 105 [expr $i_y + 5 + 32 + 14 + 5] \
	    -fill {} \
	    -outline {} \
	    -tags overlay($i_stage)
	$itk_component(stages) bind overlay($i_stage) <Enter> \
	    [code $this rollover $i_stage]
	$itk_component(stages) bind overlay($i_stage) <Leave> \
	    [code $this rolloutof $i_stage]
	$itk_component(stages) bind overlay($i_stage) <1> \
	    [code $this showStage $i_stage]
	set i_y [expr $i_y + 5 + 32 + 10 + 5 + 10]
    }
    

    foreach i_stage { indexing strategy cell_refinement integration } {
	disableStage $i_stage
    }

    ### Indexing controls ##################################
    
    itk_component add indexing {
    if {$::debugging} {
        puts "flow: indexing control in controller: $itk_interior.body.indexing "
    }
	Indexwizard $itk_interior.body.indexing
    }

    ### Strategy controls ##################################
    
    itk_component add strategy {
	StrategyWidget $itk_interior.body.strategy
    }

    ### Cellrefinement controls ##################################
    
    itk_component add cell_refinement {
	Cellrefinementwizard $itk_interior.body.cellref
    }

    ### Integration controls ##################################
    
    itk_component add integration {
	Integrationwizard $itk_interior.body.integration 
    }

    ### Mosflm output log #####################################
    
    itk_component add history {
	HistoryViewer $itk_interior.body.outputlog
    }

#    itk_component add pointless {
#	    Pointlesswizard $itk_interior.body.pointless
#    }

    # Status bar ##############################################

    itk_component add status_bar {
	frame $itk_interior.body.sb \
	    -relief flat \
	    -borderwidth 0
    } {
	usual
	ignore -borderwidth
    }

    itk_component add status_message {
	label $itk_interior.body.sb.m \
	    -relief sunken \
	    -borderwidth 2 \
	    -anchor w \
	    -highlightthickness 0
    }

    itk_component add colourcode {
    label $itk_interior.body.sb.cc \
	-relief sunken \
	-borderwidth 2 \
	-width 6 \
	-text "Status" \
	-highlightthickness 1
    }

    itk_component add progress_bar {
	Progressbar $itk_interior.body.sb.p \
	    -borderwidth 2 \
	    -relief sunken \
	    -height 10 \
	    -width 200
    }

    itk_component add warnings {
	WarningWidget $itk_interior.body.sb.ww \
	    -deletecommand [code $this deleteWarning]
    }

    ### Main controls #########################################
    
    itk_component add main {
	frame $itk_interior.body.main \
	    -borderwidth 0 \
	    -relief raised
        } {
            keep -background
            keep -width
        }
    
    # Toolbars ###############################################

    itk_component add images_toolbar {
	frame $itk_component(toolbar_frame).images
    }

    # Divider

    itk_component add divider {
	frame $itk_component(images_toolbar).div1 \
	    -width 2 \
	    -relief sunken \
	    -bd 1
    }

    itk_component add add_images_tb {
	Toolbutton $itk_component(images_toolbar).aitb \
	    -image ::img::add_image \
	    -balloonhelp "Add images..." \
	    -command [code $this addImages]
    }

    itk_component add beam_x_e {
        SettingEntry $itk_component(images_toolbar).bxe beam_x \
	    -image ::img::beam_x16x16 \
	    -balloonhelp "Beam x position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add beam_y_e {
        SettingEntry $itk_component(images_toolbar).bye beam_y \
	    -image ::img::beam_y16x16 \
	    -balloonhelp "Beam y position" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    itk_component add distance_e {
        SettingEntry $itk_component(images_toolbar).de distance \
	    -image ::img::distance16x16 \
	    -balloonhelp "Crystal to detector distance" \
	    -type real \
	    -precision 2 \
	    -width 6 \
	    -justify right 
    }

    # Images frame ####################################################    

    itk_component add heading_f {
	frame $itk_interior.body.main.hf \
	    -bd 1 \
	    -relief solid 
    }

    itk_component add heading_l {
	label $itk_interior.body.main.hf.fl \
	    -text "Images" \
	    -font title_font \
	    -anchor w
    } {
	usual
	ignore -font
    }

    # Nascent tree frame for tabs
    itk_component add tree_f {
	frame $itk_interior.body.main.tf \
	    -bd 1 \
	    -relief solid 
    }

    itk_component add session_tree {
	treectrl $itk_interior.body.main.st \
	    -showroot 0 \
	    -showrootlines 0 \
	    -showheader 0 \
	    -selectmode single \
	    -width 800 \
	    -height 414
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }
    
    $itk_component(session_tree) column create -text Session -tag session -justify left -width 300 -expand 1 ;# -itembackground {"\#ffffff" "\#e8e8e8"} 
    $itk_component(session_tree) column create -text Value -tag value -justify left  -visible 1 -expand 1;#-itembackground {"\#ffffff" "\#e8e8e8"}
    $itk_component(session_tree) column create -text Order -tag order_column -justify left  -visible 0 ;#-itembackground {"\#ffffff" "\#e8e8e8"}

    $itk_component(session_tree) element create e_icon image -image ::img::raw_solution
    $itk_component(session_tree) element create e_text text -fill {white selected}
    $itk_component(session_tree) element create e_highlight rect -showfocus yes -fill { \#3399ff {selected focus} gray {selected !focus} }
	
    $itk_component(session_tree) style create s1
    $itk_component(session_tree) style elements s1 { e_highlight e_icon e_text }
    $itk_component(session_tree) style layout s1 e_icon -expand ns -padx {0 6} -pady {1 1}
    $itk_component(session_tree) style layout s1 e_text -expand ns
    $itk_component(session_tree) style layout s1 e_highlight -union [list e_text] -iexpand nse -ipadx 2
    
    $itk_component(session_tree) style create s2
    $itk_component(session_tree) style elements s2 {e_highlight e_text}
    $itk_component(session_tree) style layout s2 e_text -expand ns
    $itk_component(session_tree) style layout s2 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
    
    $itk_component(session_tree) style create s3
    $itk_component(session_tree) style elements s3 {e_highlight e_text}
    $itk_component(session_tree) style layout s3 e_text -expand ns
    $itk_component(session_tree) style layout s3 e_highlight -union [list e_text] -iexpand nsew -ipadx 2
    
    bind $itk_component(session_tree) <Double-ButtonPress-1> [code $this doubleClickSession %W %x %y]

    bindtags $itk_component(session_tree) [list $itk_component(session_tree) TreeCtrlFileList TreeCtrl [winfo toplevel $itk_component(session_tree)] all]
    # Editing bindings

    $itk_component(session_tree) notify install <Edit-begin>
    $itk_component(session_tree) notify install <Edit-end>
    $itk_component(session_tree) notify install <Edit-accept>

    # List of lists: {column style element ...} specifying text elements
    # the user can edit
    TreeCtrl::SetEditable $itk_component(session_tree) {
	{value s3 e_text}
    }
    
    # List of lists: {column style element ...} specifying elements
    # the user can click on or select with the selection rectangle
    TreeCtrl::SetSensitive $itk_component(session_tree) {
	{session s1 e_icon e_text e_highlight} {value s2 e_text e_highlight} {value s3 e_text e_highlight}
    }
    
    # List of lists: {column style element ...} specifying elements
    # added to the drag image when dragging selected items
    TreeCtrl::SetDragImage $itk_component(session_tree) {
	{session s1 e_icon e_text}
    }
    
    # During editing, hide the text and selection-rectangle elements.
    $itk_component(session_tree) notify bind $itk_component(session_tree) <Edit-begin> {
	%T item element configure %I %C e_text -draw no;# + e_highlight -draw no
    }
    $itk_component(session_tree) notify bind $itk_component(session_tree) <Edit-accept> [code $this editTree %I %C %E %t]

    $itk_component(session_tree) notify bind $itk_component(session_tree) <Edit-end> {
	%T item element configure %I %C e_text -draw yes;# + e_highlight -draw yes
    }

    #added by luke 19 October 2007
    itk_component add contextmenu {
	menu $itk_component(session_tree).context -tearoff 0
    }
    
    $itk_component(contextmenu) add command -label "delete" -command [code $this rightClickSession]
    
    ########################################################################
    bind $itk_component(session_tree) <3> [code tk_popup $itk_component(contextmenu) %X %Y]
    bind $itk_component(session_tree) <1> [code $this singleClickSession %W %x %y]
    #####################################################################
   
    itk_component add session_scroll {
	scrollbar $itk_interior.body.main.sscroll \
	    -command [code $this component session_tree yview] \
	    -orient vertical
    }
    
    $itk_component(session_tree) configure \
	-treecolumn 0 \
	-yscrollcommand [list autoscroll $itk_component(session_scroll)]

    # Toolbar layout
    pack $itk_component(divider) \
	-side left \
	-fill y \
	-padx 2 \
	-pady 1

    pack $itk_component(add_images_tb) $itk_component(beam_x_e) $itk_component(beam_y_e) $itk_component(distance_e) \
 	-side left \
	-padx 2

    # Images panel layout 
    grid $itk_component(heading_f) - -sticky nswe -padx 7 -pady {7 0}
    pack $itk_component(heading_l) -side left -padx 5 -pady 5 -fill both -expand 1
    #grid $itk_component(tree_f) - -sticky nswe -padx 7 -pady {7 0}
    grid $itk_component(session_tree) $itk_component(session_scroll) -sticky nswe -padx 7 -pady 7
    grid columnconfigure $itk_component(main) 0 -weight 1
    grid rowconfigure $itk_component(main) 1 -weight 1
           
    # Set up global accelerator bindings - Macs use "Command" not "Control" usually
    if {[tk windowingsystem] == "aqua"} {
    bind [winfo toplevel $itk_component(hull)] <Command-n> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Command-N> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Command-o> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Command-O> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Command-s> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Command-S> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Command-F4> [code $this shutdown]
    } {
    bind [winfo toplevel $itk_component(hull)] <Control-n> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Control-N> [code $this newSession]
    bind [winfo toplevel $itk_component(hull)] <Control-o> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Control-O> [code $this openSession]
    bind [winfo toplevel $itk_component(hull)] <Control-s> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Control-S> [code $this saveSession]
    bind [winfo toplevel $itk_component(hull)] <Alt-F4> [code $this shutdown]
    }
    bind [winfo toplevel $itk_component(hull)] <Alt-i> [code $this showStage "hull"]
    bind [winfo toplevel $itk_component(hull)] <Alt-I> [code $this showStage "hull"]
    bind [winfo toplevel $itk_component(hull)] <Alt-a> [code $this showStage "indexing"]
    bind [winfo toplevel $itk_component(hull)] <Alt-A> [code $this showStage "indexing"]
    bind [winfo toplevel $itk_component(hull)] <Alt-s> [code $this showStage "strategy"]
    bind [winfo toplevel $itk_component(hull)] <Alt-S> [code $this showStage "strategy"]
    bind [winfo toplevel $itk_component(hull)] <Alt-c> [code $this showStage "cell_refinement"]
    bind [winfo toplevel $itk_component(hull)] <Alt-C> [code $this showStage "cell_refinement"]
    bind [winfo toplevel $itk_component(hull)] <Alt-p> [code $this showStage "integration"]
    bind [winfo toplevel $itk_component(hull)] <Alt-P> [code $this showStage "integration"]
    bind [winfo toplevel $itk_component(hull)] <Alt-h> [code $this showStage "history"]
    bind [winfo toplevel $itk_component(hull)] <Alt-H> [code $this showStage "history"]

#    bind [winfo toplevel $itk_component(hull)] <Alt-l> [code $this showStage "pointless"]

    # Set up bindings for 'tooltip' Status display
    bind $itk_component(colourcode) <Enter> [code $this showStatusHelp %X %Y]
    bind $itk_component(colourcode) <Motion> [code $this moveStatusHelp %X %Y]
    bind $itk_component(colourcode) <Leave> [code $this hideStatusHelp]

    # Controller layout ###############################################
    # Tools
    pack $itk_component(toolbar_frame) -side top -fill x
    pack $itk_component(toolbar) -side left
    pack $itk_component(new_tb) -side left
    pack $itk_component(open_tb) -side left
    pack $itk_component(save_tb) -side left
    # Activity indicator
    pack $itk_component(activity_l) -side right -padx {0 7}
    # Body
    pack $itk_component(body) -side top -fill both -expand 1
    # Stages menu
    grid $itk_component(stages) -row 0 -column 0 -padx {7 0} -pady 7 -sticky ns
    # Main frame
    grid $itk_component(main) -row 0 -column 1 -sticky nswe
    # Status bar
    grid $itk_component(status_bar) -row 1 -column 0 -columnspan 2  -padx 7 -pady {0 7} -sticky we
    grid columnconfigure $itk_component(body) 1 -weight 1
    grid rowconfigure $itk_component(body) 0 -weight 1

    grid $itk_component(status_message) -row 0 -column 0 -stick we -padx {0 2}
    grid $itk_component(progress_bar) -row 0 -column 1 -stick nswe -padx {0 2}
    grid $itk_component(colourcode) -row 0 -column 2 -stick we
    grid $itk_component(warnings) -row 0 -column 3 -stick we
    grid columnconfigure $itk_component(status_bar) 0 -weight 1
    grid remove $itk_component(progress_bar)

    eval itk_initialize $args

}

########################################################################
# Initialization and shutdown                                          #
########################################################################

body Controller::initialize { } {

    # Start assuming no image file given
    set image_file ""


    # Check to see if .mosflm directory exists in user home directory
    set ::mosflm_directory [file join $::env(HOME) ".mosflm"] 
    # If .mosflm directory doesn't exist, make it.
    if {![file exists $::mosflm_directory]} {
	if {[catch {file mkdir $::mosflm_directory} message]} {
	    # report failure to create .mosflm directory 
	    error "Could not create .mosflm directory in $::env(HOME)\nPlease check your permissions and HOME environment variable."
	    exit
	} else {
	    # success
	    # Set flag indicating no clean up necessary
	    set l_cleanup 0
	}
    } else {
	# Set flag indicating clean up may be necessary
	set l_cleanup 1
    }

#Below I am writing a file and checking whether the operation is successful. 
#If the write is successful then we can safely launch mosflm which writes out
#a number of files.
#If the write opearation is unsuccesful, a message window pops up
#advising the user to change to a directory in which he/she has write
#permission.
    if { ![regexp -nocase windows $::tcl_platform(os)] } {
	if {![catch {open dirwrite.test w} errormessage]} {
	    file delete dirwrite.test
	} else {
	    .m configure \
		-type "1button" \
		-title "Startup Error" \
		-text "You do not have write permission for the directory from which you launched imosflm. \n Move to a directory for which you have write permission and relaunch imosflm" \
		-button1of1 "Exit"
	    if {[.m confirm]} {
		exit
	    } else {
		#I put in the exit command below in case the user clicks on the x button
		#at the top right of the message window rather than hitting the exit button
		exit
	    }
	}
    }

    # 30.03.2015 HRP: Change default to MOSFLM_EXEC not set, but allow developers to set 
    # it. From now, we will expect the mosflm exe to be in imosflm/bin, if it isn't there
    # it will be in $CBIN; if MOSFLM_EXEC is set, the old-style route will be followed. 
    # If MOSFLM_EXEC is not set and a Mosflm exe does not exist in either of those two 
    # places, pop-up to ask User to locate a usable exe.
    # Values for LMBNAMEFORMOSFLM and CCP4NAMEFORMOSFLM are in imosflm for Unix-type 
    # systems, top-level imosflm.tcl for Windows (and presumably CCP4 builds).


    if { $::env(RUNBYTOPLEVELIMOSFLMTCL) == "1" } {
	set toplevel [file dirname $::argv0]
    } else {
	set toplevel [file dirname [file dirname $::argv0]]
    }
    if {[info exists ::env(MOSFLM_EXEC)]} {
	if { [regexp -nocase windows $::tcl_platform(os)] } {
	    set l_executable [string map {"\\" "/"} $::env(MOSFLM_EXEC)]
	} else {
	    set l_executable $::env(MOSFLM_EXEC)
	}
    } else {
# default mosflm
	if { [file exists ${toplevel}/bin/$::env(LMBNAMEFORMOSFLM)] } {
	    set l_executable ${toplevel}/bin/$::env(LMBNAMEFORMOSFLM)
	    set ::env(MOSFLM_EXEC) $l_executable
	    set ::mosflm_executable $l_executable 
# default CCP4 ipmosflm
	} elseif {[file exists $::env(CBIN)/$::env(CCP4NAMEFORMOSFLM)]} {
	    set l_executable $::env(CBIN)/$::env(CCP4NAMEFORMOSFLM)
	    set ::env(MOSFLM_EXEC) $l_executable
	    set ::mosflm_executable $l_executable 
	} else {
# mosflm executable not found
	    set l_executable ""
	}
    }

    set l_valid_exe_found 0
    while {!$l_valid_exe_found} {
	# If an executable has been named...
	if {$l_executable != ""} {
	    # test the executable, by running it
	    if {![catch {exec $l_executable << exit 2>@1 } l_result]} {
		if { [regexp -nocase windows $::tcl_platform(os)] } {
		    set summary_filename [file join $::env(MOSDIR) "SUMMARY"]
		    #set summary_filename [list $summary_filename]
		    if {[file exists $summary_filename]} {
			file delete $summary_filename
		    }
		}
		# search output for correct version number
		set mos_req "ersion $::env(MOSFLM_VERSION_REQUIRED)"
		#puts "Mosflm exec is: $l_executable"
		if { [regexp "$mos_req" $l_result] } {
		    # XML output of image_template in bad_spots_response required 7.0.8
		    # but 7.0.8 bugfix release is now 7.0.9 & was released in May 2012
		    set ::mosflm_executable $l_executable
		    break
		} else {
		    set l_message ""
		    append l_message "$::env(IMOSFLM_VERSION)\n\n"
		    append l_message "\"$l_executable\" is not compatible.\n\n"
		    append l_message "Please configure iMosflm with the correct executable.\n\n"
		}
	    } else {
		set l_message ""
		append l_message "$::env(IMOSFLM_VERSION)\n\n"
		append l_message "iMosflm cannot run \"$l_executable\":\n\n"
		append l_message "$l_result\n\n"
                if {[regexp  "shared librar" $l_result]} {
		  append l_message "A shared library is either completely missing, or your system has a\n"
		  append l_message "different version.\n"
		  append l_message "Use the command: ldconfig -p \n"
		  append l_message "to find the directory for the shared libraries, grep the\n"
		  append l_message "output from ldconfig to find the required library, e.g.\n"
		  append l_message "ldconfig -p | grep libncurses\n"
		  append l_message "For example, if mosflm requires the library\n"
		  append l_message "libncurses.so.5 but your system only has libncurses.so.6.1\n"
		  append l_message "please add a soft link to the library on your system.\n"
		  append l_message "If the libraries are in /usr/lib64, the command would be:\n"
                  append l_message "sudo ln -s /usr/lib64/libncurses.so.6.1 /usr/lib64/libncurses.so.5\n"
                  append l_message "If a library is completely missing, see the Missing libraries\n"
                  append l_message "section in the CCP4 Known Issues web page for advice:\n"
                  append l_message "https://www.ccp4.ac.uk/download/doc/known_issues_linux.html\n"
                  append l_message "You may need to repeat this for other missing libraries\n"
                  append l_message "You will probably need administrator priviledges to create the\n"
                  append l_message "link, or add a new library\n"
                  append l_message "YOU SHOULD NOW EXIT THIS SESSION"
	        } else {
		  append l_message " Please report this error to mosflm@mrc-lmb.cam.ac.uk"
                }
	    }
	} else {
	    set l_message ""
	    append l_message "$::env(IMOSFLM_VERSION)\n\n"
	    append l_message "No mosflm executable has been found in \n\n"
	    append l_message "\t$toplevel/bin\n or \n"
	    append l_message "\t$::env(CBIN)\n and \n"
	    append l_message "\tMOSFLM_EXEC has not been set.\n\n"
	    append l_message "Please configure iMosflm with the correct executable.\n\n"
	    append l_message "(You can avoid having to configure iMosflm each time by\n"
	    append l_message "setting the full pathname of your mosflm executable in\n"
	    append l_message "the environment variable MOSFLM_EXEC.)"
	}
	# No executable found yet, so prompt user configuration
	.m configure \
            -title "Configure" \
            -type "2button" \
	    -text $l_message \
	    -button1of2 "Configure" \
	    -button2of2 "Exit"
	if {![.m confirm]} {
	    # User didn't want to configure, so quit
	    exit
	} else {
	    # Get executable file from user
	    if {![winfo exists .mosflmExecutable]} {
		Fileopen .mosflmExecutable \
		    -type open \
		    -initialdir [pwd] \
		    -filtertypes {{"All Files" {.*}}}
	    }
	    set l_executable [.mosflmExecutable get]
	}
    }
    # Create user profile
    set l_profile_file [file join $::mosflm_directory .profile]
    set user_profile [namespace current]::[UserProfile \#auto $l_profile_file]
    # Add recent sessions to session menu
    updateSessionMenu
    # Add batch destinations to batch dialogs
    .bcd initialize

    #puts "MOSFLMFILE environment variable is $::env(MOSFLMFILE)"
    if { [info exists ::env(MOSFLMFILE)] && $::env(MOSFLMFILE) == 1 } {
	set l_initfile 1
    } else {
	set l_initfile 0
    }

    #puts "MOSFLMSITE environment variable is $::env(MOSFLMSITE)"
    if { [info exists ::env(MOSFLMSITE)] && $::env(MOSFLMSITE) == 1 } {
	set l_sitefile 1
    } else {
	set l_sitefile 0
    }

    # Template file has been given on command line
    if { [info exists ::env(TEMPLATE)] && $::env(TEMPLATE) != "" } {
	#puts "TEMPLATE environment variable is $::env(TEMPLATE)"
	set image_file $::env(TEMPLATE)
    }

    # Single file has been given on command line
    if { [info exists ::env(SINGLE)] && $::env(SINGLE) != "" } {
	#puts "SINGLE environment variable is $::env(SINGLE)"
	set image_file $::env(SINGLE)
    }

    # If there was an existing .mosflm directory (then the cleanup flag will be set)
    if {($l_cleanup == 1)} {
	# check for spot files, and delete any found
	set l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- msf*.tmp]
	set l_spotfiles [concat $l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- *.spt]]
	set l_spotfiles [concat $l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- *.ssr]]
	set l_spotfiles [concat $l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- spt*.lst]]
	set l_spotfiles [concat $l_spotfiles [glob -nocomplain -directory $::mosflm_directory -- spt*.hdr]]
	foreach i_spotfile $l_spotfiles {
	    file delete -- $i_spotfile
	}
	# check for strategy files, and delete any found
	set l_strategyfiles [glob -nocomplain -directory $::mosflm_directory -- *.str]
	foreach i_strategyfile $l_strategyfiles {
	    file delete -- $i_strategyfile
	}
	# Check for 'unsaved' sessions
	set l_sessions [glob -nocomplain -directory $::mosflm_directory -- *.mpr]
	set l_num_sessions [llength $l_sessions]
	if {$l_num_sessions == 0} {
	    # No recoverable sessions, so make a new one
	    newSession $image_file
	} else {
	    # Offer user chance to recover previous unsaved work - do not
	    # do this if iMosflm started with --init 
	    set l_temp_file 0
	    if { $l_initfile == 0 } {
		set l_temp_file [.srd confirm]
	    }
	    if {$l_temp_file != "0"} {
		debug "Controller: Recovering saved session"
		openSessionFile $l_temp_file
	    } else {
		debug "Controller: Starting new session"
		newSession $image_file
	    }
	}
    } else {
	# No clean up required - just start new session
	newSession $image_file
    }
    if { $l_initfile } {
	#puts "Initializing from copy in $::mosflm_directory/initfile"
        $::session initializeFromFile "$::mosflm_directory/initfile"
    }
    if { $l_sitefile } {
	#puts "Setting parameters from $::mosflm_directory/sitefile"
        $::session readFromSiteFile "$::mosflm_directory/sitefile"
    }
}

body Controller::shutdown { } {
    # If there is a user profile, try and save it.
    if {$user_profile != ""} {
	if [catch {$user_profile serialize} error] {
	    puts "Failed to save iMosflm user profile: $error"
	}
    }
    # Close the session
    if {![closeSession]} {
	# If the user didn't cancel, exit
	exit
    }
}

body Controller::saveProfile { } {
    if {$user_profile != ""} {
	$user_profile queueSave
    }
}

########################################################################
# Interface configuration                                              #
########################################################################

body Controller::updateSessionMenu { } {

    # Remove recent session entries
    while {([$itk_component(sessionmenu) type end] == "separator") || ([$itk_component(sessionmenu) entrycget end -label] != "Exit")} {
	$itk_component(sessionmenu) delete end
    }

    # Get list of recent files
    set l_file_list [$user_profile getRecentSessions]

    # If there are any recent sessions...
    if {[llength $l_file_list] > 0} {

	# Add a separator
	$itk_component(sessionmenu) add separator

	set i_count 0
	# Loop through files...
	foreach i_file $l_file_list {
	    # ...adding command entries
	    $itk_component(sessionmenu) add command \
		-label "$i_count [::abbreviatePath $i_file 50]" \
		-underline 0 \
		-command [code $this openSession $i_file]
	    # If it's unix or linux, add an icon too
	    if {($::tcl_platform(os) != "Darwin") &&
		($::tcl_platform(os) != "Windows NT")} {
		$itk_component(sessionmenu) entryconfigure end \
		    -compound left \
		    -image ::img::mosflm_session_file16x16
	    }
	    incr i_count
	}
    }
}

body Controller::launch { } {
    if {$::debugging} {
        puts "flow: entering Controller::launch"
    } 
    # Launch images panel and toolbar
    grid $itk_component(main) -row 0 -column 1 -sticky  nswe
    pack $itk_component(images_toolbar) -side left
}

body Controller::hide { } {
    # Hide images panel and toolbar
    grid forget $itk_component(main)
    pack forget $itk_component(images_toolbar) 
}

body Controller::busy { { a_message "" } } {
    # Set activity indicator to busy (with tooltip message)
    $itk_component(activity_l) busy $a_message
    # Also display message in status bar
    if {$a_message != ""} {
	$itk_component(status_message) configure -text $a_message
    } else {
	$itk_component(status_message) configure -text "Icon still spinning? Click it to reset GUI"
    }
}

body Controller::errorMessage { { a_message "Error" } } {
    # Set activity indicator to "warning" (with tooltip message)
    $itk_component(activity_l) warn $a_message
    # Also set message in status bar
    $itk_component(status_message) configure -text $a_message
}

body Controller::pause { { a_message "Paused" } } {
    # Set activity indicator to "paused"
    $itk_component(activity_l) pause
    # Also set message in status bar
    $itk_component(status_message) configure -text $a_message
}

body Controller::progress { a_percent } {
    # Display the progress bar
    grid $itk_component(progress_bar)
    # Update the progress bar
    $itk_component(progress_bar) update [expr $a_percent / 100.0]
}

body Controller::idle { } {
    # Set the activity indicator to "idle"
    $itk_component(activity_l) idle
    # Remove progress bar
    grid remove $itk_component(progress_bar)
    # Set status message to "Done"
    $itk_component(status_message) configure -text "Done"
    # Schedule removal of "Done" message after 2.5 seconds
    set status_update_queue [after 2500 [code $this updateStatusMessage]]
}

body Controller::updateStatusMessage { { a_message "" } } {
    # Cancel any scheduled changes to the status bar message
    if {$status_update_queue != ""} {
	after cancel $status_update_queue
	set status_update_queue ""
    }
    # Put the message in the status bar
    $itk_component(status_message) configure -text $a_message
}

body Controller::setColourCode { col } {
    #puts "$col colour passed to $this"
    if { ($col != "") && ([lsearch -exact { red orange green } $col] >= 0)} {
	# Check legal colour
	$itk_component(colourcode) configure -background $col
	$itk_component(colourcode) configure -text [string toupper $col 0 0]
    }
}

body Controller::showStatusHelp { x y } {

    # Borrowed from Graph::showValueLabel
    set col [$itk_component(colourcode) cget -background]
    #puts "Status $col $x $y"

    if { $col == "red" } {
	set text "There are some significant problems with the processing.\n \
		  Please examine the warnings carefully."
    } elseif { $col == "orange" } {
	set text "There are some minor issues with the processing.\n \
		  Check the warnings to see if processing can be improved."
    } else {
	set text "There are no significant problems in processing."
    }

    set sl .status_label
    catch {destroy $sl}
    toplevel $sl
    # turning on the following with Boolean '1' means wm commands ignored
    wm overrideredirect $sl 1
    if {[tk windowingsystem] == "aqua"} {
	# If aqua on a Mac we dont want to see a sideTitleBar in the value popup
	::tk::unsupported::MacWindowStyle style $sl floating noTitleBar
    }
    label $sl.l \
	-text "$text"\
	-relief raised \
	-bd 2 \
	-bg white \
	-padx 2 \
	-pady 2
    pack $sl.l -fill both

    if {[expr $x + [winfo reqwidth $sl.l]] > [winfo screenwidth $sl.l]} {
	set x [expr [winfo screenwidth $sl.l] - [winfo reqwidth $sl.l] - 2]
    }
    if {[expr $y + [winfo reqheight $sl.l]] > [winfo screenheight $sl.l]} {
	set y [expr $y - 20 - [winfo reqheight $sl.l] - 2]
    }
    moveStatusHelp $x $y

}

body Controller::moveStatusHelp { x y } {
    catch {wm geometry .status_label "+[expr $x + 10]+[expr $y + 10]"}
}

body Controller::hideStatusHelp { } {
    catch {destroy .status_label}
}

body Controller::addWarning { a_warning } {
    $itk_component(warnings) addWarning $a_warning
}

body Controller::deleteWarning { a_warning } {
    if {$::session != ""} {
	$::session deleteWarning $a_warning
    }
}

body Controller::showAbout { } {
    # Show the "About" dialog
    .about show
}

body Controller::showWebpage { url } {
    # Open given URL
    # The following line within the [catch "..." message] always failed on Windows7
    # with the misleading Dismiss popup that it could not launch Internet Explorer
    if { [regexp -nocase windows $::tcl_platform(os)] } {
    # Also in pointlesswizard which does not seem to work with open_url
	exec [regsub -all \" $::env(CCP4_BROWSER) ""] $url &
    } else {
        open_url $url
    }
}

# disbaling and enabling ##################################

body Controller::disable { } {
    # disable tools and menus
    toggleState "disabled"
    # call disable for stages and image display
    foreach i_stage { indexing strategy cell_refinement integration } {
	$itk_component($i_stage) disable
    }
    .image disable
}

body Controller::enable { } {
    # enable tools and menus
    toggleState "normal"
    # call enable for stages and image display
    foreach i_stage { indexing strategy cell_refinement integration } {
	$itk_component($i_stage) enable
    }
    .image enable
}

body Controller::toggleState { a_state } { 
    # sets the state of all tools and menus

    # session menu
    $itk_component(menu) entryconfigure 0 -state $a_state

    # session toolbuttons
    $itk_component(new_tb) configure -state $a_state
    $itk_component(open_tb) configure -state $a_state
    $itk_component(save_tb) configure -state $a_state
    $itk_component(add_images_tb) configure -state $a_state
}   

# stages ##################################################

body Controller::showStage { a_stage } {
    if {$::debugging} {
        puts "flow: entering Controller::showStage for $a_stage" 
    }
    # Send focus to stages menu, to force SettingEntry update
    focus $itk_component(stages)

    # Restore current stage's icon to unselected state
    $itk_component(stages) itemconfigure box($current_stage) \
	-fill {} \
	-outline {}

    # hide current stage
    $itk_component($current_stage) hide

    # Store previous stage (in case of reversion)
    set previous_state $current_stage

    # update the record of current stage
    set current_stage $a_stage

    # Update new stage's icon
    $itk_component(stages) itemconfigure box($current_stage) \
	-fill "\#dcdcdc" \
	-outline "\#bbbbbb"

    # display the panel
    if {$::debugging} {
        puts "flow: exiting Controller::showStage for $a_stage by launching it"
    }

        #if {[$::session getIntegrationDone] != ""  } {
	#    if {[$::session getIntegrationDone] } {
        #        return
	#    }
        #}

    $itk_component($a_stage) launch

}

body Controller::disableStage { a_stage } {
    # disable stage icon in menu
    $itk_component(stages) itemconfigure icon($a_stage) \
	-image ::img::stage_${a_stage}_haze
    # grey out text
    $itk_component(stages) itemconfigure label($a_stage) \
	-fill "lightgrey"    
    # disable bindings
    $itk_component(stages) bind overlay($a_stage) <Enter> {}
    $itk_component(stages) bind overlay($a_stage) <Leave> {}
    $itk_component(stages) bind overlay($a_stage) <1> {}
}

body Controller::enableStage { a_stage } {
    # enable stage icon in menu
    $itk_component(stages) itemconfigure icon($a_stage) \
	-image ::img::stage_${a_stage}
    # colour text black
    $itk_component(stages) itemconfigure label($a_stage) \
	-fill "black"
    # set up bindings
	$itk_component(stages) bind overlay($a_stage) <Enter> \
	[code $this rollover $a_stage]
    $itk_component(stages) bind overlay($a_stage) <Leave> \
	[code $this rolloutof $a_stage]
    $itk_component(stages) bind overlay($a_stage) <1> \
	[code $this showStage $a_stage]
}

body Controller::rollover { a_stage } {
    # Shades stage button (if not already current stage or disabled)
    if {$a_stage != $current_stage} {
	if {[$itk_component(stages) itemcget icon($a_stage) -image] != "::img::stage_${a_stage}_haze"} {
	    $itk_component(stages) itemconfigure box($a_stage) \
		-fill "\#eeeeee" \
		-outline "\#dcdcdc"
	}
    }
}

body Controller::rolloutof { a_stage } {
    # Undshades stage button (if not already current stage or disabled)
    if {$a_stage != $current_stage} {
	if {[$itk_component(stages) itemcget icon($a_stage) -image] != "::img::stage_${a_stage}_haze"} {
	    $itk_component(stages) itemconfigure box($a_stage) \
		-fill {} \
		-outline {}
	}
    }
}


# Methods to show various dialogs

body Controller::showIndexSettings { } {
    .ais show
}

body Controller::showIntegrationSettings { } {
    .is show
}

body Controller::showHistory { } {
    .hv show
}

body Controller::showExperimentSettings { } {
    .ass show
}

# Methods to enable levels of processing

body Controller::enableIndexing { } {
    enableStage "indexing"
}

body Controller::disableIndexing { } {
    disableStage "indexing"
}

body Controller::enableProcessing { } {
    enableStage strategy
    enableStage cell_refinement
    enableStage integration
}

body Controller::disableProcessing { } {
    disableStage strategy
    disableStage cell_refinement
    disableStage integration
}

########################################################################
# Session configuration                                                #
########################################################################

body Controller::getSiteFile { mode } {

    if { ($mode == "open") && [$::session getSiteFileRead] != "" } {
	.m configure \
	    -title "Site file warning" \
	    -type "2button" \
	    -text "A site configuration file has already been read.\nDo you really wish to read another file now?" \
	    -button1of2 "Ok" \
	    -button2of2 "Cancel"

	if {![.m confirm]} {
	    # User didn't want to read another site file
	    return
	} else {
	    $::session clearInSiteFile
	}
    }

    if { ($mode == "save") && [$::session getSiteFileWritten] != "" } {
	.m configure \
	    -title "Site file warning" \
	    -type "2button" \
	    -text "A site configuration file has already been saved.\nDo you really wish to save another file now?" \
	    -button1of2 "Ok" \
	    -button2of2 "Cancel"

	if {![.m confirm]} {
	    # User didn't want to read another site file
	    return
	}
    }

    # Use normal File $mode dialog
    set initial_dir [pwd]
    if {![winfo exists .${mode}SiteFile]} {
	Fileopen .${mode}SiteFile \
	    -title "Site file to $mode" \
	    -type $mode \
	    -initialdir $initial_dir \
	    -filtertypes {{"All Files" {.*}}}
    }
    # get a filename and location (as full path) from the user
    set l_site_file [.${mode}SiteFile get]
    if {$l_site_file != ""} {
	set full_path [file join [file dirname $l_site_file] [file tail $l_site_file]]
	puts "Site file to $mode is $full_path"
	if { $mode == "save" } {
	    writeSiteFile $full_path
	} elseif { $mode == "open" } {
	    readSiteFile $full_path
	} else {
	    puts "Bad mode sent to $this: $mode"
	}
    }
}

body Controller::readSiteFile { file } {
    set l_in_file [open $file r]
    while {![eof $l_in_file]} {
	set line [gets $l_in_file]
	parseSiteFile $line $file
    }
    close $l_in_file
}

body Controller::parseSiteFile { line file } {
    #puts $line
    #puts "Parsing the site file"
    set good 0
    if { [string trim $line] == "" } { return } ; # blank
    #set l_args [split $line]
    set l_args [split [regsub -all {[ \t\n]+} $line { }]] ; # Get rid of any extra white spaces AGWL
    set n_args [llength $l_args]
    #puts "n_args is: $n_args" ; #AGWL
    if { $n_args < 2 } { return } ; # one item only
    set keyw [string tolower [lindex $l_args 0]]
    set val1 [string tolower [lindex $l_args 1]]
    
    if { ($keyw == "wavelength") || ($keyw == "dispersion") || ($keyw == "distance") || ($keyw == "gain") \
          || ($keyw == "adcoffset") || ($keyw == "nullpix") } {
	# Expect one value
	if { [string is double -strict $val1] } {
	    $::session updateSetting "$keyw" $val1 "1" "1" "User"
            #puts "updating $keyw with value $val1"
	    set good 2 ; # $keyw $val
	} else {
	    puts "Unknown value or subkeyword found in site file for $keyw: $val1"
	}
    } elseif { $keyw == "distortion" } {
	# Expect subkeyword and one value
	if { ($val1 == "tilt") || ($val1 == "twist") } {
	    set val2 [string tolower [lindex $l_args 2]]
	    if { [string is double -strict $val2] } {
		$::session updateSetting "$val1" $val2 "1" "1" "User"
		set good 3 ; # $keyw $subk $val
		$::session setInSiteFile $val1 $val2
	    } else {
		puts "Unknown value found in site file for $keyw $val1: $val2"
	    }
	} else {
	    puts "Unknown value or subkeyword found in site file for $keyw: $val1"
	}
    } elseif { ($keyw == "beam") || ($keyw == "divergence") } {
	# Expect two values
	if { [string is double -strict $val1] } {
	    set val2 [string tolower [lindex $l_args 2]]
	    if { [string is double -strict $val2] } {
		$::session updateSetting "[subst $keyw]_x" $val1 "1" "1" "User"
		$::session updateSetting "[subst $keyw]_y" $val2 "1" "1" "User"
		set good 3 ; # $keyw $val1 $val2
		$::session setInSiteFile [subst $keyw]_x $val1
		$::session setInSiteFile [subst $keyw]_y $val2
	    } else {
		puts "Unknown value found in site file for $keyw: $val2"
	    }
	} else {
	    puts "Unknown value found in site file for $keyw: $val1"
	}
    } elseif { ($keyw == "pixel") } {
	# Expect one value
	if { [string is double -strict $val1] } {
		$::session updateSetting "[subst $keyw]_size" $val1 "1" "1" "User"
		set good 2 ; # $keyw $val1 
		$::session setInSiteFile [subst $keyw]_size $val1
	} else {
	    puts "Unknown value found in site file for $keyw: $val1"
	}
    } elseif { ($keyw == "detector") } {
	# Expect subkeyword and one value
	if { ($val1 == "omega") } {
	    set val2 [string tolower [lindex $l_args 2]]
	    if { [string is double -strict $val2] } {
		$::session updateSetting "[subst $keyw]_[subst $val1]" $val2 "1" "1" "User"
		set good 3 ; # $keyw $val1 $val2
		$::session setInSiteFile [subst $keyw]_[subst $val1] $val2
	    } else {
		puts "Unknown value found in site file for $keyw $val1: $val2"
	    }
	} elseif { ($val1 == "rowreadt") } {
	    set val2 [string tolower [lindex $l_args 2]]
	    if { [string is double -strict $val2] } {
		$::session updateSetting "[subst $keyw]_[subst $val1]" $val2 "1" "1" "User"
		set good 3 ; # $keyw $val1 $val2
		$::session setInSiteFile [subst $keyw]_[subst $val1] $val2
	    } else {
		puts "Unknown value found in site file for $keyw $val1: $val2"
	    }
	} elseif { ($val1 == "rotnspeed") } {
	    set val2 [string tolower [lindex $l_args 2]]
	    if { [string is double -strict $val2] } {
		$::session updateSetting "[subst $keyw]_[subst $val1]" $val2 "1" "1" "User"
		set good 3 ; # $keyw $val1 $val2
		$::session setInSiteFile [subst $keyw]_[subst $val1] $val2
	    } else {
		puts "Unknown value found in site file for $keyw $val1: $val2"
	    }
	} elseif { ($val1 == "reversephi") } {
	# Expect subkeyword only
	    $::mosflm sendCommand "$keyw $val1"
	    set good 1 ; # $keyw $subk
	    $::session setInSiteFile reverse_phi on
	    puts "reverse phi flag set"
	} else {
	    puts "Unknown subkeyword found in site file for $keyw: $val1"
	}
    } elseif { ($keyw == "polarisation") || ($keyw == "polarization") } {
	# Expect subkeyword and one value
	if { ($val1 == "synchrotron") ||($val1 == "electron") ||($val1 == "microed") ||($val1 == "electrons")  } {
	    set val2 [string tolower [lindex $l_args 2]]
	    if { [string is double -strict $val2] } {
		$::session updateSetting "polarization" $val2 "1" "1" "Images"
		set good 3 ; # $keyw $subk $val
		$::session setInSiteFile polarization $val2
	    } else {
		puts "Unknown value found in site file for $keyw $val1: $val2"
	    }
	} else {
	    # Expect subkeyword only
	    # Check allowed subkeywords
	    if { ![lsearch -exact { pinhole  mirrors  monochromator } $val1]} {
		set good 2 ; # $keyw $subk
	    } else {
		puts "Unknown subkeyword found in site file for $keyw: $val1"
	    }
	}
    } else {
	puts "Unknown keyword found in site file: $keyw"
    }
    if { $good >= 1 } {
	# Got n good components from this line
	#puts "Read from site file OK: [join [lrange $l_args 0 [expr {$good - 1}]] " "]"
	$::session setSiteFileRead $file
	if { $good == 2 } {
	    # Simple $keyw $val
            # Already done for pixel as variable is pixel_size not pixel
	    if { $keyw != "pixel" } {
               $::session setInSiteFile $keyw $val1
            }
	}
    }
}

body Controller::writeSiteFile { file } {

    set l_out_file [open $file w]

    #WAVELENGTH <x>
    puts $l_out_file "wavelength [$::session getWavelength]"
    # Test to see if getParameterValue also works .. it does, comment out now
    #puts $l_out_file "wavelength_param_value [$::session getParameterValue wavelength]"

    #DISPERSION <x>
    puts $l_out_file "dispersion [$::session getParameterValue dispersion]"

    #POLARISATION [PINHOLE | MIRRORS | MONOCHROMATOR | SYNCHROTRON <x>]
    if {[$::session getParameterValue "xray_source"] == "lab"} {
	puts $l_out_file "polarisation pinhole"
    } else {
	puts $l_out_file "polarisation synchrotron [$::session getParameterValue "polarization"]"
    }

    #DIVERGENCE <xh [xv]>
    puts $l_out_file "divergence [$::session getParameterValue divergence_x] [$::session getParameterValue divergence_y]"

    #BEAM <nimage> [SWUNG_OUT] <beamx> <beamy>
    if {![$::session getTwoTheta]} {
	puts $l_out_file "beam [$::session getBeamPosition]"
    } else {
	puts $l_out_file "beam swungout [$::session getBeamPosition]"
    }

    #DISTANCE <x>
    puts $l_out_file "distance [$::session getDistance]"
    # Test to see if getParameterValue also works .. it does, comment out now
    #puts $l_out_file "distance_param_value [$::session getParameterValue distance]"

    #DISTORTION TILT <x>
    puts $l_out_file "distortion tilt [$::session getParameterValue tilt]"

    #DISTORTION TWIST <x>
    puts $l_out_file "distortion twist [$::session getParameterValue twist]"
    
    #GAIN <x>
    puts $l_out_file "gain [$::session getParameterValue gain]"
    
    #DETECTOR REVERSEPHI
    if { [$::session getReversePhi] } {
	puts $l_out_file "detector reversephi"
    }

    #DETECTOR OMEGA <x>
    if { [$::session getDetectorOmega] != "" } {
	puts $l_out_file "detector omega [$::session getDetectorOmega]"
    }

    #ADCOFFSET <x>
    if { [$::session getParameterValue "adcoffset"]  != "" } {
	puts $l_out_file "adcoffset [$::session getParameterValue "adcoffset"]"
    }

    #PIXEL <x>
    if { [$::session getParameterValue "pixel_size"]  != "" } {
	puts $l_out_file "pixel [$::session getParameterValue "pixel_size"]"
    }

    #NULLPIX <x>
    if { [$::session getParameterValue "nullpix"]  != "" } {
	puts $l_out_file "nullpix [$::session getParameterValue "nullpix"]"
    }

    close $l_out_file
    $::session setSiteFileWritten $file
}

body Controller::addImages { } {
    # Create image-file selection dialog, if not yet created.
    
    if { [info exists ::env(IMAGEDIR)] && $::env(IMAGEDIR) != "" } {
	set initial_dir $::env(IMAGEDIR)
	unset ::env(IMAGEDIR)
    } else {
	set initial_dir [pwd]
    }
    # In filtertypes below, remove .nxs from list of "Image files" (was ..._master.h5 .nxs)
    # and also from "HDF5" (was _master.h5 .nxs)
    if {![winfo exists .addImages]} {
	Fileopen .addImages \
	    -title "Add images" \
	    -type image_open \
	    -initialdir $initial_dir \
	    -filtertypes {{"Image files" {.img .mar* .mccd .osc .SFRM .sfrm .image .ipf .cbf .pck _master.h5}} {"ADSC" {.img}} {"Bruker" {.SFRM .sfrm}} {"Mar" {.mar* .mccd .image}} {"Oxford" {.img .pck}} {"Rigaku" {.osc .img}} {"DIP" {.ipf}} {"imgCIF/CBF" {.cbf}}  {"HDF5" {_master.h5}}  {"Numbered files" {*\.[0-9]+}} {"All Files" {.*}}}
raise .addImages
    }
    # get a filename and location (as full path) from the user
    set l_image_file [.addImages get]
    #puts "addImages get: $l_image_file"
    # If the user picked one or more files
    if {$l_image_file != ""} {
	# add image(s) to the current session
	#puts "File dir  gives: [file dirname $l_image_file]"
	#puts "File tail gives: [file tail $l_image_file]"
	# can be a full path to a single file or be followed a list of image filenames
	set listofimages [file tail $l_image_file]
	# set first image to be head of the sorted list
	set first_image [file join [file dirname $l_image_file] [lindex $listofimages 0]]
	#puts "first_image $l_image_file"
	# check for >1 images in the list without 'Select images' box checked
	#puts "Number in list of files: [llength $listofimages]"
	#puts "First in list of images: $first_image"
	if {[llength $listofimages] > 1 } {
	    
            if { [winfo exists .addImages] } {
                if { [.addImages getSelectedImages] == 1 } {
                    $::session writeImageList [ lrange $listofimages 1 end ]
                }
            } else {
		set listofimages $first_image
	    }
	}
	# if it's an HDF5 file
	if { [regexp -- {^(.*?)(_master.h5)$} $l_image_file match] } {
#            puts "crucial: ***** its an HDF5 file, name $l_image_file"
            $::session setHdf5 $l_image_file
	    set ::env(HDF5file) 1
	}
	# load the first one
	$::session addImage $first_image
    }
}

body Controller::addSpots { } {

    # Only permit if some images have been loaded
    if { [llength [$::session getImages]] < 1 } {
	.m confirm \
	    -type "1button" \
	    -title "No Images Found" \
	    -text "Please load some images before attempting to read a spots file." \
	    -button1of1 "Dismiss"
	return
    }

    # Use normal File open dialog
    set initial_dir [pwd]
    if {![winfo exists .addSpots]} {
	Fileopen .addSpots \
	    -title "Read spots file" \
	    -type open \
	    -initialdir $initial_dir \
	    -filtertypes {{"Spot files" {.spt}} {"All Files" {.*}}}
    }
    # get a filename and location (as full path) from the user
    set l_spots_file [.addSpots get]
    #puts "addSpots get: $l_spot_file"
    # If the user picked one or more files - not doing this yet ...
    if {$l_spots_file != ""} {
	## add spot file(s) to the current session
	#puts "File dir  gives: [file dirname $l_spots_file]"
	#puts "File tail gives: [file tail $l_spots_file]"
	## can be a full path to a single file or be followed by a list of file names
	#set listofspotfiles [file tail $l_spots_file]
	## set first spots file to be head of the sorted list
	set full_path [file join [file dirname $l_spots_file] [file tail $l_spots_file]]
	##puts "first_spots_file $l_spots_file"
	## check for >1 spots files in the list without 'Select spots files' box checked
	##puts "Number in list of files: [llength $listofspotfiles]"
	##puts "First in list of spots files: $first_spot_file"
	#if {[llength $listofspotfiles] > 1 } {
	#    if { [.addSpots getSelectedImages] == 0 } {
	#	set listofimages $first_image
	#    } else {
	#	# save list
	#	$::session writeImageList [ lrange $listofspotfiles 1 end ]
	#    }
	#}

	# Move main window to the Indexing pane
        if {$::debugging} {
            puts "flow: Moving to Indexing pane"
        }
	.c showStage indexing
	# File may contain spots from > 1 image so extract these
	[.c component indexing] processSpotsFile $full_path
    }
}

body Controller::saveSpots { } {

    # Only permit if some images have been loaded
    if { [llength [$::session getImages]] < 1 } {
	.m confirm \
	    -type "1button" \
	    -title "No Images Found" \
	    -text "Please load some images before attempting to save a spots file." \
	    -button1of1 "Dismiss"
	return
    }

    # Use normal File open dialog
    set initial_dir [pwd]
    if {![winfo exists .saveSpots]} {
	Fileopen .saveSpots \
	    -title "Save spots file" \
	    -type save \
	    -initialdir $initial_dir \
	    -filtertypes {{"Spot files" {.spt}} {"All Files" {.*}}}
    }
    # get a filename and location (as full path) from the user
    set l_spots_file [.saveSpots get]
    #puts "addSpots get: $l_spot_file"
    # If the user picked one or more files - not doing this yet ...
    if {$l_spots_file != ""} {
	set full_path [file join [file dirname $l_spots_file] [file tail $l_spots_file]]
	# Move main window to the Indexing pane
	.c showStage indexing
	# File may contain spots from > 1 image so extract these
	#puts "Want to save spots to $full_path"
	[.c component indexing] writeSpotsFile $full_path
    }
}

body Controller::saveSessionAs { } {
    # Create save session dialgo if necessary
    if {![winfo exists .saveSession]} {
	Fileopen .saveSession  \
	    -title "Save session as" \
	    -type save \
	    -initialdir [pwd] \
	    -filtertypes {{"Mosflm sessions" {.mos}} {"All Files" {.*}}}
    }
    # Get the user to pick a new filename and location (as full path)
    set l_session_file [.saveSession get]
    # If the user picked a file
    if {$l_session_file != ""} {
	#puts "sSA: session_file [$::session getFilename]"
	# If the session has not previously been saved to a named file get the name
	#  of the temporary file in which it is stored
	if {[$::session isSaved] == ""} {
	    set l_temporary_file [$::session getFilename]
	} else {
	    set l_temporary_file ""
	}
	#puts "sSA: l_temporary_file $l_temporary_file"
	# Save the session as new file chosen by user
	if {[$::session writeToFile $l_session_file "1"]} {
	    # non-zero return value indicates error!
	    # return error code
	    return 2
	}
	# Why would you delete the $l_temporary_file here!?
	# Append file to recent session list and update the session menu
	$user_profile addRecentSession $l_session_file
	updateSessionMenu
	# success: return zero
	return 0
    } else {
	# return cancellation code  
	return 1
    }
}

body Controller::saveSession { } {
    # See if the session has already been saved in a named file
    if {[$::session isSaved] != "" } {
	# Save it again to that file
	set result [$::session writeToFile [$::session isSaved]]
    } else {
	# Do a 'Save as'
	set result [saveSessionAs]
    }
    #puts "saveSession: result is $result"
    return $result
}


body Controller::promptSaving { } {
    # If the session has been saved, or nothing has happened in it,
    #  report success
    if {([$::session isSaved] != "") || (![$::session hasHistoryEvents])} {
	set result 0
    } else {
	# Ask user if they want to save the session
	set l_save_choice [.psd confirm -title "Save session" -text "Save session before closing?"]
	if {$l_save_choice == "Cancel"} {
	    # return cancellation code
	    set result 1
	} elseif {$l_save_choice == "Yes"} {
	    # Save the session
	    set result [saveSession]	    
	} elseif {$l_save_choice == "No"} {
	    set result 0
	} else {
	    error "Prompt save dialog returned invalid code: $l_save_choice"
	}
    }
    return $result
}

body Controller::openSession { { a_file "" } } {
    # if there is a session open, prompt saving
    if {$::session != ""} {
	set l_save_result [promptSaving]
    } else {
	set l_save_result 0
    }
    # if the user didn't cancel...
    if {$l_save_result == 0} {
	# if no file was provided, pick a file to open
	if {$a_file == ""} {
	    # If necessary create the "Open project" dialog
	    if {![winfo exists .openSession]} {
		Fileopen .openSession \
		    -title "Open previously saved session" \
		    -type open \
		    -initialdir [pwd] \
		    -filtertypes {{"Mosflm sessions" {.mos}} {"All Files" {.*}}}
	    }
	    # Get file name (as full path) from user
	    # check it's a session file, if not - return now!

	    set l_session_file [.openSession get]
	    set in_file [open $l_session_file r]
	    set checkXML [read $in_file 5]
	    if { $checkXML != "<?xml" } {
		# if it isn't a session file, suggest the user might want to add images
		.m configure \
		    -type "2button" \
		    -title "File is not a saved session file" \
		    -text "[file tail $l_session_file] is not a session file; if you are trying to \nstart processing, you should use the \n\"Add images\" button\n\nDo you want to add images?" \
		    -button1of2 "Yes" \
		    -button2of2 "No"
		set l_session_file ""
		if {[.m confirm]} {
		    $this addImages
		    set result -1
		} {
		    set result 0
		}
	    }
	    close $in_file
	    #puts "openSession get: $l_session_file"
	} else {
	    set l_session_file $a_file
	}
	# If the user picked a file
	if {$l_session_file != ""} {
	    # Close the session
	    closeSession
	    # Create a new session from the chosen file
#	    puts "trying to openSessionFile $l_session_file"
	    set result [openSessionFile $l_session_file]
	    if { $result == -1 } {
		set result [$this addImages]
		return $result
	    }
	} else {
	    # if the user didn't pick a session, report cancellation.
	    set result 1
	}
    } else {
	set result 1
    }
    return $result
}
    
body Controller::closeSession { } {    
    # Close the image display
    .image closeImage

    # clear the stage panels
    foreach i_stage { indexing strategy cell_refinement integration} {
	$itk_component($i_stage) clear
    }

    # clear the status_bar
    $itk_component(warnings) clear

    # Disable stages
    foreach i_stage { indexing strategy cell_refinement integration } {
	disableStage $i_stage
    }

    # Show images stage
    showStage hull

    # Delete the session object (session will delete own file if temporary)
    if {$::session != ""} {
	delete object $::session
    }

    # Wipe the session pointer
    set ::session ""

    # Disable the controls and canvases
    $itk_component(session_tree) configure -background "\#dcdcdc"

    return 0
}

body Controller::newSession { { a_image_file "" } } {
    if {$::debugging} {
        puts "flow: entering Controller::newSession, current session is: $::session"
    }
    # if there is a session open, prompt saving
    
    if {$::session != ""} {

        if {$::debugging} {
            puts "flow: about to update ccp4_bin to [$::session getParameterValue ccp4_bin]"
        }

	$::session updateSetting ccp4_bin [file normalize [$::session getParameterValue ccp4_bin]] 0 0 "Processing_options"
        if {$::debugging} {
            # When debugging on Windows, cannot redirect stdout, so send puts output to a file
            # This debug to recognise that env(CBIN) can exist but is actually null .. see below
           set l_filename "debug_controller.log"
           set l_file [open $l_filename w]
           puts $l_file "In controller about to set env(CBIN) to: [$::session getParameterValue ccp4_bin]"
        }
	set ::env(CBIN) [$::session getParameterValue ccp4_bin]
        if {$::debugging} {
           puts $l_file "info exists env(CBIN) is: [info exists ::env(CBIN)]"
           flush $l_file
           close $l_file
        }

	set ::env(CCP4_BROWSER) [$::session getParameterValue web_browser]

	$::session updateSetting mosflm_exec [file normalize [$::session getParameterValue mosflm_exec]] 0 0 "Processing_options"
	set ::env(MOSFLM_EXEC) [$::session getParameterValue mosflm_exec]

	$::session updateSetting mosdir [file normalize [$::session getParameterValue mosdir]] 0 0 "Processing_options"
	set ::env(MOSDIR) [$::session getParameterValue mosdir]

	set ::env(MOSFLM_LOGGING) [$::session getParameterValue mosflm_logging]
	debug "Controller: Prompting saving of existing session"
	set l_save_result [promptSaving]
    } else {
	set l_save_result 0
    }
    #puts "newSession: l_save_result $l_save_result"
    # if the user didn't cancel, close the current session and make a new one
    if {$l_save_result == 0} {
	# close any current sessoin
	debug "Controller: Closing any existing session"
	closeSession

	debug "Controller: Creating new session object"
 	# create a new session with that file
 	set ::session [namespace current]::[Session \#auto -name "New session"]

	# Create random temporary file for new session 
	$::session createTempFile

	# open randomly named temporary strategy file
	openTempStrategyFile
	#puts "Temporary strategy file [getTempStrFilename]"
    
	# Colour the session tree background white
	$itk_component(session_tree) configure -background "white"
	# if there was an image file to be opened...
	if {$a_image_file != ""} {
	    if { [info exists ::env(TEMPLATE)] && $::env(TEMPLATE) != "" } {
		# Set flag to allow addition of all files matching this template
		$::session setMultipleImageFiles 1
	    }
	    if { [info exists ::env(SINGLE)] && $::env(SINGLE) != "" } {
		# Set flag to allow addition of single image file
		$::session setSingleImageFile 1
	    }
	    # Create image object and query mosflm for header information
	    $::session addImage $a_image_file
	}
	# display the session
	debug "Controller: Displaying session"
	displaySession
	# Update all the dialogs
	debug "Controller: Updating interface"
	SettingWidget::refreshAll
	# Clear any prior cell set for indexing
	if {[winfo exists .priorCell]} {
	    #puts "Here trying to clear .priorCell and set to zero"
	    .priorCell clear
	}
	# Unset find multiple lattices
	$::session setMultipleLattices 0
	# Reset any Multiple and Cell labels left following Index on the Index button
	catch {[.c component indexing] setPriorCell}
#	puts "resetting toggleMultipleLattices"
#	catch {[.c component indexing] toggleMultipleLattices 0}
	update

	# set result to indicate success
	debug "Controller: Session successfully created"
	# Green light for Go
	setColourCode green
	set result 0
    } else {
	debug "Controller: Session creation aborted"
	# set result to indicate result of saving existing session
	set result $l_save_result
    }
    #puts "newSession: returns result $result"
    return $result
}

body Controller::openSessionFile { a_file } {
    # Create a new session
    set ::session [namespace current]::[Session \#auto]
    # If successful, display the new session
    displaySession
    # Colour the canvases white
    $itk_component(session_tree) configure -background "white"
    # Try and initialize the new session with information from the file...
    if {[$::session initializeFromFile $a_file]} {
	# Refresh dialogs
	SettingWidget::refreshAll
	# Enable controls as appropriate
	if {[$::session getImages] != {}} {
	    enableIndexing
	}
	if {[$::session MatrixIsSet]} {
	    enableProcessing
	}
	# Update recent session files
	$user_profile addRecentSession $a_file
	updateSessionMenu
	return 0
    } else {
	# If unsuccessful, report failure.
	.m confirm \
	    -type "1button" \
	    -title "Failed to open session" \
	    -button1of1 "Dismiss" \
	    -text "Could not read session from file\n$a_file"
	return 1
    }
}

body Controller::openTempStrategyFile { } {

# Open randomly named temporary strategy file
    expr srand([clock clicks])
    set file_creation_incomplete 1
    set file_creation_attempts 0
    while {$file_creation_incomplete} {
	if {$file_creation_attempts > 50} {
	    .m confirm \
		-type "1button" \
		-title "Error" \
		-text "Could not create strategy file:\n$out_file" \
		-button1of1 "Dismiss"
	    return 0
	}
	set temp_strategy_file [file join $::mosflm_directory "msf[expr int(rand()*99999)].str"]
	set file_creation_incomplete [catch {open $temp_strategy_file {WRONLY CREAT EXCL}} out_file]
	incr file_creation_attempts
    }
# close file
    close $out_file
    return $temp_strategy_file
}

body Controller::existsTempStrFilename { } {
    return $haveTempStrategyfile
}

body Controller::wroteTempStrFile { } {
    set haveTempStrategyfile 1
}

body Controller::getTempStrFilename { } {
    return $temp_strategy_file
}

########################################################################
# Button callbacks                                                     #
########################################################################

body Controller::estimateMosaicity { } {
    # call session's estimate mosaicity method
    $::session estimateMosaicity
}


# Session tree methods ##################################################

body Controller::displaySession { } {

    # clear any existing session tree
    $itk_component(session_tree) item delete all
    
    # clear arrays mapping tree items
    array unset session_items_by_object *
    array unset session_obects_by_item *

    # create cell
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Lattice [$::session getCurrentLattice]" 1 "[[$::session getCell] reportCell]" 2 "1"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::cell
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object([$::session getCell]) $l_item
    set session_objects_by_item($l_item) [$::session getCell]

    # create spacegroup
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Spacegroup" 1 "[[$::session getSpacegroup] reportSpacegroup]" 2 "2"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::spacegroup
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object([$::session getSpacegroup]) $l_item
    set session_objects_by_item($l_item) [$::session getSpacegroup]

    # create mosaicity
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Mosaicity" 1 "[$::session getMosaicity]" 2 "3"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::mosaicity
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object(mosaicity) $l_item
    set session_objects_by_item($l_item) [namespace current]::[SessionParameter \#auto "mosaicity"]

    # create mosaic block size
    set l_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_item 0 s1 1 s3 2 s2
    $itk_component(session_tree) item text $l_item 0 "Mosaic block size" 1 "100" 2 "3"
    $itk_component(session_tree) item element configure $l_item 0 e_icon -image ::img::mosaicblock
    $itk_component(session_tree) item lastchild root $l_item
    set session_items_by_object(mosaicblock) $l_item
    set session_objects_by_item($l_item) [namespace current]::[SessionParameter \#auto "mosaicblock"]

    # Add sectors
    foreach i_sector [$::session getSectors] {
	addSector $i_sector
	foreach i_image [$i_sector getImages] {
	    addImage $i_sector $i_image
	}
    }
}

body Controller::addSector { a_sector } {
    # Create sector item
    #puts "addSector $a_sector"
    set l_sector_item [$itk_component(session_tree) item create -button 1]
    $itk_component(session_tree) item style set $l_sector_item 0 s1 1 s2 2 s2
    foreach { l_phi_start l_phi_end } [$a_sector getPhi] break
    $itk_component(session_tree) item text $l_sector_item 0 "Sector [$a_sector getTemplateForMosflm]" 1 "\u03c6:$l_phi_start->$l_phi_end" 2 "[$a_sector getTemplate]"
    $itk_component(session_tree) item element configure $l_sector_item 0 e_icon -image ::img::dataset
    $itk_component(session_tree) item lastchild root $l_sector_item
    set session_items_by_object($a_sector) $l_sector_item
    set session_objects_by_item($l_sector_item) $a_sector

    # Create matrix item
    set l_matrix_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_matrix_item 0 s1 1 s2 2 s2
    $itk_component(session_tree) item text $l_matrix_item 0 "Matrix" 1 "[[$a_sector getMatrix] getName]" 2 "0"
    $itk_component(session_tree) item element configure $l_matrix_item 0 e_icon -image ::img::orientation
    $itk_component(session_tree) item lastchild $l_sector_item $l_matrix_item
    set session_items_by_object([$a_sector getMatrix]) $l_matrix_item
    #puts "Setting session_items_by_object([$a_sector getMatrix]) $l_matrix_item matrix name [[$a_sector getMatrix] getName]"
    set session_objects_by_item($l_matrix_item) [$a_sector getMatrix]

    # update other user interface components
    [$itk_component(indexing) component image_numbers] addSector $a_sector
    [$itk_component(cell_refinement) component image_numbers] addSector $a_sector
    [$itk_component(integration) component image_numbers] addSector $a_sector
}

body Controller::addImage { a_sector a_image args } {
    if {$::debugging} {
        puts "flow: in Controller::addImage a_sector $a_sector a_image $a_image"
    }
    options {-sort 1} $args
    # adds image to treectrl
    # create image item
    set l_image_item [$itk_component(session_tree) item create]
    $itk_component(session_tree) item style set $l_image_item 0 s1 1 s3 2 s2
    foreach { l_phi_start l_phi_end } [$a_image getPhi] break
    if {$::debugging} {
        puts "flow: in Controller::addImage l_phi_start $l_phi_start l_phi_end $l_phi_end"
    }
    $itk_component(session_tree) item text $l_image_item 0 "Image [$a_image getNumber]" 1 "[$a_image reportPhis]" 2 "[$a_image getNumber]"
    # add image item to sector item
    $itk_component(session_tree) item lastchild $session_items_by_object($a_sector) $l_image_item
    if {$options(-sort)} {
	# sort sector item's image items
	$itk_component(session_tree) item sort $session_items_by_object($a_sector) -column order_column -dictionary
	# update the sector (phi range)
	updateSector [$a_image getSector]
    }
    # keep record of which item belongs to which image object
    set session_items_by_object($a_image) $l_image_item
    set session_objects_by_item($l_image_item) $a_image
    if {$::debugging} {
    puts "Item $session_items_by_object($a_image) is $session_objects_by_item($l_image_item)"
    }
    if {[$a_image getNumber] == "0"} {
	# Flag the line in Images pane
	flagImage 0
	# Add warning to the box
	$::session generateWarning "You have added an image file with an index of zero. The batch number offset has been automatically set to a value of 1000" -reason "Images"
	$::session updateSetting "batch_number" 1000 "1" "1" "Images"
    } else {
	$itk_component(session_tree) item element configure $l_image_item 0 e_icon -image ::img::image
	# Update status message - good for thousands of images!
	$itk_component(status_message) configure -text "Added image [$a_image getNumber]"
	#puts "Image [$a_image getNumber] phi start: $l_phi_start - phi end: $l_phi_end"		    
    }
}

body Controller::flagImage { number } {
    set l_image [$::session getImageByNumber $number]
    set l_image_item $session_items_by_object($l_image)
    $itk_component(session_tree) item element configure $l_image_item 0 e_icon -image ::img::status_warning_on16x16
}

body Controller::deleteImagesFromSector { } {
# hrp 24052018 new for deleting current images when chunking
#    puts "body Controller::deleteImagesFromSector"
    set current_sector $session_items_by_object([$::session getCurrentSector])
    # puts "body Controller::deleteImagesFromSector - current sector is $current_sector"
#    puts "body Controller::deleteImagesFromSector - sectors are [$::session getSectors]"
    foreach i_sector [$::session getSectors] {
	foreach i_image [$i_sector getImages] {
	    set item $session_items_by_object($i_image)
#	    puts "body Controller::deleteImagesFromSector - image is $session_items_by_object($i_image)"
	    foreach i_imagename [$itk_component(indexing) getIncludedImages] {
		#puts $i_imagename	
		if {$i_image == $i_imagename} {
		    #puts "attempt removal of $i_imagename from indexing component"
		    $itk_component(indexing) removeImage $i_imagename
		}	}
	    $i_sector deleteImage $i_image
	    $itk_component(session_tree) item remove $item
	    array unset session_items_by_object $i_image
	    array unset session_objects_by_item $item
	}
    }
#	.image updateImageList
}


body Controller::updateCell { a_cell } {
    # update treectrl's cell item
    #puts "Updating Images  cell: [$a_cell reportCell]"
    $itk_component(session_tree) item text $session_items_by_object($a_cell) 0 "Lattice [$::session getCurrentLattice]" 1 "[$a_cell reportCell]"
}
    
body Controller::updateSpacegroup { a_spacegroup } {
    # update treectrl's spacegroup item
    $itk_component(session_tree) item text $session_items_by_object($a_spacegroup) 1 "[$a_spacegroup reportSpacegroup]"
}
    
body Controller::updateMosaicity { a_mosaicity } {
    #update treectrl's mosaicity item
    $itk_component(session_tree) item text $session_items_by_object(mosaicity) 1 "$a_mosaicity"
}

body Controller::updateMosaicblock { a_mosaicblock} {
    #update treectrl's mosaicblock item
    $itk_component(session_tree) item text $session_items_by_object(mosaicblock) 1 "$a_mosaicblock"
}
    
body Controller::updateImage { a_image } {
    #puts "updating image [$a_image getNumber]\'s phi values [$a_image reportPhis]"
    $itk_component(session_tree) item text $session_items_by_object($a_image) 1 "[$a_image reportPhis]"
    updateSector [$a_image getSector]
}

body Controller::updateSector { a_sector } {
    if {$::debugging} {
        #puts "flow: in Controller::updateSector a_sector is $a_sector "
    }
    #update treectrl's sector item's phi range
    foreach { l_phi_start l_phi_end } [$a_sector getPhi] break
    $itk_component(session_tree) item text  $session_items_by_object($a_sector) 1 "\u03c6:$l_phi_start->$l_phi_end"
}

body Controller::updateMatrix { a_sector a_matrix } {
    #puts "Controller::updateMatrix for $a_sector [$a_sector getTemplate] Matrix: $a_matrix [$a_matrix getName]"
    # update treectrl's matrix name
    if {[$::session getMultipleLattices]} {
	# Append lattice number to matrix label written in tree
        set latt "_lattice[$::session getCurrentLattice]"
    } else {
	set latt ""
    }
    $itk_component(session_tree) item text $session_items_by_object($a_matrix) 1 "[$a_matrix getName]$latt"
    #puts "session_items_by_object([$a_sector getMatrix]) $session_items_by_object([$a_sector getMatrix]) matrix name [[$a_sector getMatrix] getName]"
    #puts "Sector: $a_sector [$a_sector getTemplate] Matrix: $a_matrix [$a_matrix getName]"
}

body Controller::singleClickSession { w x y } {
    # callback for single click on session treectrl
    set lukesingle2 ""
    set lukesingle $w
    #puts "S: lukesingle $lukesingle x y $x $y"
    #puts "S: selection [$w selection get]"
    set lukesingle2 [$w identify $x $y]
    #puts "S: id/lukesingle2 $lukesingle2"
    set id $lukesingle2
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	#puts "id: $id"
	# get the object belonging to the item double clicked on
	set l_object $session_objects_by_item($item)
	# if anything but a Sector line
	if {[$l_object isa Sector]} {
	    if {$where != "button"} {
		# Avoid misleading message when clicking on the [+] or [-] expand & collapse buttons
		updateStatusMessage "Right-click to delete selected sector"
	    }
	} elseif {[$l_object isa Image]} {
	    updateStatusMessage "Right-click to delete selected image or click again on values to edit"
	} elseif {[$l_object isa Matrix]} {
	    updateStatusMessage "Double-click for Matrix properties menu"
	} else {
	    updateStatusMessage "Click again on highlighted values to edit. Hit Return to accept your edits."
	    $::session setCellBeenEdited [$::session getCurrentLattice] 0
	}
    }
}

body Controller::rightClickSession { } {
    set current_sector $session_items_by_object([$::session getCurrentSector])
    #puts "current_sector in Controller::rightClickSession set to $current_sector"
    # callback for right click on session treectrl
    # needs to have a selection made first by a single click
    # changed 11.05.2018 HRP for deleting sectors for chunking
    if { [$::session getParameterValue sum_n_images_changed] == "0" } {
	if { $lukesingle eq "" } {
	    return
	} else {
	    set selection [$lukesingle selection get]
#	    puts "selection = $selection"
	    #puts "R: selection [$lukesingle selection get]"
	    if { $selection eq ""} { return }
	}
    } else { 
	set lukesingle2 "item $current_sector column 0 elem e_text"
    }

    set id $lukesingle2
    #puts "R: id/lukesingle2 $id x y $x $y"
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	# get the object belonging to the item double clicked on
	set l_object $session_objects_by_item($item)
	# if a Sector line, but not if anything else
	if {[$l_object isa Sector]} {
	    if {$where == "column"} {
		$itk_component(session_tree) item remove $item	
		foreach i_sector [$::session getSectors] {
		    #puts $i_sector
		    if {$i_sector == $l_object} {
			#puts "found a match and will delete $i_sector from session and stages"
			foreach i_imagename [$itk_component(indexing) getIncludedImages] {
			    #puts $i_imagename	
			    foreach l_imagename [$i_sector getImages] {
				if {$i_imagename == $l_imagename} {
				    $itk_component(indexing) removeImage $i_imagename
				}
			    }
			}
			[$itk_component(indexing) component image_numbers] deleteSector $i_sector
			[$itk_component(cell_refinement) component image_numbers] deleteSector $i_sector
			[$itk_component(integration) component image_numbers] deleteSector $i_sector
			
		        foreach l_imagename [$i_sector getImages] {
			    $::session addHistoryEvent "ImageDeleteEvent" "User action" $l_imagename
			}
			$::session deleteSector $i_sector
			#puts "Sector item was $session_items_by_object($i_sector)"
			array unset session_items_by_object $i_sector
			array unset session_objects_by_item $item
		    }
		}
	    }
	} elseif {[$l_object isa Image]} {
	    if {$where == "column"} {
		$itk_component(session_tree) item remove $item	
		foreach i_sector [$::session getSectors] {
		    foreach i_image [$i_sector getImages] {
			if {$i_image == $l_object} {
			    #puts "Image item was $session_items_by_object($i_image)"
			    #puts "found image $i_image in sector $i_sector matches object $l_object"
			    foreach i_imagename [$itk_component(indexing) getIncludedImages] {
				#puts $i_imagename	
				if {$i_image == $i_imagename} {
				    #puts "attempt removal of $i_imagename from indexing component"
				    $itk_component(indexing) removeImage $i_imagename
				}
			    }
			    set status [$i_sector deleteImage $i_image]
			    if { $status == "-1" } {
				# Deleted last image in this sector
				$::session deleteSector $i_sector
				set sector_item $session_items_by_object($i_sector)
				$itk_component(session_tree) item remove $sector_item
				# unset array pointers - image and sector
				array unset session_items_by_object $i_image
				array unset session_objects_by_item $item
				array unset session_items_by_object $i_sector
				array unset session_objects_by_item $sector_item
			    } elseif { $status == "1" } {
				# unset array pointers - just the image
				array unset session_items_by_object $i_image
				array unset session_objects_by_item $item
			    } else {
				# 0 means nothing deleted
			    }
			}
		    }
		}
	    }
	} else {
	    #
	}
	.image updateImageList
	
	if {[llength [$::session getSectors]] > 0} {
	    .image openImage [lindex [[lindex [$::session getSectors] 0] getImages] 0]
	} else {
	    .image closeImage
	    disableIndexing
	    disableProcessing
	}
    }
}

################################################################################

body Controller::doubleClickSession { w x y } {
    # callback for double click on session treectrl
    set id [$w identify $x $y]
    if {$id eq ""} {
    } elseif {[lindex $id 0] eq "header"} {
    } else {
	foreach {what item where arg1 arg2 arg3} $id {}
	# get the object belonging to the item double clicked on
	set l_object $session_objects_by_item($item)
	# if it's an image
	if {[$l_object isa Image]} {
	    .image openImage $l_object
	} elseif {[$l_object isa Matrix]} {
	    # if it's a matrix, get parent sector 
	    set l_sector $session_objects_by_item([$w item parent $item])
	    # and edit sector's matrix
	    editMatrixProperties $l_sector $l_object 
	}
    }
}

body Controller::editTree { an_item a_column an_element a_text} {
    # Updated the item's text
  # puts "debug: in Controller::editTree"
    set l_object $session_objects_by_item($an_item)
    #puts "$an_item $a_column $an_element $a_text"
    #puts $l_object
    # check user input according to item class
    if {[$l_object isa Cell]} {
	if {[regexp {^[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*(\d+\.?\d*|\.\d+)[^\d\.]*$} $a_text match l_a l_b l_c l_alpha l_beta l_gamma]} {
	    foreach i_x { l_a l_b l_c l_alpha l_beta l_gamma } {
		set $i_x [format %.2f [set $i_x]]
	    }
	    #puts "Will be validating edit: $l_a $l_b $l_c $l_alpha $l_beta $l_gamma [$::session reportSpacegroup]"
	    $::session setCellBeenEdited [$::session getCurrentLattice]
	    if { [$::session reportSpacegroup] == "Unknown" } {
              # puts "debug: in Controller::editTree Unknown call validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma"
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma
	    } else {
              # puts "debug: in Controller::editTree NOT Unknown call validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma"
		$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma [$::session reportSpacegroup]
	    }
	} else {
	    # ignore input
	}
    } elseif {[$l_object isa Spacegroup]} {
        regsub -all " " $a_text "" b_text
	if { [string length $b_text] == 0 } { return }
	set l_text [string toupper $b_text]
	if { [string index $l_text 0] == "H" } {
	    set l_text [string tolower $l_text]
	}
	# Search in iMosflm's list
	set nfound [lsearch $::spacegroups $l_text]
	#if { $nfound > -1} {
	#    puts "Spacegroup text found in iMosflm: $nfound"
	#} else {
	#    puts "Spacegroup text  NOT  in iMosflm: [string tolower $l_text]"
	#}
	foreach { l_a l_b l_c l_alpha l_beta l_gamma } [[$::session getCell] listCell] break
      # puts "debug: in Controller::editTree call validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $l_text"
	$::session validateCellAndSpacegroup $l_a $l_b $l_c $l_alpha $l_beta $l_gamma $l_text
    } elseif {[$l_object isa Image]} {
	#puts "Input: $a_text"
	set l_phi {}
	set l_phi [regexp -inline -all -- {[-+]?\d*\.?\d+} $a_text]
	#puts "Phi's: $l_phi"
	if { [llength $l_phi] == 2 } {
	    [$l_object getSector] propagatePhi $l_object [lindex $l_phi 0] [lindex $l_phi 1]
	} elseif { [llength $l_phi] == 5 } {
	    $l_object setPhi [lindex $l_phi 0] [lindex $l_phi 1] 1 1 "User"
	    $l_object updateMissets [lindex $l_phi 2] [lindex $l_phi 3] [lindex $l_phi 4] 1 1 "User" [$::session getCurrentLattice]
	} else {
	}	    
    } elseif {[$l_object isa SessionParameter]} {
	# Must be mosaicity
	if {[$l_object getName] eq "mosaicity"} {
	if {[string is double $a_text]} {
	    $::session updateSetting "mosaicity" $a_text
	}
	} else {
	    if {[string is double $a_text]} {
	        $::session updateSetting "mosaicblock" $a_text
	    }
        }
    }
}

body Controller::getObjectByItem { an_item } {
    return $session_objects_by_item($an_item)
}

body Controller::editMatrixProperties { a_sector a_matrix } {
    # Create matrix properties dialog if necessary
    if {![winfo exists .matrixProperties]} {
	MatrixDialog .matrixProperties -title "Matrix properties"
    }
    # load in the matrix to be edited
    .matrixProperties load $a_matrix
    # Get a matrix from the user
    set l_new_matrix [.matrixProperties get]
    # if the user provided a 'new' matrix
    if {$l_new_matrix != ""} {
	# get the 'old' matrix
	set l_old_matrix [$a_sector getMatrix]
	# if the new matrix is really different from the old one..
	if {![$l_old_matrix equals $l_new_matrix]} {
	    # update the sector's matrix
	    $a_sector updateMatrix "User" $l_new_matrix
	}
    }
}

body Controller::uncheckAutothreshCheckbutton {} {
    $::session updateSetting "auto_thresh_indexing" "0" 0 1 "User" 0
}

# About dialog ################################

class About {
    inherit Amodaldialog 

    constructor { args } { }
}

body About::constructor { args } {
    
    itk_component add frame {
	frame $itk_interior.f \
	    -bd 2
    }

    itk_component add icon {
	label $itk_interior.f.icon \
	    -image ::img::activity_idle16x16
    }

    itk_component add version {
	label $itk_interior.f.version \
	    -text "$::env(IMOSFLM_VERSION)\n" \
	    -font "helvetica -14 bold"
    } {
	usual
	ignore -font
    }

    itk_component add credits {
	label $itk_interior.f.credits \
	    -text "References:" \
	    -font "helvetica -14 bold"
    } {
	usual
	ignore -font
    }
    
    itk_component add imosflm-label {
	label $itk_interior.f.imosflm-label \
	    -text "iMosflm:" \
	    -font "helvetica -14 bold" \
	    -justify left
    } {
	usual
	ignore -font
    }

    itk_component add imosflm-reference {
	label $itk_interior.f.imosflm-reference \
	    -text "T.G.G. Battye, L. Kontogiannis, O. Johnson, H.R. Powell and A.G.W. Leslie.(2011) Acta Cryst. D67, 271-281" \
	    -justify left
    } {
	usual
	ignore -font
    }
    
    itk_component add mosflm-label {
	label $itk_interior.f.mosflm-label \
	    -text "Mosflm:" \
	    -font "helvetica -14 bold" \
	    -justify left
    } {
	usual
	ignore -font
    }

    itk_component add mosflm-reference {
	label $itk_interior.f.mosflm-reference \
	    -text "A.G.W. Leslie and H.R. Powell (2007), Evolving Methods for Macromolecular Crystallography, 245, 41-51 ISBN 978-1-4020-6314-5" \
	    -justify left
    } {
	usual
	ignore -font
    }
    
    itk_component add index-label {
	label $itk_interior.f.index-label \
	    -text "Autoindexing:" \
	    -font "helvetica -14 bold" \
	    -justify left
    } {
	usual
	ignore -font
    }

    itk_component add index-reference {
	label $itk_interior.f.index-reference \
	    -text "I. Steller,  R. Bolotovsky and M.G. Rossmann (1997) J. Appl. Cryst. 30, 1036-1040" \
	    -justify left
    } {
	usual
	ignore -font
    }
    
    
    
    
    itk_component add button {
	button $itk_interior.button \
	    -text "Close" \
	    -relief raised \
	    -command [code $this hide]
    }

    pack $itk_component(frame) -fill both -expand 1
    pack $itk_component(button) -pady 5
    grid $itk_component(version) -columnspan 3
    grid $itk_component(credits) -sticky w -pady 3
    grid $itk_component(imosflm-label) x $itk_component(imosflm-reference) -sticky w -pady 3
    grid $itk_component(mosflm-label) x $itk_component(mosflm-reference) -sticky w -pady 3
    grid $itk_component(index-label) x $itk_component(index-reference) -sticky w -pady 3

    eval itk_initialize $args
}
