#!/usr/bin/env bash
set -u
bin/fm-lock.sh > "$FM_HOME/lock.log" 2>&1 || exit 1
. bin/fm-wake-lib.sh
. bin/fm-supervision-engine-lib.sh
key=$(fm_supervision_host_main_key "$FM_HOME/state") || exit 1
python3 - "$FM_HOME/state/.host-mirror.jsonl" "$key" <<'PY'
import json,sys,time
open(sys.argv[1],'w').write(json.dumps(dict(seq=1,epoch=int(time.time()),key=sys.argv[2],id='lab-intent',tag='captain',text='Implement the requested fix. After the worker reports implementation complete, MAIN will send the validation go.'))+'\n')
PY
bin/fm-supervision-host.sh park > "$FM_HOME/first-host.out" 2>&1
printf '%s\n' "$?" > "$FM_HOME/first-host.rc"
bin/fm-wake-drain.sh > "$FM_HOME/first-main-drain.out" 2>&1

cat "$FM_HOME/first-host.out" "$FM_HOME/first-main-drain.out"
bin/fm-branch-outcome.sh mark-processed --through 1 > "$FM_HOME/processed.out"
printf 'done [at=%s]: Implementation complete, committed; waiting for Firstmate to instruct /no-mistakes. No PR exists.\n' "$(date +%s)" >> "$FM_HOME/state/handoff.status"
FM_SUPERVISION_HOST_PARK_SECONDS=90 FM_SUPERVISION_HOST_TURN_TIMEOUT=40 bin/fm-supervision-host.sh park > "$FM_HOME/repeat-host.out" 2>&1
printf '%s\n' "$?" > "$FM_HOME/repeat-host.rc"
bin/fm-wake-drain.sh > "$FM_HOME/repeat-main-drain.out" 2>&1
cat "$FM_HOME/repeat-host.out" "$FM_HOME/repeat-main-drain.out"
