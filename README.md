# zenoss-py-deps
This repo defines the `pydeps` artifact

# Building
To buid a dev artifact for testing locally, use
  * `git checkout develop`
  * `git pull origin devlop`
  * `make clean build`

The result should be a file named something like `pydeps-5.2.0-el7.2-rev-dev.tar.gz` artifact in the `dest` subdirectory.
If you need to make changes, create a feature branch like you would for any other kind of change, modify the requirements
definition as necessary, use `make clean build` to build a new tar file and then test it as necessary.

Once you have finished your local testing, commit your changes, push them, and create a pull-request as you would
normally. A Jenkins PR build will be started to verify that your changes will build in
a Jenkins environment.

# Releasing

Use git flow to release a new version to the `master` branch.

The artifact version is defined in the [Makefile](./Makefile) file.

For Zenoss employees, the details on using git-flow to release a version is documented 
on the Zenoss Engineering 
[web site](https://sites.google.com/a/zenoss.com/engineering/home/faq/developer-patterns/using-git-flow).
After the git flow process is complete, a jenkins job can be triggered manually to build and 
publish the artifact. 
