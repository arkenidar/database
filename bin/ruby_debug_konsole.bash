#!/usr/bin/env bash

konsole --hold -e /bin/bash \
-c "$HOME/.rbenv/shims/rdebug-ide --host 0.0.0.0 --port 8800 --dispatcher-port 9900 -- bin/tui" &
