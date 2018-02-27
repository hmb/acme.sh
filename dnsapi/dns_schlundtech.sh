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
  fulldomain="$1"
  txtvalue="$2"

  _SLTEC_credentials
  if [ "$?" -ne 0 ]; then
    _err "Please specify the SchlundTech user and password and try again."
    return 1
  fi

  if ! _SLTEC_split_domain "$fulldomain"; then
    _err "domain either invalid or not hosted by this account"
    return 1
  fi

  _info "Using the schlundtech dns api to set the ${fulldomain} record"
  _debug "fulldomain: ${fulldomain}"
  _debug "domain    : ${_SLTEC_domain}"
  _debug "subdomain : ${_SLTEC_subdomain}"
  _debug "txtvalue  : ${txtvalue}"

  _SLTEC_init_request_add "$SLTEC_user" "$SLTEC_password" "$SLTEC_context" "$_SLTEC_domain" "$_SLTEC_subdomain" "$txtvalue"
  _debug "xmladd: ${_SLTEC_xmladd}"

  _SLTEC_send_request "$_SLTEC_xmladd" "$SLTEC_server"
  echo "$_SLTEC_response" | grep "<code>S0202</code>" >/dev/null
  _ST_add_result="$?"
  _debug "result: ${_ST_add_result}"

  # returns 0 means success, otherwise error.
  return "$_ST_add_result"
}

# Remove the txt record after validation.
# Usage: dns_schlundtech_rm _acme-challenge.www.domain.com "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"

