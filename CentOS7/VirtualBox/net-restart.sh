#!/usr/bin/env bash
VBoxManage natnetwork stop --netname NatNetwork && VBoxManage natnetwork start --netname NatNetwork
