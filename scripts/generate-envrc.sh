#!/usr/bin/env bash
set -euo pipefail

function print_envrc {
  if [ -n "${aws_profile_value:-}" ]; then
    aws_profile_line="export AWS_PROFILE=${aws_profile_value}"
  else
	  aws_profile_line="# export AWS_PROFILE="
  fi

  if [ -n "${aws_region_value:-}" ]; then
    aws_region_line="export AWS_REGION=${aws_region_value}"
  else
    aws_region_line="# export AWS_REGION="
  fi

  if [ -n "${gcp_project_value:-}" ]; then
    gcp_project_line="export GCP_PROJECT=${gcp_project_value}"
  else
    gcp_project_line="# export GCP_PROJECT="
  fi

  cat <<-EOF
	${gcp_project_line}
	${aws_profile_line}
	${aws_region_line}

	# (optional) By default, dirname is used as cluster name
	# export K8S_CLUSTER=

	envrc_common=\$(cd .. && find_up .envrc-common)
	[ -n "\$envrc_common" ] && source \$envrc_common
	EOF
}

function generate_envrc {
  printf -- '- %-50s' "$(echo $dir | sed 's|^\./||') "

  target_dir="$1"
  target_file="$target_dir/.envrc"
  if [[ -e $target_file && -z "${opt_overwrite:-}" ]]; then
    echo "skip (already exists)"
  else
    print_envrc > $target_file
    echo ok
  fi

  if [ -n "${opt_direnv_allow:-}" ]; then
    (cd $target_dir && direnv allow)
  fi
}

function process_params {
  while getopts af opt; do
    case $opt in
      # 既存の .envrc への上書きを許可する
      f) confirm "Overwrite all .envrc files?" || continue
         opt_overwrite=1     ;;
      # 全ディレクトリで direnv allow する
      a) opt_direnv_allow=1  ;;
    esac
  done

  # 環境変数 AWS_PROFILE/AWS_REGION/GCP_PROJECT があればその値を envrc にセットする
  if [ -n "${AWS_PROFILE:-}" ]; then
    if confirm "Found AWS_PROFILE=${AWS_PROFILE} in this session. Do you want to set in .envrc?"; then
      aws_profile_value="$AWS_PROFILE"
    fi
  fi

  if [ -n "${AWS_REGION:-}" ]; then
    if confirm "Found AWS_REGION=${AWS_REGION} in this session. Do you want to set in .envrc?"; then
      aws_region_value="$AWS_REGION"
    fi
  fi

  if [ -n "${GCP_PROJECT:-}" ]; then
    if confirm "Found GCP_PROJECT=${GCP_PROJECT} in this session. Do you want to set in .envrc?"; then
      gcp_project_value="$GCP_PROJECT"
    fi
  fi

}

function confirm {
  MSG=$1
  while :; do
    echo -n "${MSG} [y/n]: " >&2
    read ans
    case $ans in
      "")                                 continue ;;
      "y" | "Y" | "yes" | "Yes" | "YES" ) return 0 ;;
      *                                 ) return 1 ;;
    esac
  done
}

function main {
  script_dir=$(realpath $(dirname $0))

  process_params "$@"

  declare -a workloads_dir
  : ${overlays_dir:=${script_dir}/../manifests/overlays}
  overlays_dir=$(realpath ${overlays_dir})

  (
    cd $overlays_dir
    : ${depth:=1}
    workloads_dir=$(find . -mindepth ${depth} -maxdepth ${depth} -type d)

    for dir in ${workloads_dir[@]}; do
      generate_envrc $dir
    done
  )
}

main "$@"
