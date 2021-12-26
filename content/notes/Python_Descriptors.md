---
title: "Python Descriptors"
date: 2020-06-11
tags: ["python", "descriptors"]

draft: false
---

In its most basic sense a descriptor is any object whose attribute access has been
overridden by `__get__()`, `__set__()`, or `__delete__()`. If any of these methods
are defined the object it is a descriptor.

See the official documentation [here](https://docs.python.org/3/howto/descriptor.html).

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Intro](#intro)
- [Descriptor Protocol](#descriptor-protocol)
- [Invoking Descriptors](#invoking-descriptors)
  - [if `obj` is an Object](#if-obj-is-an-object)
  - [If `obj` is a Class](#if-obj-is-a-class)
  - [For `super()`](#for-super)
- [Descriptor Example](#descriptor-example)
- [Properties](#properties)
- [Functions and Methods](#functions-and-methods)
- [Static Methods and Class Methods](#static-methods-and-class-methods)
- [Questions](#questions)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Intro

By default, the default behavior for attribute access is to get, set, or delete the
attribute from the object's dictionary; if the attribute is not found in the object's
dict, then the next object to be checked in the lookup chain is the parent object.
This continues until no parent exists and excludes metaclasses.

For example `a.x` has the look up chain:

- `a.__dict__['x']`
- `type(a).__dict__['x']`
- `type(type(a)).__dict__['x']`

The aforementioned methods can alter this default behavior.

# Descriptor Protocol

```Python
descr.__get__(self, obj, type=None) -> Value
descr.__set__(self, obj, value) -> None
descr.__delete(self, obj) -> None
```

If an object defines `__set__` or `__delete__` it is considered a "data descriptor".
Objects that only define `__get__` are called "non-data descriptors", these are typically methods.

These two descriptors differ in how overrides are calculated with respect to
entries in a instance's dict.

If the instance's dict contains an entry with the same name as a data descriptor
the descriptor takes presidency. On the other hand, if the instance's dict contains
an entry with the same name as a non-data descriptor the instance takes presidency.

To make a read-only data descriptor define both `__get__` and `__set__` where
`__set__` raises `AttributeError`.

# Invoking Descriptors

Descriptors can be called directly, i.e. `x.__get__(obj)`

However it is more common for a descriptor to be invoked auto madly upon attribute access,
i.e. `obj.d`.

For Example. `obj.d` looks up `d` in `obj`'s dictionary. If `d` defines `__get__` then
`d.__get__(obj)` is invoked according to the following rules.

## if `obj` is an Object

`obj.__getattribute__()` is used. This transforms `b.x -> type(b).__dict__['x'].__get__(b, type(b))`

This chain gives data descriptors presidency over instance variables,
instance variables presidency over non-data descriptors and,
non-data descriptors presidency over `__getaddr__()` (if provided).

## If `obj` is a Class

`type.__getattribute__()` is used instead.
This transforms `B.x -> B.__dict__['x'].__get__(None, B)`
In pure python:

```python
def __getattribute__(self, key):
	"Emulate type_getattro() in Objects/typeobject.c"
	v = object.__getattribute__(self, key)
	if hasattr(v, '__get__'):
		return v.__get__(None, self)
	return v
```

Notes:

- Descriptors are invoked by `__getattribute__`
- Overriding `__getattribute__` prevents automatic descriptor calls
- `object.__getattribute__` and `type.__getattribute__` make different calls to `__get__`
- Data descriptors always override instance dict
- Non-data descriptors may be overridden by instance dict

## For `super()`

The object returned by `super()` has a custom `__getattribute__` method for
invoking descriptors. The lookup `super(B, obj).m` searches
`obj.__class__.__mro__` for the base class "`A`" immediately following `B`.
It then returns `A.__dict__['m'].__get__(obj, B)` If `m` is not a descriptor it
is returned unchanged. If `m` is not in the dict it reverts to a search using
`object.__getattribute__()`

> Note: `__mro__` is a tuple of base classes that are searched during method resolution

# Descriptor Example

```python
class RevealAccess:
    """
    Sets and Gets objects normaly, just logs.
    """

    def __init__(self, init_val=None, name="foo"):
        self.val = init_val
        self.name = name

    def __get__(self, obj, ob_type=None):
        print(f"Getting {self.name}")
        return self.val

    def __set__(self, obj, val):
        print(f"Setting {self.name}")
        self.val = val


class RevealedClass:
    x = RevealAccess(10, "var 'x'")
    y = 3


if __name__ == "__main__":
    c = RevealedClass()
    print(f"Getting: {c.x=}")
    print(f"About to set c.x...")
    c.x = 30
```
<pre class="command-line language-bash" data-user="kgb33" data-output="2-5">
  <code>
    python descriptors.py
	Getting var 'x'
	Getting: c.x=10
	About to set c.x...
	Setting var 'x'
  </code>
</pre>


# Properties

Calling `property` is an easy way of building a data descriptor that
will trigger function calls upon attribute access. Properties have the following signature

> `property(fget=None, fset=None, fdel=None, doc=None) -> property attribute`

The following two classes are identical.

```python
class PropertyExample:
	def getx(self): return self._x
	def setx(self, val): self._x = val
	def delx(self): del self._x
	x = property(getx, setx, delx, doc="The 'x' property")
```

Vs

```python
class PropertyExample:

	@propery
	def x(self):
	"""The 'x' property"""
		return self._x
	@x.setter
	def x(self, val):
		self._x = val

	@x.deleter
	def x(self):
		del self._x
```

The python equivalent of the property implementation (written in C) is as follows:

```Python
class Property:
	"""Emulates PyPropery_Type() in Objects/descrobject.c"""

	def __init__(self,
				 fget: Optional[Callable] = None,
				 fset: Optional[Callable] = None,
				 fdel: Optional[Callable] = None,
				 doc: Optional[str] = None
				 ):
		self.fget = fget
		self.fset = fset
		self.fdel = fdel
		if doc is None and fget is not None:
			doc = fget.__doc__
		self.__doc__ = doc

	def __get__(self, obj, objtype=None):
		if obj is None:
			return self
		if self.fget is None:
			raise AttributeError("Unreadable Attr")
		return self.fget(obj)

	def __set__(self, obj, value):
		if self.fset is None:
			raise AttributeError("Cannot set attr")
		self.fset(obj, value)

	def __del__(self, obj):
		if self.fdel is None:
			raise AttributeError("Cannot delete attr")
		self.fdel(obj)

	def getter(self, fget):
		return type(self)(fget, self.fset, self.fdel, self.__doc__)

	def setter(self, fset):
		return type(self)(self.fget, fset, self.fdel, self.__doc__)

	def deleter(self, fdel):
		return type(self)(self.fget, self.fset, fdel, self.__doc__)
```

# Functions and Methods

> Note: methods are just functions written inside a class.
> The first argument is reserved for the object instance.

Functions include the `__get__` method for binding methods during attribute access.

All functions are non-data descriptors that return bound methods
when they are invoked from an object. In pure python:

```python
class Function:

	def __get__(self, obj, objtype=None):
		""" Simulates func_descr_get() in Objects/funcobject.c """
		if obj is None:
			return self
		return types.MethodType(self, obj)
```

Using the interpreter we can get a better view of whats happening

```python
>>> class D:
...  def f(self, x):
...    return x
...
>>> d = D()

# Access Via __dict__ does not invoke __get__
>>> D.__dict__['f']
<function D.f at 0x00c45070>

# Dotted access from a class calls __get__(), returning the func unchanged
>>> D.f
<function D.f at 0x00c45070>

# Dotted access from an instance calls __get__ which returns
# a function wrapped in a bound method object
>>> d.f
<bound method D.f of <__main__.D object at 0x00B18C90>>

# Internaly the bound method stores the underlining fucntion,
# The instance its bound to, and the class of the bound instance
>>> d.f.__func__
<function D.f at 0x1012e5ae8>
>>> d.f.__self__
<__main__.D object at 0x1012e1f98>
>>> d.f.__class__
<class 'method'>
```

# Static Methods and Class Methods

Functions have a `__get__` method so they can be converted to a method
when accessed as attributes. The non-data descriptor transforms `obj.f(*args)` into `f(obj, *args)`.
This transformation is why a method's first argument is always `self`.
The chart below summarizes different bindings and transformations.

| Transformation | Called from an Object | Called from a Class |
| -------------- | --------------------- | ------------------- |
| function       | f(obj, \*args)        | f(\*args)           |
| static method   | f(\*args)             | f(\*args)           |
| class method    | f(type(obj), \*args)  | f(class, \*args)    |

As you can see static methods return the underlying function with out changes. Both `c.f` and `C.f`
are equivalent to a direct lookup into `object.__getattribute__(c, "f")` or `object.__getattribute__(C, "f")`
Therefore the function is identically accessible from an object or class.

Above is the python equivalent of the function implication. The static and class methods
implementation is as follows:

```python
class StaticMethod:

	def __init__(self, f):
		self.f = f

	def __get__(self, obj, objtype=None):
	""" The static method doesn't care about what object it is called from """
		return self.f

class ClassMethod:

	def __init__(self, f):
		self.f = f

	def __get__(self, obj, objtype=None):
	""" Class methods append the class as the first argument """
		if objtype is None:
			objtype = type(obj)
		def newfunc(*args):
			return self.f(objtype, *args)
		return newfunc

```

# Questions

- Now that python classes inherit from `object` by default is there
  still a different resolution for descriptors?
