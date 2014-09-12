xtab
====

What is it?

A script to wrap the various syntaxes of tabbed terminal types to allow
the Easy launch of script commands within those tabs. Supports gnome-terminal, 
konsole, mrxvt and even screen

Why?

I got tired of trying to remember the various obscure syntax forms that
each term type accepts and I wanted to have a script to just open a "tabbed"
terminal and launch commands with little care for which flavor of terminal
type is on the users system. This script makes that easy.

Usage:

You can choose the form of terminal to launch, or if not set it will
try gnome-terminal, konsole, mrvxt and xterm in that order. We never
auto launch screen as it is a bit too obscure for the average user,
even though it is my favourite. Default default is gnome-terminal as
it seems the most end-user friendly if you are wrapping this tool in
a script.

Usage: ./xtab.sh -name ... -title ... -command ... -title ... -command ...

e.g.:

    xtab.sh          -t tabA -c "vim 1" -t tabB -c "vim 2" # use any
    xtab.sh -konsole -t tabA -c "vim 1" -t tabB -c "vim 2"
    xtab.sh -screen  -t tabA -c "vim 1" -t tabB -c "vim 2"
    xtab.sh -gnome   -t tabA -c "vim 1" -t tabB -c "vim 2"
    xtab.sh -mrxvt   -t tabA -c "vim 1" -t tabB -c "vim 2"
