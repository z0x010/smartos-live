#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#

#
# Copyright (c) 2017, Joyent, Inc.
#

if [ "$PS1" ]; then
    mt_tty=$(/usr/bin/tty 2>/dev/null)
    if [[ $mt_tty =~ ^/dev/term/[abcd] ]]; then
        # If we're on the serial console, we generally won't know how
        # big our terminal is.  Attempt to ask it using control sequences
        # and resize our pty accordingly.
        mt_output=$(/usr/lib/measure_terminal 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            eval "$mt_output"
        else
            # We could not read the size, but we should set a 'sane'
            # default as the dimensions of the previous user's terminal
            # persist on the tty device.
            export LINES=25
            export COLUMNS=80
        fi
        /usr/bin/stty rows ${LINES} columns ${COLUMNS} 2>/dev/null
    fi
    unset mt_output mt_tty
    shopt -s checkwinsize

    ps1_info=
    if [[ -f /.dcinfo ]]; then
        . /.dcinfo
        DC_NAME="${SDC_DATACENTER_NAME}"
    fi
    if test -n "${DC_NAME}"; then
        ps1_info+="${DC_NAME}"
    fi
    ps1_headnode=$(source /lib/sdc/config.sh; load_sdc_config; echo $headnode)
    if test -n "$ps1_headnode"; then
        ps1_headnode_is_primary=$(source /lib/sdc/config.sh; load_sdc_config;
            echo $CONFIG_headnode_is_primary)
        test -n "$ps1_info" && ps1_info+=" "
        if test -z "${ps1_headnode_is_primary}"; then
            ps1_info+="hn"
        elif test "$ps1_headnode_is_primary" = "true"; then
            ps1_info+="primary-hn"
        else
            ps1_info+="secondary-hn"
        fi
    fi
    if test -n "${ps1_info}"; then
       PS1="[\u@\h (${ps1_info}) \w]\\$ "
    else
       PS1="[\u@\h \w]\\$ "
    fi
    unset ps1_info ps1_headnode_is_primary ps1_headnode

    alias ll='ls -lF'
    alias ls='ls --color=auto'
    [ -n "${SSH_CLIENT}" ] && export PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME} \007" && history -a'
fi

# Load bash completion
[ -f /etc/bash/bash_completion ] && . /etc/bash/bash_completion

svclog() {
  if [[ -z "$PAGER" ]]; then
    PAGER=less
  fi
  $PAGER `svcs -L $1`
}

svclogf() {
  /usr/bin/tail -f `svcs -L $1`
}
