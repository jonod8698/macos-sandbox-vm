#!/usr/bin/env bats

load 'bats-support/load'
load 'bats-assert/load'

@test "sandbox-vm exits on non-macos" {
  run bash ./sandbox-vm.sh -h
  [ "$status" -eq 1 ]
  assert_output --partial "only for macOS arm64"
}

@test "sandbox-atomicredteam help" {
  run bash ./sandbox-atomicredteam.sh -h
  [ "$status" -eq 1 ]
  assert_output --partial "Usage:"
}

@test "prepare.sh exits on non-macos" {
  run bash ./prepare.sh 2>/dev/null
  [ "$status" -eq 1 ]
  assert_output --partial "only for macOS arm64"
}


