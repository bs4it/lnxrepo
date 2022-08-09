#!/bin/bash

# install the smartctl package first! (apt-get install smartctl)

if sudo true
then
   true
else
   echo 'Root privileges required'

   exit 1
fi

for drive in /dev/sd[a-z] /dev/sd[a-z][a-z]
do
   if [[ ! -e $drive ]]; then continue ; fi

   echo -n "$drive "

   smart=$(
      sudo smartctl -H $drive 2>/dev/null |

      grep '^SMART overall' |

      awk '{ print $6 }'
   )

   [[ "$smart" == "" ]] && smart='unavailable'

   echo "$smart"

done
