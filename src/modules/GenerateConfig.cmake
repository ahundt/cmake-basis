##############################################################################
# @file  GenerateConfig.cmake
# @brief Generates package configuration files.
#
# This CMake script configures the \<package\>Config.cmake et al. files,
# once for the build tree and once for the install tree. Variables with a
# _CONFIG suffix are replaced in the default template file by either the
# value for the build or the install tree, respectively.
#
# If present, this script includes the @c PROJECT_CONFIG_DIR/ConfigBuild.cmake
# and/or @c PROJECT_CONFIG_DIR/ConfigInstall.cmake file before configuring the
# Config.cmake.in template. If a file @c PROJECT_CONFIG_DIR/Config.cmake.in
# exists, it is used as template. Otherwise, the default template file is used.
#
# Similarly, if the file @c PROJECT_CONFIG_DIR/ConfigVersion.cmake.in exists,
# it is used as template for the \<package\>ConfigVersion.cmake file. The same
# applies to Use.cmake.in.
#
# The variable @c PACKAGE_NAME is set to the name of the project prefixed by the
# value of @c BASIS_CONFIG_PREFIX. Hence, it is the name used by other projects
# to find this software package.
#
# Copyright (c) 2011 University of Pennsylvania. All rights reserved.
# See https://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
#
# Contact: SBIA Group <sbia-software at uphs.upenn.edu>
#
# @ingroup CMakeTools
##############################################################################

# ============================================================================
# names of output files
# ============================================================================

# Attention: This has to be done before configuring any files such that these
#            variables can be used by the template files.

## @addtogroup CMakeUtilities
#  @{

## @brief Name of the CMake package configuration file.
set (CONFIG_FILE "${PACKAGE_NAME}Config.cmake")
## @brief Name of the CMake package version file.
set (VERSION_FILE "${PACKAGE_NAME}ConfigVersion.cmake")
## @brief Name of the CMake package use file.
set (USE_FILE     "${PACKAGE_NAME}Use.cmake")
## @brief Name of the CMake target exports file.
set (EXPORTS_FILE "${PACKAGE_NAME}Exports.cmake")
## @brief Name of the CMake target exports file for custom targets.
set (CUSTOM_EXPORTS_FILE "${PACKAGE_NAME}CustomExports.cmake")

## @}

# ============================================================================
# export build targets
# ============================================================================

basis_export_targets (
  FILE        "${EXPORTS_FILE}"
  CUSTOM_FILE "${CUSTOM_EXPORTS_FILE}"
)

# ============================================================================
# project configuration file
# ============================================================================

# ----------------------------------------------------------------------------
# choose template

if (EXISTS "${PROJECT_CONFIG_DIR}/Config.cmake.in")
  set (TEMPLATE "${PROJECT_CONFIG_DIR}/Config.cmake.in")
else ()
  set (TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/Config.cmake.in")
endif ()

# ----------------------------------------------------------------------------
# build tree related configuration

set (BUILD_CONFIG_SETTINGS 1)
include ("${CMAKE_CURRENT_LIST_DIR}/ConfigSettings.cmake")
include ("${PROJECT_CONFIG_DIR}/ConfigSettings.cmake" OPTIONAL)

if (INCLUDE_DIR_CONFIG)
  list (REMOVE_DUPLICATES INCLUDE_DIR_CONFIG)
endif ()

if (LIBRARY_CONFIG)
  list (REMOVE_DUPLICATES LIBRARY_CONFIG)
endif ()

# ----------------------------------------------------------------------------
# configure project configuration file for build tree

configure_file ("${TEMPLATE}" "${PROJECT_BINARY_DIR}/${CONFIG_FILE}" @ONLY)

# ----------------------------------------------------------------------------
# install tree related configuration

set (BUILD_CONFIG_SETTINGS 0)
include ("${CMAKE_CURRENT_LIST_DIR}/ConfigSettings.cmake")
include ("${PROJECT_CONFIG_DIR}/ConfigSettings.cmake" OPTIONAL)

if (INCLUDE_DIR_CONFIG)
  list (REMOVE_DUPLICATES INCLUDE_DIR_CONFIG)
endif ()

if (LIBRARY_CONFIG)
  list (REMOVE_DUPLICATES LIBRARY_CONFIG)
endif ()

# ----------------------------------------------------------------------------
# configure project configuration file for install tree

configure_file ("${TEMPLATE}" "${PROJECT_BINARY_DIR}/${CONFIG_FILE}.install" @ONLY)

# ----------------------------------------------------------------------------
# install project configuration file

install (
  FILES       "${PROJECT_BINARY_DIR}/${CONFIG_FILE}.install"
  DESTINATION "${INSTALL_CONFIG_DIR}"
  RENAME      "${CONFIG_FILE}"
)

# ============================================================================
# project version file
# ============================================================================

# ----------------------------------------------------------------------------
# choose template

if (EXISTS "${PROJECT_CONFIG_DIR}/ConfigVersion.cmake.in")
  set (TEMPLATE "${PROJECT_CONFIG_DIR}/ConfigVersion.cmake.in")
else ()
  set (TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/ConfigVersion.cmake.in")
endif ()

# ----------------------------------------------------------------------------
# configure project configuration version file

configure_file ("${TEMPLATE}" "${PROJECT_BINARY_DIR}/${VERSION_FILE}" @ONLY)

# ----------------------------------------------------------------------------
# install project configuration version file

install (
  FILES       "${PROJECT_BINARY_DIR}/${VERSION_FILE}"
  DESTINATION "${INSTALL_CONFIG_DIR}"
)

# ============================================================================
# project use file
# ============================================================================

# ----------------------------------------------------------------------------
# choose template

if (EXISTS "${PROJECT_CONFIG_DIR}/Use.cmake.in")
  set (TEMPLATE "${PROJECT_CONFIG_DIR}/Use.cmake.in")
else ()
  set (TEMPLATE "${CMAKE_CURRENT_LIST_DIR}/Use.cmake.in")
endif ()

# ----------------------------------------------------------------------------
# configure project use file

configure_file ("${TEMPLATE}" "${PROJECT_BINARY_DIR}/${USE_FILE}" @ONLY)

# ----------------------------------------------------------------------------
# install project use file

install (
  FILES       "${PROJECT_BINARY_DIR}/${USE_FILE}"
  DESTINATION "${INSTALL_CONFIG_DIR}"
)
