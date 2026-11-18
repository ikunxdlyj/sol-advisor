#!/bin/sh
# Install Sol Advisor's shipped custom-agent templates without changing Codex config.

set -eu

usage() {
  cat <<'EOF'
Usage: install-agents.sh [--target-dir PATH] [--check] [--check-role ROLE ...]

Install Sol Advisor's four current GPT-6-family custom-agent templates into the target
directory. Normal mode migrates only exact byte-matching historical templates and
retires superseded role names only when each file is byte-exact. It never
overwrites or removes a modified, nonregular, or symlinked destination.

Without --target-dir, the target is "$CODEX_HOME/agents" when CODEX_HOME is already
set, otherwise "$HOME/.codex/agents".

Options:
  --target-dir PATH  Explicit destination directory (absolute or relative).
  --check            Verify Luna High, Luna Max, Terra High, and Sol exactly; do not create,
                     replace, or remove anything.
  --check-role ROLE  Verify only ROLE (luna-high, luna-max, terra-high, or sol); repeatable and
                     implies --check. The historical luna and terra names remain
                     compatibility aliases. Unknown or missing roles fail safely.
  --help             Show this help text.
EOF
}

fail() {
  printf '%s\n' "ERROR: $*" >&2
  exit 1
}

report_preflight_error() {
  printf '%s\n' "ERROR: $*" >&2
  preflight_failed=1
}

role_selected() {
  role=$1
  if [ -z "$check_roles" ]; then
    return 0
  fi
  case ",$check_roles," in
    *,"$role",*) return 0 ;;
    *) return 1 ;;
  esac
}

path_exists() {
  [ -e "$1" ] || [ -L "$1" ]
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    checksum=$(shasum -a 256 "$1" 2>/dev/null || true)
  elif command -v sha256sum >/dev/null 2>&1; then
    checksum=$(sha256sum "$1" 2>/dev/null || true)
  else
    checksum=''
  fi
  printf '%s\n' "$checksum" | awk 'NF >= 1 && length($1) == 64 { print $1; exit }'
}

digest_is_allowed() {
  actual_digest=$1
  allowed_digests=$2
  for allowed_digest in $allowed_digests; do
    if [ "$actual_digest" = "$allowed_digest" ]; then
      return 0
    fi
  done
  return 1
}

classify_current_or_legacy() {
  destination=$1
  template=$2
  legacy_digests=$3

  if ! path_exists "$destination"; then
    printf '%s\n' missing
  elif [ -L "$destination" ] || [ ! -f "$destination" ]; then
    printf '%s\n' unsafe
  elif cmp -s "$template" "$destination"; then
    printf '%s\n' current
  else
    digest=$(sha256_file "$destination")
    if [ -n "$digest" ] && digest_is_allowed "$digest" "$legacy_digests"; then
      printf '%s\n' legacy
    elif [ -z "$digest" ]; then
      printf '%s\n' unreadable
    else
      printf '%s\n' conflict
    fi
  fi
}

classify_retired() {
  destination=$1
  legacy_digests=$2

  if ! path_exists "$destination"; then
    printf '%s\n' missing
  elif [ -L "$destination" ] || [ ! -f "$destination" ]; then
    printf '%s\n' unsafe
  else
    digest=$(sha256_file "$destination")
    if [ -n "$digest" ] && digest_is_allowed "$digest" "$legacy_digests"; then
      printf '%s\n' legacy
    elif [ -z "$digest" ]; then
      printf '%s\n' unreadable
    else
      printf '%s\n' conflict
    fi
  fi
}

same_state() {
  label=$1
  expected=$2
  actual=$3
  [ "$expected" = "$actual" ] || fail "$label changed after preflight; no further destination files were changed."
}

install_missing() {
  template=$1
  destination=$2
  staged=''

  if path_exists "$destination"; then
    fail "destination changed after preflight and will not be overwritten: $destination"
  fi

  staged=$(mktemp "$target_dir/.sol-advisor-agent.XXXXXX") || fail "could not stage template for installation: $destination"
  if ! cp "$template" "$staged"; then
    rm -f "$staged"
    fail "could not stage template for installation: $destination"
  fi

  if ! ln "$staged" "$destination"; then
    rm -f "$staged"
    fail "destination changed after preflight and will not be overwritten: $destination"
  fi

  rm -f "$staged" || fail "could not remove staged template after installation: $staged"
  printf '%s\n' "INSTALLED: $destination"
}

