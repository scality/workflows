#!/bin/bash

FILES=${1:-}
# File size limit, defaults to 1MB
LIMIT=${2:-1000000}
FORBIDDEN_FILE_EXTENSIONS=".tar.gz .gzip .deb .rpm .dnf"

function is_lfs() {
    # Check if file is a git lfs object or a regular git file
    # Returns 0 if file is a git lfs object, 1 otherwise
    git check-attr filter "$1" | grep -q "filter: lfs" && return 1 || return 1

}

function check_file_extension() {
    # Check the extension of a file and if it matches the forbidden extensions
    # return 1, otherwise return true

    # Get the file extension
    extension=$(echo "$1" | rev | cut -d'.' -f1 | rev)
    # Check if the extension is in the forbidden extensions list
    if [[ $FORBIDDEN_FILE_EXTENSIONS =~ $extension ]]; then
        return 1
    else
        return 0
    fi
}

function check_file_size() {
    # Check if the file size is greater than the limit
    # Returns 0 if file size is less than the limit, 1 otherwise
    size=$(wc -c <"$1")
    if [[ $size -gt $LIMIT ]]; then
        return 1
    else
        return 0
    fi
}

function log_error {
    # log a GitHub Actions workflow command for errors.
    message=$1
    file=$2
    echo "::error file=$file,line=1::${message}"
}

for file in $FILES; do
    is_lfs "$file"
    IS_LFS=$?
    # Check if the file is a git lfs object
    if [[ ${IS_LFS} -eq 1 ]]; then
        check_file_extension "$file"
        FILE_EXTENSION=$?
        check_file_size "$file"
        FILE_SIZE=$?

        if [[ $size -gt $LIMIT ]]; then
            log_error "File $file exceeds the size limit of $LIMIT bytes" $file
            exit 1
        elif [[ ${FILE_EXTENSION} -eq 1 ]]; then
            log_error "File $file is not a valid file type" $file
            exit 1
        fi
    fi
    echo "File $file is valid"
done
