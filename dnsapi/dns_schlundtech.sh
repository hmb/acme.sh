#!/usr/bin/env sh

########
# This is a custom DNS adapter for the german Schlundtech domain provider.
# Use as DNS api with the acme.sh LetsEncrypt script.
# See https://github.com/Neilpang/acme.sh for more information.
#
# Usage: acme.sh --issue --dns dns_schlundtech -d www.domain.com
#
# Author: Holger Böhnke
# Report bugs here: https://github.com/hmb/acme.sh
#
########

########  initialization #######################

# set these values, when using the provider the first time
#export SLTEC_user="0000000"
#export SLTEC_password="********************"

# set these values if they differ from the default below
#export SLTEC_context="10"
#export SLTEC_server="https://gateway.schlundtech.de/"

# default values for schlundtech dns requests, if the above not given
SLTEC_context_default="10"
SLTEC_server_default="https://gateway.schlundtech.de/"


########  public functions #####################

# Add the txt record before validation.
# Usage: dns_schlundtech_add _acme-challenge.www.domain.com "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"

dns_schlundtech_add() {
  local fulldomain="$1"
  local txtvalue="$2"

  _SLTEC_credentials
  if [ "$?" -ne 0 ]; then
    _err "Please specify the SchlundTech user and password and try again."
    return 1
  fi

  _SLTEC_split_domain "$fulldomain"

  _info "Using the schlundtech dns api to set the ${fulldomain} record"
  _debug "fulldomain: ${fulldomain}"
  _debug "domain    : ${_SLTEC_domain}" 
  _debug "subdomain : ${_SLTEC_subdomain}" 
  _debug "txtvalue  : ${txtvalue}"

  _SLTEC_init_request_add "$SLTEC_user" "$SLTEC_password" "$SLTEC_context" "$_SLTEC_domain" "$_SLTEC_subdomain" "$txtvalue"
  _debug "xmladd: ${_SLTEC_xmladd}" 

  _SLTEC_send_request "$_SLTEC_xmladd" "$SLTEC_server"
  echo "$_SLTEC_response" | grep "<code>S0202</code>" > /dev/null
  local result="$?"
  _debug "result: ${result}"

  # returns 0 means success, otherwise error.
  return "$result"
}


# Remove the txt record after validation.
# Usage: dns_schlundtech_rm _acme-challenge.www.domain.com "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"

dns_schlundtech_rm() {
  local fulldomain="$1"
  local txtvalue="$2"

  _SLTEC_credentials
  if [ "$?" -ne 0 ]; then
    _err "Please specify the SchlundTech user and password and try again."
    return 1
  fi

  _SLTEC_split_domain "$fulldomain"

  _info "Using the schlundtech dns api to remove the ${fulldomain} record"
  _debug "fulldomain: ${fulldomain}"
  _debug "txtvalue  : ${txtvalue}"
  _debug "domain    : ${_SLTEC_domain}" 
  _debug "subdomain : ${_SLTEC_subdomain}" 

  _SLTEC_init_request_rm "$SLTEC_user" "$SLTEC_password" "$SLTEC_context" "$_SLTEC_domain" "$_SLTEC_subdomain" "$txtvalue"
  _debug "xmlrm:  ${_SLTEC_xmlrm}" 

  _SLTEC_send_request "$_SLTEC_xmlrm" "$SLTEC_server"
  echo "$_SLTEC_response" | grep "<code>S0202</code>" > /dev/null
  local result="$?"
  _debug "result: ${result}"
    
  # no return value documented
  #return "$result"
}


####################  private functions below ##################################

_SLTEC_credentials() {

  if [ -z "${SLTEC_context}" ]; then
    SLTEC_context="${SLTEC_context_default}"
  fi

  if [ -z "${SLTEC_server}" ]; then
    SLTEC_server="${SLTEC_server_default}"
  fi

  if [ -z "${SLTEC_user}" ] || [ -z "$SLTEC_password" ] || [ -z "${SLTEC_context}" ] || [ -z "${SLTEC_server}" ]; then
    SLTEC_user=""
    SLTEC_password=""
    SLTEC_context=""
    SLTEC_server=""
    return 1
  else
    _saveaccountconf SLTEC_user "${SLTEC_user}"
    _saveaccountconf SLTEC_password "${SLTEC_password}"
    _saveaccountconf SLTEC_context "${SLTEC_context}"
    _saveaccountconf SLTEC_server "${SLTEC_server}"
    return 0
  fi
}


_SLTEC_split_domain() {
  local fulldomain="$1"
  
  _SLTEC_domain="$(echo "$fulldomain" | sed 's/.*\.\([^.]*\.[^.]*\)/\1/')" 
  _SLTEC_subdomain="$(echo "$fulldomain" | sed 's/\(.*\)\.[^.]*\.[^.]*/\1/')"
}


_SLTEC_init_request_add() {
  local user="$1"
  local password="$2"
  local context="$3"
  local domain="$4"
  local subdomain="$5"
  local value="$6"

  _SLTEC_xmladd="<?xml version='1.0' encoding='utf-8'?>
  <request>
    <auth>
      <user>${user}</user>
      <password>${password}</password>
      <context>${context}</context>
    </auth>
    <task>
      <code>0202001</code>
      <default>
        <rr_add>
          <name>${subdomain}</name>
          <type>TXT</type>
          <value>${value}</value>
          <ttl>60</ttl>
        </rr_add>
      </default>
      <zone>
        <name>${domain}</name>
      </zone>
    </task>
  </request>"
}


_SLTEC_init_request_rm() {
  local user="$1"
  local password="$2"
  local context="$3"
  local domain="$4"
  local subdomain="$5"
  local value="$6"

  _SLTEC_xmlrm="<?xml version='1.0' encoding='utf-8'?>
  <request>
    <auth>
      <user>${user}</user>
      <password>${password}</password>
      <context>${context}</context>
    </auth>
    <task>
      <code>0202001</code>
      <default>
        <rr_rem>
          <name>${subdomain}</name>
          <type>TXT</type>
          <value>${value}</value>
        </rr_rem>
      </default>
      <zone>
        <name>${domain}</name>
      </zone>
    </task>
  </request>"
}


_SLTEC_send_request() {
  local request="$1"
  local url="$2"

  _SLTEC_response="$(curl -s -H "Content-type: text/xml" --data-binary "${request}" "${url}")"
  _debug "response: ${_SLTEC_response}"
}
