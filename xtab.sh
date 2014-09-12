#!/bin/bash
#
# Copyright (C) 2014 Neil McGill
#
# This is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this software; if not, write to the Free
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
VERSION="0.1"

help()
{
    echo "A tool to kick off a tabbed terminal with a command running in each."
    echo
    echo "You can choose the form of terminal to launch, or if not set it will"
    echo "try gnome-terminal, konsole, mrxt and xterm in that order."
    echo
    echo "Usage: $0 -name ... -title ... -command ... -title ... -command ..."

    echo
cat <<%%
    xtab.sh          -t tabA -c "vim 1" -t tabB -c "vim 2" # use any
    xtab.sh -konsole -t tabA -c "vim 1" -t tabB -c "vim 2"
    xtab.sh -screen  -t tabA -c "vim 1" -t tabB -c "vim 2"
    xtab.sh -gnome   -t tabA -c "vim 1" -t tabB -c "vim 2"
    xtab.sh -mrxvt   -t tabA -c "vim 1" -t tabB -c "vim 2"
%%
    echo

    echo "  -n"
    echo "  -name"
    echo "  --name <title>    : Name of the window."
    echo
    echo "  -t"
    echo "  -title"
    echo "  --title           : Title for this tab."
    echo
    echo "  -c"
    echo "  -command"
    echo "  --command         : Command to run in this tab."
    echo
    echo "  -gnome"
    echo "  --gnome           : Use tabbed gnome terminal"
    echo
    echo "  -xterm"
    echo "  --xterm           : Use multiple xterms"
    echo
    echo "  -konsole"
    echo "  --konsole         : Open tabbed konsole sessions"
    echo
    echo "  -mrxvt"
    echo "  --mrxvt           : Open tabbed mrxvt sessions"
    echo
    echo "  -screen"
    echo "  --screen          : Open terminal screen sessions"
    echo
    echo "Version $VERSION"
}

XTAB_ARG_FILE=/tmp/xtab.sh.$LOGNAME.$$
trap "/bin/rm -f $XTAB_ARG_FILE &>/dev/null" 0 1 2 15 ERR

COMMAND_COUNT=0
TITLE_COUNT=0

export OPT_UI_SET=0
export OPT_UI_SCREEN=0
export OPT_UI_XTERM=0
export OPT_UI_GNOME=0
export OPT_UI_KONSOLE=0
export OPT_UI_MRXVT=0
export OPT_NAME=$LOGNAME

while [ "$#" -ne 0 ];
do
    case $1 in
    -n | -name | --name )
        shift
        export OPT_NAME=$1
        ;;

    -gnome | --gnome )
        export OPT_UI_GNOME=1
        export OPT_UI_SET=1
        ;;

    -xterm | --xterm )
        export OPT_UI_XTERM=1
        export OPT_UI_SET=1
        ;;

    -konsole | --konsole )
        export OPT_UI_KONSOLE=1
        export OPT_UI_SET=1
        ;;

    -mrxvt | --mrxvt )
        export OPT_UI_MRXVT=1
        export OPT_UI_SET=1
        ;;

    -screen | --screen )
        export OPT_UI_SCREEN=1
        export OPT_UI_SET=1
        ;;

    -t | -title | --title )
        shift
        TITLES[$TITLE_COUNT]=$1
        TITLE_COUNT=$(( $title_count + 1 ))
        ;;

    -c | -command | --command )
        shift
        COMMANDS[$COMMAND_COUNT]=$1
        COMMAND_COUNT=$(( $COMMAND_COUNT + 1 ))
        ;;

    *)
        help
        echo $0: $1 unknown arg
        exit 1
    esac

    shift
done

if [ $COMMAND_COUNT -eq 0 ]
then
    help
    echo $0: no commands specified
    exit 1
fi

trace()
{
    echo $*
    $*
}

