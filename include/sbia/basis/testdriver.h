/**
 * @file  testdriver.h
 * @brief Default test driver include file.
 *
 * This file is specified as INCLUDE argument to the create_test_sourcelist()
 * command of CMake which generates the code of the test driver. Such test
 * driver is used, in particular, to run a test which generates an output image.
 * The resulting image can then be compared by the test driver to one or more
 * baseline images. Note the difference to plain non-image processing based
 * unit tests. These shall make use of the unit testing frameworks included
 * with BASIS instead (see test.h for a C++ unit testing framework).
 *
 * This file in particular declares the functions which are used to parse
 * the command-line arguments of the test driver and those which are used by
 * the code fragments defined in the files testdriver-before-test.inc and
 * testdriver-after-test.inc.
 *
 * Currently available test driver implementations included by this file are:
 * - testdriver.hxx
 * - testdriver-itk.hxx
 *
 * This file is in parts a modified version of the itkTestDriverInclude.h
 * file which is part of the TestKernel module of the ITK 4 project.
 *
 * Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen<br />
 * Copyright Insight Software Consortium.<br />
 * Copyright (c) 2011, University of Pennsylvania.
 *
 * Portions of this file are subject to the VTK Toolkit Version 3 copyright.
 *
 * For complete copyright, license and disclaimer of warranty information
 * please refer to the COPYRIGHT file.
 *
 * Contact: SBIA Group <sbia-software at uphs.upenn.edu>
 */

 /*=========================================================================
 *
 *  Copyright Insight Software Consortium
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0.txt
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 *=========================================================================*/
/*=========================================================================
 *
 *  Portions of this file are subject to the VTK Toolkit Version 3 copyright.
 *
 *  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
 *
 *  For complete copyright, license and disclaimer of warranty information
 *  please refer to the NOTICE file at the top of the ITK source tree.
 *
 *=========================================================================*/

#pragma once
#ifndef _SBIA_BASIS_TESTDRIVER_H
#define _SBIA_BASIS_TESTDRIVER_H


#include <string>
#include <map>
#include <vector>
#include <iostream>
#include <fstream>
#include <cstdio> // remove() - removes a file
#include <limits> // used in basistest-after-test.inc

#include <sbia/basis/config.h>
#include <sbia/basis/except.h>
#include <sbia/basis/assert.h>
#include <sbia/basis/path.h>    // get_file_name() - basistest-after-test.inc
#include <sbia/basis/CmdLine.h> // parsing of command-line arguments


// acceptable in test driver includes
using namespace std;
using namespace sbia::basis;

 
// ===========================================================================
// arguments
// ===========================================================================

/// @brief Maximum dimension of images used for testing.
const unsigned int BASIS_MAX_TEST_IMAGE_DIMENSION = 6;

// ---------------------------------------------------------------------------
// environment
MultiStringArg add_before_libpath(
        "", "add-before-libpath",
        "Add a path to the library path environment. This option takes"
        " care of choosing the right environment variable for your system.",
        false, "<dir>");

MultiStringArg add_before_env(
        "", "add-before-env",
        "Add an environment variable named <name> with the given value."
        " The seperator used is the default one on the system.",
        false, "<name> <value>", 2);

MultiStringArg add_before_env_with_sep(
        "", "add-before-env-with-sep",
        "Add an environment variable named <name> with the given value.",
        false, "<name> <value> <sep>", 3);

// ---------------------------------------------------------------------------
// regression testing

/// @brief Structure holding arguments to --compare option and currently
///        set tolerances to be used for the regression test.
struct RegressionTest {
    string       test_image_file;
    string       baseline_image_file;
    float        intensity_tolerance;
    unsigned int max_number_of_differences;
    unsigned int tolerance_radius;
};

/// @brief Container storing added regression tests, one for each occurrence
///        of the --compare option.
vector<RegressionTest> regression_tests;

/// @brief Visitor used to handle --compare option.
class CompareVisitor : public TCLAP::Visitor
{
public:
    CompareVisitor() {}
    ~CompareVisitor() {}
    void visit();
};

CompareVisitor compare_visitor;

MultiStringArg compare(
        "", "compare",
        "Compare the <test> image to the <baseline> image using the"
        " current tolerances. If the test image should be compared to"
        " to more than one baseline image, specify the file name of"
        " the main baseline image and name the other baseline images"
        " similarly with only a numerical suffix appended to the"
        " basename of the image file path using a dot (.) as separator."
        " For example, name your baseline images baseline.nii,"
        " baseline.1.nii, baseline.2.nii,..., and specify baseline.nii"
        " second argument value.",
        false, "<test> <baseline>", 2, false, &compare_visitor);

DoubleArg intensity_tolerance(
        "", "intensity-tolerance",
        "The accepted maximum difference between image intensities"
        " to use for the following regression tests."
        // default should be printed automatically
        " (default: 2.0)",
        false, 2.0, "<float>", true);

