
# Alfred workflow scaffold

To create a simple `filter -> openurl` workflow:

* edit `lib/workflow.ls` (Livescript); use the `alfredo` library to generate candidate items for feedback.
* put your filter and workflow images into the `images` folder
* Update `package.json` with name, author, description and relative icon paths.
* `make -f makefile.mk pack` to create the alfred workflow

