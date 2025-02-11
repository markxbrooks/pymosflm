# $Id: chunking.tcl,v 1.2 2020/12/15 20:22:39 andrew Exp $
package provide chunking 1.0

class Chunking {
    inherit Amodaldialog

    # Member variables

    private variable sum_n_images
    private variable auto_sum_images_popup_relay
    private variable recommended "2"
    private variable degsym "\u00b0"
    private variable chunkingonoff "chunkon"
    # methods

    public method toggleSumImagesPopupRelayBool
    public method updateContents
    public method chunkingnoton
    public method chunkingnotoff
    public method applyAndExit
    public method enableButton

    constructor { args } { }
}

body Chunking::constructor { args } {

    # Main frame
    itk_component add main_f {
	frame $itk_interior.mf \
	    -bd 2 \
	    -relief raised
    }


    # Internal frame
    itk_component add internal_f {
	frame $itk_interior.mf.if \
	    -bd 1 \
	    -relief solid
    }

    # Header label

    itk_component add heading_l {
	label $itk_interior.mf.if.fl \
	    -text "Chunking HDF5 images" \
	    -font title_font
    } {
	usual
	ignore -font
    }
    # descriptive text
    itk_component add preamble_l {
	label $itk_interior.mf.if.chunkpreamble \
	    -justify left \
	    -text "The oscillation angle for each image is ???$degsym. If the images are very \nweak iMosflm may process the data better if the images are combined together to give \nan oscillation angle >= 0.2 $degsym. \n\nDo you want to do this?"


    }
    itk_component add chunkingframe {
	frame $itk_interior.mf.if.chunkingframe
    }
    itk_component add chunkingon {
	radiobutton $itk_interior.mf.if.chunkingframe.chunkingon \
	    -text "yes, combine" \
	    -variable [scope chunkingonoff] \
	    -value "chunkon" \
	    -command [code $this chunkingnotoff]
    }

    itk_component add chunkingoff {
	radiobutton $itk_interior.mf.if.chunkingframe.chunkingoff \
	-text "no, process images individually" \
	    -variable [scope chunkingonoff] \
	    -value "chunkoff" \
	    -command [code $this chunkingnoton]
    }

#    itk_component add chunk_on {
#	gcheckbutton $itk_interior.mf.if.chunk_on \
#	    -text "turn chunking on, summing" \
#	    -balloonhelp "
#If you choose this option, real images will be added together to give 
#a set of virtual images; for example, if you have a dataset with 1000 
#images each of rotation range 0.1$degsym and choose to chunk in groups 
#of 4, the dataset will appear to consist of 250 images each with 
#rotation range 0.4$degsym
#
#Because of the way that data is handled inside iMosflm, if you change 
#this value, you need to re-index with the new chunking"
#    }


    itk_component add chunk_l2 {
        label $itk_interior.mf.if.chunkingframe.chunk_l2 \
	    -text " images into 1 virtual image"
    }


    itk_component add chunk_e2 {
	SettingEntry $itk_interior.mf.if.chunkingframe.chunk_e2 sum_n_images \
	    -type int \
	    -width 2 \
	    -minimum 2 \
	    -maximum 10 \
	    -balloonhelp "enter your own number of images to chunk together; the initial value here is 
based on the rotation angle of the real images" \
	    -justify right
	}


    ## don't show again label & button

    itk_component add dontshow_b {
        checkbutton $itk_interior.mf.if.dontshow_b \
	    -command [ code $this toggleSumImagesPopupRelayBool ] \
	    -variable [scope auto_sum_images_popup_relay] \
	    -text "Show this message (you can change this in \n\"Processing options -> Processing\""
# 	    -balloonhelp "you can change this in the \"Processing options -> Processing\" 
# dialogue, and you can also change the chunking size there"
# need a -variable and -text	    -command [code $this hide]
    }

    ## Dismiss button

    itk_component add dismiss {
        button $itk_interior.mf.button \
	    -takefocus 0 \
	    -text "Apply & dismiss" \
	    -command [code $this applyAndExit] \
	    -state "disabled"
    }

    # Arrange widgets

    set margin 7
    
    pack $itk_component(main_f) -fill both -expand 1
    
    grid x $itk_component(internal_f) - - x -sticky we -pady 7
    grid x $itk_component(heading_l) -columnspan 4 -column 0 -row 0 -sticky we
    grid x $itk_component(preamble_l) -columnspan 4 -column 0 -row 1 -sticky we

#    grid $itk_component(chunk_l) -column 2 -row 2
#    grid $itk_component(chunk_e) -column 1 -row 2
#    grid $itk_component(chunk_on) -column 0 -row 2 -sticky w
    grid $itk_component(chunkingframe)  -column 0 -row 3 -sticky w
    grid $itk_component(chunkingon)  -column 0 -row 3 -sticky w
    grid $itk_component(chunk_e2)  -column 1 -row 3 -sticky w
    grid $itk_component(chunk_l2)  -column 2 -row 3 -sticky w
    grid $itk_component(chunkingoff)  -column 0 -row 4 -sticky w -columnspan 3
    grid $itk_component(dontshow_b) -column 0 -row 5 -sticky w
    grid columnconfigure $itk_component(main_f) { 0 4 } -minsize 7
    grid columnconfigure $itk_component(main_f) { 3 } -weight 1
    grid rowconfigure $itk_component(main_f) { 5 } -weight 1
    grid $itk_component(dismiss) -column 3 -row 6

    
    $itk_component(dismiss) configure -state "disabled"

    eval itk_initialize $args
}

