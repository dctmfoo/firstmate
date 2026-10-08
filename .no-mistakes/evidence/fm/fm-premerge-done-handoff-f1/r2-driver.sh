#!/usr/bin/env bash
set -eu
bin/fm-lock.sh > "$FM_HOME/lock.log" 2>&1
. bin/fm-wake-lib.sh
. bin/fm-supervision-engine-lib.sh
key=$(fm_supervision_host_main_key "$FM_HOME/state")
python3 - "$FM_HOME/state/.host-mirror.jsonl" "$key" <<'PY'
import json,sys,time
open(sys.argv[1],'w').write(json.dumps(dict(seq=1,epoch=int(time.time()),key=sys.argv[2],id='lab-intent',tag='main',text='The worker is implementing the requested fix. When implementation is complete, I will send the validation go.'))+'\n')
PY
echo ready > "$FM_HOME/ready"
run_stage() {
  local stage=$1
  (until [ -f "$FM_HOME/$stage-host.out" ] && grep -q '^watcher:' "$FM_HOME/$stage-host.out"; do sleep 1; done; sleep 2; printf 'done [at=%s]: Implementation complete, committed; waiting for Firstmate to instruct /no-mistakes. No PR exists.\n' "$(date +%s)" >> "$FM_HOME/state/handoff.status") &
  FM_SUPERVISION_HOST_PARK_SECONDS=150 FM_SUPERVISION_HOST_TURN_TIMEOUT=50 bin/fm-supervision-host.sh park > "$FM_HOME/$stage-host.out" 2>&1
  echo "$?" > "$FM_HOME/$stage-host.rc"
  bin/fm-wake-drain.sh > "$FM_HOME/$stage-main-drain.out" 2>&1
  ack=$(sed -n 's/^WAKE_ACK_REQUIRED: after handling completes run //p' "$FM_HOME/$stage-main-drain.out")
  if [ -n "$ack" ]; then bash -c "$ack" > "$FM_HOME/$stage-main-ack.out" 2>&1; fi
  cp "$FM_HOME/state/branch-outcomes.jsonl" "$FM_HOME/$stage-outcomes.jsonl"
  cp "$FM_HOME/state/.supervision-host-engine" "$FM_HOME/$stage-engine.txt"
  cp "$FM_HOME/state/.supervision-host.log" "$FM_HOME/$stage-host.log"
  cat "$FM_HOME/$stage-host.out" "$FM_HOME/$stage-main-drain.out"
}
case "${LIVE_TEST_STAGE:-first}" in
  first)
    run_stage first
    bin/fm-branch-outcome.sh mark-processed --through "$(jq -r '.seq' "$FM_HOME/state/branch-outcomes.jsonl" | tail -1)"
    run_stage same-session
    ;;
  restart) run_stage restart ;;
  prior-routine) run_stage prior-routine ;;
esac
echo finished > "$FM_HOME/finished"
