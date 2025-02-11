# $Id: imagenumbers.tcl,v 1.14 2021/07/09 14:49:06 andrew Exp $
package provide imagenumbers 1.0

class Imagenumbers {
    inherit itk::Widget

    itk_option define -command command Command ""

    private variable templates_by_index ;# array
    private variable indices_by_template ;# array
    private variable index "1"

    public method clear
    public method addSector
    public method deleteSector
    public method execute
    public method updateSector
    public method getContent
   
    constructor { args } { }
}

body Imagenumbers::constructor { args } {
    # create dummy gEntry to allow options to be kept!
    itk_component add dummy {
	gEntry $itk_interior.dummy
    } {
	usual
    }

    eval itk_initialize $args
}

body Imagenumbers::clear { } {
    foreach i_index [array names templates_by_index] {
	destroy $itk_component(frame$i_index)
	set l_template $templates_by_index($i_index)
	array unset templates_by_index $i_index
	array unset indices_by_template $l_template
    }
}

body Imagenumbers::addSector { a_sector } {
    
    itk_component add frame$index {
	frame $itk_interior.frame$index
    }
    
    itk_component add label$index {
	label $itk_interior.frame$index.label \
	    -text "[$a_sector getTemplateForMosflm] :" \
	    -anchor w
    }
    
    itk_component add entry$index {
	gEntry $itk_interior.frame$index.entry \
	    -borderwidth 2 \
	    -relief sunken
    } {
	usual
	ignore -relief -borderwidth
	keep -state
	    
    }
    bind [$itk_component(entry$index) component entry] <Return> [code $this execute $index]
    bind [$itk_component(entry$index) component entry] <FocusOut> [code $this execute $index]
    
    pack $itk_component(frame$index) -side top -fill x
    pack $itk_component(label$index) -side left
    pack $itk_component(entry$index) -side right -fill x -expand 1
    
    set templates_by_index($index) [$a_sector getTemplate]
    set indices_by_template([$a_sector getTemplate]) $index

    incr index
    
    # Show template label even for first sector rather than 'Images:'
    foreach i_index [array names templates_by_index] {
	pack $itk_component(label$i_index) -side left
    }

}

body Imagenumbers::deleteSector { a_sector } {
    set l_index $indices_by_template([$a_sector getTemplate])
    destroy $itk_component(frame$l_index)
    array unset templates_by_index $l_index
    array unset indices_by_template [$a_sector getTemplate]

    # Remove template labels if only one sector remains
    set l_count [llength [array names templates_by_index]]
    if {$l_count == 1} {
	pack forget $itk_component(label[lindex [array names templates_by_index] 0])
    }
	
}

body Imagenumbers::execute { an_index } {
    if {$itk_option(-command) != ""} {
	set l_num_list [uncompressNumList [$itk_component(entry$an_index) query]]
	#puts $l_num_list
	uplevel \#0 $itk_option(-command) $templates_by_index($an_index) [list $l_num_list]
    }
}

body Imagenumbers::updateSector {a_template a_num_list} {
    $itk_component(entry$indices_by_template($a_template)) update $a_num_list
}

body Imagenumbers::getContent { } {
    set l_content {}
    set lsort_nums {}
    foreach i_template [array names indices_by_template] {
	set l_nums [uncompressNumList [$itk_component(entry$indices_by_template($i_template)) query]]
	#puts $l_nums
	if {$l_nums != ""} {
	    # Sort this list unique to prevent overlapping ranges screwing-up the plots
	    set lsort_nums [lsort -integer -uniq $l_nums]
	    #puts $lsort_nums
	    lappend l_content [list $i_template $lsort_nums]
	}
    }
    return $l_content
}

usual Imagenumbers {
    usual gEntry
}

# ########################################################################

class ImagenumbersSingle {
    inherit itk::Widget

    itk_option define -command command Command ""

    private variable templates
    private variable titles
    private variable indices_by_template ;# array
    private variable index "1"
    private variable singlesectorcombo_title ""

    private variable old_template ""
    public method toggleTemplate

    public method clear
    public method addSector
    public method deleteSector
    public method execute
    public method updateSector
    public method getContent
   
    constructor { args } { }
}

body ImagenumbersSingle::constructor { args } {
    itk_component add singlesectorcombo {
	combobox::combobox $itk_interior.singlesectorcombo \
	    -listvar [scope titles] \
	    -width 32 \
	    -editable 0 \
	    -highlightcolor black \
	    -command [code $this toggleTemplate]
    } {
	keep -state
	keep -background -cursor -foreground -font
	keep -selectbackground -selectborderwidth -selectforeground
	keep -highlightcolor -highlightthickness
	rename -highlightbackground -background background Background
	rename -background -textbackground textBackground Background
    }
    
    set old_template "\n"	
    #puts $old_template

    itk_component add entry {
	gEntry $itk_interior.entry \
	    -relief sunken \
	    -borderwidth 2
    } {
	usual
	ignore -borderwidth -relief
	keep -state
    }
    bind [$itk_component(entry) component entry] <Return> [code $this execute]
    bind [$itk_component(entry) component entry] <FocusOut> [code $this execute]

    pack $itk_component(singlesectorcombo) -side left
    pack $itk_component(entry) -side right -fill x -expand 1

    eval itk_initialize $args

}

body ImagenumbersSingle::clear { } {
    set old_template ""
    set templates {}
    $itk_component(singlesectorcombo) delete 0 end
    $itk_component(entry) update ""
}

