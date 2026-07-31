#!/usr/bin/env bash
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
core_role_directive "YOU DECIDE: 다른 로케일에서도 산출물이 성립하는가" "USE WHEN: i18n 대상 표면이 걸릴 때" "PRODUCES: locale-fitness verdict per target locale, string-external issue list" "HAND-OFF: 카피 원문 자체를 다시 써야 하면 → content-design"