replace_legacy_role() {
  label=$1
  template=$2
  destination=$3
  legacy_digests=$4
  staged=''

  [ "$(classify_current_or_legacy "$destination" "$template" "$legacy_digests")" = legacy ] ||
    fail "legacy $label destination changed after preflight and will not be replaced: $destination"

  staged=$(mktemp "$target_dir/.sol-advisor-agent.XXXXXX") || fail "could not stage migrated $label template: $destination"
  if ! cp "$template" "$staged"; then
    rm -f "$staged"
    fail "could not stage migrated $label template: $destination"
  fi

  [ "$(classify_current_or_legacy "$destination" "$template" "$legacy_digests")" = legacy ] || {
    rm -f "$staged"
    fail "legacy $label destination changed after preflight and will not be replaced: $destination"
  }

  if ! mv -f "$staged" "$destination"; then
    rm -f "$staged"
    fail "could not replace exact legacy $label template: $destination"
  fi

  printf '%s\n' "MIGRATED: $destination"
}

retire_legacy_role() {
  label=$1
  destination=$2
  legacy_digests=$3

  [ "$(classify_retired "$destination" "$legacy_digests")" = legacy ] ||
    fail "legacy $label destination changed after preflight and will not be retired: $destination"
  rm -f "$destination" || fail "could not retire exact legacy $label template: $destination"
  path_exists "$destination" && fail "retired $label destination still exists: $destination"
  printf '%s\n' "RETIRED: $destination"
}

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd) || exit 1
template_dir=$script_dir/../agents

if [ -n "${CODEX_HOME-}" ]; then
  target_dir=$CODEX_HOME/agents
else
  [ -n "${HOME-}" ] || fail "HOME is unset and CODEX_HOME was not supplied; pass --target-dir explicitly."
  target_dir=$HOME/.codex/agents
fi

check_only=0
check_roles=''

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-dir)
      [ "$#" -ge 2 ] || fail "--target-dir requires a path."
      [ -n "$2" ] || fail "--target-dir requires a non-empty path."
      case "$2" in
        --*) fail "--target-dir path must be explicit; prefix an option-like relative name with ./ or use an absolute path." ;;
      esac
      target_dir=$2
      shift 2
      ;;
    --check)
      check_only=1
      shift
      ;;
    --check-role)
      [ "$#" -ge 2 ] || fail "--check-role requires a role: luna-max, luna-high, terra-high, or sol."
      case "$2" in
        luna-high|luna) selected_role=luna-high ;;
        luna-max|terra) selected_role=luna-max ;;
        terra-high) selected_role=terra-high ;;
        sol) selected_role=sol ;;
        *) fail "unknown --check-role '$2'; expected luna-max, luna-high, terra-high, or sol." ;;
      esac
      check_only=1
      check_roles=$check_roles$selected_role,
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1 (run with --help for usage)."
      ;;
  esac
done

