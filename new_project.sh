#!/bin/bash

# Validate input
if [ "$#" -ne 3 ]; then
    echo "Usage: ./create-xcproject.sh <ProjectName> <OrganizationName> <OrganizationIdentifier>"
    exit 1
fi

# Variables from command-line arguments
project_name="$1"
organization_name="$2"
organization_identifier="$3"

# Create a new Xcode project
xcodebuild -create-xcproject \
    -projectName "$project_name" \
    -organizationName "$organization_name" \
    -organizationIdentifier "$organization_identifier"

