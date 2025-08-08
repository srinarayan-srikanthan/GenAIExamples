#!/bin/bash
# Copyright (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

chatqna_arg=$CHATQNA_TYPE

if [[ $chatqna_arg == "CHATQNA_FAQGEN" ]]; then
    python chatqna.py --faqgen
elif [[ $chatqna_arg == "CHATQNA_NO_RERANK" ]]; then
    python chatqna.py --without-rerank
elif [[ $chatqna_arg == "CHATQNA_GUARDRAILS" ]]; then
    python chatqna.py --with-guardrails
elif [[ $chatqna_arg == "CHATQNA_VISION" ]]; then
    python chatqna.py --vision
else
    python chatqna.py
fi
