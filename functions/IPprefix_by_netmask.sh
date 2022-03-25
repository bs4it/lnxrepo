#!/bin/bash
# 2022 - Fernando Della Torre @ BS4IT
IPprefix_by_netmask () { 
   c=0 x=0$( printf '%o' ${1//./ } )
   while [ $x -gt 0 ]; do
       let c+=$((x%2)) 'x>>=1'
   done
   echo $c ; }
