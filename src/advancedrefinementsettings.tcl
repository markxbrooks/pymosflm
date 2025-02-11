# $Id: advancedrefinementsettings.tcl,v 1.24 2018/07/19 15:49:58 andrew Exp $
# package name
package provide advancedrefinementsettings 1.0

# Class
class Advancedrefinementsettings {
    inherit itk::Widget Settings2

    # variables
    ###########
    private variable profile_optimise_state 1

    # methods
    #########
    public method toggleProfileOptimise
    public method debug
    public method getPatternMatchingBool
    public method getPatternRefineBool

    # widget callbacks
    ##################
    private variable pattern_matching_bool "0"
    private variable pattern_refine_bool "0"
    private method togglePatternMatch
    private method togglePatternRefine

    constructor { args } { }

}

# Bodies

body Advancedrefinementsettings::debug { a_val } {
}

body Advancedrefinementsettings::constructor { args } {

    itk_component add processing_l {
        gSection $itk_interior.pl  -text "Detector parameter refinement"
    }
    
    itk_component add size_central_region_l {
        label $itk_interior.scrl  -text "Size of central region (mm):"  -anchor w
    }

    itk_component add size_central_region_e {
        SettingEntry $itk_interior.scre size_central_region \
	    -type real \
	    -precision 2\
	    -width 7 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add max_weighted_residual_l {
        label $itk_interior.mwrl  -text "Max weighted residual:"  -anchor w
    }

    itk_component add max_weighted_residual_e {
        SettingEntry $itk_interior.mwre max_weighted_residual \
	    -type real \
	    -precision 2\
	    -minimum 0 \
	    -width 7 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add max_number_reflections_l {
        label $itk_interior.mnrl  -text "Max number of reflections:"  -anchor w
    }

    itk_component add max_number_reflections_e {
        SettingEntry $itk_interior.mnre max_number_reflections \
	    -type int \
	    -minimum 1 \
	    -width 7 \
	    -balloonhelp " " \
	    -justify right
    }

	itk_component add donot_refine_detector_l {
   	label $itk_interior.drdl  -text "Do not refine detector parameters "  -anchor w
    }

    itk_component add donot_refine_detector_check {
        SettingCheckbutton $itk_interior.drdc donot_refine_detector \
	    -text "" 
    }

	itk_component add smooth_refined_detector_l {
   	label $itk_interior.srdl  -text "Smooth refined detector parameters "  -anchor w
    }

    itk_component add smooth_refined_detector_check {
        SettingCheckbutton $itk_interior.srdc smooth_refined_detector \
	    -text "" 
    }


	itk_component add use_overloads_in_refining_detector_l {
   	label $itk_interior.uoirdl  -text "Use overloads in refining detector"  -anchor w
    }

    itk_component add use_overloads_in_refining_detector_check {
        SettingCheckbutton $itk_interior.uoirdc use_overloads_in_refining_detector \
	    -text "" 
    }

    itk_component add number_images_ccom_l {
        label $itk_interior.nicl  -text "Number of images in smoothing ccom, yscale, dist:"  -anchor w
    }

    itk_component add number_images_ccom_e {
        SettingEntry $itk_interior.nice nsm1 \
	    -type int \
	    -minimum 1 \
	    -width 7 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add number_images_other_l {
        label $itk_interior.niol  -text "Number of images in smoothing other params:"  -anchor w
    }

    itk_component add number_images_other_e {
        SettingEntry $itk_interior.nioe nsm2 \
	    -type int \
	    -minimum 1 \
	    -width 7 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add nullpix_l {
        label $itk_interior.nullpixl  -text "Null pixel threshold:"  -anchor w
    }

    itk_component add nullpix_e {
        SettingEntry $itk_interior.nullpixe nullpix \
	    -balloonhelp "Spots containing a pixel with a value lower than this are ignored" \
	    -type int \
	    -width 7 \
	    -justify right
    }

    itk_component add ref_refl_count_thresh_l {
        label $itk_interior.rrctl  -text "Minimum number of reflections:"  -anchor w
    }

    itk_component add ref_refl_count_thresh_e {
        SettingEntry $itk_interior.rrcte ref_refl_count_thresh \
	    -balloonhelp "If there are fewer spots than this in the central area, refinement will abort" \
	    -type int \
	    -minimum 5 \
	    -width 7 \
	    -justify right
    }

    itk_component add max_backgr_grad_l {
        label $itk_interior.mbgl  -text "Maximum background gradient: "  -anchor w
    }

    itk_component add max_backgr_grad_e {
        SettingEntry $itk_interior.mbge rejection_gradient_refinement \
	    -type real \
	    -precision 2 \
	    -width 7 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add no_imgs_to_sum_l {
        label $itk_interior.noimsl  -text "Images to sum to find spot centroids (Pilatus or Eiger only): "  -anchor w
    }

    itk_component add no_imgs_to_sum_e {
        SettingEntry $itk_interior.noimse no_imgs_summed \
	    -balloonhelp "Enter the number of images that will be summed to determine spot centroids" \
	    -type int \
	    -minimum 1 \
	    -maximum 100 \
	    -width 7 \
	    -justify right
    }

    itk_component add postref_l {
        gSection $itk_interior.postrefl  -text "Postrefinement "
    }

    itk_component add postref_refl_int_thresh_l {
        label $itk_interior.pritl  -text "Threshold for using reflections (I/sigma):"  -anchor w
    }

    itk_component add postref_refl_int_thresh_e {
        SettingEntry $itk_interior.prite postref_refl_intensity_thresh \
	    -balloonhelp "Only reflections with intensity greater than this will be used in postrefinement" \
	    -type int \
	    -minimum 0 \
	    -maximum 10000 \
	    -width 7 \
	    -justify right
    }

    itk_component add postref_refl_count_thresh_l {
        label $itk_interior.prctl  -text "Minimum number of reflections for refinement:"  -anchor w
    }

    itk_component add postref_refl_count_thresh_e {
        SettingEntry $itk_interior.prcte postref_refl_count_thresh \
	    -balloonhelp "Postrefinement will only be carried out if there are more usable reflections than this" \
	    -type int \
	    -width 7 \
	    -minimum 4 \
	    -maximum 10000 \
	    -justify right
    }

    itk_component add mosaic_safety_l {
        label $itk_interior.msl  -text "Mosaic spread safety factor:"  -anchor w
    }

    itk_component add mosaic_safety_e {
        SettingEntry $itk_interior.mse mosaic_safety_factor \
	    -type real \
	    -precision 2 \
	    -minimum 0 \
	    -width 7 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add images_mosaic_smooth_l {
        label $itk_interior.imsl  -text "Images used to smooth mosaic spread:"  -anchor w
    }

    itk_component add images_mosaic_smooth_e {
        SettingEntry $itk_interior.imse images_mosaic_smooth \
	    -type int \
	    -width 7 \
	    -minimum 0 \
	    -balloonhelp " " \
	    -justify right
    }

    


    itk_component add postrefpartnl {
        label $itk_interior.prptl \
	    -text "Size of smaller fraction of summed partials:" \
	    -anchor w
    }

    itk_component add postrefpartne {
	SettingEntry $itk_interior.prpte smaller_partials_fraction \
	    -type real \
	    -width 7 \
	    -minimum 0.2 \
	    -maximum 0.5 \
	    -balloonhelp " " \
	    -justify right
    }

	itk_component add smooth_refined_missets_l {
   	label $itk_interior.srml  -text "Smooth refined mis-setting angles "  -anchor w
    }
    itk_component add smooth_refined_missets_check {
        SettingCheckbutton $itk_interior.srme smooth_refined_missets \
	    -text "" 
    }

##

    itk_component add pattmat_l {
        gSection $itk_interior.pm_sect  -text "Pattern matching orientation refinement "
    }

    itk_component add pattmat_c {
	checkbutton $itk_interior.pm_check \
	    -variable [scope pattern_matching_bool] \
	    -text "Refine orientation of first image in any run by pattern matching" \
       -command [code $this togglePatternMatch]
    }

    itk_component add pattmat_cr {
	checkbutton $itk_interior.pm_checkr -text "Integrate all images specified after refining orientation of first image" \
	-variable [scope pattern_refine_bool]
	#command [code $this togglePatternRefine]
    }

    itk_component add pattmatreslinit_l {
        label $itk_interior.pm_reslinit_l  -text "Initial resolution limit:"  -anchor w
    }

    itk_component add pattmatreslinit_e {
        SettingEntry $itk_interior.pm_reslinit_e pm_resinit \
	    -balloonhelp "Initial resolution limit" \
	    -type real \
	    -width 7 \
	    -justify right
    }

    itk_component add pattmatreslfinal_l {
        label $itk_interior.pm_reslfinal_l  -text "Final resolution limit:"  -anchor w
    }

    itk_component add pattmatreslfinal_e {
        SettingEntry $itk_interior.pm_reslfinal_e pm_resfinl \
	    -balloonhelp "Final resolution limit" \
	    -type real \
	    -width 7 \
	    -justify right
    }

    itk_component add pattmatradconv_l {
        label $itk_interior.pm_radconv_l  -text "Radius of convergence(degrees):"  -anchor w
    }

    itk_component add pattmatradconv_e {
        SettingEntry $itk_interior.pm_radconv_e pm_radconv \
	    -balloonhelp "Radius of convergence in degrees" \
	    -type real \
	    -width 7 \
	    -justify right
    }

    itk_component add pattmatreflcountthr_l {
        label $itk_interior.pm_rrctl  -text "Minimum number of reflections:"  -anchor w
    }

    itk_component add pattmatreflcountthr_e {
        SettingEntry $itk_interior.pm_rrcte pm_refl_count_thresh \
	    -balloonhelp "If there are fewer spots found than this in the central region, the processing will fail.\nIf using values less than 10, parameters like tilt,twist,yscale,distance might have to be fixed." \
	    -type int \
	    -minimum 4 \
	    -maximum 200 \
	    -width 7 \
	    -justify right
    }


    # layout ####################################

    set indent 20
    set margin 7

    grid x $itk_component(processing_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(size_central_region_l) - $itk_component(size_central_region_e) x x -sticky w
    grid x x $itk_component(max_weighted_residual_l) - $itk_component(max_weighted_residual_e) x x -sticky w
    grid x x $itk_component(max_number_reflections_l) - $itk_component(max_number_reflections_e) x x -sticky w
    grid x x $itk_component(donot_refine_detector_l) - $itk_component(donot_refine_detector_check) x x -sticky w
    grid x x $itk_component(use_overloads_in_refining_detector_l) - $itk_component(use_overloads_in_refining_detector_check) x x -sticky w
    grid x x $itk_component(smooth_refined_detector_l) - $itk_component(smooth_refined_detector_check) x x -sticky w
    grid x x x $itk_component(number_images_ccom_l)  $itk_component(number_images_ccom_e) x x -sticky w
    grid x x x $itk_component(number_images_other_l)  $itk_component(number_images_other_e) x x -sticky w
    grid x x $itk_component(ref_refl_count_thresh_l) - $itk_component(ref_refl_count_thresh_e) x x -sticky w
    grid x x $itk_component(max_backgr_grad_l) - $itk_component(max_backgr_grad_e) x x -sticky w
    grid x x $itk_component(no_imgs_to_sum_l) - $itk_component(no_imgs_to_sum_e) x x -sticky w

    grid x $itk_component(postref_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(postref_refl_int_thresh_l) - $itk_component(postref_refl_int_thresh_e) x x -sticky w
    grid x x $itk_component(postref_refl_count_thresh_l) - $itk_component(postref_refl_count_thresh_e) x x -sticky w
    grid x x $itk_component(mosaic_safety_l) - $itk_component(mosaic_safety_e) x x -sticky w
    grid x x $itk_component(images_mosaic_smooth_l) - $itk_component(images_mosaic_smooth_e) x x -sticky w
    grid x x $itk_component(postrefpartnl) - $itk_component(postrefpartne) x x -sticky w

    grid x x $itk_component(smooth_refined_missets_l) - $itk_component(smooth_refined_missets_check) x x -sticky w

    grid x $itk_component(pattmat_l) - - - - -sticky we -pady {5 0}
    grid x $itk_component(pattmat_c)   - - - - - -sticky w 
    grid x $itk_component(pattmat_cr)   - - - - - -sticky w 
    grid x x $itk_component(pattmatreslinit_l) - $itk_component(pattmatreslinit_e) x x -sticky w
    grid x x $itk_component(pattmatreslfinal_l) - $itk_component(pattmatreslfinal_e) x x -sticky w
    grid x x $itk_component(pattmatradconv_l) - $itk_component(pattmatradconv_e) x x -sticky w
    grid x x $itk_component(pattmatreflcountthr_l) - $itk_component(pattmatreflcountthr_e) x x -sticky w

    grid columnconfigure $itk_interior 3 -weight 1
    grid columnconfigure $itk_interior {0 5} -minsize $margin 
    grid columnconfigure $itk_interior {1} -minsize $indent
    grid rowconfigure $itk_interior {99} -minsize 7 -weight 1

    eval itk_initialize $args

    # Disable pattern matching entry boxes at the start
    $itk_component(pattmatreslinit_e) configure -state disabled
    $itk_component(pattmatreslfinal_e) configure -state disabled
    $itk_component(pattmatradconv_e) configure -state disabled
    $itk_component(pattmat_cr) configure -state disabled
    $itk_component(pattmatreflcountthr_e) configure -state disabled
}


########################################################################
# Usual config options                                                 #
########################################################################

usual Advancedrefinementsettings { 
   keep -background
   keep -foreground
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -font
   keep -entryfont
}

body Advancedrefinementsettings::toggleProfileOptimise {a_value} {
    if {$a_value == 0} {
	if {[$itk_component(profile_optimise_standard_check) getValue]} {
	    $itk_component(profile_optimise_standard_check) invoke
	}
	$itk_component(profile_optimise_standard_check) configure -state disabled
    } else {
	$itk_component(profile_optimise_standard_check) configure -state normal
    }
}

body Advancedrefinementsettings::togglePatternMatch {} {
    if {$pattern_matching_bool == 0} {
	$itk_component(pattmatreslinit_e) configure -state disabled
	$itk_component(pattmatreslfinal_e) configure -state disabled
	$itk_component(pattmatradconv_e) configure -state disabled
	$itk_component(pattmat_cr) configure -state disabled
	$itk_component(pattmatreflcountthr_e) configure -state disabled
    } else {
	$itk_component(pattmatreslinit_e) configure -state normal
	set hr_set [$::session getParameterValue high_resolution_limit]
	if { $hr_set > 0 } {
	    if { $hr_set < [$::session getParameterValue pm_resfinl] } {
		$::session updateSetting pm_resfinl $hr_set 1 1 "User"
		puts "High resolution limit is $hr_set here is [$::session getParameterValue pm_resfinl]"
	    }
	}
	$itk_component(pattmatreslfinal_e) configure -state normal
	$itk_component(pattmatradconv_e) configure -state normal
	$itk_component(pattmat_cr) configure -state normal
	$itk_component(pattmatreflcountthr_e) configure -state normal
    }
}

body Advancedrefinementsettings::getPatternMatchingBool { } {
    return $pattern_matching_bool
}

body Advancedrefinementsettings::getPatternRefineBool { } {
    return $pattern_refine_bool
}
