# $Id: spotlistwindow.tcl,v 1.3 2014/12/10 15:27:28 ojohnson Exp $
package provide spotlistwindow 1.0

class SpotlistWindow {
    inherit Amodaldialog

    # methods

    public method launch
    public method process
    constructor { args } { }
}


body SpotlistWindow::constructor { args } {

    itk_component add textarea {
	listbox $itk_interior.ta \
	    -width 72 \
	    -height 20
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

    $itk_component(textarea) configure \
	-yscrollcommand [code $this component textareayscrollbar set]
    
    # Arrange widgets

    set margin 7
    
    pack $itk_component(textarea) -side left -expand true -fill both
    pack $itk_component(textareayscrollbar) -side right -fill y

    eval itk_initialize $args
}

body SpotlistWindow::launch { } {
    # show the dialog
    show
}


body SpotlistWindow::process { l_spotlist l_image } {
    
    .splw configure -title "Spot search results - Image [$l_image getNumber]"

    launch
    $itk_component(textarea) delete 0 end

    # Read the file with saved spot search results
    set spot_result [$l_image makeAuxiliaryFileName "ssr" $::mosflm_directory]
    set l_in_file [open $spot_result]
    set content [read $l_in_file]
    close $l_in_file

    # Split into records on newlines
    set records [split $content "\n"]
    
    # Iterate over the records adding to the text widget
    foreach rec $records {
	$itk_component(textarea) insert end $rec
    }

    # Add summary information stored in spot list object
    set l_auto [format %3d [$l_spotlist getAuto]]
    set l_manual [format %3d [$l_spotlist getManual]]
    set l_deleted [format %3d [$l_spotlist getDeleted]]
    set l_total [format %3d [$l_spotlist getTotal]]
    set l_totalIsigI [format %3d [$l_spotlist getTotalAboveIsigi]] 
    #$itk_component(textarea) insert end "Auto: $l_auto  Man: $l_manual  Del: $l_deleted  Total: $l_total  \>I/\u03c3(I): $l_totalIsigI"
    #$itk_component(textarea) insert end " "

    # Just read the spot list file from ~/.mosflm
    set spot_file [$l_image makeAuxiliaryFileName "spt" $::mosflm_directory]
    $itk_component(textarea) insert end "Spot list file: $spot_file"

    # Read the user's input file into a string
#    set l_in_file [open $spot_file]
#    set content [read $l_in_file]
#    close $l_in_file
#
#    # Split into records on newlines
#    set records [split $content "\n"]
#    
#    # Iterate over the records adding to the text widget
#    foreach rec $records {
#	$itk_component(textarea) insert end $rec
#    }

}

