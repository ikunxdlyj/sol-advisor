#!/bin/sh
# Install Sol Advisor's shipped custom-agent templates without changing Codex config.

set -eu

usage() {
  cat <<'EOF'
Usage: install-agents.sh [--target-dir PATH] [--check] [--check-role ROLE ...]

Install Sol Advisor's three current GPT-6 custom-agent templates into the target
directory. Normal mode migrates only exact byte-matching historical templates and
retires superseded role names only when each file is byte-exact. It never
overwrites or removes a modified, nonregular, or symlinked destination.

Without --target-dir, the target is "$CODEX_HOME/agents" when CODEX_HOME is already
set, otherwise "$HOME/.codex/agents".

Options:
  --target-dir PATH  Explicit destination directory (absolute or relative).
  --check            Verify Luna High, Luna Max, and Sol exactly; do not create,
                     replace, or remove anything.
  --check-role ROLE  Verify only ROLE (luna-high, luna-max, or sol); repeatable and
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
  shasum -a 256 "$1" 2>/dev/null | awk 'NF >= 1 && length($1) == 64 { print $1; exit }'
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
      [ "$#" -ge 2 ] || fail "--check-role requires a role: luna-max, luna-high, or sol."
      case "$2" in
        luna-high|luna) selected_role=luna-high ;;
        luna-max|terra) selected_role=luna-max ;;
        sol) selected_role=sol ;;
        *) fail "unknown --check-role '$2'; expected luna-max, luna-high, or sol." ;;
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
sol_file=sol-advisor-sol-reviewer.toml
retired_high_file=sol-advisor-luna-high-implementer.toml
retired_terra_file=sol-advisor-terra-implementer.toml
luna_template=$template_dir/$luna_file
max_template=$template_dir/$max_file
sol_template=$template_dir/$sol_file
luna_destination=$target_dir/$luna_file
max_destination=$target_dir/$max_file
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
legacy_luna_v070_sha256=df2244de46202513abd8451e3837122d47a7de82342e20853d06f7466c614295
legacy_high_v070_sha256=c4d09eaf837973d729eeaf05d022da97fd9349123d857852e78816906479a705
luna_legacy_digests="$legacy_luna_sha256 $legacy_luna_v050_sha256 $legacy_luna_v060_sha256 $legacy_luna_v070_sha256"
terra_legacy_digests="$legacy_terra_sha256 $legacy_terra_v050_sha256 $legacy_terra_v060_sha256"
sol_legacy_digests=$legacy_sol_v060_sha256

for template in "$luna_template" "$max_template" "$sol_template"; do
  [ -f "$template" ] && [ ! -L "$template" ] ||
    fail "shipped template is missing or not a regular file: $template"
done

preflight_failed=0
if path_exists "$target_dir"; then
  if [ -L "$target_dir" ] || [ ! -d "$target_dir" ]; then
    report_preflight_error "target directory is not a real directory: $target_dir"
  fi
fi

luna_state=$(classify_current_or_legacy "$luna_destination" "$luna_template" "$luna_legacy_digests")
max_state=$(classify_current_or_legacy "$max_destination" "$max_template" '')
sol_state=$(classify_current_or_legacy "$sol_destination" "$sol_template" "$sol_legacy_digests")
retired_high_state=$(classify_retired "$retired_high_destination" "$legacy_high_v070_sha256")
retired_terra_state=$(classify_retired "$retired_terra_destination" "$terra_legacy_digests")

if [ "$check_only" -eq 1 ]; then
  if role_selected luna-high; then
    [ "$luna_state" = current ] ||
      report_preflight_error "Luna High template is $luna_state, not the current exact file: $luna_destination"
  fi
  if role_selected luna-max; then
    [ "$max_state" = current ] ||
      report_preflight_error "Luna Max template is $max_state, not the current exact file: $max_destination"
    [ "$retired_high_state" = missing ] ||
      report_preflight_error "retired Luna High role is $retired_high_state, not absent: $retired_high_destination"
    [ "$retired_terra_state" = missing ] ||
      report_preflight_error "retired Terra role is $retired_terra_state, not absent: $retired_terra_destination"
  fi
  if role_selected sol; then
    [ "$sol_state" = current ] ||
      report_preflight_error "Sol template is $sol_state, not the current exact file: $sol_destination"
  fi
else
  case "$luna_state" in
    current|legacy|missing) ;;
    *) report_preflight_error "Luna High destination is $luna_state and will not be replaced: $luna_destination" ;;
  esac
  case "$max_state" in
    current|missing) ;;
    *) report_preflight_error "Luna Max destination is $max_state and will not be replaced: $max_destination" ;;
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
fi

[ "$preflight_failed" -eq 0 ] || exit 1

if [ "$check_only" -eq 1 ]; then
  if [ -n "$check_roles" ]; then
    printf '%s\n' "CHECK PASSED: selected role templates exactly match $template_dir."
  else
    printf '%s\n' "CHECK PASSED: Luna High, Luna Max, and Sol exactly match $template_dir."
  fi
  exit 0
fi

if [ ! -d "$target_dir" ]; then
  mkdir -p "$target_dir" || fail "could not create target directory: $target_dir"
fi
[ -d "$target_dir" ] && [ ! -L "$target_dir" ] ||
  fail "target directory changed after preflight: $target_dir"

same_state "Luna High" "$luna_state" "$(classify_current_or_legacy "$luna_destination" "$luna_template" "$luna_legacy_digests")"
same_state "Luna Max" "$max_state" "$(classify_current_or_legacy "$max_destination" "$max_template" '')"
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
  current) printf '%s\n' "ALREADY CURRENT: $max_destination" ;;
esac

case "$sol_state" in
  missing) install_missing "$sol_template" "$sol_destination" ;;
  legacy) replace_legacy_role Sol "$sol_template" "$sol_destination" "$sol_legacy_digests" ;;
  current) printf '%s\n' "ALREADY CURRENT: $sol_destination" ;;
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
[ "$(classify_current_or_legacy "$max_destination" "$max_template" '')" = current ] ||
  fail "post-install exactness check failed: $max_destination"
[ "$(classify_current_or_legacy "$sol_destination" "$sol_template" "$sol_legacy_digests")" = current ] ||
  fail "post-install exactness check failed: $sol_destination"
[ "$(classify_retired "$retired_high_destination" "$legacy_high_v070_sha256")" = missing ] ||
  fail "post-install retirement check failed: $retired_high_destination"
[ "$(classify_retired "$retired_terra_destination" "$terra_legacy_digests")" = missing ] ||
  fail "post-install retirement check failed: $retired_terra_destination"

printf '%s\n' "INSTALL PASSED: Luna High, Luna Max, and Sol exactly match $template_dir."
