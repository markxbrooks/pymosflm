# $Id: message.tcl,v 1.4 2015/07/14 14:15:38 harry Exp $
package provide message 0.1

class Message {
    inherit Dialog

    itk_option define -type type Type "1button" {
	unbutton
	switch -- $itk_option(-type) {
	    "1button" {
         	pack $itk_component(button1of1) -side top -padx 7 -pady 7
		focus $itk_component(button1of1)
	    }
	    "2button" {
         	pack $itk_component(button1of2) -side left -padx 7 -pady 7
         	pack $itk_component(button2of2) -side right -padx 7 -pady 7
		focus $itk_component(button2of2)
	    }
	    "3button" {
		pack $itk_component(buttontext) -side top -anchor ne
         	pack $itk_component(button1of3) -side left -padx 7 -pady 7
         	pack $itk_component(button2of3) -padx 7 -side right 
         	pack $itk_component(button3of3) -padx 7 -side right 
		focus $itk_component(button3of3)
	    }
	    "TwoButton" {
         	pack $itk_component(buttonAofB) -side left -padx 7 -pady 7
         	pack $itk_component(buttonBofB) -side right -padx 7 -pady 7
		focus $itk_component(buttonAofB)
	    }
	}
    }
    
    constructor { args } {
	
	itk_option add hull.borderwidth
	
	wm iconbitmap $itk_component(hull) [wm iconbitmap .]
	wm iconmask $itk_component(hull) [wm iconmask .]
	
	set warning "R0lGODlhIAAgAKEAAAAAAP//AJmZmf///yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAIAAgAAACjpyPB5vtb0CYAFonJxW3j6wBAuc9\noBaIZJmc4ci26KzGyozWtovrrLvIwX60xcnXARqFqwvPCBw6e0tmEpeqWi28\nbJAmxWC9XaRs/O2FEd1QO7WOjClv82dOx5vf+K28n4YmxUemN0RYaMiBmNUH\nt+gYuTHCKKkCKal4CMXZ6bkwEooQSlpqehqHqopqUAAAOw=="
	image create photo warning -data $warning
	
	$itk_component(hull) configure -borderwidth 0
	

	itk_component add messageframe {
	    frame $itk_interior.mf \
         	-relief raised \
		-borderwidth 1
	}
	pack $itk_component(messageframe) -side top -fill both -expand 1
	
   	itk_component add icon {
	    label $itk_interior.mf.icon \
         	-image warning \
		-anchor center
	} {
	    keep -background
	}
	pack $itk_component(icon) -side left -padx 7 -pady 14
	
	itk_component add message {
	    label $itk_interior.mf.message \
		-anchor w \
		-justify left
	} {
	    keep -background
	    keep -text
	}
	pack $itk_component(message) -side left -padx 7 -pady 14
	
	itk_component add buttonframe {
	    frame $itk_interior.bf \
         	-relief raised \
		-borderwidth 1
	}
	pack $itk_component(buttonframe) -side top -fill x
	
	itk_component add buttontext {
	    label $itk_interior.bf.text \
         	-text "Session"
	} {
	    keep -background
	    rename -activebackground -background background Background
	    rename -highlightbackground -background background Background
	    rename -text -buttontext buttontext Text
	}

	
	itk_component add button1of1 {
	    button $itk_interior.bf.button1of1 \
         	-text "OK" \
		-command [code $this dismiss 1] \
		-highlightthickness 1 \
		-width 7 \
		-pady 2
	} {
	    keep -background
	    rename -activebackground -background background Background
	    rename -highlightbackground -background background Background
	    rename -text -button1of1 button1of1 Text
	}
	
	itk_component add button1of2 {
	    button $itk_interior.bf.button1of2 \
         	-text "Yes" \
		-command [code $this dismiss 1] \
		-highlightthickness 1 \
		-width 7 \
		-pady 2
	} {
	    keep -background
	    rename -activebackground -background background Background
	    rename -highlightbackground -background background Background
	    rename -text -button1of2 button1of2 Text
	}
	
	itk_component add button2of2 {
	    button $itk_interior.bf.button2of2 \
         	-text "No" \
		-command [code $this dismiss 0] \
		-highlightthickness 1 \
		-width 7 \
		-pady 2 \
	    } {
		keep -background
		rename -activebackground -background background Background
		rename -highlightbackground -background background Background
		rename -text -button2of2 button2of2 Text
	    }
	
	itk_component add button1of3 {
	    button $itk_interior.bf.button1of3 \
         	-text "No" \
		-command [code $this dismiss 2] \
		-highlightthickness 1 \
		-width 7 \
		-pady 2 \
	    } {
		keep -background
		rename -activebackground -background background Background
		rename -highlightbackground -background background Background
		rename -text -button1of3 button1of3 Text
	    }
	
	itk_component add button2of3 {
	    button $itk_interior.bf.button2of3 \
         	-text "Once" \
		-command [code $this dismiss 0] \
		-highlightthickness 1 \
		-width 10 \
		-pady 2 \
	    } {
		keep -background
		rename -activebackground -background background Background
		rename -highlightbackground -background background Background
		rename -text -button2of3 button2of3 Text
	    }
	
	itk_component add button3of3 {
	    button $itk_interior.bf.button3of3 \
         	-text "Always" \
		-command [code $this dismiss 1] \
		-highlightthickness 1 \
		-width 10 \
		-pady 2 \
	    } {
		keep -background
		rename -activebackground -background background Background
		rename -highlightbackground -background background Background
		rename -text -button3of3 button3of3 Text
	    }
	
	itk_component add buttonAofB {
	    button $itk_interior.bf.buttonAofB \
         	-text "Yes" \
		-command [code $this dismiss 1] \
		-highlightthickness 1 \
		-width 0 \
		-pady 2
	} {
	    keep -background
	    rename -activebackground -background background Background
	    rename -highlightbackground -background background Background
	    rename -text -buttonAofB buttonAofB Text
	}
	
	itk_component add buttonBofB {
	    button $itk_interior.bf.buttonBofB \
         	-text "No" \
		-command [code $this dismiss 0] \
		-highlightthickness 1 \
		-width 0 \
		-pady 2 \
	    } {
		keep -background
		rename -activebackground -background background Background
		rename -highlightbackground -background background Background
		rename -text -buttonBofB buttonBofB Text
	    }
	
	eval itk_initialize $args
    }
    
