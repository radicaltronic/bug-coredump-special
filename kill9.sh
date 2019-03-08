#!/bin/bash

#------------------------------------------------------------------------------------
# @author 		Guillaume Plante <radicaltronic@gmail.com>
# @description	Script to kill the test app
# @copyright    2018 GNU GENERAL PUBLIC LICENSE v3
#------------------------------------------------------------------------------------


kill -9 `pidof bug-coredump-special`
