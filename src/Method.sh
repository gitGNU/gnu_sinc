#
# Method.sh
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

# Static group with only one method. Same runlevel as the caller.
Method()
{
    eval $(
        local methodToCall="$1"

        # If there is at least one input argument, we can through away the
        # first one safely, otherwise we would have nothing to throw, causing
        # error on dash.
        [ "$#" -ge 1 ] && shift 1

        if [ -n "$methodToCall" ]; then
            printf "%s" "$methodToCall "
        else
            printf "%s" "default "
        fi

        # Add automatic quoting to each paramteter. This avoids thinking about
        # quoting when scripting using this group. We can't use a temporary
        # variable for "$@", otherwise we would lose the paramtere's structure.
        for i in "$@"; do
            printf "%s " "\"$i\""
        done
    )
}

