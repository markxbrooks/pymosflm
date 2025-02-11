# $Id: session.tcl,v 1.303 2021/08/26 09:13:04 andrew Exp $
# package name
package provide session 1.0

####################################################################
# Class Session                                                    #
####################################################################
class Session {
    inherit Tree

    # variables
    ###########
    
    # Session parameters
    private variable data ""

    public variable name "New Session"
    # Name for temporary session file
    private variable session_file ""
    # Name for user Save file
    private variable saved_file ""
    private variable saved_file_read "0"
    private variable hdf5_master ""
    private variable count "0"
    private variable queued_save ""
    private variable sitefileread ""
    private variable sitefilewritten ""
    private variable integration_done "0"

    private variable ccp4i2files ; # NB array - don't initialize

    private variable crashed "0"

    private variable warnings {}
    private variable spatial_overlaps {}
    private variable lattice_overlaps {}

    private variable history ""

    private variable cellbeenedited ; # NB array - don't initialize
    private variable cellbeenwarned ; # NB array - don't initialize

    public variable project "New Project"
    public variable crystal "New Crystal"
    public variable dataset "New Dataset"
    private variable title "Untitled"

    # Interface variables
    private variable visual_session_trees ""

    # Image loading variables
    private variable indexing_list {}
    private variable globbed_images {}
    private variable firstglobimage ""
    private variable firstimagematching ""
    private variable images_last_indexed {}
# HRP 22022018 for HDF5
    private variable image_template ""
    private variable image_number ""
    private variable total_images ""
    private variable oscrange "360"

    # This is switched ON if a file name is passed to newSession
    private variable addmultipleimagefiles "0"
    private variable addsingleimagefile "0"

    # Experiment settings
    private variable origin ""
    private variable axis_order ""
    private variable two_theta_direction ""

    # Lookup to store values read from site file
    private variable sitesetting ; # NB array - don't initialize
    # Should site parameters read from file override later values read from image header
    private variable siteoverride "0"

    # Flag to store if initial crystal & detector parameters have been saved in this session
    private variable savedXDparams "0"

    # Flag the last image number where the user edited the beam
    private variable beamEditedImage "0"

    private variable xray_source "synchrotron"
    private variable beam_x ""
    private variable beam_y ""
    private variable beam_y_corrected ""
    private variable distance ""
    private variable divergence_x "0.02"
    private variable divergence_y "0.02"
    private variable dispersion "0.0002"
    private variable polarization "0.95"
    private variable two_theta "0.00"
    private variable rad_two_theta "0.00"
    private variable yscale "1.0000"
    private variable gain "1.00"
    private variable bias "0"
    private variable adcoffset ""
    private variable pixel_size ""
    private variable header_size ""
    private variable tilt "0"
    private variable twist "0"
    private variable tangential_offset "0.00"
    private variable radial_offset "0.00"
    private variable ccomega "0.00"
    private variable wavelength "1.541"

    private variable header_beam_x ""
    private variable header_beam_y ""
    private variable beamstop_radius ""
    private variable detector_manufacturer ""
    private variable detector_manufacturer_extra ""
    private variable display_manufacturer ""
    private variable detector_omega "0"
    private variable detector_rowreadt ""
    private variable detector_rotnspeed ""
    private variable detector_model ""
    private variable detector_serno ""
    private variable spiral "$::env(SPIRAL)"
    private variable invertx ""
    private variable image_height ""
    private variable image_width ""
    # new items from Harry, starting 19.03.2007
    private variable this_detector_information ""
    private variable reverse_phi "0"
    private variable trusted_detector "1"
    private variable phi_correct_in_header "1"
    private variable limits_xmin ""
    private variable limits_xmax ""
    private variable limits_xscan ""
    private variable limits_ymin ""
    private variable limits_ymax ""
    private variable limits_yscan ""
    private variable limits_rmin ""
    private variable limits_rmax ""
    private variable limits_rscan ""

    private variable backstop_x ""
    private variable backstop_y ""
    private variable backstop_radius "5.00"

    private variable current_resolution ""
    
    private variable cell ""
    private variable spacegroup ""

    private variable mosaicity "0.00"
    private variable mosaicblock "100"

    private variable psi_x "0.00"
    private variable psi_y "0.00"
    private variable psi_z "0.00"

    private variable bgratio "3.0"
    private variable pkratio "3.5"
    private variable rejection_gradient_integration "0.03"
    private variable rejection_gradient_refinement  "0.03"
    private variable smaller_partials_fraction "0.25"

    private variable pm_resinit "6.0"
    private variable pm_resfinl "4.0"
    private variable pm_radconv "1.0"
    private variable pm_refl_count_thresh "12"
    private variable pickbox_size_x "11"
    private variable pickbox_size_y "11"

    private variable size_central_region ""
    private variable max_weighted_residual "10.0"
    private variable max_number_reflections "200"
    private variable donot_refine_detector "0"
    private variable smooth_refined_detector "1"
    private variable smooth_refined_missets "0"
    private variable use_overloads_in_refining_detector "0"
    private variable use_overloads_in_refining_detector_is_set "0"
    private variable nsm1 "5"
    private variable nsm2 "10"

    # Spotfinding settings
    private variable nsum_pil_spf "1"
    private variable nsum_pil_ref "1"
    private variable search_area_min_radius "0.00"
    private variable search_area_max_radius "0.00"
    private variable exclusion_segment_horizontal "0.00"
    private variable exclusion_segment_vertical "0.00"
    private variable threshold "5.00"
    private variable bbox_orientation "North"
    private variable bbox_offset "0.00"
    private variable minpix "6"
    private variable spot_size_min_x "0.50"
    private variable spot_size_min_y "0.50"
    private variable spot_size_max_x "10.00"
    private variable spot_size_max_y "10.00"
    private variable spot_separation_x "0.00"
    private variable spot_separation_y "0.00"
    private variable fix_separation "0"
    private variable separation_close "1"
    private variable spot_splitting_x "0.00"
    private variable spot_splitting_y "0.00"

    private variable background_box_offset_x ""
    private variable background_box_offset_y ""

    private variable local_background "1"
    private variable local_background_box_size_x "16"
    private variable local_background_box_size_y "16"
    private variable max_unresolved_peaks "30"

    private variable auto_resolution "1"
    private variable auto_ring "1"
    private variable spot_rms_var "3.0"
    private variable spot_anisotropy "5.0"

    # Indexing settings
    private variable exclude_ice "1"
    private variable exclude_auto "0"
    private variable fix_distance_indexing "1"
    private variable fix_cell_indexing "0"
    private variable fix_max_cell_edge "0"
    private variable max_cell_edge ""
    private variable sigma_cutoff "2.50"
    private variable i_sig_i "20"
    private variable auto_thresh_indexing "1"
    private variable auto_thresh_value "20"
    private variable i_sig_i_delta "50"

    private variable hkldev_max "0.300"
    private variable numvectors "30"

    private variable beamsearch_stepsize "0.50"
    private variable beamsearch_stepnumx "2"
    private variable beamsearch_stepnumy "2"

    # Multiple lattice indexing
    private variable find_multiple_lattices "0"
    public variable total_lattices "1"
    public variable current_lattice "1"
    private variable lattice_numbers {} ; # NB list of lattice numbers
    private variable pathToLatticeTab ; # NB array - don't initialize

    # Multiple lattice processing results objects
    private variable results_cell_refinement ; # NB array - don't initialize
    private variable results_integration ; # NB array - don't initialize

    # Strategy settings
    private variable anomalous "0"

    # Processing settings
    private variable low_resolution_limit ""
    private variable high_resolution_limit ""
    private variable estimated_high_resolution_limit ""
    private variable aniso_res_a ""
    private variable aniso_res_b ""
    private variable aniso_res_c ""
    private variable space_group ""
    private variable resolution_cutoff ""
    private variable excl_res_rng ""
    private variable view_predictions_during_processing "0"
    private variable resolution_exclude_ice "0"

    private variable nullpix "0"
    private variable raster_nxs ""
    private variable raster_nys ""
    private variable raster_nc ""
    private variable raster_nrx ""
    private variable raster_nry ""
    private variable max_refl_width "5"
    private variable postref_refl_intensity_thresh "3"
    private variable postref_refl_count_thresh "10"
    private variable ref_refl_count_thresh "20"
    private variable no_imgs_summed "1"
    private variable profile_tolerance_min "0.02"
    private variable profile_tolerance_max "0.03"
    private variable optimise_profile_tolerance "1"
    private variable profile_refl_count_av_thresh "10"
    private variable profile_rmsbg_thresh "20"
    private variable overload_cutoff ""
    private variable profile_overload_cutoff ""
    private variable threshold_spot_inclusion "2"

    private variable mosaic_safety_factor "0.05"
    private variable images_mosaic_smooth "10"

    private variable profile_optimise_central "1"
    private variable profile_optimise_standard "1"
    private variable optimise_box_size "1"

    private variable mtz_overwrite "0"

    # Outlier exclusion
    private variable ice_ring_width "0.005"
    private variable prcutval "0.05"
    private variable excl_near_ice "1"

    # Flags for Pointless & Scala
    private variable pnt_hklref_file ""
    private variable pnt_hklref_dir ""
    private variable use_feckless_prep "1"
    private variable ssm_mtz_file ""
    private variable use_mosflm_symmetry "0"
    private variable treat_anomalous_data "1"
    private variable uq_rfree_frac "0.05"
    private variable aimls_high_res_lim ""
    private variable aimls_low_res_lim ""
    private variable aimls_batch_excl ""
    private variable aimls_range_excl ""
    private variable scale_factor_spacing "5"
    private variable B_factor_spacing "20"
    private variable keep_overloaded "0"
    private variable part_frac_low "0.95"
    private variable part_frac_high "1.05"
    private variable outl_sig_cutoff "6.0"
    private variable sameSDall "0"
    private variable setSDBterm0 "0"

    # Integration settings
    private variable numberOfCores "0"
    private variable maxNumberOfCores "0"
    private variable thisBatchSize "0"
    private variable totalBatchSize "0"
    private variable blockrefine_yesno "1"
    private variable uselastbatch_yesno "1"
    private variable showgraphs_yesno "1"
    private variable showrefine_yesno "0"
    private variable automatch_yesno "0"
    #hrp 17.11.2006 currentSector added
    private variable currentSector ""
    private variable block_size ""
    private variable auto_update_mtz "1"
    private variable mtz_file ""
    private variable mtz_directory ""
    private variable batch_number ""

    private variable cell_refinement_fix_beam "0"
    private variable cell_refinement_fix_distance "0"
    private variable cell_refinement_fix_yscale "0"
    private variable cell_refinement_fix_tilt "0"
    private variable cell_refinement_fix_twist "0"
    private variable cell_refinement_fix_radial_offset "0"
    private variable cell_refinement_fix_tangential_offset "0"
    private variable cell_refinement_fix_ccomega "0"

    private variable cell_refinement_postrefinement_check "1"
    private variable cell_refinement_fix_cell_a "0"
    private variable cell_refinement_fix_cell_b "0"
    private variable cell_refinement_fix_cell_c "0"
    private variable cell_refinement_fix_cell_alpha "0"
    private variable cell_refinement_fix_cell_beta "0"
    private variable cell_refinement_fix_cell_gamma "0"
    private variable cell_refinement_fix_mosaicity "0"

    private variable integration_fix_beam "0"
    private variable integration_fix_distance "0"
    private variable integration_fix_yscale "0"
    private variable integration_fix_tilt "0"
    private variable integration_fix_twist "0"
    private variable integration_fix_radial_offset "0"
    private variable integration_fix_tangential_offset "0"
    private variable integration_fix_ccomega "0"

    private variable integration_postrefinement_check "1"
    private variable integration_fix_cell_a "1"
    private variable integration_fix_cell_b "1"
    private variable integration_fix_cell_c "1"
    private variable integration_fix_cell_alpha "1"
    private variable integration_fix_cell_beta "1"
    private variable integration_fix_cell_gamma "1"
    private variable integration_fix_mosaicity "0"

    private variable wait_length "0"
    private variable wait_activation "0"

    private variable multiple_mtz_files "0"
    private variable pointless_live "0"
    private variable initial_detect_param ; # NB array - don't initialize

    # HRP 03052018 variables for summing images for processing from HDF5 files

    private variable auto_sum_images "0"
    private variable sum_n_images "1"
    private variable sum_n_images_changed "0"

    # environment variables
    private variable mosflm_exec ""
    private variable web_browser ""
    private variable ccp4_bin ""
    private variable mosdir ""
    private variable mosflm_logging ""
    
    private variable n_ps_logfiles "0"
    # For phi profile
    private variable restrict_resolution "0"
    private variable imgpad "0"

    # methods
    #########

    # Special method for debugging
    public method tracker
    public method hack
    public method getMosflmLogging

    # Session creating/saving/copying methods
    public method isSaved
    public method isHdf5
    public method setHdf5
#    public method setSessionFileRead
    public method getSessionFileRead
    public method getSiteFileRead
    public method setSiteFileRead
    public method getSiteFileWritten
    public method setSiteFileWritten
    public method getIntegrationDone
    public method setIntegrationDone
    public method getFilename
    public method initializeFromFile
    public method readFromSiteFile
    public method serialize
    public method writeToFile
    public method createTempFile
    public method doQueuedWrite
    public method addCCP4i2file
    public method writeCCP4i2list

    # Warning methods
    public method generateWarning
    public method deleteWarning
    public method parseWarnings
    public method parseInfoAndWarnings
    public method processInterfaceInputResponse

    # Image/sector configuration methods
    public method addImage
    public method setIndexingList
    public method getIndexingList
    public method getglobbedImages
    private method loadglobbedImages
    public method loadglobbedHeaders
    private method addNextImage
    private method addImageList
    public method addNewSector
    public method addSector
    public method getSectors
    public method getSectorByTemplate
    public method getSectorByMatrix
    public method deleteSector
# hrp 17.11.2006 added to pass current sector about - it may be possible to use 
# getSectorByTemplate, but I haven't figured out how this can be done.
    public method getCurrentSector
    public method setCurrentSector

    public method getImages
    public method getImagesLastIndexed
    public method getmatchingSector
    public method getImageByName
    public method getImageByTemplateAndNumber
    public method getImageByNumber
    public method getImageByPhi
    public method getImageTemplate

    public method deleteImages

    public method setMultipleImageFiles
    public method setSingleImageFile

    public method getSpatialOverlaps
    public method getLatticeOverlaps

    public method writeImageList
# methods for popup at start after HDF5 images read in and 
# phi range < 0.2degrees
    public method reportOscRange

    # General setting query
    public method getParameterValue
# for setting values from elsewhere - only used for chunking (HRP 11.05.2018)
    public method setParameterValue

    # Experiment settings methods
    public method beamIsSet
    public method getBeamPosition
    public method getHeaderBeamPosition
    public method processExperimentData
    public method processHeaderData
    private method isLabSource
    public method processBriefHeaderData
    public method processWaitBriefHeaderData
    public method setBeamToImageCentre
    public method forceOscangSetting
    public method forceBeamSetting
    public method forceDistanceSetting
    public method distanceIsSet
    public method getDistance
    public method forcePixelSizeSetting
    public method getWavelength
    public method getHighResolution
    public method getTwoTheta
    public method getImageHeight
    public method getImageWidth
    public method getDetectorOmega
    public method getInvertX
    public method getReversePhi
    public method getSpiral
    public method setPhiIncorrectInHeader
    public method getPhiCorrectInHeader
    public method getFullDetectorInformation
    public method getDetectorManufacturer
    public method getDetectorModel
    public method forceMosaicityEstimation
    public method mosaicityIsSet
    public method estimateMosaicity

    # Indexing settings methods
    public method getIndexSubcommands
    public method getFixedDistance
    public method getSigmaCutoff
    public method getISigmaI
    public method getISigmaIdelta
    public method getHKLDevMax
    public method getNumVectors
    public method getMultipleLattices
    public method setMultipleLattices
    public method getCurrentLattice
    public method setCurrentLattice
    public method setCurrentCellMatrixSpaceGroup

    # Spotfinding settings methods
    public method initializeSearchRadius
    public method getFindspotsParameters

    # Setting updating methods
    public method updateSetting
    private method querySiteSetting
    public method setInSiteFile
    public method clearInSiteFile
    private method valueInSiteFile
    public method updateSpacegroup
    public method validateCellAndSpacegroup
    public method getXDparamsSaved

    # Backstop commands
    public method getBackstopCommand

    # Resolution methods
    public method calcResolution
    public method thisResolution
    public method reportResolution

    # Prediction methods
    public method predictionPossible
    public method updatePredictions

    public method mosaicityEstimationPossible

    # Indexing results methods
    public method updateCell
    public method getCell
    public method listCell
    public method reportCell
    public method getSpacegroup
    public method getLattice
    public method reportSpacegroup
    public method MatrixIsSet
    public method getNumberLattices
    public method setNumberLattices
    public method parseNumberLattices
    public method getLatticeList
    public method unsetLatticeList
    public method removeLatticeList
    public method appendLatticeList

    # Processing methods
    public method rasterIsValid
    public method getRaster
    public method getParamsRefinedInIntegration
    public method getMTZFilename
    public method setMTZFilename
    public method getMTZDirectory
    public method getHKLREFfile
    public method getHKLREFdirectory
    public method resolutionCommandRequired
    public method getResolutionCommand
    public method getEstimatedResolutionCommand
    public method separationCommandRequired
    public method getSeparationCommand
    public method getProfileCommand
    public method getRefinementCommand
    public method getPostrefinementCommand
    public method processExclResRngs
    public method getMosaicity

    public method setLatticeResultsObject
    public method getLatticeResultsObject

    # History methods
    public method addHistoryEvent
    public method addHistoryEventQuickly
    public method refreshHistory
    public method hasHistoryEvents

    # XML message parsing
    public method processRasterAndSeparation
    public method processGenerateResponse

    # Error handling methods
    public method parseErrors
    public method processFatalError
    public method processTrappedError
    public method setCrashed

    public method setIndexingRelayBool
    public method getIndexingRelayBool
    private variable indexing_relay_bool "0"
    public method setMosaicityRelayBool
    public method getMosaicityRelayBool
    private variable mosaicity_relay_bool "0"
    public method getTilt
    public method getTwist
    public method getTangentialOffset
    public method getRadialOffset

    public method setIntegrationRun
    private variable integration_run "0"
    public method getIntegrationRun
    private variable pmon ""
    public method callPointlessProcess
    public method initialisePMon

    public method setRunningProcessing
    private variable running_integration "0"
    public method getRunningProcessing

    # methods for parallel processing
    public variable listOfXMLFiles {}
    public method clearListOfXMLFiles
    public method appendToListOfXMLFiles
    public method removeFromListOfXMLFiles
    public method getListOfXMLFiles
    public method setShowGraphs
    public method getShowGraphs
    public method setMaxNumberOfCores
    public method updateMaxNumberOfCores
    public method getMaxNumberOfCores
    public method setNumberOfCores
    public method getNumberOfCores
    public method setTotalBatchSize
#    public method getTotalBatchSize
#    public method getBatchSize
#    public method setBatchSize
    public method getBatchSizeFromCores
#    public method getCoresFromBatchSize
#    public method getBatchSizeAndCores
    public method getFirstAndLastImage
    public method getHistory

    public method resetDetector

    public method setCellBeenEdited    

    # Get and set the last image number where the user edited the beam
    public method getBeamEditedImage
    public method setBeamEditedImage


