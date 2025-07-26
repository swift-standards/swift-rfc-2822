#!/bin/bash

# Setup script for new RFC repository
# Usage: ./Scripts/setup-rfc.sh <RFC_NUMBER> <RFC_TITLE> [AUTHOR_NAME]

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <RFC_NUMBER> <RFC_TITLE> [AUTHOR_NAME]"
    echo "Example: $0 2822 'Internet Message Format' 'John Doe'"
    exit 1
fi

RFC_NUMBER=$1
RFC_TITLE=$2
AUTHOR_NAME=${3:-"Generated"}
CREATION_DATE=$(date +"%d/%m/%Y")

echo "Setting up RFC $RFC_NUMBER: $RFC_TITLE"
echo "Author: $AUTHOR_NAME"
echo "Date: $CREATION_DATE"

# Function to process template files
process_template() {
    local file=$1
    local new_file="${file%.template}"
    
    sed "s/XXXX/$RFC_NUMBER/g; s/RFC_TITLE/$RFC_TITLE/g; s/RFC_AUTHOR_NAME/$AUTHOR_NAME/g; s/RFC_CREATION_DATE/$CREATION_DATE/g" "$file" > "$new_file"
    rm "$file"
    echo "Processed: $new_file"
}

# Process all template files
find . -name "*.template" -type f | while read -r file; do
    process_template "$file"
done

# Rename directories
if [ -d "Sources/RFC_XXXX" ]; then
    mv "Sources/RFC_XXXX" "Sources/RFC_$RFC_NUMBER"
    echo "Renamed: Sources/RFC_$RFC_NUMBER"
fi

if [ -d "Tests/RFC_XXXX Tests" ]; then
    mv "Tests/RFC_XXXX Tests" "Tests/RFC_${RFC_NUMBER} Tests"
    echo "Renamed: Tests/RFC_${RFC_NUMBER} Tests"
fi

# Initialize git repository if not already initialized
if [ ! -d ".git" ]; then
    git init
    echo "Initialized git repository"
fi

echo ""
echo "✅ RFC $RFC_NUMBER setup complete!"
echo ""
echo "Next steps:"
echo "1. Review and commit the generated files"
echo "2. Create GitHub repository: swift-rfc-$RFC_NUMBER"
echo "3. Push to GitHub"
echo "4. Start implementing RFC $RFC_NUMBER types in Sources/RFC_$RFC_NUMBER/"