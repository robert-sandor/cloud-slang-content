# (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
# The Apache License is available at
# http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
# Pings addresses from input list and sends an email with results.
#
# Inputs:
#   - ip_list - list of IPs to be checked
#   - hostname - email host
#   - port - email port
#   - from - email sender
#   - to - email recipient
#   - username - mail username
#   - password - mail password
# Results:
#   - SUCCESS - addressee will get an email with result
#   - FAILURE - addressee will get an email with exception of operation
#
####################################################
namespace: io.cloudslang.base.network.example

imports:
  network: io.cloudslang.base.network
  mail: io.cloudslang.base.mail
  strings: io.cloudslang.base.strings

flow:
  name: ping_hosts

  inputs:
    - ip_list
    - message_body:
        default: []
        overridable: false
    - all_nodes_are_up:
        default: True
        overridable: false
    - hostname
    - port
    - username
    - password
    - from
    - to

  workflow:
    - check_address:
        loop:
          for: address in ip_list
          do:
            network.ping:
              - address
        publish:
              - messagebody: "fromInputs['message_body'].append(message)"
              - all_nodes_are_up: "fromInputs['all_nodes_are_up'] and is_up"
        navigate:
          UP: check_result
          DOWN: failure_mail_send
          FAILURE: failure_mail_send

    - check_result:
        do:
          strings.string_equals:
            - first_string: >
                str(all_nodes_are_up)
            - second_string: >
                "True"
        navigate:
          SUCCESS: mail_send
          FAILURE: failure_mail_send

    - mail_send:
        do:
          mail.send_mail:
            - hostname
            - port
            - from
            - to
            - subject: "'Ping Result'"
            - body: >
                  "Result: " + " ".join(message_body)
            - username
            - password

    - on_failure:
        - failure_mail_send:
            do:
              mail.send_mail:
                - hostname
                - port
                - from
                - to
                - subject: "'Ping Result'"
                - body: >
                      "Result: Failure to ping: " + " ".join(message_body)
                - username
                - password