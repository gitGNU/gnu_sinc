#!/usr/bin/env bash

#
# sinc.sh
#
# Copyright (C) 2016 frnmst (Franco Masotti) <franco.masotti@student.unife.it>
#
# This file is part of SINC.
#
# SINC is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SINC is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SINC.  If not, see <http://www.gnu.org/licenses/>.
#

. ./src/Method.sh

Environment()
{
    set_()
    {
        saved_environment="$(set +o)"
        set -m
        set -o posix
        # FIXME: Add PATH env variable check.

        # Add the possibility to set new aliases.
        shopt -s expand_aliases
    }

    clean()
    {
        shopt -u expand_aliases extglob
        $saved_environment
    }

    # These variables must be in the same order than in the form.
    # void set_global_variables( void )
    set_global_variables()
    {
        project_homepage="savannah.nongnu.org/idontknowyet"
        project_wiki="savannah.nongnu.org/idontknowyet"
        author="frnmst (Franco Masotti)"
        author_email="franco.masotti@student.unife.it"
        copyright_year="2016"
        program_version="0.0"
        configuration_file=""$HOME"/.config/sinc/sinc.config"
        path_to_manual="man/sinc.man"

        # Arrays are not portable but simple.
        #
        # Protocol: <variable name>_<variable type>
        # where variable type is a single uppercase letter like the following:
        #
        # Variable types:
        # S = string
        # N = non-spaced string
        # U = unsigned integer
        # ...
        program_variables=( \
                            address_N \
                            port_U \
                            username_N \
                            remote_directory_S \
                            sshfs_options_S \
                            ssh_options_S \
                            ssh_keygen_options_S \
                            local_directory_S \
                            mount_options_S \
                            git_options_S \
                            inotify_options_S \
                            notification_time_U \
                            icons_directory_S \
                          )
    }

    # It would be nice to set aliases for ssh so its optons can be set one and for
    # all. Obviously this means that a specific function must be called after
    # having read the configuration file.
    # void set_aliases( void )
    set_aliases()
    {
        alias dialog='dialog --stdout --backtitle "$project_homepage" \
--title "SINC SETUP"'
        alias getopt='getopt --name sinc --shell bash'
    }

    Method "$@"
}

# Non-blocking mkfifo to share info between f.e. git and this instance.
CurrentStatus() { printf "Current status\n"; }

Debug()
{
    local retval=""

    set -x
    start
    retval=$?
    set +x
    return $retval
}

# void help( void )
Help()
{ (
    print()
    {
        cat <<- EOF
Usage: sinc [ OPTIONS ]
SINC, Sinc Is Not Cloud: fully free, secure, simple and lightweight
syncronization which imitates Dropbox's approach.

Multiple options are permitted.
  -c, --current-status          print the current status
  -d, --debug                   start and print all executed commands on screen
  -h, --help                    display this help and exit
  -i, --initialize              start a new setup
  -p, --print-configuration     display configuration file content and exit
  -q, --quit                    quit the program
  -s, --start                   start SINC normally
  -v, --version                 output version information and exitn\

If no option is given, SINC starts normally.
Configuration file is found in ~/.config/sinc/sinc.config.

Exit status:
 0  if OK,
 1  if some error occurred.

Report bugs to: $author_email
SINC home page: <$project_homepage>
Full documentation at: <$project_wiki>
or available locally via: man $path_to_manual
EOF
    }

    default()
    {
        print
    }

    Method "$@"
) }

VariableParser()
{ (
    # Small variable parser.
    # The following is surely not portable but much more readable.
    # char get_variable_type( char *var )
    get_variable_type()
    {
        local var="$1"

        if [ -z "$var" ]; then printf "E"
        elif [[ $var = *[[:space:]]* ]]; then printf "S"
        elif [ -z "$(printf "$var" | tr -d 0-9)" ]; then printf "U"
        elif [[ $var = *[![:space:]]* ]]; then printf "N"
        fi
    }

    # The following is a small subset checker.
    # If the variable is valid it returns 0, otherwise 1.
    # bool check_variable_validity( char *variable_type, char *value_type )
    check_variable_validity()
    {
        local variable_type="$1"
        local value_type="$2"

        # Test print.
        printf "$variable_type $value_type\n"

        if [ "$value_type" = "E" ]; then return 1

        elif [ "$variable_type" = "S" ]; then
            if [ "$value_type" != "S" ] && [ "$value_type" != "N" ] \
&& [ "$value_type" != "U" ]; then
                return 1
            fi

        elif [ "$variable_type" = "N" ]; then
            if [ "$value_type" != "N" ] && [ "$value_type" != "U" ]; then
                return 1
            fi

        elif [ "$variable_type" = "U" ] && [ "$value_type" != "U" ]; then
            return 1

        fi

        return 0
    }

    # Return 0 if all variables are correct, 1 otherwise.
    # bool verify_variables( void )
    verify_variables()
    {
        local var
        local variable_type
        local val
        local value_type

        for var in ${program_variables[@]}; do
            variable_type="${var:(-1)}"
            val="${var:0:(-2)}"
            value_type="$(get_variable_type "${!val}")"
            check_variable_validity "$variable_type" "$value_type" || return 1
            # Test print.
            printf "%s\n" "${var} ${!val}"
        done

        return 0
    }

    default()
    {
        verify_variables
    }

    Method "$@"
) }