    constructor { args } {
	set pmon [PointlessMonitor \#auto]
	#set indexing_relay_bool "0"
	#set mosaicity_relay_bool "0"

	# Create list of data
	set data [list \
	    saved_file \
            hdf5_master \
            sitefileread \
            sitefilewritten \
	    \
	    project \
	    crystal \
	    dataset \
	    title \
	    \
	    xray_source \
	    beam_x \
	    beam_y \
	    beam_y_corrected \
	    distance \
	    divergence_x \
	    divergence_y \
	    dispersion \
	    polarization \
	    two_theta \
	    rad_two_theta \
	    yscale \
	    gain \
	    bias \
	    adcoffset \
	    tilt \
	    twist \
	    tangential_offset \
	    radial_offset \
	    ccomega \
	    wavelength \
	    \
	    header_beam_x \
	    header_beam_y \
            beamstop_radius \
	    detector_manufacturer \
	    display_manufacturer \
	    detector_omega \
            detector_rowreadt \
            detector_rotnspeed \
	    detector_model \
	    detector_serno \
	    spiral \
	    invertx \
	    trusted_detector \
	    phi_correct_in_header \
	    limits_xmin \
	    limits_xmax \
	    limits_xscan \
	    limits_ymin \
	    limits_ymax \
	    limits_yscan \
	    limits_rmin \
	    limits_rmax \
	    limits_rscan \
	    image_height \
	    image_width \
	    reverse_phi \
	    pixel_size \
	    header_size \
	    \
	    backstop_x \
	    backstop_y \
	    backstop_radius \
	    \
	    psi_x \
	    psi_y \
	    psi_z \
	    mosaicity \
	    mosaicblock \
	    \
	    bgratio \
	    pkratio \
	    rejection_gradient_integration \
	    rejection_gradient_refinement \
	    smaller_partials_fraction \
            \
            pm_resinit \
            pm_resfinl \
            pm_radconv \
            pm_refl_count_thresh \
            \
	    pickbox_size_x \
	    pickbox_size_y \
	    size_central_region \
	    max_weighted_residual \
	    max_number_reflections \
	    donot_refine_detector \
	    smooth_refined_detector \
	    smooth_refined_missets \
	    use_overloads_in_refining_detector \
	    use_overloads_in_refining_detector_is_set \
	    nsm1 \
	    nsm2 \
	    \
            nsum_pil_spf \
            nsum_pil_ref \
            \
	    search_area_min_radius \
	    search_area_max_radius \
	    exclusion_segment_horizontal \
	    exclusion_segment_vertical \
	    threshold \
	    bbox_orientation \
	    bbox_offset \
	    minpix \
	    spot_size_min_x \
	    spot_size_min_y \
	    spot_size_max_x \
	    spot_size_max_y \
	    spot_separation_x \
	    fix_separation \
	    separation_close \
	    spot_separation_y \
	    spot_splitting_x \
	    spot_splitting_y \
	    \
	    background_box_offset_x \
	    background_box_offset_y \
	    \
	    local_background \
	    local_background_box_size_x \
	    local_background_box_size_y \
	    max_unresolved_peaks \
	    auto_resolution \
	    auto_ring \
	    spot_rms_var \
	    spot_anisotropy \
	    \
	    exclude_ice \
	    exclude_auto \
	    fix_distance_indexing \
	    fix_cell_indexing \
	    fix_max_cell_edge \
	    max_cell_edge \
	    sigma_cutoff \
	    i_sig_i \
	    auto_thresh_indexing \
	    auto_thresh_value \
	    i_sig_i_delta \
	    \
	    hkldev_max \
	    numvectors \
	    \
	    beamsearch_stepsize \
	    beamsearch_stepnumx \
	    beamsearch_stepnumy \
	    \
	    find_multiple_lattices \
	    anomalous \
	    \
	    space_group \
	    low_resolution_limit \
	    high_resolution_limit \
	    estimated_high_resolution_limit \
	    resolution_cutoff \
	    excl_res_rng \
	    view_predictions_during_processing \
	    resolution_exclude_ice \
	    \
	    block_size \
	    mtz_file \
	    mtz_directory \
	    batch_number \
	    \
	    nullpix \
	    raster_nxs \
	    raster_nys \
	    raster_nc \
	    raster_nrx \
	    raster_nry \
	    max_refl_width \
	    postref_refl_intensity_thresh \
	    postref_refl_count_thresh \
	    mosaic_safety_factor \
	    images_mosaic_smooth \
	    ref_refl_count_thresh \
            no_imgs_summed \
	    profile_tolerance_min \
	    profile_tolerance_max \
            optimise_profile_tolerance \
	    profile_refl_count_av_thresh \
	    profile_rmsbg_thresh \
	    overload_cutoff \
	    profile_overload_cutoff \
	    threshold_spot_inclusion \
	    profile_optimise_central\
	    profile_optimise_standard\
	    optimise_box_size\
	    \
	    mtz_overwrite \
	    \
	    ice_ring_width \
	    prcutval \
	    excl_near_ice \
	    \
	    pnt_hklref_file \
	    pnt_hklref_dir \
            use_feckless_prep \
            ssm_mtz_file \
	    use_mosflm_symmetry \
	    aimls_high_res_lim \
	    aimls_low_res_lim \
	    aimls_batch_excl \
	    aimls_range_excl \
	    scale_factor_spacing \
	    B_factor_spacing \
	    keep_overloaded \
	    part_frac_low \
	    part_frac_high \
	    outl_sig_cutoff \
            sameSDall \
            setSDBterm0 \
	    treat_anomalous_data \
            uq_rfree_frac \
	    \
	    cell_refinement_fix_beam \
	    cell_refinement_fix_distance \
	    cell_refinement_fix_yscale \
	    cell_refinement_fix_tilt \
	    cell_refinement_fix_twist \
	    cell_refinement_fix_radial_offset \
	    cell_refinement_fix_tangential_offset \
	    cell_refinement_fix_ccomega \
	    cell_refinement_postrefinement_check \
	    cell_refinement_fix_cell_a \
	    cell_refinement_fix_cell_b \
	    cell_refinement_fix_cell_c \
	    cell_refinement_fix_cell_alpha \
	    cell_refinement_fix_cell_beta \
	    cell_refinement_fix_cell_gamma \
	    cell_refinement_fix_mosaicity \
	    \
	    integration_fix_beam \
	    integration_fix_distance \
	    integration_fix_yscale \
	    integration_fix_tilt \
	    integration_fix_twist \
	    integration_fix_radial_offset \
	    integration_fix_tangential_offset \
	    integration_fix_ccomega \
	    integration_postrefinement_check \
	    integration_fix_cell_a \
	    integration_fix_cell_b \
	    integration_fix_cell_c \
	    integration_fix_cell_alpha \
	    integration_fix_cell_beta \
	    integration_fix_cell_gamma \
	    integration_fix_mosaicity \
	    wait_activation \
	    wait_length \
            sum_n_images \
	    multiple_mtz_files \
	    pointless_live \
	    mosflm_exec \
	    web_browser \
	    ccp4_bin \
	    mosdir \
            mosflm_logging \
            restrict_resolution \
            imgpad]

# was           mosflm_logging ]

	debug "Session: Creating session's component objects"

	# Create component object members
	set cell [namespace current]::[Cell \#auto "blank" "cell"]
	set spacegroup [namespace current]::[Spacegroup \#auto "blank" "spacegroup"]
	set history [namespace current]::[History \#auto]

	debug "Session: Loading session history"

	# Put history in history viewer
	[.c component history] changeHistory $history

	# configure supplied options
	eval configure $args

	debug "Session: Starting mosflm"

	set mtz_directory [pwd]	

	if { ![regexp -nocase windows $::tcl_platform(os)] } {
	    if {[file exists mosflm.lp]} {
		set old_datestamp "[clock format [clock seconds] -format "%Y%m%d_%H%M%S"]"
		file rename mosflm.lp mosflm_old_${old_datestamp}.lp
		#puts "renamed old file"
	    }
	}
	# Set web browser if changed in Environement variable settings window
	if {[getParameterValue web_browser] != ""} {
	    set ::env(CCP4_BROWSER) [getParameterValue web_browser]
	} else {
	    if { [info exists ::env(CCP4_BROWSER)] } {
		if { [regexp -nocase windows $::tcl_platform(os)] } {
		    # Remove the quotes around the path which corrupt the XML parsing
		    set ::env(CCP4_BROWSER) [string trim $::env(CCP4_BROWSER) \"\"]
# Windows wants \""\" , apparently!		    set ::env(CCP4_BROWSER) [string trim $::env(CCP4_BROWSER) \"\"]
		}
		updateSetting web_browser $::env(CCP4_BROWSER) 0 0 "Processing_options"
	    }
	}

	# Set ccp4_bin if we can - also should set CBIN
        if {$::debugging} {
            # When debugging on Windows, cannot redirect stdout, so send puts output to a file
            # This debug to recognise that env(CBIN) can exist but is actually null .. see below

            set l_filename "debug.log"
            set l_file [open $l_filename w]
            puts $l_file "In SESSION, ccp4_bin is: [getParameterValue ccp4_bin]"
            puts $l_file "about to test if env(CBIN) exists, value is: [info exists ::env(CBIN)] "
            if { [info exists ::env(CBIN)] } {
                puts $l_file "env(CBIN) does apparently exist"
            } else {
                puts $l_file "env(CBIN) does not exist"
            }
            puts $l_file "gone past test on env(CBIN)"
            flush $l_file
        }

	if {[getParameterValue ccp4_bin] != ""} {
            if {$::debugging} {
                puts "flow: about to set env(CBIN) to [getParameterValue ccp4_bin]"
                puts $l_file "setting env(CBIN) to: [file normalize [getParameterValue ccp4_bin]]"
            }
	    # set via Environment variable settings window
	    set ::env(CBIN) [file normalize [getParameterValue ccp4_bin]]
            if {$::debugging} {
                puts $l_file "Info exists env(CBIN) is: [info exists ::env(CBIN)]"
            }
	} else {
	    if { [info exists ::env(CBIN)] } {
                if {$::debugging} {
                    puts "flow: about to set ccp4_bin using env(CBIN) which is: $::env(CBIN)"
                    puts $l_file "about to updateSetting ccp4_bin to env(CBIN)"
                    puts $l_file "the name for CBIN is [ array names env CBIN ] "
                }

                if { [ array names env CBIN ] != "" } {
		    updateSetting ccp4_bin $::env(CBIN) 0 0 "Processing_options"
                }
	    }
	}
        if {$::debugging} {
             flush $l_file
             close $l_file
        }


	# Set MOSDIR if not set already, but don't set if mosdir isn't assigned.
	if {[getParameterValue mosdir] != ""} {
	    # set via Environement variable settings window
	    set ::env(MOSDIR) [getParameterValue mosdir]
	} else {
	    if { [info exists ::env(MOSDIR)] } {
		updateSetting mosdir $::env(MOSDIR) 0 0 "Processing_options"
	    } else {
		# okay, not set, we should set it to the current working directory
		updateSetting mosdir [pwd] 0 0 "Processing_options"
		set ::env(MOSDIR) $mosdir
	    }
	}
    
	# Set mosflm_exec to MOSFLM_EXEC if it's assigned.

	# Set MOSFLM_EXEC if not set already, but don't set if mosflm_exec isn't assigned.
	if {[getParameterValue mosflm_exec] != ""} {
	    # set via Environement variable settings window
	    set ::env(MOSFLM_EXEC) [getParameterValue mosflm_exec]
	} else {
	    if { [info exists ::env(MOSFLM_EXEC)] } {
		updateSetting mosflm_exec $::env(MOSFLM_EXEC) 0 0 "Processing_options"
	    }
	}

	# Set MOSFLM_LOGGING if not set already, but don't set if mosflm_logging isn't assigned.
	if {[getParameterValue mosflm_logging] != "" } {
	    # set via Environment variable settings window
	    set ::env(MOSFLM_LOGGING) [getParameterValue mosflm_logging]
	} else {
	    if { [info exists ::env(MOSFLM_LOGGING)] } {
		updateSetting mosflm_logging $::env(MOSFLM_LOGGING) 0 0 "Processing_options"
	    } else {
		updateSetting mosflm_logging 0 0 0 "Processing_options"
	    } 
	}
    
	# Start mosflm
	Mosflm::startMosflm
    
	if { ![regexp -nocase windows $::tcl_platform(os)] } {
	    after 1500 [if {[catch {file rename mosflm.lp "mosflm_[$::mosflm getDateStamp].lp"} catchmessage]} {}]
	    addCCP4i2file "mosflm_logfile" "mosflm_[$::mosflm getDateStamp].lp"
	}
	debug "Session: Session object creation complete"
    }

    destructor {
	# cancel scheduled saves
	after cancel $queued_save

        if { $::ccp4i2 == 1 } {
            # In --ccp4i2 mode force copying of the temporary file to the file session.mos
            file copy -force $session_file session.mos
            addCCP4i2file "mosflm_session_file" "session.mos"
            writeCCP4i2list
            array unset ccp4i2files
        }

	# if no crash delete the temporary file
	if { $crashed == 0 } {
	    file delete $session_file
            #puts "saved file: $saved_file and not crashed"
            #puts "so deleted: $session_file"
	}

	# Delete component objects
	delete object $cell
	delete object $spacegroup
	delete object $history
	foreach i_warning $warnings {
	    delete object $i_warning
	}
	
	# Clear masks
	Mask::clearAll
	# Close mosflm
	Mosflm::closeMosflm
    }
}

body Session::tracker { args } {
# call with     trace variable <varname> rw [code $this tracker]
    $::mosflm updateSessionForNewChunk
}

body Session::appendToListOfXMLFiles { a_file } {
    lappend listOfXMLFiles $a_file
}

body Session::removeFromListOfXMLFiles { an_index } {
    set listOfXMLFiles [lreplace $listOfXMLFiles $an_index $an_index]
}

body Session::getListOfXMLFiles {} {
    return $listOfXMLFiles
}

body Session::setShowGraphs { arg } {
    set showgraphs_yesno $arg
}

body Session::getShowGraphs  {} {
    return $showgraphs_yesno
}

body Session::setMaxNumberOfCores { a_dom } {
    set maxNumberOfCores [$a_dom selectNodes string(/processor_information/number_of_cores)]
    #puts "setMaxNumberOfCores $maxNumberOfCores"
    return $maxNumberOfCores
}

body Session::updateMaxNumberOfCores { a_number } {
    set maxNumberOfCores $a_number
    return $maxNumberOfCores
}

body Session::getMaxNumberOfCores { } {
    return $maxNumberOfCores
}

body Session::setNumberOfCores { a_number } {
    set numberOfCores $a_number
    return $numberOfCores
}

body Session::getNumberOfCores { } {
    if { $numberOfCores <= 0 } {
	set numberOfCores $maxNumberOfCores
    }
    return $numberOfCores
}

body Session::getBatchSizeFromCores { } {
    if { $numberOfCores > 0 } {
	set thisBatchSize [ expr $totalBatchSize/$numberOfCores ]
	return $thisBatchSize
    } {
	return 1
    }
}

#body Session::getCoresFromBatchSize { } {
#    set numberOfCores [ expr $totalBatchSize/$thisBatchSize ]
#    #puts "numberOfCores = totalBatchSize \/ thisBatchSize $numberOfCores = $totalBatchSize \/ $thisBatchSize"
#    return $numberOfCores
#}

body Session::setTotalBatchSize { first_and_last_image } {
    set totalBatchSize [ expr [lindex $first_and_last_image 1] - [lindex $first_and_last_image 0] + 1 ]
    return $totalBatchSize
}

#body Session::getTotalBatchSize { } {
#    return $totalBatchSize
#}

#body Session::setBatchSize { i_value } {
#    set thisBatchSize $i_value
#    return $thisBatchSize
#}

#body Session::getBatchSize { } {
#    return $thisBatchSize
#}

body Session::getHistory { } {
    return $history
}


# Session creating/saving/copying methods ####################################

# Method to determine whether session has been saved to a named file

body Session::isSaved { } {
    #puts "isSaved: $saved_file"
    return $saved_file
}

body Session::isHdf5 { } {
    return $hdf5_master
}

body Session::setHdf5 { an_hdf5_file } {
    set hdf5_master $an_hdf5_file
}

# Method to determine if a saved session file has been read

body Session::getSessionFileRead { } {
    return $saved_file_read
}

# Method to determine if an integration run has been done (debugging purposes)
body Session::getIntegrationDone { } {
    #puts "in Session::getIntegrationDone, integration_done is $integration_done"
    return $integration_done
}

body Session::setIntegrationDone { } {
    set integration_done 1
}


# Method to determine whether site file has been read

body Session::getSiteFileRead { } {
    return $sitefileread
}

body Session::setSiteFileRead { file } {
    set sitefileread $file
}

# Method to determine whether site file has been written

body Session::getSiteFileWritten { } {
    return $sitefilewritten
}

body Session::setSiteFileWritten { file } {
    set sitefilewritten $file
}

# Method to get the session's filename

body Session::getFilename { } {
    return $session_file
}

# Route to read from site configuration file

body Session::readFromSiteFile { a_file } {
    .c readSiteFile $a_file
}

# Method to store a site specific parameter read from a file

body Session::setInSiteFile { parameter value } {
    set sitesetting($parameter) $value
    #puts "setting sitesetting($parameter) to $value"
}

# Method to clear all site specific parameters read from a file

body Session::clearInSiteFile { } {
    array unset sitesetting
}

# Method to retrieve a site specific parameter read from a file

body Session::valueInSiteFile { parameter } {
    return $sitesetting($parameter)
}

# Method to tell if initial detector and crystal parameters have been saved for this session

body Session::getXDparamsSaved { } {
    return $savedXDparams
}

# Method to initialize session from saved session file

body Session::initializeFromFile { a_file } {
    if {$::debugging} {
        puts "flow: Session::initializeFromFile for $a_file"
    }
#    Image::setSessionFileRead
    set saved_file_read 1
    # open the file and read the entire content
    set in_file [open $a_file r]
    # set UNIX-style line-endings for Windows
    fconfigure $in_file -translation auto
    set content [read $in_file [file size $a_file]]
    close $in_file

    # If recovering a temporary file, continue to use it as the temporary file
    if { [regexp {^temp[0-9]+\.[a-z]+$} [file tail $a_file]] } {
        #puts "$a_file recovered"
        set session_file $a_file
    } else {
        #puts "$a_file read in"
        set saved_file ""
        if { [file tail $a_file] == "initfile" } {
            # If reading an init file the temporary file should already be present
        } else {
            createTempFile
        }
    }

    # parse the xml into a DOM tree
    if {$::debugging} {
        puts "flow: parsing xml into DOM tree"
    }
    if {[catch {set dom [dom parse $content]} result]} {
	puts "Error creating dom tree: $result"
	puts "Bad xml: $content"
        .m confirm \
	    -type "1button" \
	    -title "Error" \
	    -text "Session: Could not parse file:\n\"$a_file\"" \
	    -button1of1 "Dismiss"
        return 0
    }

    #puts [$dom asHTML]

    # Get the session element
    if {$::debugging} {
        puts "flow: getting session element"
    }
    set session_node [$dom selectNodes session]
    if {$::debugging} {
        puts "flow: session_node $session_node"
    }

    # Loop through session elements' child data elements, creating Sectors
    foreach i_sector_node [$session_node selectNodes sector] {
        if {$::debugging} {
          puts "flow: i_sector_node $i_sector_node"
          puts "flow: namespace current [namespace current]"
        }
        # NB images and a-matrices parse within sector constructor
	set new_sector [namespace current]::[Sector \#auto "xml" $i_sector_node]
	# Update controller
        if {$::debugging} {
            puts "flow: new_sector $new_sector"
        }
	.c updateSector $new_sector
    }

    # Set the session attributes
    foreach i_datum $data {
	if {[$session_node hasAttribute $i_datum]} {
    if {$::debugging} {
        puts "flow: updatesetting for $i_datum"
    }
	    updateSetting $i_datum [$session_node getAttribute $i_datum] 0
	}
    }
    if { $hdf5_master != "" } {
      set ::env(HDF5file) 1
    }
    # Set initial detector parameters from data loaded
    foreach param { beam_x beam_y beam_y_corrected distance yscale } {
    	eval querySiteSetting $param \$$param 1 1 "Images" ; # check site file
	#puts "Set initial detector value $initial_detect_param($param) for $param"
    }

    # Set MOSFLM_LOGGING if not set already, but don't set if mosflm_logging isn't assigned.
    if {[getParameterValue mosflm_logging] != "" } {
	# set via Environement variable settings window
	set ::env(MOSFLM_LOGGING) [getParameterValue mosflm_logging]
    } else {
	if { [info exists ::env(MOSFLM_LOGGING)] } {
	    updateSetting mosflm_logging $::env(MOSFLM_LOGGING) 0 0 "Processing_options"
	} else {
	    updateSetting mosflm_logging 0 0 0 "Processing_options"
	}
    }

    # Parse component objects
    $cell parseDom [$session_node selectNodes {cell[@name='cell']}]
    $spacegroup parseDom [$session_node selectNodes {spacegroup[@name='spacegroup']}]
    $history parseDom [$session_node selectNodes "history"]

    # Parse warnings
    foreach i_warning_node [$session_node selectNodes {//warnings/warning}] {
	set i_warning [namespace current]::[Warning \#auto "xml" $i_warning_node]
	lappend warnings $i_warning
	.c addWarning $i_warning
    }

    # Parse masks
    Mask::parseMasks [$session_node selectNodes "masks"]

    # Update controller with cell and spacegroup
    .c updateCell $cell
    .c updateSpacegroup $spacegroup

    # Update settings widgets
    SettingWidget::refreshAll

    # Check if multiple lattices
    if {[getMultipleLattices]} {
        #puts "Cannot restore any cell refinement & integration in multi-lattice mode. Sorry."
    } else {
        #puts "Multi-lattice mode not detected."
        # Load most recent processing results, if there are any
        set l_most_recent_cellref [$history getMostRecentEvent CellrefinementEvent]
        #puts "l_most_recent_cellref $l_most_recent_cellref repeat?"
        if {$::debugging} {
            puts "l_most_recent_cellref is: $l_most_recent_cellref"
        }
        if {$l_most_recent_cellref != ""} {
            $l_most_recent_cellref repeat
        }
        set l_most_recent_integration [$history getMostRecentEvent IntegrationEvent]
        #puts "l_most_recent_integration $l_most_recent_integration repeat?"
        if {$::debugging} {
            puts "l_most_recent_integration is: $l_most_recent_integration"
        }
        if {$l_most_recent_integration != ""} {
            $l_most_recent_integration repeat
        }
    }

    # Never previously got most recent solution event - probably due to (mis)use of split in Solution::unserialize
    set l_most_recent_solution [$history getMostRecentEvent SolutionEvent]
    #puts "l_most_recent_solution $l_most_recent_solution extract images used?"
    if {$l_most_recent_solution != ""} {
	#$l_most_recent_solution repeat
        if {$::debugging} {
            puts "About to set images_last_indexed to: [$l_most_recent_solution getImageNosUsed]"
        }
        set images_last_indexed [$l_most_recent_solution getImageNosUsed]
        #puts "Image numbers last used for indexing $images_last_indexed"
    }

    # Open the first image if there are any
    set l_images [getImages]
    if {[llength $l_images] > 0} {
	.image openImage [lindex $l_images 0]
	.c enableIndexing
    }
    # To be consistent with openSessionFile
    if {[$::session MatrixIsSet]} {
	.c enableProcessing
    }

    # Need to force repeat of indexing before further procesing if multiple-lattice mode was set when session saved
    if {[getMultipleLattices]} {
        .c disableProcessing
    }

    # If reading an init file delete setting of saved_file to prevent overwriting
    if { [file tail $a_file] == "initfile" } {
        set saved_file ""
    }

    return 1
}

body Session::serialize { } {

    # Begin xml
    set xml "<?xml version='1.0'?><!DOCTYPE session><session "

    # Add session attributes
    foreach i_datum $data {
	append xml "${i_datum}=\"[set $i_datum]\" "
    }
    append xml ">"

    # Write component objects
    append xml [$cell serialize]
    append xml [$spacegroup serialize]

    # Write sectors
    foreach a_sector $children {
        append xml [$a_sector serialize]
	# N.B. a-matrices and images serialized as part of sectors 
    }

    # Write masks
    append xml [Mask::serializeAll]

    # Write warnings
    append xml "<warnings>"
    foreach i_warning $warnings {
	append xml [$i_warning serialize]
    }
    append xml "</warnings>"

    # Write history
    append xml [$history serialize]

    # Close session tag
    append xml "</session>"

    return $xml
}

body Session::getMosflmLogging { } {
    set value [getParameterValue mosflm_logging]
    return $value
}

body Session::createTempFile { } {
    # Create random temporary file for new session 
    # Create new seed for random number generator based on the current clock state
    expr srand([clock clicks])
    # set flag to indicate file create is incomplete
    set file_creation_incomplete 1
    # initialize the counter for the number of attempts
    set file_creation_attempts 0
    # loop until a file has been created
    while {$file_creation_incomplete} {
        # Check we haven't tried too many times already
        if {$file_creation_attempts > 50} {
            # Inform the user of failure
            .m confirm \
                -type "1button" \
                -title "Error" \
                -text "Could not create session file:\n$out_file" \
                -button1of1 "Dismiss"
            # Stop trying as it has failed.
            return 0
        }
        # Create a new random filename pointing to in the hidden mosflm directory 
        set l_randomfilename [file join $::mosflm_directory "temp[format %05u [expr int(rand()*99999)]].mpr"]
        # try and create the file recording result (will fail if file exists)
        set file_creation_incomplete [catch {open $l_randomfilename {WRONLY CREAT EXCL}} out_file]
        # Keep tally of creation attempts
        incr file_creation_attempts
    }
    # Close the file created
    close $out_file
    debug "Controller: Writing session to hidden file"
    #puts "createTempFile: [file tail $l_randomfilename]"
    writeToFile $l_randomfilename
}

# Session::writeToFile #####################################################
#
# Saves session in a file indicated by the first arg, or to the filename
#   stored in member variable session_file if there is no first arg
# Second arg is flag to indicate whether this is a 'real' user save, or
#   just a background save to a hidden file
#
# NB Does not actually save the session, but queues it to happend soon
############################################################################

body Session::writeToFile { {a_file ""} { a_save_flag "0"} } {
    
    # Set where to save the session (either file passed as arg,
    #  or file already recorded in session
    if {$a_file == ""} {
	set l_file $session_file
    } else {
	if { [regexp {^temp[0-9]+\.[a-z]+$} [file tail $a_file]] } {
            #puts "temp $a_file"
            set session_file $a_file
        } else {
            #puts "perm $a_file"
        }
	set l_file $a_file
    }

    #puts "wTF: [file tail $l_file] [incr count]"

    # If it's a user requested save, store chosen file name in saved_file
    if {$a_save_flag == 1} {
	set saved_file $l_file
	doQueuedWrite $l_file
    } else {
	after cancel $queued_save
	set queued_save [after 5000 [list $::session doQueuedWrite $l_file]]
    }
}

# method to actually save session in file (queued by writeToFile)

body Session::doQueuedWrite { a_file } {
    
    # Create the xml from the session
    set xml [serialize]
    
    set temp [::open $a_file w]
    ::close  $temp
    
    # Open the file for writing to
    if {[catch {::open $a_file w} result]} {
        .m confirm \
	    -type "1button" \
	    -title "Error" \
	    -text "Could not open file:\n\"$a_file\"\nError message: $result" \
	    -button1of1 "Dismiss"
        return 101
    } else {
        set outfile $result
	# set UNIX-style line-endings for Windows
	fconfigure $outfile -translation lf
    }

    # Write the xml to the file
    if {[catch {puts $outfile $xml} result]} {
        .m confirm \
	    -type "1button" \
	    -title "Error" \
	    -text "Could not write to file:\n\"$a_file\"\nError message: $result" \
	    -button1of1 "Dismiss"
        return 102
    }

    # Close the file
    if {[catch {::close $outfile} result]} {
        .m confirm \
	    -type "1button" \
	    -title "Error" \
	    -text "Could not close file:\n\"$a_file\"\nError message: $result" \
	    -button1of1 "Dismiss"
        return 103
    }
    
    # update the session's record of the file it's saved to
    #puts "dQW: [file tail $a_file] [incr count]"
    if { [regexp {^temp[0-9]+\.[a-z]+$} [file tail $a_file]] } {
        set session_file $a_file
    }

    return 0
}

body Session::addCCP4i2file { tag file } {
    if { $tag eq "pointscale_logfile" } {
        # Attempt to keep successive pointandscale log files from session
        incr n_ps_logfiles
        eval set tag ${tag}_${n_ps_logfiles}
    }
    set ccp4i2files($tag) $file
    #puts "addCCP4i2file: tag: $tag file: $file"
}

body Session::writeCCP4i2list { } {
    # Write an XML file listing the files required for CCP4i2
    # open the file for writing
    set l_file_handle [::open session_files.xml w]
    # write main tag, and recent_sessions tag
    puts $l_file_handle "<?xml version='1.0'?><!DOCTYPE session_files>"
    puts $l_file_handle "<selected_files>"
    # write batch destination tags
    foreach tag [array names ccp4i2files] {
        if {[info exists ccp4i2files($tag)]} {
            puts $l_file_handle "<$tag=\"$ccp4i2files($tag)\"/>"
        }
    }
    puts $l_file_handle "</selected_files>"
    puts $l_file_handle "</session_files>"
    # close file
    ::close $l_file_handle
}

# Warning methods ###########################################################

body Session::generateWarning { a_message args } {
    options {-type "Warning" -reason "User" -detail "Sorry no further information" \
	    -hint "Sorry no further information" -note "Sorry no further information" -colour ""} $args
    set l_warning [namespace current]::[Warning \#auto "build" $options(-type) $options(-detail) \
					$options(-hint) $options(-note) $a_message $options(-colour)]
    lappend warnings $l_warning
    .c addWarning $l_warning
    addHistoryEvent "WarningEvent" $options(-reason) $l_warning
}

body Session::deleteWarning { a_warning } {
    set l_index [lsearch $warnings $a_warning]
    if {$l_index != -1} {
	delete object [lindex $warnings $l_index]
	set warnings [lreplace $warnings $l_index $l_index]
    }
}

body Session::parseWarnings { a_dom } {
    set l_node [$a_dom selectNodes {/warnings}]
    set l_reason [string totitle [$l_node selectNodes normalize-space(process)]]
    foreach i_node [$l_node selectNodes {//warning}] {
	set l_type [string totitle [$i_node selectNodes normalize-space(type)]]
	set l_message [string totitle [$i_node selectNodes normalize-space(message)]]
	set l_explain [$i_node selectNodes normalize-space(detail)]
	set l_hint [$i_node selectNodes normalize-space(hint)]
	set l_note [$i_node selectNodes normalize-space(note)]
	set l_colour [$i_node selectNodes normalize-space(colour)]
	generateWarning $l_message -type $l_type -reason $l_reason -detail $l_explain -hint $l_hint -note $l_note -colour $l_colour
	#puts "parseWarnings: $l_message\ntype:$l_type\nreason:$l_reason\ndetail:$l_explain\nhint:$l_hint\nnote:$l_note\n\n"
    }
}

body Session::parseInfoAndWarnings { a_processor a_dom } {
    # workout reason for warnings
    if { $a_processor == "" } {
	puts "parseInfoAndWarnings: No processor given"
	set l_node [$a_dom selectNodes {/information_and_warnings}]
	set l_message [$l_node selectNodes normalize-space(warning)]
	puts "Message is $l_message"
    } else {
	if {[$a_processor info class] == "::Integrationwizard"} {
	    set l_reason "Integration"
	} else {
	    set l_reason "Cell_refinement"
	}
	set l_node [$a_dom selectNodes {/information_and_warnings}]
        set trafficl [$l_node selectNodes normalize-space(traffic_light_colour)]
        #puts "Light is $trafficl"
	foreach i_node [$l_node selectNodes {warning}] {
	    set l_type [string totitle [$i_node selectNodes normalize-space(type)]]
	    set l_message [$i_node selectNodes normalize-space(summary)]
	    # '__nl__' is used to indicate [CR][LF] in the XML sent from Mosflm
	    set l_message [regsub -all {\_\_nl\_\_} $l_message "\n"]
	    set l_explain [$i_node selectNodes normalize-space(detail)]
	    set l_explain [regsub -all {\_\_nl\_\_} $l_explain "\n"]
	    set l_hint [$i_node selectNodes normalize-space(hint)]
	    set l_hint [regsub -all {\_\_nl\_\_} $l_hint "\n"]
	    set l_note [$i_node selectNodes normalize-space(note)]
	    set l_note [regsub -all {\_\_nl\_\_} $l_note "\n"]
	    set l_colour [$i_node selectNodes normalize-space(colour)]
	    generateWarning $l_message -type $l_type -reason $l_reason -detail $l_explain -hint $l_hint -note $l_note -colour $l_colour
	    #puts "parseInfoAndWarnings: $l_message\ntype:$l_type\nreason:$l_reason\ndetail:$l_explain\nhint:$l_hint\nnote:$l_note\n\n"
	}
        .c setColourCode [string tolower $trafficl]
    }
}    

body Session::processGenerateResponse { a_dom } {
    set l_node [$a_dom selectNodes {/generate_response}]
    set d_image [$l_node selectNodes normalize-space(imagefile)]
    set d_template [$l_node selectNodes normalize-space(image_template)]
    set d_number [$l_node selectNodes normalize-space(image_number)]
    # puts "pGR d_"
    if { [file tail $d_image] == $d_template } {
	set d_image "image.[format %07g $d_number]"
    }
    set o_image [Image::getImageByPath $d_image]
    # hrp 27.09.2012 - for reading from .XML file
    if { $o_image == "" } {
	set o_image [getImageByName [file tail $d_image]]
    }
    # puts "pGR o_ $o_image"
    if { $o_image != "" } {
	# generate response may contain an image we have not read in e.g. if only sighting images at 90 degrees
	set n_image [$o_image getNumber]
	# puts "pGR n_ $n_image"
	
	while {[llength $spatial_overlaps] < [expr $n_image + 1]} {
	    lappend spatial_overlaps 0
	}
	set f_image [file tail $d_image]
	foreach i_node [$l_node selectNodes {//reflections_generated}] {
	    set l_spatover [$i_node selectNodes normalize-space(spatially_overlapped)]
	    #puts "Image $n_image: $f_image $l_spatover spatially overlapped reflections"
	    set spatial_overlaps [lreplace $spatial_overlaps $n_image $n_image $l_spatover]
	}

	while {[llength $lattice_overlaps] < [expr $n_image + 1]} {
	    lappend lattice_overlaps 0
	}
	set f_image [file tail $d_image]
	foreach i_node [$l_node selectNodes {//reflections_generated}] {
	    set l_lattover [$i_node selectNodes normalize-space(lattice_overlapped)]
	    #puts "Image $n_image: $f_image $l_lattover spatially overlapped reflections"
	    set lattice_overlaps [lreplace $lattice_overlaps $n_image $n_image $l_lattover]
	}
    }
}

# Image/sector configuration methods ########################################

body Session::addImage { a_image_file } {
trace variable sum_n_images w [code $this tracker]
#    puts "body Session::addImage: a_image_file is $a_image_file"
    set ::timer07 [clock clicks -milliseconds]
    # Check image isn't already present
    set l_image [getImageByName [file tail $a_image_file]]
    #puts "addImage: l_image is $l_image"
    if {$l_image == ""} {
	# Make a new image
	set l_new_image [namespace current]::[Image \#auto "build" "$a_image_file"]
	if { [getmatchingSector $l_new_image] == "" || $sum_n_images_changed == "1"} {
	    # query mosflm for info about the image
	    #puts "NO sector match for l_new_image: $l_new_image"
	    $::mosflm getExperimentData $l_new_image
            set hdf5_master [ $l_new_image getTemplateForMosflm]
            if { [regexp -- {^(.*?)(_master.h5)$} $hdf5_master match] } {
	    } else {
              set hdf5_master ""
            }
 
	    # NB receipt of experiment data will trigger creation of
	    # new sector, adding of image to sector and search for
	    # more images; hrp 24052018 - this must not happen if we are
	    # just changing the chunk size!
	} else {
	    #puts "** sector match for l_new_image: $l_new_image"
	    # query mosflm for phi info
            set firstimagematching [file tail $a_image_file]
	    $::mosflm getPhi $l_new_image
	    # NB receipt of phi info will trigger adding of image to sector
	}
	# delete image object - why?
	if { $sum_n_images_changed == "0" } {
#	    puts "deleting image object $l_new_image"
	    delete object $l_new_image
	} else {
# don't delete it since the image list is not being created from XML...
#	    puts "NOT deleting image object $l_new_image"
	}
	# N.B. image will be re-created and added to session upon
	#  receipt of a header or brief header response xml message
    } else {
	.m confirm \
	    -title "Error" \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -text "Image [file tail $a_image_file] is already in the session."
    }
}

body Session::setIndexingList { { list "" } } {
    if {$::debugging} {
        puts "flow: in Session::setIndexingList, setting IndexingList to: $list"
    }
    set indexing_list $list
}

body Session::getIndexingList { } {
    return $indexing_list
}

body Session::getglobbedImages { a_image } {
# Method to search for more images matching a given image's template and directory
    if { $::fastload == 1 } {
        # Loop through images looking for the 90 degree image and append to list for indexing
        foreach { l_phi_start l_phi_end } [$a_image getPhi] break
        #puts "getglobbedImages from image [$a_image getNumber] phis: $l_phi_start - $l_phi_end"
        #
        set l_phi_range [expr $l_phi_end - $l_phi_start]
        set deg90 0
        set wedge $l_phi_range
    
        # Get a glob pattern from image to search for rest of dataset
        #puts $a_image
        set t [$a_image getTemplate]
        #puts "Template is: $t"
        regsub -all {\#} [$a_image getTemplate] "?" l_glob_pattern
        #puts "glob pattern is: $l_glob_pattern"
        # Glob for possible image files from same dataset
        set l_possible_image_files [glob -nocomplain [file join [$a_image getDirectory] $l_glob_pattern]]
        #puts $l_possible_image_files
        # Get a regexp to REALLY check the filenames are matches
        # Also permit the + character within the image filename
        regsub -all {\+} [$a_image getTemplate] "\\+" l_regexp0
        regsub -all {\#} $l_regexp0 "\\d" l_regexp
        # reset list of globbed-for files
        set globbed_images {}
        foreach i_file $l_possible_image_files {
            # if the file matches the regexp
            if {[regexp $l_regexp $i_file]} {
                # if the file hasn't already been added
                if {[Image::getImageByPath $i_file] == ""} {
                    # add the file to the list of further files to be added
                    lappend globbed_images $i_file
                }
            }
        }
    
        set reading_list {}
        if {[llength $globbed_images] > 0} {
            set ::timer10 [clock clicks -milliseconds]
            # Sort files
            set globbed_images [lsort $globbed_images]
            # Loop through found image files, and query mosflm for their phi values
            set fileno 1
            foreach i_file $globbed_images {
                incr fileno
                set l_phi_start $l_phi_end
                if { $l_phi_start > 360.0 } { set l_phi_start [expr ($l_phi_start - 360.0)]}
                set l_phi_end [expr ($l_phi_start + $l_phi_range)]
                #
                #puts "Image $fileno phi range $l_phi_start - $l_phi_end is $i_file"
                #
                set wedge [expr ($wedge + $l_phi_range)]
                if { ($wedge >= 90) && ($deg90 == "0") } {
                    # Ninety degree image
                    #puts "Image $fileno phi range $l_phi_start - $l_phi_end is 90degree image"
                    eval set t_image [namespace current]::[Image \#auto "build" "$i_file"]
                    eval $::mosflm getPhi $t_image
                    set deg90 $fileno
                    break
                }
            }
            # Not reached 90 degrees?
            if { $deg90 == "0" } {
                #puts "Still need a \'ninety degree\' image"
                eval set t_image [namespace current]::[Image \#auto "build" "$i_file"]
                eval $::mosflm getPhi $t_image
                set deg90 $fileno
            }
            #puts "Image $fileno phi range $l_phi_start - $l_phi_end is 90degree image"
            #
            eval lappend indexing_list $deg90
            delete object $t_image
            #puts "[expr ([clock clicks -milliseconds] - $::timer10)/1000.] ms. getting 90 degree image"
            #
            puts "Images in indexing list checked on launching Autoindexing pane: $indexing_list"
            #
    
            set lastimagetoload [loadglobbedImages]
            #puts "Expecting last image to be $lastimagetoload"
            #
            #puts "Next try loadglobbedHeaders ..."
            #
            after 2000 [code $this loadglobbedHeaders $lastimagetoload]
            #puts "Number images added to session now [llength [[$::session getCurrentSector] getImages]]"
            #
    
            #puts "globbed_images: $globbed_images"
        }
    
        return $globbed_images
    } else {
	if { [$a_image getTemplate] == [$a_image getTemplateForMosflm] } {
	    #
	    #  conventional images, one per file
	    #
	    set HDF5File 0
	    # Use original code
	    # Get a glob pattern from image to search for rest of dataset
	    #puts $a_image
	    set t [$a_image getTemplate]
	    #puts "Template is: $t"
	    regsub -all {\#} [$a_image getTemplate] "?" l_glob_pattern
	    #puts "glob pattern is: $l_glob_pattern"
	    # Glob for possible image files from same dataset
	    set l_possible_image_files [glob -nocomplain [file join [$a_image getDirectory] $l_glob_pattern]]
	    #puts $l_possible_image_files
	    # Get a regexp to REALLY check the filenames are matches
	    # Also permit the + character within the image filename
	    regsub -all {\+} [$a_image getTemplate] "\\+" l_regexp0
	    regsub -all {\#} $l_regexp0 "\\d" l_regexp
	    # reset list of globbed-for files
	    set globbed_images {}
	    foreach i_file $l_possible_image_files {
		# if the file matches the regexp
		if {[regexp $l_regexp $i_file]} {
		    # if the file hasn't already been added
		    if {[Image::getImageByPath $i_file] == ""} {
			# add the file to the list of further files to be added
			lappend globbed_images $i_file
		    }
		}
	    }
	    if {[llength $globbed_images] > 0} {
		# Sort files
		set globbed_images [lsort $globbed_images]
	    }
        } {
	    #
	    # HDF5 file, many images per file
	    #
	    set HDF5File 1
	    regsub -all {\#} [$a_image getTemplate] "?" l_glob_pattern
	    set l_possible_image_files {}
	    regsub -all {\+} [$a_image getTemplate] "\\+" l_regexp0
	    regsub -all {\#} $l_regexp0 "\\d" l_regexp
	    for { set i 1 } { $i <= $total_images } { incr i } {
		set i_file [file join [$a_image getDirectory] "image.[format %07g $i]"]
		if { [regexp $l_regexp $i_file] } {
		    lappend l_possible_image_files $i_file
		}
	    }

# l_possible_image_files is in numeric order, so no need to sort after this
	    set globbed_images {}
	    foreach i_file $l_possible_image_files {
		# if the file matches the regexp
		if {[regexp $l_regexp $i_file]} {
		    # if the file hasn't already been added
		    if {[Image::getImageByPath $i_file] == ""} {
			# add the file to the list of further files to be added
			lappend globbed_images $i_file
		    }
		}
	    }
	}
	if {[llength $globbed_images] > 0} {
	    # Loop through found image files, and query mosflm for their phi values
	    foreach i_file $globbed_images {
		# create temporary image object to use for query
		set t_image [namespace current]::[Image \#auto "build" "$i_file"]
		# Query mosflm for image's phi values
		$::mosflm getPhi $t_image
		# delete temporary image object
		delete object $t_image
	    }
	    #puts $globbed_images
	}

        return $globbed_images
    }
}

body Session::loadglobbedImages { } {

    # Load globbed_images in a separate Mosflm batch job
    #puts "Write script to load globbed_images in a separate Mosflm batch job"
    #
    set fo [open load_glob "w"]
    if { ![regexp -nocase windows $::tcl_platform(os)] } {
        puts $fo "#!/bin/sh"
        puts $fo "$::env(MOSFLM_EXEC) XMLFILE load_glob.xml << EOF >/dev/null"
    }

    foreach i_file $globbed_images {
        # create temporary image object to use for query
        set t_image [namespace current]::[Image \#auto "build" "$i_file"]
        if { [$t_image getNumber] == [lindex $indexing_list 1] } {
            #puts "Skip [$t_image getShortName] second in indexing list: $indexing_list"
        } else {
            if { ![regexp -nocase windows $::tcl_platform(os)] } {
                puts $fo "directory [$t_image getDirectory]"
            } else {
                puts $fo "directory \"[$t_image getDirectory]\""
            }
            puts $fo "template [$t_image getTemplate]"
            puts $fo "image [$t_image getNumber]"
            puts $fo "head brief"
            puts $fo "go"
        }
        set lastimagenumber [$t_image getNumber]
        delete object $t_image
    }

    if { ![regexp -nocase windows $::tcl_platform(os)] } { puts $fo "EOF" }
    close $fo
    if { ![regexp -nocase windows $::tcl_platform(os)] } {
        exec chmod u+x load_glob
        set pid [exec ./load_glob &]
    } else {
        # Windows ...
        exec $::env(MOSFLM_EXEC) XMLFILE load_glob.xml < load_glob > load_glob.lp
    }
    #puts "[expr ([clock clicks -milliseconds] - $::timer10)/1000.] ms. sent Mosflm job off for brief headers"
    #
    #puts "Process id is $pid"

    #set okPID 1
    #while {$okPID} {
    #    set okPID [catch {set thisPIDisStillRunning "[exec ps -p $pid]"}]
    #}
    #puts "Process $pid has finished"

    return $lastimagenumber
}

body Session::loadglobbedHeaders { lastimagetoload } {
    
    # Try to read the brief_header_responses from XML file
    after 1000 [if {[catch {set in_file [::open load_glob.xml "r"]} catchmessage]} {}]
    #set fo [open loadglob_done "w"]
    #puts "Reading $in_file (load_glob.xml) at [clock format [clock seconds] -format "%H:%M:%S"]"
    set linenum 0
    set curr_image_no 0
    while { $curr_image_no < $lastimagetoload && ![eof $in_file] } {
        gets $in_file line
        if {[catch {set dom [dom parse $line]}]} {
            #puts $fo "Caught non XML line at line $linenum\n$line"
        } else {
            set doctype [[$dom documentElement] nodeName]
            if {$doctype == "brief_header_response"} {
                set curr_image_no [$::session processBriefHeaderData $dom]
                incr linenum
                update
                #puts $fo "$linenum"
                if { [expr ( $linenum % 1000)] == 0 } {
                    #puts "$linenum headers processed"
                }
            }
        }
    }
    #puts $fo "EOF"
    close $in_file
    #close $fo
    #puts "Finished $in_file (load_glob.xml) at [clock format [clock seconds] -format "%H:%M:%S"]"

    return
}

body Session::writeImageList { list } {
    set globbed_images $list
    #puts "Written globbed_images: $globbed_images"
}


body Session::reportOscRange { } {
    return $oscrange
}

body Session::getSpatialOverlaps { image_number } {
    # method to get stored spatial overlaps by image number
    if { ($image_number != "") && ([llength spatial_overlaps] <= [expr $image_number + 1])} {
	return [lindex $spatial_overlaps $image_number]
    }
    return 0
}

body Session::getLatticeOverlaps { image_number } {
    # method to get stored lattice overlaps by image number
    if { ($image_number != "") && ([llength lattice_overlaps] <= [expr $image_number + 1])} {
	return [lindex $lattice_overlaps $image_number]
    }
    return 0
}

body Session::addNextImage { { img_file "" } } {
    if { $img_file != "" } {
#	puts "body Session::addNextImage file: $img_file"
	# create temporary image object to use for query
	set t_image [namespace current]::[Image \#auto "build" "$img_file"]
	# Query mosflm for image's phi values
	$::mosflm getPhi $t_image
	#puts "addNextImage temp: $t_image"
	# delete temporary image object -why?
	delete object $t_image
    } else {
	# no file passed
    }
}

body Session::addImageList { { list "" } } {
    if { $list != "" } {
        set ::timer10 [clock clicks -milliseconds]
        foreach i_file $list {
            #puts "Create image object from $i_file"
            # create temporary image object to use for query
            set t_image [namespace current]::[Image \#auto "build" "$i_file"]
            # Query mosflm for image's phi values
            $::mosflm getPhi $t_image
            # delete temporary image object
            delete object $t_image
        }
        #puts "[expr ([clock clicks -milliseconds] - $::timer10)/1000.] milliseconds in addImageList"
        set list ""
    } else {
	# no list passed
    }
}

body Session::deleteImages { a_image_files } {
    foreach i_image_file $a_image_files {
	foreach i_sector [getSectors] {
	    if {[$i_sector deleteImage $i_image_file -record 1 -update_imagecombo 1] == "-1"} {
		deleteSector $i_sector
	    }
	}
    }
    .c displaySession
}

body Session::getImages { } {
    # loop through sectors getting all their images
    if {$::debugging} {
       puts "flow: getImages, children is $children"
    }
    set some_images {}
    foreach a_sector $children {
        set some_images [concat $some_images [$a_sector getImages]]
    }
    if {$::debugging} {
       puts "flow: getImages, some_images $some_images"
    }
#    puts "crucial: from Session::getImages, some_images is $some_images"
    return $some_images
}

body Session::getImagesLastIndexed { } {
    return $images_last_indexed
}


body Session::getImageByName { a_name } {
    # method to get an image object by its name
    set l_image ""
    foreach i_sector $children {
        foreach i_image [$i_sector getImages] {
        }
    }
    foreach i_sector $children {
        foreach i_image [$i_sector getImages] {
            if {[$i_image getShortName] == $a_name} {
                return $i_image
            }
        }
    }
    return ""
}

body Session::getImageByTemplateAndNumber { a_template a_number } {
    # method to get an image object by template and number
    set l_sector ""
    set l_image ""
    set l_sector [getSectorByTemplate $a_template]
    if {$l_sector != ""} {
        foreach i_image [$l_sector getImages] {
            if {[$i_image getNumber] == $a_number} {
                set l_image $i_image
                break
            }
        }
    }
    return $l_image
}

body Session::getImageByNumber { a_number } {
    # method to get an image by its number
    foreach i_sector $children {
        foreach i_image [$i_sector getImages] {
            if {[$i_image getNumber] == $a_number} {
                return $i_image
            }
        }
    }
    return ""
}

body Session::getImageByPhi { val } {
    # method to get an image from a phi value - preferably within the range start to end
    foreach i_sector $children {
        foreach i_image [$i_sector getImages] {
            foreach { start end } [$i_image getPhi] break
	    # Test for phi range crossing 0 & offset
	    if { ($val > 355) && ($val < 5) } {
		set start [expr {$start+10}]
		set end [expr {$end+10}]
		set val [expr {$val+10}]
	    }
	    if { ($val == $start) || ($val == $end) } { return $i_image }
	    if { ($val > $start) && ($val < $end) } { return $i_image }
	}
    }
    return ""
}


body Session::getImageTemplate {} {
    return $image_template
}

body Session::getSectors { } {
    # return all sectors in image (which are children)
    #puts "In Session::getSectors, children is: $children"
    return $children
}


body Session::getSectorByTemplate { a_template } {
    # method to get a sector by its template
    foreach i_sector [getSectors] {
	if {[$i_sector getTemplate] == $a_template} {
	    return $i_sector
	}
    }
    return ""
}

body Session::getSectorByMatrix { a_matrix } {
    # method to get a sector by its matrix
    set l_sector ""
    foreach i_sector [getSectors] {
	if {[$a_matrix equals [$i_sector getMatrix]]} {
	    set l_sector $i_sector
	    break
	}
    }
    return $l_sector
}

# hrp 17.11.2006 two new methods to set the current sector and return it

body Session::setCurrentSector { a_currentsector } {
    # method to set the current sector (for integration purposes initially)
    if { $a_currentsector != "" } {
	set currentSector $a_currentsector
    } else {
	set currentSector ""
    }
    #puts "In Session::setCurrentSector, currentSector set to $currentSector"
    return ""
}

body Session::getCurrentSector { } {
    #puts "In Session::getCurrentSector, currentSector is $currentSector"
    if { $currentSector != "" } {
	if { [regexp $currentSector [getSectors] ] } {
            #puts "In Session::getCurrentSector, set a_currentsector using currentSector: $currentSector"
	    set a_currentsector $currentSector
	} else {
	    set a_currentsector [lindex $children 0]
            #puts "In Session::getCurrentSector, set a_currentsector using lindex children 0"
	    set currentSector $a_currentsector
	} 
    } else {
        #puts "In Session::getCurrentSector, currentSector is null, set sector using lindex children 0"
	set a_currentsector [lindex $children 0]
	set currentSector $a_currentsector
    }
    #puts "Current sector got as $currentSector [$currentSector getTemplate]"
    #puts " In Session::getCurrentSector, returning sector: $a_currentsector"
    return $a_currentsector
}

body Session::getmatchingSector { image } {
# Loop through sectors looking for one with matching template
    set l_matching_sector ""
    foreach i_sector [getSectors] {
	if {[$i_sector getTemplate] == [$image getTemplate]} {
	    set l_matching_sector $i_sector
	    #puts "$image matches sector $l_matching_sector"
	    break
	}
    }
    return $l_matching_sector
}

body Session::deleteSector { a_sector } {
    # remove sector from session's list of children
    set position [lsearch $children $a_sector]
    set children [lreplace $children $position $position]
    if {$::debugging} {
       puts "flow Session::deleteSector children is $children"
    }
    #puts "position $position children $children"
    # delete sector object
    delete object $a_sector
}

body Session::addNewSector { a_template } {
    # create sector object
    set new_sector [namespace current]::[Sector \#auto "build" $a_template]
    # add the sector to the session
    addSector $new_sector
    return $new_sector
}

body Session::addSector { a_sector } {
    # add sector to session
    add $a_sector
    # add sector to controller's session tree
    .c addSector $a_sector
    # add sector to image viewer's template combo
    #.image addTemplate [$a_sector getTemplate]
}

body Session::setMultipleImageFiles { value } {
    set addmultipleimagefiles $value
    if { $value == 1 } {
        set addsingleimagefile 0
    }
    #puts "set multiple $value"
}

body Session::setSingleImageFile { value } {
    set addsingleimagefile $value
    if { $value == 1 } {
        set addmultipleimagefiles 0
    }
    #puts "set single $value"
}

# General setting query ########################################################

body Session::getParameterValue { a_parameter } {
    return [set $a_parameter]
}
 # new setting method, HRP 11.05.2018
body Session::setParameterValue { a_parameter a_value } {
#    puts "a_parameter = $a_parameter, a_value = $a_value"
    set $a_parameter $a_value
    return
}

# Experiment settings methods ################################################

body Session::beamIsSet { } {
    if {$beam_x == "" || $beam_y == ""} {
        return 0
    } else {
        return 1
    }
}

# method to get the session's beam position
body Session::getBeamPosition { } {
    return [list $beam_x $beam_y]
}

# method to get the beam position as provided in the image header
body Session::getHeaderBeamPosition { } {
    return [list $header_beam_x $header_beam_y]
}

# method to process header information returned by mosflm in a
#  header_response xml message

body Session::processHeaderData { a_dom } {

    # Check on status of task
    set status_code [$a_dom selectNodes string(/header_response/status/code)]
    if {$status_code == "error"} {
	set imagefullpath [$a_dom selectNodes string(/header_response/image_filename)]
	set imagefilename [file tail $imagefullpath]
	set imageobject [getImageByName $imagefilename]
	.m configure \
	    -type "1button" \
	    -title "Image read error" \
	    -text "Error reading image header. Message from Mosflm is\n[$a_dom selectNodes string(/header_response/status/message)]" \
	    -button1of1 "Exclude image"
	    if { [.m confirm] } {
		#puts "Deleting $imageobject read from file $imagefullpath"
		deleteImages $imageobject
	    } else {
		# do what exactly?
	    }
	    catch [$::mosflm removeJob "image"]
	    catch [$::mosflm removeJob "prediction"]
	    .image enable
    } else {

	# Check detector is same as any previous one, otherwise do not proceed!
	set l_detector_manufacturer [$a_dom selectNodes normalize-space(//detector_manufacturer)]
        #puts "l_detector_manufacturer from XML is $l_detector_manufacturer"
# Extract additional information on detector (if any)
# For historical reasons, only 4 characters are used to denote different detectors. This
# is not sufficent to distinguish Pilatus and Pilatus3, or Eiger and Eiger2, so add another
# character to <detector_manufacturer> sent in the XML to allow the distinction.
# In fact this only changes the string displayed in the Detector tab of Experiment settings.
        set detector_manufacturer_extra [string range $l_detector_manufacturer 4 4]
# Only take first 4 characters
        set l_detector_manufacturer [string range $l_detector_manufacturer 0 3]
        #puts "l_detector_manufacturer set to $l_detector_manufacturer"
	set l_detector_model [$a_dom selectNodes normalize-space(//detector_model)]
	set l_detector_serial_number [$a_dom selectNodes normalize-space(//detector_serial_number)]
	set trusted_detector [$a_dom selectNodes normalize-space(//trusted_detector)]
	if {("$detector_manufacturer$detector_model" ne "") && \
		("$detector_manufacturer$detector_model" ne "$l_detector_manufacturer$l_detector_model")} {
#added by luke on 21 November 2007
#		puts "$l_detector_model" 
#		puts "$l_detector_manufacturer$l_detector_model"
####################################################


	    .om configure \
		-options 2 \
		-message "Sorry, you can't work on images from\ndifferent detectors in the same session." \
		-option1 "Continue working with current images" \
		-option2 "Start a new session"
	    set l_choice [.om confirm]
	    # If the user chose to start a new session
	    if {$l_choice == 2} {
		# Get name of image file to start new session with
		set l_filename [$a_dom selectNodes normalize-space(//image_filename)]
		# start new session with new image
		
		.c newSession $l_filename
	    } else {
		# otherwise just restart mosflm
		Mosflm::restartMosflm
	    }
	} else {
	    # If the detector does match, or there was none previously,
	    #   add the image and update the session properties

	    # Get image-specific data
	    set l_filename [$a_dom selectNodes normalize-space(//image_filename)]
	    #puts "Filename from header response: $l_filename"
	    set l_phi_start [$a_dom selectNodes normalize-space(//phi_start)]
	    set l_phi_end [$a_dom selectNodes normalize-space(//phi_end)]

	    # Create a new image and a sector for it
 
		if { $::env(HDF5file) == 1 } {
		set i_file "[file dirname $l_filename]/image.0000001"
	    } {
		set i_file $l_filename
	    }

	    set l_new_image [namespace current]::[Image \#auto "build" "$i_file"]
	    #puts "[file tail $l_filename] gives $l_new_image in processHeaderData"
	    set templ [$l_new_image getTemplateForMosflm]

#hrp 22022018 for HDF5 --------------------



	    set image_template [$a_dom selectNodes normalize-space(//image_template)]
	    set total_images [$a_dom selectNodes normalize-space(//total_images)]
	    set l_image_number [$a_dom selectNodes normalize-space(//image_number)]
	    $l_new_image setNumber $l_image_number
#hrp 22022018 for HDF5 =====================
	    if {[$l_new_image getTemplate] == [$l_new_image getTemplateForMosflm]} {
		$l_new_image setInternalImageName [file tail $l_new_image]
	    } {
		$l_new_image setInternalImageName "[file dirname $l_filename]/image.[format %07g [$l_new_image getNumber]]"
	    }
	    set internal_image_name [$l_new_image getInternalImageName]
#	    set l_sector [addNewSector [$l_new_image getTemplateForMosflm]]
	    set l_sector [addNewSector [$l_new_image getTemplate]]
	    #puts "[file tail $l_filename] HeaderData  $l_new_image assigned to sector $l_sector"
	    # update image's phi values
	    $l_new_image setPhi $l_phi_start $l_phi_end

	    # Get the oscillation range
	    if { $l_phi_end > $l_phi_start } {
		set oscrange [expr $l_phi_end - $l_phi_start]
	    } else {
		# oscillation range may have crossed phi=0
		set oscrange [expr $l_phi_end + 360.0 - $l_phi_start]
	    }
	    set this_phi_range [$l_new_image reportPhis -mode "range"]
	    if { $oscrange <=  0.15 } {
		set l_smllr_partls_fract 0.25
	    } else {
		set l_smllr_partls_fract 0.35
		if { $oscrange >=  0.25 } {
		    set l_smllr_partls_fract 0.50
		}
	    }

	    # Add the image to the sector (auto-updates session tree)
	    $l_sector addImage $l_new_image -sort 0

	    # Update size of smaller fraction of summed partials appropriate for oscillation range
	    #puts "Osc.range $oscrange smaller_partials_fraction $l_smllr_partls_fract"
	    updateSetting smaller_partials_fraction $l_smllr_partls_fract 1 1 "Images"

            # Check site specific parameters have not been read from a file
            if { [getSiteFileRead] != "" } {
                .m configure \
                    -title "Site file warning" \
                    -type "2button" \
                    -text "Site configuration parameters have been read from a file.\nDo you wish those values to override values read from images?" \
                    -button1of2 "Yes" \
                    -button2of2 "No"
        
                if {[.m confirm]} {
                    # Override with site file values
                    set siteoverride 1
                }
            }
	    # Update trusted experiment data
	    updateSetting detector_manufacturer $l_detector_manufacturer 1 1 "Images"
	    updateSetting detector_model $l_detector_model 1 1 "Images"
	    updateSetting detector_serno $l_detector_serial_number 1 1 "Images"
	    updateSetting trusted_detector [$a_dom selectNodes normalize-space(//trusted_detector)] 0 0 "Images"
	    #sets NULLPIX from XML for all detectors
	    querySiteSetting nullpix [$a_dom selectNodes normalize-space(//null_pixel_value)] 1 1 "Images"
	    #updateSetting nullpix [$a_dom selectNodes normalize-space(//null_pixel_value)] 1 1 "Images"
	    #sets PKRATIO, BGRATIO from XML for all detectors
	    updateSetting pkratio [$a_dom selectNodes normalize-space(//maximum_peak_ratio)] 1 1 "Images"
	    updateSetting bgratio [$a_dom selectNodes normalize-space(//maximum_background_ratio)] 1 1 "Images"
	    #sets Maximum background gradients from XML for all detectors
	    updateSetting rejection_gradient_integration [$a_dom selectNodes normalize-space(//maximum_integration_gradient)] 1 1 "Images"
	    updateSetting rejection_gradient_refinement [$a_dom selectNodes normalize-space(//maximum_refinement_gradient)] 1 1 "Images"
	    updateSetting header_size [$a_dom selectNodes normalize-space(//header_size)] 1 1 "Images"
	    updateSetting image_width [$a_dom selectNodes normalize-space(//image_width)] 1 1 "Images"
	    updateSetting image_height [$a_dom selectNodes normalize-space(//image_height)] 1 1 "Images"
	    updateSetting invertx [$a_dom selectNodes normalize-space(//invertx)] 1 1 "Images"
	    querySiteSetting detector_omega [$a_dom selectNodes normalize-space(//omegafd)] 1 1 "Images" ; # check site file
	    
	    querySiteSetting distance [$a_dom selectNodes normalize-space(//distance)] 1 1 "Images" ; # check site file
	    if {![distanceIsSet]} {
		generateWarning "No crystal-to-detector distance in image header. Set this to the correct value in Experiment settings." -reason "Images"
		forceDistanceSetting
	    }

            # Test for zero oscillation angle (eg incorrect header read in HDF5 files
            if { $oscrange < 0.001 } {
                forceOscangSetting
            }

	    updateSetting two_theta [$a_dom selectNodes normalize-space(//two_theta)] 1 1 "Images"
            
            # Set orange partial prediction boxes by default for Pilatus, Eiger, TIMEpix
            set manu [string toupper [string range [$::session getParameterValue detector_manufacturer] 0 3]]
            #puts "In session, about to change prediction colour for manufacturer $manu "
            if { $manu == "PILA" || $manu == "EIGE" || $manu == "APAD" || $manu == "HDF5" || $manu == "TIME" || $manu == "RIEI" || $manu == "RIPI" || $manu == "PHOT" } {
                #puts "setting partials to orange in session for manufacturer $manu "
                .image setPredictionColour partials orange
            }

	    querySiteSetting wavelength [$a_dom selectNodes normalize-space(//wavelength)] 1 1 "Images" ; # check site file
	    if {[isLabSource $wavelength] > 0} {
		# Returns 1 for Mo, 2 for Cu, else 0
		updateSetting xray_source "lab" 1 1 "Images"
		querySiteSetting divergence_x 0.00 1 1 "Images" ; # check site file
		querySiteSetting divergence_y 0.00 1 1 "Images" ; # check site file
		querySiteSetting dispersion 0.0025 1 1 "Images" ; # check site file
		querySiteSetting polarization 0.00 1 1 "Images" ; # check site file
		updateSetting profile_tolerance_min 0.01 1 1 "Images"
		updateSetting profile_tolerance_max 0.01 1 1 "Images"
	    }
	    if {[isLabSource $wavelength] > 1 && $detector_manufacturer != "RIPI" && $detector_manufacturer != "RIEI" && $detector_manufacturer != "PHOT" } {
		# Returns 1 for Mo, 2 for Cu, else 0
		updateSetting minpix 30 1 1 "Images"
		updateSetting threshold 3.5 1 1 "Images"
		updateSetting spot_rms_var 1.0 1 1 "Images"
	    }
	    set l_pixel_size [$a_dom selectNodes normalize-space(//pixel_size)]
	    if { (($l_pixel_size == "") || ([string compare [format %.4f $l_pixel_size] "0.0000"] == 0)) && \
                 !([info exists sitesetting(pixel_size)] && ($sitesetting(pixel_size) != "") && ($siteoverride)) } {
		# updateSetting pixel_size 0.1 1 1 "Images"
		# generateWarning "No pixel size information in image header. Setting pixel size to 0.1mm." -reason "Images"
                forcePixelSizeSetting
	    } else {
		querySiteSetting pixel_size $l_pixel_size 1 1 "Images"
	    }

	    updateSetting yscale [$a_dom selectNodes normalize-space(//yscale)] 0 1 "Images"

            querySiteSetting gain [$a_dom selectNodes normalize-space(//gain)] 0 1 "Images" ; # check site file

	    # Why a second time?
	    #querySiteSetting detector_omega [$a_dom selectNodes normalize-space(//omegafd)] 0 0 "Images" ; # check site file

	    querySiteSetting adcoffset [$a_dom selectNodes normalize-space(//adc_offset)] 0 1 "Images" ; # check site file
	    #updateSetting adcoffset [$a_dom selectNodes normalize-space(//adc_offset)] 0 1 "Images"
	    updateSetting overload_cutoff [$a_dom selectNodes normalize-space(//saturation_pixel_value)] 0 1 "Images"
	    updateSetting profile_overload_cutoff [$a_dom selectNodes normalize-space(//maximum_pixel_value)] 0 1 "Images"
	    updateSetting size_central_region [$a_dom selectNodes normalize-space(//central_region_size)] 0 1 "Images"
	    
	    # Extract image orientation information
	    updateSetting origin [$a_dom selectNodes normalize-space(//spotfile_origin)] 0 0 "Hidden"
	    updateSetting axis_order [$a_dom selectNodes normalize-space(//spotfile_axis_order)] 0 0 "Hidden"
	    updateSetting two_theta_direction [$a_dom selectNodes normalize-space(//twotheta_swing_axis)] 0 0 "Hidden"

	    # Only set beam position if image is from reliable detector
	    set header_beam_x [$a_dom selectNodes normalize-space(//beam_x)]
	    set header_beam_y [$a_dom selectNodes normalize-space(//beam_y)]
	    set error_message [catch {set beamstop_radius [$a_dom selectNodes normalize-space(//beamstop_radius)]}]

	    if {[lsearch [list MAR180 MAR300 MAR345 DIP20X0 M300 M180 M345] $detector_model] > -1 || $detector_manufacturer == "DIP2" } {
		updateSetting spiral 1 1 1 "Images"
	    }
	    # Search list of known reverse phi ADSC detectors by serial number
	    # 930 was reversephi in October 2010, by July 2015 it wasn't. No-one said anything 
	    # when the change was made, and the images don't have the date in the header 
	    # so you can't tell anyway.
	    #
	    if {[lsearch [list 457 915 928] $l_detector_serial_number] > -1 && $l_detector_manufacturer == "ADSC" } {
                querySiteSetting reverse_phi 1 1 1 "Images" ; # check site file
	    }
            #puts "trusted_detector is $trusted_detector"
	    if { $trusted_detector } {
		querySiteSetting beam_x $header_beam_x 1 1 "Images" ; # check site file
		querySiteSetting beam_y $header_beam_y 1 1 "Images" ; # check site file
		#updateSetting backstop_x $header_beam_x 1 1 "Images"
		#updateSetting backstop_y $header_beam_y 1 1 "Images"
		updateSetting backstop_x $beam_x 1 1 "Images"
		updateSetting backstop_y $beam_y 1 1 "Images"
                #puts "backstop coords $backstop_x $backstop_y"
		updateSetting backstop_radius $beamstop_radius 1 1 "Images"
                #puts "backstop_radius set to $beamstop_radius"
	    } else {
		generateWarning "No beam information in image header. Setting beam and backstop positions to image centre." -reason "Images"
		updateSetting backstop_x [expr ($image_width * $pixel_size) * 0.5] 1 1 "Images"
		updateSetting backstop_y [expr ($image_height* $pixel_size) * 0.5] 1 1 "Images"
		querySiteSetting beam_x $backstop_x 1 1 "Images" ; # check site file
		querySiteSetting beam_y $backstop_y 1 1 "Images" ; # check site file
	        #puts "Bckstp x,y = $beam_x $beam_y"
	    }

	    updateSetting beam_y_corrected [expr $beam_y * $yscale] 1 1 "Images"

	    set initial_detect_param(beam_x) $beam_x
	    set initial_detect_param(beam_y) $beam_y
	    set initial_detect_param(beam_y_corrected) $beam_y_corrected
	    set initial_detect_param(distance) $distance
	    set initial_detect_param(yscale) $yscale

	    set l_bbox_dir [$a_dom selectNodes normalize-space(//background_box_direction)]
	    if {$two_theta >= 0} {
		if {$l_bbox_dir == "F"} {
		    updateSetting bbox_orientation "North" 1 1 "Images"
		} else {
		    updateSetting bbox_orientation "East" 1 1 "Images"
		}
	    } {
		if {$l_bbox_dir == "F"} {
		    updateSetting bbox_orientation "South" 1 1 "Images"
		} else {
		    updateSetting bbox_orientation "West" 1 1 "Images"
		}
	    } 
	    set l_bbox_offset [$a_dom selectNodes normalize-space(//background_box_offset)]
	    if {$l_bbox_offset != "0"} {
		updateSetting bbox_offset "$l_bbox_offset" 1 1 "Images"
	    }
	    
	    # Calculate smallest dimension size
	    set l_min_dimension [expr ($image_width < $image_height ? $image_width : $image_height) * $pixel_size]

	    # Calculate spot search area
#	    updateSetting search_area_min_radius [expr 0.025 * $l_min_dimension] 1 1 "Images"
	    updateSetting search_area_min_radius 2.0 1 1 "Images"
	    updateSetting search_area_max_radius [expr 0.475 * $l_min_dimension] 1 1 "Images"

	    # Calculate default resolution limits
	    set l_use_inscribe_circle 1
	    if {$l_use_inscribe_circle} {
		# Calculate beam position relative to detector centre
		set l_det_centre_x [expr ($image_width * $pixel_size) * 0.5]
		set l_det_centre_y [expr ($image_height * $pixel_size) * 0.5]
		set l_inscribe_r [expr $l_min_dimension * 0.5]
		
		set l_dx [expr $beam_x - $l_det_centre_x]
		set l_dy [expr $beam_y - $l_det_centre_y]


# luke 27 November 2008
# I commented out the next if else set of statements.
# There are two points to make
# 1) When l_dx is zero and l_dy is positive or zero then things work fine
#    However, the possibility of l_dy being negative is left unaccounted
#    This was highlighte with Roger Rowlett's RAXIS image which happened to have
#    beam_x set exactly at the detector centre ==> l_dx was zero
#    but beam_y was 149.85 (detector_centre 150.00) so l_dy was negative
#    thus throwing an error since l_max_res_x and l_max_res_y were undefined.
# 2) I don't understand what the code is doing in the if statement so I replaced the following
#    I now calculate l_angle with the atan2 function rather than atan
#    Atan2 can deal with angles all the way around the trigonometric circle whereas atan doesn't.
#    I am not sure about the details but it works and there is not chance of division by zero 
#    as in atan where we were dividing l_dy/l_dx
#    A few lines further down I calculate l_new_dx with sin and l_new_dy with cos
#    It was the other way around when we were using atan
#    Again, I don't know why this needs to be done but it works as before
#
#		if {[format %.3f $l_dx] == "0.000"} {
#		    if {$l_dy >= 0} {
#			set l_max_res_x $l_det_centre_x
#			set l_max_res_y 0
#		    } 			
#		} else {
		    # Work angle between detector centre and beam centre
#		    set l_angle [expr atan(double($l_dy)/$l_dx)]
		if { $l_dx == 0 && $l_dy == 0 } {
		    set l_angle 0.0
		} else {
		    set l_angle [expr atan2((double($l_dx)),(double($l_dy)))]
		}
#	puts "ANGLE $l_angle"
		    # Work out coords of point projected from det. centre,
		    #  through beam centre to inscribe circle (relative to
		    #  det. centre)
#		    set l_new_dx [expr cos($l_angle) * $l_inscribe_r]
#		    set l_new_dy [expr sin($l_angle) * $l_inscribe_r]
		    set l_new_dx [expr sin($l_angle) * $l_inscribe_r]
		    set l_new_dy [expr cos($l_angle) * $l_inscribe_r]
		    # reverse polarity to project point through det centre
		    #  from beam
		    set l_new_dx [expr -1 * $l_new_dx]
		    set l_new_dy [expr -1 * $l_new_dy]

		    # Calculate new coords in global frame
		    set l_max_res_x [expr $l_det_centre_x + $l_new_dx]
		    set l_max_res_y [expr $l_det_centre_y + $l_new_dy]
#			puts "mas_res_x $l_max_res_x"
#			puts "mas_res_y $l_max_res_y"
#		}
		set l_resolution [calcResolution [list $l_max_res_x $l_max_res_y]]
		updateSetting high_resolution_limit $l_resolution 1 1 "Images"
	    } else {
		# Find corner with highest resolution
		set l_highest_resolution 999
		foreach i_coord_mm [list [list 0 0] \
					[list 0 [expr $image_height * $pixel_size]]\
					[list [expr $image_width * $pixel_size] 0]\
					[list [expr $image_width * $pixel_size] [expr $image_height * $pixel_size]]] {
		    set l_resolution [calcResolution $i_coord_mm]
		    if {$l_resolution < $l_highest_resolution} {
			set l_highest_resolution $l_resolution
		    }
		}
		updateSetting high_resolution_limit $l_highest_resolution 1 1 "Images"
	    }

            # Adjust pattern matching resolution limit final if necessary
            set hr_set [$::session getParameterValue high_resolution_limit]
            if { $hr_set < [$::session getParameterValue pm_resfinl] } {
                $::session updateSetting pm_resfinl $hr_set 1 1 "User"
            }

	    # Find resolution at default backstop radius
	    updateSetting low_resolution_limit [calcResolution [list $beam_x [expr $beam_y + $backstop_radius]]] 1 1 "Images"
	    if { $low_resolution_limit > 100 } {
		updateSetting low_resolution_limit 100 1 1 "Images"
	    }
	    # Do we set the anisotropic resolution limits to be isotropic here, I wonder?

	    # Search for other images in the same directory with the same template 

	    #added by luke on 14 November 2007
	    #it the selectedimages variable in the addImages widget
	    #is set to false only then do we glob for all the images
	    #with a particular template
	    # Open first image before we process the list to be added, not after
	    .image openImage $l_new_image

            # Add the first image to the indexing list
            #puts "First image detected [$l_new_image getShortName]"
            lappend indexing_list [$l_new_image getNumber]
	    # chunking does not always clear the list, so sometimes need to make 
	    # it unique
	    set indexing_list [lsort -unique -integer $indexing_list]

            if { [winfo exists .addImages] } {
                #puts ".addImages window exists"
                if { [.addImages getSelectedImages] == 0 } {
                    #puts "Selected images not checked"
                    getglobbedImages $l_new_image
                } else {
                    #puts "Selected images checked"
                    addImageList $globbed_images
                }
            } else {
                #puts ".addImages window absent"
                if { $addmultipleimagefiles == 1 } {
                    getglobbedImages $l_new_image
                } else {
                    addNextImage [lindex $globbed_images 0]
                }
	    }
	}	
    }
            #puts "about to assign display manufacturer to $detector_manufacturer"
            #puts "detector_manufacturer_extra is: $detector_manufacturer_extra"
            set l_display_manufacturer $detector_manufacturer
	    if { $detector_manufacturer == "PHOT" } {
               set l_display_manufacturer "Bruker Photon"
            } else {
	     if { $detector_manufacturer == "HDF5" } {
		if { ($detector_manufacturer_extra == "2") } {
                    set l_display_manufacturer "Eiger2"
                } else {
                    set l_display_manufacturer "Eiger"
                }
             } else {
                if { ($detector_manufacturer == "EIGE") || ($detector_manufacturer == "RIEI") } {
		    if { ($detector_manufacturer_extra == "2") } {
                        set l_display_manufacturer "Eiger2"
                    } else {
                        set l_display_manufacturer "Eiger"
                    }
                } else {
                    if { ($detector_manufacturer == "PILA") || ($detector_manufacturer == "RIPI") } {
			if { ($detector_manufacturer_extra == "") } {
                           set l_display_manufacturer "Pilatus"
                        } else {
                            if { ($detector_manufacturer_extra == "3") } {
                               set l_display_manufacturer "Pilatus3"
                            }
                        }
                    } else {
                       # Allow for electron diffraction images written in SMV format from
                       # an unknown detector. Flagged with extra character "U" after ADSC.
                       if { ($detector_manufacturer == "ADSC") } {
			  if { ($detector_manufacturer_extra == "") } {
                             set l_display_manufacturer "ADSC"
                          } else {
                              if { ($detector_manufacturer_extra == "U") } {
                                 #puts "ADSCU detected"
                                 if { $siteoverride && [info exists sitesetting(gain)] && ($sitesetting(gain) != "") } {
                                    #puts " gain supplied in site file"
				 } else {
                                    .m configure \
       	                               -title "Unrecognised detector" \
	                               -type "1button" \
	                               -button1of1 "Dismiss" \
	                               -text "Mosflm does not recognise this detector\nAssumed to be for electron diffraction\nThe GAIN for these detectors is typically in the range 2 to 4\nAs spotfinding depends critically on the GAIN it has been set to 2.0\nThe ADC offset has been set to zero, Null pixel threshold to -1\nand the beam polarisation and dispersion set to suitable values\nYou may need to adjust the GAIN, check warnings after an integration run\nTo avoid this message in future, set the GAIN using the site file option\nimosflm --site <filename>\n(See Tutorial section 14.1 for details)"

                                     if {[.m confirm]} {
                                     }
                                  }


                                 set l_display_manufacturer "Unknown"
                                 # set new defaults for polarisation, dispersion, divergence
                                 querySiteSetting polarization 0.0 1 1 "Images" ; # check site file
                 		 querySiteSetting divergence_x 0.00 1 1 "Images" ; # check site file
		                 querySiteSetting divergence_y 0.00 1 1 "Images" ; # check site file
		                 querySiteSetting dispersion 0.0001 1 1 "Images" ; # check site file
                              }
                          }
		       }
                    }
		}
              }
            }

            #puts "l_display_manufacturer is $display_manufacturer"
            updateSetting display_manufacturer $l_display_manufacturer 0 1 "Images"
}

body Session::isLabSource { a_wavelength } {
    if {($wavelength > (1.5418 - 0.002)) && \
	    ($wavelength < (1.5418 + 0.002))} {
	#puts "isLabSource - Cu"
	return 2
    }
    if {($wavelength > (0.7107 - 0.0002)) && \
	    ($wavelength < (0.7107 + 0.0002))} {
	#puts "isLabSource - Mo"
	return 1
    }
    return 0
}
# method to process brief_header_response xml message (containing an 
#  image's phin values)

body Session::processBriefHeaderData { a_dom } {
#	set wait_xml "<?xml version='1.0'?><!DOCTYPE brief_header_response><brief_header_response><status><code>ok</code></status><image_filename>/home/lukek/LearnMosflm/deleteSector/fiveimgs/hg_010.mar1600</image_filename><phi_start>      10.00</phi_start><phi_end>      11.00</phi_end><gain>   1.00</gain></brief_header_response>"
#	set wait_dom [dom parse $wait_xml]
#	puts [$wait_dom selectNodes string(/brief_header_response/status/code)]
    # Check on status of task
    set status_code [$a_dom selectNodes string(/brief_header_response/status/code)]
    if {$status_code == "error"} {
#	puts "received a error"
	set error_message "[$a_dom selectNodes string(/brief_header_response/message)]"
#	puts $error_message 
	set error_image "[$a_dom selectNodes normalize-space(//image_filename)]"
	if {$error_message == "problem reading image - check file permissions"} {
	    .m configure \
		-type "2button" \
		-title "Error in opening image file" \
		-text "Could not open file:\n\"$error_image\"\nError message: $error_message\n\nDo you want to allow iMosflm to try to change the file\npermissions for you?\n\nThis will start a new session, so if you don't want to do that,\nyou should exit iMosflm and change the permissions yourself" \
		-button1of2 "Allow" \
		-button2of2 "Deny"
	    if { [.m confirm] } {
		set change_permissions "1"
	    } {
		set change_permissions "0"
	    }
	    if { $change_permissions == "1" } {
		if {! [file readable $error_image]} { 
		    file attributes $error_image -permissions +r 
		} {
		    deleteImages [Image::getImageByPath $error_image]
		}
	    }
	    set image_object [namespace current]::[Image \#auto "build" "$error_image"]
	    # change for all that have this template
	    # Get a glob pattern from image to search for rest of dataset
	    regsub {\#+} [$image_object getTemplate] "*" l_glob_pattern
	    # Glob for possible image files from same dataset
	    set l_possible_image_files [glob -nocomplain [file join [$image_object getDirectory] $l_glob_pattern]]
	    # Get a regexp to REALLY check the filenames are matches
            # Also permit the + character within the image filename
            regsub -all {\+} [$image_object getTemplate] "\\+" l_regexp0
	    regsub -all {\#} $l_regexp0 "\\d" l_regexp 
	    deleteImages $image_object
	    delete object $image_object
	    foreach i_file $l_possible_image_files {
		# if the file matches the regexp
		if {[regexp $l_regexp $i_file]} {
		    # if the file hasn't already been added
		    if {[Image::getImageByPath $i_file] == ""} {
			# add the file to the list of further files to be added
			if { $change_permissions == "1" } {
			    file attributes $i_file -permissions +r
			} {
			    deleteImages [Image::getImageByPath $i_file]
			}
		    }
		}
	    }
	    if { $change_permissions == "1" } {
		set change_permissions "0"
		# doesn't initialize properly .c newSession 
		# otherwise just restart mosflm
		Mosflm::restartMosflm
	    }
	}
    } elseif {$status_code == "notification"} {
	set notification_message [$a_dom selectNodes normalize-space(//message)]
	if {[regexp "image does not exist yet" $notification_message]} {
	    .c component integration component process configure -state disabled
	    .c component integration component cancel configure -state disabled
	} elseif {[regexp "image exists now" $notification_message]} {
	    .c component integration component process configure -state normal
	    .c component integration component cancel configure -state normal
	}
    } else {
	# get filename from xml
	set l_image_number [$a_dom selectNodes normalize-space(//image_number)]
	set l_filename [$a_dom selectNodes normalize-space(//image_filename)]
	set l_template [$a_dom selectNodes normalize-space(//image_template)]
	set l_contig [$a_dom selectNodes normalize-space(//contig)]
	set l_filename [file normalize $l_filename]
        eval set ::timeri$l_image_number [clock clicks -milliseconds]
        #eval puts \"timeri$l_image_number [expr (\$::timeri$l_image_number) - \$::timeri[expr ($l_image_number - 1)]] milliseconds\"
        if { [winfo exists .addImages] } {
            #puts ".addImages window exists"
            if { [.addImages getSelectedImages] == 0 } {
                #puts "Selected images not checked"
                set globbed_images [lrange $globbed_images 1 end]
            } else {
                #puts "Selected images checked"
                if { $firstimagematching == [file tail $l_filename] } {
                    # Do not delete the first in the list if this image matches a previous
                    # sector loaded when the head of the list will be the next image required
                    #puts "firstimagematching $firstimagematching"
                    set firstimagematching ""
                    addImageList $globbed_images
                } else {
                    #puts "not the first image matching"
                }

            }
        } else {
            #puts ".addImages window absent"
            if { $addmultipleimagefiles == 1 } {
                set globbed_images [lrange $globbed_images 1 end]
            }
        }

	# extract data from xml
	set l_phi_start [$a_dom selectNodes normalize-space(//phi_start)]
	set l_phi_end [$a_dom selectNodes normalize-space(//phi_end)]

	# Create a new image and find the matching sector for it


	if { $::env(HDF5file) == 1 } {
		set i_file "[file dirname $l_filename]/image.[format %07g $l_image_number]"
	    } {
		set i_file $l_filename
	    }

	set l_new_image [namespace current]::[Image \#auto "build" "$i_file"]
	$l_new_image setInternalImageName "[file dirname $l_filename]/image.[format %07g $l_image_number]"
	set l_sector [getSectorByTemplate [$l_new_image getTemplate]]
	if { $l_sector == "" } {
	    set l_sector [addNewSector [$l_new_image getTemplate]]
	    #puts "[file tail $l_filename] BriefHeader $l_new_image assigned to sector $l_sector"	    
	} else {
	    #puts "[file tail $l_filename] BriefHeader $l_new_image assigned to sector $l_sector"
	}
	# update image's phi values & image number
	$l_new_image setPhi $l_phi_start $l_phi_end
	$l_new_image setNumber $l_image_number

	set fname [file tail $l_filename]
	#puts "$fname gives $l_new_image in processBriefHeaderData response"

        if { [winfo exists .addImages] } {
            #puts ".addImages window exists"
            if { [.addImages getSelectedImages] == 0 } {
                #puts "Selected images not checked"
                if { [ llength $globbed_images ] == 0 } {
                    set globbed_images [ getglobbedImages $l_new_image ]
                }
            } else {
                #puts "Selected images checked"
                if { [ llength $globbed_images ] > 0 } {
                    #puts "Number in globbed_images: [llength $globbed_images]"
                    # Use length of globbed_images as a counter to know when to sort
                    set globbed_images [lrange $globbed_images 1 end]
                }
            }
        } else {
            #puts ".addImages window absent"
            if { $addmultipleimagefiles == 1 } {
                if { [ llength $globbed_images ] == 0 } {
                    set globbed_images [ getglobbedImages $l_new_image ]
                }
            } else {
                #puts "Number in ImageList: [llength $ImageList]"
                addNextImage [lindex $globbed_images 0]
                set globbed_images [lrange $globbed_images 1 end]
            }
        }

	# If it was the last image...
	if {[llength $globbed_images] == 0} {
            if { $addmultipleimagefiles == 1 } {
                # Reset command line flag
                setMultipleImageFiles 0
            }
            if { $addsingleimagefile == 1 } {
                # Reset command line flag
                setSingleImageFile 0
            }
	    # Add the image to the sector (auto-updates session tree) and sort
	    $l_sector addImage $l_new_image -sort 1 -update_interface 1 -update_imagecombo 1
# enable button on chunked images pop-up when list of images is complete
            if { [reportOscRange] <= 0.1999 && $::env(HDF5file) == "1" && $l_contig == "0"  && [.ats component processing getSumImagesPopupRelayBool] > 0 } {
	       .chunk updateContents
	       .chunk show
            } else {
	       .chunk hide
            }
            .chunk enableButton
        } else {
	    # otherwise just add the image to the sector without bothering to sort
	    $l_sector addImage $l_new_image -sort 0 -update_interface 1 -update_imagecombo 1
	}

        #eval puts \"timeri$l_image_number [expr (\$::timeri$l_image_number) - \$::timeri[expr ($l_image_number - 1)]] ms. in processBriefHeader\"
        #puts "Brief header response for $fname after [expr ([clock clicks -milliseconds] - $::timer07)/1000.] secs."
    }
    return $l_image_number
}

body Session::processWaitBriefHeaderData {a_dom} {
    set l_filename [$a_dom selectNodes normalize-space(//image_filename)]
    set l_filename [file normalize $l_filename]

    set globbed_images [lreplace $globbed_images 0 0]
    #puts "in processWaitBriefHeaderData - globbed_images:"
    #puts $globbed_images

    # extract data from xml
    set l_phi_start [$a_dom selectNodes normalize-space(//phi_start)]
    set l_phi_end [$a_dom selectNodes normalize-space(//phi_end)]

    # Create a new image and find the matching sector for it
    set l_new_image [namespace current]::[Image \#auto "build" "$l_filename"]
    #puts "this is the new image $l_new_image"
    #puts [$l_new_image getTemplate]
    set l_sector [getSectorByTemplate [$l_new_image getTemplate]]
    #puts "this is the sector it belongs to $l_sector"
    #puts "in processWaitBriefHeaderData - l_sector is: $l_sector"

    # update image's phi values
    $l_new_image setPhi $l_phi_start $l_phi_end

    # If it was the last image...
    if {[llength $globbed_images] == 0} {
	# Add the image to the sector (auto-updates session tree) and sort
	$l_sector addImage $l_new_image -sort 1 -update_interface 1
	#puts "just after sector addImage"
    } else {
	# otherwise just add the image without bothering to sort
	$l_sector addImage $l_new_image -sort 0 -update_interface 1 -update_imagecombo 0
	#puts "just after sector addImage two"
# enable button on chunked images pop-up when list of images is complete
    .chunk enableButton
    }
}

body Session::forceOscangSetting { } {
    # if the oscrange is zero
	# Get user to set phi start and end
	.m configure \
	    -type "2button" \
	    -title "Oscillation range is zero, image header not correctly read?" \
	    -text "After images have all been read, edit phi values for the first image \nin order to set phi values for all images BEFORE Indexing" \
	    -button1of2 "OK" \
	    -button2of2 "Ignore"
	if { [.m confirm] } {
	    # .ass show
	    # raise .ass
	} else {
	    # return failure!
            return 0
        }
}

body Session::setBeamToImageCentre { } {
    # Calculate image centre (in mm)
    set t_beam_x [expr 0.5 * $image_width * $pixel_size]
    set t_beam_y [expr 0.5 * $image_height * $pixel_size]
    # if the beam's x coordinate has changed
    if {$t_beam_x != $beam_x} {
	# update the beam_x setting
        updateSetting beam_x $t_beam_x 1 1 "User"
    }
    # if the beam's y coordinate has changed
    if {$t_beam_y != $beam_y} {
	# update the beam_y setting
        updateSetting beam_y $t_beam_y 1 1 "User"
    }
}

# Force the user to set the beam
body Session::forceBeamSetting { } {
    # if the beam hasn't been set
    if {![beamIsSet]} {
	# Ask the user if they want to set the beam to the image centre
        .m configure  -title "Warning"  -text "The beam position has not been set.\nUse image centre? (Dangerous!)"  -type "YesNo"  -text0 "Cancel"  -text1 "Ok"
        if {[.m confirm]} {
	    # if they do, do it
            setBeamToImageCentre
	    # return success!
            return 1
        } else {
	    # return failure!
            return 0
        }
    } else {
	# return success (as beam is already set)
        return 1
    }
}

body Session::forceDistanceSetting { } {
    # if the distance hasn't been set
    if {![distanceIsSet]} {
	# Get user to set distance
	.m configure \
	    -type "2button" \
	    -title "No crystal-to-detector distance set" \
	    -text "Set this to the correct value in Experiment settings.\nNote: this can be set using a Site File (See Tutorial)" \
	    -button1of2 "OK" \
	    -button2of2 "Ignore"
	if { [.m confirm] } {
	    .ass show
	    raise .ass
	} else {
	    # return failure!
            return 0
        }
    } else {
	# return success (as distance is already set)
        return 1
    }
}

body Session::distanceIsSet { } {
    if { ($distance == "") || ([string compare [format %.4f $distance] "0.0000"] == 0) } {
        return 0
    } else {
        return 1
    }
}

body Session::forcePixelSizeSetting { } {
	# Get user to set pixel size
	.m configure \
	    -type "1button" \
	    -title "No pixel size set!!" \
	    -text "Pixel size set to 0.1mm to allow program to continue.\nYou must set this to the correct value in Detector settings." \
	    -button1of1 "OK" 
	if { [.m confirm] } {
	    .ass show
	    raise .ass
	} else {
	    # return failure!
            return 0
        }
        updateSetting pixel_size 0.1 1 1 "Images"
}

# parameter accessor methods

body Session::getDistance { } {
    return $distance
}

body Session::getWavelength { } {
    return $wavelength
}

body Session::getHighResolution { } {
    return $high_resolution_limit
}

body Session::getTwoTheta { } {
    return $two_theta
}

body Session::getImageHeight { } {
    return $image_height
}

body Session::getImageWidth { } {
    return $image_width
}

body Session::getDetectorOmega { } {
    return $detector_omega
}

body Session::getInvertX { } {
    return $invertx
}

body Session::getReversePhi { } {
    return $reverse_phi
}

body Session::getSpiral { } {
    return $spiral
}

body Session::setPhiIncorrectInHeader { } {
    set phi_correct_in_header "0"
    return $phi_correct_in_header
}

body Session::getPhiCorrectInHeader { } {
    return $phi_correct_in_header
}

body Session::getDetectorManufacturer { } {
    return $detector_manufacturer
}



# method to return a string with full information about the detector
body Session::getFullDetectorInformation { } {
    set l_fullinformation ""
    set l_fulldetectorinformation ""
    if { $detector_manufacturer != "" } {
	if { $detector_manufacturer == "RAXI" || $detector_manufacturer == "DIP2" } {
	    lappend l_fullinformation $detector_model
	} else {
	    lappend l_fullinformation $detector_manufacturer
	}
	# can be set in non-expert mode for I24
	if { $detector_omega != "" } {
	    lappend l_fullinformation "omega"
	    lappend l_fullinformation "[$::session getDetectorOmega]"
	}
	if { [$::session getReversePhi] } {
	    lappend l_fullinformation "reversephi"
	}
	if { $detector_rowreadt != "" } {
	    append l_fullinformation " rowreadt" 
	    append l_fullinformation " $detector_rowreadt"
	}
	if { $detector_rotnspeed != "" } {
	    append l_fullinformation " rotnspeed" 
	    append l_fullinformation " $detector_rotnspeed"
	}
        if {$invertx != "" } {
            lappend l_fullinformation "invertx"
            lappend l_fullinformation "[$::session getInvertX]"
        }	
	if { $l_fullinformation != ""  } {
	    set l_fulldetectorinformation [concat "detector" $l_fullinformation]
	}
    }
    if { $l_fullinformation != $this_detector_information  } {
	set this_detector_information $l_fullinformation
	return $l_fulldetectorinformation
    } {
	return
    }
}

# method to force user to estimate mosaicity - now automatically done!
# need to ensure a estimate is made if a value of zero is entered by user
# 11/7/18 AL
body Session::forceMosaicityEstimation { } {
    if {(![mosaicityIsSet]) || ( $mosaicity == 0.0000 ) } {
        set f_image [lindex [[getCurrentSector] getImages] 0]
        eval .me launch $f_image
    } else {
        # If mosaicity has been entered without <CR> or Tab predictions are not updated
        # puts "debug: update predictions from forcemosaicity"
        updatePredictions
    }
    return 1
}

# method to work out if mosaicity has been set
body Session::mosaicityIsSet { } {
    # Check the history for a mosaicity update!
    return [$history hasParameterBeenUpdated mosaicity]
}

# method to estimate mosaicity
body Session::estimateMosaicity { } {
    # Launch mosaicity estimation with first image used in indexing
    set l_image [lindex $images_being_autoindexed 0]
    if {$l_image == ""} {
	set l_image [.image getImage]
    }
    eval .me launch $l_image
}

# Spotfinding settings methods ###############################################

body Session::initializeSearchRadius { } {
    # get the largest image dimension (width or height)
    if {$image_width > $image_height} {
	set max_diameter $image_width
    } else {
	set max_diameter $image_height
    }
    # set search radius limits to 5% and 95% of the max dimension
    #puts $search_area_min_radius
    set search_area_max_radius [expr 0.90 * ( 0.5 * ($max_diameter * $pixel_size))]
    set search_area_min_radius "2.0"
     
    # update the image viewer
    .image updateSetting search_area_min_radius $search_area_min_radius
    .image updateSetting search_area_max_radius $search_area_max_radius
}

body Session::getFindspotsParameters { } {
    # method to provide mosflm object with parameters for findspots comand
    set parameters "threshold $threshold"
    if {$search_area_min_radius != ""} {
	set rmin $search_area_min_radius
    } else {
	set rmin $default_search_area_min_radius
    }
    if {$search_area_max_radius != ""} {
	set rmax $search_area_max_radius
    } else {
	set rmax $default_search_area_max_radius
    }

    append parameters " split $spot_splitting_x $spot_splitting_y"
    append parameters " minx $spot_size_min_x"
    append parameters " maxx $spot_size_max_x"
    append parameters " miny $spot_size_min_y"
    append parameters " maxy $spot_size_max_y"
##############################################################################
#modified by luke on 11 October 2007
#This used to be North 
    if {$bbox_orientation == "South"} {
	set offset_subcommand " xoffset $bbox_offset"
	set rmin_subcommand " rmin $rmin"
	set rmax_subcommand " rmax $rmax"
#This used to be South 
   } elseif {$bbox_orientation == "North"} {
	set offset_subcommand " xoffset $bbox_offset"
	set rmin_subcommand " rmin [expr - $rmin]"
	set rmax_subcommand " rmax [expr - $rmax]"
#This used to be East
    } elseif {$bbox_orientation == "West"} {
	set offset_subcommand " yoffset $bbox_offset"
	set rmin_subcommand " rmin $rmin"
	set rmax_subcommand " rmax $rmax"
#This used to be West
    } elseif {$bbox_orientation == "East"} {
	set offset_subcommand " yoffset $bbox_offset"
	set rmin_subcommand " rmin [expr - $rmin]"
	set rmax_subcommand " rmax [expr - $rmax]"
    }
    append parameters $rmin_subcommand
    append parameters $rmax_subcommand
    append parameters $offset_subcommand
    append parameters " xmin $exclusion_segment_vertical"
    append parameters " ymin $exclusion_segment_horizontal"
##############################################################################

    if {$minpix != ""} {
	append parameters " minpix $minpix"
    }

    append parameters " MAXPEAK $max_unresolved_peaks"
    append parameters " BOX $local_background_box_size_x $local_background_box_size_y"
    append parameters " RMSFACTOR $spot_rms_var"
    append parameters " ANISOMAX $spot_anisotropy"
    
    if {$auto_resolution} {
        append parameters " AUTORESLN"
    } else {
	append parameters " NOAUTORESLN"
    }

    if {$auto_ring} {
        append parameters " AUTORING"
    } else {
        append parameters " NOAUTORING"
    }

    if {[set local_background]} {
        append parameters " LOCAL"
    }	

    if {$exclude_ice == 1} {
        append parameters " ICE"
    } else {
        append parameters " NOICE"
    }

    if {$nsum_pil_spf != "0"} {
        append parameters " sumimages $nsum_pil_spf"
    }

    return $parameters
}

# Indexing settings methods ##################################################

body Session::getIndexSubcommands { } {
    # method to provide mosflm object with indexing subcommands
    set subcommands "dps threshold $i_sig_i"

    set hkldmax [getHKLDevMax]
    if {$find_multiple_lattices} {
	if { $hkldmax == "0.300" } {
	    set hkldmax 0.200
	}
	append subcommands " multi hkldev $hkldmax"
    } else {
	append subcommands " hkldev $hkldmax"
    }

    if {!$fix_distance_indexing} {
	append subcommands " unfixdist"
    }

    set numvectors [getNumVectors]
    append subcommands " nvect $numvectors nvref $numvectors"

    if {$exclude_auto} {
	append subcommands " exclude auto"
    }

    if {$fix_max_cell_edge == "1"} {
	if {$max_cell_edge == ""} {
	    updateSetting "fix_max_cell_edge" "0" "1" "1" "Indexing"
	    #append subcommands " maxcell 0" - Harry says we never need send this 29.vi.2012
	} else {
	    append subcommands " maxcell $max_cell_edge"
	}
    } else {
	#append subcommands " maxcell 0" - Harry says we never need send this 29.vi.2012
    }	
    return $subcommands
}

# accessor methods for indexing settings

body Session::getFixedDistance { } {
    return $fix_distance_indexing
}

body Session::getSigmaCutoff { } {
    return $sigma_cutoff
}

body Session::getISigmaI { } {
    return $i_sig_i
}

body Session::getISigmaIdelta { } {
    return $i_sig_i_delta
}

body Session::getHKLDevMax { } {
    return $hkldev_max
}

body Session::getNumVectors { } {
    return $numvectors
}

body Session::getMultipleLattices { } {
    return $find_multiple_lattices
}

body Session::setMultipleLattices { val } {
    set find_multiple_lattices $val
}

body Session::setBeamEditedImage { val } {
    set beamEditedImage $val
}

body Session::getBeamEditedImage { } {
    return $beamEditedImage
}

# Setting updating methods ###################################################
#
# method to update a session parameter, which can also:
#  - record the update in the history
#  - update the image viewer
#  - update the appropriate settings dialog
#  - update the main controller
#  - update predictions
#
# according to parameter and flags

body Session::querySiteSetting { a_varname a_value {f_record "1"} {f_update_interface "0"} {a_reason "User"} { a_predict 0 } } {
    # Change default for a_predict to 0 as this method only called when reading a site file and there is not enough information to predict
    if { $siteoverride && [info exists sitesetting($a_varname)] && ($sitesetting($a_varname) != "")} {
        # If overriding image header value and site value is not null
        #puts "Using $a_varname from site file: $sitesetting($a_varname)"
        updateSetting $a_varname $sitesetting($a_varname) $f_record $f_update_interface $a_reason $a_predict
    } else {
        # Update with incoming header value
        #puts "Using $a_varname from header: $a_value"
        updateSetting $a_varname $a_value $f_record $f_update_interface $a_reason $a_predict
    }
    set initial_detect_param($a_varname) $a_value
}

body Session::updateSetting { a_varname a_value {f_record "1"} {f_update_interface "0"} {a_reason "User"} { a_predict 1 } } {

    # Record as event in history if requeseted
    if {$f_record} {
	$history addEvent "ParameterUpdateEvent" "$a_reason" "group" $a_varname [set $a_varname] $a_value
    }

    # Make the update itself!
    set $a_varname $a_value
    #puts "debug: in updateSetting set $a_varname to $a_value"
    if { $a_varname == "invertx" } {
       #set image_object [.image getImage] gives same result as l_image below
       set l_image [.image getImage]
       if { $l_image != "" } {
          set summation_method "Addition"
          set l_forceread 1
          #puts "now getting the image $l_image with summation $summation_method"
          # Get the image from mosflm and sum the required number of images using the chosen method
          $::mosflm getImage $l_image 0 0 1 $summation_method $l_forceread
       }
    }
    # Update colour of partial reflections if appropriate
    if { $a_varname == "detector_manufacturer" } {
            set manu $a_value
            #puts "About to change colour? detector is $manu"
            if { $manu == "PILA" || $manu == "EIGE" || $manu == "APAD" || $manu == "HDF5" || $manu == "TIME" || $manu == "RIEI" || $manu == "RIPI" || $manu == "PHOT" } {
                #puts "setting partials to orange in session for manufacturer $manu "
                .image setPredictionColour partials orange
            }
    }
    # Update ImageDisplay if necessary
    if {[lsearch { pixel_size origin axis_order two_theta_direction beam_x beam_y distance wavelength backstop_x backstop_y backstop_radius search_area_min_radius search_area_max_radius exclusion_segment_horizontal_check exclusion_segment_vertical_check exclusion_segment_horizontal exclusion_segment_vertical orientation high_resolution_limit low_resolution_limit i_sig_i} $a_varname] != -1} {
	if {$a_reason != "Interactive edit"} {
            # puts "debug: updating image display updates $a_varname to $a_value"
	    .image updateSetting $a_varname $a_value
	}
    }
    # Update overlays!
    if {[lsearch { beam_x beam_y distance wavelength two_theta backstop_x backstop_y backstop_radius search_area_min_radius search_area_max_radius bbox_orientation bbox_offset high_resolution_limit low_resolution_limit} $a_varname] != -1} {
            # puts "debug: updating overlays updates $a_varname to $a_value"
	Overlay::updateParameter $a_varname $a_value
    }

    if {[lsearch { beam_x beam_y distance yscale tilt twist tangential_offset radial_offset} $a_varname] != -1} {
	[.c component cell_refinement getRefinementTree] item text [.c component cell_refinement getItemsByParameter $a_varname] 1 $a_value
	[.c component integration getRefinementTree] item text [.c component integration getItemsByParameter $a_varname] 1 $a_value
    }
    
    # Update settings pannels if requested
    if {$f_update_interface} {
	SettingWidget::refresh $a_varname
	MultiSettingEntry::refresh $a_varname
	# combo boxes - must be done "by hand"
# 	if {$a_varname == "bbox_orientation"} {
# 	    [.ats component spotfinding] updateBboxOrientation $a_value
# 	}
    }

    # Update images panel of controller if necessary
    if {[lsearch { mosaicity } $a_varname] != -1} {
	.c updateMosaicity $a_value
	[.c component cell_refinement getPostrefinementTree] item text [.c component cell_refinement getItemsByParameter $a_varname] 1 $a_value
	[.c component integration getPostrefinementTree] item text [.c component integration getItemsByParameter $a_varname] 1 $a_value
    }
    
    if {[lsearch { mosaicblock } $a_varname] != -1} {
	.c updateMosaicblock $a_value
    }

    # Make new prediction if necessary
    if {$a_predict} {
	if {[lsearch { beam_x beam_y backstop_x backstop_y backstop_radius \
	    distance wavelength two_theta mosaicity mosaicblock low_resolution_limit_check \
	    high_resolution_limit_check high_resolution_limit low_resolution_limit resolution_cutoff_check \
	    aniso_res_a aniso_res_b aniso_res_c excl_res_rng \
	    resolution_cutoff num_exclusion_rings excl_1_lower excl_1_upper excl_2_lower excl_2_upper \
	    excl_3_lower excl_3_upper excl_4_lower excl_4_upper excl_5_lower excl_5_upper \
	    resolution_exclude_ice raster_nxs raster_nys raster_nc raster_nrx raster_nry \
	    spot_separation_x spot_separation_y max_refl_width } $a_varname] != -1} {
	    if {![$::mosflm busy] && ![$::session getRunningProcessing]} {
		# Only if Mosflm is not busy else flow of "continue" commands sent to Mosflm is disrupted
		# Also, do not update if the flag is set to indicate an integration run is in progress
		#puts "Changing $a_varname should update predictions if possible and Mosflm not busy"
                if {$::debugging} {
                    puts "flow: about to update predictions from Session::updateSetting for variable $a_varname "
                }
		updatePredictions
	    }
	}
    }

    # Update spot plots if necessary
    if {$a_varname == "i_sig_i"} {
	[.c component indexing] updateSpotSummary
	.image plotSpots
    }

}

# method to provide mosflm with backstop command
body Session::getBackstopCommand { } {
    return "backstop centre $backstop_x $backstop_y radius $backstop_radius"
}

# method to calculate the resolution at a given point on the detector - 
# does not work for swung out detectors
body Session::calcResolution { a_coords_mm } {
    if {$distance == 0} {
	set l_resolution "infinity"
	set radius_mm "0"
    } else {
	foreach { l_x_mm l_y_mm } $a_coords_mm break
	set l_xN [expr $l_x_mm - $beam_x]
	set l_yN [expr $l_y_mm - $beam_y]
	if {[format %.2f $two_theta] == "0.00"} {
	    
	    set radius_mm [expr sqrt(pow($l_xN,2)+pow($l_yN,2))/$distance]
	} else {
	    set rad_two_theta [expr 0.0174532925 * $two_theta]
	    set cos2theta [expr cos($rad_two_theta)]
	    set sin2theta [expr sin($rad_two_theta)]
	    set A [expr $cos2theta * $l_yN]
	    set B [expr $sin2theta * $l_yN]
	    set radius_mm [expr sqrt(pow($A,2)+pow($l_xN,2))/($distance+$B)]
	}
    }
    if {($radius_mm == 0)} {
	set l_resolution "infinity"
    } else {
	set l_resolution [expr $wavelength / (2 * sin(0.5 * atan($radius_mm)))]
	set l_resolution [format %.3f $l_resolution]
    }
    return $l_resolution
}

# method to calculate the resolution at a given point on a general detector - 
# calls Mosflm procedure
body Session::thisResolution { a_coords_mm } {
    if {$distance == 0} {
	set l_resolution "infinity"
	set radius_mm "0"
    } else {
	foreach { l_x_mm l_y_mm } $a_coords_mm break
	set l_xN [expr $l_x_mm - $beam_x]
	set l_yN [expr $l_y_mm - $beam_y]
	$::mosflm sendCommand "resolution check $a_coords_mm"
	set l_resolution $current_resolution
    }
    return $l_resolution
}

body Session::reportResolution { a_dom } {
	    set current_resolution [$a_dom selectNodes string(/resolution_response/resolution)]
	}

# method to determine if mosaicity estimation is possible
#  .i.e. is there a valid matrix and beam position
body Session::mosaicityEstimationPossible { } {
    set l_result 0
    foreach i_sector [getSectors] {
	if {[[$i_sector getMatrix] isValid]} {
	    set l_result 1
	    break
	}
    }
    if {$l_result} {    
	if {![beamIsSet]} {
	    set l_result 0
	} elseif {[reportCell] == "Unknown"} {
	    set l_result 0
	} elseif {[reportSpacegroup] == "Unknown"} {
	    set l_result 0
	}
    }
    return $l_result
}

# method to work out if it is possible to make a prediction
#  i.e. is there an image open, and does that image have a matrix
#  and is the beam set
body Session::predictionPossible { } {
    set l_result 1
    set l_image [.image getImage]
    if {$l_image == ""} {
	set l_result 0
    } else {
	set l_sector [$l_image getSector]
	if {[reportCell] == "Unknown"} {
	    set l_result 0
	} elseif {[$l_sector reportMatrix] == "Unknown"} {
	    set l_result 0
	} elseif {[reportSpacegroup] == "Unknown"} {
	    set l_result 0
	} elseif {![beamIsSet]} {
	    set l_result 0
	}
    }
    return $l_result
}

body Session::updatePredictions { } {
    if {$::debugging} {
        puts "flow: Session::updatePredictions"
    }
    # if it's possible to make a prediction, do so
    # puts "flow: In session:updatePredictions, call getPredictions"
    if {[predictionPossible]} {
	.image getPredictions
    } else {
	.image clearPredictions
    }
}

# Methods for session's member objects (cell & spacegroup) ###############

body Session::updateCell { a_reason a_cell { a_record 1 } { a_update_interface 1 } { a_predict 1 } } {
    #puts "Session::updateCell $a_cell [$a_cell reportCell]"
    # update the cell and, according to flags also record history event,
    # update the controller window, and make a new prediction
    
    if {$a_record} {
	# record event in history
	addHistoryEvent "CellUpdateEvent" $a_reason $cell $a_cell
    }
    
    # update the cell
    $cell copyFrom $a_cell
    #puts "Session cell is [[$::session getCell] listCell]"
    #puts "Cell $cell is [$cell listCell]"
    # update the controller
    .c updateCell $cell

    if { $a_predict } {
	#puts "updateCell calls updatePredictions $a_predict"
        # puts "debug: update predictions from Session::updateCell"
	updatePredictions
    }
}

body Session::validateCellAndSpacegroup { a b c alpha beta gamma { a_spacegroup P1 } } {
    # Ask Mosflm to validate the cell & spacegroup combination
    # puts "debug: send validate command with cell $a $b $c $alpha $beta $gamma"
    $::mosflm sendCommand "cell $a $b $c $alpha $beta $gamma"
    $::mosflm sendCommand "symmetry $a_spacegroup"
    $::mosflm sendCommand "validate"
    # Returns an interface_input_response as XML
}

body Session::updateSpacegroup { a_reason a_spacegroup { a_record 1 } { a_update_interface 1 } { a_predict 1 } } {
    # update the spacegroup and, according to flags also record history
    #  event, update the controller window, and make a new prediction

    if {$a_record} {
	# record event in history
	addHistoryEvent "SpacegroupUpdateEvent" $a_reason $spacegroup $a_spacegroup
    }
    
    # update the spacegroup
    $spacegroup copyFrom $a_spacegroup
    
    # update the controller
    .c updateSpacegroup $spacegroup

    if { $a_predict } {
	# update the predictions
	#puts "updateSpacegroup calls updatePredictions $a_predict"
        # puts "debug: update predictions from Session::updateSpacegroup"
	updatePredictions
    }

}

# accessor methods / reporting methods

body Session::getCell { } {
    return $cell
}

body Session::listCell { } {
    return [$cell listCell]
}

body Session::reportCell { } {
    return [$cell reportCell]
}

body Session::getSpacegroup { } {
    return $spacegroup
}

body Session::getLattice { } {
    set space_group [$spacegroup reportSpacegroup]
    foreach lattice [array names ::spacegroup] {
	#puts "Searching lattice $lattice for $space_group"
	if { [lsearch -exact $::spacegroup($lattice) $space_group] >= 0 } {
	    return $lattice
	}
    }
    return ""
}

body Session::getCurrentLattice { } {
    return $current_lattice
}

body Session::setCellBeenEdited { lattice {val 1} } {
    set cellbeenedited($lattice) $val
    if { $val eq 0 } {
        set cellbeenwarned($lattice) $val
    }
}

body Session::setCurrentLattice { req_lattice } {

    if { $current_lattice ne $req_lattice } {
	#puts "Current lattice: $current_lattice required: $req_lattice"
        set current_lattice $req_lattice
    }
}

body Session::setCurrentCellMatrixSpaceGroup { req_lattice } {

    set session_cell ""
    set solution_cell ""
    set refined_cell ""
    set chosen_cell ""

    #puts "sCCMSG Current lattice: $current_lattice required: $req_lattice"

    # update the session to use this lattice and its latest cell
    set solution [[.c component indexing getPathToLatticeTab $req_lattice] getChosenSolution]
    # The chosen solution cannot be determined if reading a saved session file so need to trap
    if { $solution eq "" } {
	#puts "solution not determined"
	return
    }

    # update the cell before the spacegroup to avoid validateCellAndSpacegroup error
    set session_cell [$::session getCell]
    set params_session [$session_cell listCell]
    set solution_cell [$solution getCell]
    set params_solution [$solution_cell listCell]
    set refined_cell [[.c component indexing getPathToLatticeTab $req_lattice] getRefinedCell]

    if { $refined_cell != "" } {
	# Got refined cell for this lattice
        set params_refined [$refined_cell listCell]
	set chosen_cell $refined_cell
        set params_chosen $params_refined
        set choice refined
    } else {
	# No refined cell - assume solution cell
	set chosen_cell $solution_cell
        set params_chosen $params_solution
        set choice solution
    }

    if { $params_session != $params_chosen } {
        if { $cellbeenedited($req_lattice) == 1 } {
            if { $cellbeenwarned($req_lattice) == 0 } {
                .m configure \
                    -title "Cells disagree" \
                    -type "2button" \
                    -button1of2 "Yes" \
                    -button2of2 "No" \
                    -text "The session cell has been edited to:\n$params_session\nand now differs from the $choice cell:\n$params_chosen\n\nKeep the edited session cell?"
                if {[.m confirm]} {
                    set chosen_cell $session_cell
                    set params_chosen $params_session
                    set choice session
                }
                set cellbeenwarned($req_lattice) 1
            } else {
                puts "You have been warned! Using $choice cell"
            }
        } else {
            # not been edited
        }
        #puts "Chosen cell: $choice $params_chosen"
    }

    #puts "Soln. [$solution getNumber] latt. $req_lattice $choice cell $params_chosen"
    $::session updateCell "Indexing" $chosen_cell 1 1 0

    # update only the current sector with new matrix and any/all images with new missets or remove the missets from the previous lattice processed
    #puts "setCurrentCellMatrixSpaceGroup: update all used sectors with new matrix [$solution getMatrix]"
    foreach i_sector [getSectors] {
        if { $i_sector == [getCurrentSector] } {
            #puts "Sector: $i_sector Template: [$i_sector getTemplate] Current sector: [getCurrentSector]"
            eval $i_sector updateMatrix "Indexing" [$solution getMatrix] 1 1 0
            foreach image [$i_sector getImages] {
                .c updateImage $image
            }
        }
    }

    # update the spacegroup
    set l_lattice_type [$solution getLattice]
    set l_spacegroup [namespace current]::[Spacegroup \#auto "initialize" "unnamed" [lindex $::spacegroup($l_lattice_type) 0]]
    #puts "Lattice: $lattice_number type: $l_lattice_type space group: [$l_spacegroup reportSpacegroup]"
    $::session updateSpacegroup "Indexing" $l_spacegroup 1 1 0
    delete object $l_spacegroup
}

body Session::getNumberLattices { } {
    return $total_lattices
}

body Session::setNumberLattices { num } {
    set total_lattices $num
}

body Session::parseNumberLattices { a_dom } {
    # Check on status of task
    set status_code [$a_dom selectNodes string(/multiple_lattice_index_response/status/code)]
    if {$status_code == "ok"} {
	set nlattices [$a_dom selectNodes normalize-space(/multiple_lattice_index_response/total_lattices_found)]
	#puts "Multiple lattices index response: $nlattices lattices found"
	if { $nlattices != [getNumberLattices] } {
	    puts "Mosflm gives $nlattices lattices, I have counted [getNumberLattices]"
	}
    } else {
	puts "Multiple lattices index response: status code $status_code"
    }
}

body Session::getLatticeList { } {
    return $lattice_numbers
}

body Session::unsetLatticeList { } {
    set lattice_numbers {}
}

body Session::removeLatticeList { num } {
    # Remove lattice num from the list
    set posn [lsearch $lattice_numbers $num]
    set lattice_numbers [lreplace $lattice_numbers $posn $posn]
    # Adjust the current lattice setting to be the first
    setCurrentLattice [lindex $lattice_numbers 0]
}

body Session::appendLatticeList { num } {
    lappend lattice_numbers $num
}

body Session::reportSpacegroup { } {
    return [$spacegroup reportSpacegroup]
}

# method to see if a matrix has been set

body Session::MatrixIsSet { } {
    set l_count_of_valid_matrices 0
    foreach i_sector [getSectors] {
	if {[$i_sector reportMatrix] != "Unknown"} {
	    incr l_count_of_valid_matrices
	}
    }
    return [expr $l_count_of_valid_matrices > 0]
}

# History methods ##############################################################

body Session::addHistoryEvent { args } {
    eval $history addEvent $args
}

body Session::addHistoryEventQuickly { args } {
    eval $history addEventQuickly $args
}

body Session::refreshHistory { } {
    $history refresh
}

body Session::hasHistoryEvents { } {
    if {[llength [$history getEvents]] > 0} {
	return 1
    } else {
	return 0
    }
}

body Session::setCrashed { } {
    # puts "setting \$crashed 1"
    set crashed 1
}
# Integration methods ##########################################################

body Session::rasterIsValid { } {
    foreach i_param {raster_nxs raster_nys raster_nc raster_nrx raster_nry} {
	if {[set $i_param] == ""} {
	    return 0
	}
    }
    return 1
}

body Session::getRaster { } {
    return "$raster_nxs $raster_nys $raster_nc $raster_nrx $raster_nry"
}


body Session::getParamsRefinedInIntegration { } {
    return [concat [list $beam_x $beam_y $beam_y_corrected $distance $yscale $tilt $twist $tangential_offset $radial_offset $ccomega "" "" "" $psi_x $psi_y $psi_z] [getCell] [list $mosaicity]]
}

body Session::getMTZFilename { } {
    return $mtz_file
}

body Session::setMTZFilename { arg } {
    set mtz_file $arg
}

body Session::getMTZDirectory { } {
    return $mtz_directory
}

body Session::getHKLREFfile { } {
    return $pnt_hklref_file
}

body Session::getHKLREFdirectory { } {
    return $pnt_hklref_dir
}

body Session::resolutionCommandRequired { } {
    return 1
}

body Session::getResolutionCommand { } {
    set l_command "resolution"

    if {$high_resolution_limit != ""} {
	append l_command " $high_resolution_limit"
    } else {
	append l_command " 0.00"
    }

    if {$low_resolution_limit != ""} {
	append l_command " low $low_resolution_limit"
    } else {
    }

    if {$resolution_cutoff != ""} {
	append l_command " cutoff $resolution_cutoff"
    } else {
	append l_command " cutoff 0"
    }

    if {$resolution_exclude_ice == 1} {
	append l_command " EXCLUDE ICE"
    }

    if {[string trim $excl_res_rng] != ""} {
        # parse the input field ranges
        set l_ranges [$::session processExclResRngs $excl_res_rng]
        foreach range $l_ranges {
            set num1 [lindex $range 0]
            set num2 [lindex $range 1]
            #puts "EXCLUDE $num1 to $num2"
            # and add EXCLUDE subkeywords
            # append l_command " EXCLUDE $num1 to $num2"
            append l_command " EXCLUDE $num1 $num2"
        }
    }

    set aniso_vals {}
    foreach axis { a b c } {
	set val [subst "\$aniso_res_${axis}"]
	if { $val != "" } {
	    lappend aniso_vals $val
	}
    }
    if { [llength $aniso_vals] == 3 } {
	set vals [join $aniso_vals { }]
	append l_command " anisotropic $vals"
    }

    #puts $l_command
    return $l_command
}

body Session::getEstimatedResolutionCommand { } {
    set l_command "resolution"
	append l_command " $estimated_high_resolution_limit"

    if {$low_resolution_limit != ""} {
	append l_command " low $low_resolution_limit"
    } else {
    }

    if {$resolution_cutoff != ""} {
	append l_command " cutoff $resolution_cutoff"
    } else {
	append l_command " cutoff 0"
    }

    if {$resolution_exclude_ice == 1} {
	append l_command " EXCLUDE ICE"
    }

    if {[string trim $excl_res_rng] != ""} {
        # parse the input field ranges n-m
        set l_ranges [$::session processExclResRngs $excl_res_rng]
        foreach range $l_ranges {
            set num1 [lindex $range 0]
            set num2 [lindex $range 1]
            #puts "EXCLUDE $num1 to $num2"
            # and add EXCLUDE subkeywords
            # append l_command " EXCLUDE $num1 to $num2"
            append l_command " EXCLUDE $num1  $num2"
        }
    }

    return $l_command
}

body Session::separationCommandRequired { } {
    return 1
}

body Session::getSeparationCommand { } {
    set l_command "separation $spot_separation_x $spot_separation_y"
    if {!$fix_separation} {
	append l_command " update"
    }
    if {$separation_close} {
	append l_command " close"
    } else {
	append l_command " notclose"
    }
    return $l_command
}

body Session::getProfileCommand { } {
    set l_command "profile"
    if {([$::session getParameterValue profile_tolerance_max] != "")} {
	if {([$::session getParameterValue profile_tolerance_min] != "")} {
	    append l_command " tolerance [$::session getParameterValue profile_tolerance_min] [$::session getParameterValue profile_tolerance_max]"
	} else {
	    append l_command " tolerance [$::session getParameterValue profile_tolerance_max]"
	}
    }

    if {[$::session getParameterValue optimise_profile_tolerance]} {
	append l_command " UPDATE"
    } else {
        append l_command " NOUPDATE"
    }

    append l_command " nref [$::session getParameterValue profile_refl_count_av_thresh]"
    append l_command " rmsbg [$::session getParameterValue profile_rmsbg_thresh]"
    if {([$::session getParameterValue profile_overload_cutoff] != "")} {
	append l_command " CUTOFF [$::session getParameterValue profile_overload_cutoff]"
    }

    append l_command " ISDR [$::session getParameterValue threshold_spot_inclusion]"

    if {[$::session getParameterValue profile_optimise_central]} {
	if {[$::session getParameterValue profile_optimise_standard]} {
	    append l_command " OPTIMISE"
	} else {
	    append l_command " NOOPTIMISE"	
	}		
    } else {
	append l_command " NOOPTIMISE ATALL"
    } 

    if {[$::session getParameterValue optimise_box_size]} {
	append l_command " NOFIXBOX"
    } else {
	append l_command " FIXBOX"
    }

    if {[$::session getParameterValue excl_near_ice]} {
	append l_command " ICE [$::session getParameterValue ice_ring_width] PRCUT [$::session getParameterValue prcutval]"
    } else {
	append l_command " NOICE PRCUT [$::session getParameterValue prcutval]"
    }

    return $l_command
}

body Session::getRefinementCommand { a_process } {
    # refinement command
    set l_command "refinement"
    # subkeywords

    if {$size_central_region != ""} {
        append l_command " LIMIT $size_central_region"
    }
    
    if {[$::session getParameterValue "smooth_refined_detector"]} {
        append l_command " SMOOTH"
    } else {
        append l_command " NOSMOOTH"
    }

	
    if {[$::session getParameterValue "use_overloads_in_refining_detector"]} {
	append l_command " INCLUDE OVERLOADS"
	set use_overloads_in_refining_detector_is_set "1"
    } else {
# only send if it has been set but is no longer
	if {[$::session getParameterValue "use_overloads_in_refining_detector_is_set"]} {
	    append l_command " EXCLUDE OVERLOADS"
	    set use_overloads_in_refining_detector_is_set "0"
	}
    }	
    append l_command " RESIDUAL $max_weighted_residual"
    append l_command " MAXREF $max_number_reflections"
    append l_command " NSM1 $nsm1"
    append l_command " NSM2 $nsm2"
    append l_command " GRADIENT [getParameterValue rejection_gradient_integration]"
	
    append l_command " nref $ref_refl_count_thresh"
    # Fixing and freeing of parameter
    set l_fixes " fix"
    set l_frees " free"
    if { !$spiral } {
	set  ${a_process}_fix_radial_offset 1
	set  ${a_process}_fix_tangential_offset 1
    }
    if {[set ${a_process}_fix_beam]} {
	append l_fixes " xcen ycen"
    } else {
	append l_frees " xcen ycen"
    }
    if {[set ${a_process}_fix_distance]} {
	append l_fixes " xtofra"
    } else {
	append l_frees " xtofra"
    }
    if {[set ${a_process}_fix_yscale]} {
	append l_fixes " yscale"
    } else {
	append l_frees " yscale"
    }
    if {[set ${a_process}_fix_tilt]} {
	append l_fixes " tilt"
    } else {
	append l_frees " tilt"
    }
    if {[set ${a_process}_fix_twist]} {
	append l_fixes " twist"
    } else {
	append l_frees " twist"
    }
    if {[set ${a_process}_fix_radial_offset]} {
	append l_fixes " roff"
    } else {
	append l_frees " roff"
    }
    if {[set ${a_process}_fix_tangential_offset]} {
	append l_fixes " toff"
    } else {
	append l_frees " toff"
    }
    if {[set ${a_process}_fix_ccomega]} {
	append l_fixes " CCOMEGA"
    } else {
	append l_frees " CCOMEGA"
    }
    if {$l_fixes != "fix"} {
	append l_command $l_fixes
    }
    if {$l_frees != "free"} {
	append l_command $l_frees
    }
    if {$no_imgs_summed != "0"} {
        append l_command " sumimages $no_imgs_summed"
    }
    return $l_command
}

body Session::getPostrefinementCommand { a_process } {
    # Is postrefinement on or off?
    if {[set ${a_process}_postrefinement_check] == 0} {
	set l_command "postref off"
    } else {
        set smllr_partls_fract [$::session getParameterValue smaller_partials_fraction]
	set l_command "postref multi partition $smllr_partls_fract"
	# subkeywords
	append l_command " MOSADD $mosaic_safety_factor"
	append l_command " MOSSMOOTH $images_mosaic_smooth"
	append l_command " sdfac $postref_refl_intensity_thresh"
	append l_command " nref $postref_refl_count_thresh"
	# Fixing and freeing of parameter
	set l_fixes " fix"
	set l_frees " unfix"
	if {[set ${a_process}_fix_cell_a]} {
	    append l_fixes " a"
	} else {
	    append l_frees " a"
	}
	if {[set ${a_process}_fix_cell_b]} {
	    append l_fixes " b"
	} else {
	    append l_frees " b"
	}
	if {[set ${a_process}_fix_cell_c]} {
	    append l_fixes " c"
	} else {
	    append l_frees " c"
	}
	if {[set ${a_process}_fix_cell_alpha]} {
	    append l_fixes " alpha"
	} else {
	    append l_frees " alpha"
	}
	if {[set ${a_process}_fix_cell_beta]} {
	    append l_fixes " beta"
	} else {
	    append l_frees " beta"
	}
	if {[set ${a_process}_fix_cell_gamma]} {
	    append l_fixes " gamma"
	} else {
	    append l_frees " gamma"
	}
	if {[set ${a_process}_fix_mosaicity]} {
	    append l_fixes " mosaic"
	} else {
	    append l_frees " mosaic"
	}
	if {$l_fixes != " fix"} {
	    append l_command $l_fixes
	}
	if {$l_frees != " unfix"} {
	    append l_command $l_frees
	}
	if {[$::session getParameterValue "smooth_refined_missets"]} {
	    append l_command " smooth"
	} else {
	    append l_command " nosmooth"
	}
    }
    return $l_command
}

body Session::processExclResRngs { string } {
    # Parse the excluded resolution ranges (n-m) and add EXCLUDE subkeywords up to ten

    # shrink all spaces adjacent to hyphens
    regsub -all {\- } $string {%} string
    regsub -all { \-} $string {%} string
    regsub -all {%} $string {-} string

    # replace all double spaces by space
    regsub -all {"  "} $string { } string

    # replace spaces with commas
    regsub -all { ,} $string {,} string
    regsub -all {, } $string {,} string

    # initialize result string
    #set result ""
    set result {}

    # loop through comma-separated string portions up to ten
    set i 0
    foreach i_portion [split $string ","] {
	if {[regexp {^\s*([0-9]+\.?[0-9]*)\s*-\s*([0-9]+\.?[0-9]*)\s*$} $i_portion match num1 num2]} {
	    if { $i < 10 } {
                lappend result [list $num1 $num2]
		#set result "$result EXCLUDE $num1 $num2"
		incr i
	    }
	}
    }
    return $result
}

body Session::getMosaicity { } {
    return $mosaicity
}

body Session::setLatticeResultsObject { stage lattice results } {
    set results_${stage}($lattice) $results
    #puts "Results object [subst \$results_${stage}($lattice)] for $stage of lattice $lattice"
}

body Session::getLatticeResultsObject { stage lattice } {
    set robject ""
    if {[info exists [subst results_${stage}($lattice)]]} {
	#puts "[subst \$results_${stage}($lattice)] $stage of lattice $lattice"
	set robject [subst \$results_${stage}($lattice)]
    }
    return $robject
}

body Session::processRasterAndSeparation { a_dom a_processor } {
    # N.B. No status!
    # Check on status of task
    #     set status_code [$a_dom selectNodes string(//code)]
    #     if {$status_code == "error"} {
    # 	error "[$a_dom selectNodes string(//message)]"
    #     } else { }

    # Determine update reason
    if {$a_processor == [.c component cell_refinement]} {
	set l_reason "Cell_refinement"
    } else {
	set l_reason "Integration"
    }

    # Separation
    foreach { l_sep_x l_sep_y } [$a_dom selectNodes normalize-space(//separation)] break
    if {$l_sep_x != $spot_separation_x} {
	updateSetting "spot_separation_x" $l_sep_x 1 1 $l_reason 1
    }
    if {$l_sep_y != $spot_separation_y} {
	updateSetting "spot_separation_y" $l_sep_y 1 1 $l_reason 1
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
    }

    # Profile tolerances
    foreach { l_min l_max } [$a_dom selectNodes normalize-space(//profile_tolerances)] break
    if {$l_min != $profile_tolerance_min} {
	updateSetting "profile_tolerance_min" $l_min 1 1 $l_reason
    }
    if {$l_max != $profile_tolerance_max} {
	updateSetting "profile_tolerance_max" $l_max 1 1 $l_reason
    }

}

body Session::parseErrors { a_dom } {
    set l_command [$a_dom selectNodes normalize-space(//command)]
    set l_keyword [$a_dom selectNodes normalize-space(//keyword)]

    .c errorMessage "Mosflm keyword error"

    .m configure \
	-title "Error" \
	-type "1button" \
	-button1of1 "Dismiss" \
	-text "Mosflm has been passed a command \'$l_command\'.\n$l_keyword is unknown to Mosflm and has been ignored.\nSorry."

    if {[.m confirm]} {
	.c showStage hull
	[.c component cell_refinement] resetControls
	[.c component integration] resetControls
	# following was just .c idle - Session menu button remained greyed-out & inactive
	.c idle
	# so re-enable interface
	.c enable
    }
}

body Session::processInterfaceInputResponse { a_dom processor } {
    # Check on status of task
    set l_message [$a_dom selectNodes normalize-space(//message)]

    set status_code [$a_dom selectNodes string(//status/code)]
    if {$status_code == "error"} {

	#puts $l_message

	.c errorMessage "Mosflm cell and spacegroup validation error"
    
	.m configure \
	    -type "1button" \
	    -button1of1 "Dismiss" \
	    -title "Cell/Spacegroup validation error" \
	    -text "$l_message\n\nPlease fix this before proceeding."
    
	if {[.m confirm]} {
	    # .c showStage hull - but we may have changed spacegroup in Indexing or Strategy panes
	    # following was just .c idle - Session menu button remained greyed-out & inactive
	    .c idle
	    # so re-enable interface
	    .c enable
	}
    } elseif {$status_code == "ok"} {
	# status code was ok
	set l_symmetry [$a_dom selectNodes normalize-space(//symmetry)]
	set l_a [$a_dom selectNodes normalize-space(//cell/a)]
	set l_b [$a_dom selectNodes normalize-space(//cell/b)]
	set l_c [$a_dom selectNodes normalize-space(//cell/c)]
	set l_alpha [$a_dom selectNodes normalize-space(//cell/alpha)]
	set l_beta  [$a_dom selectNodes normalize-space(//cell/beta)]
	set l_gamma [$a_dom selectNodes normalize-space(//cell/gamma)]

	#puts "processIIR: $processor $l_symmetry $l_a $l_b $l_c $l_alpha $l_beta $l_gamma"

	# update cell - but it is only the regularized cell from indexwizard as toggling space group is done before refinement
	set t_cell [namespace current]::[Cell \#auto "initialize" "temp" $l_a $l_b $l_c $l_alpha $l_beta $l_gamma]
	# Should interface input response really update iMosflm's cell here?
	$::session updateCell "User" $t_cell
	# This can leave the Session's cell set to some intermediate cell during multilattice indexing
	delete object $t_cell

	# update spacegroup, lowercase leading H if hexagonal
	if { [string index $l_symmetry 0] == "H" } {
	    set l_symmetry [string tolower $l_symmetry]
	} else {
	    set l_symmetry [string toupper $l_symmetry]
	}
	set t_spacegroup [namespace current]::[Spacegroup \#auto "initialize" "temp" $l_symmetry]
	$::session updateSpacegroup "User" $t_spacegroup
	delete object $t_spacegroup

	set l_curr_lattice [$::session getLattice]
	set l_current_lattice [$::session getCurrentLattice]
	if { $l_curr_lattice != "" } {
	    #puts "$l_symmetry set and lattice is $l_curr_lattice current lattice $l_current_lattice"
	    [.c component strategy] updateSpacegroupCombo $l_curr_lattice $l_symmetry
	    # if mosflm is not busy,calculate completeness for existing data
	    if {![$::mosflm busy]} {
		# Attempt re-calculation in Strategy widget
		if { $processor == "strategy" } {
		    [.c component strategy] calculate
		}
	    }
	}

    } else {
	# is there any other status code
    }
}

body Session::processFatalError { a_dom } {
    set l_subroutine [$a_dom selectNodes normalize-space(//subroutine)]
    set l_message [$a_dom selectNodes normalize-space(//message)]
    set l_message [regsub -all {\_\_nl\_\_} $l_message "\n"]
    set l_errlevel [$a_dom selectNodes normalize-space(//level)]
    .c errorMessage "Fatal mosflm error"
    set l_filename [$::mosflm fileErrorLog "fatal"]
    catch { Mosflm::closeMosflm }

    # Set the session flag
    set crashed 1
    if { $l_errlevel < 10 } {
        .m configure \
	-title "Error" \
	-type "1button" \
	-button1of1 "Dismiss" \
	-text "Mosflm has encountered a fatal error in subroutine \"$l_subroutine\". \n$l_message \nAn error log has been compiled in file:\n\n\t$l_filename\n\nYou should find clues regarding the cause of the problem if you read \nthe end of the log file (say, the last hundred lines or so). You may \nbe able to work out what went wrong, and you may be able to alter your \nprocessing to avoid the problem.\n\nIf, after examining the log file, you need any more help, please try \nto re-run the job in exactly the same way as before, but check the \n\"Debug output\" box in the \"Environment variables\" window (found \nunder \"Processing options\"), and send the report and the full \ndatestamped logfile produced (in the current working directory, \n\$MOSDIR), along with the associated mosflm.lp file to:\n\n\t$::env(MAINTAINER)\n\nand we will be happy to help.\n\nThank you."
    } else {
        .m configure \
	-title "Error" \
	-type "1button" \
	-button1of1 "Dismiss" \
	-text "Mosflm has encountered a fatal error in subroutine \"$l_subroutine\". \n$l_message \n"
    }
    if {[.m confirm]} {
	.c showStage hull
	[.c component cell_refinement] resetControls
	[.c component integration] resetControls
	Mosflm::startMosflm
	# following was just .c idle - Session menu button remained greyed-out & inactive
	.c idle
	# so re-enable interface
	.c enable
    }
}

body Session::processTrappedError { a_dom } {
    set l_message [$a_dom selectNodes normalize-space(//message)]
    set l_message [regsub -all {\_\_nl\_\_} $l_message "\n"]
    # .c errorMessage "Trapped mosflm error"
    set l_filename [$::mosflm fileErrorLog "trapped"]
    #catch { Mosflm::closeMosflm }

    # Set the session flag ..Comment this out AGWL 15/6/18
    #set crashed 1

    .m configure \
	-title "Trapped error" \
	-type "1button" \
	-button1of1 "Dismiss" \
	-text "Mosflm has trapped an error\n$l_message."

    if {[.m confirm]} {
	#.c showStage hull
	#[.c component cell_refinement] resetControls
	#[.c component integration] resetControls
        # Try commenting out the restart of mosflm 15/6/18
	#Mosflm::restartMosflm
	# following was just .c idle - Session menu button remained greyed-out & inactive
	#.c idle
	# so re-enable interface
	#.c enable
    }
}

body Session::setMosaicityRelayBool { a_value } {
	set mosaicity_relay_bool $a_value
}

body Session::setIndexingRelayBool { a_value } {
	set indexing_relay_bool $a_value
}

body Session::getMosaicityRelayBool {  } {
	return $mosaicity_relay_bool 
}

body Session::getIndexingRelayBool {  } {
	return $indexing_relay_bool 
}

body Session::getTilt {} {
	return $tilt
}

body Session::getTwist {} {
	return $twist
}

body Session::getTangentialOffset {} {
	return $tangential_offset
}

body Session::getRadialOffset {} {
	return $radial_offset
}

body Session::setIntegrationRun {a_int} {
	#puts "Setting integration_run to \#\# $a_int \#\#"
	set integration_run $a_int
}

body Session::getIntegrationRun { } {
	#puts "Getting integration_run as \@\@ $integration_run \@\@"
	return $integration_run
}

body Session::setRunningProcessing {a_int} {
	#puts "Setting running_integration to \#\# $a_int \#\#"
	set running_integration $a_int
}

body Session::getRunningProcessing { } {
	#puts "Getting running_integration as \@\@ $running_integration \@\@"
	return $running_integration
}

body Session::callPointlessProcess { } {
	incr integration_run
	$pmon setupPointless
}

body Session::initialisePMon {} {
	$pmon initialise
}

body Session::resetDetector {} {

    #puts "Images: [getImages]"
    foreach image [getImages] {
        # Unset the detector parameter values stored in each image
        foreach param { beam_x beam_y beam_y_corrected distance yscale tilt twist tangential_offset radial_offset } {
            if { [$image getNumber] < 2 } {
                #puts "$param for image [$image getNumber] stored as [$image getValue $param] resetting to null"
            }
            $image setValue $param ""
        }
    }

    #puts "Initial detector params: [array names initial_detect_param]"
    foreach param { beam_x beam_y beam_y_corrected distance yscale tilt twist tangential_offset radial_offset } {
        if { [info exists initial_detect_param($param)] } {
            # Update session setting from initial detector parameters
            updateSetting $param $initial_detect_param($param) 1 1 "User"
            #puts "Updated $param to $initial_detect_param($param)"
        } else {
            updateSetting $param 0.00 1 1 "User"
            #puts "Updated $param to 0.00"
        }
    }
    updateSetting tangential_offset "0.00" 1 1 "User"
    updateSetting radial_offset "0.00" 1 1 "User"
    updateSetting ccomega "0.00" 1 1 "User"
    querySiteSetting tilt "0.00" 1 1 "User" ; # check site file
    querySiteSetting twist "0.00" 1 1 "User" ; # check site file
    # Finally, some Mosflm keywords reset behind the scenes
    $::mosflm sendCommand "DISTORTION XTOFRA 1.0"
    $::mosflm sendCommand "CAMCON CCX 0.0 CCY 0.0 CCOM 0.0"
}

###############################################################################
# ########################################################################### #
# # CLASS: Visual Sector                                                    # #
# ########################################################################### #
###############################################################################

class Sector {
    inherit Tree

    public variable template ""
    private variable matrix ""

    public method addImage
    public method sortImages
    public method deleteImage
    public method getImages

    public method setTemplate
    public method getTemplate
    public method getTemplateForInterface
    public method getTemplateForMosflm

    public method getMatrix
    public method listMatrix
    public method reportMatrix
    public method updateMatrix
    public method propagatePhi

    public method getPhi

    public method serialize

    constructor { a_method args } {
	if {$a_method == "build"} {
	    set template [lindex $args 0]
	    set matrix [namespace current]::[Matrix \#auto "blank" "Unknown"]
	} elseif {$a_method == "xml"} {
	    set template [$args getAttribute template]
            if {$::debugging} {
               puts "flow: constructor in Class Sector, method xml, args is $args, template is $template"
            }             
	    set l_matrix_node [$args selectNodes matrix]
	    set matrix [namespace current]::[Matrix \#auto "xml" $l_matrix_node]
	    $::session addSector $this
	    foreach i_image_node [$args selectNodes image] {
		set new_image [namespace current]::[Image \#auto "xml" $i_image_node]
		addImage $new_image -record 0
	    }
	}
    }
    
    destructor {
	# NB images are children, and so taken care of by Tree's destructor
    }

}

body Sector::addImage { an_image args } {
    options {-record 1 -update_interface 1 -sort 1 -update_imagecombo 1} $args
    if {$::debugging} {
        puts "flow: Sector::addImage an_image is $an_image args $args"
    }
    #puts $an_image
    add $an_image
    if {$options(-sort)} {
	sortImages
    }

    # Record the event in the history if required
    if {$options(-record)} {
 	# record the event
 	$::session addHistoryEvent "ImageAddEvent" "User action" $an_image
    }

    if {$options(-update_interface)} {
	# update the session tree
        if {$::debugging} {
            puts "flow: in Sector::addImage update the session tree this is $this an_image is $an_image"
            puts "flow: children is $children "
        }
	.c addImage $this $an_image -sort $options(-sort)
    }
    
    if {$options(-update_imagecombo)} {
	# update the image display's image list (combo)
	#.image updateImageList - this actually rebuilds the combo list afresh for each new image added
        if {$::debugging} {
            puts "flow: in Sector::addImage update image display's image list (combo)"
        }
	.image appendToImageCombo $an_image
    }
    if {$::debugging} {
        puts "flow: end of Sector::addImage children is $children"
    }

}

body Sector::deleteImage { an_image args } {
    options {-record 1 -update_imagecombo 1} $args

    set result "0"
    #puts luke
    set i_index 0
    foreach i_image $children {
	#puts $i_image
	if {$i_image == $an_image} {
	    set children [lreplace $children $i_index $i_index]
	    # Record the event in the history if required
	    if {$options(-record)} {
		# record the event
		$::session addHistoryEvent "ImageDeleteEvent" "User action" $an_image
	    }
	    delete object $i_image
	    #puts "deleted image object $i_image"
	    set result "1"
	    break
	}
	incr i_index
    }
    #puts "No. children: [llength $children]"
    if {[llength $children] == 0} {
	# return a flag to say this sector should be deleted
	set result "-1"
    }

    if {$options(-update_imagecombo)} {
	# update the image display's image list (combo)
	.image updateImageList
    }
    return $result
}

body Sector::sortImages { } {
    if {$::debugging} {
       puts "flow: in Sector::sortImages, children is $children"
    }
    set l_image_paths {}
    foreach i_image $children {
        if {$::debugging} {
            puts "flow: for i_image: $i_image, getfullpathname is [$i_image getFullPathName]"
        }
	lappend l_image_paths [$i_image getFullPathName]
    }
    if {$::debugging} {
        puts "flow: Unsorted l_image_paths $l_image_paths"
    }
    set l_sorted_image_paths [lsort $l_image_paths]
    set l_sorted_images {}
    foreach i_path $l_sorted_image_paths {
        if {$::debugging} {
            puts "flow: Image::getImageByPath for ipath $i_path is [Image::getImageByPath $i_path]"
        }
	lappend l_sorted_images [Image::getImageByPath $i_path]
    }
    #puts "Sorted [llength $l_sorted_images] image file full paths"
    set children $l_sorted_images
    set i_level 0
    while {$i_level <= [info level]} {
	incr i_level
    }
    if {$::debugging} {
       puts "flow: exiting Sector::sortImages, children is $children"
    }
}

body Sector::getImages { } {
#    puts "crucial: from Sector::getImages, returning children: $children"
    return $children
}


body Sector::setTemplate { a_template } {
    set template $a_template
}

body Sector::getTemplate { } {
    return $template
}

body Sector::getTemplateForInterface { } {
	if { $::env(HDF5file) == 1 } {
	# only for HDF5 files or perhaps others which are containers, so do not have
	# an image number in the image name.
	return "image.\#\#\#\#\#\#\#"
    } {
	return $template
    }
}

body Sector::getTemplateForMosflm { } {

    if {$::debugging} {
        puts "flow: in getTemplateForMosflm, template is $template"
        puts "flow: image_template is [$::session getImageTemplate]"
#        set template image.\#\#\#\#\#\#\#
#	return $template
    }


    if { $template == "image.\#\#\#\#\#\#\#" } {
# only for HDF5 files or perhaps others which are containers, so do not have
# an image number in the image name.
        if {$::debugging} {
            puts "flow: template is HDF5 style, get image_template"
        }
	if { [$::session getImageTemplate] == "" } {
            if {$::debugging} {
                puts "flow: image_template not set yet"
            }
	    # image_template not set yet, but if we are here we must 
	    # have the filename
            return $template
#	    return [file tail $full_path]
	} {
            if {$::debugging} {
                puts "flow: return with [$::session getImageTemplate]"
            }
	    return [$::session getImageTemplate]
	}
    } {
	return $template
    }
}

body Sector::getMatrix { } {
    return $matrix
}

body Sector::listMatrix { } {
    return [$matrix listMatrix]
}

body Sector::reportMatrix { } {
    return [$matrix reportMatrix]
}

body Sector::updateMatrix { a_reason a_matrix { a_record 1 } { a_update_interface 1 } { a_predict 1 } } {
    #puts "Sector::updateMatrix $this"
    #puts "Sector: $this [$this getTemplate] Matrix: $a_matrix [$a_matrix getName]"
    if {$a_record} {
	$::session addHistoryEvent "MatrixUpdateEvent" $a_reason $template $matrix $a_matrix
    }
    if { [$matrix getName] != [$a_matrix getName] } {
        #puts "Sector MatrixUpdateEvent $a_reason $template matrix:[$matrix getName] a_matrix:[$a_matrix getName]"
    }
    $matrix Matrix::copyFrom $a_matrix
    
    if {$a_update_interface} {
	.c updateMatrix $this $matrix
	.c enableProcessing
    }
    
    if {$a_predict} {
	#puts "updateMatrix calls updatePredictions $a_predict"	
        # puts "debug: update predictions from Session::updateMatrix"
	$::session updatePredictions
    }
}

body Sector::propagatePhi { a_image a_phi_start a_phi_end } {
    # Calculate phi range per image
    set l_phi_range [expr $a_phi_end - $a_phi_start]
    set phi_for_first_image $a_phi_start
    # Set flag to indicate when the image to be begin updates at is reached 
    set l_below_image 0
    # hrp 02.07.2009 if we're doing this, we don't believe the phi values 
    # in the header
    $::session setPhiIncorrectInHeader
    set offset_from_first_image 0
    set firstImage [$a_image getNumber]
    foreach i_image [getImages] {
	set imageSerial [expr [$i_image getNumber] - $firstImage]
	# See if image to begin updates has been reached
	if {$i_image == $a_image} {
	    set l_below_image 1
	    if  {$i_image != [lindex $i_image 0]} {
		set offset_from_first_image [expr -[$i_image getNumber]]
	    }
	}
	# If image to begin updates at has been reached...
	if {$l_below_image} {
	    # hrp 02.07.2009 change so it works right when images are not contiguous
	    set a_phi_start [expr double ($phi_for_first_image + $offset_from_first_image + ($imageSerial * $l_phi_range))]
	    set a_phi_end [expr double ($phi_for_first_image + $offset_from_first_image + (($imageSerial + 1) * $l_phi_range))]
          # Increment phi start and end for next image
#           set a_phi_start $a_phi_end
#           set a_phi_end [expr $a_phi_end + $l_phi_range]

	    # Make updates to phi
	    $i_image setPhi $a_phi_start $a_phi_end 1 1 "User"
	}
    }    
}

body Sector::getPhi { } {
#    puts "crucial: in Sector::getPhi"
#    puts "crucial: llength getimages is [llength [getImages]]"
    if {$::debugging} {
        #puts "flow: in getPhi, no of images is [llength [getImages]]"
#        puts "flow: make it crash $crash"
        #puts "children is $children"
    }
    if {[llength [getImages]] != 0} {
#        puts "crucial: In Sector::getPhi lindex children 0 is [lindex $children 0]"
	set l_image_number ""
	foreach { l_phi_start l_junk l_image_number } [[lindex $children 0] getPhi] break
	foreach { l_junk l_phi_end l_image_number } [[lindex $children end] getPhi] break
#        puts "crucial: exiting1 result is: [list $l_phi_start $l_phi_end  $l_image_number ] "
	set result [list $l_phi_start $l_phi_end  $l_image_number ]
    } else {
#        puts "crucial: exiting2 result is [list "" ""]"
	set result [list "" ""]
    }
}

body Sector::serialize { } {
    set xml "<sector template=\"$template\">"
    append xml [$matrix serialize]
    foreach im [getImages] {
	append xml [$im serialize]
    }
    append xml "</sector>"
    return $xml
}

# Class Image ##########################################

class Image {
    inherit Tree

    private common images_by_path ; # array
    public proc getImageByPath

#    private variable saved_file_read "0"
    private variable full_path ""
    private variable number ""
    private variable image_template ""
    private variable template ""
    private variable internal_image_name ""
    private variable phi_start ""
    private variable phi_end ""
    private variable phi_x ""
    private variable phi_y ""
    private variable phi_z ""
    private variable spotlist ""
    private variable badspotlist ""
    private variable badspotlist_by_lattice ; # array

    private variable missets_by_lattice ; # array of misset triplets

    private variable beam_x ""
    private variable beam_y ""
    private variable distance ""
    private variable yscale ""
    private variable tilt ""
    private variable twist ""
    private variable tangential_offset ""
    private variable radial_offset ""
    private variable global_absolute_rms_residual ""
    private variable central_absolute_rms_residual ""
    private variable global_weighted_rms_residual ""
    private variable beam_y_corrected ""

    public proc parseFilename
    private method extractDescriptors

    public method getFullPathName
    public method getShortName
    public method getRootName
# HARRY 06022018
    public method setNumber
    public method getNumber
    public method getTemplate
    public method getTemplateForMosflm
    public method setInternalImageName
    public method getInternalImageName
    public method getDirectory
#    public method setSessionFileRead
#    public method getSessionFileRead

    public method getSector

    public method setPhi
    public method getPhi
    public method setValue
    public method getValue
    public method updateMissets
    public method updateMissetsFromPatternMatching
    public method hasMissets
    public method getMissets
    public method copyMissets
    public method reportPhis

    public method getBadSpotlist
    public method setBadSpotlist
    public method unsetBadSpotlist

    public method setSpotlist
    public method getSpotlist
    public method makeAuxiliaryFileName

    public method getImageHeight

    public method serialize
    
    constructor { a_method args } {
	if {$a_method == "build"} {
	    set full_path [file normalize [lindex $args 0]]
	} elseif {$a_method == "xml"} {
            if {$::debugging} {
               puts "flow: constructor in Class Image, method xml, args is $args"
            }             
	    set full_path [$args getAttribute "full_path"]
# Next line needed for reading hdf5 natively, but without the default to zero 
# a saved session could not be read, add the default "0" 05/6/18
	    set number [$args getAttribute "image_number" "0"]
            if {$::debugging} {
               puts "flow: Class Image constructor, number is $number"
            }             
	    set phi_start [$args getAttribute "phi_start"]
	    set phi_end [$args getAttribute "phi_end"]
            if {$::debugging} {
               puts "flow: Class Image constructor, phi_start is $phi_start phi_end is $phi_end"
            }             
	    set phi_x [$args getAttribute "phi_x"]
	    set phi_y [$args getAttribute "phi_y"]
	    set phi_z [$args getAttribute "phi_z"]
	    set spotlist_node [$args selectNodes spotlist]
	    if {$spotlist_node != ""} {
		set spotlist [namespace current]::[Spotlist \#auto "xml" $spotlist_node]
	    }
	    set badspotlist_node [$args selectNodes badspotlist]
	    if {$badspotlist_node != ""} {
		set badspotlist [namespace current]::[BadSpotlist \#auto "xml" $badspotlist_node]
	    }
	} elseif { $a_method == "copy" } {
	    set full_path [$args getFullPathName]
	    foreach { phi_start phi_end } [$args getPhi] break
	    foreach { phi_x phi_y phi_z } [$args copyMissets] break
	    set spotlist [$args getSpotlist]
	    if {$spotlist != ""} {
		set spotlist [namespace current]::[Spotlist \#auto "copy" $spotlist]
	    }
	    set badspotlist [$args getBadSpotlist]
	    if {$badspotlist != ""} {
		set badspotlist [namespace current]::[BadSpotlist \#auto "copy" $badspotlist]
	    }
	}

	set name [file tail $full_path]
        if {$::debugging} {
           puts "flow: name is $name"
        }             
	if { [regexp -- {^(.*?)(_master.h5)$} $full_path match] ||[regexp -- {^(.*?)(.nxs)$} $full_path match] } {
	    # can we use this test here? NO!, 20032018
	# if { $::env(HDF5file) == 1 } {}
	    # do this for first image only
	    set i_file "[file dirname $full_path]/image.0000001"
	    set images_by_path($i_file) $this
            if {$::debugging} {
               puts "flow: i_file is $i_file, this is $this"
            }             
	} {
	    set images_by_path($full_path) $this
            if {$::debugging} {
               puts "flow: setting images_by_path, full_path is $full_path, this is $this"
            }             
	}
	extractDescriptors $full_path
	
    }

    destructor {
	if { [regexp -- {^(.*?)(_master.h5)$} $full_path match] ||[regexp -- {^(.*?)(.nxs)$} $full_path match] } {
	    # can we use this test here? NO!, 20032018	if { $::env(HDF5file) == 1 } {}
	    # do this for first image only
	    set i_file "[file dirname $full_path]/image.0000001"
	} {
	    set i_file $full_path
	}
	array unset images_by_path $i_file
	array unset badspotlist_by_lattice
	array unset missets_by_lattice
    }
}

body Image::getImageByPath { a_path } {
    if {[info exists images_by_path($a_path)]} {
	return $images_by_path($a_path)
    } else {
	return ""
    }
}

body Image::extractDescriptors { a_filename } {
    foreach { template number } [parseFilename $a_filename] break
}

body Image::parseFilename { image_fullpath } {

    # If there is embedded white space in image_fullpath, chop it into bits and hope
    # file tail on the last bit returns the image file name in $filetail
    if { [regexp " " $image_fullpath] } {
        set bits [split $image_fullpath]
        set tail [lindex $bits [ expr { [llength $bits] -1 } ]]
        set filetail [file tail $tail]
    } else {
        set filetail [file tail $image_fullpath]
    }
    if {$::debugging} {
        puts "Image:parseFilename $filetail"
    }             


# harry tries to break things 25.08.2006 this one must go first!
# 
# allow for 1 - 7 digits in filename
# first check for HDF5 master files, then for files which 
# have digits following the period.
#
    if {[regexp -- {^(.*?)(_master.h5)$} $filetail match]} {
	# can we use this test here? NO, 20032018
	# if { $::env(HDF5file) == 1 } {}
	set l_hdf5file $filetail
	set local_file $filetail
	set suffix ""
	set l_number "1"
	set number "1"
	set prefix ""
	set length_prefix 0
	set length_stem 0
	set l_template "image.\#\#\#\#\#\#\#"
        if {$::debugging} {
            #puts "Image:parseFilename master.h5, l_template $l_template"
        }             
	
    } elseif {[regexp -- {^(.*?)(.nxs)$} $filetail match]} {
	# can we use this test here? NO, 20032018
	# if { $::env(HDF5file) == 1 } {}
	set l_hdf5file $filetail
	set local_file $filetail
	set suffix ""
	set l_number "1"
	set number "1"
	set prefix ""
	set length_prefix 0
	set length_stem 0
	set l_template "image.\#\#\#\#\#\#\#"
        if {$::debugging} {
            #puts "Image:parseFilename .nxs, l_template $l_template"
        }             
    
    } elseif {[regexp -- {^(.*?)(\.\d{1,7})$} $filetail match prefix number]} {
        set local_file $filetail
        set l_template "$prefix.[string repeat "\#" [expr [string length $number] -1 ]]"
        # must trim period first, or can we robustly do this in one line?
	set number [string trimleft $number .]
        set l_number [string trimleft $number 0]
        set suffix ""
        if {$::debugging} {
            #puts "Image:parseFilename l_number $l_number"
        }             

    } elseif {[regexp -- {^(.*?)(\d{1,7})(|\..+)$} $filetail match prefix number suffix]} {
        # harry 30.07.2007 tries to break things again for unusual filenames 
        # with numbers and periods all over the place. We need to re-assign 
        # TclTk'sprefix, number and suffix since these appear to be defined 
        # in an inflexible way - or is it the test above here that does that?
        set local_file $filetail
        set suffix [file extension $local_file]
        set stem [regsub $suffix $local_file ""]
        set prefix [string trimright $stem 0123456789]

        set length_prefix [string length $prefix]
        set length_stem [string length $stem]
        set number [string range $local_file [expr $length_prefix] [expr $length_stem - 1] ]
        set length_number [string length $number]
        #
        # if length_number > 7, we need to re-define prefix & number 
        # again because Mosflm only allows 7 digits 
        if { $length_number > 7 } {
            set prefix [string range $local_file 0 [expr $length_stem - 8]]
            set number [string range $local_file [expr $length_stem - 7] [expr $length_stem - 1]]
            set length_number 7
        }

        set l_number [string trimleft $number 0]
        set l_template "$prefix[string repeat "\#" $length_number]$suffix"
        if {$::debugging} {
            #puts "Image:parseFilename unusual filename l_number $l_number"
        }             

    } else {
	error "Could not determine template from filename: $filetail - invalid filename format."
    }
##############################################################################
#added by luke on 09 Oct 2007
#inserted the if statement to check whether the parsed number has resulted in a blank string. This occurs when the image file has a file index of zero. Usually image files start at file 1 and move up. We need to catch the cases where they start at zero.
    if {[string trimleft $number 0] == ""} {
        set number "0"
        set l_number "0"	
    }
##############################################################################
    #puts "parseFilename: $l_template"
    #puts "parseFilename: $l_number"
    if {$::debugging} {
        #puts "Return from Image:parseFilename l_template $l_template , l_number $l_number"
    }             

    return [list $l_template $l_number]
}

body Image::getFullPathName { } {
    if {$::debugging} {
       #puts "flow: this is $this, this getTemplate is [$this getTemplate]"
       #puts "flow: this getTemplateForMosflm is [$this getTemplateForMosflm]"
       #puts "flow: full_path is $full_path"
       #puts "flow: internal_image_name is $internal_image_name"
    }
    if { [$this getTemplate] == [$this getTemplateForMosflm] } {
#        puts "crucial2: getFullPathName returning $full_path"
	return $full_path
    } {
# Returned name depends on whether a saved session file has been read
# as in this case internal_image_name is not set up
        if {[ $::session getSessionFileRead ]  } {
#           puts "crucial2: getFullPathName returning $full_path"
 	   return $full_path
        } {
#           puts "crucial2: getFullPathName returning $internal_image_name"
	   return $internal_image_name
        }
    }
}

body Image::getShortName { } {
    return [file tail $full_path]
}

body Image::getRootName { } {
    return [file rootname [file tail $full_path]]
}


#HARRY: 06022018
body Image::setNumber { a_number } {
    set number $a_number
}

body Image::getNumber { } {
    return $number
}

body Image::getTemplate { } {
    return $template
}

body Image::getTemplateForMosflm { } {
    if {$::debugging} {
    }
    if { $template == "image.\#\#\#\#\#\#\#" } {
# only for HDF5 files or perhaps others which are containers, so do not have
# an image number in the image name.
	if { [$::session getImageTemplate] == "" } {
	    # image_template not set yet, but if we are here we must 
	    # have the filename
            if { [$::session isHdf5] == "" } {
# needed for reading savefile 
               return $template
	    } {
# needed for a processing job
		if {[ $::session getSessionFileRead ]  } {
                   return [$::session isHdf5]
                } {
	           return [file tail $full_path]
                }
	    }
	} {
	    return [$::session getImageTemplate]
	}
    } {
	return $template
    }
}

body Image::setInternalImageName { a_name } {
    set internal_image_name $a_name
}

body Image::getInternalImageName { } {
    return $internal_image_name
}


body Image::getDirectory { } {
    set temp [file dirname $full_path]
    return "$temp"
}



body Image::getSector { } {
    return $parent
}

body Image::setPhi { a_start a_end { a_record 0 } { a_update_interface 0} { a_reason "User" } } {
    # Record event in history if necessary
    if { $a_record } {
	# Add history event
	$::session addHistoryEvent "PhiUpdateEvent" $a_reason $this $a_start $a_end $phi_start $phi_end
    }

    # Make update to image#s phi values
    set phi_start $a_start
    set phi_end $a_end

    # Update controller's session tree if necessary
    if {$a_update_interface} {
	.c updateImage $this
	if {[.image getImage] == $this} {
#		puts "IN SETPHI"
            # puts "debug: update predictions from Image::setPhi"
	    $::session updatePredictions
	}
    }
}

body Image::getPhi { } {
#    puts "crucial: in Image::getPhi"
#    puts "crucial: return is: [list $phi_start $phi_end]"
#    return [list $phi_start $phi_end $number]
    return [list $phi_start $phi_end]
}

body Image::setValue { param value } {
    # puts "debug: $this setValue $param $value"
    set [subst $param] $value
}

body Image::getValue { param } {
    #puts "$this getValue for $param is [set $param]"
    return [set $param]
}

body Image::updateMissets { a_x a_y a_z { a_record "1" } { a_update_interface "1" } { a_reason "Processing" } { lattice 1 } } {

    if { $a_record } {
	# record history event
	$::session addHistoryEvent "MissetUpdateEvent" "$a_reason" $this $a_x $a_y $a_z $phi_x $phi_y $phi_z
    }
    set phi_x $a_x
    set phi_y $a_y
    set phi_z $a_z

    # Update for this lattice
    set missets_by_lattice($lattice) [list $phi_x $phi_y $phi_z]
    if {$a_update_interface} {
	.c updateImage $this
	if {[.image getImage] == $this} {
#		puts "IN UPDATEMISSETS"
            if {$::debugging} {
                puts "flow: about to call session::updatePredictions from Session::updateMissets"
            }
	    $::session updatePredictions
	}
    }
}

body Image::updateMissetsFromPatternMatching { a_x a_y a_z { a_record "1" } { a_update_interface "1" } { a_reason "Processing" } { lattice 1 } } {
# HRP 05.06.2015
# do not actually update predictions because this is often called in the middle of a
# process run (either refine or integrate) which has not finished - so some things
# get messed up because the process tidying has not been performed

    if { $a_record } {
	# record history event
	$::session addHistoryEvent "MissetUpdateEvent" "$a_reason" $this $a_x $a_y $a_z $phi_x $phi_y $phi_z
    }
    set phi_x $a_x
    set phi_y $a_y
    set phi_z $a_z

    # Update for this lattice
    set missets_by_lattice($lattice) [list $phi_x $phi_y $phi_z]
    if {$a_update_interface} {
	.c updateImage $this
    }
}

body Image::hasMissets { } {

    set lattice [$::session getCurrentLattice]
    if {[info exists missets_by_lattice($lattice)]} {
        # missets stored for lattice
        foreach phi $missets_by_lattice($lattice) {
            if { $phi == "" } {
                return 0
            }
        }
        return 1
    } else {
        if { ($phi_x != "") && ($phi_y != "") && ($phi_z != "")} {
            # missets not stored for lattice but image has missets
            return 1
        }
        return 0
    }
}

body Image::getMissets { } {
    set lattice [$::session getCurrentLattice]
    if {[hasMissets]} {
	if {[info exists missets_by_lattice($lattice)]} {
	    #puts "Image [$this getNumber] has missets of $missets_by_lattice($lattice) for lattice $lattice"
	    return $missets_by_lattice($lattice)
	} else {
	    #puts "Image [$this getNumber] has no missets in \$missets_by_lattice($lattice) for lattice $lattice but has $phi_x $phi_y $phi_z"
	    return [list $phi_x $phi_y $phi_z]
	}
    } else {
	return [list 0 0 0]
    }
}

body Image::copyMissets { } {
    return [list $phi_x $phi_y $phi_z]
}

body Image::reportPhis { args } {
    options {-mode "auto"} $args
    if {$options(-mode) == "auto"} {
        set lattice [$::session getCurrentLattice]
	if {[hasMissets]} {
            if {[info exists missets_by_lattice($lattice)]} {
                foreach { phi_x phi_y phi_z } [getMissets] {
                    set l_report "\u03c6(r):$phi_start - $phi_end, \u03c6(x):$phi_x, \u03c6(y):$phi_y, \u03c6(z):$phi_z"
                }
            } else {
                set l_report "\u03c6(r):$phi_start - $phi_end, \u03c6(x):$phi_x, \u03c6(y):$phi_y, \u03c6(z):$phi_z"
            }
	} else {
            set l_report "\u03c6(r):$phi_start - $phi_end"
	}
    } elseif {$options(-mode) == "range"} {
	set l_report "$phi_start - $phi_end"
    } else {
	set l_report ""
    }
    return $l_report
}

body Image::setSpotlist { a_spotlist } {
    # Delete any existing spotlist
    if {$spotlist != ""} {
	delete object $spotlist
    }
    # Set the spotlist to be the new spotlist
    set spotlist $a_spotlist
}

body Image::getSpotlist { } {
    return $spotlist
}

body Image::serialize { } {
    set xml "<image full_path=\"$full_path\" phi_start=\"$phi_start\" phi_end=\"$phi_end\" phi_x=\"$phi_x\" phi_y=\"$phi_y\" phi_z=\"$phi_z\">"
    if {$spotlist != ""} {
	append xml [$spotlist serialize]
    }
    if {$badspotlist != ""} {
	append xml [$badspotlist serialize]
    }
    append xml "</image>"
    return $xml
}

body Image::getBadSpotlist { lattice } {
    #puts "Looking for bad spot list for image [$this getNumber]"
    if { [info exists badspotlist_by_lattice($lattice)] && ($badspotlist_by_lattice($lattice) != "") } {
	if { [catch { set list [$badspotlist_by_lattice($lattice) getBadSpots] } msg ] } {
	    #puts "Error getting bad spots - $msg"
	    return ""
	} else {
	    #puts "Found $badspotlist_by_lattice($lattice) for $this"
	    #puts $list
	    return $badspotlist_by_lattice($lattice)
	}
    }
}

body Image::unsetBadSpotlist { lattice } {
    
    if {[info exists badspotlist_by_lattice($lattice)]} {
	#puts "Want to unset $badspotlist_by_lattice($lattice) bad spot list for image [$this getNumber]"
	unset badspotlist_by_lattice($lattice)
	if { [catch { delete object $badspotlist_by_lattice($lattice) } msg] } {
	    #puts "unsetBadSpotlist: Error deleting list - $msg"
	} else {
	    #puts "unsetBadSpotlist: Deleted object $badspotlist_by_lattice($lattice)"
	}
    }
}

body Image::setBadSpotlist { badspotlist lattice } {
    if {[info exists badspotlist_by_lattice($lattice)]} {
	unset badspotlist_by_lattice($lattice)
	if { [catch { delete object $badspotlist_by_lattice($lattice) } msg] } {
	    #puts "setBadSpotlist: Error deleting list - $msg"
	} else {
	    #puts "setBadSpotlist: Deleted object $badspotlist_by_lattice($lattice)"
	}
    }
    # Set the badspotlist to be the new badspotlist
    set badspotlist_by_lattice($lattice) $badspotlist
    #puts "sBS:[llength [$badspotlist getBadSpots]] bad spots stored in $badspotlist_by_lattice($lattice) for image [$this getNumber] lattice $lattice"
}

body Image::makeAuxiliaryFileName { a_new_extension { a_directory "" } } {
if { [regexp -- {^(.*?)(_master.h5)$} [$this getTemplateForMosflm] match]} {
	set temp [string replace [file tail [file rootname [$this getTemplateForMosflm]]] end-6 end]
    } elseif { [regexp -- {^(.*?)(.nxs)$} [$this getTemplateForMosflm] match]} {
	set temp [file rootname [$this getTemplateForMosflm]]
    } else { 
	set temp [file tail [file rootname $full_path]]
    }
    # Add lattice if required
    if { $a_new_extension eq "mtz" && ([$::session getNumberLattices] > 1) } {
	set temp ${temp}_lattice[$::session getCurrentLattice]
    }
    set filename [file join $a_directory "$temp.$a_new_extension"]
    return $filename
}

body Image::getImageHeight { } {
    #puts "[root] getImageHeight"
    [root] getImageHeight
}

####################################################################
# Class Cell                                                       #
####################################################################

class Cell {
    
    private common precision 2
    public proc getPrecision { } { return $precision }

    # member variables
    protected variable name ""

    protected variable a ""
    protected variable b ""
    protected variable c ""
    protected variable alpha ""
    protected variable beta ""
    protected variable gamma ""
    
    # methods
    public method setCell
    public method listCell
    public method reportCell
    public method copyFrom

    public method serialize
    public method parseDom

    constructor { a_method args } { }
}

body Cell::constructor { a_method a_name args } {
    set name $a_name
    if {$a_method == "blank"} {
	# Leave member variables at intial values
    } elseif {$a_method == "zeros"} {
	setCell 0 0 0 0 0 0
    } elseif {$a_method == "initialize"} {
	eval setCell $args
    } elseif {$a_method == "copy"} {
	eval setCell [$args listCell]
    } elseif {$a_method == "xml"} {
	parseDom $args
    }
}

body Cell::setCell { a_a a_b a_c a_alpha a_beta a_gamma } {
    foreach i_param { a b c alpha beta gamma } {
	if {[set a_$i_param] == ""} {
	    set $i_param ""
	} else {
	    set $i_param [format %.${precision}f [set a_$i_param]]
	}
    }
}

body Cell::listCell { } {
    return [list $a $b $c $alpha $beta $gamma]
}

body Cell::reportCell { } {
    set l_blanks 0
    foreach i_param { a b c alpha beta gamma } {
	if {[set $i_param] == ""} {
	    incr l_blanks
	    break
	}
    }
    if {$l_blanks > 0} {
	return "Unknown"
    } else {
	return "$a, $b, $c, $alpha, $beta, $gamma"
    }
}

body Cell::copyFrom { a_cell } {
    eval setCell [$a_cell listCell]
}
    

body Cell::serialize { } {
    return "<cell name=\"$name\" a=\"$a\" b=\"$b\" c=\"$c\" alpha=\"$alpha\" beta=\"$beta\" gamma=\"$gamma\"/>"
}

body Cell::parseDom { an_element } {
    set a [$an_element getAttribute "a"]
    set b [$an_element getAttribute "b"]
    set c [$an_element getAttribute "c"]
    set alpha [$an_element getAttribute "alpha"]
    set beta [$an_element getAttribute "beta"]
    set gamma [$an_element getAttribute "gamma"]
}

# ###########################################################

class Spacegroup {

    protected variable spacegroup "Unknown"
    protected variable name "Unnamed"

    public method reportSpacegroup { } {return $spacegroup}
    public method setSpacegroup { a_spacegroup } {set spacegroup $a_spacegroup}

    public method serialize
    public method parseDom 
    public method copyFrom

    constructor { a_method a_name args } { }
    
}

body Spacegroup::constructor { a_method a_name args } {
    set name $a_name
    if {$a_method == "blank"} {
	# Leave member variables at intial values
    } elseif {$a_method == "initialize"} {
	eval setSpacegroup $args
    } elseif {$a_method == "copy"} {
	eval setSpacegroup [$args reportSpacegroup]
    } elseif {$a_method == "xml"} {
	parseDom $args
    }
}

body Spacegroup::serialize { } {return "<spacegroup name=\"$name\" spacegroup=\"$spacegroup\"/>"}

body Spacegroup::parseDom { a_node } {
    set spacegroup [$a_node getAttribute "spacegroup"]
}

body Spacegroup::copyFrom { a_spacegroup } {
    set spacegroup [$a_spacegroup reportSpacegroup]
}

# ###########################################################

####################################################################
# Class Matrix                                                    #
####################################################################

class Matrix {
    
    # member variables
    private variable name "Unknown"
#    private variable bunny ""
    private variable a11 ""
    private variable a12 ""
    private variable a13 ""
    private variable a21 ""
    private variable a22 ""
    private variable a23 ""
    private variable a31 ""
    private variable a32 ""
    private variable a33 ""

    # methods
    public method getName { } { return $name }
    public method setName { a_name } { set name $a_name }
    public method setMatrix
    public method listMatrix
    public method reportMatrix
    public method copyFrom

    public method equals
    public method isValid

    public method serialize
    public method parseDom

    constructor { a_method args } { }
}

body Matrix::constructor { a_method args } {
    if {$a_method == "blank"} {
	set name $args
    } elseif {$a_method == "initialize"} {
	set name [lindex $args 0]
	eval setMatrix [lrange $args 1 end]
    } elseif {$a_method == "copy"} {
	copyFrom $args
    } elseif {$a_method == "xml"} {
	parseDom $args
    }
}

body Matrix::setMatrix { a_a11 a_a12 a_a13 a_a21 a_a22 a_a23 a_a31 a_a32 a_a33 } {
    set a11 $a_a11
    set a12 $a_a12
    set a13 $a_a13
    set a21 $a_a21
    set a22 $a_a22
    set a23 $a_a23
    set a31 $a_a31
    set a32 $a_a32
    set a33 $a_a33
}

body Matrix::listMatrix { } {
    return [list $a11 $a12 $a13 $a21 $a22 $a23 $a31 $a32 $a33]
}

body Matrix::reportMatrix { } {
    if {![isValid]} {
	return "Unknown"
    } else {
	return [list \
		    [format %.3f $a11] \
		    [format %.3f $a12] \
		    [format %.3f $a13] \
		    [format %.3f $a21] \
		    [format %.3f $a22] \
		    [format %.3f $a23] \
		    [format %.3f $a31] \
		    [format %.3f $a32] \
		    [format %.3f $a33]]
    }
}

body Matrix::copyFrom { a_matrix } {
    set name [$a_matrix getName]
    eval setMatrix [$a_matrix listMatrix]
}

body Matrix::equals { a_matrix } {
    return [lequal [listMatrix] [$a_matrix listMatrix]]
}

body Matrix::isValid { } {
    set l_valid 1
    foreach i_elem { a11 a12 a13 a21 a22 a23 a31 a32 a33 } {
	if {([set $i_elem] == "") || (![string is double [set $i_elem]])} {
	    set l_valid 0
	    break
	}
    }
    return $l_valid
}    

body Matrix::serialize { } {
    return "<matrix name=\"$name\" a11=\"$a11\" a12=\"$a12\" a13=\"$a13\" a21=\"$a21\" a22=\"$a22\" a23=\"$a23\" a31=\"$a31\" a32=\"$a32\" a33=\"$a33\"/>"
}

body Matrix::parseDom { a_node } {
    set name [$a_node getAttribute "name"]
    set a11 [$a_node getAttribute "a11"]
    set a12 [$a_node getAttribute "a12"]
    set a13 [$a_node getAttribute "a13"]
    set a21 [$a_node getAttribute "a21"]
    set a22 [$a_node getAttribute "a22"]
    set a23 [$a_node getAttribute "a23"]
    set a31 [$a_node getAttribute "a31"]
    set a32 [$a_node getAttribute "a32"]
    set a33 [$a_node getAttribute "a33"]
}

####################################################################
# Class CellPlus                                                   #
####################################################################

class CellPlus {

    # member variables
    private variable cell ""
    private variable a_matrix ""

    # methods
    public method getCell
    public method getMatrix
    
    constructor { a_method args } { }
}

body CellPlus::constructor { a_method args } {
    # Methods:
    #  copy components: takes cell and a-matrix, creates new components.
    #  copy: takes cell-plus, and copies its components
    #  build: takes cell and a-matrix and uses them directly as components
    #  zeros: takes nothing, creates blank a-matrix and zero cell 
    
    if {$a_method == "copy components"} {
	set cell [namespace current]::[Cell \#auto "copy" [lindex $args 0]]
	set a_matrix [namespace current]::[Cell \#auto "copy" [lindex $args 0]]
    } elseif {$a_method == "copy"} {
	set cell [namespace current]::[Cell \#auto "copy" [[lindex $args 0] getCell]]
	set a_matrix [namespace current]::[Cell \#auto "copy" [[lindex $args 0] getMatrix]]
    } elseif {$a_method == "build"} {
	set cell [lindex $args 0]
	set a_matrix [lindex $args 1]
    } elseif {$a_method == "zeros"} {
	set cell [namespace current]::[Cell \#auto "zeros"]
	set a_matrix [namespace current]::[Matrix \#auto "blank"]
    } else {
	error "Poor attempt to create a CellPlus object."
    }
}

body CellPlus::getCell { } {
    return $cell
}

body CellPlus::getMatrix { } {
    return $a_matrix
}

class SessionParameter {
    private variable name ""
    constructor { a_name } { set name $a_name }
    public method getName { }
}


body SessionParameter::getName { } {
    return $name
}
