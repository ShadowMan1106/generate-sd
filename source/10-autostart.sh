#!/bin/bash

##########################################################################
#
# This script starts a game automatically.
# The game to start is found in a USB key installed on the raspberry
# The directory structure of the key MUST be always the same :
#   /
#     roms
#       MACHINE_NAME
#         GAME (extension depends on the kind of machine)
#         Controller configuration file (.cfg)
#
# Requirements :
# - Linux OS
##########################################################################


# globals ################################################################

DEBUG=

root_usb_key="/Volumes/ROMS"
#root_usb_key = "/media/usb0/"
root_roms="roms"

# Name of the core that will be launched
core_name=

# name of the game
game_name=

# controller configuration
controller_config_ext="cfg"
controller_config_filename=

# Error Management #######################################################

function trace() {
  local tracemsg=$1

  if ! [[ -z $DEBUG ]]; then
    echo "[DEBUG] " $tracemsg
  fi
}

function exitonerror() {
  local errormsg=$1

  echo "[ERROR] " $errormsg
  exit 1
}

# Check functions ########################################################

function check_directories() {

  # Check if the USB Key is accessible
  trace "root_usb_key=${root_usb_key}"
  if [[ ! -d "${root_usb_key}" || -L "${root_usb_key}" ]]; then
    exitonerror "La clé USB n'a pas été trouvée"
  fi

  # Check if directory of roms exists
  local roms_directory="${root_usb_key}/${root_roms}"
  trace "roms_directory=${roms_directory}"
  if [[ ! -d "${roms_directory}" || -L "${roms_directory}" ]]; then
    exitonerror "Le répertoire 'roms' n'a pas été trouvé sur la clé"
  fi

  # check if roms directory contains at least on machine directory
  local nbOfDirectories=$(ls -d1 "${roms_directory}"/*/ | wc -l)
  trace "nbOfDirectories in roms=${nbOfDirectories}"
  if [ $nbOfDirectories -eq 0 ]; then
    exitonerror "Le répertoire 'roms' ne contient aucun répertoire de machine"
  fi
}

# Game Management #######################################################

function extract_machine_name() {
  local roms_directory="${root_usb_key}/${root_roms}"

  local machine_name=$(file ${roms_directory}/* | grep directory | cut -d':' -f1 | head -1)
  trace "Machine Name (first)= ${machine_name}"
  machine_name=$(basename ${machine_name})
  trace "Machine Name (first)= ${machine_name}"

  if [[ -z ${machine_name} ]]; then
    exitonerror "Le premier répertoire trouvé n'a pas de nom"
  fi

  core_name=${machine_name}
  trace "Machine name is ${core_name}"
}

function extract_game_name() {
  local game_directory="${root_usb_key}/${root_roms}/${core_name}"

  local files_in_directory=$(find ${game_directory}/* -type f)
  trace "List of files in ${game_directory}= ${files_in_directory}"
  local nb_files_in_directory=$(find ${game_directory}/* -type f | wc -l)
  trace "Nb of files in ${game_directory}= ${nb_files_in_directory}"

  if [[ -z ${files_in_directory} ]]; then
    exitonerror "Le répertoire de la machine ${game_directory} est vide"
  fi
  if [ $nb_files_in_directory -lt 2 ]; then
    exitonerror "Le répertoire de la machine ${game_directory} ne contient pas les bons fichiers : fichier du jeu (parfois 2) + la configuration des Controllers"
  fi

  find ${game_directory}/* -type f | while read file; do
    extension=${file##*.};
    trace "Extension found : ${extension}"

    case "$extension" in

      ${controller_config_ext})
        controller_config_filename=${file}
        trace "Controller configuration file found = ${controller_config_filename}"
      ;;
      *)
        game_name=${file}
        trace "Game file found = ${game_name}"
      ;;

    esac

  done
}

function summary() {

  echo "La machine à émuler = ${core_name}"
  echo "Le fichier de configuration des controlleurs = ${controller_config_filename}"
  echo "Le fichier de jeu = ${game_name}"
}

# Parameters Management #################################################

function get_options() {

  while getopts "dh" option ;
  do
    case "$option" in

      #Input Retropie Image
#      l)
#        ROOT_LOOP=$OPTARG
#        echo "Le mapper est $ROOT_LOOP"
#        set_mappers
#	      ;;

      #Source Directory
#      s)
#        source_directory=$OPTARG
#        echo "Le répertoire des sources est $source_directory"
#        set_directories
#	      ;;

      #Missing Arguments
      :)
        exitonerror "L'option \"$OPTARG\" requiert une argument"
        ;;

#      n)
#        echo "No splashscreen"
#        no_splash_screen="ON"
#        ;;

      d)
        DEBUG="ON"
        trace "Debug mode = ON"
        ;;

      #Invalid Option
      \?)
        exitonerror "L'option \"$OPTARG\" est invalide"
        ;;

      # Help
      h)
        usage
        # getting the help message from the comments in this source code
        sed '/^#H /!d; s/^#H //' "$0"
        ;;
    esac
  done

  shift $((OPTIND-1))

  # get arguments if any
}

function usage() {
  echo
  echo "USAGE: $(basename $0) -d"
  echo
  echo "Use '-h' to see all the options"
  echo
}

# Main starts here ######################################################

get_options "$@"

check_directories

extract_machine_name

extract_game_name

summary

exit 0