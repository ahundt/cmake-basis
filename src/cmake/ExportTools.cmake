##############################################################################
# @file  ExportTools.cmake
# @brief Functions and macros for the export of targets.
#
# Copyright (c) 2011, 2012 University of Pennsylvania. All rights reserved.<br />
# See http://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
#
# Contact: SBIA Group <sbia-software at uphs.upenn.edu>
#
# @ingroup CMakeTools
##############################################################################

if (__BASIS_EXPORTIMPORTTOOLS_INCLUDED)
  return ()
else ()
  set (__BASIS_EXPORTIMPORTTOOLS_INCLUDED TRUE)
endif ()


## @addtogroup CMakeUtilities
#  @{


# ----------------------------------------------------------------------------
## @brief Get soname of object file.
#
# This function extracts the soname from object files in the ELF format on
# systems where the objdump command is available. On all other systems,
# an empty string is returned.
#
# @param [out] SONAME  The soname of the object file.
# @param [in]  OBJFILE Object file in ELF format.
function (basis_get_soname SONAME OBJFILE)
  # get absolute path of object file
  basis_get_target_uid (TARGET_UID ${OBJFILE})
  if (TARGET TARGET_UID)
    basis_get_target_location (OBJFILE ${TARGET_UID} ABSOLUTE)
  else ()
    get_filename_component (OBJFILE "${OBJFILE}" ABSOLUTE)
  endif ()
  # usually CMake did this already
  find_program (CMAKE_OBJDUMP NAMES objdump DOC "The objdump command")
  # run objdump and extract soname
  execute_process (
    COMMAND ${CMAKE_OBJDUMP} -p "${OBJFILE}"
    COMMAND sed -n "-e's/^[[:space:]]*SONAME[[:space:]]*//p'"
    RESULT_VARIABLE STATUS
    OUTPUT_VARIABLE SONAME_OUT
    ERROR_QUIET
  )
  # return
  if (STATUS EQUAL 0)
    set (${SONAME} "${SONAME_OUT}" PARENT_SCOPE)
  else ()
    set (${SONAME} "" PARENT_SCOPE)
  endif ()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Generate header of exports file.
