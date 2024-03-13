#!/bin/sh

usage() {
  printf "build-image [-a|--alpine] <alpine version> [-s|--squid] <squid version>\n"
  printf " \n"
  printf " Builds an image of squid using the given versions of squid and alpine linux.\n"
  printf " If no versions are given, the latest version of alpine linux and squid 6.6-r0 are used.\n"
  printf " \n"
  printf " OPTIONS\n"
  printf "  -a --alpine\t\tthe version of alpine linux (optional)\n"
  printf "  -s --squid\t\tthe version of squid (optional)\n"
  printf "  -t --tag\t\ttag without the version for the new squid image (optional)\n"
  printf "  -v --verbose\t\texplain what is being done\n"
  printf "  -h --help\t\tprint this help\n"
  exit 1
}

TRUE=1
FALSE=0

verbose=$FALSE

while [ "$#" -gt 0 ]; do
  case "$1" in
    -a|--alpine) alpine="$2" shift ;;
    -s|--squid) squid="$2" shift ;;
    -t|--tag) tag="$2" shift ;;
    -v|--verbose) verbose=$TRUE;;
    -h|--help) usage ;;
            *) usage ;;
  esac
  shift
done

[ -z "$alpine" ] && alpine="latest"
[ -z "$squid" ] && squid="6.6-r0"
[ -z "$tag" ] && tag="gpjavierjob/alpine-squid"

echo -n "Pulling alpine ... "

if [ $verbose -eq $TRUE ]; then
  echo ""
  docker pull "alpine:$alpine"
  echo -n "... "
else
  docker pull -q "alpine:$alpine" > /dev/null
fi

if [ $? -gt 0 ]; then
  echo "Error on pulling Alpine."
  return 1
fi

echo "Pull done."

echo -n "Building squid image ... "

tag="$tag:$squid"
dockerfile_dir="$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")/alpine-squid"

if [ $verbose -eq $TRUE ]; then
  echo ""
  docker buildx build -t "$tag" --build-arg "ALPINE_VER=$alpine" --build-arg "SQUID_VER=$squid" "$dockerfile_dir"
  echo -n "... "
else
  docker buildx build -q -t "$tag" --build-arg "ALPINE_VER=$alpine" --build-arg "SQUID_VER=$squid" "$dockerfile_dir" > /dev/null 2>&1
fi

if [ $? -gt 0 ]; then
  echo "Error on building the image."
  return 1
fi

echo "Build done."
