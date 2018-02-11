#!/bin/bash
#
# Copyright 2015-2018 Martin Goellnitz
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

CMD=$1
ISSUES=$2
DIR=`dirname $0`
CWD=`pwd`

. $DIR/trackdown-lib.sh

# usage command
if [ -z "$CMD" ] ; then

  # see encodeMessage task in build script
  MYNAME=`basename $0`
MSG=$(echo -e H4sICAMLaVoCA3VzYWdlLXRlbXBsYXRlLnR4dACVlT1z2zAMhnf/CmyN79xk79jmrtchU9IplwGi \
YIsRRbL8kM/99QVISk4a59pMPhFfzwsC9M+IB/qy2Xy7u4XgsJ/Qw6NyxpBK2lnYa0NPGwAftE2L \
R3U3EeaLvkbHBDrGTBH2LsBMIYp9rnHK+dM7kcWUBgLrUgtGYy7mguQASyBYnAjm66mv+SdtCR4n \
evon3HHQagAMBBOGkXrJ2VFJUFM1v3fzCJxnVJs0Lpg1Mke6GBYpZQ/KOGYUPSUGUkA1anuAK+fF \
nfOe4KjTwI2w0NMes0klx7al9z0m4nzPmTHqFwTyLurkwqkVYDnSTMNG9jroxA2eJv4ZnBubQqsT \
p5Gfv1mkvrbw/ccDMOgdBZWDyOwCWjUsvQ7BBdF1sqoSB5q1y5EFVK1rvgljogBXzGGw27FjL53e \
CdiQ+eDgDrF8Ee7A6xGV6wk+gyXqIzz/atoDTdxyUKDBC3qhXg5ZH9qejdy3atEVy2PgMREAL7bm \
X/mFLrocFLEOhpxqocol/jCuV9cOz4E+uGe+ZHHbgztaruBqyYOeyQKyEjrBCFeLDpY0o5HBWm6W \
L6rcWL9mO7n8iedS2+3Kwk3jLLye+ekljRxformEIK1pIR3yhOZgIJ/BtkyWF6goVNX5mttaMTqd \
uqxGkgJ5pTifvgsis847EV6Va9L42t8KO8+CTN86DR9SyjluSoqbNf7/ZC/uy8CVQS2MZ9HL6UeI \
lpiLFLVYTJhy5Cr3gzvyrmna8xRw+yYsDwl2Lqey1m8WU0JJplCsdfhfvEBfy9pKxK0OfMbPRKvI \
qyv1+GcIzurfVBK0DXnxqBRVYnqQlb7lWV8eyKKt/XvsXzHxB3Nu/gDG2vvsZwYAAA==)
  echo $MSG|sed -e 's/\ /\n/g'|base64 -d|gunzip -c|sed -e s/CMD/$MYNAME/g
  exit

fi


windUp trackdown
TDBASE=`pwd`
# At least try to find a reference base directory from DVCS
if [ ! -f .trackdown/config ] ; then
  cd $CWD
  windUp hg
  if [ ! -d .hg ] ; then
    cd $CWD
    windUp git
  fi
fi
TDBASE=`pwd`
VCS=`test -d .hg && echo hg || echo git`
TDCONFIG=$TDBASE/.trackdown/config
echo "TrackDown-$VCS: base directory $TDBASE"
cd $CWD
if [ "$VCS" == "git" ] ; then
  REMOTE=`git remote get-url origin|cut -d '@' -f 2|sed -e 's/[a-z]+:\/\///g'|sed -e 's/.git$//g'|sed -e 's/:/\//g'`
fi
if [ "$VCS" == "hg" ] ; then
  REMOTE=`hg paths default|cut -d '@' -f 2|sed -e 's/[a-z]+:\/\///g'|sed -e 's/.git$//g'|sed -e 's/:/\//g'`
fi
if [ ! -z "$REMOTE" ] ; then
  CASE=`echo $REMOTE|cut -d '/' -f 1`
  REMOTEUSER=`echo $REMOTE|cut -d '/' -f 2`
  REMOTEPROJECT=`echo $REMOTE|cut -d '/' -f 3`
  test ! -z "$REMOTE" && echo "Remote system is $CASE with project \"$REMOTEPROJECT\" and user $REMOTEUSER"
fi

# ls command to list potential issues in the collection for a certain release
if [ "$CMD" = "ls" ] ; then

  # Location of the issues file
  ISSUES=$3
  discoverIssues
  grep -B2 "^\*$2\*" $ISSUES|grep "^\#\#\ "|sed -e 's/^\#\#\ /* /g'

fi


# command to list my issues in the collection
if [ "$CMD" = "mine" ] ; then

  discoverIssues
  if [ -z "$ME" ] ; then
    ME=`grep me= $TDCONFIG|cut -d '=' -f 2`
  fi
  if [ -z "$ME" ] ; then
    ME="$USER"
  fi
  grep -B2 "Currently.assigned.to...$ME" $ISSUES|grep "^\#\#\ "|sed -e 's/^\#\#\ /* /g'

fi


# roadmap command to pretty print a roadmap
if [ "$CMD" = "roadmap" ] ; then

  # Location of the issues file
  discoverIssues
  roadmap

fi


# issues command to list all potential issues in the collection
if [ "$CMD" = "issues" ] ; then

  discoverIssues
  grep "^\#\#\ " $ISSUES | sed -e "s/^##\ /- /g"

fi


