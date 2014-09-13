#!/usr/bin/expect -f
# -*-mode: tcl; indent-tabs-mode: nil; backward-delete-char-untabify-method: nil;-*-

proc ExpectShellPrompt {} {
    expect {
        {bash-[0-9]} {
            puts "Received a bash prompt (type 1)"
        }
        -re {[^@]+@[^ ]+ *:} {
            puts "Received a bash prompt (type 2)"
        }
        timeout {
            puts "Got a timeout"
            send "\r"
            exp_continue
        }
    }
}

proc SendExpectShellPrompt {args} {
    eval send $args
    ExpectShellPrompt
}

proc InteractUntilExit {} {
    set CTRLD \004
    puts "Hit CTRL-D to exit Tcl expect automation..."
    interact {
        $CTRLD {
            puts "Terminating Tcl expect automation ..."
            exit
        }
    }
}

proc Note {args} {
    set str ""
    foreach arg $args {
        append str "$arg "
    }
    set msg "\nAUTOMATER: $str"
    puts $msg
    send_log $msg
}

set doMinimalExample 0

if {$doMinimalExample} {
    set timeout 2
    spawn bash
    set LOG_FILE [lindex $argv 0]
    log_file $LOG_FILE
    ExpectShellPrompt

    set myPause 2000
    Note "pausing ..."; after $myPause;

    send "read -p \"Enter arithmetic or Perl expression: \" dummy\r"
    expect {
        {Enter arithmetic or Perl expression:} {
            Note "Got Term::ReadLine prompt"
            send "exit\r"
        }
        timeout {
            Note "Got a timeout waiting for Term::ReadLine prompt"
            exp_continue
        }
    }
    InteractUntilExit
}

# We may eventually want to stop doing this manually and try the
# things in
# http://www.nntp.perl.org/group/perl.cpan.discuss/2010/04/msg554.html
# but that seemed just as high-maintenance as this expect script so
# skip that for now:
if { ! $doMinimalExample } {
    set timeout 4
    spawn cpan Bundle::CPAN
    set LOG_FILE [lindex $argv 0]
    log_file $LOG_FILE
    expect {
        {Would you like to configure as much as possible automatically} {
            Note "Detected the configure as much as possible automatically prompt"
            send "yes\r"
            exp_continue
        }
        {Would you like me to automatically choose some CPAN} {
            Note "Detected the Would you like me to automatically choose some CPAN prompt"
            send "yes\r"
            exp_continue
        }
        {Enter arithmetic or Perl expression:} {
            Note "Detected the Term::ReadLine Enter arithmetic or Perl expression prompt"
            send "exit\r"
            exp_continue
        }
        {Ah, I see you already have installed libnet before} {
            # The full prompt is
            #    Ah, I see you already have installed libnet before.
            #    
            #    Do you want to modify/update your configuration (y|n) ? [no] 
            Note "Detected the libnet I see you already have installed libnet before prompt"
            # If we say "yes" here we get prompted for a ton of things like host names and I do not think it is needed so say "no":
            send "no\r"
            exp_continue
        }
        timeout {
            exp_continue
        }
    }
    Note "Done with Bundle::CPAN"
}