function (basis_export_header CODE)
  set (C "# Generated by BASIS\n\n")
  set (C "${C}if (\"\${CMAKE_MAJOR_VERSION}.\${CMAKE_MINOR_VERSION}\" LESS 2.8)\n")
  set (C "${C}  message (FATAL_ERROR \"CMake >= 2.8.4 required\")\n")
  set (C "${C}endif ()\n")
  set (C "${C}cmake_policy (PUSH)\n")
  set (C "${C}cmake_policy (VERSION 2.8.4)\n")
  set (C "${C}#----------------------------------------------------------------\n")
  set (C "${C}# Generated CMake target import file.\n")
  set (C "${C}#----------------------------------------------------------------\n")
  set (C "${C}\n# Commands may need to know the format version.\n")
  set (C "${C}set (CMAKE_IMPORT_FILE_VERSION 1)\n")
  set (${CODE} "${C}" PARENT_SCOPE)
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add code to compute prefix relative to @c INSTALL_CONFIG_DIR.
function (basis_export_prefix CODE)
  set (C "\n# Compute the installation prefix relative to this file.\n")
  set (C "${C}get_filename_component (_IMPORT_PREFIX \"\${CMAKE_CURRENT_LIST_FILE}\" PATH)\n")
  string (REGEX REPLACE "[/\\]" ";" DIRS "${INSTALL_CONFIG_DIR}")
  foreach (D IN LISTS DIRS)
    set (C "${C}get_filename_component (_IMPORT_PREFIX \"\${_IMPORT_PREFIX}\" PATH)\n")
  endforeach ()
  set (${CODE} "${${CODE}}${C}" PARENT_SCOPE)
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add code to add import targets.
function (basis_export_import_targets CODE)
  set (C)
  foreach (T IN LISTS ARGN)
    basis_get_fully_qualified_target_uid (UID "${T}")
    set (C "${C}\n# Create import target \"${UID}\"\n")
    get_target_property (BASIS_TYPE ${T} "BASIS_TYPE")
    if (BASIS_TYPE MATCHES "EXECUTABLE")
      set (C "${C}add_executable (${UID} IMPORTED)\n")
    elseif (BASIS_TYPE MATCHES "LIBRARY|MODULE_SCRIPT|MEX")
      string (REGEX REPLACE "_LIBRARY" "" TYPE "${BASIS_TYPE}")
      if (TYPE MATCHES "MEX|MCC")
        set (TYPE "SHARED")
      elseif (TYPE MATCHES "^MODULE_SCRIPT$")
        set (TYPE "UNKNOWN")
      endif ()
      set (C "${C}add_library (${UID} ${TYPE} IMPORTED)\n")
    else ()
      message (FATAL_ERROR "Cannot export target ${T} of type ${BASIS_TYPE}! Use NO_EXPORT option.")
    endif ()
    set (C "${C}set_target_properties (${UID} PROPERTIES BASIS_TYPE \"${BASIS_TYPE}\")\n")
  endforeach ()
  set (${CODE} "${${CODE}}${C}" PARENT_SCOPE)
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add code to set properties of imported targets for build tree.
function (basis_export_build_properties CODE)
  set (C)
  if (CMAKE_BUILD_TYPE)
    set (CONFIG "${CMAKE_BUILD_TYPE}")
  else ()
    set (CONFIG "noconfig")
  endif ()
  string (TOUPPER "${CONFIG}" CONFIG_UPPER)
  foreach (T IN LISTS ARGN)
    basis_get_fully_qualified_target_uid (UID "${T}")
    set (C "${C}\n# Import target \"${UID}\" for configuration \"${CONFIG}\"\n")
    set (C "${C}set_property (TARGET ${UID} APPEND PROPERTY IMPORTED_CONFIGURATIONS ${CONFIG})\n")
    set (C "${C}set_target_properties (${UID} PROPERTIES\n")
    basis_get_target_location (LOCATION ${T} ABSOLUTE)
    set (C "${C}  IMPORTED_LOCATION_${CONFIG_UPPER} \"${LOCATION}\"\n")
    if (BASIS_TYPE MATCHES "LIBRARY|MEX")
      set (C "${C}  IMPORTED_LINK_INTERFACE_LANGUAGES_${CONFIG_UPPER} \"CXX\"\n")
    endif ()
    set (C "${C}  )\n")
  endforeach ()
  set (${CODE} "${${CODE}}${C}" PARENT_SCOPE)
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add code to set properties of imported targets for installation.
function (basis_export_install_properties CODE)
  set (C)
  if (CMAKE_BUILD_TYPE)
    set (CONFIG "${CMAKE_BUILD_TYPE}")
  else ()
    set (CONFIG "noconfig")
  endif ()
  string (TOUPPER "${CONFIG}" CONFIG_UPPER)
  foreach (T IN LISTS ARGN)
    basis_get_fully_qualified_target_uid (UID "${T}")
    set (C "${C}\n# Import target \"${UID}\" for configuration \"${CONFIG}\"\n")
    set (C "${C}set_property (TARGET ${UID} APPEND PROPERTY IMPORTED_CONFIGURATIONS ${CONFIG})\n")
    set (C "${C}set_target_properties (${UID} PROPERTIES\n")
    basis_get_target_location (LOCATION ${T} POST_INSTALL_RELATIVE)
    set (C "${C}  IMPORTED_LOCATION_${CONFIG_UPPER} \"\${_IMPORT_PREFIX}/${LOCATION}\"\n")
    if (BASIS_TYPE MATCHES "LIBRARY|MEX")
      set (C "${C}  IMPORTED_LINK_INTERFACE_LANGUAGES_${CONFIG_UPPER} \"CXX\"\n")
    endif ()
    set (C "${C}  )\n")
  endforeach ()
  set (${CODE} "${${CODE}}${C}" PARENT_SCOPE)
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add footer of exports file.
function (basis_export_footer CODE)
  set (C "\n# Cleanup temporary variables.\n")
  set (C "${C}set (_IMPORT_PREFIX)\n")
  set (C "${C}\n# Commands beyond this point should not need to know the version.\n")
  set (C "${C}set (CMAKE_IMPORT_FILE_VERSION)\n")
  set (C "${C}cmake_policy (POP)\n")
  set (${CODE} "${${CODE}}${C}" PARENT_SCOPE)
endfunction ()

