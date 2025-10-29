#!/usr/bin/env bash
set -euo pipefail

# TODO: add greek tasks list and use them randomly as the commit message
# TODO: add messaging to the effect of "hey I'm glad you're actually checking up on these commit messages rather than assum I'm honestly generating commits EVERY DAMN DAY in public repos (which would be unrealistic)"

generate_commits_for_day() {
    local file="$1"
    local day="$2"
    local maxcommits="$3"
    # Execute this block a random number of times between 1 and maxcommits
    commit_count=$(( (RANDOM % maxcommits) + 1 ))
    prevhour=0
    prevminute=0
    prevsecond=0
    echo "Commit count: $commit_count"
    for ((i = 0; i < commit_count; i++)); do
        # Generate random hour, minute, and second
        hour=$((RANDOM % 22))
        minute=$((RANDOM % 50))
        second=$((RANDOM % 50))

        if [ $hour -lt $prevhour ]; then
            hour=$prevhour
            minute=$((prevminute + 1))
            if [ $minute -gt 59 ]; then
                minute=59
            fi
        fi
        if [ $minute -lt $prevminute ]; then
            minute=$prevminute
            second=$((prevsecond + 1))
            if [ $second -gt 59 ]; then
                second=59
            fi
        fi

        # Construct random timestamp for that day in ISO8601
        hh=$(printf "%02d" $hour) || echo "hour was $hour"
        mm=$(printf "%02d" $minute) || echo "minute was $minute"
        ss=$(printf "%02d" $second) || echo "second was $second"
        ts="${day}T${hh}:${mm}:${ss}"
        echo "Changing file $file at $ts" >> "$file"

        # Stage file
        git add "$file"

        # Commit with message and set the author/committer date to random ts
        GIT_AUTHOR_DATE="${ts}" GIT_COMMITTER_DATE="${ts}" \
            git commit -m "Commit $((i + 1)) of $commit_count" --date="$ts" > /dev/null 2>&1 || true

        prevhour=$hour
        prevminute=$minute
        prevsecond=$second
    done
}

# Generate daily commits from 2019-01-01 up to today, one file per day
START_DATE="2019-01-01"
END_DATE="$(date +%Y-%m-%d)"
MAX_COMMITS=4
current="$START_DATE"
while [[ "$current" < "$END_DATE" ]] || [[ "$current" == "$END_DATE" ]]; do
    # Check if the current date is a Saturday (6) or Sunday (7)
    day_of_week=$(date -d "$current" +%u)
    echo "$current is the $day_of_week day"
    if [[ "$day_of_week" -eq 6 || "$day_of_week" -eq 7 ]]; then
        # Generate a random number between 1 and 10
        skip_chance=$((RANDOM % 10))
        if [[ "$skip_chance" -lt 9 ]]; then
            # 90% chance to skip
            echo "Skipping $current because it is the weekend"
            current=$(date -I -d "$current + 1 day")
            continue
        fi
    fi

    # Only add file if it doesn't exist (restart safe)
    FILE="./files/file_${current}.txt"
    echo "Committing to $FILE"
    if [ ! -f "$FILE" ]; then
        echo "Daily file for $current" > "$FILE"
        MAX_COMMITS=$(( (RANDOM % 5) + 1 ))
        generate_commits_for_day "$FILE" "$current" $MAX_COMMITS
    else
        echo "File $FILE already exists"
    fi

    # Increment date by one
    current=$(date -I -d "$current + 1 day")
done

