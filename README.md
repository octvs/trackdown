# TrackDown

[![License](https://img.shields.io/github/license/mgoellnitz/trackdown.svg)](https://github.com/mgoellnitz/trackdown/blob/master/LICENSE)

Issue Tracking with plain [Markdown][markdown].

In short: You are missing the "git clone" for your tickets from [github.com][github]
or [bitbucket.org][bitbucket] or where we already have this for code and wiki?

You need issue tracking which works for distributed and potentially disconnected
situations together with your distributed version control [GIT][git] and e.g. your
also distributed wiki editing through [GIT][git] as well?

Then this here is for you!

It is not intended for large, permanently online or connected teams and heavy flows
of tickets though, since you will be having only one file a plain [Markdown][markdown]
with your issues - and optionally other stuff - collected in it.


# The Format

While sticking to only partly structured [Markdown][markdown] the following elements
should be maintainable with TrackDown:

- ID
- Title
- Status
- Commits
- Target Version
- Severity
- Affected Versions
- Description
- Comments

These fields are mapped to the following source structure

```
  ## ID Title (status)

  ### severity priority

  ### Target Version (optional)

  affected versions: 1.0, 1.1 (optional - structured)

  ### Description (optional)

  description

  ### Comments (optional)

  comments (structured)

  ### Commits (auto generated)

  The headline commits at level three is optional. The commit messages are inserted
  just as the last part of the issue's level two text area.
```

The really fixed non optional parts of this are

```
  ## ID Title (status)

  (Commit messages inserted here before the next ticket)
```


## Field Values

### ID

Any combination of (english) upper- and lower-case letters and digits.

### Title

Any expressible in Markdown.

### Status

Anything expressible in Markdown. Automatically set values are "in progress" if
you start committing for a certain ID and "resolved", if you are using a prefix
of "fixes ID" or "resolves ID".

Other intended values inlude "new", where the issue is just files, and "closed"
when the solution is brought into production.

### Target Version

Anything expressible in Markdown.

```
  Future-Work Will be evaluated to calculate your project's roadmap
```

### Description

Anything expressible in Markdown.

### Affected Versions

Anything expressible in Markdown. Is expected to describe which version are
affected by the issue (if this is possible to say).

### Comments

Anything expressible in Markdown.

### Severity

Anything expressible in Markdown.

# Commands in the commit messages

Right now TrackDown understands only two commands in the commit messages.

## refs *id*

Reference the commit in the list of commits at the end of the issue text.

This command changes the state to "in progress" from anything like new, nothing,
or even resolved

```
  (Future work: lifts the issue up to the top of the list)
```


## resolves|fixes *id*

Reference the commit in the list of commits at the end of the issue text.

This command changes the state to "resolved" from anything like new, nothing, or
in progress

```
  (Future work: moves the issue to the top the part of the list where the resolved issues reside)
```


# Setup

There are two ways to setup TrackDown. The default way is to use it in a
separate branch of you source code repository and have it editable in your IDE
through a symbolic link to the issue collection file which is maintained by you
through direct typing or the commit hook integration.

The second way is to use the file at a different location - e.g. in the wiki of
the project instead of the source code repository, which is described later.


## Initialize the Repository

If you want to track the issues in a trackdown branch of your source code
repository, you need to modify the [GIT][git] repository accordingly. To initialize
a [GIT][git] repository that way call the script

```
  trackdown.sh init
```

This creates the TrackDown thread for the issue tracking. You have to manually
propagate this thread to your upstream repositories. TrackDown does not
interfere with your remote workflow.

```
  git push original trackdown
```

Initialization must only to be executed once for a repository and all of its
fork and clones.

If you want to use the issue collection file from a different location, leave
out this step.


## Repository Integration

Regardless of the location of the issue collection file, for each clone of the
repository you have to set up the TrackDown tooling to be able to use it
integrated with your source code [GIT][git] commits.

To start using TrackDown for the respective clone you have to issue

```
  trackdown.sh use
```

when using the TrackDown branch in the source code repository or

```
  trackdown.sh use <path/to/issues.md>
```

like in

```
  trackdown-use.sh ../wiki/issues.md
```

when using TrackDown with the issue collection file at a different location.
Automatic commit and push (see below) will be switched of in the latter case.

This creates a gitignored link issues.md in the root directory of your project
pointing to the issue collection file and it will configure a post-commit hook
for [GIT][git].

After this step you can edit the issue collection file following the format
mentioned here.


# Configuration

The source tree contains a directory named .trackdown.

This directory contains a file named config. There are some options in this
file, which you can change.

Example config file for TrackDown:

```
  autocommit=true
  autopush=false
  location=../wiki/issues.md
```


```
  (Future Work: It also contains a file named trackdown.sh update for TrackDown updates)
```

## Auto Commit all Issue Collection Changes

Automatically commits the new change to the trackdown branch. If you didn't
change the default location where your normal source code repository contains
the trackdown branch will want to leave the unchanged to true.

In other scenarios you may switch it to false.


## Auto Push all Issue Collection Commits

Automatically pushes after each commit to the upstream repository. If you didn't
changethe default locations where your normal source code repository is the
upstream repositoryof your issue collection you will want to leave the unchanged
to *true*.

In other scenarios you may switch it to false. E.g. if the issue collection is
part of your project wiki then automatically pushing might lead to remote
operations whichis not desirable.


# Installation

Just copy the files from bin to you /usr/local/bin or somewhere else on your $PATH
for now. Perhaps we will add something more convenient later.


# Issues

## ROADMAP related features need to be implemented.

TrackDown is promised to deal with a sorting features for issues to group them into
Sprints, Release, or the like. This feature is completely missing right now.

## COPY release notes.

When closing a release or sprint, it should be possible to copy all the resolved
issues to a new [Markdown][markdown] file to remove the from the issues collection
and have a contribution to release notes.

## MULTIISSUE There can be only one issue per ticket.

[markdown]: https://daringfireball.net/projects/markdown/
[git]: http://git-scm.com/
[trac]: http://trac.edgewall.org/
[bitbucket]: https://bitbucket.org/
[fossil]: http://fossil-scm.org/index.html/doc/trunk/www/index.wiki
[github]: https://github.com/