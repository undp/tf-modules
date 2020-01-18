# Contributing

This projects follows the [Gitflow workflow][WorkflowRef]. When contributing, please discuss the change you wish to make via [Issues][IssuesRef], email, or any other method with the maintainers of this repository before raising a [Pull Request](#pull-request-process).

[WorkflowRef]: https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow
[IssuesRef]: https://github.com/undp/tf-modules/issues

## Commit messages

This project uses `gitchangelog` to automatically generate the content of [CHANGELOG.md](CHANGELOG.md). So, it is important to follow a convention on how to format your `git commit` messages. In general, all commit messages should follow the structure below:

```sh
<subject>
<BLANK LINE>
<body>
```

`<subject>` should follow the standard `gitchangelog` convention below. See  `gitchangelog.rc` [example][GitHubGitchangelog] on GitHub for more information.

[GitHubGitchangelog]: https://github.com/vaab/gitchangelog/blob/master/.gitchangelog.rc

* `ACTION: [AUDIENCE:] SUBJ_MSG [!TAG ...]`

* `ACTION` indicates **WHAT** the change is about.
  * `chg` is for refactor, small improvement, cosmetic changes, etc
  * `fix` is for bug fixes
  * `new` is for new features, big improvement

* `AUDIENCE` indicates **WHO** is concerned by the change.
  * `dev`  is for developers (API changes, refactoring...)
  * `user`  is for final users (UI changes)
  * `pkg`  is for packagers (packaging changes)
  * `test` is for testers (test only related changes)
  * `doc`  is for tech writers (doc only changes)

* `SUBJ_MSG` is the subject itself.

* `TAGs` are for commit filtering and are preceded with `!`. Commonly used tags are:
  * `refactor` is obviously for refactoring code only
  * `minor` is for a very meaningless change (a typo, adding a comment)
  * `cosmetic` is for cosmetic driven change (re-indentation, etc)
  * `wip` is for partial functionality.

* `EXAMPLES`:
  * `new: usr: support of bazaar implemented.`
  * `chg: re-indent some lines. !cosmetic`
  * `new: dev: update code to be compatible with killer lib ver1.2.3.`
  * `fix: pkg: update year of license coverage.`
  * `new: test: add tests around usability of feature Foo.`
  * `fix: typo in spelling. !minor`

## Pull Request Process

1. Clone the repo to your workstation:

    ```sh
    git clone https://github.com/undp/tf-modules.git tf-modules
    ```

1. Switch to the `develop` branch:

    ```sh
    git checkout develop
    ```

1. Create a new feature branch named `feature/fooBar` from the `develop` branch:

    ```sh
    git checkout -b feature/fooBar
    ```

1. Introduce your modifications locally. Don't forget about corresponding tests!

1. Commit your changes. Ensure your commit message follows the formatting convention [described above](#commit-messages).

    ```sh
    git commit -am "new: usr: add fooBar feature. (close #123)"
    ```

1. Push the `feature/fooBar` branch to the remote origin

    ```sh
    git push origin feature/fooBar
    ```

1. Create a new Pull Request for the repo.

1. You may merge the Pull Request in once you have the sign-off from a repo owner. Or, if you do not have permission to merge, you may request the reviewer to merge it for you.