# copy all issues for a given milestore to a separate file
if [ "$CMD" = "copy" ] ; then

  # Location of the issues file
  ISSUES=$3
  discoverIssues
  ISSUEDIR=`dirname $ISSUES`
  LINES=`cat $ISSUES|wc -l`
  MILESTONE=$ISSUEDIR/$2
  echo "# Issues resolved in $2" > "$MILESTONE.md"
  echo "" >> "$MILESTONE.md"
  TOTALSIZE=0
  COPY=$ISSUEDIR/$2-issues.md
  cp $ISSUES $COPY
  for START in `grep -n -B2 "^\*$2\*" $ISSUES|grep -e-\#\#\ |cut -d '-' -f 1` ; do 
    REST=$[ $LINES - $START + 1 ]
    SIZE=`tail -$REST $COPY|grep -n ^\#\#\ |head -2|tail -1|cut -d ':' -f 1`
    # tail -$REST $ISSUES|head -1
    # echo "Starting at line $START with $SIZE lines."
    if [ $SIZE = 1 ] ; then
      tail -$REST $COPY >> "$MILESTONE.md"
    else 
      tail -$REST $COPY | head -$[ $SIZE - 1 ] >> "$MILESTONE.md"
    fi
    CSTART=$[ $START - $TOTALSIZE ]
    # tail -$REST $COPY|head -1
    # echo "Starting at line $CSTART with $SIZE lines."
    CUT=`date +%s%N`.md
    head -$[ $CSTART - 1 ] $COPY >$CUT
    tail -$[ $REST - $SIZE + 1 ] $COPY >>$CUT
    mv $CUT $COPY
    TOTALSIZE=$[ $TOTALSIZE + $SIZE - 1 ]
  done

fi


# use command
if [ "$CMD" = "use" ] ; then

  if [ -f $TDCONFIG ] ; then
    echo "Project already initialized for trackdown use."
    exit
  fi
  if [ -d $TDBASE/.git ] ; then
    rm -f $TDBASE/.git/hooks/post-commit
    ln -s $DIR/trackdown-hook.sh $TDBASE/.git/hooks/post-commit
    ln -s $DIR/trackdown-lib.sh $TDBASE/.git/hooks/
    test ! -d $TDBASE/.trackdown && mkdir $TDBASE/.trackdown
    if [ -z "$ISSUES" ] ; then
      if [ `(git branch -r;git branch -l)|grep trackdown|wc -l` = 0 ] ; then
        echo "GIT repository doesn't contain a trackdown branch. Did you issue the init command? Exiting."
        exit
      fi
      ISSUES=".git/trackdown/issues.md"
      NAME=`git config -l|grep user.name|cut -d '=' -f 2`
      MAIL=`git config -l|grep user.email|cut -d '=' -f 2`
      cd $TDBASE
      echo "prepare local"
      test -z `git branch |grep trackdown|sed -e 's/\ /_/g'` && git branch trackdown
      git branch --set-upstream-to=origin/trackdown trackdown
      REMOTE=`git remote get-url origin`
      if [ -z "$REMOTE" ] ; then
        REMOTE=".."
      fi
      cd .git
      # git clone --single-branch --branch trackdown .. trackdown
      # git clone --branch trackdown .. trackdown
      git clone --branch trackdown $REMOTE trackdown
      cd trackdown
      git config --local push.default simple
      git config --local user.email "$MAIL"
      git config --local user.name "$NAME"
      # git remote remove origin
      # git remote add origin $REMOTE
      # git fetch
      # git branch --set-upstream-to=origin/trackdown trackdown
      # git rebase
      cd ../..
      echo "autocommit=true" > $TDCONFIG
      echo "autopush=false" >> $TDCONFIG
    else
      echo "autocommit=false" > $TDCONFIG
      echo "autopush=false" >> $TDCONFIG
    fi

    REMOTE=`git remote get-url origin|cut -d '@' -f 2|sed -e 's/[a-z]+:\/\///g'|sed -e 's/.git$//g'|sed -e 's/:/\//g'`
    CASE=`echo $REMOTE|cut -d '/' -f 1`
    test ! -z "$REMOTE" && echo "Remote system is $CASE."
    if [ "$CASE" = "github.com" ] ; then
      echo "Discovered github remote"
      echo "prefix=https://$REMOTE/commit/" >> $TDCONFIG
    fi
    if [ "$CASE" = "v2.pikacode.com" ] ; then
      echo "Discovered pikacode gogs remote"
      echo "prefix=https://$REMOTE/commit/" >> $TDCONFIG
    fi
    if [ "$CASE" = "bitbucket.org" ] ; then
      echo "Discovered bitbucket.org remote"
      echo "prefix=https://$REMOTE/commits/" >> $TDCONFIG
    fi
  fi
  if [ -d $TDBASE/.hg ] ; then
    test ! -d .trackdown && mkdir .trackdown
    if [ -z "$ISSUES" ] ; then
      if [ `hg branches|grep trackdown|wc -l` = 0 ] ; then
        echo "Mercurial repository missing trackdown branch. Did you issue the init command? Exiting."
        exit
      fi
      ISSUES=".hg/trackdown/issues.md"
      cd $TDBASE/.hg
      hg clone --branch trackdown .. trackdown
      test -f hgrc && grep username hgrc >>trackdown/.hg/hgrc
      cd ..
      echo "autocommit=true" > $TDCONFIG
      echo "autopush=true" >> $TDCONFIG
    else
      echo "autocommit=false" > $TDCONFIG
      echo "autopush=false" >> $TDCONFIG
    fi
    echo "[hooks]" >> .hg/hgrc
    echo "commit=$DIR/trackdown-hook.sh" >> .hg/hgrc
    cd $CWD

    REMOTE=`hg paths|grep "default ="|cut -d '=' -f 2|cut -d ' ' -f 2-100|cut -d '@' -f 2|sed -e 's/[a-z]+:\/\///g'`
    CASE=`echo $REMOTE|cut -d '/' -f 1`
    echo "Remote system is $CASE."
    if [ "$CASE" = "bitbucket.org" ] ; then
      echo "Discovered bitbucket.org remote"
      echo "prefix=https://$REMOTE/commits/" >> $TDCONFIG
    fi

  fi
  if [ -f $TDCONFIG ] ; then
    echo "location=$ISSUES" >> $TDCONFIG
    ID=`dirname $TDBASE/$ISSUES`
    cd $TDBASE
    ignoreFileHelper
    if [ "$TDBASE" != "$ID" ] ; then
      ln -sf $ISSUES issues.md
      ln -sf `dirname $ISSUES`/roadmap.md roadmap.md
      CHECK=`grep -s roadmap.md $IGNOREFILE|wc -l`
      if [ $CHECK = 0 ] ; then
       echo "${IFBEGIN}roadmap.md${IFEND}" >> $IGNOREFILE
      fi
    fi
    if [ -h issues.md ] ; then
      CHECK=`grep issues.md $IGNOREFILE|wc -l`
      if [ $CHECK = 0 ] ; then
        echo "${IFBEGIN}issues.md${IFEND}" >> $IGNOREFILE
      fi
    fi
    cd $CWD
  else
    echo "Could not use trackdown in this repository due to missing DCVS (git/hg)."
  fi

