#!/bin/bash

ROOT_DIR="$(dirname "$0")/.."
BASE_DIR="$ROOT_DIR/hidden/inbox"
INDEX_FILE="$BASE_DIR/index.txt"
MESSAGE_FILE="$BASE_DIR/message.json"
INDEXES_DIR="$BASE_DIR/indexes"

initialize_data_files() {
    if [ ! -d "$BASE_DIR" ]; then
        mkdir -p "$BASE_DIR"
    fi
    if [ ! -d "$INDEXES_DIR" ]; then
        mkdir -p "$INDEXES_DIR"
    fi
    if [ ! -f "$INDEX_FILE" ]; then
        echo "0" > "$INDEX_FILE"
    fi
    if [ ! -f "$MESSAGE_FILE" ]; then
        echo "[]" > "$MESSAGE_FILE"
    fi
}

new_employee_id() {
    initialize_data_files
    current_id=$(cat "$INDEX_FILE")
    echo "$((current_id + 1))" > "$INDEX_FILE"
    echo "Your employee id is $current_id!"
}

fetch_messages() {
    local id="$1"
    initialize_data_files
    local employee_index_file="$INDEXES_DIR/$id.txt"
    if [ ! -f "$employee_index_file" ]; then
        echo "0" > "$employee_index_file"
    fi
    local last_read=$(cat "$employee_index_file")
    local messages=()
    local i=0
    while IFS= read -r line; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        line=$(echo "$line" | sed 's/^"//;s/"\s*,\s*$//;s/"\s*$//')
        if [ -n "$line" ]; then
            messages[$i]="$line"
            i=$((i+1))
        fi
    done < <(grep -v '^\[' "$MESSAGE_FILE" | grep -v '^\]')
    local messages_count=${#messages[@]}
    if [ "$messages_count" -gt "$last_read" ]; then
        echo "New Message:"
        for ((i=last_read; i<messages_count; i++)); do
            echo "${messages[$i]}"
        done
        echo "$messages_count" > "$employee_index_file"
    else
        echo "No new messages for now. Please try again later."
    fi
}

post_message() {
    local id="$1"
    local content="$2"
    initialize_data_files
    local new_message="$id: $content"
    if [ ! -s "$MESSAGE_FILE" ] || [ "$(cat "$MESSAGE_FILE")" = "[]" ]; then
        cat > "$MESSAGE_FILE" << EOF
[
  "$new_message"
]
EOF
    else
        sed -i '$d' "$MESSAGE_FILE"
        sed -i '$s/$/,/' "$MESSAGE_FILE"
        cat >> "$MESSAGE_FILE" << EOF
  "$new_message"
]
EOF
    fi
}

initialize_data_files

case "$1" in
    "new")
        new_employee_id
        ;;
    "fetch")
        if [ -n "$2" ]; then
            fetch_messages "$2"
        else
            echo "Error: Employee ID is required for fetch command"
        fi
        ;;
    "post")
        if [ -n "$2" ] && [ -n "$3" ]; then
            post_message "$2" "$3"
        else
            echo "Error: Employee ID and Message are required for post command"
        fi
        ;;
    *)
        echo "Error: Invalid command. Available commands: new, fetch, post"
        ;;
esac