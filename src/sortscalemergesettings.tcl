# $Id: sortscalemergesettings.tcl,v 1.26 2021/04/22 11:57:59 andrew Exp $
# package name
package provide sortscalemergesettings 1.0

# Class
class SortScaleMergesettings {
    inherit itk::Widget Settings2

    # variables
    ###########
    private variable use_scala "0"
    private variable use_truncate "0"
    private variable output_unmerged "1"
    private variable pnt_mtz_files ""
    private variable pnt_mtz_dir ""

    # methods
    #########
    public method getUseScalaBool
    public method setUseScalaBool
    public method getUseTrnctBool
    public method getOutputUnmergedBool
    public method setOutputUnmergedBool
    public method getPointlessMTZfiles
    public method getPointlessMTZdirectory
    private method selectHKLREFfile
    private method clearOutputIdentifier
    private method browseMTZfiles
    private method clearMTZfiles
    private method getMTZFilename
    private method resetBatchExcl
    private method resetResLimits

    # widget callbacks

    public method debug

    constructor { args } { }

}

# Bodies

body SortScaleMergesettings::debug { a_val } {
}

body SortScaleMergesettings::constructor { args } {
    itk_component add pntls_only_l {
        gSection $itk_interior.pntlsonlyl  -text "Pointless options "
    }

    itk_component add hklref_file_l {
	label $itk_interior.hklfl -text "HKLREF file: "
    }
    itk_component add hklref_file_e {
        SettingEntry $itk_interior.hklfe pnt_hklref_file \
	    -balloonhelp "Supply the name of the MTZ file to be used as a reference\n \
			    for testing alternative indexing schemes (if required)" \
	    -image ::img::mtz_file16x16
    }

    itk_component add hklref_file_browse {
	button $itk_interior.hklfb \
	    -text "Browse" \
	    -width 7 \
	    -command [code $this selectHKLREFfile] 
    }

    itk_component add feckless_prep_l {
   	label $itk_interior.usefeckprep -text "Treat multi-lattice MTZ files with Feckless "  -anchor w
    }

    itk_component add feckless_prep_check {
        SettingCheckbutton $itk_interior.feckprepc use_feckless_prep \
	    -text ""
    }

    itk_component add ssm_mtz_files_l {
        gSection $itk_interior.psmtzfilesl -text "Pointless, Aimless/Scala & Truncate MTZ output identifier "
    }

    itk_component add ssm_mtz_ident_l {
	label $itk_interior.mkl -text "<program_name>_"
    }
    itk_component add ssm_mtz_ident_e {
	# Sort, scale & merge run file identifier
        SettingEntry $itk_interior.mke ssm_mtz_file \
	    -balloonhelp "This label will be used in the names of the output MTZ \
			files\n from this run of the sort, scale & merge program, for example\n \
        pointless_test_001.mtz \naimless_test_001.mtz \netc.\n \
                                If you enter an identifier, but still want distinct filenames\n \
                                for different integration runs you must give a different identifier\n \
                                for each run otherwise the MTZ files will be overwritten." \
	    -width 20
    }
    itk_component add ssm_mtz_ident_clear {
	button $itk_interior.mkc \
	    -text "Clear" \
	    -command [code $this clearOutputIdentifier]
    }


    itk_component add pntls_scala_l {
        gSection $itk_interior.pntlscalal -text "Pointless, Aimless/Scala, Truncate & Uniqueify switches "
    }

    itk_component add use_scala_l {
   	label $itk_interior.usescala -text "Use Scala NOT Aimless in QuickScale option "  -anchor w
    }

    itk_component add use_scala_check {
	gcheckbutton $itk_interior.usescalac -variable [scope use_scala]
    }

    itk_component add use_truncate_l {
   	label $itk_interior.usetruncate -text "Use Truncate NOT Ctruncate in QuickScale option "  -anchor w
    }

    itk_component add use_truncate_check {
	gcheckbutton $itk_interior.usetruncatec -variable [scope use_truncate]
    }

    itk_component add mosflm_symmetry_l {
   	label $itk_interior.usemossymm -text "Use iMosflm symmetry in QuickScale option "  -anchor w
    }

    itk_component add mosflm_symmetry_check {
        SettingCheckbutton $itk_interior.mossymmc use_mosflm_symmetry \
	    -text ""
    }

    itk_component add anomalous_data_l {
   	label $itk_interior.trtanomdat -text "Treat anomalous data in QuickScale option "  -anchor w
    }

    itk_component add anomalous_data_check {
        SettingCheckbutton $itk_interior.anomdatac treat_anomalous_data \
	    -text ""
    }

    itk_component add output_unmerged_l {
   	label $itk_interior.outunmerged -text "Output unmerged observations from Aimless "  -anchor w
    }

    itk_component add output_unmerged_check {
	gcheckbutton $itk_interior.outunmergedc -variable [scope output_unmerged]
    }

    itk_component add rfree_frac_l {
	label $itk_interior.rfreefrl \
	    -text "Fraction of reflections to be tagged with each free-R indicator: "
    }

    itk_component add rfree_frac_e {
        SettingEntry $itk_interior.rfreefre uq_rfree_frac \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -justify right
    }

    itk_component add multiple_mtz_l {
        gSection $itk_interior.myltimtzl  -text "Multiple MTZ files "
    }

    itk_component add buttons_frame {
	frame $itk_interior.bf
    }

    itk_component add mtz_browse {
	button $itk_interior.bf.mfb \
	    -text "Browse" \
	    -command [code $this browseMTZfiles]
    }

    itk_component add mtz_clear {
	button $itk_interior.bf.mfc \
	    -text "Clear" \
	    -command [code $this clearMTZfiles]
    }

    itk_component add mtzfiles_frame {
	frame $itk_interior.mf
    }

    itk_component add mtzfiles_box {
	listbox $itk_interior.mf.lb \
	    -width 42 \
	    -height 5
    } {
	rename -background -textbackground textBackground Background
	rename -font -entryfont entryFont Font
    }

    itk_component add mtzfiles_scroll {
	scrollbar $itk_interior.mf.scroll \
	    -command [list $itk_component(mtzfiles_box) yview] \
	    -orient vertical
    }
    
    $itk_component(mtzfiles_box) configure \
	-yscrollcommand [list autoscroll $itk_component(mtzfiles_scroll)]

    itk_component add aimls_opts_l {
        gSection $itk_interior.aimlsoptsl  -text "Aimless/Scala parameters "
    }

    itk_component add reslimits_reset {
	button $itk_interior.amrlr \
	    -text "Clear both" \
	    -command [code $this resetResLimits] 
    }

    itk_component add aimls_max_res_l {
	label $itk_interior.maxrl \
	    -text "High resolution limit: "
    }

    itk_component add aimls_max_res_e {
        SettingEntry $itk_interior.maxre aimls_high_res_lim \
	    -image ::img::max_res16x16 \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add aimls_min_res_l {
	label $itk_interior.minrl \
	    -text "Low resolution limit: "
    }

    itk_component add aimls_min_res_e {
        SettingEntry $itk_interior.minre aimls_low_res_lim \
	    -image ::img::min_res16x16 \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add aimlsbatchexcl_l {
	label $itk_interior.abel -text "Numbers to exclude: "
    }
    itk_component add aimlsbatchexcl_e {
        SettingEntry $itk_interior.abee aimls_batch_excl \
	    -balloonhelp "Give a list of batch numbers"
    }

    itk_component add aimlsrangeexcl_l {
	label $itk_interior.abrl -text "Ranges to exclude: "
    }
    itk_component add aimlsrangeexcl_e {
        SettingEntry $itk_interior.abre aimls_range_excl \
	    -balloonhelp "Give a comma-separated list of batch\n\
	    ranges e.g. 12-14, 54-58, etc."
    }

    itk_component add batchexcl_reset {
	button $itk_interior.amrsb \
	    -text "Clear both" \
	    -command [code $this resetBatchExcl] 
    }

    itk_component add spacing_scales_l {
	label $itk_interior.spcscl \
	    -text "Spacing for scale factors (degrees): "
    }

    itk_component add spacing_scales_e {
        SettingEntry $itk_interior.spcsce scale_factor_spacing \
	    -type integer \
	    -width 3 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add spacing_Bs_l {
	label $itk_interior.spcBl \
	    -text "Spacing for B factors (degrees): "
    }

    itk_component add spacing_Bs_e {
        SettingEntry $itk_interior.spcBe B_factor_spacing \
	    -type integer \
	    -width 3 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add profoverl_l {
   	label $itk_interior.profoverlt -text "Accept profile fitted estimate of overloaded reflections "  -anchor w
    }

    itk_component add profoverl_check {
        SettingCheckbutton $itk_interior.profoverlc keep_overloaded \
	    -text ""
    }

    itk_component add part_frac_l {
	label $itk_interior.prtfrl \
	    -text "Accept partials with total fraction between (lower limit): "
    }

    itk_component add part_frac_low_e {
        SettingEntry $itk_interior.prtfrle part_frac_low \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add part_frac_l1 {
	label $itk_interior.prtfrl1 \
	    -text "and (upper limit): "
    }

    itk_component add part_frac_high_e {
        SettingEntry $itk_interior.prtfrhe part_frac_high \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -balloonhelp " " \
	    -justify right
    }

    itk_component add outl_sigma_l {
	label $itk_interior.outsgl \
	    -text "Outlier sigma rejection cutoff: "
    }

    itk_component add outl_sigma_e {
        SettingEntry $itk_interior.outsge outl_sig_cutoff \
	    -balloonhelp "Reject outliers deviating more than N sigma from the mean" \
	    -type real \
	    -precision 2 \
	    -width 5 \
	    -justify right
    }

    itk_component add same_SD_allruns_l {
	label $itk_interior.sameSDallrunsl \
	    -text "Apply same SD correction parameters to all runs"
    }

    itk_component add same_SD_allruns_check {
        SettingCheckbutton $itk_interior.sameSDallc sameSDall \
	    -text ""
    }

    itk_component add set_SDB_term0_l {
	label $itk_interior.setSDBterm0l \
	    -text "Set SDB term of SD correction to zero"
    }

    itk_component add set_SDB_term0_check {
        SettingCheckbutton $itk_interior.setSDBterm0c setSDBterm0 \
	    -text ""
    }

    # layout ####################################

    set indent 20
    set margin 7

    grid x $itk_component(pntls_only_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(hklref_file_l) $itk_component(hklref_file_e) $itk_component(hklref_file_browse) x x -sticky we
    grid x x $itk_component(feckless_prep_l) - $itk_component(feckless_prep_check) x x -sticky w
    
    grid x $itk_component(ssm_mtz_files_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(ssm_mtz_ident_l) $itk_component(ssm_mtz_ident_e) $itk_component(ssm_mtz_ident_clear)  x -sticky we

    grid x $itk_component(pntls_scala_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(use_scala_l) - $itk_component(use_scala_check) x x -sticky w
    grid x x $itk_component(use_truncate_l) - $itk_component(use_truncate_check) x x -sticky w
    grid x x $itk_component(mosflm_symmetry_l) - $itk_component(mosflm_symmetry_check) x x -sticky w
    grid x x $itk_component(anomalous_data_l) - $itk_component(anomalous_data_check) x x -sticky w
    grid x x $itk_component(output_unmerged_l) - $itk_component(output_unmerged_check) x x -sticky w
    grid x x $itk_component(rfree_frac_l) - $itk_component(rfree_frac_e) x x -sticky w
    
    grid x $itk_component(multiple_mtz_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(buttons_frame) $itk_component(mtzfiles_frame) - - - -sticky we -pady {5 0}
    grid x x $itk_component(mtzfiles_box) $itk_component(mtzfiles_scroll) -sticky nsew
    grid x x $itk_component(mtz_browse) -sticky we
    grid x x $itk_component(mtz_clear) -sticky we
    
    grid x $itk_component(aimls_opts_l) - - - - -sticky we -pady {5 0}
    grid x x $itk_component(aimls_max_res_l) - $itk_component(aimls_max_res_e) x x -sticky w
    grid x x $itk_component(aimls_min_res_l) $itk_component(reslimits_reset) $itk_component(aimls_min_res_e) x x -sticky w
    grid x x $itk_component(aimlsbatchexcl_l) $itk_component(aimlsbatchexcl_e) x x -sticky we 
    grid x x $itk_component(aimlsrangeexcl_l) $itk_component(aimlsrangeexcl_e) $itk_component(batchexcl_reset) x -sticky we 
    grid x x $itk_component(spacing_scales_l) - $itk_component(spacing_scales_e) x x -sticky w
    grid x x $itk_component(spacing_Bs_l) - $itk_component(spacing_Bs_e) x x -sticky w
    grid x x $itk_component(profoverl_l) - $itk_component(profoverl_check) x x -sticky w
    grid x x $itk_component(part_frac_l) - $itk_component(part_frac_low_e) x x -sticky w
    grid x x $itk_component(part_frac_l1) - $itk_component(part_frac_high_e) x x -sticky w
    grid x x $itk_component(outl_sigma_l) - $itk_component(outl_sigma_e) x x -sticky w
    grid x x $itk_component(same_SD_allruns_l) - $itk_component(same_SD_allruns_check) x x -sticky w
    grid x x $itk_component(set_SDB_term0_l) - $itk_component(set_SDB_term0_check) x x -sticky w

    grid columnconfigure $itk_interior 3 -weight 1
    grid columnconfigure $itk_interior {0 5} -minsize $margin 
    grid columnconfigure $itk_interior {1} -minsize $indent
    grid rowconfigure $itk_interior {99} -minsize 7 -weight 1

    eval itk_initialize $args

}


########################################################################
# Usual config options                                                 #
########################################################################

usual SortScaleMergesettings { 
   keep -background
   keep -foreground
   keep -font
   keep -selectbackground
   keep -selectforeground
   keep -textbackground
   keep -entryfont
}

body SortScaleMergesettings::getUseScalaBool { } {
    return $use_scala
}

body SortScaleMergesettings::setUseScalaBool { a_value } {
    set use_scala $a_value
}

body SortScaleMergesettings::getOutputUnmergedBool { } {
    return $output_unmerged
}

body SortScaleMergesettings::setOutputUnmergedBool { a_value } {
    set output_unmerged $a_value
}

body SortScaleMergesettings::getUseTrnctBool { } {
    return $use_truncate
}

body SortScaleMergesettings::getPointlessMTZfiles { } {
    return $pnt_mtz_files
}

body SortScaleMergesettings::getPointlessMTZdirectory { } {
    return $pnt_mtz_dir
}

body SortScaleMergesettings::selectHKLREFfile { args } {
    set filechosen [getMTZFilename open]
    if { $filechosen ne "" } {
	# Directory path prepended to first file returned
	set pnt_hklref_file [file tail $filechosen]
	$::session updateSetting "pnt_hklref_file" $pnt_hklref_file 1 1
	set pnt_hklref_dir [file dirname $filechosen]
	$::session updateSetting "pnt_hklref_dir" $pnt_hklref_dir 1 1
    }
}

body SortScaleMergesettings::clearOutputIdentifier { } {
    $::session updateSetting "ssm_mtz_file" "" 1 1    
}

body SortScaleMergesettings::browseMTZfiles { args } {
    set filechosen [getMTZFilename image_open]
    if { $filechosen ne "" } {
	$itk_component(mtzfiles_box) delete 0 end
	# Directory path prepended to first file returned
	set pnt_mtz_files [file tail $filechosen]
	set pnt_mtz_dir [file dirname $filechosen]
	# File name could be one or more file names
	foreach file [split $pnt_mtz_files] {
	    $itk_component(mtzfiles_box) insert end $file
	}
    }
}

body SortScaleMergesettings::clearMTZfiles { args } {
    $itk_component(mtzfiles_box) delete 0 end
    set pnt_mtz_files ""
    set pnt_mtz_dir ""
}

body SortScaleMergesettings::getMTZFilename { type } {
    # Recreate Strategy file dialog of correct $type (open or save)
    catch {destroy .fileMTZ}
    Fileopen .fileMTZ  \
	-title "Choose MTZ file(s)" \
	-type $type \
	-initialdir [pwd] \
	-filtertypes {{"MTZ files" {.mtz}} {"All Files" {.*}}}
    # Get the user to pick a new filename and location (as full path)
    return [.fileMTZ get]
}

body SortScaleMergesettings::resetBatchExcl { } {
    $::session updateSetting aimls_batch_excl "" 1 1
    $::session updateSetting aimls_range_excl "" 1 1
}

body SortScaleMergesettings::resetResLimits { } {
    $::session updateSetting aimls_high_res_lim "" 1 1
    $::session updateSetting aimls_low_res_lim "" 1 1
}