fi


# update command to use the latest git post commit hook
if [ "$CMD" = "update" ] ; then

  checkTrackdown
  if [ -d $TDBASE/.git ] ; then
    TYPE=`grep mirror.type= $TDCONFIG|cut -d '=' -f 2`
    if [ -z $TYPE ] ; then
      rm -f $TDBASE/.git/hooks/post-commit
      rm -f $TDBASE/.git/hooks/trackdown-lib.sh
      ln -s $DIR/trackdown-hook.sh $TDBASE/.git/hooks/post-commit
      ln -s $DIR/trackdown-lib.sh $TDBASE/.git/hooks/
      chmod 755 $TDBASE/.git/hooks/post-commit
    else
      echo "This repository is set up as a mirror - no hoook update needed."
    fi
  else
    echo "This is no GIT repository. Exiting."
  fi

fi


#  issue collection and roadmap status command
if [ "$CMD" = "status" ] ; then

  discoverIssues
  DIR=`dirname $ISSUES`
  if [ -d $DIR/.git ] ; then
    (cd $DIR ; git diff)
  else
    if [ -d $DIR/.hg ] ; then
      (cd $DIR ; hg status)
    else
      (cd $DIR ; ls -l *.md)
    fi
  fi

fi


#  remote vcs sync command
if [ "$CMD" = "sync" ] ; then

  discoverIssues
  DIR=`dirname $ISSUES`
  if [ -d $DIR/.git ] ; then
    if [ `cd $DIR ; git branch -l|grep ^*|cut -d ' ' -f 2` != "trackdown" ] ; then
      echo "Not working on a special trackdown branch. Exiting."
      exit
    fi
    echo "fetch"
    (cd $DIR ; git fetch)
    echo "stash"
    (cd $DIR ; git stash)
    echo "rebase"
    (cd $DIR ; git rebase)
    echo "apply"
    (cd $DIR ; git stash apply)
    roadmap >$DIR/roadmap.md
    echo "commit"
    (cd $DIR ; git commit -m "Issue collection and roadmap update" $ISSUES roadmap.md)
    echo "push"
    (cd $DIR ; git gc ; git push)
  fi
  if [ -d $DIR/.hg ] ; then
    if [ `cd $DIR ; hg branch` != "trackdown" ] ; then
      echo "Not working on a special trackdown branch. Exiting."
      exit
    fi
    (cd $DIR ; hg pull)
    (cd $DIR ; hg update trackdown)
    roadmap >$DIR/roadmap.md
    (cd $DIR ; hg commit -m "Issue collection and roadmap update" $ISSUES roadmap.md)
    (cd $DIR ; hg push)
  fi

fi


# init command
if [ "$CMD" = "init" ] ; then

  if [ -d $TDBASE/.git ] ; then
    cd $TDBASE
    if [ `git log|wc -l` = 0 ] ; then
      echo "GIT repository missing commits. Exiting."
      exit
    fi
    if [ `(git branch -r;git branch -l)|sed -e s/^.\ //g|grep trackdown|wc -l` != 0 ] ; then
      echo "TrackDown branch already present. Exiting."
      exit
    fi
    git stash
    BRANCH=`git branch|grep '*'|cut -d ' ' -f 2`
    git checkout --orphan trackdown
    git rm -rf .
    echo "# Issues" > issues.md
    echo "# Roadmap" > roadmap.md
    git add -f issues.md roadmap.md
    git commit -m "Empty issues collection" issues.md roadmap.md
    git checkout issues.md roadmap.md
    git checkout $BRANCH
    git stash apply
    cd $CWD
    exit
  fi
  if [ -d .hg ] ; then
    cd $TDBASE
    if [ `hg log|wc -l` = 0 ] ; then
      echo "Mercurial repository missing commits. Exiting."
      exit
    fi
    if [ `hg branches|grep trackdown|wc -l` != 0 ] ; then
      echo "TrackDown branch already present. Exiting."
      exit
    fi
    BRANCH=`hg branch`
    hg update -r 0
    hg branch trackdown
    hg rm -f .
    echo "# Issues" > issues.md
    echo "# Roadmap" > roadmap.md
    hg add issues.md roadmap.md
    hg commit -m "Empty issues collection"
    hg push --new-branch
    hg update $BRANCH
    cd $CWD
    exit
  fi

  echo "Coud not initialize DVCS based tooling. No DCVS (git/hg) repository found."

fi