body Chunking::updateContents { } {
    set sum_n_images [$::session getParameterValue sum_n_images]
    if { $sum_n_images < 1 } {
	set sum_n_images 1
    }
    set recommended [expr int(0.2/([$::session reportOscRange]/$sum_n_images))]
    if { $recommended < 1 } {
	set recommended 1
    }
    set number_of_images [expr int([$::session getParameterValue total_images]/$recommended)]
    if { $number_of_images < 1 } {
	set number_of_images 1
    }
    $itk_component(chunk_e2) setValue $recommended

    $itk_component(preamble_l) configure -text "The oscillation angle for each image is [$::session reportOscRange]$degsym. If the images are very \nweak iMosflm may process the data better if the images are combined together to give\n an oscillation angle >= 0.2$degsym. \n\nThe calculated optimum value will give $number_of_images images, each with an oscillation\n angle of [expr $recommended * [$::session reportOscRange]]$degsym. \n\nDo you want to do this?"

set auto_sum_images_popup_relay [.ats component processing getSumImagesPopupRelayBool]

    $itk_component(dismiss) configure -state "disabled"

}

body Chunking::toggleSumImagesPopupRelayBool { } {
    if { [.ats component processing getSumImagesPopupRelayBool] == "1" } {
	set auto_sum_images_popup_relay 0
	.ats component processing setSumImagesPopupRelayBool 0
    } else {
	set auto_sum_images_popup_relay 1
	.ats component processing setSumImagesPopupRelayBool 1
    }
}


body Chunking::chunkingnoton { } {
    $itk_component(chunk_e2) setValue 1
    set sum_n_images 1
    $::session setParameterValue sum_n_images $sum_n_images
}

body Chunking::chunkingnotoff { } {
    set sum_n_images $recommended
    $::session setParameterValue sum_n_images $sum_n_images
}
# #############################################################



body Chunking::applyAndExit { } {
    if { $chunkingonoff == "chunkon" } {
	$::session setParameterValue sum_n_images $recommended
    } {
	
	$::session setParameterValue sum_n_images 1
    }
    $itk_component(dismiss) configure -state "disabled"
    hide

}

body Chunking::enableButton { } {
    $itk_component(dismiss) configure -state "active"

}
#class Chunking { }


