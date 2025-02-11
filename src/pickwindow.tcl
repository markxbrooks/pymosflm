# $Id: pickwindow.tcl,v 1.10 2020/12/15 20:22:39 andrew Exp $
package provide pickwindow 1.0

class PickWindow {
    inherit Amodaldialog

    # methods

    public method launch
    public method processPick
    constructor { args } { }
}


body PickWindow::constructor { args } {

    itk_component add textarea {
	    text $itk_interior.ta -wrap none
    }

    # Close button
    itk_component add close_b {
        button $itk_interior.button \
	    -highlightthickness 0 \
	    -takefocus 0 \
	    -text "Close" \
	    -command [code $this hide]
    }

    itk_component add textareayscrollbar {
	scrollbar $itk_interior.txtscrollbar_y \
	    -command [code $this component textarea yview] \
	    -orient vertical
    }

    itk_component add textareaxscrollbar {
	scrollbar $itk_interior.txtscrollbar_x \
	    -command [code $this component textarea xview] \
	    -orient horizontal
    }

    $itk_component(textarea) configure \
	-yscrollcommand [code $this component textareayscrollbar set]
    
    $itk_component(textarea) configure \
	-xscrollcommand [code $this component textareaxscrollbar set]

    # Arrange widgets

    set margin 7
    
    pack $itk_component(textareaxscrollbar) -side bottom -fill x
    pack $itk_component(textarea) -side left -expand true -fill both
    pack $itk_component(textareayscrollbar) -side right -fill y

    eval itk_initialize $args
}

body PickWindow::launch { } {
    # show the dialog
    show
}


body PickWindow::processPick { a_dom } {
    #puts "mydebug: entering PickWindow::processPick"
    launch
    set tabstop 7
    set boxsize_x [$::session getParameterValue pickbox_size_x]
    set boxsize_y [$::session getParameterValue pickbox_size_y]
    $itk_component(textarea) delete 1.0 end
    .pw configure -title "Pixel Intensities: $boxsize_x x $boxsize_y pixels"

    set l_data [$a_dom selectNodes normalize-space(/pick_region)]
    set middle_pixel_x [lindex $l_data 1]
    set middle_pixel_y [lindex $l_data 2]
    set start_pixel_x [expr {$middle_pixel_x - ($boxsize_x/2)}]
    set start_pixel_y [expr {$middle_pixel_y - ($boxsize_y/2)}]
    set coord_iterator 0
    while {$coord_iterator < $boxsize_x} {
	set pixel_coord_x [expr {$start_pixel_x + $coord_iterator}]
	$itk_component(textarea) insert end "\t$pixel_coord_x"
	incr coord_iterator
    }
    # Add tag to underline x pixel headings
    $itk_component(textarea) tag add pixelx 1.0 1.end
    $itk_component(textarea) insert end "\n"
    
    set coord_iterator 0
    set l_y 0
    while {$l_y < $boxsize_y} {
	set pixel_coord_y [expr {$start_pixel_y + $coord_iterator}]
	$itk_component(textarea) insert end $pixel_coord_y
	set l_x 0
	while {$l_x < $boxsize_x} {
	    set l_datum [lindex $l_data [expr {($l_x * $boxsize_y) + $l_y + 5}]]
	    $itk_component(textarea) insert end "\t$l_datum"
	    set pixel_coord_x [expr {$start_pixel_x + $l_x}]
	    if { ($pixel_coord_y == $middle_pixel_y) && ($pixel_coord_x == $middle_pixel_x)} {
		set row [expr {$l_y + 2}]; # the row containing the target pixel
		set uline [string length $l_datum]; # the number of characters from the end to underline
		# Add tag to underline the picked pixel
		$itk_component(textarea) tag add target "$row.end - $uline\c" "$row.end"
	    }
	    incr l_x
	}
	incr l_y
	incr coord_iterator
	$itk_component(textarea) insert end "\n"
    }
    $itk_component(textarea) configure -tabs ".$tabstop\i right"
    # Switch on underlining of x pixel headings and target pixel
    $itk_component(textarea) tag configure pixelx -underline true
    $itk_component(textarea) tag configure target -underline true
}

