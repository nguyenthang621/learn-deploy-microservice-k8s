#!/bin/bash

TOKEN="<TKEN_TELEGRAM_BOT>"

# Hàm xử lý khi nhận tin nhắn /build
function handle_build() {
    chat_id="$1"
    branch="$2"
    user_id="$3"

    # Lấy tên người dùng từ user_id
    username=$(curl -s "https://api.telegram.org/bot$TOKEN/getChat?chat_id=$user_id" | jq -r ".result.username")

    # Lấy thời gian hiện tại
    current_time=$(date +"%Y-%m-%d %H:%M:%S")

    curl -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$chat_id" -d "text=Đang thực hiện lệnh build trên nhánh $branch bởi @$username lúc $current_time..."
    
    # Link api chạy Pipeline
    response=$(curl -X POST "<GITLAB_DOMAIN>/api/v4/projects/<GITLAB_PROJECT_ID>/pipeline" -H "PRIVATE-TOKEN: <GITLAB_ACCESS_TOKEN>" -F "ref=$branch")

    # Kiểm tra trạng thái từ response gọi pipeline
    status=$(echo "$response" | jq -r ".status")
    echo "Response: $response"
    if [ "$status" == "created" ]; then
        message="Đã thực hiện lệnh build trên nhánh $branch bởi @$username lúc $current_time!"
    else
        message="Không thể thực hiện lệnh build trên nhánh $branch vì nhánh không tồn tại hoặc lỗi."
    fi

    curl -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$chat_id" -d "text=$message"
}

# Lấy tin nhắn mới
function get_updates() {
    offset="$1"
    response=$(curl -s "https://api.telegram.org/bot$TOKEN/getUpdates?offset=$offset")
    echo "$response"
}

offset=0

while true; do
    updates=$(get_updates $offset)
    message_count=$(echo "$updates" | jq '.result | length')

    if [ "$message_count" -gt 0 ]; then
        for (( i = 0; i < $message_count; i++ )); do
            chat_id=$(echo "$updates" | jq -r ".result[$i].message.chat.id")
            user_id=$(echo "$updates" | jq -r ".result[$i].message.from.id")
            text=$(echo "$updates" | jq -r ".result[$i].message.text")

            if [[ "$text" == "/build "* ]]; then
                branch="${text#/build }"
                handle_build "$chat_id" "$branch" "$user_id"
            fi

            update_id=$(echo "$updates" | jq -r ".result[$i].update_id")
            offset=$((update_id + 1))
        done
    fi

    sleep 1
done