# ----------------------------------------------------------------------------
## @brief Export all targets added by basis_add_* commands.
function (basis_export_targets)
  # parse arguments
  CMAKE_PARSE_ARGUMENTS (ARGN "" "FILE;CUSTOM_FILE" "" ${ARGN})

  if (NOT ARGN_FILE)
    message (FATAL_ERROR "basis_export_targets(): FILE option is required!")
  endif ()
  if (NOT ARGN_CUSTOM_FILE)
    message (FATAL_ERROR "basis_export_targets(): CUSTOM_FILE option is required!")
  endif ()

  if (IS_ABSOLUTE ARGN_FILE)
    message (FATAL_ERROR "basis_export_targets(): FILE option argument must be a relative path!")
  endif ()
  if (IS_ABSOLUTE ARGN_CUSTOM_FILE)
    message (FATAL_ERROR "basis_export_targets(): CUSTOM_FILE option argument must be a relative path!")
  endif ()

  # --------------------------------------------------------------------------
  # export non-custom targets
  basis_get_project_property (EXPORT_TARGETS PROPERTY EXPORT_TARGETS)

  if (EXPORT_TARGETS)
    if (BASIS_USE_FULLY_QUALIFIED_UIDS)
      set (NAMESPACE_OPT)
    else ()
      set (NAMESPACE_OPT NAMESPACE "${BASIS_PROJECT_NAMESPACE_CMAKE}.")
    endif ()

    export (
      TARGETS   ${EXPORT_TARGETS}
      FILE      "${PROJECT_BINARY_DIR}/${ARGN_FILE}"
      ${NAMESPACE_OPT}
    )
    foreach (COMPONENT "${BASIS_RUNTIME_COMPONENT}" "${BASIS_LIBRARY_COMPONENT}")
      install (
        EXPORT      "${PROJECT_NAME}"
        DESTINATION "${INSTALL_CONFIG_DIR}"
        FILE        "${ARGN_FILE}"
        COMPONENT   "${COMPONENT}"
        ${NAMESPACE_OPT}
      )
    endforeach ()
  endif ()

  # --------------------------------------------------------------------------
  # export custom targets and/or test targets
  basis_get_project_property (CUSTOM_EXPORT_TARGETS)
  basis_get_project_property (TEST_EXPORT_TARGETS)

  if (CUSTOM_EXPORT_TARGETS OR TEST_EXPORT_TARGETS)

    # write exports for build tree
    basis_export_header (CONTENT)
    basis_export_import_targets (CONTENT ${CUSTOM_EXPORT_TARGETS} ${TEST_EXPORT_TARGETS})
    basis_export_build_properties (CONTENT ${CUSTOM_EXPORT_TARGETS}  ${TEST_EXPORT_TARGETS})
    basis_export_footer (CONTENT)

    file (WRITE "${PROJECT_BINARY_DIR}/${ARGN_CUSTOM_FILE}" "${CONTENT}")
    unset (CONTENT)

    # write exports for installation - excluding test targets
    if (CUSTOM_EXPORT_TARGETS)
      basis_export_header (CONTENT)
      basis_export_prefix (CONTENT)
      basis_export_import_targets (CONTENT ${CUSTOM_EXPORT_TARGETS})
      basis_export_install_properties (CONTENT ${CUSTOM_EXPORT_TARGETS})
      basis_export_footer (CONTENT)

      # DO NOT use '-' in the filename prefix for the custom exports.
      # Otherwise, it is automatically included by the exports file written
      # by CMake for the installation tree. This is, however, not the case
      # for the build tree. Therefore, we have to include the custom exports
      # file our selves in the use file.
      get_filename_component (TMP_FILE "${ARGN_CUSTOM_FILE}" NAME_WE)

      set (TMP_FILE "${TMP_FILE}.install")
      file (WRITE "${PROJECT_BINARY_DIR}/${TMP_FILE}" "${CONTENT}")
      unset (CONTENT)

      install (
        FILES       "${PROJECT_BINARY_DIR}/${TMP_FILE}"
        DESTINATION "${INSTALL_CONFIG_DIR}"
        RENAME      "${ARGN_CUSTOM_FILE}"
      )
    endif ()

  endif ()
endfunction ()


## @}
# end of Doxygen group