# command to mirror the issue collection file from a remote system and calculate roadmap accordingly
if [ "$CMD" = "mirror" ] ; then
 
  checkTrackdown
  TYPE=`grep mirror.type= $TDCONFIG|cut -d '=' -f 2`
  bailOnZero "No mirror setup done for this repository." $TYPE
  unset ISSUES
  discoverIssues
  checkJq
  EXPORT=${2:-"/tmp/issues.json"}
  if [ $TYPE = "gitlab" ] ; then
    URL=`grep gitlab.url= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gitlab source url configured. Did you setup gitlab mirroring?" $URL
    TOKEN=`grep gitlab.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gitlab api token configured. Did you setup gitlab mirroring?" $TOKEN
    PROJECT=`grep gitlab.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gitlab project. Did you setup gitlab mirroring?" $PROJECT
    URL="${URL}/api/v3/projects/$PROJECT/issues"
    PAGES=`curl -D - -X HEAD -H "PRIVATE-TOKEN: $TOKEN" "$URL?per_page=100" 2> /dev/null|grep X-Total-Pages|sed -e 's/X.Total.Pages..\([0-9]*\).*/\1/g'`
    echo "$PAGES chunks of issues"
    issueCollectionHeader "Issues"
    PAGE="1"
    while [ "$PAGE" -le "$PAGES" ] ; do
      echo "Chunk $PAGE"
      curl -H "PRIVATE-TOKEN: $TOKEN" "$URL?per_page=100&page=$PAGE" 2> /dev/null >$EXPORT
      checkExport $EXPORT
      for id in `jq  -c '.[]|.id' $EXPORT` ; do
        echo "" >>$ISSUES
        echo "" >>$ISSUES
        TITLE=`jq  -c '.[]|select(.id == '$id')|.title' $EXPORT|sed -e 's/\\\"/\`/g'|sed -e 's/"//g'`
        IID=`jq  -c '.[]|select(.id == '$id')|.iid' $EXPORT|sed -e 's/"//g'`
        STATE=`jq  -c '.[]|select(.id == '$id')|.state' $EXPORT|sed -e 's/"//g'`
        s=`echo $STATE|sed -e 's/opened/in progress/g'|sed -e 's/closed/resolved/g'`
        MILESTONE=`jq  -c '.[]|select(.id == '$id')|.milestone' $EXPORT|sed -e 's/null/No Milestone/g'|sed -e 's/.*title...\([a-zA-Z0-9\ _]*\).*"./\1/g'`
        ASSIGNEE=`jq  -c '.[]|select(.id == '$id')|.assignee' $EXPORT|sed -e 's/.*name...\(.*\)","username...\([a-zA-Z0-9\.]*\).*/\1 (\2)/g'`
        echo "## $IID $TITLE ($s)"  >>$ISSUES
        echo "" >>$ISSUES
        echo -n "*${MILESTONE}*"  >>$ISSUES
        LABELS=`jq  -c '.[]|select(.id == '$id')|.labels' $EXPORT`
        if [ ! "$LABELS" = "[]" ] ; then
          echo -n " $LABELS"|sed -e 's/"/\`/g'|sed -e 's/,/][/g' >>$ISSUES
        fi
        if [ "$ASSIGNEE" != "null" ] ; then
          echo -n " - Currently assigned to: \`$ASSIGNEE\`" >>$ISSUES
        fi
        echo "" >>$ISSUES
        AUTHOR=`jq  -c '.[]|select(.id == '$id')|.author' $EXPORT|sed -e 's/.*name...\(.*\)","username.*/\1/g'`
        echo "" >>$ISSUES
        if [ "$AUTHOR" != "null" ] ; then
          echo -n "Author: \`$AUTHOR\` " >>$ISSUES
        fi
        echo "GitLab ID $id" >>$ISSUES
        DESCRIPTION=`jq  -c '.[]|select(.id == '$id')|.description' $EXPORT`
        if [ "$DESCRIPTION" != "null" ] ; then
          echo "" >>$ISSUES
          echo "$DESCRIPTION" |sed -e 's/\\"/\`/g'|sed -e 's/"//g'|sed -e 's/\\r\\n/\n&/g'|sed -e 's/\\r\\n//g'|sed -e 's/\\n/\n/g' >>$ISSUES
        fi
      done
      PAGE=$[ $PAGE + 1 ]
    done
  fi

  if [ $TYPE = "github" ] ; then
    OWNER=`grep github.owner= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No github repository owner configured. Did you setup github mirroring?" $OWNER
    TOKEN=`grep github.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No github api token configured. Did you setup github mirroring?" $TOKEN
    PROJECT=`grep github.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No github project. Did you setup github mirroring?" $PROJECT
    URL="https://api.github.com/repos/${OWNER}/${PROJECT}/issues?state=all"
    curl -H "Authorization: token $TOKEN" $URL 2> /dev/null >$EXPORT
    checkExport $EXPORT
    RESULT=`jq '.message?' $EXPORT`
    if [ ! -z "$RESULT" ] ; then
      echo "Cannot mirror issues for github project ${OWNER}/${PROJECT}: ${RESULT}"
      exit
    fi
    issueCollectionHeader "Issues"
    for id in `jq  -c '.[]|.id' $EXPORT` ; do
      echo "" >>$ISSUES
      echo "" >>$ISSUES
      TITLE=`jq  -c '.[]|select(.id == '$id')|.title' $EXPORT|sed -e 's/\\\"/\`/g'|sed -e 's/"//g'`
      IID=`jq  -c '.[]|select(.id == '$id')|.number' $EXPORT|sed -e 's/"//g'`
      STATE=`jq  -c '.[]|select(.id == '$id')|.state' $EXPORT|sed -e 's/"//g'`
      s=`echo $STATE|sed -e 's/open/in progress/g'|sed -e 's/closed/resolved/g'`
      MILESTONE=`jq  -c '.[]|select(.id == '$id')|.milestone.title' $EXPORT|sed -e 's/"//g'|sed -e 's/null/No Milestone/g'`
      ASSIGNEE=`jq  -c '.[]|select(.id == '$id')|.assignee' $EXPORT|sed -e 's/.*"name"..\(.*\)","username.*id":\([0-9]*\).*/\1 (\2)/g'`
      LABELS=`jq  -c '.[]|select(.id == '$id')|.labels' $EXPORT|sed -e 's/.*"name"..\(.*\)","color.*/[\`\1\`] /g'`
      echo "## $IID $TITLE ($s)"  >>$ISSUES
      echo "" >>$ISSUES
      echo -n "*${MILESTONE}*"  >>$ISSUES
      if [ ! "$LABELS" = "[]" ] ; then
        echo -n " $LABELS" >>$ISSUES
      fi
      if [ "$ASSIGNEE" != "null" ] ; then
        echo -n " - Currently assigned to: \`$ASSIGNEE\`" >>$ISSUES
      fi
      echo "" >>$ISSUES
      AUTHOR=`jq  -c '.[]|select(.id == '$id')|.user' $EXPORT|sed -e 's/.*login...\(.*\)","id.*/\1/g'`
      echo "" >>$ISSUES
      if [ "$AUTHOR" != "null" ] ; then
        echo -n "Author: \`$AUTHOR\` " >>$ISSUES
      fi
      echo "GitHub ID $id" >>$ISSUES
      DESCRIPTION=`jq  -c '.[]|select(.id == '$id')|.body' $EXPORT`
      if [ "$DESCRIPTION" != "null" ] ; then
        echo "" >>$ISSUES
        echo "$DESCRIPTION" |sed -e 's/\\"/\`/g'|sed -e 's/"//g'|sed -e 's/\\n/\n&/g'|sed -e 's/\\n//g'|sed -e 's/\\r//g' >>$ISSUES
      fi
    done
  fi

  if [ $TYPE = "redmine" ] ; then
    BASEURL=`grep redmine.url= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No redmine source url configured. Did you setup redmine mirroring?" $BASEURL
    KEY=`grep redmine.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No redmine api key configured. Did you setup redmine mirroring?" $KEY
    PROJECTS=`grep redmine.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No redmine project. Did you setup redmine mirroring?" $PROJECTS
    rm $ISSUES
    for PROJECT in `echo "$PROJECTS"|sed -e 's/,/\ /g'`; do
      echo "Project: $PROJECT"
      issueCollectionHeader "$PROJECT" "append"
      COUNT=0
      OFFSET=0
      PAGE=1
      until [ $OFFSET -gt $COUNT ] ; do
        URL="${BASEURL}/projects/$PROJECT/issues.json?page=$PAGE"'&limit=100&f\[\]=status_id&op\[status_id\]=*&set_filter=1'
        curl -H "X-Redmine-API-Key: $KEY" "$URL" 2> /dev/null >$EXPORT
        checkExport $EXPORT
        PAGE=$[ $PAGE + 1 ]
        COUNT=`jq  -c '.total_count' $EXPORT`
        OFFSET=`jq  -c '.offset' $EXPORT`
        test $OFFSET -lt $COUNT && echo "continue $OFFSET - $COUNT"
        for id in `jq  -c '.issues[]|.id' $EXPORT` ; do
          echo "" >>$ISSUES
          echo "" >>$ISSUES
          SUBJECT=`jq  -c '.issues[]|select(.id == '$id')|.subject' $EXPORT|sed -e 's/"//g'`
          STATUS=`jq  -c '.issues[]|select(.id == '$id')|.status' $EXPORT|sed -e 's/.*name...\(.*\)"./\1/g'`
          s=`echo $STATUS|sed -e 's/In\ Bearbeitung/In Progress/g'|sed -e 's/Umgesetzt/Resolved/g'|sed -e 's/Erledigt/Resolved/g'`
          echo "## $id $SUBJECT ($s)" >>$ISSUES
          echo "" >>$ISSUES
          VERSION=`jq  -c '.issues[]|select(.id == '$id')|.fixed_version' $EXPORT|sed -e 's/null/*No Milestone*/g'|sed -e 's/.*name...\(.*\)"./*\1*/g'`
          ASSIGNEE=`jq  -c '.issues[]|select(.id == '$id')|.assigned_to' $EXPORT|sed -e 's/.*id..\([0-9]*\).*name...\(.*\)"./\2 (\1)/g'`
          PRIORITY=`jq  -c '.issues[]|select(.id == '$id')|.priority' $EXPORT|sed -e 's/.*id..\([0-9]*\).*name...\(.*\)"./\2 (\1)/g'`
          echo -n "${VERSION}"  >>$ISSUES
          if [ "$ASSIGNEE" != "null" ] ; then
            echo -n " - Currently assigned to: \`$ASSIGNEE\`" >>$ISSUES
          fi
          echo "" >>$ISSUES
          echo "" >>$ISSUES
          echo "### Priority: $PRIORITY" >>$ISSUES
          echo "" >>$ISSUES
          echo "### Description" >>$ISSUES
          echo "" >>$ISSUES
          AUTHOR=`jq  -c '.issues[]|select(.id == '$id')|.author' $EXPORT|sed -e 's/.*name...\(.*\)"./\1/g'`
          if [ "$AUTHOR" != "null" ] ; then
            echo "Author: \`$AUTHOR\`" >>$ISSUES
            echo "" >>$ISSUES
          fi
          jq  -c '.issues[]|select(.id == '$id')|.description' $EXPORT \
            |sed -e 's/\\r\\n/\n&/g'|sed -e 's/\\r\\n//g' \
            |sed -e 's/\&ouml;/ö/g'|sed -e 's/\&Ouml;/Ö/g' \
            |sed -e 's/\&auml;/ä/g'|sed -e 's/\&Auml;/Ä/g' \
            |sed -e 's/\&uuml;/ü/g'|sed -e 's/\&Uuml;/Ü/g' \
            |sed -e 's/\&quot;/"/g'|sed -e 's/\&szlig;/ß/g' \
            |sed -e 's/<strong>//g'|sed -e 's/<\/strong>//g' \
            |sed -e 's/<a href=\\"\(.*\)\\">\(.*\)<\/a>/[\2](\1)/g' \
            |sed -e 's/<h3>/\`/g'|sed -e 's/<\/h3>/\`/g' \
            |sed -e 's/<em>/\`/g'|sed -e 's/<\/em>/\`/g' \
            |sed -e 's/<u>/\`/g'|sed -e 's/<\/u>/\`/g' \
            |sed -e 's/<ul>//g'|sed -e 's/<\/ul>//g' \
            |sed -e 's/<ol>//g'|sed -e 's/<\/ol>//g' \
            |sed -e 's/<span>//g'|sed -e 's/<\/span>//g' \
            |sed -e 's/<li>/* /g'|sed -e 's/<\/li>//g' \
            |sed -e 's/<p[\ =a-z0-9\\"]*>//g'|sed -e 's/<\/p>//g' \
            |sed -e 's/^"//g'|sed -e 's/\\t//g' \
            |sed -e 's/<br \/>//g' |sed -e 's/\\"/\`/g' >>$ISSUES
        done
      done
    done
  fi

  if [ $TYPE = "bitbucket" ] ; then
    USER=`grep bitbucket.user= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No bitbucket.org user configured. Did you setup bitbucket.org mirroring?" $USER
    DISPLAY=`echo $USER|cut -d ':' -f 1`
    PROJECT=`grep bitbucket.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No bitbucket.org project configured. Did you setup bitbucket.org mirroring?" $PROJECT
    URL="https://api.bitbucket.org/2.0/repositories/${PROJECT}/issues"
    curl --basic -u $USER $URL 2> /dev/null >$EXPORT
    checkExport $EXPORT
    RESULT=`jq '.error?|.message?' $EXPORT`
    if [ ! "$RESULT" = "null" ] ; then
      echo "Cannot mirror issues for bitbucket.org project ${PROJECT} as ${DISPLAY}: ${RESULT}"
      cd $CWD
      exit
    fi
    issueCollectionHeader "Issues"
    for id in `jq  -c '.values[].id' $EXPORT` ; do
      echo "" >>$ISSUES
      echo "" >>$ISSUES
      TITLE=`jq  -c '.values[]|select(.id == '$id')|.title' $EXPORT|sed -e 's/\\\"/\`/g'|sed -e 's/"//g'`
      STATE=`jq  -c '.values[]|select(.id == '$id')|.state' $EXPORT|sed -e 's/"//g'`
      s=`echo $STATE|sed -e 's/open/in progress/g'|sed -e 's/closed/resolved/g'`
      MILESTONE=`jq  -c '.values[]|select(.id == '$id')|.milestone|.title' $EXPORT|sed -e 's/"//g'|sed -e 's/null/No Milestone/g'`
      ASSIGNEE=`jq  -c '.values[]|select(.id == '$id')|.assignee|.display_name' $EXPORT|sed -e s/^\"//g|sed -e s/\"$//g`
      echo "## $id $TITLE ($s)"  >>$ISSUES
      echo "" >>$ISSUES
      echo -n "*${MILESTONE}*"  >>$ISSUES
      if [ "$ASSIGNEE" != "null" ] ; then
        echo -n " - Currently assigned to: \`$ASSIGNEE\`" >>$ISSUES
      fi
      echo "" >>$ISSUES
      AUTHOR=`jq  -c '.values[]|select(.id == '$id')|.reporter|.display_name' $EXPORT|sed -e s/^\"//g|sed -e s/\"$//g`
      echo "" >>$ISSUES
      if [ "$AUTHOR" != "null" ] ; then
        echo "Author: \`$AUTHOR\` " >>$ISSUES
      fi
      DESCRIPTION=`jq  -c '.values[]|select(.id == '$id')|.content.raw' $EXPORT`
      if [ "$DESCRIPTION" != "null" ] ; then
        echo "" >>$ISSUES
        echo "$DESCRIPTION" |sed -e 's/\\"/\`/g'|sed -e 's/"//g'|sed -e 's/\\n/\n&/g'|sed -e 's/\\n//g' >>$ISSUES
      fi
    done
  fi

  if [ $TYPE = "gogs" ] ; then
    URL=`grep gogs.url= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gogs source url configured. Did you setup gogs mirroring?" $URL
    TOKEN=`grep gogs.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gogs api token configured. Did you setup gogs mirroring?" $TOKEN
    PROJECT=`grep gogs.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gogs/pikacode/gitea project. Did you setup gogs mirroring?" $PROJECT
    URL="${URL}/api/v1/repos/${PROJECT}/issues?state=all"
    curl -H "Authorization: token $TOKEN" $URL 2> /dev/null >$EXPORT
    checkExport $EXPORT
    RESULT=`jq '.message?' $EXPORT`
    if [ ! -z "$RESULT" ] ; then
      echo "Cannot mirror issues for gogs project ${OWNER}/${PROJECT}: ${RESULT}"
      exit
    fi
    issueCollectionHeader "Issues"
    for id in `jq  -c '.[]|.id' $EXPORT` ; do
      echo "" >>$ISSUES
      echo "" >>$ISSUES
      TITLE=`jq  -c '.[]|select(.id == '$id')|.title' $EXPORT|sed -e 's/\\\"/\`/g'|sed -e 's/"//g'`
      IID=`jq  -c '.[]|select(.id == '$id')|.number' $EXPORT|sed -e 's/"//g'`
      STATE=`jq  -c '.[]|select(.id == '$id')|.state' $EXPORT|sed -e 's/"//g'`
      s=`echo $STATE|sed -e 's/open/in progress/g'|sed -e 's/closed/resolved/g'`
      MILESTONE=`jq  -c '.[]|select(.id == '$id')|.milestone|.title' $EXPORT|sed -e 's/"//g'|sed -e 's/null/No Milestone/g'`
      ASSIGNEE=`jq  -c '.[]|select(.id == '$id')|.assignee|.full_name' $EXPORT|sed -e s/^\"//g|sed -e s/\"$//g`
      LABELS=`jq  -c '.[]|select(.id == '$id')|.labels' $EXPORT|sed -e 's/.*"name"..\(.*\)","color.*/[\`\1\`] /g'`
      echo "## $IID $TITLE ($s)"  >>$ISSUES
      echo "" >>$ISSUES
      echo -n "*${MILESTONE}*"  >>$ISSUES
      if [ ! "$LABELS" = "[]" ] ; then
        echo -n " $LABELS" >>$ISSUES
      fi
      if [ "$ASSIGNEE" != "null" ] ; then
        echo -n " - Currently assigned to: \`$ASSIGNEE\`" >>$ISSUES
      fi
      echo "" >>$ISSUES
      AUTHOR=`jq  -c '.[]|select(.id == '$id')|.user|.full_name' $EXPORT|sed -e s/^\"//g|sed -e s/\"$//g`
      echo "" >>$ISSUES
      if [ "$AUTHOR" != "null" ] ; then
        echo -n "Author: \`$AUTHOR\` " >>$ISSUES
      fi
      echo "Remote ID $id" >>$ISSUES
      DESCRIPTION=`jq  -c '.[]|select(.id == '$id')|.body' $EXPORT`
      if [ "$DESCRIPTION" != "null" ] ; then
        echo "" >>$ISSUES
        echo "$DESCRIPTION" |sed -e 's/\\"/\`/g'|sed -e 's/"//g'|sed -e 's/\\n/\n&/g'|sed -e 's/\\n//g' >>$ISSUES
      fi
    done
  fi
  # rm -f $EXPORT

  writeRoadmap
  
