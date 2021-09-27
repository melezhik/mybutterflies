# Ain

Recently I've come across an interesting tool called [ain](/project/ain/reviews). 

I knew about it from hacker news, which I use quite often to pass my time.

It allows one to make http calls using simple DSL. 

The author of ain represents the tool as a console alternative to postman.

The tool is written in go which simplifies an installation process:

```bash
brew tap jonaslu/tools
brew install ain
```

Now all you need to do is define some template to implement request logic:

`cat basic_template.ain`:

```ini
[Host]
https://mybf.io/project/ain/reviews

[Headers]
Content-Type: text/plain

[Backend]
curl

[BackendOptions]
-sSL
```

And then:

```bash
ain basic_template.ain
```

Output:

```html
... output truncated
      <div class="panel-block">
        <p class="control">
          project: ain | points: 0 | reviews cnt: 0
        </p>
      </div>
... output truncated
```

This is how one tests http endpoints.


# Merge configuration files

Ain operates on configuration files, that are merged in order. So one can
have more then one configs:


`cat basic_template.ain`:

```ini
[Host]
https://mybf.io
```

`cat project.ain`:

```ini
[Host]
/project/ain/reviews
```

And then successfully create a request:

```bash
ain basic_template.ain project.ain
```


All this allows a project module architecture.


# Parametrization

Of course, this is something one expect from tools like that. 

Ability to parameterize requests. Ain has an idea of variables for this:


`cat project.ain`:

```ini
[Host]
/mbf/project/${project}/reviews
```

So one can:

```bash
project=ain ain basic_template.ain project.ain
```

# External commands

Another level of freedom is ability to run external commands, that allows one
to generate configuration parameters in runtime:


`cat project.ain`:

```ini
[Host]
$(echo /mbf/project/ain/reviews)
```

# Conclusion

Ain is simple, yet flexible command line tool to test your http applications. 

I've not tested in real projects but the first impression is 4 butterflies. Good job.

Let's see how the tool evolve in the future ...