launch_screen()
{
    for i in $(seq 0 $((${#COMMANDS[*]}-1)))
    do
        local COMMAND=${COMMANDS[i]}
        local TITLE=${TITLES[i]}

        if [ "$TITLE" != "" ]
        then
            screen sh -c "$COMMAND"
        else
            screen -t "$TITLE" sh -c "$COMMAND"
        fi

        sleep 1
    done
}

launch_xterm()
{
    for i in $(seq 0 $((${#COMMANDS[*]}-1)))
    do
        local COMMAND=${COMMANDS[i]}
        local TITLE=${TITLES[i]}

        if [ "$TITLE" = "" ]
        then
            TITLE="untitled"
        fi

        trace xterm -title "$TITLE" -e "$COMMAND" &
    done
}

launch_mrxvt()
{
    x=1
    for i in $(seq 0 $((${#COMMANDS[*]}-1)))
    do
        if [ "$IP" = "" ]
        then
            IP="$x"
        else
            IP="$IP,$x"
        fi

        x=$(( $x + 1 ))
    done

    if [ "$OPT_NAME" != "" ]
    then
        echo "mrxvt -title \"$OPT_NAME\" -ip $IP \\" > $XTAB_ARG_FILE
    else
        echo "mrxvt -ip $IP \\" > $XTAB_ARG_FILE
    fi

    x=1
    for i in $(seq 0 $((${#COMMANDS[*]}-1)))
    do
        local COMMAND=${COMMANDS[i]}
        local TITLE=${TITLES[i]}

        if [ "$TITLE" = "" ]
        then
            TITLE="untitled"
        fi

        cat <<%% >>$XTAB_ARG_FILE
-profile${x}.tabTitle $TITLE -profile${x}.command "$COMMAND" \\
%%
        x=$(( $x + 1 ))
    done

    chmod +x $XTAB_ARG_FILE
    cat $XTAB_ARG_FILE
    $XTAB_ARG_FILE &
}

launch_konsole()
{
    for i in $(seq 0 $((${#COMMANDS[*]}-1)))
    do
        local COMMAND=${COMMANDS[i]}
        local TITLE=${TITLES[i]}

        if [ "$TITLE" = "" ]
        then
            TITLE="untitled"
        fi

        cat <<%% >>$XTAB_ARG_FILE
title: $TITLE;; command: $COMMAND
%%
    done

    if [ "$OPT_NAME" != "" ]
    then
        trace konsole --title "$OPT_NAME" --tabs-from-file $XTAB_ARG_FILE &
    else
        trace konsole --tabs-from-file $XTAB_ARG_FILE &
    fi
    cat $XTAB_ARG_FILE
}

launch_gnome_terminal()
{
    if [ "$OPT_NAME" != "" ]
    then
        echo "gnome-terminal --title \"$OPT_NAME\" $ARGS \\" >$XTAB_ARG_FILE
    else
        echo "gnome-terminal $ARGS \\" >$XTAB_ARG_FILE
    fi

    ARGS=""

    for i in $(seq 0 $((${#COMMANDS[*]}-1)))
    do
        local COMMAND=${COMMANDS[i]}
        local TITLE=${TITLES[i]}

        if [ "$TITLE" = "" ]
        then
            TITLE="untitled"
        fi

        cat <<%% >>$XTAB_ARG_FILE
--tab -t "$TITLE" -e "$COMMAND" \\
%%
    done

    chmod +x $XTAB_ARG_FILE
    cat $XTAB_ARG_FILE
    $XTAB_ARG_FILE &
}

get_default()
{
    if [ "$OPT_UI_SET" = "0" ]
    then
        which gnome-terminal &>/dev/null
        if [ $? -eq 0 ]
        then
            OPT_UI_GNOME=1
            OPT_UI_SET=1
        fi
    fi

    if [ "$OPT_UI_SET" = "0" ]
    then
        which konsole &>/dev/null
        if [ $? -eq 0 ]
        then
            OPT_UI_KONSOLE=1
            OPT_UI_SET=1
        fi
    fi

    if [ "$OPT_UI_SET" = "0" ]
    then
        which mrxvt &>/dev/null
        if [ $? -eq 0 ]
        then
            OPT_UI_MRXVT=1
            OPT_UI_SET=1
        fi
    fi

    if [ "$OPT_UI_SET" = "0" ]
    then
        which xterm &>/dev/null
        if [ $? -eq 0 ]
        then
            OPT_UI_XTERM=1
            OPT_UI_SET=1
        fi
    fi
}

main()
{
    /bin/rm -f $XTAB_ARG_FILE

    get_default

    if [ "$OPT_UI_SCREEN" = "1" ]
    then
        launch_screen
    elif [ "$OPT_UI_XTERM" = "1" ]
    then
        launch_xterm
    elif [ "$OPT_UI_KONSOLE" = "1" ]
    then
        launch_konsole
    elif [ "$OPT_UI_MRXVT" = "1" ]
    then
        launch_mrxvt
    else
        launch_gnome_terminal
    fi

    #
    # konsole is slow. give time for consoles to spawn and read the tab file
    #
    sleep 5
}

main

exit 0