Configuration()
{
    print()
    {
        [ -r "$configuration_file" ] \
&& cat "$configuration_file" \
|| { printf "Cannot load the configuration file\n" 1>&2-; return 1; }
    }

    # Load variables from file and avoid injected malicious code.
    # void load_variables( char *path )
    load()
    {
        local path="$1"

        # Configuration file must belong to $UID and have 600 of permission.
        { [ -O "$path" ] && [ $(stat --format=%a "$path") -eq 600 ]; } || return 1
        while read -r line; do
            # Before eval, ignore any possible malicious line of code.
            eval "$line"
        done < "$path"
    }


    # int initialize ( void )
    Initialize()
    { (
        trap 'setup_error "Setup stopped"' SIGINT SIGTERM

        # char *get_setup_values( void )
        get_setup_values()
        {
            local x=110
            local y=30
            local key_chars=35
            local value_chars=80

            printf "%s" "$(dialog --mixedform "Edit the values \
(please read the documentation first)" $y $x 0 \
"SSH server address or hostname:" 1 1 -- "$server" 1 $key_chars \
$value_chars 0 0 \
"SSH server port:" 2 1 -- "$port" 2 $key_chars \
$value_chars 0 0 \
"SSH server username:" 3 1 -- "$username" 3 $key_chars \
$value_chars 0 0 \
"SSH server directory path:" 4 1 -- "$remote_directory" 4 $key_chars \
$value_chars 0 0 \
"SSHFS options:" 5 1 -- "$sshfs_options" 5 $key_chars \
$value_chars 0 0 \
"SSH options:" 6 1 -- "$ssh_options" 6 $key_chars \
$value_chars 0 0 \
"SSH Keygen options:" 7 1 -- "$ssh_keygen_options" 7 $key_chars \
$value_chars 0 0 \
"Local directory path:" 8 1 -- "$local_directory" 8 $key_chars \
$value_chars 0 0 \
"Local mount options:" 9 1 -- "$mount_options" 9 $key_chars \
$value_chars 0 0 \
"Git options:" 10 1 -- "$git_options" 10 $key_chars \
$value_chars 0 0 \
"Inotify options:" 11 1 -- "$inotify_options" 11 $key_chars \
$value_chars 0 0 \
"Event notification time:" 12 1 -- "$notification_time" 12 $key_chars \
$value_chars 0 0 \
"Icons directory:" 13 1 -- "$icons_directory" 13 $key_chars \
$value_chars 0 0)"
        }

        # Only to do in setup.
        # void assign_values_to_variables( char *values )
        assign_values_to_variables()
        {
            local i=0
            local values="$1"

            # These variables are assigned globally.
            # printf is used to treat each value literaly (no interpretation from the shell.
            while read -r line; do
                eval "${program_variables[$i]:0:(-2)}='$line'"
                i=$(($i+1))
            done <<< "$(printf "%s" "$values")"
        }

        make_repository()
        {
            printf "Making repository\n"
        }

        write_configuration_file()
        {
            printf "Writing configuration file\n"
        }

        setup_error()
        {
            local error="$1"

            printf "%s\n" "Setup error: $error"
        }

        default()
        {
            load "src/sinc.default.conf" || { setup_error "config_file"; return 1; }
            assign_values_to_variables "$(get_setup_values)"
            VariableParser default || { setup_error "verify_variables"; return 1; }
            make_repository || { setup_error "make_repository"; return 1; }
            write_configuration_file ||  { setup_error "write_configuration_file"; return 1; }
        }

        Method "$@"
    ) }

    default()
    {
        Initialize default "$@"
    }

    Method "$@"
}


Quit() { printf "Quit\n"; }

Start() { printf "Start\n"; }

# void version( void )
Version()
{ (
    print()
    {
       cat <<- EOF
SINC $program_version
Copyright (C) $copyright_year $author
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF
    }

    default()
    {
        print "$@"
    }

    Method "$@"
) }

# int main( char *program_path, char *argc )
Main()
{ (
    # void unrecognized_option( void )
    # To test that information is printed on stderr:
    # $ ./sinc -l 2>/dev/null
    # should show nothing.
    unrecognized_option()
    {
        printf "%s\n" "Try 'sinc --help' for more information"
    } 1>&2-

    parse_options()
    {
        local program_path="$1"
        local argc="$2"
        local options="cdhipqsv"
        local long_options="current-status,debug,help,initialize,\
print-configuration,quit,start,version"
        local opts
        local opt
        local ret

        [ -z "$argc" ] && argc="-s"

        opts="$(getopt --options $options --longoptions $long_options -- $argc)"

        [ $? -ne 0 ] && unrecognized_option && return 1

        eval set -- "$opts"

        for opt in $opts; do
            case "$opt" in
                -- )                            ;;
                -c | --current-status )         CurrentStatus; ret=$? ;;
                -d | --debug )                  Debug; ret=$? ;;
                -h | --help )                   Help; ret=$? ;;
                -i | --initialize )             Configuration Initialize; ret=$? ;;
                -p | --print-configuration )    Configuration print; ret=$? ;;
                -q | --quit )                   Quit; ret=$? ;;
                -s | --start )                  Start; ret=$? ;;
                -v | --version )                Version; ret=$? ;;
            esac
        done

        return $ret
    }

    default()
    {
        parse_options "$@"
    }

    Method "$@"
) }

# Program entry point.
Environment set_
Environment set_global_variables
Environment set_aliases
Main default "$0" "$*"
retval="$?"
Environment clean
exit "$retval"