UIntArg max_number_of_differences(
        "", "max-number-of-differences",
        "When comparing images specified with the following --compare option(s),"
        " allow the given number of image elements to differ.",
        false, 0, "<n>", true);

UIntArg tolerance_radius(
        "", "tolerance-radius",
        "At most one image element in the neighborhood specified by the"
        " given radius has to fulfill the criteria of the following"
        " regression tests",
        false, 0, "<int>", true);

// ---------------------------------------------------------------------------
// test execution
StringArg redirect_output(
        "", "redirect-output",
        "Redirects the test output to the specified file.",
        false, "", "<file>");

UIntArg max_number_of_threads(
        "", "max-number-of-threads",
        "Use at most <n> threads. Set explicitly to n=1 to disable"
        " multi-threading. Note that the test itself still may use"
        " more threads, but the regression tests will not.",
        false, 0, "<n>");

SwitchArg full_output(
        "", "full-output",
        "Causes the full output of the test to be passed to CDash.",
        false);

MultiSwitchArg verbose(
        "v", "verbose",
        "Increase verbosity of output messages.",
        false);

// ---------------------------------------------------------------------------
// test / test command
#ifdef BASIS_STANDALONE_TESTDRIVER

PositionalArgs testcmd(
        "testcmd",
        "The external test command and its command-line arguments."
        " This command is executed by the test driver after altering the"
        " environment as subprocess. After the subprocess finished, the"
        " requested regression tests are performed by the test driver."
        " Note that if the -- option is not given before the test command,"
        " labeled arguments following the test command will be considered"
        " to be options of the test driver if known by the test driver.",
        true, "[--] <test command> <arg>...");

SwitchArg noprocess(
        "", "noprocess",
        "Do not run any test subprocess but only perform the regression tests.",
        true);

#else // defined(BASIS_STANDALONE_TESTDRIVER)

PositionalArgs testcmd(
        "testcmd",
        "The name of the test to run and optional arguments."
        " Displays a list of available tests if this argument is omitted"
        " and waits for the user to input the number of the test to run."
        " Exist with error if an invalid test was specified."
        " Note that if the -- option is not given before the test name,"
        " labeled arguments following the test name will be considered"
        " to be options of the test driver if known by the test driver."
        " Otherwise, if the option is unknown to the test driver or the"
        " -- option has been given before the test name, the remaining"
        " arguments are passed on to the test.",
        false, "", "[--] [<test name> [<arg>...]]");

#endif // defined(BASIS_STANDALONE_TESTDRIVER)

// ===========================================================================
// initialization
// ===========================================================================

/**
 * @brief Parse command-line arguments and initialize test driver.
 *
 *
 * @param [in] argc Number of arguments.
 * @param [in] argv Command-line arguments.
 */
void testdriversetup(int* argc, char** argv[]);

// ===========================================================================
// image regression testing
// ===========================================================================

/**
 * @brief Generate list of names of baseline files from a given template filename.
 *
 * The list of baseline file names is generated from the template filename using
 * the following algorithm:
 * -# Strip the file name suffix.
 * -# Append a suffix containing of a dot (.) and a digit, i.e., .x
 * -# Append the original file name suffix.
 * It the file exists, increment x and continue.
 *
 * Additionally, if a file @p filename_template exists, it is the first
 * element in the resulting list.
 *
 * @param [in] filename_template File path template.
 *
 * @return List of baseline filenames or empty list if no such files exist.
 */
vector<string> get_baseline_filenames(string filename_template);

/**
 * @brief Compare output image to baseline image.
 *
 * This function compares a given image to a baseline image and returns a
 * regression test result depending on how well the output image matches the
 * baseline image given the provided tolerance arguments.
 *
 * @param [in] imagefile                 Output image file of test run.
 * @param [in] baseline                  Baseline image file.
 * @param [in] intensity_tolerance       Maximum tolerable intensity difference.
 * @param [in] max_number_of_differences Maximum number of differing pixels.
 * @param [in] tolerance_radius          Tolerance radius.
 * @param [in] report                    Level of test report to generate.
 *                                       If zero, no report is generated.
 *                                       If greater than zero, a report is
 *                                       generated. Similar to the verbosity of
 *                                       a program, is this parameter used to
 *                                       set the verbosity of the report. Most
 *                                       implementations yet only either
 *                                       generate a (full) report or none.
 */
int image_regression_test(const char*  imagefile,
                          const char*  baseline,
                          double       intensity_tolerance = 2.0,
                          unsigned int max_number_of_differences = 0,
                          unsigned int tolerance_radius = 0,
                          int          report = 0);


// inline definitions
#include "testdriver.hxx"


#endif // _SBIA_BASIS_TESTDRIVER_H
