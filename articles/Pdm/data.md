# PDM - modern Python package manager

[PDM](/project/PDM/reviews) is claimed to be a modern Python package manager.
After taking a glimpse at the documentation [site](https://pdm.fming.dev/), which I find really cool,

I have a feeling that I want to give it try. At least it _looks_ simpler 
and more flexible in comparison with older tools, like `virtualenv`.

At least the approach reminds me package managers from other languages:

Js - npm, Perl - carton and Ruby - bundler.


# Installation issue

According the documentation all user has to do is to `curl` installation
script and pipe it to `python` what I did:


```
curl -sSL https://raw.githubusercontent.com/pdm-project/pdm/main/install-pdm.py | python3 -
```

error:

```
  File "<stdin>", line 1
SyntaxError: future feature annotations is not defined

```

After rereading the docs I see this:

> There is no restriction about what Python version your project is using, but installing PDM itself needs Python 3.7+.

Oh, bummer, I wish I could install using any `Python3*` version, 
now I need to upgrade my python first:

```
curl -O https://www.python.org/ftp/python/3.7.3/Python-3.7.3.tar.xz

tar -xf Python-3.7.3.tar.xz

cd Python-3.7.3

./configure --enable-optimizations

make -j 8

sudo yum install libffi-devel # this is required to build Python on CentOS

sudo make altinstall
```

Now pdm installation succeeds:

```
curl -sSL https://raw.githubusercontent.com/pdm-project/pdm/main/install-pdm.py | python3.7
```

# Hello world project

As pdm implies we always work in some local folder and install dependencies for this folder:


```
mkdir pdm
cd pdm
```

Now, first of all initialize pdm for that project:

```
export PATH=~/.local/bin/:$PATH
pdm init
```

output:

```
Creating a pyproject.toml for PDM...
Please enter the Python interpreter to use
0. /usr/local/bin/python3.7 (3.7)
1. /usr/local/bin/python3.7m (3.7)
2. /usr/bin/python3 (3.6)
3. /usr/bin/python3.6 (3.6)
4. /usr/bin/python3.6m (3.6)
5. /bin/python3 (3.6)
6. /bin/python3.6 (3.6)
7. /bin/python3.6m (3.6)
8. /root/.local/share/pdm/venv/bin/python (3.7)
Please select: [0]: 2
Using Python interpreter: /usr/bin/python3 (3.6)
Is the project a library that will be uploaded to PyPI? [y/N]: N
License(SPDX name) [MIT]:
Author name []: John Brown
Author email []: user@mail.org
Python requires('*' to allow any) [>=3.6]:
Changes are written to pyproject.toml.
```

It's really cool to see that pdm picks up all my Python interpreters and offer me
to configure using a specific one.


Now let's install some dependencies, for example `requests` pip module:

```
pdm add requests
```

output:

```
Adding packages to default dependencies: requests
✔ 🔒 Lock successful
Changes are written to pdm.lock.
Changes are written to pyproject.toml.
Synchronizing working set with lock file: 5 to add, 0 to update, 0 to remove

  ✔ Install certifi 2021.10.8 successful
  ✔ Install charset-normalizer 2.0.7 successful
  ✔ Install idna 3.3 successful
  ✔ Install requests 2.26.0 successful
  ✔ Install urllib3 1.26.7 successful

🎉 All complete!
```

The output is pretty informative as well, basically it just tells as what has been installed.
I like it so far :-)).

If we list the local folder now we could guess that all dependencies are installed locally
( I guess into `__pypackages__` folder ):

```
ls -1
```

output:

```
pdm.lock
__pypackages__
pyproject.toml
```

Which is pretty awesome also, as even if something goes wrong I can always remove stuff by just deleting a folder, 
something I would not afford if I go standard `pip install` way. 

Great!


# Using dependencies

Now let's check that the installed dependency is accessible for our python.

First let's ensure we don't have `requests` installed system wide:


```
python3 -c 'from requests import *'
```

output:

```
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'requests'
```

Now we need to use _locally_ installed `requests`.

First thing that came into my mind was to adjust `PYTHONPATH` var, but that did not
succeed:

```
PYTHOPATH=__pypackages__/3.6/lib/  /usr/bin/python3 -c 'from requests import *'
```

output:

```
Traceback (most recent call last):
  File "<string>", line 1, in <module>
ModuleNotFoundError: No module named 'requests'
```

I spent some time trying to find an answer in the internet but did not
find anything interesting. However my experience with other languages alike
systems gave me right direction. We should use `pdm run` wrapper:


```
pdm run  /usr/bin/python3 -c 'from requests import *' && echo $?
```

output:

```
0
```

I would suggest pdm developers to reflect this significant step 
in their [documentation](https://pdm.fming.dev/usage/dependency/).

# Conclusion

I would like to stop here. Of course `pdm` has a lot of other cool feature not mentioned here.
It'd a lot of time to cover all them. 

However I intentionally used a very simple
scenario to show pdm fundamental principles:

* Dependencies get installed into local folders
* To pass dependencies to python one needs to use `pdm run` wrapper

I hope this was useful.

Even my slightly "picky" mindset tells me that `pdm` deserves 5 butterflies, however
considering some significant documentation gaps and requiring of `python 3.7*` version
I am going to give [4](/project/PDM/reviews).

Anyway, I am impressed. Great project, guys!

---

Alexey
