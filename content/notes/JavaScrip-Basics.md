---
title: "JavaScript Basics"
date: 2020-02-16
tags: ["javascript", "js"]

draft: false
---

Notes following along with freeCodeCamp's JavaScript tutorial.
The tutorial can be found [here](https://www.freecodecamp.org/learn/javascript-algorithms-and-data-structures/es6/)
and in video from [here](https://www.youtube.com/watch?v=PkZNo7MFNFg).

<!--more-->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Declaring Variables](#declaring-variables)
  - [`var` and `let`](#var-and-let)
    - [`var` example](#var-example)
    - [`let` example](#let-example)
  - [Scopes of `var` and `len`](#scopes-of-var-and-len)
  - [`const` keyword](#const-keyword)
    - [Mutate arrays declared by `const`](#mutate-arrays-declared-by-const)
  - [Preventing object mutation](#preventing-object-mutation)
- [Functions](#functions)
  - [Arrow/Anonymous Functions.](#arrowanonymous-functions)
      - [Basic notation](#basic-notation)
      - [Arrow Notation](#arrow-notation)
      - [Body-less Arrow Notation](#body-less-arrow-notation)
    - [Arrow functions with parameters](#arrow-functions-with-parameters)
  - [Default Parameters](#default-parameters)
  - [Rest Parameters](#rest-parameters)
  - [Destructing Assignment on Objects](#destructing-assignment-on-objects)
    - [Restructuring Assignment on nested objects](#restructuring-assignment-on-nested-objects)
  - [Destructing Assignment For Arrays](#destructing-assignment-for-arrays)
    - [Combining Array Deconstruction with the Rest Parameter](#combining-array-deconstruction-with-the-rest-parameter)
    - [Using the Deconstruction Assignment on a function's parameters](#using-the-deconstruction-assignment-on-a-functions-parameters)
      - [Deconstruction within the function](#deconstruction-within-the-function)
      - [Automatic in-place Deconstruction](#automatic-in-place-deconstruction)
- [String Template Literals](#string-template-literals)
- [Promise](#promise)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Declaring Variables

## `var` and `let`

In JavaScript both `var` and `let` are used to declare variables.

`var` lets you override a variable without throwing an error, conversely, `let` will throw an error.

### `var` example

```javascript
var camper = 'James';
var camper = 'David';
console.log(camper);
// logs 'David'
```

### `let` example

```javascript
let camper = 'James';
let camper = 'David'; // throws an error
```

`"use strict";` enables strict mode, which can catch common coding errors.

```javascript
"use strict";
x = 3.14; // throws an error because x is not declared
```

## Scopes of `var` and `len`

When a variable is declared using `var` it is in the local or global scope,
depending on if its declared at the\top level or in a function.

The `let` keyword has the same functionality, however if the variable is contained within a block, statement or expression it is limited to that scope.


## `const` keyword

Variables declared using the `const` keyword is read-only and cannot be reassigned

```javascript
"use strict";
const FAV_PET = "Cats";
FAV_PET = "Dogs"; // returns error
```

### Mutate arrays declared by `const`

Mutable objects (including arrays and functions) that are declared with `const` can still be modified. `const` only prevents reassignment of the variable.

```javascript
"use strict";
const s = [5, 6, 7];
s = [1, 2, 3]; // throws error, trying to assign a const
s[2] = 45; // works just as it would with an array declared with var or let
console.log(s); // returns [5, 6, 45]
```

## Preventing object mutation

Due to `const` only preventing reassignment, JavaScript has a function called `Object.freeze` to prevent mutation.

```javascript
let obj = {
  name:"FreeCodeCamp",
  review:"Awesome"
};
Object.freeze(obj);
obj.review = "bad"; // will be ignored. Mutation not allowed
obj.newProp = "Test"; // will be ignored. Mutation not allowed
console.log(obj);
// { name: "FreeCodeCamp", review:"Awesome"}
```

# Functions

## Arrow/Anonymous Functions.

You can use the arrow notation to write anonymous functions.

The following snipping all do the same thing

#### Basic notation
```javascript
const myFunc = function() {
  const myVar = "value";
  return myVar;
}
```

#### Arrow Notation
```javascript
const myFunc = () => {
  const myVar = "value";
  return myVar;
}
```

#### Body-less Arrow Notation
```javascript
const myFunc = () => "value";
```

### Arrow functions with parameters

```javascript
// doubles input value and returns it
const doubler = (item) => item * 2;

// the same function, without the argument parentheses
const doubler = item => item * 2;

// multiplies the first input value by the second and returns it
const multiplier = (item, multi) => item * multi;
```

## Default Parameters

Very similar syntax to python

```javascript
const greeting = (name = "Anonymous") => "Hello " + name;

console.log(greeting("John")); // Hello John
console.log(greeting()); // Hello Anonymous
```

## Rest Parameters

This is equivalent to `def func(*args):` in python.

```javascript
function howMany(...args) {
  return "You have passed " + args.length + " arguments.";
}
console.log(howMany(0, 1, 2)); // You have passed 3 arguments.
console.log(howMany("string", null, [1, 2, 3], { })); // You have passed 4 arguments.
```

Because the rest parameter always returns an array we can use the `map()`, `filter()` and `reduce()` functions on the array.


The same syntax can be used to evaluate arrays in-place

```javascript
const arr = [6, 89, 3, 45];
const maximus = Math.max(...arr); // returns 89
```

`Math.max()` expects comma separated values

## Destructing Assignment on Objects

The following code blocks are equivalent.

```javascript
const user = { name: 'John Doe', age: 34 };

const name = user.name; // name = 'John Doe'
const age = user.age; // age = 34
```

Vs

```javascript
const { name, age } = user;
// name = 'John Doe', age = 34
```

You can also rename variables when deconstructing

```javascript
const user = { name: 'John Doe', age: 34 };

const { name: userName, age: userAge } = user;
// userName = 'John Doe', userAge = 34
```

  > get the value of `user.name` and assign it to a new variable named `userName`


### Restructuring Assignment on nested objects

```javascript
const user = {
  johnDoe: {
    age: 34,
    email: 'johndoe@gmail.com'
  }
}
```

Extract the values `age` and `email`

```javascript
const {johnDoe: {age, email}} = user;
```

Extract and rename `age` and `email`

```javascript
const {johnDoe: { age: userAge, email: userEmail }} = user;
```

## Destructing Assignment For Arrays

Where the spread operator unpacked _ALL_ of the elements in the array, the
deconstruction notation allows us to pick and choose which indexes we want.

```javascript
const [a, b] = [1, 2, 3, 4, 5, 6];
console.log(a, b); // 1, 2
```

You can also access any index by using commas

```javascript
const [a, b,,, c] = [1, 2, 3, 4, 5, 6];
console.log(a, b, c); // 1, 2, 5
```

This notation can also be used to swap the values in two variables.

```javascript
let a = 8, b = 6;
[b, a] = [a, b]
console.log(a, b) // 6, 8
```

### Combining Array Deconstruction with the Rest Parameter

Sometimes in array Deconstruction it is useful to collect the remaining elements
in their own array. I.e. `1, 2, [3, 4, 5]` from `[1, 2, 3, 4, 5]`.

In python we would use deconstruction and the splat operator.

```python
a, b, *c = [1, 2, 3, 4, 5]
```

The notation for JavaScript is similar.

```javascript
const [a, b, ...c] = [1, 2, 3, 4, 5];
console.log(a, b) // 1, 2
console.log(arr) // [3, 4, 5]
```

However, unlike python, the rest parameter (`...`) must be the last variable.

### Using the Deconstruction Assignment on a function's parameters

Given some object `profileData` with at-least `name`, `age`, `nationality` and `location`
properties the function will automatically restructure the object into the needed parts.

For example the following code blocks accomplish the same thing.

#### Deconstruction within the function
```javascript
const profileUpdate = (profileData) => {
  const { name, age, nationality, location } = profileData;
    // do something with these variables
}
```


#### Automatic in-place Deconstruction
```javascript
const profileUpdate = ({ name, age, nationality, location }) => {
  /* do something with these fields */
}
```

# String Template Literals

Basically `f-strings` in python.

```javascript
const person = {
    name: "Bob",
    age: 32
};

const greeting = `Hi, my name is ${person.name}.
I am ${person.age} years old.`;

console.log(greeting);
// Hi, my name is Bob.
// I am 32 years old.
```

Several things to note.
  1. The use of back ticks \` rather than quotes
  1. The string preserves indentation/multi lines
  1. The `${expression}` placeholders. Anything within the brackets will be evaluated.


# Promise
A promise is an asynchronous functions

```javascript
const makeServerRequest = new Promise((resolve, reject) => {
  let responseFromServer = false;
  if(responseFromServer) {
    resolve("We got the data");
  } else {
    reject("Data not received");
  }
}).then(
  result => {console.log(result);}
).catch(
  error => {consol.log(error);
);
```

If the promise is successful, the `resolve` function is called, then the returned values
are passed to `then`

If the promise is unsuccessful, the `reject` function is called,
then the returned values are passed to `catch`
