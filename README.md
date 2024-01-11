# pacstall-repo

A repository of `pacstall` installation scripts.

About `pacstall` see https://pacstall.dev/ (Github:
https://github.com/pacstall/pacstall)


## Make this repo known to `pacstall`

Adding this repo to the `pacstall` repositories list:

```bash
pacstall -A https://raw.githubusercontent.com/ya55en/pacstall-repo/main
```

## Testing a new package locally

When preparing a new package, we need to fool `pacstall` to find the local clone of the
repo.

This is how we can do it:

1. Add this to the repos (if not yet there):
   ```bash
   pacstall -A file:///$PROJECTS_HOME/pacstall-repo
   ```

   _Note:_ It seems the corresponding remote version of the repo:
   `https://raw.githubusercontent.com/ya55en/pacstall-repo/main` gets a lower
   presidence, thus _no need_ to remove it (you can remove it though; it just needs
   to be back when the testing is over).

2. Use this as a repo base url in the _pacsript_:
   ```
   local REPO_BASE_URL='file:///$PROJECTS_HOME/pacstall-repo'
   ```

3. Create a symlink in the repo root like this:
   ```bash
   ln -s . main
   ```
   (Looks like pacstall appends `main` it the repo URL does not end on this.)

This should suffice to install the app using the local repo.