fi


# remote command to issue commands on mirror sources
if [ "$CMD" = "remote" ] ; then

  checkTrackdown
  TYPE=`grep mirror.type= $TDCONFIG|cut -d '=' -f 2`
  bailOnZero "No mirror setup done for this repository." $TYPE
  REMOTE=$2
  bailOnZero "No remote command given as the second parameter" $REMOTE
  # echo "Remote command: $REMOTE"
  ISSUE=$3
  bailOnZero "No target issue to operate on given as the third parameter" $ISSUE
  # echo "Target issue: $ISSUE"
  PARAM=$4
  bailOnZero "No parameter for the remote operation given as the forth parameter" $PARAM
  # echo "Parameter: $PARAM"
  if [ "$TYPE" = "gitlab" ] ; then
    URL=`grep gitlab.url= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gitlab source url configured. Did you setup gitlab mirroring?" $URL
    TOKEN=`grep gitlab.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gitlab api token configured. Did you setup gitlab mirroring?" $TOKEN
    PROJECT=`grep gitlab.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gitlab project. Did you setup gitlab mirroring?" $PROJECT
    if [ "$REMOTE" = "comment" ] ; then
      echo "Adding comment \"$PARAM\" to $ISSUE"
      curl -X POST -H "PRIVATE-TOKEN: $TOKEN" --data "body=${PARAM}" \
           ${URL}/api/v3/projects/${PROJECT}/issues/${ISSUE}/notes 2>&1 > /dev/null
      exit
    fi
    if [ "$REMOTE" = "assign" ] ; then
      echo "Assigning $ISSUE to user $PARAM"
      curl -X PUT -H "PRIVATE-TOKEN: $TOKEN" \
           ${URL}/api/v3/projects/${PROJECT}/issues/${ISSUE}?assignee_id=${PARAM} 2>&1 > /dev/null
      exit
    fi
    if [ "$REMOTE" = "milestone" ] ; then
      echo "Creating milestone $ISSUE ($PARAM)"
      curl -H "PRIVATE-TOKEN: $TOKEN" --data "title=${ISSUE}&description=${PARAM}" \
           ${URL}/api/v3/projects/${PROJECT}/milestones 2> /dev/null | jq .
      exit
    fi
    if [ "$REMOTE" = "issue" ] ; then
      echo "Creating issue $ISSUE with label $PARAM"
      curl -H "PRIVATE-TOKEN: $TOKEN" --data "title=${ISSUE}&description=${ISSUE}&labels=${PARAM}" \
           "${URL}/api/v3/projects/${PROJECT}/issues?title=${ISSUE}&labels=${PARAM}" 2> /dev/null | jq .
      exit
    fi
  fi
  if [ "$TYPE" = "github" ] ; then
    OWNER=`grep github.owner= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No github owner configured. Did you setup github mirroring?" $OWNER
    TOKEN=`grep github.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No github api token configured. Did you setup github mirroring?" $TOKEN
    PROJECT=`grep github.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No github project. Did you setup github mirroring?" $PROJECT
    URL="https://api.github.com/repos/${OWNER}/${PROJECT}"
    if [ "$REMOTE" = "comment" ] ; then
      echo "Adding comment \"$PARAM\" to $ISSUE"
      curl -X POST -H "Authorization: token $TOKEN" --data "{\"body\":\"${PARAM}\"}"\
           ${URL}/issues/${ISSUE}/comments 2>&1 > /dev/null
      exit
    fi
    if [ "$REMOTE" = "assign" ] ; then
      echo "Assigning $ISSUE to user $PARAM"
      DATA="{\"assignees\": [ \"${PARAM}\" ]}\""
      echo $DATA
      curl -X POST -H "Authorization: token $TOKEN" --data "$DATA"\
           ${URL}/issues/${ISSUE}/assignees 2>&1 > /dev/null
      exit
    fi
  fi
  if [ "$TYPE" = "redmine" ] ; then
    URL=`grep redmine.url= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No redmine source url configured. Did you setup redmine mirroring?" $URL
    KEY=`grep redmine.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No redmine api key configured. Did you setup redmine mirroring?" $KEY
    if [ "$REMOTE" = "comment" ] ; then
      echo "Adding comment \"$PARAM\" to $ISSUE"
      curl -X PUT -H 'Content-Type: application/json' -H "X-Redmine-API-Key: $KEY" \
           -d "{\"issue\":{\"notes\":\"$PARAM\"}}" ${URL}/issues/${ISSUE}.json 2> /dev/null
      exit
    fi
    if [ "$REMOTE" = "assign" ] ; then
      echo "Assigning $ISSUE to user $PARAM"
      curl -X PUT -H 'Content-Type: application/json' -H "X-Redmine-API-Key: $KEY" \
           -d "{\"issue\":{\"assigned_to_id\":\"$PARAM\"}}" ${URL}/issues/${ISSUE}.json 2> /dev/null
      exit
    fi
  fi
  if [ "$TYPE" = "gogs" ] ; then
    URL=`grep gogs.url= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gogs/gitea source url configured. Did you setup mirroring?" $URL
    TOKEN=`grep gogs.key= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gogs/gitea api token configured. Did you setup mirroring?" $TOKEN
    PROJECT=`grep gogs.project= $TDCONFIG|cut -d '=' -f 2`
    bailOnZero "No gogs/gitea project. Did you setup mirroring?" $PROJECT
    if [ "$REMOTE" = "comment" ] ; then
      echo "Adding comment \"$PARAM\" to $ISSUE"
      curl -X POST -H "Authorization: token $TOKEN" --data "body=${PARAM}" \
           ${URL}/api/v1/repos/${PROJECT}/issues/${ISSUE}/comments 2> /dev/null
      exit
    fi
    # Doesn't seem to work for some reason
    if [ "$REMOTE" = "assign" ] ; then
      echo "Assigning $ISSUE to user $PARAM"
      curl -X PATCH -H "Authorization: token $TOKEN" --data "assignee=${PARAM}"  \
           ${URL}/api/v1/repos/${PROJECT}/issues/${ISSUE} 2> /dev/null | jq .
      exit
    fi
  fi
  echo "Unknown remote command \"$REMOTE\" for mirror source of type \"$TYPE\""