    public method unbutton
    public method confirm
}

body Message::unbutton { } {
    pack forget $itk_component(button1of1)
    pack forget $itk_component(button1of2)
    pack forget $itk_component(button2of2)
    pack forget $itk_component(button1of3)
    pack forget $itk_component(button2of3)
    pack forget $itk_component(button3of3)
    pack forget $itk_component(buttontext)
    pack forget $itk_component(buttonAofB)
    pack forget $itk_component(buttonBofB)
}

body Message::confirm { args } {
    eval configure $args
    Dialog::confirm
}

class OptionMessage {
    inherit Dialog

    private variable choice "1"

    public method dismiss { result }

    itk_option define -options options Options "2" {
	grid forget \
	    $itk_component(option1) \
	    $itk_component(option2) \
	    $itk_component(option3) \
	    $itk_component(buttonframe)
	set count 1
	while {$count <= $itk_option(-options)} {
	    grid x $itk_component(option$count) -sticky w
	    incr count
	}
	grid $itk_component(buttonframe) - -sticky we
    }

    constructor { args } { }
}

body OptionMessage::constructor { args } {

    wm iconbitmap $itk_component(hull) [wm iconbitmap .]
    wm iconmask $itk_component(hull) [wm iconmask .]
    set itk_option(-title) "Warning" 
        
    image create photo warning -data "R0lGODlhIAAgAKEAAAAAAP//AJmZmf///yH+FUNyZWF0ZWQgd2l0aCBUaGUg\nR0lNUAAh+QQBCgADACwAAAAAIAAgAAACjpyPB5vtb0CYAFonJxW3j6wBAuc9\noBaIZJmc4ci26KzGyozWtovrrLvIwX60xcnXARqFqwvPCBw6e0tmEpeqWi28\nbJAmxWC9XaRs/O2FEd1QO7WOjClv82dOx5vf+K28n4YmxUemN0RYaMiBmNUH\nt+gYuTHCKKkCKal4CMXZ6bkwEooQSlpqehqHqopqUAAAOw=="
    
    itk_component add icon {
	label $itk_interior.icon \
	    -image warning \
	    -anchor center
    } {
	keep -background
    }
    #	pack $itk_component(icon) -side left -padx 7 -pady 14
    
    itk_component add message {
	label $itk_interior.message
    } {
	usual
	rename -text -message message Message
    }
    
    itk_component add option1 {
	Radio $itk_interior.radio1 \
	    -variable [scope choice] \
	    -value 1 \
	    -text "Option 1"
    } {
	usual
	rename -text -option1 option1 Text
    }
    
    itk_component add option2 {
	Radio $itk_interior.radio2 \
	    -variable [scope choice] \
	    -value 2 \
	    -text "Option 2"
    } {
	usual
	rename -text -option2 option2 Text
    }
    
    itk_component add option3 {
	Radio $itk_interior.radio3 \
	    -variable [scope choice] \
	    -value 3 \
	    -text "Option 3"
    } {
	usual
	rename -text -option3 option3 Text
    }
    
    itk_component add buttonframe {
	frame $itk_interior.bf \
	    -borderwidth 0
    }
    
    itk_component add okay {
	button $itk_interior.bf.okay \
	    -text "Ok" \
	    -command [code $this dismiss 1] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    }
    
    itk_component add cancel {
	button $itk_interior.bf.cancel \
	    -text "Cancel" \
	    -command [code $this dismiss 0] \
	    -highlightthickness 1 \
	    -width 7 \
	    -pady 2
    }
    
    grid $itk_component(icon) $itk_component(message)
    grid x $itk_component(option1) -sticky w
    grid x $itk_component(option2) -sticky w
    grid $itk_component(buttonframe) - -sticky we
    pack $itk_component(okay) -side right -padx 7 -pady 7
    pack $itk_component(cancel) -side right -pady 7

    eval itk_initialize $args
    
}

body OptionMessage::dismiss { okay } {
    if {$okay} {
	Dialog::dismiss $choice
    } else {
	Dialog::dismiss 0
    }
}
