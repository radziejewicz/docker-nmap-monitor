#!/bin/bash
set -e
set -o pipefail

ERRORS=()


for f in $(find ./scripts -type f -name "*.sh" | sort -u); do
	if file "$f" | grep --quiet shell; then
		{
			shellcheck -e SC2034 "$f" && echo -e "\e[32m[OK]\e[0m sucessfully linted: $f"
		} || {
			# add to errors
            echo -e "\e[31m[ERROR]\e[0m failed linted file: $f"
			ERRORS+=("$f")
		}
	fi
done


if [ ${#ERRORS[@]} -eq 0 ]; then
	echo -e "\e[32mNo errors, OK!"
else
    echo -e "\e[31mThese files failed shellcheck: ${ERRORS[*]}"
	exit 1
fi