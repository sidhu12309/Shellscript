#!/bin/bash
# ============================================================
# Description: Backup old logs, upload to S3, clean old files,
#              and display system resource usage.
# ============================================================

# ======= CONFIGURATION =======
LOG_DIR="/var/log/myapp"               # Location of logs
BACKUP_DIR="/backup/logs"              # Local backup directory
S3_BUCKET="s3://mycompany-log-backup"  # Target S3 bucket
DAYS=7                                 # Archive logs older than 7 days
DATE=$(date +"%Y-%m-%d")
HOSTNAME=$(hostname)
ARCHIVE_NAME="${HOSTNAME}_logs_${DATE}.tar.gz"
ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"

# ======= PREPARATION =======
mkdir -p "$BACKUP_DIR"

echo "🚀 Starting log backup and monitoring on host: $HOSTNAME"
echo "------------------------------------------------------------"

# ======= STEP 1: FIND AND ARCHIVE LOGS =======
echo "📦 Searching for logs older than $DAYS days in $LOG_DIR ..."
OLD_LOGS=$(find "$LOG_DIR" -type f -name "*.log" -mtime +$DAYS)

if [ -n "$OLD_LOGS" ]; then
    echo "🗜️ Creating archive..."
    tar -czf "$ARCHIVE_PATH" $OLD_LOGS
    echo "✅ Archive created at $ARCHIVE_PATH"

    echo "🧹 Removing old logs..."
    find "$LOG_DIR" -type f -name "*.log" -mtime +$DAYS -delete
    echo "✅ Old logs deleted."
else
    echo "⚠️ No logs older than $DAYS days found."
    exit 0
fi

echo "------------------------------------------------------------"

# ======= STEP 2: UPLOAD TO S3 =======
echo "☁️ Uploading archive to S3 bucket: $S3_BUCKET ..."
aws s3 cp "$ARCHIVE_PATH" "$S3_BUCKET/"

if [ $? -eq 0 ]; then
    echo "✅ Successfully uploaded: $S3_BUCKET/$ARCHIVE_NAME"
    rm -f "$ARCHIVE_PATH"
    echo "🧹 Local archive removed after upload."
else
    echo "❌ Failed to upload to S3. Archive retained locally."
fi

echo "------------------------------------------------------------"

# ======= STEP 3: CLEANUP OLD LOCAL BACKUPS =======
echo "🧹 Cleaning up local backups older than 30 days..."
find "$BACKUP_DIR" -type f -mtime +30 -name "*.tar.gz" -exec rm -f {} \;
echo "✅ Cleanup complete."
echo "------------------------------------------------------------"

# ======= STEP 4: SYSTEM RESOURCE MONITORING =======
echo "📊 System Resource Usage Report"
echo "------------------------------------------------------------"

# CPU usage
echo "🧠 CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{printf("User: %.2f%% | System: %.2f%% | Idle: %.2f%%\n", $2, $4, $8)}'

# Memory usage
echo ""
echo "💾 Memory Usage:"
free -h | awk '/Mem:/ {printf("Total: %s | Used: %s | Free: %s | Available: %s\n", $2, $3, $4, $7)}'

# Disk usage
echo ""
echo "🗄️ Disk Usage:"
df -h | awk 'NR==1 || /^\/dev/ {printf("%-20s %-8s %-8s %-8s %-6s %-10s\n", $1,$2,$3,$4,$5,$6)}'

echo "------------------------------------------------------------"
echo "✅ Log backup, S3 upload, cleanup, and monitoring completed successfully!"
