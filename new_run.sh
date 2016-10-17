#!/bin/bash

RUN=$1

if [ -z "$RUN" ]; then
    echo "Please specify a run name, such as '2015_11' or 'T1'."
    echo "Run names must be unique across all runs."
    exit 1
fi

if [ "$RUN" == "_base" ]; then
    echo "This run name is reserved.  Please choose another one."
    exit 1
fi

# Check the base files are pristine.
for i in course.xml policies/_base/policy.json; do
    if ! grep '{{ RUN }}' $i >/dev/null 2>&1; then
        echo "Please checkout pristine versions of course.xml and policy.json, and try again."
	exit 1
    fi
done

# Check if symlink is already there
if [ -e policies/$RUN ]; then
    # If it's a symlink, just remove it.
    if [ -L policies/$RUN ]; then
        rm policies/$RUN
    else
        echo "The policies directory, policies/$RUN, already exists.  Please move it out of the way and try again."
	exit 1
    fi
fi

# Check if target branch exists
if git rev-parse --verify run/$RUN >/dev/null 2>&1; then
    echo "The target git branch already exists.  Please delete it and try again."
    echo "You can do so with: "
    echo
    echo "git branch -d run/$RUN"
    exit 1
fi

# Create the new branch and check it out
git checkout -b run/$RUN

# Replace run name.
for i in \
    course.xml \
    chapter/*.xml \
    sequential/*.xml \
    static/markdown/*.md \
    policies/_base/policy.json
do
    sed -i "s/{{ RUN }}/$RUN/" $i
done

# Create symlink for policies
ln -sf _base policies/$RUN

# Git add the changed files.
for i in \
    course.xml \
    chapter/*.xml \
    sequential/*.xml \
    static/markdown/*.md \
    policies/_base/policy.json
do
    git add $i
done

# Git commit
git commit -m "New run: $RUN"

echo
echo "All done!  Don't forget to change start and end dates on policy.json"
echo "(you have to do so manually), then git-add this and any other changes"
echo "before commiting."
echo
echo "To push this new branch upstream, run:"
echo
echo "$ git push origin run/$RUN"
echo
echo "To switch back to master, run:"
echo
echo "$ git checkout master"
echo

exit 0
