#!/bin/bash -u

if [ -f .env ]; then
    source .env
fi

: ${TARGETS:=''}
: ${HEALTHCHECK_WEBHOOK:=''}
: ${OPTIONS:=''}
: ${CHECK_INTERVAL:=3600}
: ${SLACK_USERNAME:="nmap-monitor"}
: ${SLACK_ICON:=":warning:"}
: ${SLACK_WEBHOOK:=''}

if [ "${TARGETS:-}" == "" ]; then
    echo "TARGETS not set!"
    exit
fi

if [ "${SLACK_WEBHOOK:-}" == "" ]; then
    echo "SLACK_WEBHOOK not set!"
    exit
fi

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LOG_DIR=logs
LOG_TARGET_DIR="${SCRIPT_DIR}/../${LOG_DIR}"
LAST_RUN_FILE="${SCRIPT_DIR}/../${LOG_DIR}/last_run.log"


function sendMessageToSlack {
    curl -s -X POST --data-urlencode "payload={\"username\": \"$SLACK_USERNAME\", \"icon_emoji\": \"$SLACK_ICON\", \"text\": \"$1\"}" $SLACK_WEBHOOK > /dev/null &
}

function pingHealthCheck {
    if [ -n "$HEALTHCHECK_WEBHOOK" ]; then       
        curl -m 10 -s -X POST $HEALTHCHECK_WEBHOOK > /dev/null &
    fi    
}

function showLog {
    CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$CURRENT_DATE] $1"
}

while true; do
    if [ -e "${LAST_RUN_FILE}" ]; then
        LAST_RUN=$(date -r ${LAST_RUN_FILE} +"%Y-%m-%d %H:%M:%S") 
        showLog "Script last run: $LAST_RUN"  
    fi

    START_TIME=$(date +%s)
    DATE_NOW=$(date +"%Y-%m-%d_%H:%M:%S")
    
    for TARGET in ${TARGETS}; do
        showLog "Starting target ${TARGET}"

        CUR_LOG_FILE="${LOG_TARGET_DIR}/${TARGET/\//-}.${DATE_NOW}.xml"
        PREV_LOG_FILE="${LOG_TARGET_DIR}/${TARGET/\//-}.prev.xml"
        DIFF_LOG_FILE="${LOG_TARGET_DIR}/${TARGET/\//-}.diff.xml"

        nmap ${OPTIONS} ${TARGET} -oX ${CUR_LOG_FILE} >/dev/null
        if [ -e ${PREV_LOG_FILE} ]; then
            # Exclude date and nmap version
            ndiff "${PREV_LOG_FILE}" "${CUR_LOG_FILE}" | egrep -v '^(\+|-)N' > "${DIFF_LOG_FILE}"

            if [ -s ${DIFF_LOG_FILE} ]; then                
                OPEN_PORTS="$(nmap -sV ${TARGET} | grep open | grep -v "#" > openports.txt)"                
                showLog "Changes were detected on ${TARGET}. Ports are now open: \n```$OPEN_PORTS```"
                sendMessageToSlack "Changes were detected on ${TARGET}. The following ports are now open: \n```$OPEN_PORTS```"
              
                ln -sf ${CUR_LOG_FILE} ${PREV_LOG_FILE}
            else
                # No changes - remove current log
                showLog "No changes detected."
                rm ${CUR_LOG_FILE}
            fi
            rm -f ${DIFF_LOG_FILE}
        else            
            ln -sf ${CUR_LOG_FILE} ${PREV_LOG_FILE}
        fi
    done

    touch ${LAST_RUN_FILE}
    END_TIME=$(date +%s)
    FINAL_TIME=$(expr ${END_TIME} - ${START_TIME})
    showLog "Done all targets in ${FINAL_TIME} seconds."
    pingHealthCheck
    sleep ${CHECK_INTERVAL}
done
