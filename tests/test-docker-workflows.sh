#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dockerfile="$repo_root/Dockerfile"
plugin_workflows=(
	"$repo_root/.github/workflows/Docker-nocache.yml"
	"$repo_root/.github/workflows/UpdateDockerOnly.yml"
)
full_workflow="$repo_root/.github/workflows/docker-image.yml"
update_workflow="$repo_root/.github/workflows/Update check.yml"

die() {
	echo "$*" >&2
	exit 1
}

assert_contains() {
	local file="$1"
	local needle="$2"
	grep -F -- "$needle" "$file" >/dev/null || die "Expected '$needle' in ${file#$repo_root/}"
}

assert_not_contains() {
	local file="$1"
	local needle="$2"
	if grep -F -- "$needle" "$file" >/dev/null; then
		die "Did not expect '$needle' in ${file#$repo_root/}"
	fi
}

line_of() {
	local file="$1"
	local needle="$2"
	local match
	match="$(grep -nF -m1 -- "$needle" "$file")" || die "Expected '$needle' in ${file#$repo_root/}"
	printf '%s\n' "${match%%:*}"
}

assert_contains "$dockerfile" 'ARG L4D2_SOURCE_IMAGE=morzlee/l4d2:game-base'
assert_contains "$dockerfile" 'ARG COMPETITIVE_REF=master'
assert_contains "$dockerfile" 'ARG ANNE_REF=zonemod'
assert_contains "$dockerfile" 'fetch --depth 1 origin "$COMPETITIVE_REF"'
assert_contains "$dockerfile" 'config branch.master.merge refs/heads/master'
assert_contains "$dockerfile" 'FROM runtime_common AS game_base'
assert_contains "$dockerfile" 'FROM --platform=$IMAGE_PLATFORM ${L4D2_SOURCE_IMAGE} AS l4d2_source_image'
assert_contains "$dockerfile" 'FROM runtime_system AS install_game_image'
assert_contains "$dockerfile" 'FROM game_from_image_base AS game_from_image'
assert_contains "$dockerfile" 'FROM l4d2_source_image AS plugin_from_game_base'
assert_not_contains "$dockerfile" 'needupdate-plugins'

game_target_line="$(line_of "$dockerfile" 'FROM game_base AS game')"
first_plugin_copy_line="$(line_of "$dockerfile" 'COPY --chown=louis:louis --from=plugin_sources /home/louis/CompetitiveWithAnne')"
((first_plugin_copy_line > game_target_line)) || die 'Plugin layers must follow the game layer'

plugin_copy_count="$(grep -Fc -- 'COPY --chown=louis:louis --from=plugin_sources /home/louis/CompetitiveWithAnne' "$dockerfile" || true)"
[[ "$plugin_copy_count" == "4" ]] || die "Expected plugin copies in all final image targets"

for workflow in "${plugin_workflows[@]}"; do
	assert_contains "$workflow" 'target: plugin_from_game_base'
	assert_contains "$workflow" 'platforms: linux/amd64'
	assert_contains "$workflow" 'cache-from: type=registry,ref=morzlee/l4d2:buildcache-plugin'
	assert_contains "$workflow" 'L4D2_SOURCE_IMAGE=morzlee/l4d2:game-base'
	assert_contains "$workflow" 'COMPETITIVE_REF=${{ steps.plugin_refs.outputs.competitive_ref }}'
	assert_contains "$workflow" 'ANNE_REF=${{ steps.plugin_refs.outputs.anne_ref }}'
	assert_contains "$workflow" 'if: steps.game_base.outputs.exists != '\''true'\'''
	assert_contains "$workflow" 'target: game_from_image_base'
	assert_contains "$workflow" 'L4D2_SOURCE_IMAGE=morzlee/l4d2:latest'
	assert_contains "$workflow" 'run: bash tests/test-docker-workflows.sh'
	assert_not_contains "$workflow" 'date +%s'
	assert_not_contains "$workflow" 'NEEDUPDATE=bootstrap'
	assert_not_contains "$workflow" 'setup-qemu-action'
done

assert_contains "$full_workflow" 'target: game_base'
assert_contains "$full_workflow" 'tags: morzlee/l4d2:game-base'
assert_contains "$full_workflow" 'cache-from: type=registry,ref=morzlee/l4d2:buildcache-game'
assert_contains "$full_workflow" 'target: plugin_from_game_base'
assert_contains "$full_workflow" 'cache-from: type=registry,ref=morzlee/l4d2:buildcache-plugin'
assert_contains "$full_workflow" 'L4D2_SOURCE_IMAGE=morzlee/l4d2:game-base'
assert_contains "$full_workflow" 'run: bash tests/test-docker-workflows.sh'
assert_not_contains "$full_workflow" 'setup-qemu-action'

assert_contains "$update_workflow" 'competitive_ref=$(git -C "$RUNNER_TEMP/competitive" rev-parse HEAD)'
assert_contains "$update_workflow" 'anne_ref=$(git -C "$RUNNER_TEMP/anne" rev-parse HEAD)'
assert_contains "$update_workflow" 'event-type: plugin-update'
assert_contains "$update_workflow" '"competitive_ref":"${{ steps.getHash.outputs.competitive_ref }}"'
assert_contains "$update_workflow" '"anne_ref":"${{ steps.getHash.outputs.anne_ref }}"'

echo "Docker layering and workflow cache tests passed"
