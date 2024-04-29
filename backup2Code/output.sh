#!/usr/bin/bash

exit=0
skipRotatingDelete=0

function exit_ {
  clearColor
  exit $exit
}

function error {
  if [[ "$1" = "-n" ]] ; then
    echo -e -n "$2" 1>&2
  else
    echo -e "$1" 1>&2 
  fi
  exit=1
  progExit=1
}

function output {
  if [[ "$1" = "-n" ]] ; then
    echo -e -n "$2"
  else
    echo -e "$1"
  fi
}

function clearColor {
  echo -e -n "${resetEND}"
}