body ImagenumbersSingle::addSector { a_sector } {
    if { [regexp -- {^(.*?)(_master.h5)$} [$a_sector getTemplateForMosflm] match]} {
	set title [string replace [$a_sector getTemplateForMosflm] end-9 end]
	set singlesectorcombo_title [$a_sector getTemplateForMosflm]
    } elseif { [regexp -- {^(.*?)(.nxs)$} [$a_sector getTemplateForMosflm] match]} {
	set title [file rootname [$a_sector getTemplateForMosflm]]
	set singlesectorcombo_title [$a_sector getTemplateForMosflm]
    } {
	set title [$a_sector getTemplate]
    }
    set l_template [$a_sector getTemplate]

    lappend titles $title
    lappend templates [$a_sector getTemplate]
#    $itk_component(singlesectorcombo) select [expr [llength $templates] -1]
    $itk_component(singlesectorcombo) select [expr [llength $titles] -1]
    set l_text [$itk_component(singlesectorcombo) get]
    if {$l_text == ""} {
	$itk_component(singlesectorcombo) select 0
    }

    # Show template label even for first sector rather than 'Images:'
    pack $itk_component(singlesectorcombo) -side left

}

body ImagenumbersSingle::deleteSector { a_sector } {
    set l_template [$a_sector getTemplate]  
    set l_title [$a_sector getTemplateForMosflm]
    set l_index [lsearch $templates $l_template]
    if {$l_index != -1} {
	set templates [lreplace $templates $l_index $l_index]
	set titles [lreplace $titles $l_index $l_index]
	set l_text [$itk_component(singlesectorcombo) get]
#HRP 07032018	if {$l_text == $l_template} {
#HRP 07032018	    $itk_component(singlesectorcombo) select 0
#HRP 07032018	}
	if {$l_text == $l_template} {
	    $itk_component(singlesectorcombo) select 0
	}
    }    
    # Make sure template labels are shown if more than one sector is present
    if {[llength $templates] > 1} {
	pack $itk_component(singlesectorcombo) -side left
    } else {
	pack forget $itk_component(singlesectorcombo)	
    }
}

body ImagenumbersSingle::execute { } {
    if {$itk_option(-command) != ""} {
	#puts "Command is $itk_option(-command)"
	set l_num_list [uncompressNumList [$itk_component(entry) query]]
	#puts "ImagenumbersSingle::execute num_list is $l_num_list"
	# execute is called if a new session is started so check for an empty list
	#if { $l_num_list == "" } {
	#    puts "Empty so could build num_list from all current sector\'s images"
	#    foreach l_image [[$::session getCurrentSector] getImages] {
	#	puts "lappend l_num_list [$l_image getNumber]"
	#    }
	#}
	# Dont pass list back to indexwizard else spot finding commences for all images
	# or cellrefinement wizard when all images are selected for cell refinement due to
	# Mosflm::getCellRefinementSegments not knowing the current selected.
	# Command in both cellrefinement and integration wizards is defaultImageSelection
	#puts "Try [$itk_component(singlesectorcombo) get] [list $l_num_list]"

	# template and image numbers list returned for Indexwizard::chooseImages
	uplevel \#0 $itk_option(-command) [$itk_component(singlesectorcombo) get] [list $l_num_list]
    }
}

body ImagenumbersSingle::updateSector { a_template { a_num_list "" } } {

    #puts "ImagenumbersSingle::updateSector template $a_template num_list $a_num_list"
    #puts "In ImagenumbersSingle::updateSector calling setcurrentsector with template $a_template"
    $::session setCurrentSector [$::session getSectorByTemplate $a_template]
    set l_index [lsearch $templates $a_template]
    #puts "updateSector: index $l_index $templates"
    if {$l_index != -1} {
	# Disable singlesectorcombo's command before updating to prevent recursive updating!
	set l_command [$itk_component(singlesectorcombo) cget -command]
	$itk_component(singlesectorcombo) configure -command {}
	$itk_component(singlesectorcombo) select $l_index
	# ... and restore command after update
	$itk_component(singlesectorcombo) configure -command $l_command
        $itk_component(entry) update $a_num_list
    }
    # If no matrix for this sector disable processing stages
    #puts "In ImagenumbersSingle::updateSector calling getCurrentSector"
    if { ![[[$::session getCurrentSector] getMatrix] isValid] } {
	.c disableProcessing
    } else {
	.c enableProcessing
    }
}

body ImagenumbersSingle::getContent { } {
    set l_content {}
    set l_title [$itk_component(singlesectorcombo) get]
#    if { [regexp -- {^(.*?)(_master.h5)$} $singlesectorcombo_title match]} {}
	# can we use this test here?
    if { $::env(HDF5file) == 1 } {
	set l_template "image.\#\#\#\#\#\#\#"
    } {
	set l_template $l_title
    }
    set l_nums [uncompressNumList [$itk_component(entry) query]]
    if {($l_template != "") && ($l_nums != "")} {
	set l_content [list [list $l_template $l_nums]]
        updateSector $l_template [compressNumList $l_nums]
	return $l_content
    }
}

body ImagenumbersSingle::toggleTemplate { a_combo a_value } {

    if {$a_value != $old_template} { 
	#puts "Template was $old_template changing to $a_value"
        updateSector $a_value ;# why? - to update session's current sector
	set old_template $a_value
	$itk_component(entry) update ""
	focus [$itk_component(entry) component entry]
	execute

	focus $a_combo ;# but unsure why
    }
}

usual ImagenumbersSingle {
    usual gEntry
}
