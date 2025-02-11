# $Id: activity.tcl,v 1.3 2014/03/06 15:27:04 harry Exp $
package provide activity 1.0

image create photo ::img::activity_idle16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhg4IlpNqQAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABEElEQVQ4y6WSsU0EMRBFn81WQEwAARcQQEwL5OTQANLlUAASiIAOoAgySkAEBEhUAB14PZ5PsLdn7wVI7H3Jsr+l+frzZ8Lx3bdC7CBEkCMvqPTIxpNwS8j61Z1QTut3F2LH+3KXOTi4fCaGuMNsBIiS2AYRt/nVEp0sr/nJ/Q94QSWjkvEmyDbMr8ezKuClr4KWkDu4oZKH222YjPswJZXGgNPJUv3ICcn5uFkAcHT9Bm583p4CcHj1Au5NCxsCbgmaUMdWKh8c1fpC57bRQitg/aRgbKny8rcDLz0UmziYcDdYLF81F3vnD4reOPj3GngmagsBgK0cAIT9iycRQmtstTAatlLjYpUhNDdEDfoX1YIrP2IJQqsAAAAASUVORK5CYII="
image create photo ::img::activity_blue_blank16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhkYAC9cIAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAA8klEQVQ4y6WTwXFEMQhDtTMpKWlxi0hhaQaQ9mAwsJPb/ovtb1s8BH5IEj74vgDg+xcABIVD4QANpAO5Fh0Ky30Dcv33/DkCECHGOcQUCYdoYPi9gDEXvQlEByLGgUPRY/ScTdUChckU4InGHBElVtEP7SIoxM7dBk0sdCbNILAbvS4rPRAd8PQj95HiO4UwYBo5BMlJ4210CWCURoxBMS7WfJT0CnTecbCjCW70t8vaHswSWfaAj/zn/6KKncItzzST1n3AdD4rtVKYxsl9HJ6NY8vEXcY3h5uoUtnvAP924o1yyskSWh0aqxIA8Pj0Ob8ApJQID4ePxKQAAAAASUVORK5CYII="
image create photo ::img::activity_blue_N16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhkjsSS1BAAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABHklEQVQ4y6WTQUoEQQxFX4t38ATigO48h4fwAO6GcSkeQlx7CfeCuBcENy68RldX8l2kqrq6mcXIBEIlUP3yk0oPksQRdgpw/TwBA7IJ5YTbiHIKt4TXOI/IIvac+Hm64QQgRPT+TwWyokCG5CCHApXUYohDXaECSJHKkRlyC5hX2OyiwNUDcgLgc3t2kOzzu9f9gENN8mgVyhAtpl3t6vGby4evlm/uP7jYvs0Et2ipKvCVArcpLtWKntEit5bvbUGWFgAsh/cKloBxCcgTqKtoGfm0UhTAQZI2u/flG8vBYyfkGcziowKSZWQTvy+3yxbqLiDFlGuvbq1qU1MUrIY4b11don0A6tlvYnngBgkFjmRNiTxH3M1kOPZ3/gMGokeSiWQqxgAAAABJRU5ErkJggg=="
image create photo ::img::activity_blue_NE16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhky25SV9gAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABaElEQVQ4y6WTv04bQRCHPyPeARoKE8kFpiIdJTWkSUMbaOgQKIgyGLmhoQIlUkpEyQOkMO9gEAbEn/fw3c78KMa3Ppt0Xmm0N6ubmd83s9uQJGZY8wBff5cAyEo8FSgVyIYoFTW/QKl2ZgWvl9+YY8Y1D+CpCM8tTM7d8RIA7ZMBIJBiC63hQyiQjSRaiTzRP1rMFR5OVkAOcoSPvkWVKhJkzpL+z4VPMgfdNVQF1m06Qb3y6ukT7V/32X86Wwc3JEPySDiNUK125zFwLE0oeT7fAHeQxQ40JKndeYw/pGBVNHPQXftv57/s3SAref+7XSEMw6pmpnIiuHXYo7X/L/tvf77HtKoxKo3lU+MDaB30kCeYwpGnWoKKX0IjjNbhbTTNDTzxcrGZg5s7V3H+6SLlCzNS4Y7ceL3cmgy2lBs8hTCecczdciWA5o8r5AlZCRMIaVinyxgxd2d59zoC3aKyjxU0Zn3OH3MLQ7LDH/NKAAAAAElFTkSuQmCC"
image create photo ::img::activity_blue_E16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhk7okgtUgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABNklEQVQ4y6WTMU7EMBBFnyPuwAUQiAIhcQG4Aueg3QqJioIGWrgHR6ClQkJIW2zBMRJ75lOMnV0ib7WWLMfR5Pn/P06SJA4YRwBXryOQwDJuEyoxvYz1edzuLfZeJjZvtwwAKQ2kYYCUAlRHWh6X9iiQZSAhN5DztTruyj1bfYAEItYG8DJFhRxZ2W9YDggFYUdBqRnIkRsXT7/IcvWb+Xm8rAAheYD0DzC1I5BbWLEMZuBbRZKBN4AvAAkkgZzvh9O+BTckQ+7IdwBu4yyxkfsRGLQp61iogPP7z1pckBXWLzcVUJBZrG7LEFtImsPEo3hWYGX+uL1ftDHas36+7luwjDxXJaWjYO71vgwKWIkOeem3EYmTu/dqw2cbs2zLYaWnQLudkMelqfciIKGgZQGQDv2d/wCewEE2AonGCQAAAABJRU5ErkJggg=="
image create photo ::img::activity_blue_SE16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhoINrUfhwAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABYUlEQVQ4y6WTv0ojURTGfxN8E6NEWRBdK9HOTtjXcBUbi2ixARVFcLewcfcpVtxiSzvFSmzUGNQXSWbO+SzunZuZxC4HDsNczv3m+3MmkyQmqCmAr38GkDWQDfBigGyAirL7I2fD9/ff32gwYU0BuOVkWYbcQF5rIbrHCwC09m4JegVReQOoUM+RFcgNuSN5GgTo/VyNwAogCSBqUwUEL8ANuTH34z6BvJ6vg4Q0BhCNshxZzmOnydPBHLiBG632bQJ5u9gITKoSaglYnoa7J4tBkqzunlvFxKIPZEGbgvb5zgPdk6Wg/Wyldnf6+2XwZ9SD58N5no++JC9a+3djsTW3rpI3Yx6U9XK6PHYG0Nz+h7xAHk0uJZSDrfYNvV9rgXZ81i5bUekKA7c+Hk2c3b3+lHaZTslAkUF9D+K+z+z8rxnm5eXURUqqJiFsqZCc6c2/IZEyQrPh123oQTbp7/wBztVhAAetmiMAAAAASUVORK5CYII="
image create photo ::img::activity_blue_S16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhoQJdmH0QAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABH0lEQVQ4y6WTMUoEQRBF38rewQsIaiAIXsAreA7TTTYxEcyM9x4ewdBMEEEQPMfMVNU3qN7pntkVgykGun/T9fn/d81KklhQa4CbnSEF8gFZh6xH3hPWV2xdYq9n37s7TlhYayBZJQgDBUiJyx5E+lTi/CpBWJcoAoUhGYQXgkBlrWSFaFRgPQDvm1MArp5+UDgfDxcAXG7fQMHX8y0AZ/cvSTgn2JfcUAwVh6OI5kLMCboZwYDC6kF45jP2F1s1g7mCHoU3DTbBSejTV2jr8/F6gvfejxEetfBfZSZ+aOF885pvHYGUMvOyjcHKLfMomTSvUEZDyoDCy5pyx0ZPErn9YUExTqFiqoJWyaGCHNVsLgQTG94QGPKck9XS3/kXAHFIKTTW+5AAAAAASUVORK5CYII="
image create photo ::img::activity_blue_SW16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhoaxQxuzwAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABcUlEQVQ4y6WTMWsbURCEPwX/CRcJiBiRIEgj/A/SpAl24V5pUqWwiwSBm7MhbgOBWOBKuHXpMmpTurBBFiTKD7m7tzsu9qS749xpYeHY93bezM5eT5LYInYARtMSAFmJpxylosocTwWyxvfmPGc1PeQFW8YOgKeCHiA3cAc5D5OXAAyzBUh1Btc2gKyIkjvyxP3X3foJOZIToxLIQWI9ugBIxeZys3mYPQYrBSs8gKQKqAbIAXiYvKqbz5bIE3JjebEPwOBkDm4gawP4mkEjZCVYYvl9VBfdQo6HrI6EYbZgkQ0BeDx/1wIcHP+uhpyChRtA2BjeRr49veuwGRzPKzmJ1eUB/6+OAqwGKFr55tufthwvkZWsfn1s1KwxA8treyubBidz/v54D8C/nx9agP3xLKR0GeTICtxiXfe+3Hbk9MczZAlZemYG1pBiBUolrz/fdJu9RBWDlguCamV9s4G40f90HQ1uFUAKm4Hetr/zE+KdSE7mi96HAAAAAElFTkSuQmCC"
image create photo ::img::activity_blue_W16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhoi7Q7WUQAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABKElEQVQ4y6WTMU4EMQxFXxB3oEcIkJBoOAFH4BI0FDQrasQBaPcM1FS0iAvQrLQSF9lM7E/hTIYws9VGY81k4rz4206SJA4YxwA36wFJyAZUMrIdKhkvGZX4jvkO2fTvZ33HUXASKaU/3LR8XNoTgSzHzA3kfK9OFvdfrD5BgngmgJcMCNyRl/2C5eGHAtQiKLvmILfmf/W8qZpzRClH1QLWAHkC1IWYFuSGZMjrmtfNSwBRHerYvFx3Cs4fP3pYy4GNEtTIyymwSPRocwk94PLpC1kJKTZMkup7IYn0OSjjphKg0dz+A3Kt61QegO3rbSfh9P4NvEzW98EcMBtWpdRI5hJqKc8e3qeeUIQri1NDwtAark8iIi5n7UpFtpvmBohIANKh1/kXam9Eb0XwMk4AAAAASUVORK5CYII="
image create photo ::img::activity_blue_NW16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhopetwP2QAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAABaElEQVQ4y6VTvUoDQRicE9/E/BxoI7aildoJvkRALJLCoI2iYGcKLSQPYGcldtFKFPICiRjRwsfI7n47Ft/e3l5SSRaWu9vdmW9m9ruMJLHAWAaAjb4FSVAs6AzopqAY+OI9PP3M3k//AEvKkyHLspI2+6cCitEvLwA9QIIkEObH1ToAoHn8qucI3QNUgXcG3k3Vgnegl0AmGF+uxWqT3raSwweWQBB9ilESUZLReT4n+et2NypLCAzoQmhiQbEYndUjKD8ZlvIBfN/tq9WqAk2XzlTAMRsvqLcHcYleyhC9M8Uyxherc7I/rzfR6LwA3qF2+KiFKgpE/afg/HSIvPteer/ZAUWqIc9aSAedBcVo5Sjbgr4gcdoyJNnsvoUTxKS3FQGN9qAEiAvXbGPQv/et+RAbnefkyvZCsDaCIa6cs9dY9EPt6GnOSuyP2CcuaeXEv7awx0rrQZP2kvgWQFywkWSwyO/8B/V5aN52sWupAAAAAElFTkSuQmCC"
image create photo ::img::activity_error_blank16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDhsHvxEzVwAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAgElEQVQ4y6VTQQ7AIAiryd6x/z9S6C5q5kTEaUIgxpbWQCJJHJwLAJASCIAAFICU0EW+yUJQwBVIB/Sum4J6qUHgQLACfYlrDAqszD8KrM5iKOkU7FrInoU86S6eAp3IFMfG1h9YdSPIk4eyIOkUaGB0dXcSNTqJErAw24V0us4PeyLKdRr7WXAAAAAASUVORK5CYII="
image create photo ::img::activity_error_N16x16 -data "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABmJLR0QAAAAAAAD5Q7t/AAAACXBIWXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH1gMXDho1bt1TlgAAAB10RVh0Q29tbWVudABDcmVhdGVkIHdpdGggVGhlIEdJTVDvZCVuAAAAs0lEQVQ4y6VTwQ0CMQyzET+GYA72nwLx4IduiLbmQVsF04iTLlLUy7W2nNSlJOFAnAEAJACg9aw9/bsBKOH/VfoQyMAZUbOcCmQbA6g/iiZBJjcDq6+TYPR22TnPOzkJTjBJeyLOYBLUcGAj8eo3AwBPEo9Q/wyxmYJmhKPvESUbYgTsrZcErsBrhfOUpI38MouvJVxd3LsNJ7ppIqgsXFpXPnDTrMCuYOnElrSRvQUefc5v9uGmfr2outoAAAAASUVORK5CYII="


