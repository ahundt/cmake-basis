##############################################################################
# @file  FindMATLAB.cmake
# @brief Find MATLAB installation.
#
# @par Input variables:
# <table border="0">
#   <tr>
#     @tp @b MATLAB_DIR @endtp
#     <td>The installation directory of MATLAB.
#         Can also be set as environment variable.</td>
#   </tr>
#   <tr>
#     @tp @b MATLABDIR @endtp
#     <td>Alternative environment variable for @p MATLAB_DIR.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_PATH_SUFFIXES @endtp
#     <td>Path suffixes which are used to find the proper MATLAB libraries.
#         By default, this find module tries to determine the path suffix
#         from the CMake variables which describe the system. For example,
#         on 64-bit Unix-based systems, the libraries are searched in
#         @p MATLAB_DIR/bin/glna64. Set this variable before the
#         find_package() command if this find module fails to
#         determine the correct location of the MATLAB libraries within
#         the root directory.</td>
#   </tr>
# </table>
#
# @par Output variables:
# <table border="0">
#   <tr>
#     @tp @b MATLAB_FOUND @endtp
#     <td>Whether the package was found and the following CMake
#         variables are valid.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_EXECUTABLE @endtp
#     <td>The absolute path of the found matlab executable.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_MCC_EXECUTABLE @endtp
#     <td>The absolute path of the found MATLAB Compiler (mcc) executable.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_MEX_EXECUTABLE @endtp
#     <td>The absolute path of the found MEX script (mex) executable.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_MEXEXT_EXECUTABLE @endtp
#     <td>The absolute path of the found mexext script executable.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_INCLUDE_DIR @endtp
#     <td>Package include directories.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_INCLUDES @endtp
#     <td>Include directories including prerequisite libraries.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_mex_LIBRARY @endtp
#     <td>The MEX library of MATLAB.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_mx_LIBRARY @endtp
#     <td>The @c mx library of MATLAB.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_eng_LIBRARY @endtp
#     <td>The MATLAB engine library.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_LIBRARY @endtp
#     <td>All MATLAB libraries.</td>
#   </tr>
#   <tr>
#     @tp @b MATLAB_LIBRARIES @endtp
#     <td>Package libraries and prerequisite libraries.</td>
#   </tr>
# </table>
#
# Copyright (c) 2011, 2012 University of Pennsylvania. All rights reserved.<br />
# See http://www.rad.upenn.edu/sbia/software/license.html or COPYING file.
#
# Contact: SBIA Group <sbia-software at uphs.upenn.edu>
#
# @ingroup CMakeFindModules
##############################################################################

# ----------------------------------------------------------------------------
# initialize search
if (NOT MATLAB_DIR)
  if (NOT $ENV{MATLABDIR} STREQUAL "")
    set (MATLAB_DIR "$ENV{MATLABDIR}"  CACHE PATH "Installation prefix for MATLAB." FORCE)
  else ()
    set (MATLAB_DIR "$ENV{MATLAB_DIR}" CACHE PATH "Installation prefix for MATLAB." FORCE)
  endif ()
endif ()

if (NOT MATLAB_PATH_SUFFIXES)
  if (WIN32)
    if (CMAKE_GENERATOR MATCHES "Visual Studio 6")
      set (MATLAB_PATH_SUFFIXES "extern/lib/win32/microsoft/msvc60")
    elseif (CMAKE_GENERATOR MATCHES "Visual Studio 7")
      # assume people are generally using 7.1,
      # if using 7.0 need to link to: extern/lib/win32/microsoft/msvc70
      set (MATLAB_PATH_SUFFIXES "extern/lib/win32/microsoft/msvc71")
    elseif (CMAKE_GENERATOR MATCHES "Visual Studio 8")
      set (MATLAB_PATH_SUFFIXES "extern/lib/win32/microsoft/msvc80")
    elseif (CMAKE_GENERATOR MATCHES "Visual Studio 9")
      set (MATLAB_PATH_SUFFIXES "extern/lib/win32/microsoft/msvc90")
    elseif (CMAKE_GENERATOR MATCHES "Borland")
      # assume people are generally using 5.4
      # if using 5.0 need to link to: ../extern/lib/win32/microsoft/bcc50
      # if using 5.1 need to link to: ../extern/lib/win32/microsoft/bcc51
      set (MATLAB_PATH_SUFFIXES "extern/lib/win32/microsoft/bcc54")
    endif ()
  else ()
    if (CMAKE_SIZE_OF_VOID_P EQUAL 4)
      set (MATLAB_PATH_SUFFIXES "bin/glnx86")
    else ()
      set (MATLAB_PATH_SUFFIXES "bin/glnxa64")
    endif ()
  endif ()
endif ()

set (MATLAB_LIBRARY_NAMES "mex" "mx" "eng")