dns_schlundtech_rm() {
  fulldomain="$1"
  txtvalue="$2"

  _SLTEC_credentials
  if [ "$?" -ne 0 ]; then
    _err "Please specify the SchlundTech user and password and try again."
    return 1
  fi

  if ! _SLTEC_split_domain "$fulldomain"; then
    _err "domain either invalid or not hosted by this account"
    return 1
  fi

  _info "Using the schlundtech dns api to remove the ${fulldomain} record"
  _debug "fulldomain: ${fulldomain}"
  _debug "txtvalue  : ${txtvalue}"
  _debug "domain    : ${_SLTEC_domain}"
  _debug "subdomain : ${_SLTEC_subdomain}"

  _SLTEC_init_request_rm "$SLTEC_user" "$SLTEC_password" "$SLTEC_context" "$_SLTEC_domain" "$_SLTEC_subdomain" "$txtvalue"
  _debug "xmlrm:  ${_SLTEC_xmlrm}"

  _SLTEC_send_request "$_SLTEC_xmlrm" "$SLTEC_server"
  echo "$_SLTEC_response" | grep "<code>S0202</code>" >/dev/null
  _ST_rm_result="$?"
  _debug "result: ${_ST_rm_result}"

  # no return value documented
  #return "$_ST_rm_result"
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

# function _SLTEC_split_domain
# split a fully qualified domain name into domain and subdomain
# using the SchlundTech xml gateway interface
# param 1: fqdn, e.g.: _acme-challenge.www.domain.com
#returns
# _SLTEC_subdomain=_acme-challenge.www
# _SLTEC_domain=domain.com
#
_SLTEC_split_domain() {
  _ST_split_fulldomain="$1"

  _SLTEC_sd_i=2
  _SLTEC_sd_p=1
  _SLTEC_sd_max=100

  while true; do
    _SLTEC_domain="$(printf "%s" "$_ST_split_fulldomain" | cut -d . -f $_SLTEC_sd_i-$_SLTEC_sd_max)"
    _debug "trying to inquire domain: $_SLTEC_domain"

    if [ -z "$_SLTEC_domain" ]; then
      # domain not valid
      return 1
    fi

    # assemble inquire request and send it
    _SLTEC_init_request_zoneinq "$SLTEC_user" "$SLTEC_password" "$SLTEC_context" "$_SLTEC_domain"
    _debug "xmlzoneinc: ${_SLTEC_xmlzoneinq}"
    _SLTEC_send_request "$_SLTEC_xmlzoneinq" "$SLTEC_server"
    _debug "xmlzoneinc response: ${_SLTEC_response}"

    if _contains "$_SLTEC_response" "<name>${_SLTEC_domain}</name>"; then
      # found the correct domain/subdomain split
      _SLTEC_subdomain=$(printf "%s" "$_ST_split_fulldomain" | cut -d . -f 1-$_SLTEC_sd_p)
      _debug "_SLTEC_subdomain" "$_SLTEC_subdomain"
      _debug "_SLTEC_domain" "$_SLTEC_domain"
      return 0
    fi

    _SLTEC_sd_p=$_SLTEC_sd_i
    _SLTEC_sd_i=$(_math "$_SLTEC_sd_i" + 1)
  done

  # code never reached
  return 1
}

# function _SLTEC_init_request_zoneinq
# fill a zone inquiry request with user, password context and domain
# param 1: <SchlundTech user>
# param 2: <SchlundTech password>
# param 3: <SchlundTech context>
# param 4: <domain>
# returns: _SLTEC_xmlzoneinq the request to be sent to the server
#
_SLTEC_init_request_zoneinq() {
  _ST_init_zi_user="$1"
  _ST_init_zi_password="$2"
  _ST_init_zi_context="$3"
  _ST_init_zi_domain="$4"

  _SLTEC_xmlzoneinq="<?xml version='1.0' encoding='utf-8'?>
  <request>
    <auth>
      <user>${_ST_init_zi_user}</user>
      <password>${_ST_init_zi_password}</password>
      <context>${_ST_init_zi_context}</context>
    </auth>
    <task>
      <code>0205</code>
      <where>
        <key>name</key>
        <operator>eq</operator>
        <value>${_ST_init_zi_domain}</value>
      </where>
    </task>
  </request>"
}

_SLTEC_init_request_add() {
  _ST_init_add_user="$1"
  _ST_init_add_password="$2"
  _ST_init_add_context="$3"
  _ST_init_add_domain="$4"
  _ST_init_add_subdomain="$5"
  _ST_init_add_value="$6"

  _SLTEC_xmladd="<?xml version='1.0' encoding='utf-8'?>
  <request>
    <auth>
      <user>${_ST_init_add_user}</user>
      <password>${_ST_init_add_password}</password>
      <context>${_ST_init_add_context}</context>
    </auth>
    <task>
      <code>0202001</code>
      <default>
        <rr_add>
          <name>${_ST_init_add_subdomain}</name>
          <type>TXT</type>
          <value>${_ST_init_add_value}</value>
          <ttl>60</ttl>
        </rr_add>
      </default>
      <zone>
        <name>${_ST_init_add_domain}</name>
      </zone>
    </task>
  </request>"
}

_SLTEC_init_request_rm() {
  _ST_init_rm_user="$1"
  _ST_init_rm_password="$2"
  _ST_init_rm_context="$3"
  _ST_init_rm_domain="$4"
  _ST_init_rm_subdomain="$5"
  _ST_init_rm_value="$6"

  _SLTEC_xmlrm="<?xml version='1.0' encoding='utf-8'?>
  <request>
    <auth>
      <user>${_ST_init_rm_user}</user>
      <password>${_ST_init_rm_password}</password>
      <context>${_ST_init_rm_context}</context>
    </auth>
    <task>
      <code>0202001</code>
      <default>
        <rr_rem>
          <name>${_ST_init_rm_subdomain}</name>
          <type>TXT</type>
          <value>${_ST_init_rm_value}</value>
        </rr_rem>
      </default>
      <zone>
        <name>${_ST_init_rm_domain}</name>
      </zone>
    </task>
  </request>"
}

_SLTEC_send_request() {
  _ST_send_request="$1"
  _ST_send_url="$2"

  export _H1="Content-Type: text/xml"
  _SLTEC_response="$(_post "${_ST_send_request}" "${_ST_send_url}")"
  _debug "response: ${_SLTEC_response}"
}