fi


# gitlab command to setup a gitlab system as a remote mirror source
if [ "$CMD" = "gitlab" ] ; then

  checkJq
  bailOnZero "No api token given as the first parameter" $2
  bailOnZero "No project name given as the second parameter" $3
  preventRepeatedMirrorInit
  URL=${4:-https://gitlab.com}
  PID=`curl --header "PRIVATE-TOKEN: $2" ${URL}/api/v3/projects?per_page=100 2> /dev/null|jq '.[]|select(.name=="'$3'")|.id'`
  if [ -z "$PID" ] ; then
    PID=`curl --header "PRIVATE-TOKEN: $2" ${URL}/api/v3/projects?per_page=100 2> /dev/null|jq '.[]|select(.path_with_namespace=="'$3'")|.id'`
  fi
  echo "Setting up TrackDown to mirror from $3 ($PID) on $URL"
  setupCollectionReference gitlab
  echo "gitlab.url=$URL" >> $TDCONFIG
  echo "gitlab.project=$PID" >> $TDCONFIG
  echo "gitlab.key=$2" >> $TDCONFIG

fi


# github command to setup a github system as a remote mirror source
if [ "$CMD" = "github" ] ; then

  checkJq
  P=${2:-$REMOTEPROJECT}
  bailOnZero "No project name given as the first parameter" $P
  U=${3:-$REMOTEUSER}
  bailOnZero "No username given as the second parameter" $U
  TOKEN=${4:-$GITHUB_COM_TOKEN}
  bailOnZero "No api token given as the third parameter" $TOKEN
  preventRepeatedMirrorInit
  echo "Setting up TrackDown to mirror $P owned by $U from github.com"
  setupCollectionReference github
  echo "prefix=https://github.com/$U/$P/commit/" >> $TDCONFIG
  echo "github.owner=$U" >> $TDCONFIG
  echo "github.project=$P" >> $TDCONFIG
  echo "github.key=$TOKEN" >> $TDCONFIG

fi


# bitbucket command to setup bitbucket.org as a remote mirror source
if [ "$CMD" = "bitbucket" ] ; then

  checkJq
  P=${2:-$REMOTEPROJECT}
  bailOnZero "No project name given as the first parameter" $P
  U=${3:-$REMOTEUSER}
  bailOnZero "No username given as the second parameter" $U
  preventRepeatedMirrorInit
  echo "Setting up TrackDown to mirror $P as $U from bitbucket.org"
  setupCollectionReference bitbucket
  echo "prefix=https://bitbucket.org/$U/$P/commits/" >> $TDCONFIG
  echo "bitbucket.user=$U" >> $TDCONFIG
  echo "bitbucket.project=$P" >> $TDCONFIG

fi


# redmine command to setup a redmine system as a remote mirror source
if [ "$CMD" = "redmine" ] ; then

  checkJq
  bailOnZero "No api key given as the first parameter" $2
  bailOnZero "No project name given as the second parameter" $3
  bailOnZero "No redmine instance base url given as the third parameter" $4
  preventRepeatedMirrorInit
  echo "Setting up TrackDown to mirror from $3 on $4"
  setupCollectionReference redmine
  echo "redmine.url=$4" >> $TDCONFIG
  echo "redmine.project=$3" >> $TDCONFIG
  echo "redmine.key=$2" >> $TDCONFIG

fi


# gogs command to setup a gogs, gitea, or pikacode system as a remote mirror source
if [ "$CMD" = "gogs" ] ; then

  checkJq
  bailOnZero "No api token given as the first parameter" $2
  bailOnZero "No project name given as the second parameter" $3
  URL=${4:-https://v2.pikacode.com}
  preventRepeatedMirrorInit
  echo "Setting up TrackDown to mirror from $3 on $URL"
  setupCollectionReference gogs
  echo "prefix=$URL/$3/commit/" >> $TDCONFIG
  echo "gogs.url=$URL" >> $TDCONFIG
  echo "gogs.project=$3" >> $TDCONFIG
  echo "gogs.key=$2" >> $TDCONFIG

fi