class Activity {
    inherit Balloonwidget

    private variable current_image_list {}
    private variable busy_list {::img::activity_blue_N16x16 ::img::activity_blue_NE16x16 ::img::activity_blue_E16x16 ::img::activity_blue_SE16x16 ::img::activity_blue_S16x16 ::img::activity_blue_SW16x16 ::img::activity_blue_W16x16 ::img::activity_blue_NW16x16}
    private variable warn_list {::img::activity_error_N16x16 ::img::activity_error_N16x16 ::img::activity_error_blank16x16}
    private variable pause_list {::img::activity_blue_N16x16 ::img::activity_blue_N16x16 ::img::activity_blue_blank16x16 }
    private variable idle_list {::img::activity_idle16x16 }

    private variable queue ""

    public method busy
    public method idle
    public method pause
    public method warn

    private method animate
    private method reset
    private method stop

    private method loopImages

    constructor { args } { }
}

body Activity::constructor { args } {

    itk_component add label {
	Toolbutton $itk_interior.l \
	    -command [ code $this reset ]
    }
    pack $itk_component(label)

    eval itk_initialize $args
}

body Activity::reset { } {
    # If iMosflm is hung with a spinning icon this should clear its job queue and re-enable it
    while { [$::mosflm busy] } {
	set job [$::mosflm getFirstJob]
	$::mosflm removeJob $job
    }
    .c idle
    .c enable
    idle
}

body Activity::busy { {a_message ""} } {
    configure -balloonhelp $a_message
    animate $busy_list
}

body Activity::idle { } {
    configure -balloonhelp "Idle"
    animate $idle_list
}

body Activity::pause { } {
    configure -balloonhelp "Paused"
    animate $pause_list 200
}

body Activity::warn { {a_message "Error"} } {
    configure -balloonhelp $a_message
    animate $warn_list 200
}

body Activity::animate { a_list { a_interval "125" } } {
    stop
    set current_image_list $a_list
    if {[llength $current_image_list] <= 1} {
	$itk_component(label) configure \
	    -image [lindex $current_image_list 0]
    } else {
	loopImages 0 $a_interval
    }
}

body Activity::stop { } {
    if {$queue != ""} {
	after cancel $queue
    }
}    

body Activity::loopImages { a_index a_interval } {
    if {$a_index >= [llength $current_image_list]} {
	set a_index 0
    }
    $itk_component(label) configure \
	-image [lindex $current_image_list $a_index]
    incr a_index
    set queue [after $a_interval [code $this loopImages $a_index $a_interval]]
}

usual Activity { }