case "$target_dir" in
  /*) ;;
  *) target_dir=$(pwd -P)/$target_dir ;;
esac

case "$target_dir" in
  /|//) fail "refusing to use the filesystem root as an agent target directory." ;;
esac

luna_file=sol-advisor-luna-implementer.toml
max_file=sol-advisor-luna-max-implementer.toml
specialist_file=sol-advisor-terra-specialist.toml
sol_file=sol-advisor-sol-reviewer.toml
retired_high_file=sol-advisor-luna-high-implementer.toml
retired_terra_file=sol-advisor-terra-implementer.toml
luna_template=$template_dir/$luna_file
max_template=$template_dir/$max_file
specialist_template=$template_dir/$specialist_file
sol_template=$template_dir/$sol_file
luna_destination=$target_dir/$luna_file
max_destination=$target_dir/$max_file
specialist_destination=$target_dir/$specialist_file
sol_destination=$target_dir/$sol_file
retired_high_destination=$target_dir/$retired_high_file
retired_terra_destination=$target_dir/$retired_terra_file

# Immutable byte digests calculated from previously shipped role files.
legacy_luna_sha256=fba1b42849d93737e83b094a2ab0b1611f87ac37db7438c8bbdf581f0813f8eb
legacy_terra_sha256=4425a8c1f21ce8c6af93f96adc253bbc33ea301f1389b3fa8ce350be08584eca
legacy_luna_v050_sha256=5cfaf77f14757074ca5d3cfecd0b8204c91dc14eff8d6119985c64416ddf4853
legacy_terra_v050_sha256=dc329fe87f6f6610c13157ec16432f91c79cf5a541ee3e7448f6afb165dd18ce
legacy_luna_v060_sha256=12fa9180a292876e6731bc325779123bcd931c3caa902fbf90d676a31833be84
legacy_terra_v060_sha256=77ed2f36bb149da5d9032230c3d6f5e5cd56b059b3fa5f59085249bba06e1f3a
legacy_sol_v060_sha256=0333acf0ef562bcfebd06009ac09bd1dd8cbc04c4cf28e08e9e049bd8bf202d2
legacy_luna_v060_crlf_sha256=000ff8bed7f94f77a460fb81424d51233eb6146db5b21a346068aceb6a9abe27
legacy_terra_v060_crlf_sha256=7c9497c46207007565f72ac9bac6ce4954a1491914e4d64b44e27e4c27e8cd43
legacy_sol_v060_crlf_sha256=6ac63677bcc8677a9a743522cf06696c8edb1b005a61430e0fc8fa62e18dc355
legacy_luna_v070_sha256=df2244de46202513abd8451e3837122d47a7de82342e20853d06f7466c614295
legacy_high_v070_sha256=c4d09eaf837973d729eeaf05d022da97fd9349123d857852e78816906479a705
legacy_sol_v080_sha256=18cb3a5c08eb3f103f07626c944b9ba8978b20c5a706cf4579e07a5fded18e0a
legacy_sol_v080_crlf_sha256=4238b91b1e1dde1d93282a0bb4586361e8c3f0690c48397f98df04eccf42b384
# v0.10 角色仅允许按精确 LF/CRLF 指纹迁移，保留所有用户定制。
legacy_luna_v010_sha256=de0a29a94dd09db39738cee106ced36a076bd0ce5a86a4babde8468f48694016
legacy_luna_v010_crlf_sha256=3038e6aea67cb7b5d2deb2457fa8ff45f75870791654d0854b5779ddc0ca81e1
legacy_max_v010_sha256=c36d25cf9169b1be536aaaed743b69b78e5d86d2f694665031b6a3cc0d16cc15
legacy_max_v010_crlf_sha256=212ac8dd45f99f93d1c50c78fe3b38196934c628a4334624aa8db81b95330268
legacy_specialist_v010_sha256=1d28d5fd87c277699a43d2243a4ed79e94137a4431d228eeb28cbf2282f7c7c7
legacy_specialist_v010_crlf_sha256=a28ea02ba506942c1db5e1138d4520af4811e667ca8ab7495b59f6877554f245
legacy_sol_v010_sha256=83fa964b13e43f59794e857bf79856960c30dff3a000e805c9cf25f4b2111e2e
legacy_sol_v010_crlf_sha256=2d72970be77909adcfb941834744be620af93dd4d755c8f4e54a6c12da777829
luna_legacy_digests="$legacy_luna_sha256 $legacy_luna_v050_sha256 $legacy_luna_v060_sha256 $legacy_luna_v060_crlf_sha256 $legacy_luna_v070_sha256 $legacy_luna_v010_sha256 $legacy_luna_v010_crlf_sha256"
terra_legacy_digests="$legacy_terra_sha256 $legacy_terra_v050_sha256 $legacy_terra_v060_sha256 $legacy_terra_v060_crlf_sha256"
sol_legacy_digests="$legacy_sol_v060_sha256 $legacy_sol_v060_crlf_sha256 $legacy_sol_v080_sha256 $legacy_sol_v080_crlf_sha256 $legacy_sol_v010_sha256 $legacy_sol_v010_crlf_sha256"

max_legacy_digests="$legacy_max_v010_sha256 $legacy_max_v010_crlf_sha256"
specialist_legacy_digests="$legacy_specialist_v010_sha256 $legacy_specialist_v010_crlf_sha256"

preflight_failed=0
if path_exists "$target_dir"; then
  if [ -L "$target_dir" ] || [ ! -d "$target_dir" ]; then
    report_preflight_error "target directory is not a real directory: $target_dir"
  fi
fi

# 任务预检只比较选中角色的模板，不计算无关角色的历史指纹。
if [ "$check_only" -eq 1 ]; then
  for selected in luna-high luna-max terra-high sol; do
    role_selected "$selected" || continue
    case "$selected" in
      luna-high) template=$luna_template; destination=$luna_destination ;;
      luna-max) template=$max_template; destination=$max_destination ;;
      terra-high) template=$specialist_template; destination=$specialist_destination ;;
      sol) template=$sol_template; destination=$sol_destination ;;
    esac
    [ -f "$template" ] && [ ! -L "$template" ] ||
      fail "shipped template is missing or not a regular file: $template"
    if [ ! -f "$destination" ] || [ -L "$destination" ] || ! cmp -s "$template" "$destination"; then
      report_preflight_error "$selected does not match the current exact template: $destination"
    fi
  done
  # 历史别名的退役检查仅随相关角色执行，避免影响无关通道。
  if role_selected luna-max || role_selected terra-high; then
    if path_exists "$retired_high_destination"; then
      report_preflight_error "retired Luna High role is not absent: $retired_high_destination"
    fi
    if path_exists "$retired_terra_destination"; then
      report_preflight_error "retired Terra role is not absent: $retired_terra_destination"
    fi
  fi
  [ "$preflight_failed" -eq 0 ] || exit 1
  if [ -n "$check_roles" ]; then
    printf '%s\n' "CHECK PASSED: selected role templates exactly match $template_dir."
  else
    printf '%s\n' "CHECK PASSED: Luna High, Luna Max, Terra High, and Sol exactly match $template_dir."
  fi
  exit 0
fi

# 安装及迁移仍先检查全部目标，任一冲突都必须在写入前失败。
for template in "$luna_template" "$max_template" "$specialist_template" "$sol_template"; do
  [ -f "$template" ] && [ ! -L "$template" ] ||
    fail "shipped template is missing or not a regular file: $template"
done
luna_state=$(classify_current_or_legacy "$luna_destination" "$luna_template" "$luna_legacy_digests")
max_state=$(classify_current_or_legacy "$max_destination" "$max_template" "$max_legacy_digests")
specialist_state=$(classify_current_or_legacy "$specialist_destination" "$specialist_template" "$specialist_legacy_digests")
sol_state=$(classify_current_or_legacy "$sol_destination" "$sol_template" "$sol_legacy_digests")
retired_high_state=$(classify_retired "$retired_high_destination" "$legacy_high_v070_sha256")
retired_terra_state=$(classify_retired "$retired_terra_destination" "$terra_legacy_digests")

case "$luna_state" in
  current|legacy|missing) ;;
  *) report_preflight_error "Luna High destination is $luna_state and will not be replaced: $luna_destination" ;;
esac
case "$max_state" in
  current|legacy|missing) ;;
  *) report_preflight_error "Luna Max destination is $max_state and will not be replaced: $max_destination" ;;
esac
case "$specialist_state" in
  current|legacy|missing) ;;
  *) report_preflight_error "Terra High destination is $specialist_state and will not be replaced: $specialist_destination" ;;
esac
case "$sol_state" in
  current|legacy|missing) ;;
  *) report_preflight_error "Sol destination is $sol_state and will not be replaced: $sol_destination" ;;
esac
case "$retired_high_state" in
  legacy|missing) ;;
  *) report_preflight_error "retired Luna High destination is $retired_high_state and will not be removed: $retired_high_destination" ;;
esac
case "$retired_terra_state" in
  legacy|missing) ;;
  *) report_preflight_error "retired high-risk destination is $retired_terra_state and will not be removed: $retired_terra_destination" ;;
esac

[ "$preflight_failed" -eq 0 ] || exit 1


if [ ! -d "$target_dir" ]; then
  mkdir -p "$target_dir" || fail "could not create target directory: $target_dir"
fi
[ -d "$target_dir" ] && [ ! -L "$target_dir" ] ||
  fail "target directory changed after preflight: $target_dir"

same_state "Luna High" "$luna_state" "$(classify_current_or_legacy "$luna_destination" "$luna_template" "$luna_legacy_digests")"
same_state "Luna Max" "$max_state" "$(classify_current_or_legacy "$max_destination" "$max_template" "$max_legacy_digests")"
same_state "Terra High" "$specialist_state" "$(classify_current_or_legacy "$specialist_destination" "$specialist_template" "$specialist_legacy_digests")"
same_state Sol "$sol_state" "$(classify_current_or_legacy "$sol_destination" "$sol_template" "$sol_legacy_digests")"
same_state "retired Luna High role" "$retired_high_state" "$(classify_retired "$retired_high_destination" "$legacy_high_v070_sha256")"
same_state "retired high-risk role" "$retired_terra_state" "$(classify_retired "$retired_terra_destination" "$terra_legacy_digests")"

case "$luna_state" in
  missing) install_missing "$luna_template" "$luna_destination" ;;
  legacy) replace_legacy_role "Luna High" "$luna_template" "$luna_destination" "$luna_legacy_digests" ;;
  current) printf '%s\n' "ALREADY CURRENT: $luna_destination" ;;
esac

case "$max_state" in
  missing) install_missing "$max_template" "$max_destination" ;;
  legacy) replace_legacy_role "Luna Max" "$max_template" "$max_destination" "$max_legacy_digests" ;;
  current) printf '%s\n' "ALREADY CURRENT: $max_destination" ;;
esac

case "$sol_state" in
  missing) install_missing "$sol_template" "$sol_destination" ;;
  legacy) replace_legacy_role Sol "$sol_template" "$sol_destination" "$sol_legacy_digests" ;;
  current) printf '%s\n' "ALREADY CURRENT: $sol_destination" ;;
esac

case "$specialist_state" in
  missing) install_missing "$specialist_template" "$specialist_destination" ;;
  legacy) replace_legacy_role "Terra High" "$specialist_template" "$specialist_destination" "$specialist_legacy_digests" ;;
  current) printf '%s\n' "ALREADY CURRENT: $specialist_destination" ;;
esac

case "$retired_high_state" in
  legacy) retire_legacy_role "v0.7 Luna High role" "$retired_high_destination" "$legacy_high_v070_sha256" ;;
  missing) ;;
esac

case "$retired_terra_state" in
  legacy) retire_legacy_role "pre-v0.7 high-risk role" "$retired_terra_destination" "$terra_legacy_digests" ;;
  missing) ;;
esac

[ "$(classify_current_or_legacy "$luna_destination" "$luna_template" "$luna_legacy_digests")" = current ] ||
  fail "post-install exactness check failed: $luna_destination"
[ "$(classify_current_or_legacy "$max_destination" "$max_template" "$max_legacy_digests")" = current ] ||
  fail "post-install exactness check failed: $max_destination"
[ "$(classify_current_or_legacy "$specialist_destination" "$specialist_template" "$specialist_legacy_digests")" = current ] ||
  fail "post-install exactness check failed: $specialist_destination"
[ "$(classify_current_or_legacy "$sol_destination" "$sol_template" "$sol_legacy_digests")" = current ] ||
  fail "post-install exactness check failed: $sol_destination"
[ "$(classify_retired "$retired_high_destination" "$legacy_high_v070_sha256")" = missing ] ||
  fail "post-install retirement check failed: $retired_high_destination"
[ "$(classify_retired "$retired_terra_destination" "$terra_legacy_digests")" = missing ] ||
  fail "post-install retirement check failed: $retired_terra_destination"

printf '%s\n' "INSTALL PASSED: Luna High, Luna Max, Terra High, and Sol exactly match $template_dir."
