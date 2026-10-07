FROM docker.io/library/python:3.14-alpine

RUN pip install --no-cache-dir nanobot-ai==0.3.5

# Backport of an unreleased upstream fix (github.com/HKUDS/nanobot, main):
# nanobot 0.3.5 publishes "Compressing context…" / "Context compacted." into a
# user-facing chat whenever the idle auto-compact runs on an internal
# maintenance session (heartbeat, dream:*), because turn_delivery.py has no
# internal-session guard. The patch reproduces the upstream guard 1:1.
#
# patch(1) is not in Alpine's busybox (CONFIG_PATCH is not set), so it is
# installed as a temporary virtual dependency and removed again.
# The patch uses exact context with fuzz disabled: if the anchors move in a
# future nanobot release the build fails loudly instead of shipping a gateway
# that is only half patched.
COPY nanobot-0.3.5-internal-session-compaction.patch /tmp/nanobot-internal-session.patch
RUN apk add --no-cache --virtual .patch-deps patch \
 && sp="$(python -c 'import site; print(site.getsitepackages()[0])')" \
 && patch -p1 -F0 -d "$sp" < /tmp/nanobot-internal-session.patch \
 && grep -q "_is_internal_session(session_key)" "$sp/nanobot/agent/turn_delivery.py" \
 && python -m compileall -q "$sp/nanobot/agent/turn_delivery.py" \
 && rm -f /tmp/nanobot-internal-session.patch \
 && apk del .patch-deps

VOLUME ["/root/.nanobot"]

RUN nanobot onboard

CMD ["nanobot", "gateway"]
