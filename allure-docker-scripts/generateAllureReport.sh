#!/bin/bash

EXEC_STORE_RESULTS_PROCESS=$1
PROJECT_ID=$2

# USED FROM API
ORIGIN=$3
EXECUTION_NAME=$4
EXECUTION_FROM=$5
EXECUTION_TYPE=$6

PROJECT_ROOT=$STATIC_CONTENT_PROJECTS/$PROJECT_ID
PROJECT_REPORTS=$PROJECT_ROOT/reports
PROJECT_RESULTS=$PROJECT_ROOT/results
PROJECT_HISTORY_FILE=$PROJECT_ROOT/history.jsonl

if [ "$(ls $PROJECT_REPORTS | wc -l)" != "0" ]; then
    if [ -e "$PROJECT_REPORTS/latest" ]; then
        LAST_REPORT_PATH_DIRECTORY=$(ls -td $PROJECT_REPORTS/* | grep -wv $PROJECT_REPORTS/latest | grep -v $EMAILABLE_REPORT_FILE_NAME | head -1)
    else
        LAST_REPORT_PATH_DIRECTORY=$(ls -td $PROJECT_REPORTS/* | grep -v $EMAILABLE_REPORT_FILE_NAME | head -1)
    fi
fi

LAST_REPORT_DIRECTORY=$(basename -- "$LAST_REPORT_PATH_DIRECTORY")

if [ ! -d "$PROJECT_RESULTS" ]; then
    echo "Creating results directory for PROJECT_ID: $PROJECT_ID"
    mkdir -p $PROJECT_RESULTS
fi

EXECUTOR_PATH=$PROJECT_RESULTS/$EXECUTOR_FILENAME

echo "Creating $EXECUTOR_FILENAME for PROJECT_ID: $PROJECT_ID"
if [[ "$LAST_REPORT_DIRECTORY" != "latest" ]]; then
    BUILD_ORDER=$(($LAST_REPORT_DIRECTORY + 1))

    if [ -z "$EXECUTION_NAME" ]; then
        EXECUTION_NAME='Automatic Execution'
    fi

    if [ -z "$EXECUTION_TYPE" ]; then
        EXECUTION_TYPE='another'
    fi

EXECUTOR_JSON=$(cat <<EOF
{
    "reportName": "$PROJECT_ID",
    "buildName": "$PROJECT_ID #$BUILD_ORDER",
    "buildOrder": "$BUILD_ORDER",
    "name": "$EXECUTION_NAME",
    "reportUrl": "../$BUILD_ORDER/index.html",
    "buildUrl": "$EXECUTION_FROM",
    "type": "$EXECUTION_TYPE"
}
EOF
)
    if [[ "$EXEC_STORE_RESULTS_PROCESS" == "1" ]]; then
        echo $EXECUTOR_JSON > $EXECUTOR_PATH
    else
        echo '' > $EXECUTOR_PATH
    fi
else
    echo '' > $EXECUTOR_PATH
fi

echo "Generating report for PROJECT_ID: $PROJECT_ID"
rm -rf $PROJECT_REPORTS/latest/*

# Allure 3 persists trend/history in a single jsonl file per project
if [ "$KEEP_HISTORY" == "TRUE" ] || [ "$KEEP_HISTORY" == "true" ] || [ "$KEEP_HISTORY" == "1" ]; then
    HISTORY_ARGS="--history-path $PROJECT_HISTORY_FILE"
else
    HISTORY_ARGS=""
    rm -f $PROJECT_HISTORY_FILE
fi

allure awesome \
    --report-name "Allure Report" \
    --report-language en \
    $HISTORY_ARGS \
    -o $PROJECT_REPORTS/latest \
    $PROJECT_RESULTS

# Keep only the last N history entries (max lookback reports)
if [ -n "$HISTORY_ARGS" ] && [ -f "$PROJECT_HISTORY_FILE" ]; then
    LIMIT=30
    if echo "$KEEP_HISTORY_LATEST" | grep -E -q '^[0-9]+$'; then
        LIMIT=$KEEP_HISTORY_LATEST
    fi
    tail -n "$LIMIT" "$PROJECT_HISTORY_FILE" > "$PROJECT_HISTORY_FILE.tmp" && \
        mv "$PROJECT_HISTORY_FILE.tmp" "$PROJECT_HISTORY_FILE"
fi

# Strip Google Analytics tracking injected by the awesome plugin
if [ -f "$PROJECT_REPORTS/latest/index.html" ]; then
    sed -i '/googletagmanager\.com\/gtag\/js/d; /window\.dataLayer = window\.dataLayer/,/gtag(.config., .G-/d' \
        $PROJECT_REPORTS/latest/index.html
fi

if [ "$OPTIMIZE_STORAGE" == "1" ] ; then
    REPORT_DIR=$PROJECT_REPORTS/latest
    for ASSET in app.js styles.css; do
        if [ -f "$ALLURE_RESOURCES/$ASSET" ] && [ -f "$REPORT_DIR/$ASSET" ]; then
            ln -sf $ALLURE_RESOURCES/$ASSET $REPORT_DIR/$ASSET
        fi
    done
fi

if [ "$KEEP_HISTORY" == "TRUE" ] || [ "$KEEP_HISTORY" == "true" ] || [ "$KEEP_HISTORY" == "1" ] ; then
    if [[ "$EXEC_STORE_RESULTS_PROCESS" == "1" ]]; then
        $ROOT/storeAllureReport.sh $PROJECT_ID $BUILD_ORDER
    fi
fi

$ROOT/keepAllureLatestHistory.sh $PROJECT_ID
