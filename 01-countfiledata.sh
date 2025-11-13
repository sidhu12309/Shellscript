#!/bin/bash

# Check if file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

FILE=$1

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found!"
    exit 1
fi

echo "Analyzing file: $FILE"
echo "--------------------------------------"

# Total counts
LINES=$(wc -l < "$FILE")
WORDS=$(wc -w < "$FILE")
CHARS=$(wc -m < "$FILE")

echo "Total Lines     : $LINES"
echo "Total Words     : $WORDS"
echo "Total Characters: $CHARS"
echo "--------------------------------------"

# Top 5 repeated words
echo "🔹 Top 5 Repeated Words:"
tr '[:space:][:punct:]' '[\n*]' < "$FILE" | \
grep -v '^$' | \
tr '[:upper:]' '[:lower:]' | \
sort | uniq -c | sort -nr | head -5
echo "--------------------------------------"

# Top 5 longest lines
echo "🔹 Top 5 Longest Lines (by character count):"
awk '{ print length, ":", $0 }' "$FILE" | sort -nr | head -5
echo "--------------------------------------"

# Top 5 most frequent characters
echo "🔹 Top 5 Most Frequent Characters:"
cat "$FILE" | tr -d '\n' | fold -w1 | sort | uniq -c | sort -nr | head -5
echo "--------------------------------------"
