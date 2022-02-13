#!/bin/bash
declare -A opts_yes
opts_yes=([yes]=1 [YES]=1 [y]=1 [Y]=1)


for opt in "${opts_yes[@]}"; do
    echo "${opt}"
done
