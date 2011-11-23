##############################################################################
# @file  CMakeLists.txt
# @brief Common build configuration file to add uninstaller.
#
# CMake does not support the creation of an uninstaller. Therefore, we add
# code to the cmake_install.cmake file which writes the content of the
# install_manifest.txt file to a file in the installation tree. As this
# code has to be executed after all files were executed and CMake includes
# the cmake_install.cmake files of subdirectories at last, this CMakeLists.txt
# is placed into a shared directory of the BASIS installation which is added
# to every BASIS project using add_subdirctory() at the very end of the root
# CMakeLists.txt file.
#
# Copyright (c) 2011 University of Pennsylvania. All rights reserved.
# See https://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
#
# Contact: SBIA Group <sbia-software at uphs.upenn.edu>
##############################################################################

# install CMake-based uninstall script
install (
  FILES       "${PROJECT_BINARY_DIR}/cmake_uninstall.cmake"
  DESTINATION "${INSTALL_CONFIG_DIR}"
  RENAME      "${PROJECT_NAME}Uninstall.cmake"
)

# write executable uninstaller
if (INSTALL_SINFIX)
  set (UNINSTALLER_NAME "uninstall")
else ()
  set (UNINSTALLER_NAME "uninstall_${PROJECT_NAME}")
endif ()
if (WIN32)
  set (UNINSTALLER_NAME "${UNINSTALLER_NAME}.bat")
endif ()

install (
  CODE
    "
    set (UNINSTALLER \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${INSTALL_RUNTIME_DIR}/${UNINSTALLER_NAME}\")
    message (\"-- Installing: \${UNINSTALLER}\")
    file (WRITE \"\${UNINSTALLER}\" \"\")
    if (UNIX)
      file (APPEND \"\${UNINSTALLER}\" \"#! /bin/sh\n\")
    endif ()
    file (APPEND \"\${UNINSTALLER}\" \"\\\"${CMAKE_COMMAND}\\\" -P \\\"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${INSTALL_CONFIG_DIR}/${PROJECT_NAME}Uninstall.cmake\\\"\")
    if (UNIX)
      execute_process (COMMAND /bin/chmod +x \"\\\"\${UNINSTALLER}\\\"\")
    endif ()
    list (APPEND CMAKE_INSTALL_MANIFEST_FILES \"\${UNINSTALLER}\")
    "
)

if (INSTALL_SINFIX AND INSTALL_LINKS)
  basis_install_link (
    "${INSTALL_RUNTIME_DIR}/${UNINSTALLER_NAME}"
    "bin/uninstall_${PROJECT_NAME_LOWER}"
  )
endif ()

# write install manifest at the very end of the installation
install (
  CODE
    "
    set (INSTALL_MANIFEST_FILE \"\$ENV{DESTDIR}\${CMAKE_INSTALL_PREFIX}/${INSTALL_CONFIG_DIR}/${PROJECT_NAME}InstallManifest.txt\")
    list (APPEND CMAKE_INSTALL_MANIFEST_FILES \"\${INSTALL_MANIFEST_FILE}\")
    message (\"-- Installing: \${INSTALL_MANIFEST_FILE}\")
    file (WRITE \"\${INSTALL_MANIFEST_FILE}\" \"\")
    foreach (F \${CMAKE_INSTALL_MANIFEST_FILES})
      file (APPEND \"\${INSTALL_MANIFEST_FILE}\" \"\${F}\n\")
    endforeach ()
    "
)