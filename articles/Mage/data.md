[Mage](/project/mage/reviews) is an implementation of task runner / makefile written on Go. 

The author aims to make it with minimal dependencies ( pure go ) and concise and clear syntax. 

---

Let's get started.

# Installation

I am using mac os, so

```bash
brew install mage
```

# First problem

So, when following documentation I've create a simple magefile and try to run `mage`

```go
//+build mage

package main

// My build target.
func Build() {
  println("ok")
}
```

I get the following error:
 
```
Error determining list of magefiles: failed to list non-mage gofiles: exit status 1: go: go.mod file not found in current directory or any parent directory; see 'go help modules' 
```

After some consideration of the problem, I finally realize that mage require some

go module structure in the current directory, which is a bit weird, because it was not

the case when I did the same on another Linux machine.

So I do this to fix the problem:

```bash
go mod init example/foo
```

output:

    go: creating new go.mod: module example/foo
    go: to add module requirements and sums:
    go mod tidy


```bash
mage -l
```

output:

    Targets:
      build   My build target.

So, mage works fine, it's listing our only target called `build` which is _just_ a
go function.

To execute a target we should run `mage <target_name>`. For example:

```bash
mage build
```

output:

    ok


# Dependencies

Mage allows to declare dependencies for targets. So to say, target `build` might require 
2 targets `prepare` and `config`  to be executed first:

```go
//+build mage

package main

// Runs go mod download and then installs the binary.
func Build() {
  mg.Deps(Prepare, Configure)
  println("ok")
}

func Prepare() {
  println("prepare")
}

func Configure() {
  println("configure")
}
```

When I've run this first time I got the error:

```bash
mage build
```

    # command-line-arguments
    ./magefile.go:11:3: undefined: mg
    Error: error compiling magefiles


It took me some time to realize that I need to import `github.com/magefile/mage/mg`
to make this work:


```go
package main

import (
    "github.com/magefile/mage/mg"
)
```

Now I can run `mage build` and dependencies will be triggered first, 
where ever sub task gets executed in separate thread as goroutine:

```
mage build
```


    configure
    prepare
    ok


# Conclusion

Mage is an interesting replacement of makefile, with simple, clear API and
go only dependency. 

As we could see It has some glitches for the first time user, but they are 
not significant and could be easily overcome.

If I wrote in go I would definitely give it a try. 

4 solid butterflies from me. (I would give it a 5 if I could run a task with named 
named parameters, see my [first review](/project/mage/reviews) on mybfio).

Decent work!




