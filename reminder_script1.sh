#!/bin/bash

# Function to display a header
print_header() {
    echo -e "\033[1;34m==============================\033[0m"
    echo -e "\033[1;32m      Event Notification       \033[0m"
    echo -e "\033[1;34m==============================\033[0m"
}

# Function to validate email format
validate_email() {
    if [[ ! "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "\033[1;31mInvalid email format. Please try again.\033[0m"
        return 1
    fi
    return 0
}

# Function to validate date format
validate_date() {
    date -d "$1" &>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "\033[1;31mInvalid date format. Please use YYYY-MM-DD.\033[0m"
        return 1
    fi
    return 0
}

# Function to validate time format
validate_time() {
    date -d "1970-01-01 $1" &>/dev/null
    if [[ $? -ne 0 ]]; then
        echo -e "\033[1;31mInvalid time format. Please use HH:MM AM/PM.\033[0m"
        return 1
    fi
    return 0
}

# Function to send an email
send_email() {
    local subject="$1"
    local body="$2"
    local recipient="$3"

    echo -e "Subject:$subject\nContent-Type: text/html; charset=UTF-8\n\n$body" | sendmail "$recipient"
    if [[ $? -eq 0 ]]; then
        echo -e "\033[1;32mEmail sent successfully to $recipient.\033[0m"
    else
        echo -e "\033[1;31mFailed to send email to $recipient.\033[0m"
    fi
}

# Display header
print_header

# Collect user inputs with validation
echo -e "\033[1;36mPlease enter the following details:\033[0m"

# Event Name
read -p "$(echo -e '\033[1;33mEvent Name: \033[0m')" EVENT_NAME

# User Email
while true; do
    read -p "$(echo -e '\033[1;33mUser Email: \033[0m')" USER_EMAIL
    validate_email "$USER_EMAIL" && break
done

# Event Date
while true; do
    read -p "$(echo -e '\033[1;33mEvent Date (YYYY-MM-DD): \033[0m')" EVENT_DATE
    validate_date "$EVENT_DATE" && break
done

# Event Timee
while true; do
    read -p "$(echo -e '\033[1;33mEvent Time (HH:MM AM/PM): \033[0m')" EVENT_TIME
    validate_time "$EVENT_TIME" && break
done

# Event Description
echo -e "\033[1;33mPlease provide a brief description of the event:\033[0m"
read -p "$(echo -e '\033[1;33mEvent Description: \033[0m')" EVENT_DESC

# Convert event time to 24-hour format and calculate timestamps
EVENT_TIME_24=$(date -d "$EVENT_TIME" +"%H:%M")
EVENT_DATE_SECS=$(date -d "$EVENT_DATE $EVENT_TIME_24" +%s)
START_DATE=$(date -d "$EVENT_DATE -2 days" +%Y-%m-%d)

# Send confirmation email
CONFIRMATION_SUBJECT="Event Notification Added"
CONFIRMATION_BODY="
<html>
<body>
    <h2 style='color: #4CAF50;'>Event Added Successfully!</h2>
    <p><strong>Event:</strong> $EVENT_NAME</p>
    <p><strong>Description:</strong> $EVENT_DESC</p>
    <p><strong>Date:</strong> $EVENT_DATE</p>
    <p><strong>Time:</strong> $EVENT_TIME</p>
    <p>Daily reminders will start two days before the event.</p>
    <footer style='font-size: 12px; color: #777;'>This confirmation is sent by our event notification system.</footer>
</body>
</html>
"
send_email "$CONFIRMATION_SUBJECT" "$CONFIRMATION_BODY" "$USER_EMAIL"

# Create a unique temporary script for the event
TEMP_SCRIPT=$(mktemp /tmp/event_reminder_XXXXXX.sh)

cat <<EOL > "$TEMP_SCRIPT"
#!/bin/bash
# Event reminder email
$(declare -f send_email)
REMINDER_SUBJECT="Upcoming Event Reminder: $EVENT_NAME"
REMINDER_BODY="
<html>
<body>
    <h2 style='color: #4CAF50;'>Event Reminder: $EVENT_NAME</h2>
    <p><strong>Description:</strong> $EVENT_DESC</p>
    <p><strong>Date:</strong> $EVENT_DATE</p>
    <p><strong>Time:</strong> $EVENT_TIME</p>
    <footer style='font-size: 12px; color: #777;'>This reminder is sent by our event notification system.</footer>
</body>
</html>
"
send_email "\$REMINDER_SUBJECT" "\$REMINDER_BODY" "$USER_EMAIL"
EOL

chmod +x "$TEMP_SCRIPT"

# Schedule the cron job
CRON_TIME=$(date -d "$START_DATE $EVENT_TIME_24" +"%M %H")
(crontab -l 2>/dev/null; echo "$CRON_TIME * * * bash $TEMP_SCRIPT") | crontab -

# Confirmation message
echo -e "\033[1;32mEvent notifications scheduled successfully from $START_DATE to $EVENT_DATE.\033[0m"
