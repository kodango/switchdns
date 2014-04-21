#!/bin/bash
# vim: set expandtab smarttab shiftwidth=4 tabstop=4:

# Source the workflow library
. workflowHandler.sh

# DNS Profile config file
PROFILE_CONF='.dns_profile'

# Icons folder
ICONS_DIR="./icons"

# Current used network device
CURR_DEV=''
# Current used network service
CURR_SERV=''

# Get current network device name
function get_curr_network_dev()
{
    netstat -rn | awk '/default/{print $NF}'
}

# Get the network service name
# $1: network device name
function get_network_service()
{
    # Do not check $1 value, maybe empty?
    networksetup -listnetworkserviceorder | awk \
            "/$1/{print \$3}" | tr -d ', ' | head -1
}

# Get the dns servers
# $1: network service name
function get_dns_servers()
{
    local servers=$(networksetup -getdnsservers "$1" | grep -v 'any')

    if [ -n "$servers" ]; then
        echo "$servers" | tr '\n' ',' | sed 's/,$//'
    else
        echo "empty"
    fi
}

# Generate feedback results
function list_dns()
{
    local cnt=0
    local curr_dns=$(get_dns_servers "$CURR_SERV")

    local title subtitle arg icon

    while IFS=: read dns_name dns_desc dns_servers; do
        uid="switchdns-$cnt"
        let cnt+=1
    
        icon="$ICONS_DIR/$dns_name.png"
    
        # Use default workflow icon if not found
        if [ ! -f "$icon" ]; then
            icon="icon.png"
        fi
    
        if [ "$curr_dns" != "$dns_servers" ]; then
            title="$dns_desc"
        else
            title="Now: $dns_desc" # Tag current used dns servers
        fi

        subtitle="$dns_servers"
        arg="$dns_desc:$dns_servers"

        addResult "$uid" "$arg" "$title" "$subtitle" "$icon" "yes"
    done <<EOF
default:Default DNS:empty
`grep -vE '(^[[:space:]]*$)|(^[[:space:]]*#)' $PROFILE_CONF`
EOF
    
    # Show feedback results
    getXMLResults
}

# Switch dns profile
function switch_dns()
{
    local dns_desc dns_servers

    dns_desc=$(echo "$1" | awk -F: '{print $1}')
    dns_servers=$(echo "$1" | awk -F: '{print $2}' | tr ',' ' ')

    # Set the dns servers
    networksetup -setdnsservers "$CURR_SERV" $dns_servers
    # Clear the dns cache
    dscacheutil -flushcache

    echo "切换配置到 '$dns_desc', 当前 DNS 为 '$dns_servers'"
}

# The main entry
function main()
{
    CURR_DEV=$(get_curr_network_dev)
    CURR_SERV=$(get_network_service "$CURR_DEV")

    if [ "$1" = "list_dns" ]; then
        list_dns
    else
        shift && switch_dns "$1"
    fi
}

main "$@" # Run from here