# ----------------------------------------------------------------------------
# find MATLAB executables
if (MATLAB_DIR)
  find_program (
    MATLAB_EXECUTABLE
      NAMES         matlab
      HINTS         "${MATLAB_DIR}"
      PATH_SUFFIXES "bin"
      DOC           "The MATLAB application (matlab)."
  )

  find_program (
    MATLAB_MCC_EXECUTABLE
      NAMES         mcc
      HINTS         "${MATLAB_DIR}"
      PATH_SUFFIXES "bin"
      DOC           "The MATLAB Compiler (mcc)."
  )

  find_program (
    MATLAB_MEX_EXECUTABLE
      NAMES         mex
      HINTS         "${MATLAB_DIR}"
      PATH_SUFFIXES "bin"
      DOC           "The MEX-file generator of MATLAB (mex)."
  )

  find_program (
    MATLAB_MEXEXT_EXECUTABLE
      NAMES         mexext
      HINTS         "${MATLAB_DIR}"
      PATH_SUFFIXES "bin"
      DOC           "The MEXEXT script of MATLAB (mexext)."
  )
else ()
  find_program (
    MATLAB_EXECUTABLE
      NAMES matlab
      DOC "The MATLAB application (matlab)."
  )

  find_program (
    MATLAB_MCC_EXECUTABLE
      NAMES mcc
      DOC "The MATLAB Compiler (mcc)."
  )

  find_program (
    MATLAB_MEX_EXECUTABLE
      NAMES mex
      DOC "The MEX-file generator of MATLAB (mex)."
  )

  find_program (
    MATLAB_MEXEXT_EXECUTABLE
      NAMES mexext
      DOC "The MEXEXT script of MATLAB (mexext)."
  )
endif ()

mark_as_advanced (MATLAB_EXECUTABLE)
mark_as_advanced (MATLAB_MCC_EXECUTABLE)
mark_as_advanced (MATLAB_MEX_EXECUTABLE)
mark_as_advanced (MATLAB_MEXEXT_EXECUTABLE)

# ----------------------------------------------------------------------------
# find paths/files
if (MATLAB_DIR)

  find_path (
    MATLAB_INCLUDE_DIR
      NAMES         mex.h
      HINTS         "${MATLAB_DIR}"
      PATH_SUFFIXES "extern/include"
      DOC           "Include directory for MATLAB libraries."
      NO_DEFAULT_PATH
  )

  foreach (LIB ${MATLAB_LIBRARY_NAMES})
    find_library (
      MATLAB_${LIB}_LIBRARY
        NAMES         ${LIB} lib${LIB}
        HINTS         "${MATLAB_DIR}"
        PATH_SUFFIXES ${MATLAB_PATH_SUFFIXES}
        DOC           "MATLAB ${LIB} link library."
        NO_DEFAULT_PATH
    )
  endforeach ()

else ()

  find_path (
    MATLAB_INCLUDE_DIR
      NAMES mex.h
      HINTS ENV C_INCLUDE_PATH ENV CXX_INCLUDE_PATH
      DOC   "Include directory for MATLAB libraries."
  )

  foreach (LIB ${MATLAB_LIBRARY_NAMES})
    find_library (
      MATLAB_${LIB}_LIBRARY
        NAMES         ${LIB}
        HINTS ENV LD_LIBRARY_PATH
        DOC           "MATLAB ${LIB} link library."
    )
  endforeach ()

endif ()

mark_as_advanced (MATLAB_INCLUDE_DIR)
foreach (LIB ${MATLAB_LIBRARY_NAMES})
  mark_as_advanced (MATLAB_${LIB}_LIBRARY)
endforeach ()

set (MATLAB_LIBRARY)
foreach (LIB ${MATLAB_LIBRARY_NAMES})
  if (MATLAB_${LIB}_LIBRARY)
    list (APPEND MATLAB_LIBRARY "${MATLAB_${LIB}_LIBRARY}")
  endif ()
endforeach ()

# ----------------------------------------------------------------------------
# prerequisite libraries
set (MATLAB_INCLUDES  "${MATLAB_INCLUDE_DIR}")
set (MATLAB_LIBRARIES "${MATLAB_LIBRARY}")

# ----------------------------------------------------------------------------
# aliases / backwards compatibility
set (MATLAB_INCLUDE_DIRS "${MATLAB_INCLUDES}")

# ----------------------------------------------------------------------------
# handle the QUIETLY and REQUIRED arguments and set *_FOUND to TRUE
# if all listed variables are found or TRUE
include (FindPackageHandleStandardArgs)

set (MATLAB_LIBRARY_VARS)
foreach (LIB ${MATLAB_LIBRARY_NAMES})
  list (APPEND MATLAB_LIBRARY_VARS "MATLAB_${LIB}_LIBRARY")
endforeach ()

find_package_handle_standard_args (
  MATLAB
# MESSAGE
    DEFAULT_MSG
# VARIABLES
    MATLAB_EXECUTABLE
    MATLAB_INCLUDE_DIR
    ${MATLAB_LIBRARY_VARS}
)

# ----------------------------------------------------------------------------
# set MATLAB_DIR
if (NOT MATLAB_DIR AND MATLAB_FOUND)
  string (REGEX REPLACE "extern/include/?" "" MATLAB_PREFIX "${MATLAB_INCLUDE_DIR}")
  set (MATLAB_DIR "${MATLAB_PREFIX}" CACHE PATH "Installation prefix for MATLAB." FORCE)
  unset (MATLAB_PREFIX)
endif ()
