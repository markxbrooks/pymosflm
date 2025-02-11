# $Id: qtrv.tcl,v 1.6 2022/09/08 09:52:58 andrew Exp $
package provide qtrv 0.0

namespace eval qtrv {
   variable available 0
   variable viewerpid 0

    if { [regexp -nocase windows $::tcl_platform(os)] } {
      proc file_executable { file } {
         return [file isfile $file]
      }
   } else {
      proc file_executable { file } {
         return [file executable $file]
      }
   }

   if { [string length [array names ::env -exact CCP4]] } {
      set ccp4path [file normalize $::env(CCP4)]
      # puts "qtrv: ccp4path is $ccp4path"
      variable viewer [file join $ccp4path bin qtrview]
      # puts "qtrv: variable viewer is $viewer"
      if { ! [file_executable $viewer] } { set viewer $viewer.exe }

      variable viewer_py [file join $ccp4path bin qtrview.py]
      # puts "qtrv: variable viewer_py is $viewer_py"

      variable generator [file join $ccp4path share smartie qtrgeneric.py]
      # puts "qtrv: variable generator is $generator"

      variable ccp4python no_ccp4_python
      set python_version [ exec ccp4-python -V]
      puts "Python version is: $python_version"
      # Add parentheses to "print" statement to make compatible with Python ver 3 (CCP4 8.0)
      if { ![catch { exec ccp4-python -c "import sys ; print (sys.executable)" } python_path] } {
         set ccp4python [file normalize $python_path]
         # puts "qtrv: ccp4python set to $ccp4python"
      }

       # puts "qtrv: file_executable_viewer is: [expr [file_executable $viewer]]"
       # puts "qtrv: file_executable_ccp4python is: [expr [file_executable $ccp4python]]"
       # puts "qtrv: file_executable_generator is: [expr [file isfile  $generator]]"

      set available [expr [file_executable $viewer] && [file_executable $ccp4python] && [file isfile $generator]]
      # puts "qtrv: available is $available"
   }

   proc isAvailable {} {
      variable available
      return $available
   }

   proc footPrint {} {
      variable viewerpid
      set cmd {}
      if { [catch { set cmd [lindex [split [exec ps -o comm -p $viewerpid]] 1] } errmsg] } {
         catch { set cmd [lindex [split [exec TASKLIST /FI "PID eq $viewerpid" /FO CSV /V /NH] ,] 0] } errmsg
      }
      return $cmd
   }

   proc launchReportViewer { a_logfile a_mtz_file a_bool } {
      variable available

      if { $available } {
         set rep_suffix qt
         set rep_roottail report

         set log_file_path [file normalize $a_logfile]

         set rep_dir_path [file rootname $log_file_path]_$rep_suffix
         if { ! [file isdir $rep_dir_path] } {
            if { [file exists $rep_dir_path] } { file delete -force $rep_dir_path }
            file mkdir $rep_dir_path
         }
         set rep_rootname [file join $rep_dir_path $rep_roottail]
         set rep_inp_unit [open $rep_rootname.inp w]

         variable ccp4python
         variable generator
         puts $rep_inp_unit "PYTHON $ccp4python"
         puts $rep_inp_unit "XRT_GEN $generator"
         puts $rep_inp_unit "LOGFILE $log_file_path"
         puts $rep_inp_unit "REP_DIR $rep_dir_path"
         puts $rep_inp_unit "REP_XRT $rep_rootname.xrt"
         puts $rep_inp_unit "REP_XML $rep_rootname.xml"

         set proj_dir_path [file dirname $log_file_path]
         puts $rep_inp_unit "HKLIN [file join $proj_dir_path $a_mtz_file]"
         if { $a_bool } {
            puts $rep_inp_unit "HKLOUT [file join $proj_dir_path pointless_$a_mtz_file]"
            puts $rep_inp_unit "TITLE Quick Symmetry"
         } else {
            puts $rep_inp_unit "HKLOUT [file join $proj_dir_path ctruncate_$a_mtz_file]"
            puts $rep_inp_unit "TITLE Quick Scale"
         }
         close $rep_inp_unit

         variable command
         if { ! [info exists command] } { set command void }
# next line stops a new qtrview instance being started
	  #         if { ! [file isfile nograph] && ! [string equal $command [footPrint]] } {}
         if { ! [file isfile nograph] } {
            variable viewer
            variable viewer_py
            variable viewerpid
            if { [file isfile $viewer_py] } {
               set viewerpid [exec $ccp4python $viewer_py $viewer $rep_rootname.inp &]
            } else {
               set viewerpid [exec $viewer --inp-file $rep_rootname.inp &]
            }
            set command [footPrint]
         } else {
            puts -nonewline [exec $ccp4python $generator $rep_rootname.inp]
         }
      }
   }
}

