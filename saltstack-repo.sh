
SALT_VERSION="2017.7.5"
USER_PASS=""
BASE_URL="https://xxxxxx.net/artifactory"

MAJOR_VERSION=$(echo $SALT_VERSION | awk -F. '{ print $1 "." $2 }')
REPO_NAME="rpm-saltstack-${SALT_VERSION}"
REPO_TEMPL="/tmp/repo_template.json"

cat > $REPO_TEMPL << "EOL"
{
  "key" : "${REPO_NAME}",
  "packageType" : "${PT}",
  "description" : "${REPO_NAME} desc",
  "notes" : "",
  "includesPattern" : "**/*",
  "excludesPattern" : "",
  "repoLayoutRef" : "simple-default",
  "enableComposerSupport" : false,
  "enableNuGetSupport" : false,
  "enableGemsSupport" : false,
  "enableNpmSupport" : false,
  "enableBowerSupport" : false,
  "enableCocoaPodsSupport" : false,
  "enableConanSupport" : false,
  "enableDebianSupport" : ${EDS},
  "debianTrivialLayout" : false,
  "enablePypiSupport" : false,
  "enablePuppetSupport" : false,
  "enableDockerSupport" : false,
  "dockerApiVersion" : "V2",
  "forceNugetAuthentication" : false,
  "enableVagrantSupport" : false,
  "enableGitLfsSupport" : false,
  "enableDistRepoSupport" : false,
  "checksumPolicyType" : "client-checksums",
  "handleReleases" : true,
  "handleSnapshots" : true,
  "maxUniqueSnapshots" : 0,
  "maxUniqueTags" : 0,
  "snapshotVersionBehavior" : "unique",
  "suppressPomConsistencyChecks" : true,
  "blackedOut" : false,
  "propertySets" : [ "artifactory" ],
  "archiveBrowsingEnabled" : false,
  "calculateYumMetadata" : false,
  "enableFileListsIndexing" : false,
  "yumRootDepth" : 3,
  "xrayIndex" : false,
  "enabledChefSupport" : false,
  "rclass" : "local"
}
EOL


for PT in "rpm" "debian"; do
  echo $PT
  if [ $PT == "rpm" ] ; then
    REPO_NAME="rpm-saltstack-${SALT_VERSION}"
    EDS=false
    SALTREPO_URL="http://repo.saltstack.com/yum/redhat/7/x86_64/${MAJOR_VERSION}/" #Better to use 'archive' 
    DIR_NAME="yum"
  else
    REPO_NAME="deb-saltstack-${SALT_VERSION}"
    EDS=true
    SALTREPO_URL="http://repo.saltstack.com/apt/ubuntu/16.04/amd64/${MAJOR_VERSION}/"
    DIR_NAME="apt"
  fi
  REPO_MFILE="/tmp/${REPO_NAME}.json"
  #Create
  RP=$(curl --write-out %{http_code} --silent --output /dev/null -u ${USER_PASS} -H "Accept: application/json" ${BASE_URL}/api/repositories/${REPO_NAME})

  if [ $RP -eq "400" ] ; then

    eval "cat <<EOF
$(<$REPO_TEMPL)
EOF" > $REPO_MFILE

    curl -kv -u ${USER_PASS} -H "Content-Type: application/json" -X PUT ${BASE_URL}/api/repositories/${REPO_NAME} --data-binary @${REPO_MFILE}

    wget -R *html* -r -np -nH --cut-dirs=0 ${SALTREPO_URL}
    tar czvf ${PT}.tar.gz ${DIR_NAME}

    #Upload
    curl -kv -u ${USER_PASS} -XPUT -H "X-Explode-Archive: true" ${BASE_URL}/${REPO_NAME}/ -T ${PT}.tar.gz
  else
    echo "Repo '${REPO_NAME}' is alsready exist on "
    #exit 1
  fi
done




