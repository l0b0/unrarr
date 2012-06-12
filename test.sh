#!/usr/bin/env bash
#
# NAME
#        test.sh - Test script
#
# BUGS
#        https://github.com/l0b0/unrarr/issues
#
# COPYRIGHT AND LICENSE
#        Copyright (C) 2012 Victor Engmark
#
#        This program is free software: you can redistribute it and/or modify
#        it under the terms of the GNU General Public License as published by
#        the Free Software Foundation, either version 3 of the License, or
#        (at your option) any later version.
#
#        This program is distributed in the hope that it will be useful,
#        but WITHOUT ANY WARRANTY; without even the implied warranty of
#        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#        GNU General Public License for more details.
#
#        You should have received a copy of the GNU General Public License
#        along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
################################################################################

declare -r cmd="$(dirname -- "$0")/$(basename -- "$(dirname -- "$0")").sh"
declare -r test_name=$'--$`!*@\a\b\E\f\r\t\v\\\'"\360\240\202\211 \n'
declare -r test_file="$0"

oneTimeSetUp() {
    test_dir="$__shunit_tmpDir/$test_name"
    stdout_file="${test_dir}/stdout"
    stderr_file="${test_dir}/stderr"
}

setUp() {
    mkdir -- "$test_dir"
    assertEquals 'Exit code' 0 $?
}

tearDown() {
    rm -r -- "$test_dir"
}

test_simple() {
    archive="$test_dir"/"$test_name".rar
    rar a -- "$archive" "$test_file" 2>&1 >/dev/null
    assertEquals 'Could not create archive' 0 $?
    "$cmd" -- "$test_dir" > "$stdout_file" 2> "$stderr_file"
    assertEquals 'Could not extract archive' 0 $?
    assertTrue 'Extracted file missing' '[ -f "$test_dir/$test_file" ]'
    assertTrue 'Archive missing' '[ -f "$archive" ]'
    assertFalse "Output on standard output: $(cat "$stdout_file")" '[ -s "$stdout_file" ]'
    assertFalse "Output on standard error: $(cat "$stderr_file")" '[ -s "$stderr_file" ]'
}

test_wrong_params() {
    archive="$test_dir"/"$test_name".rar
    rar a -- "$archive" "$test_file" 2>&1 >/dev/null
    assertEquals 'Could not create archive' 0 $?
    "$cmd" --delete --verbose --invalid -- "$test_dir" > "$stdout_file" 2> "$stderr_file"
    assertNotEquals 'Should not extract archive' 0 $?
    assertFalse 'Should not have extracted file' '[ -f "$test_dir/$test_file" ]'
    assertTrue 'Archive missing' '[ -f "$archive" ]'
    assertFalse "Output on standard output: $(cat "$stdout_file")" '[ -s "$stdout_file" ]'
    assertTrue 'No output on standard error' '[ -s "$stderr_file" ]'
}

test_verbose() {
    archive="$test_dir"/"$test_name".rar
    rar a -- "$archive" "$test_file" 2>&1 >/dev/null
    assertEquals 'Could not create archive' 0 $?
    "$cmd" --verbose -- "$test_dir" > "$stdout_file" 2> "$stderr_file"
    assertEquals 'Could not extract archive' 0 $?
    assertTrue 'Extracted file missing' '[ -f "$test_dir/$test_file" ]'
    assertTrue 'Archive missing' '[ -f "$archive" ]'
    assertTrue 'No output on standard output' '[ -s "$stdout_file" ]'
    assertFalse "Output on standard error: $(cat "$stderr_file")" '[ -s "$stderr_file" ]'
}

test_delete() {
    archive="$test_dir"/"$test_name".rar
    rar a -- "$archive" "$test_file" 2>&1 >/dev/null
    assertEquals 'Could not create archive' 0 $?
    "$cmd" --delete -- "$test_dir" > "$stdout_file" 2> "$stderr_file"
    assertEquals 'Could not extract archive' 0 $?
    assertTrue 'Extracted file missing' '[ -f "$test_dir/$test_file" ]'
    assertFalse 'Archive should be deleted' '[ -f "$archive" ]'
    assertFalse "Output on standard output: $(cat "$stdout_file")" '[ -s "$stdout_file" ]'
    assertFalse "Output on standard error: $(cat "$stderr_file")" '[ -s "$stderr_file" ]'
}

test_delete_standard_multipart_archives() {
    archive_prefix="$test_dir"/"$test_name"
    archive_extension=rar
    archive="$archive_prefix"."$archive_extension"
    archive_1="$archive_prefix".part1."$archive_extension"
    archive_2="$archive_prefix".part2."$archive_extension"
    rar a -v1 -- "$archive" "$test_file" 2>&1 >/dev/null # .part1.rar, .part2.rar, etc.
    assertEquals 'Could not create archive' 0 $?
    "$cmd" --delete -- "$test_dir" > "$stdout_file" 2> "$stderr_file"
    assertEquals 'Could not extract archive' 0 $?
    assertTrue 'Extracted file missing' '[ -f "$test_dir/$test_file" ]'
    assertFalse 'Archive part 1 should be deleted' '[ -f "$archive_1" ]'
    assertFalse 'Archive part 2 should be deleted' '[ -f "$archive_2" ]'
    assertFalse "Output on standard output: $(cat "$stdout_file")" '[ -s "$stdout_file" ]'
    assertTrue 'No output on standard error' '[ -s "$stderr_file" ]'
}

test_delete_extension_multipart_archives() {
    archive_prefix="$test_dir"/"$test_name"
    archive_extension=rar
    archive="$archive_prefix"."$archive_extension"
    archive_1="$archive_prefix".rar
    archive_2="$archive_prefix".r00
    rar a -v1 -vn -- "$archive" "$test_file" 2>&1 >/dev/null # .rar, .r00, .r01, etc.
    assertEquals 'Could not create archive' 0 $?
    "$cmd" --delete -- "$test_dir" > "$stdout_file" 2> "$stderr_file"
    assertEquals 'Could not extract archive' 0 $?
    assertTrue 'Extracted file missing' '[ -f "$test_dir/$test_file" ]'
    assertFalse 'Archive part 1 should be deleted' '[ -f "$archive_1" ]'
    assertFalse 'Archive part 2 should be deleted' '[ -f "$archive_2" ]'
    assertFalse "Output on standard output: $(cat "$stdout_file")" '[ -s "$stdout_file" ]'
    assertFalse "Output on standard error: $(cat "$stderr_file")" '[ -s "$stderr_file" ]'
}

# load and run shUnit2
test -n "${ZSH_VERSION:-}" && SHUNIT_PARENT=$0
. /usr/share/shunit2/shunit2
