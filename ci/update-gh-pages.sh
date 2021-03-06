#!/bin/sh
set -ex

# ------------------------------------------------------------------------------
# This script is supposed to be called from Travis continuous integration server
#
# It will update the gh.pages branch of GeoExt with various artifacts created
# in the previous step
# ------------------------------------------------------------------------------

# Load variables and the 'running-on-travis'-check
. $TRAVIS_BUILD_DIR/ci/shared.sh

if [ $TRAVIS_PULL_REQUEST != "false" ]; then
    # Dont build anything for PR requests, only for merges
    return 0;
fi

if [ $TRAVIS_BRANCH != "master" ]; then
    # only update when the target branch is master
    return 0;
fi

# default is master…
SUB_FOLDER_NAME=$TRAVIS_BRANCH;
DOC_SUFFIX="-dev"

if [ $TRAVIS_TAG != "" ]; then
    # … but if we are building for a tag, let's use this as folder name
    SUB_FOLDER_NAME=$TRAVIS_TAG
    DOC_SUFFIX=""
fi

DOCS_DIR=$SUB_FOLDER_NAME/docs
DOCS_W_EXT_DIR=$SUB_FOLDER_NAME/docs-w-ext

RAW_CP_DIRS="examples resources src"

ORIGINAL_AUTHOR_NAME=$(git show -s --format="%aN" $TRAVIS_COMMIT)
ORIGINAL_AUTHOR_EMAIL=$(git show -s --format="%ae" $TRAVIS_COMMIT)

GH_PAGES_BRANCH=gh-pages
GH_PAGES_REPO_FROM_SLUG="github.com/$TRAVIS_REPO_SLUG.git"
GH_PAGES_REPO="https://$GH_PAGES_REPO_FROM_SLUG"
GH_PAGES_REPO_AUTHENTICATED="https://$GH_TOKEN@$GH_PAGES_REPO_FROM_SLUG"
GH_PAGES_DIR=/tmp/geoext3-gh-pages
GH_PAGES_COMMIT_MSG=$(cat <<EOF
Update resources on gh-pages branch

This commit was autogenerated by the 'update-gh-pages.sh' script.
EOF
)

git config --global user.name "$ORIGINAL_AUTHOR_NAME"
git config --global user.email "$ORIGINAL_AUTHOR_EMAIL"


git clone --branch $GH_PAGES_BRANCH $GH_PAGES_REPO $GH_PAGES_DIR

cd $GH_PAGES_DIR


# 1. Update GeoExt package
mkdir -p cmd/pkgs/$GEOEXT_PACKAGE_NAME
rm -Rf cmd/pkgs/$GEOEXT_PACKAGE_NAME/$GEOEXT_PACKAGE_VERSION
cp -r $INSTALL_DIR/../repo/pkgs/$GEOEXT_PACKAGE_NAME/$GEOEXT_PACKAGE_VERSION cmd/pkgs/$GEOEXT_PACKAGE_NAME
# TODO the files catalog.json should better be updated, instead of overwritten…
cp $INSTALL_DIR/../repo/pkgs/catalog.json cmd/pkgs/
cp $INSTALL_DIR/../repo/pkgs/$GEOEXT_PACKAGE_NAME/catalog.json cmd/pkgs/$GEOEXT_PACKAGE_NAME

# 2.
# 2.1 examples, resources & src copied from repo
for RAW_CP_DIR in $RAW_CP_DIRS
do
    mkdir -p $SUB_FOLDER_NAME/$RAW_CP_DIR
    rm -Rf $SUB_FOLDER_NAME/$RAW_CP_DIR/*
    cp -r $TRAVIS_BUILD_DIR/$RAW_CP_DIR/* $SUB_FOLDER_NAME/$RAW_CP_DIR
done

# 2.2 copy created resources from build process
cp $GEOEXT_IN_SENCHA_WS_FOLDER/build/$GEOEXT_PACKAGE_NAME.js $SUB_FOLDER_NAME
cp $GEOEXT_IN_SENCHA_WS_FOLDER/build/$GEOEXT_PACKAGE_NAME-debug.js $SUB_FOLDER_NAME


# 3. Update the API docs
# 3.1 … without ExtJS
# mkdir -p $DOCS_DIR # for the API-docs without ExtJS classes
# rm -Rf $DOCS_DIR/* # remove any content from previous runs
# jsduck \
#     --title="$GEOEXT_PACKAGE_NAME $GEOEXT_PACKAGE_VERSION$DOC_SUFFIX Documentation" \
#     --output="$DOCS_DIR/" \
#     --eg-iframe=$TRAVIS_BUILD_DIR/docresources/eg-iframe.html \
#     $TRAVIS_BUILD_DIR/src/

# 3.2 … with ExtJS
# mkdir -p $DOCS_W_EXT_DIR # for the API-docs without ExtJS classes
# rm -Rf $DOCS_W_EXT_DIR/* # remove any content from previous runs
# jsduck \
#     --title="$GEOEXT_PACKAGE_NAME $GEOEXT_PACKAGE_VERSION$DOC_SUFFIX Documentation (incl. ExtJS classes)" \
#     --output="$DOCS_W_EXT_DIR/" \
#     --eg-iframe=$TRAVIS_BUILD_DIR/docresources/eg-iframe.html \
#     "$DOWN_DIR/ext-$SENCHA_EXTJS_VERSION/packages/core/src" \
#     "$DOWN_DIR/ext-$SENCHA_EXTJS_VERSION/classic/classic/src" \
#     $TRAVIS_BUILD_DIR/src/


# 4. done.

# Next: add, commit and push
git add .
git commit -m "$GH_PAGES_COMMIT_MSG"
git push --quiet $GH_PAGES_REPO_AUTHENTICATED $GH_PAGES_BRANCH

# Cleanup
rm -Rf $GH_PAGES_DIR
